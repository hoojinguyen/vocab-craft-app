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

    public func speak(text: String, rate: Float = 1.0, locale: String = "en-US") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: trimmed)
        
        // Scale rate relative to AVSpeechUtteranceDefaultSpeechRate (0.5) so 1.0x = normal speed
        let scaledRate = AVSpeechUtteranceDefaultSpeechRate * rate
        utterance.rate = min(max(scaledRate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)

        if let voice = AVSpeechSynthesisVoice(language: locale) {
            utterance.voice = voice
        } else if let fallbackVoice = AVSpeechSynthesisVoice.speechVoices().first(where: { $0.language.hasPrefix("en") }) {
            utterance.voice = fallbackVoice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        }

#if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set AVAudioSession category for TTS: \(error)")
        }
#endif

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
        Task { @MainActor [weak self] in
            self?.isSpeaking = false
        }
    }

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.isSpeaking = false
        }
    }
}
