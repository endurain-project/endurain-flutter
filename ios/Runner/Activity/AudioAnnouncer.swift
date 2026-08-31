import AVFoundation
import Foundation

/// Process-wide `AVSpeechSynthesizer` wrapper for spoken progress
/// announcements.
///
/// Mirrors the Android `AudioAnnouncer` object: a single synthesizer instance
/// is shared by every recording so announcements queue (the default
/// `AVSpeechSynthesizer` behavior) rather than talking over each other, and
/// the shared `AVAudioSession` stays active while speech is queued so
/// announcements remain audible in the background. Other audio is optionally
/// ducked, and the session is deactivated after the final utterance finishes.
@MainActor
final class AudioAnnouncer: NSObject {
    static let shared = AudioAnnouncer()

    private let synthesizer = AVSpeechSynthesizer()
    private var sessionActive = false
    private var sessionDucks = false
    private var activeUtteranceIds = Set<ObjectIdentifier>()

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Speaks `text`, ducking other audio first when `duck` is true.
    func speak(_ text: String, duck: Bool, languageTag: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: languageTag)
            ?? AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        activeUtteranceIds.insert(ObjectIdentifier(utterance))
        if !sessionActive || sessionDucks != duck {
            activateSession(duck: duck)
        }
        synthesizer.speak(utterance)
    }

    /// Stops any in-progress or queued utterance and releases audio focus.
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        activeUtteranceIds.removeAll()
        deactivateSession()
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
            // Best-effort: speech still proceeds even when the audio session
            // could not be reconfigured (e.g. another app holds an
            // incompatible category); losing the duck effect is preferable to
            // losing the announcement.
        }
    }

    private func deactivateSession() {
        guard sessionActive else {
            return
        }
        sessionActive = false
        sessionDucks = false
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}

extension AudioAnnouncer: @preconcurrency AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        finish(utterance)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        finish(utterance)
    }
}
