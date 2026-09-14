import AVFoundation
import Foundation
import SpeechKit
import Testing
@testable import VocabCraftApp

@Suite("Conversation playback")
@MainActor
struct ConversationPlaybackTests {
    @Test("successful synthesizer completion via delegate is distinct from failure")
    func successfulCompletionViaDelegate() async {
        let coordinator = PlaybackTestAudioCoordinator()
        let synthesizer = MockTextToSpeechSynthesizer()
        let service = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            synthesizer: synthesizer
        )

        let task = Task { @MainActor in
            await service.speakWithCompletion(
                text: "A reliable test build by tomorrow afternoon.",
                rate: 1,
                locale: "en-US"
            )
        }

        // Wait until speech has started and utterance is registered
        for _ in 0..<50 {
            if synthesizer.spokenUtterances.count == 1 { break }
            await Task.yield()
        }

        #expect(synthesizer.spokenUtterances.count == 1)
        #expect(service.isSpeaking == true)
        #expect(await coordinator.activeLeaseCount == 1)

        synthesizer.finishUtterance()

        let result = await task.value
        #expect(result == .finished)
        #expect(service.isSpeaking == false)
        #expect(await coordinator.activeLeaseCount == 0)
    }

    @Test("cancelled playback via stop resolves to cancelled and releases lease")
    func cancelledViaStop() async {
        let coordinator = PlaybackTestAudioCoordinator()
        let synthesizer = MockTextToSpeechSynthesizer()
        let service = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            synthesizer: synthesizer
        )

        let task = Task { @MainActor in
            await service.speakWithCompletion(
                text: "Hold on while this is cancelled.",
                rate: 1,
                locale: "en-US"
            )
        }

        for _ in 0..<50 {
            if synthesizer.spokenUtterances.count == 1 { break }
            await Task.yield()
        }

        #expect(service.isSpeaking == true)
        #expect(await coordinator.activeLeaseCount == 1)

        service.stop()

        let result = await task.value
        #expect(result == .cancelled)
        #expect(service.isSpeaking == false)
        #expect(await coordinator.activeLeaseCount == 0)
    }

    @Test("cancelled playback via synthesizer didCancel resolves to cancelled")
    func cancelledViaSynthesizerDelegate() async {
        let coordinator = PlaybackTestAudioCoordinator()
        let synthesizer = MockTextToSpeechSynthesizer()
        let service = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            synthesizer: synthesizer
        )

        let task = Task { @MainActor in
            await service.speakWithCompletion(
                text: "Interrupted by system route change.",
                rate: 1,
                locale: "en-US"
            )
        }

        for _ in 0..<50 {
            if synthesizer.spokenUtterances.count == 1 { break }
            await Task.yield()
        }

        synthesizer.cancelUtterance()

        let result = await task.value
        #expect(result == .cancelled)
        #expect(service.isSpeaking == false)
        #expect(await coordinator.activeLeaseCount == 0)
    }

    @Test("audio lease failure cannot look like successful speech")
    func leaseFailure() async {
        let coordinator = PlaybackTestAudioCoordinator(shouldFail: true)
        let synthesizer = MockTextToSpeechSynthesizer()
        let service = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            synthesizer: synthesizer
        )

        let result = await service.speakWithCompletion(
            text: "A reliable test build by tomorrow afternoon.",
            rate: 1,
            locale: "en-US"
        )

        #expect(result == .failed)
        #expect(synthesizer.spokenUtterances.isEmpty)
        #expect(service.isSpeaking == false)
        #expect(await coordinator.activeLeaseCount == 0)
    }

    @Test("timeout returns failed and cleans up lease without hanging")
    func timeoutReturnsFailed() async {
        let coordinator = PlaybackTestAudioCoordinator()
        let synthesizer = MockTextToSpeechSynthesizer()
        let service = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            synthesizer: synthesizer
        )
        service.playbackTimeout = .milliseconds(50)

        let result = await service.speakWithCompletion(
            text: "This utterance will never finish naturally.",
            rate: 1,
            locale: "en-US"
        )

        #expect(result == .failed)
        #expect(synthesizer.spokenUtterances.count == 1)
        #expect(synthesizer.stopSpeakingCallCount >= 1)
        #expect(service.isSpeaking == false)
        #expect(await coordinator.activeLeaseCount == 0)
    }

    @Test("stale delegate callbacks do not resolve active continuation or release lease")
    func staleDelegateCallbacksIgnored() async {
        let coordinator = PlaybackTestAudioCoordinator()
        let synthesizer = MockTextToSpeechSynthesizer()
        let service = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            synthesizer: synthesizer
        )

        let task = Task { @MainActor in
            await service.speakWithCompletion(
                text: "Current active text.",
                rate: 1,
                locale: "en-US"
            )
        }

        for _ in 0..<50 {
            if synthesizer.spokenUtterances.count == 1 { break }
            await Task.yield()
        }

        guard let activeUtterance = synthesizer.spokenUtterances.first else {
            Issue.record("Active utterance not registered")
            return
        }

        let staleUtterance = AVSpeechUtterance(string: "Stale text")

        // Fire didCancel with a stale utterance: must be ignored
        synthesizer.cancelUtterance(staleUtterance)
        await Task.yield()

        #expect(service.isSpeaking == true)
        #expect(await coordinator.activeLeaseCount == 1)

        // Fire didFinish with a stale utterance: must be ignored
        synthesizer.finishUtterance(staleUtterance)
        await Task.yield()

        #expect(service.isSpeaking == true)
        #expect(await coordinator.activeLeaseCount == 1)

        // Now fire didFinish with the actual active utterance
        synthesizer.finishUtterance(activeUtterance)

        let result = await task.value
        #expect(result == .finished)
        #expect(service.isSpeaking == false)
        #expect(await coordinator.activeLeaseCount == 0)
    }

    @Test("duplicate didFinish callbacks resolve continuation once without crashing")
    func duplicateDelegateCallbacksHandled() async {
        let coordinator = PlaybackTestAudioCoordinator()
        let synthesizer = MockTextToSpeechSynthesizer()
        let service = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            synthesizer: synthesizer
        )

        let task = Task { @MainActor in
            await service.speakWithCompletion(
                text: "Duplicated completion test.",
                rate: 1,
                locale: "en-US"
            )
        }

        for _ in 0..<50 {
            if synthesizer.spokenUtterances.count == 1 { break }
            await Task.yield()
        }

        guard let activeUtterance = synthesizer.spokenUtterances.first else {
            Issue.record("Active utterance not registered")
            return
        }

        // Fire didFinish twice in a row
        synthesizer.finishUtterance(activeUtterance)
        synthesizer.finishUtterance(activeUtterance)

        let result = await task.value
        #expect(result == .finished)
        #expect(service.isSpeaking == false)
        #expect(await coordinator.activeLeaseCount == 0)
    }

    @Test("empty text returns failed immediately without acquiring lease")
    func emptyTextReturnsFailed() async {
        let coordinator = PlaybackTestAudioCoordinator()
        let synthesizer = MockTextToSpeechSynthesizer()
        let service = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            synthesizer: synthesizer
        )

        let result = await service.speakWithCompletion(text: "    ", rate: 1, locale: "en-US")
        #expect(result == .failed)
        #expect(synthesizer.spokenUtterances.isEmpty)
        #expect(await coordinator.activeLeaseCount == 0)
    }

    @Test("TextToSpeechConversationPlayer translates outcomes and teardown properly")
    func playerAdapterTranslatesOutcomes() async {
        let coordinator = PlaybackTestAudioCoordinator()
        let synthesizer = MockTextToSpeechSynthesizer()
        let service = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            synthesizer: synthesizer
        )
        let player = TextToSpeechConversationPlayer(service: service)

        // 1. Finished outcome
        let task1 = Task { @MainActor in
            await player.play(text: "First line", locale: "en-US")
        }
        for _ in 0..<50 {
            if synthesizer.spokenUtterances.count == 1 { break }
            await Task.yield()
        }
        synthesizer.finishUtterance()
        let result1 = await task1.value
        #expect(result1 == .finished)
        await player.teardown()
        #expect(await coordinator.activeLeaseCount == 0)

        // 2. Cancelled outcome via player.stop()
        let task2 = Task { @MainActor in
            await player.play(text: "Second line", locale: "en-US")
        }
        for _ in 0..<50 {
            if synthesizer.spokenUtterances.count == 2 { break }
            await Task.yield()
        }
        player.stop()
        let result2 = await task2.value
        #expect(result2 == .cancelled)
        await player.teardown()
        #expect(await coordinator.activeLeaseCount == 0)
    }

    @Test("SpeechKitConversationRecognizer delegates lifecycle and maps errors")
    func recognizerDelegatesAndMapsErrors() async throws {
        let mockEngine = MockConversationRecognitionEngine()
        let recognizer = SpeechKitConversationRecognizer(engine: mockEngine)

        // 1. Authorization
        mockEngine.requestAuthResult = true
        let authorized = await recognizer.requestAuthorization()
        #expect(authorized == true)

        // 2. Start & callbacks
        var receivedPartial = ""
        var receivedFinal = ""
        var receivedError: ConversationRecognitionError?

        try recognizer.start(
            contextualPhrases: ["Target sentence", "hint1"],
            onPartial: { partial in receivedPartial = partial },
            onFinal: { final in receivedFinal = final },
            onError: { error in receivedError = error }
        )

        #expect(mockEngine.startCallCount == 1)
        #expect(mockEngine.passedContextualPhrases == ["Target sentence", "hint1"])

        mockEngine.onPartialHandler?("Target")
        // Allow MainActor dispatch
        for _ in 0..<10 {
            if receivedPartial == "Target" { break }
            await Task.yield()
        }
        #expect(receivedPartial == "Target")

        mockEngine.onFinalHandler?("Target sentence")
        for _ in 0..<10 {
            if receivedFinal == "Target sentence" { break }
            await Task.yield()
        }
        #expect(receivedFinal == "Target sentence")

        // 3. Error mapping: recognizerUnavailable -> .unavailable
        mockEngine.onErrorHandler?(SpeechKitError.recognizerUnavailable)
        for _ in 0..<10 {
            if receivedError == .unavailable { break }
            await Task.yield()
        }
        #expect(receivedError == .unavailable)

        // Generic error -> .failed
        struct GenericError: Error {}
        mockEngine.onErrorHandler?(GenericError())
        for _ in 0..<10 {
            if receivedError == .failed { break }
            await Task.yield()
        }
        #expect(receivedError == .failed)

        // 4. Stop
        recognizer.stop()
        #expect(mockEngine.stopCallCount == 1)
    }
}

// MARK: - Test Helpers

private actor PlaybackTestAudioCoordinator: AudioSessionCoordinating {
    enum Failure: Error { case unavailable }
    private(set) var activeLeases: [UUID: AudioSessionLease] = [:]
    let shouldFail: Bool

    init(shouldFail: Bool = false) { self.shouldFail = shouldFail }

    func acquire(_ intent: AudioSessionIntent) async throws -> AudioSessionLease {
        if shouldFail { throw Failure.unavailable }
        let lease = AudioSessionLease(generation: 1, intent: intent)
        activeLeases[lease.id] = lease
        return lease
    }

    func release(_ lease: AudioSessionLease) async {
        activeLeases.removeValue(forKey: lease.id)
    }

    var activeLeaseCount: Int {
        activeLeases.count
    }
}

@MainActor
private final class MockTextToSpeechSynthesizer: TextToSpeechSynthesizing {
    weak var delegate: (any AVSpeechSynthesizerDelegate)?
    var isSpeaking: Bool = false
    var spokenUtterances: [AVSpeechUtterance] = []
    var stopSpeakingCallCount = 0
    private let dummySynthesizer = AVSpeechSynthesizer()

    func speak(_ utterance: AVSpeechUtterance) {
        isSpeaking = true
        spokenUtterances.append(utterance)
    }

    func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool {
        stopSpeakingCallCount += 1
        isSpeaking = false
        return true
    }

    func finishUtterance(_ utterance: AVSpeechUtterance? = nil) {
        isSpeaking = false
        guard let target = utterance ?? spokenUtterances.last else { return }
        delegate?.speechSynthesizer?(dummySynthesizer, didFinish: target)
    }

    func cancelUtterance(_ utterance: AVSpeechUtterance? = nil) {
        isSpeaking = false
        guard let target = utterance ?? spokenUtterances.last else { return }
        delegate?.speechSynthesizer?(dummySynthesizer, didCancel: target)
    }
}

private final class MockConversationRecognitionEngine: SpeechRecognitionEngineProtocol, @unchecked Sendable {
    var isRecording: Bool = false
    var requestAuthResult: Bool = true
    var passedContextualPhrases: [String] = []
    var onPartialHandler: (@Sendable (String) -> Void)?
    var onFinalHandler: (@Sendable (String) -> Void)?
    var onErrorHandler: (@Sendable (Error) -> Void)?
    var startCallCount = 0
    var stopCallCount = 0
    var errorToThrowOnStart: Error?

    func requestAuthorization(completion: @escaping @Sendable (Bool) -> Void) {
        completion(requestAuthResult)
    }

    func start(
        contextualPhrases: [String],
        onPartialResult: @escaping @Sendable (String) -> Void,
        onFinalResult: @escaping @Sendable (String) -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) throws {
        if let error = errorToThrowOnStart {
            throw error
        }
        startCallCount += 1
        isRecording = true
        passedContextualPhrases = contextualPhrases
        onPartialHandler = onPartialResult
        onFinalHandler = onFinalResult
        onErrorHandler = onError
    }

    func stop() {
        stopCallCount += 1
        isRecording = false
    }
}
