import Foundation
import AVFoundation
import Observation

@MainActor
@Observable
public final class TextToSpeechService: NSObject, @preconcurrency AVSpeechSynthesizerDelegate, TextToSpeechProtocol, @unchecked Sendable {
    private let synthesizer = AVSpeechSynthesizer()
    public var isSpeaking: Bool = false

    public override init() {
        super.init()
        synthesizer.delegate = self
    }

    public func speak(text: String, rate: Float = 0.5, locale: String = "en-US") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.rate = rate
        if let voice = AVSpeechSynthesisVoice(language: locale) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    public func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    // MARK: - AVSpeechSynthesizerDelegate

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
