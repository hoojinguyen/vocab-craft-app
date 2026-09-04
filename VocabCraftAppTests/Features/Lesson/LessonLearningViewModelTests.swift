import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

final class MockCompleteLessonUseCase: CompleteLessonUseCaseProtocol, @unchecked Sendable {
    var executedStageId: String?
    var executedDeckId: String?
    var executedStars: Int?
    var executedWeakWordIds: [Int64]?
    var executedProgressFraction: Double?
    var shouldFail: Bool = false
    var executeCallCount: Int = 0

    func execute(
        stageId: String,
        deckId: String,
        stars: Int,
        weakWordIds: [Int64],
        progressFraction: Double
    ) async throws -> LessonCompletionResult {
        executeCallCount += 1
        if shouldFail {
            throw URLError(.timedOut)
        }
        self.executedStageId = stageId
        self.executedDeckId = deckId
        self.executedStars = stars
        self.executedWeakWordIds = weakWordIds
        self.executedProgressFraction = progressFraction
        return LessonCompletionResult(
            stageId: stageId,
            deckId: deckId,
            score: stars,
            xpEarned: 25,
            weakWordIds: weakWordIds,
            isUnitCheckpoint: false
        )
    }
}

#if canImport(Testing)
@Suite("Lesson Learning ViewModel Tests")
@MainActor
struct LessonLearningViewModelTests {
    private func makeSampleWords(count: Int = 2) -> [TopicWordDTO] {
        let all = [
            TopicWordDTO(
                id: 1,
                stageId: "stage_1",
                lemma: "apple",
                phonetic: "/ˈæp.əl/",
                pos: "noun",
                cefrLevel: "A1",
                definitionVi: "quả táo",
                definitionEn: "a round fruit",
                exampleEn: "She eats an apple.",
                exampleVi: "Cô ấy ăn một quả táo."
            ),
            TopicWordDTO(
                id: 2,
                stageId: "stage_1",
                lemma: "banana",
                phonetic: "/bəˈnɑː.nə/",
                pos: "noun",
                cefrLevel: "A1",
                definitionVi: "quả chuối",
                definitionEn: "a long yellow fruit",
                exampleEn: "Monkeys like bananas.",
                exampleVi: "Khỉ thích chuối."
            ),
            TopicWordDTO(
                id: 3,
                stageId: "stage_1",
                lemma: "cat",
                phonetic: "/kæt/",
                pos: "noun",
                cefrLevel: "A1",
                definitionVi: "con mèo",
                definitionEn: "a small domesticated carnivorous mammal",
                exampleEn: "The cat sleeps.",
                exampleVi: "Con mèo đang ngủ."
            ),
            TopicWordDTO(
                id: 4,
                stageId: "stage_1",
                lemma: "dog",
                phonetic: "/dɒɡ/",
                pos: "noun",
                cefrLevel: "A1",
                definitionVi: "con chó",
                definitionEn: "a domesticated carnivorous mammal",
                exampleEn: "The dog barks.",
                exampleVi: "Con chó sủa."
            )
        ]
        return Array(all.prefix(count))
    }

    @Test("Initializes with discovery and exercise steps")
    func testInitialization() {
        let words = makeSampleWords()
        let vm = LessonLearningViewModel(
            stageId: "stage_1",
            deckId: "deck_1",
            words: words,
            completeLessonUseCase: MockCompleteLessonUseCase(),
            ttsService: MockTextToSpeechService(),
            soundEffectService: MockSoundEffectService(),
            speechEngine: MockResilientReflexSpeechEngine()
        )

        #expect(vm.steps.count == 4) // 2 discovery + 2 exercises
        #expect(vm.currentStepIndex == 0)
        #expect(!vm.isCompleted)
        #expect(vm.progress == 0.0)
    }

    @Test("Submitting a correct answer updates stats and presents feedback")
    func testCorrectAnswerSubmission() throws {
        let words = makeSampleWords()
        let vm = LessonLearningViewModel(
            stageId: "stage_1",
            deckId: "deck_1",
            words: words,
            completeLessonUseCase: MockCompleteLessonUseCase(),
            ttsService: MockTextToSpeechService(),
            soundEffectService: MockSoundEffectService(),
            speechEngine: MockResilientReflexSpeechEngine()
        )

        while vm.currentExerciseItem == nil && !vm.isSummaryStep {
            vm.advanceStep()
        }

        let exerciseItem = try #require(vm.currentExerciseItem)
        vm.submitAnswer(isCorrect: true, for: exerciseItem)

        #expect(vm.isFeedbackPresented)
        #expect(vm.lastAttemptCorrect)
        #expect(vm.correctAnswers == 1)
        #expect(vm.totalAnswered == 1)
        #expect(vm.mistakeCount == 0)
    }

    @Test("Submitting an incorrect answer downgrades active mode and requeues")
    func testIncorrectAnswerRequeuing() throws {
        let words = makeSampleWords()
        let vm = LessonLearningViewModel(
            stageId: "stage_1",
            deckId: "deck_1",
            words: words,
            completeLessonUseCase: MockCompleteLessonUseCase(),
            ttsService: MockTextToSpeechService(),
            soundEffectService: MockSoundEffectService(),
            speechEngine: MockResilientReflexSpeechEngine()
        )

        while vm.currentExerciseItem == nil && !vm.isSummaryStep {
            vm.advanceStep()
        }

        let initialStepCount = vm.steps.count
        let exerciseItem = try #require(vm.currentExerciseItem)

        vm.submitAnswer(isCorrect: false, for: exerciseItem)

        #expect(vm.isFeedbackPresented)
        #expect(!vm.lastAttemptCorrect)
        #expect(vm.mistakeCount == 1)
        #expect(vm.weakWordIds.contains(exerciseItem.word.id))
        #expect(vm.steps.count == initialStepCount + 1)

        // Verify downgraded mode and requeued item
        if case .exercise(let retryItem) = vm.steps.last {
            #expect(retryItem.word.id == exerciseItem.word.id)
            #expect(retryItem.isRequeued)
            #expect(retryItem.attemptCount == 2)
            #expect(retryItem.assignedMode == .multipleChoice)
        } else {
            #expect(Bool(false), "Expected retry exercise step")
        }
    }

    @Test("Second failure on same word does not requeue endlessly (Max 1 retry)")
    func testMaxOneRetryRule() throws {
        let words = makeSampleWords()
        let vm = LessonLearningViewModel(
            stageId: "stage_1",
            deckId: "deck_1",
            words: words,
            completeLessonUseCase: MockCompleteLessonUseCase(),
            ttsService: MockTextToSpeechService(),
            soundEffectService: MockSoundEffectService(),
            speechEngine: MockResilientReflexSpeechEngine()
        )

        // Advance to first exercise
        while vm.currentExerciseItem == nil && !vm.isSummaryStep {
            vm.advanceStep()
        }

        let exerciseItem = try #require(vm.currentExerciseItem)

        // First attempt (fails -> requeues)
        vm.submitAnswer(isCorrect: false, for: exerciseItem)
        let stepCountAfterFirstFail = vm.steps.count

        // Advance until reaching the retry step for this word (attemptCount == 2)
        while (vm.currentExerciseItem?.attemptCount ?? 1) < 2 && !vm.isSummaryStep {
            vm.advanceStep()
        }

        let retryItem = try #require(vm.currentExerciseItem)
        #expect(retryItem.attemptCount == 2)
        #expect(retryItem.word.id == exerciseItem.word.id)

        // Second attempt on same word
        vm.submitAnswer(isCorrect: false, for: retryItem)

        // Does NOT append another step
        #expect(vm.steps.count == stepCountAfterFirstFail)
        #expect(vm.weakWordIds.contains(exerciseItem.word.id))
    }

    @Test("Requesting hint advances hintStage and eliminates wrong distractor")
    func testHintRequest() throws {
        let words = makeSampleWords()
        let vm = LessonLearningViewModel(
            stageId: "stage_1",
            deckId: "deck_1",
            words: words,
            completeLessonUseCase: MockCompleteLessonUseCase(),
            ttsService: MockTextToSpeechService(),
            soundEffectService: MockSoundEffectService(),
            speechEngine: MockResilientReflexSpeechEngine()
        )

        // Advance to first exercise with options
        while (vm.currentExerciseItem?.options.count ?? 0) < 2 && !vm.isSummaryStep {
            vm.advanceStep()
        }

        let exerciseItem = try #require(vm.currentExerciseItem)

        #expect(vm.hintStage == 0)
        #expect(vm.eliminatedOptionId == nil)

        vm.requestHint(for: exerciseItem)
        #expect(vm.hintStage == 1)

        vm.requestHint(for: exerciseItem)
        #expect(vm.hintStage == 2)
        #expect(vm.eliminatedOptionId != nil)
        let firstEliminated = vm.eliminatedOptionId

        // Extra hint request should cap at stage 2 for multiple choice and preserve eliminated option
        vm.requestHint(for: exerciseItem)
        #expect(vm.hintStage == 2)
        #expect(vm.eliminatedOptionId == firstEliminated)

        vm.requestHint(for: exerciseItem)
        #expect(vm.hintStage == 2)
        #expect(vm.eliminatedOptionId == firstEliminated)
    }

    @Test("Progress does not jump backwards when an exercise is requeued on error")
    func testProgressDoesNotJumpBackwardsOnRequeue() throws {
        let words = makeSampleWords()
        let vm = LessonLearningViewModel(
            stageId: "stage_1",
            deckId: "deck_1",
            words: words,
            completeLessonUseCase: MockCompleteLessonUseCase(),
            ttsService: MockTextToSpeechService(),
            soundEffectService: MockSoundEffectService(),
            speechEngine: MockResilientReflexSpeechEngine()
        )

        // Advance to first exercise step
        while vm.currentExerciseItem == nil && !vm.isSummaryStep {
            vm.advanceStep()
        }

        let item = try #require(vm.currentExerciseItem)
        let progressBefore = vm.progress
        vm.submitAnswer(isCorrect: false, for: item)
        let progressAfter = vm.progress
        #expect(progressAfter >= progressBefore, "Progress should never decrease upon requeue")
    }

    @Test("Skipping exercise submits incorrect answer and triggers feedback")
    func testSkipExercise() throws {
        let words = makeSampleWords()
        let vm = LessonLearningViewModel(
            stageId: "stage_1",
            deckId: "deck_1",
            words: words,
            completeLessonUseCase: MockCompleteLessonUseCase(),
            ttsService: MockTextToSpeechService(),
            soundEffectService: MockSoundEffectService(),
            speechEngine: MockResilientReflexSpeechEngine()
        )

        while vm.currentExerciseItem == nil && !vm.isSummaryStep {
            vm.advanceStep()
        }

        let exerciseItem = try #require(vm.currentExerciseItem)
        vm.skipExercise(for: exerciseItem)

        #expect(vm.isFeedbackPresented)
        #expect(!vm.lastAttemptCorrect)
        #expect(vm.mistakeCount == 1)
    }

    @Test("Completing all steps calculates 3 stars when 0 mistakes made and persists progress")
    func testFinishLessonWithThreeStars() async throws {
        let words = makeSampleWords()
        let completeUseCase = MockCompleteLessonUseCase()
        let vm = LessonLearningViewModel(
            stageId: "stage_1",
            deckId: "deck_1",
            words: words,
            completeLessonUseCase: completeUseCase,
            ttsService: MockTextToSpeechService(),
            soundEffectService: MockSoundEffectService(),
            speechEngine: MockResilientReflexSpeechEngine()
        )

        // Advance through all steps until summary is reached
        while !vm.isSummaryStep {
            vm.advanceStep()
        }

        #expect(vm.isSummaryStep)
        #expect(vm.summary != nil)
        #expect(vm.summary?.stars == 3)
        #expect(vm.summary?.xpEarned == 25)

        // Await and verify completeLessonUseCase execution
        let result = try await vm.awaitCompletion()
        #expect(result != nil)
        #expect(vm.isCompleted)
        #expect(completeUseCase.executedStars == 3)
        #expect(completeUseCase.executedStageId == "stage_1")
        #expect(completeUseCase.executedDeckId == "deck_1")
        #expect(completeUseCase.executedProgressFraction == 1.0)
        #expect(completeUseCase.executedWeakWordIds?.isEmpty == true)
    }

    @Test("Transient persistence failure allows retry via awaitCompletion or retryCompletion")
    func testPersistenceFailureAndRetry() async throws {
        let words = makeSampleWords()
        let completeUseCase = MockCompleteLessonUseCase()
        completeUseCase.shouldFail = true

        let vm = LessonLearningViewModel(
            stageId: "stage_1",
            deckId: "deck_1",
            words: words,
            completeLessonUseCase: completeUseCase,
            ttsService: MockTextToSpeechService(),
            soundEffectService: MockSoundEffectService(),
            speechEngine: MockResilientReflexSpeechEngine()
        )

        while !vm.isSummaryStep {
            vm.advanceStep()
        }

        // Initial completion fails
        do {
            _ = try await vm.awaitCompletion()
            #expect(Bool(false), "Expected persistence error")
        } catch {
            #expect(!vm.isCompleted)
            #expect(vm.persistenceError != nil)
        }

        // Fix transient error and retry
        completeUseCase.shouldFail = false
        let retryResult = try await vm.awaitCompletion()
        #expect(retryResult != nil)
        #expect(vm.isCompleted)
        #expect(vm.persistenceError == nil)
    }

    @Test("Retrying speaking restarts speech engine listening for current item")
    func testRetrySpeaking() throws {
        let words = makeSampleWords(count: 4)
        let speechEngine = MockResilientReflexSpeechEngine()
        let vm = LessonLearningViewModel(
            stageId: "stage_1",
            deckId: "deck_1",
            words: words,
            completeLessonUseCase: MockCompleteLessonUseCase(),
            ttsService: MockTextToSpeechService(),
            soundEffectService: MockSoundEffectService(),
            speechEngine: speechEngine
        )

        // Advance to speaking exercise
        while vm.currentExerciseItem?.assignedMode != .speaking && !vm.isSummaryStep {
            vm.advanceStep()
        }

        let exerciseItem = try #require(vm.currentExerciseItem)
        vm.startListeningForSpeaking(targetLemma: exerciseItem.word.lemma, item: exerciseItem)
        #expect(speechEngine.isSessionActive)

        // Simulate error leading to idle
        speechEngine.simulateError(URLError(.timedOut))
        #expect(vm.speechState == .idle)

        // Retry speaking
        vm.retrySpeaking(for: exerciseItem)
        #expect(speechEngine.isSessionActive)
        if case .listening = vm.speechState {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "Expected speechState to be listening after retry")
        }
    }

    @Test("Hint requests are capped at 2 for non-speaking exercises and 3 for speaking")
    func testHintCapPerMode() throws {
        let words = makeSampleWords(count: 4)
        let vm = LessonLearningViewModel(
            stageId: "stage_1",
            deckId: "deck_1",
            words: words,
            completeLessonUseCase: MockCompleteLessonUseCase(),
            ttsService: MockTextToSpeechService(),
            soundEffectService: MockSoundEffectService(),
            speechEngine: MockResilientReflexSpeechEngine()
        )

        // Advance to multiple choice exercise
        while vm.currentExerciseItem?.assignedMode != .multipleChoice && !vm.isSummaryStep {
            vm.advanceStep()
        }

        let mcItem = try #require(vm.currentExerciseItem)
        #expect(mcItem.assignedMode == .multipleChoice)

        vm.requestHint(for: mcItem)
        #expect(vm.hintStage == 1)

        vm.requestHint(for: mcItem)
        #expect(vm.hintStage == 2)

        // Third request should be ignored for multipleChoice
        vm.requestHint(for: mcItem)
        #expect(vm.hintStage == 2)

        // Advance to speaking exercise
        while vm.currentExerciseItem?.assignedMode != .speaking && !vm.isSummaryStep {
            vm.advanceStep()
        }

        let speakingItem = try #require(vm.currentExerciseItem)
        #expect(speakingItem.assignedMode == .speaking)

        vm.requestHint(for: speakingItem)
        #expect(vm.hintStage == 1)

        vm.requestHint(for: speakingItem)
        #expect(vm.hintStage == 2)

        vm.requestHint(for: speakingItem)
        #expect(vm.hintStage == 3)

        // Fourth request should be ignored for speaking
        vm.requestHint(for: speakingItem)
        #expect(vm.hintStage == 3)
    }

    @Test("retryCompletion reuses in-flight completionTask instead of spawning duplicate")
    func testRetryCompletionReusesInFlightTask() async throws {
        let words = makeSampleWords()
        let completeUseCase = MockCompleteLessonUseCase()
        let vm = LessonLearningViewModel(
            stageId: "stage_1",
            deckId: "deck_1",
            words: words,
            completeLessonUseCase: completeUseCase,
            ttsService: MockTextToSpeechService(),
            soundEffectService: MockSoundEffectService(),
            speechEngine: MockResilientReflexSpeechEngine()
        )

        while !vm.isSummaryStep {
            vm.advanceStep()
        }

        // Multiple concurrent calls to retryCompletion should reuse the task
        async let first = vm.retryCompletion()
        async let second = vm.retryCompletion()

        let (result1, result2) = try await (first, second)
        #expect(result1 != nil)
        #expect(result2 != nil)
        #expect(vm.isCompleted)
        #expect(completeUseCase.executeCallCount == 1)
    }

    @Test("Empty words session advances to summary and sets isSummaryStep to true")
    func testEmptyWordsSessionAdvancesToSummary() {
        let vm = LessonLearningViewModel(
            stageId: "stage_1",
            deckId: "deck_1",
            words: [],
            completeLessonUseCase: MockCompleteLessonUseCase(),
            ttsService: MockTextToSpeechService(),
            soundEffectService: MockSoundEffectService(),
            speechEngine: MockResilientReflexSpeechEngine()
        )

        #expect(!vm.isSummaryStep)
        vm.advanceStep()
        #expect(vm.isSummaryStep)
        #expect(vm.summary != nil)
    }

    @Test("Verify transition from speaking to non-speaking pauses rather than stops speech session")
    func testTransitionMaintainsSpeechSession() {
        let mockWord = TopicWordDTO(id: "w1", lemma: "apple", phonetics: "/ˈæp.əl/", meaningVi: "quả táo", exampleEn: "An apple a day", exampleVi: "Một quả táo mỗi ngày", partOfSpeech: "noun")
        let vm = LessonLearningViewModel(stageId: "stage_test", deckId: "deck_test", words: [mockWord])
        vm.startSpeechSession()
        #expect(vm.speechEngine.isSessionActive == true)
        vm.stopListeningForSpeaking()
        #expect(vm.speechEngine.isSessionActive == true)
        vm.cleanup()
        #expect(vm.speechEngine.isSessionActive == false)
    }

    @Test("Verify startListeningForSpeaking lazily prepares engine and resumes listening")
    func testStartListeningPreparesEngineAndResumesListening() throws {
        let words = makeSampleWords(count: 4)
        let speechEngine = MockResilientReflexSpeechEngine()
        let vm = LessonLearningViewModel(
            stageId: "stage_test",
            deckId: "deck_test",
            words: words,
            completeLessonUseCase: MockCompleteLessonUseCase(),
            ttsService: MockTextToSpeechService(),
            soundEffectService: MockSoundEffectService(),
            speechEngine: speechEngine
        )
        vm.startSpeechSession()
        #expect(speechEngine.isSessionActive == true)
        #expect(speechEngine.prepareEngineIfNeededCallCount == 0)

        // Advance to speaking exercise
        while vm.currentExerciseItem?.assignedMode != .speaking && !vm.isSummaryStep {
            vm.advanceStep()
        }

        let speakingItem = try #require(vm.currentExerciseItem)
        vm.startListeningForSpeaking(targetLemma: speakingItem.word.lemma, item: speakingItem)

        #expect(speechEngine.prepareEngineIfNeededCallCount == 1)
        #expect(speechEngine.resumeListeningCallCount == 1)

        vm.stopListeningForSpeaking()
        #expect(speechEngine.pauseListeningCallCount == 1)
        #expect(speechEngine.isSessionActive == true)

        vm.cleanup()
        #expect(speechEngine.isSessionActive == false)
        #expect(speechEngine.stopSessionCallCount == 1)
    }

    @Test("Verify finishLesson triggers cleanup and deactivates speech session")
    func testFinishLessonPerformsSpeechCleanup() {
        let words = makeSampleWords(count: 2)
        let speechEngine = MockResilientReflexSpeechEngine()
        let vm = LessonLearningViewModel(
            stageId: "stage_test",
            deckId: "deck_test",
            words: words,
            completeLessonUseCase: MockCompleteLessonUseCase(),
            ttsService: MockTextToSpeechService(),
            soundEffectService: MockSoundEffectService(),
            speechEngine: speechEngine
        )
        vm.startSpeechSession()
        #expect(speechEngine.isSessionActive == true)

        // Advance through all steps to complete lesson
        while !vm.isSummaryStep {
            if let item = vm.currentExerciseItem {
                vm.submitAnswer(isCorrect: true, for: item)
            }
            vm.advanceStep()
        }

        #expect(vm.isSummaryStep == true)
        #expect(speechEngine.isSessionActive == false)
        #expect(speechEngine.stopSessionCallCount >= 1)
    }

    @Test("Verify handleCantSpeakNow disables speaking, stops session, and converts all speaking items to multiple choice")
    func testHandleCantSpeakNowDisablesSpeakingAndConvertsExercises() throws {
        let words = makeSampleWords(count: 4)
        let speechEngine = MockResilientReflexSpeechEngine()
        let vm = LessonLearningViewModel(
            stageId: "stage_test",
            deckId: "deck_test",
            words: words,
            completeLessonUseCase: MockCompleteLessonUseCase(),
            ttsService: MockTextToSpeechService(),
            soundEffectService: MockSoundEffectService(),
            speechEngine: speechEngine
        )
        vm.startSpeechSession()
        #expect(speechEngine.isSessionActive == true)

        // Advance to speaking exercise
        while vm.currentExerciseItem?.assignedMode != .speaking && !vm.isSummaryStep {
            vm.advanceStep()
        }

        let speakingItem = try #require(vm.currentExerciseItem)
        #expect(speakingItem.assignedMode == .speaking)

        // Request hint in speaking mode to test state reset
        vm.requestHint(for: speakingItem)
        #expect(vm.hintStage >= 1)

        vm.handleCantSpeakNow(for: speakingItem)

        #expect(vm.isSpeakingDisabledForLesson == true)
        #expect(vm.hintStage == 0)
        #expect(vm.eliminatedOptionId == nil)
        #expect(speechEngine.isSessionActive == false)
        #expect(speechEngine.stopSessionCallCount >= 1)

        // Current item should now be converted to multiple choice
        let convertedItem = try #require(vm.currentExerciseItem)
        #expect(convertedItem.assignedMode == .multipleChoice)
        #expect(!convertedItem.options.isEmpty)
        #expect(convertedItem.word.id == speakingItem.word.id)

        // All subsequent steps with speaking mode should be converted to multiple choice
        for step in vm.steps {
            if case .exercise(let item) = step {
                #expect(item.assignedMode != .speaking)
            }
        }

        // Calling startSpeechSession after cantSpeakNow should be a no-op
        vm.startSpeechSession()
        #expect(speechEngine.isSessionActive == false)
    }

    @Test("Verify autoPronounceTask speaks vocabulary word after 250ms for non-listening exercise")
    func testAutoPronounceTaskSpeaksForNonListening() async throws {
        let words = makeSampleWords(count: 2)
        let tts = MockTextToSpeechService()
        let vm = LessonLearningViewModel(
            stageId: "stage_test",
            deckId: "deck_test",
            words: words,
            completeLessonUseCase: MockCompleteLessonUseCase(),
            ttsService: tts,
            soundEffectService: MockSoundEffectService(),
            speechEngine: MockResilientReflexSpeechEngine()
        )

        // Advance to non-listening exercise (multiple choice or typing)
        while (vm.currentExerciseItem == nil || vm.currentExerciseItem?.assignedMode == .listening) && !vm.isSummaryStep {
            vm.advanceStep()
        }

        let item = try #require(vm.currentExerciseItem)
        #expect(item.assignedMode != .listening)

        tts.speakCallCount = 0
        vm.submitAnswer(isCorrect: true, for: item)

        // Before task completes, speak should not have been called immediately
        #expect(tts.speakCallCount == 0)

        // Await the autoPronounceTask directly to guarantee completion regardless of runner thread load
        _ = await vm.autoPronounceTask?.value

        #expect(tts.speakCallCount == 1)
        #expect(tts.lastSpokenText == item.word.lemma)
    }

    @Test("Verify autoPronounceTask does not speak for listening exercises")
    func testAutoPronounceTaskDoesNotSpeakForListening() async throws {
        let words = makeSampleWords(count: 4)
        let tts = MockTextToSpeechService()
        let vm = LessonLearningViewModel(
            stageId: "stage_test",
            deckId: "deck_test",
            words: words,
            completeLessonUseCase: MockCompleteLessonUseCase(),
            ttsService: tts,
            soundEffectService: MockSoundEffectService(),
            speechEngine: MockResilientReflexSpeechEngine()
        )

        // Advance to listening exercise
        while vm.currentExerciseItem?.assignedMode != .listening && !vm.isSummaryStep {
            vm.advanceStep()
        }

        let item = try #require(vm.currentExerciseItem)
        #expect(item.assignedMode == .listening)

        tts.speakCallCount = 0
        vm.submitAnswer(isCorrect: true, for: item)

        #expect(vm.autoPronounceTask == nil)
        #expect(tts.speakCallCount == 0)
    }

    @Test("Verify advanceStep cancels in-flight autoPronounceTask")
    func testAdvanceStepCancelsAutoPronounceTask() async throws {
        let words = makeSampleWords(count: 4)
        let tts = MockTextToSpeechService()
        let vm = LessonLearningViewModel(
            stageId: "stage_test",
            deckId: "deck_test",
            words: words,
            completeLessonUseCase: MockCompleteLessonUseCase(),
            ttsService: tts,
            soundEffectService: MockSoundEffectService(),
            speechEngine: MockResilientReflexSpeechEngine()
        )

        // Advance to non-listening exercise
        while (vm.currentExerciseItem == nil || vm.currentExerciseItem?.assignedMode == .listening) && !vm.isSummaryStep {
            vm.advanceStep()
        }

        let item = try #require(vm.currentExerciseItem)
        tts.speakCallCount = 0
        vm.submitAnswer(isCorrect: true, for: item)

        let task = vm.autoPronounceTask
        #expect(task != nil)

        // Immediately advance step before 250ms delay
        vm.advanceStep()

        #expect(task?.isCancelled == true)
        _ = await task?.value

        #expect(tts.speakCallCount == 0)
    }

    @Test("Verify speechEngine onError does not terminate session and resets speechState to idle")
    func testSpeechEngineOnErrorKeepsSessionAlive() throws {
        let words = makeSampleWords(count: 4)
        let speechEngine = MockResilientReflexSpeechEngine()
        let vm = LessonLearningViewModel(
            stageId: "stage_test",
            deckId: "deck_test",
            words: words,
            completeLessonUseCase: MockCompleteLessonUseCase(),
            ttsService: MockTextToSpeechService(),
            soundEffectService: MockSoundEffectService(),
            speechEngine: speechEngine
        )
        vm.startSpeechSession()

        // Advance to speaking exercise
        while vm.currentExerciseItem?.assignedMode != .speaking && !vm.isSummaryStep {
            vm.advanceStep()
        }

        let speakingItem = try #require(vm.currentExerciseItem)
        vm.startListeningForSpeaking(targetLemma: speakingItem.word.lemma, item: speakingItem)
        #expect(speechEngine.isSessionActive == true)

        // Simulate error callback
        speechEngine.onError?(NSError(domain: "test.speech", code: 500))

        #expect(vm.speechState == .idle)
        #expect(speechEngine.isSessionActive == true)
        #expect(speechEngine.stopSessionCallCount == 0)
    }
}

extension TopicWordDTO {
    fileprivate init(
        id: String,
        lemma: String,
        phonetics: String,
        meaningVi: String,
        exampleEn: String,
        exampleVi: String,
        partOfSpeech: String
    ) {
        self.init(
            id: Int64(id.filter(\.isNumber)) ?? 1,
            stageId: "stage_test",
            lemma: lemma,
            phonetic: phonetics,
            pos: partOfSpeech,
            cefrLevel: "A1",
            definitionVi: meaningVi,
            definitionEn: "",
            exampleEn: exampleEn,
            exampleVi: exampleVi
        )
    }
}

extension LessonLearningViewModel {
    fileprivate convenience init(
        stageId: String,
        deckId: String,
        words: [TopicWordDTO]
    ) {
        self.init(
            stageId: stageId,
            deckId: deckId,
            words: words,
            completeLessonUseCase: MockCompleteLessonUseCase(),
            ttsService: MockTextToSpeechService(),
            soundEffectService: MockSoundEffectService(),
            speechEngine: MockResilientReflexSpeechEngine()
        )
    }
}
#endif
