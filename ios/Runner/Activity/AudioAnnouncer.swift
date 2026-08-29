import AVFoundation
import Foundation

/// Process-wide `AVSpeechSynthesizer` wrapper for spoken progress
/// announcements.
///
/// Mirrors the Android `AudioAnnouncer` object: a single synthesizer instance
/// is shared by every recording so announcements queue (the default
/// `AVSpeechSynthesizer` behavior) rather than talking over each other, and
/// the shared `AVAudioSession` is only switched to a ducking configuration
/// while an announcement that requested it is speaking — deactivated again as
/// soon as that utterance finishes so music/podcasts return to full volume
/// immediately.
final class AudioAnnouncer: NSObject {
    static let shared = AudioAnnouncer()

    private let synthesizer = AVSpeechSynthesizer()
    private var duckingActive = false

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Speaks `text`, ducking other audio first when `duck` is true.
    func speak(_ text: String, duck: Bool, languageTag: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        if duck {
            activateDuckedSession()
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: languageTag)
            ?? AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        synthesizer.speak(utterance)
    }

    /// Stops any in-progress or queued utterance and releases audio focus.
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        deactivateSession()
    }

    private func activateDuckedSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, options: [.duckOthers, .mixWithOthers])
            try session.setActive(true, options: [])
            duckingActive = true
        } catch {
            // Best-effort: speech still proceeds even when the audio session
            // could not be reconfigured (e.g. another app holds an
            // incompatible category); losing the duck effect is preferable to
            // losing the announcement.
        }
    }

    private func deactivateSession() {
        guard duckingActive else {
            return
        }
        duckingActive = false
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}

extension AudioAnnouncer: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        deactivateSession()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        deactivateSession()
    }
}
