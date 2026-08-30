import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@MainActor
@Suite("ReflexBlitzViewModel Listening Tests")
struct ReflexBlitzViewModelListeningTests {
    @Test("Simulates listening mode elapsed time and verifies hint progression")
    func testListeningHintProgression() {
        let mockTTS = MockTextToSpeechService()
        let vm = ReflexBlitzViewModel(
            words: ReflexBlitzWordItem.defaultStarterWords,
            continuousSpeechService: MockContinuousReflexSpeechService(),
            ttsService: mockTTS,
            evaluateSRSUseCase: MockEvaluateSRSUseCase(),
            soundEffectService: MockSoundEffectService()
        )
        vm.startDrillSession(mode: .listening)

        #expect(vm.hintStage == 0)

        vm.simulateElapsedTime(ms: 1800)
        #expect(vm.hintStage == 1)

        vm.simulateElapsedTime(ms: 3000)
        #expect(vm.hintStage == 2)
    }

    @Test("Verifies answer submission in listening mode does not auto-speak on review flip")
    func testListeningAnswerSubmissionMuteReview() {
        let mockTTS = MockTextToSpeechService()
        let vm = ReflexBlitzViewModel(
            words: ReflexBlitzWordItem.defaultStarterWords,
            continuousSpeechService: MockContinuousReflexSpeechService(),
            ttsService: mockTTS,
            evaluateSRSUseCase: MockEvaluateSRSUseCase(),
            soundEffectService: MockSoundEffectService()
        )
        vm.startDrillSession(mode: .listening)
        let initialSpeakCount = mockTTS.speakCallCount

        if let option = vm.currentOptions.first {
            vm.selectOption(option)
        }

        // Should not have spoken again during selectOption review flip
        #expect(mockTTS.speakCallCount == initialSpeakCount)
    }

    @Test("Verifies speech rate is 1.0 on load and speakLemma in listening mode")
    func testListeningSpeechRateNormalization() {
        let mockTTS = MockTextToSpeechService()
        let vm = ReflexBlitzViewModel(
            words: ReflexBlitzWordItem.defaultStarterWords,
            continuousSpeechService: MockContinuousReflexSpeechService(),
            ttsService: mockTTS,
            evaluateSRSUseCase: MockEvaluateSRSUseCase(),
            soundEffectService: MockSoundEffectService()
        )
        vm.startDrillSession(mode: .listening)

        #expect(mockTTS.lastSpokenRate == 1.0)

        vm.speakLemma("test")
        #expect(mockTTS.lastSpokenRate == 1.0)
    }
}
#endif
