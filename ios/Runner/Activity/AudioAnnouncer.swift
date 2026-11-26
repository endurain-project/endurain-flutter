import AVFoundation
import Foundation
import OSLog

/// Process-wide `AVSpeechSynthesizer` wrapper for spoken progress
/// announcements.
///
/// Mirrors the Android `AudioAnnouncer` object: a single synthesizer instance
/// is shared by every recording so announcements queue (the default
/// `AVSpeechSynthesizer` behavior) rather than talking over each other, and
/// the shared `AVAudioSession` stays active while speech is queued so
/// announcements remain audible in the background. Other audio is optionally
/// ducked, and the session is deactivated after the final utterance finishes.
/// Diagnostics contain only fixed stages and system error codes, never spoken
/// text or other recording data.
@MainActor
final class AudioAnnouncer: NSObject {
    static let shared = AudioAnnouncer()

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.endurain.endurain",
        category: "AudioAnnouncer"
    )

    private enum FailureStage: String {
        case voice
        case stop
        case audioSessionActivation = "audio_session_activation"
        case audioSessionDeactivation = "audio_session_deactivation"
        case utteranceCancelled = "utterance_cancelled"
        case utteranceResume = "utterance_resume"
    }

    private let synthesizer = AVSpeechSynthesizer()
    private var sessionActive = false
    private var sessionDucks = false
    private var activeUtteranceIds = Set<ObjectIdentifier>()
    /// Set by `stop()` while the cancelled speech is still winding down; the
    /// session is released from the synthesizer's cancel/finish callback.
    private var deactivateWhenSilent = false
    private var deactivationRetryScheduled = false

    /// Delay before retrying a deactivation the system refused (typically
    /// "busy" while audio was still being torn down).
    private static let deactivationRetryDelay: TimeInterval = 1

    private override init() {
        super.init()
        synthesizer.delegate = self
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    /// Speaks `text`, ducking other audio first when `duck` is true.
    func speak(_ text: String, duck: Bool, languageTag: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        let utterance = AVSpeechUtterance(string: text)
        let requestedVoice = AVSpeechSynthesisVoice(language: languageTag)
        let fallbackVoice = AVSpeechSynthesisVoice(
            language: AVSpeechSynthesisVoice.currentLanguageCode()
        )
        utterance.voice = requestedVoice ?? fallbackVoice
        if utterance.voice == nil {
            reportFailure(stage: .voice)
        }
        activeUtteranceIds.insert(ObjectIdentifier(utterance))
        // This utterance's own finish callback releases the session now.
        deactivateWhenSilent = false
        if !sessionActive || sessionDucks != duck {
            activateSession(duck: duck)
        }
        synthesizer.speak(utterance)
    }

    /// Stops any in-progress or queued utterance and releases audio focus.
    ///
    /// Deactivating the session while the synthesizer is still stopping
    /// fails as "busy" and leaves other audio ducked, so when speech was
    /// actually playing the session is released from the synthesizer's
    /// `didCancel`/`didFinish` callback once it has gone silent.
    func stop() {
        let hadActiveUtterances = !activeUtteranceIds.isEmpty
        activeUtteranceIds.removeAll()
        guard hadActiveUtterances, synthesizer.isSpeaking else {
            deactivateSession()
            return
        }
        guard synthesizer.stopSpeaking(at: .immediate) else {
            reportFailure(stage: .stop)
            deactivateSession()
            return
        }
        deactivateWhenSilent = true
    }

    @objc private func handleAudioSessionInterruption(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else {
            return
        }
        switch type {
        case .began:
            sessionActive = false
        case .ended:
            guard !activeUtteranceIds.isEmpty else {
                sessionDucks = false
                return
            }
            let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            guard options.contains(.shouldResume) else {
                stop()
                return
            }
            activateSession(duck: sessionDucks)
            if synthesizer.isPaused && !synthesizer.continueSpeaking() {
                reportFailure(stage: .utteranceResume)
            }
        @unknown default:
            break
        }
    }

    private func finish(_ utterance: ObjectIdentifier) {
        let wasActive = activeUtteranceIds.remove(utterance) != nil
        guard activeUtteranceIds.isEmpty, wasActive || deactivateWhenSilent else {
            return
        }
        deactivateWhenSilent = false
        deactivateSession()
    }

    private func activateSession(duck: Bool) {
        let session = AVAudioSession.sharedInstance()
        do {
            var options: AVAudioSession.CategoryOptions = [.mixWithOthers]
            if duck {
                options.insert(.duckOthers)
            }
            try session.setCategory(.playback, options: options)
            try session.setActive(true, options: [])
            sessionActive = true
            sessionDucks = duck
        } catch {
            reportFailure(stage: .audioSessionActivation, error: error)
            // Best-effort: speech still proceeds even when the audio session
            // could not be reconfigured (e.g. another app holds an
            // incompatible category); losing the duck effect is preferable to
            // losing the announcement.
        }
    }

    /// Releases the session. It stays marked active when the system refuses,
    /// so a later attempt (one retry here, or the next utterance's finish)
    /// can still restore other apps' volume.
    private func deactivateSession(retryOnFailure: Bool = true) {
        guard sessionActive else {
            sessionDucks = false
            return
        }
        do {
            try AVAudioSession.sharedInstance().setActive(
                false,
                options: [.notifyOthersOnDeactivation]
            )
            sessionActive = false
            sessionDucks = false
        } catch {
            reportFailure(stage: .audioSessionDeactivation, error: error)
            if retryOnFailure {
                scheduleDeactivationRetry()
            }
        }
    }

    private func scheduleDeactivationRetry() {
        guard !deactivationRetryScheduled else {
            return
        }
        deactivationRetryScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.deactivationRetryDelay) { [weak self] in
            guard let self else {
                return
            }
            self.deactivationRetryScheduled = false
            // Speech queued meanwhile owns the session and releases it itself.
            guard self.activeUtteranceIds.isEmpty, !self.synthesizer.isSpeaking else {
                return
            }
            self.deactivateSession(retryOnFailure: false)
        }
    }

    private func cancel(_ utterance: ObjectIdentifier) {
        // An utterance cancelled by `stop()` is no longer tracked; only an
        // unexpected cancellation is a failure.
        if activeUtteranceIds.contains(utterance) {
            reportFailure(stage: .utteranceCancelled)
        }
        finish(utterance)
    }

    private func reportFailure(stage: FailureStage, error: Error? = nil) {
        guard let error else {
            Self.logger.error(
                "TTS failure at stage=\(stage.rawValue, privacy: .public)"
            )
            return
        }
        let nativeError = error as NSError
        Self.logger.error(
            """
            TTS failure at stage=\(stage.rawValue, privacy: .public) \
            domain=\(nativeError.domain, privacy: .public) \
            code=\(nativeError.code)
            """
        )
    }
}

// AVFoundation does not document the delegate queue, so the callbacks hop to
// the main actor instead of asserting they are already on it. Utterances are
// tracked by identity, which is Sendable.
extension AudioAnnouncer: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        let id = ObjectIdentifier(utterance)
        Self.onMainActor { $0.finish(id) }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        let id = ObjectIdentifier(utterance)
        Self.onMainActor { $0.cancel(id) }
    }

    /// Runs [work] right away when already on the main thread, keeping the
    /// callback order, and otherwise in order on the main queue.
    nonisolated private static func onMainActor(
        _ work: @escaping @MainActor @Sendable (AudioAnnouncer) -> Void
    ) {
        if Thread.isMainThread {
            MainActor.assumeIsolated { work(.shared) }
        } else {
            DispatchQueue.main.async { work(.shared) }
        }
    }
}
