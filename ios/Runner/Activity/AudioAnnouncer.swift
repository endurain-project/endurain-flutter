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
        if !sessionActive || sessionDucks != duck {
            activateSession(duck: duck)
        }
        synthesizer.speak(utterance)
    }

    /// Stops any in-progress or queued utterance and releases audio focus.
    func stop() {
        let hadActiveUtterances = !activeUtteranceIds.isEmpty
        activeUtteranceIds.removeAll()
        if hadActiveUtterances && !synthesizer.stopSpeaking(at: .immediate) {
            reportFailure(stage: .stop)
        }
        deactivateSession()
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

    private func finish(_ utterance: AVSpeechUtterance) {
        guard activeUtteranceIds.remove(ObjectIdentifier(utterance)) != nil,
              activeUtteranceIds.isEmpty else {
            return
        }
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

    private func deactivateSession() {
        let wasActive = sessionActive
        sessionActive = false
        sessionDucks = false
        guard wasActive else {
            return
        }
        do {
            try AVAudioSession.sharedInstance().setActive(
                false,
                options: [.notifyOthersOnDeactivation]
            )
        } catch {
            reportFailure(stage: .audioSessionDeactivation, error: error)
        }
    }

    private func cancel(_ utterance: AVSpeechUtterance) {
        guard activeUtteranceIds.contains(ObjectIdentifier(utterance)) else {
            return
        }
        reportFailure(stage: .utteranceCancelled)
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

extension AudioAnnouncer: @preconcurrency AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        finish(utterance)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        cancel(utterance)
    }
}
