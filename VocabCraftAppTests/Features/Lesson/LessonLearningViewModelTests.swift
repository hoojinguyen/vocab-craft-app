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
    func testCorrectAnswerSubmission() {
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

        let exerciseItem = LessonExerciseItem(
            id: "mc-1",
            word: words[0],
            assignedMode: .multipleChoice,
            options: []
        )

        vm.submitAnswer(isCorrect: true, for: exerciseItem)

        #expect(vm.isFeedbackPresented)
        #expect(vm.lastAttemptCorrect)
        #expect(vm.correctAnswers == 1)
        #expect(vm.totalAnswered == 1)
        #expect(vm.mistakeCount == 0)
    }

    @Test("Submitting an incorrect answer downgrades active mode and requeues")
    func testIncorrectAnswerRequeuing() {
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

        let initialStepCount = vm.steps.count
        let exerciseItem = LessonExerciseItem(
            id: "typing-1",
            word: words[0],
            assignedMode: .typing,
            options: []
        )

        vm.submitAnswer(isCorrect: false, for: exerciseItem)

        #expect(vm.isFeedbackPresented)
        #expect(!vm.lastAttemptCorrect)
        #expect(vm.mistakeCount == 1)
        #expect(vm.weakWordIds.contains(1))
        #expect(vm.steps.count == initialStepCount + 1)

        // Verify downgraded mode is multipleChoice
        if case .exercise(let retryItem) = vm.steps.last {
            #expect(retryItem.assignedMode == .multipleChoice)
            #expect(retryItem.isRequeued)
            #expect(retryItem.attemptCount == 2)
        } else {
            #expect(Bool(false), "Expected retry exercise step")
        }
    }

    @Test("Second failure on same word does not requeue endlessly (Max 1 retry)")
    func testMaxOneRetryRule() {
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

        let exerciseItem = LessonExerciseItem(
            id: "typing-1",
            word: words[0],
            assignedMode: .typing,
            options: []
        )

        // First attempt (fails -> requeues)
        vm.submitAnswer(isCorrect: false, for: exerciseItem)
        let stepCountAfterFirstFail = vm.steps.count

        vm.advanceStep()

        // Second attempt on same word
        let retryItem = LessonExerciseItem(
            id: "mc-retry-1",
            word: words[0],
            assignedMode: .multipleChoice,
            options: [],
            attemptCount: 2
        )
        vm.submitAnswer(isCorrect: false, for: retryItem)

        // Does NOT append another step
        #expect(vm.steps.count == stepCountAfterFirstFail)
        #expect(vm.weakWordIds.contains(1))
    }

    @Test("Requesting hint advances hintStage and eliminates wrong distractor")
    func testHintRequest() {
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

        let options = [
            ReflexBlitzOption(id: "opt-1", text: "apple", isCorrect: true),
            ReflexBlitzOption(id: "opt-2", text: "banana", isCorrect: false),
            ReflexBlitzOption(id: "opt-3", text: "orange", isCorrect: false)
        ]
        let exerciseItem = LessonExerciseItem(
            id: "mc-1",
            word: words[0],
            assignedMode: .multipleChoice,
            options: options
        )

        #expect(vm.hintStage == 0)
        #expect(vm.eliminatedOptionId == nil)

        vm.requestHint(for: exerciseItem)
        #expect(vm.hintStage == 1)

        vm.requestHint(for: exerciseItem)
        #expect(vm.hintStage == 2)
        #expect(vm.eliminatedOptionId == "opt-2" || vm.eliminatedOptionId == "opt-3")
    }

    @Test("Skipping exercise submits incorrect answer and triggers feedback")
    func testSkipExercise() {
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

        let exerciseItem = LessonExerciseItem(
            id: "typing-1",
            word: words[0],
            assignedMode: .typing,
            options: []
        )

        vm.skipExercise(for: exerciseItem)

        #expect(vm.isFeedbackPresented)
        #expect(!vm.lastAttemptCorrect)
        #expect(vm.mistakeCount == 1)
    }

    @Test("Completing all steps calculates 3 stars when 0 mistakes made")
    func testFinishLessonWithThreeStars() {
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

        // Advance through all steps
        while !vm.isCompleted {
            vm.advanceStep()
        }

        #expect(vm.isCompleted)
        #expect(vm.summary != nil)
        #expect(vm.summary?.stars == 3)
        #expect(vm.summary?.xpEarned == 25)
    }
}
#endif
