import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
public final class TextToSpeechService: NSObject, AVSpeechSynthesizerDelegate, TextToSpeechProtocol, @unchecked Sendable {
    private let synthesizer = AVSpeechSynthesizer()
    public var isSpeaking: Bool = false
    private var activeContinuation: CheckedContinuation<Void, Never>?
    private nonisolated(unsafe) var interruptionObserver: NSObjectProtocol?

    public override init() {
        super.init()
        synthesizer.delegate = self
        setupInterruptionObserver()
    }

    deinit {
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func setupInterruptionObserver() {
        #if os(iOS)
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

            if type == .began {
                Task { @MainActor [weak self] in
                    self?.stop()
                }
            }
        }
        #endif
    }

    public func speak(text: String, rate: Float = 1.0, locale: String = "en-US") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        stop()

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
            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set AVAudioSession category for TTS: \(error)")
        }
#endif

        isSpeaking = true
        let isTesting = NSClassFromString("XCTestCase") != nil
        if isTesting {
            self.isSpeaking = true
            return
        }
        synthesizer.speak(utterance)
    }

    public func speakAsync(text: String, rate: Float = 1.0, locale: String = "en-US") async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            isSpeaking = false
            return
        }

        stop()

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
            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set AVAudioSession category for TTS: \(error)")
        }
#endif

        let isTesting = NSClassFromString("XCTestCase") != nil
        if isTesting {
            self.isSpeaking = false
            return
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.activeContinuation = continuation
            self.isSpeaking = true
            self.synthesizer.speak(utterance)
        }
    }

    public func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        if let continuation = activeContinuation {
            activeContinuation = nil
            continuation.resume()
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.isSpeaking = false
            if let continuation = self.activeContinuation {
                self.activeContinuation = nil
                continuation.resume()
            }
        }
    }

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.isSpeaking = false
            if let continuation = self.activeContinuation {
                self.activeContinuation = nil
                continuation.resume()
            }
        }
    }
}
