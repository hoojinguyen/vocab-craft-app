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

    func execute(
        stageId: String,
        deckId: String,
        stars: Int,
        weakWordIds: [Int64],
        progressFraction: Double
    ) async throws -> LessonCompletionResult {
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
    private func makeSampleWords() -> [TopicWordDTO] {
        [
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
            )
        ]
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

        while vm.currentExerciseItem == nil && !vm.isCompleted {
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

        while vm.currentExerciseItem == nil && !vm.isCompleted {
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
        while vm.currentExerciseItem == nil && !vm.isCompleted {
            vm.advanceStep()
        }

        let exerciseItem = try #require(vm.currentExerciseItem)

        // First attempt (fails -> requeues)
        vm.submitAnswer(isCorrect: false, for: exerciseItem)
        let stepCountAfterFirstFail = vm.steps.count

        // Advance until reaching the retry step for this word (attemptCount == 2)
        while (vm.currentExerciseItem?.attemptCount ?? 1) < 2 && !vm.isCompleted {
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
        while (vm.currentExerciseItem?.options.count ?? 0) < 2 && !vm.isCompleted {
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

        // Extra hint request should cap at stage 3 and preserve eliminated option
        vm.requestHint(for: exerciseItem)
        #expect(vm.hintStage == 3)
        #expect(vm.eliminatedOptionId == firstEliminated)

        vm.requestHint(for: exerciseItem)
        #expect(vm.hintStage == 3)
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
        while vm.currentExerciseItem == nil && !vm.isCompleted {
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

        while vm.currentExerciseItem == nil && !vm.isCompleted {
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
}
#endif
