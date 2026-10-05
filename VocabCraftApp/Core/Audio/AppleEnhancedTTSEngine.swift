import AVFoundation
import Foundation

private final class UtteranceTransferBox: @unchecked Sendable {
    let utterance: AVSpeechUtterance
    init(_ utterance: AVSpeechUtterance) {
        self.utterance = utterance
    }
}

@MainActor
public final class AppleEnhancedTTSEngine: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    private let synthesizer: AVSpeechSynthesizer
    private var activeContinuation: CheckedContinuation<Void, Never>?
    public private(set) var isSpeaking: Bool = false
    public private(set) var currentUtterance: AVSpeechUtterance?
    private var onFinishedCallback: (@Sendable () -> Void)?

    public override init() {
        self.synthesizer = AVSpeechSynthesizer()
        super.init()
        synthesizer.delegate = self
    }

    public init(synthesizer: AVSpeechSynthesizer) {
        self.synthesizer = synthesizer
        super.init()
        synthesizer.delegate = self
    }

    public func makeUtterance(text: String, rate: Float, locale: String) -> AVSpeechUtterance? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let utterance = AVSpeechUtterance(string: trimmed)

        // Standard English speech rate: scale around 0.49
        let baseRate = AVSpeechUtteranceDefaultSpeechRate * 0.98
        let scaledRate = baseRate * rate
        utterance.rate = min(max(scaledRate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)

        // Warm, friendly pitch multiplier
        utterance.pitchMultiplier = 1.06

        // Acoustic buffers to prevent clipping and jarring ends
        utterance.preUtteranceDelay = 0.05
        utterance.postUtteranceDelay = 0.10

        if let voice = AppleVoiceSelector.resolveBestVoice(for: locale) {
            utterance.voice = voice
        }

        return utterance
    }

    public func speak(
        text: String,
        rate: Float = 1.0,
        locale: String = "en-US",
        onFinished: (@Sendable () -> Void)? = nil
    ) {
        guard let utterance = makeUtterance(text: text, rate: rate, locale: locale) else {
            onFinished?()
            return
        }
        stop()

        isSpeaking = true
        currentUtterance = utterance
        onFinishedCallback = onFinished

        let isTesting = NSClassFromString("XCTestCase") != nil
        if isTesting { return }
        synthesizer.speak(utterance)
    }

    public func speakAsync(text: String, rate: Float = 1.0, locale: String = "en-US") async {
        guard let utterance = makeUtterance(text: text, rate: rate, locale: locale) else {
            isSpeaking = false
            currentUtterance = nil
            return
        }

        stop()
        isSpeaking = true
        currentUtterance = utterance

        let isTesting = NSClassFromString("XCTestCase") != nil
        if isTesting {
            isSpeaking = false
            currentUtterance = nil
            return
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.activeContinuation = continuation
            self.synthesizer.speak(utterance)
        }
    }

    public func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        currentUtterance = nil
        if let continuation = activeContinuation {
            activeContinuation = nil
            continuation.resume()
        }
        if let callback = onFinishedCallback {
            onFinishedCallback = nil
            callback()
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let box = UtteranceTransferBox(utterance)
        Task { @MainActor [weak self] in
            guard let self, self.currentUtterance === box.utterance else { return }
            self.currentUtterance = nil
            self.isSpeaking = false
            if let continuation = self.activeContinuation {
                self.activeContinuation = nil
                continuation.resume()
            }
            if let callback = self.onFinishedCallback {
                self.onFinishedCallback = nil
                callback()
            }
        }
    }

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let box = UtteranceTransferBox(utterance)
        Task { @MainActor [weak self] in
            guard let self, self.currentUtterance === box.utterance else { return }
            self.currentUtterance = nil
            self.isSpeaking = false
            if let continuation = self.activeContinuation {
                self.activeContinuation = nil
                continuation.resume()
            }
            if let callback = self.onFinishedCallback {
                self.onFinishedCallback = nil
                callback()
            }
        }
    }
}
