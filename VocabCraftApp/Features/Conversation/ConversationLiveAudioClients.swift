import Foundation
import SpeechKit

@MainActor
public final class TextToSpeechConversationPlayer: ConversationSpeechPlaying {
    private let service: TextToSpeechService

    public init(service: TextToSpeechService) {
        self.service = service
    }

    public func play(text: String, locale: String) async -> ConversationPlaybackResult {
        switch await service.speakWithCompletion(text: text, rate: 1, locale: locale) {
        case .finished: .finished
        case .cancelled: .cancelled
        case .failed: .failed
        }
    }

    public func stop() {
        service.stop()
    }

    public func teardown() async {
        await service.playbackReleaseTask?.value
    }
}

@MainActor
public final class SpeechKitConversationRecognizer: ConversationSpeechRecognizing {
    private let engine: any SpeechRecognitionEngineProtocol

    public init(
        engine: any SpeechRecognitionEngineProtocol = SpeechRecognitionEngine(managesAudioSession: false)
    ) {
        self.engine = engine
    }

    public func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            engine.requestAuthorization { isAuthorized in
                continuation.resume(returning: isAuthorized)
            }
        }
    }

    public func start(
        contextualPhrases: [String],
        onPartial: @escaping @MainActor @Sendable (String) -> Void,
        onFinal: @escaping @MainActor @Sendable (String) -> Void,
        onError: @escaping @MainActor @Sendable (ConversationRecognitionError) -> Void
    ) throws {
        do {
            try engine.start(
                contextualPhrases: contextualPhrases,
                onPartialResult: { transcript in
                    Task { @MainActor in onPartial(transcript) }
                },
                onFinalResult: { transcript in
                    Task { @MainActor in onFinal(transcript) }
                },
                onError: { error in
                    let result: ConversationRecognitionError
                    if let speechError = error as? SpeechKitError,
                       speechError == .recognizerUnavailable {
                        result = .unavailable
                    } else {
                        result = .failed
                    }
                    Task { @MainActor in onError(result) }
                }
            )
        } catch let speechError as SpeechKitError where speechError == .recognizerUnavailable {
            throw ConversationRecognitionError.unavailable
        } catch {
            throw ConversationRecognitionError.failed
        }
    }

    public func stop() {
        engine.stop()
    }
}
