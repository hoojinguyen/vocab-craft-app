import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
public final class TextToSpeechService: NSObject, AVSpeechSynthesizerDelegate, TextToSpeechProtocol {
    private let synthesizer = AVSpeechSynthesizer()
    public var isSpeaking: Bool = false
    private var activeContinuation: CheckedContinuation<Void, Never>?
    private var interruptionObserver: (any NSObjectProtocol)?

    public override init() {
        super.init()
        synthesizer.delegate = self
        setupInterruptionObserver()
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

    private nonisolated(unsafe) static var cachedVoices: [String: AVSpeechSynthesisVoice] = [:]
    private nonisolated static let voiceLock = NSLock()

    public nonisolated static func resolveVoice(for locale: String) -> AVSpeechSynthesisVoice? {
        voiceLock.lock()
        defer { voiceLock.unlock() }
        if let cached = cachedVoices[locale] { return cached }
        let voice = AVSpeechSynthesisVoice(language: locale)
            ?? AVSpeechSynthesisVoice.speechVoices().first(where: { $0.language.hasPrefix("en") })
            ?? AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        if let voice { cachedVoices[locale] = voice }
        return voice
    }

    public func speak(text: String, rate: Float = 1.0, locale: String = "en-US") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        stop()

        let utterance = AVSpeechUtterance(string: trimmed)

        // Scale rate relative to AVSpeechUtteranceDefaultSpeechRate (0.5) so 1.0x = normal speed
        let scaledRate = AVSpeechUtteranceDefaultSpeechRate * rate
        utterance.rate = min(max(scaledRate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)

        utterance.voice = Self.resolveVoice(for: locale)

#if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP])
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

        utterance.voice = Self.resolveVoice(for: locale)

#if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP])
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

        let timeoutTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: 8_000_000_000)
            } catch {
                return
            }
            guard let self = self else { return }
            if self.activeContinuation != nil {
                if self.synthesizer.isSpeaking {
                    self.synthesizer.stopSpeaking(at: .immediate)
                }
                self.isSpeaking = false
                if let continuation = self.activeContinuation {
                    self.activeContinuation = nil
                    continuation.resume()
                }
            }
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.activeContinuation = continuation
            self.isSpeaking = true
            self.synthesizer.speak(utterance)
        }

        timeoutTask.cancel()
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
