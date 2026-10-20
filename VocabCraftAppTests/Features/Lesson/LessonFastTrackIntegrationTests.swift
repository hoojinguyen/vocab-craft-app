import CraftUIKit
import Foundation
import Testing
@testable import VocabCraftApp

@MainActor
@Suite("Lesson Fast-Track Integration Tests")
struct LessonFastTrackIntegrationTests {
    private func makeWord(id: Int64, lemma: String) -> TopicWordDTO {
        TopicWordDTO(
            id: id,
            stageId: "stage_daily_1",
            lemma: lemma,
            phonetic: "/\(lemma)/",
            pos: "noun",
            cefrLevel: "A1",
            definitionVi: "Nghĩa tiếng Việt",
            definitionEn: "English definition",
            exampleEn: "Example sentence with \(lemma).",
            exampleVi: "Câu ví dụ với \(lemma)."
        )
    }

    private func makeSampleWords() -> [TopicWordDTO] {
        [
            makeWord(id: 1, lemma: "apple"),
            makeWord(id: 2, lemma: "banana")
        ]
    }

    @Test("Failed fast-track checkpoint (<85%) leaves checkpoint and stages uncompleted")
    func testFailedFastTrackLeavesCheckpointAndStagesUncompleted() async throws {
        let mockDataSource = MockVocabularyDataSource()
        let mockStageRepo = MockStageProgressRepository()
        let mockProgressRepo = MockUserProgressRepository()
        let fastTrackUseCase = FastTrackUnitUseCase(
            dataSource: mockDataSource,
            stageRepo: mockStageRepo,
            progressRepo: mockProgressRepo
        )
        let mockCompleteLessonUseCase = MockCompleteLessonUseCase()

        let vm = LessonLearningViewModel(
            stageId: "checkpoint_deck_daily",
            deckId: "deck_daily",
            words: makeSampleWords(),
            isFastTrack: true,
            completeLessonUseCase: mockCompleteLessonUseCase,
            ttsService: MockTextToSpeechService(),
            soundEffectService: MockSoundEffectService(),
            speechEngine: MockResilientReflexSpeechEngine()
        )

        // Simulate failing answers (<85% accuracy)
        while !vm.isSummaryStep {
            if let item = vm.currentExerciseItem {
                vm.submitAnswer(isCorrect: false, for: item)
            }
            vm.advanceStep()
        }

        #expect(vm.isSummaryStep == true)
        #expect(vm.summary != nil)
        let accuracy = vm.summary?.accuracyFraction ?? 1.0
        #expect(accuracy < 0.85)

        // 1. Verify LessonLearningViewModel finishLesson did NOT invoke completeLessonUseCase
        #expect(mockCompleteLessonUseCase.executeCallCount == 0)
        #expect(vm.completionTask == nil)
        #expect(vm.isCompleted == false)
        let awaitResult = try await vm.awaitCompletion()
        #expect(awaitResult == nil)

        // 2. Simulate HomepageView fast-track evaluation on the result
        let result = try await fastTrackUseCase.execute(deckId: "deck_daily", scorePercentage: accuracy)
        #expect(result.isSuccess == false)

        // 3. Verify repository state: no stages were completed or saved
        #expect(mockStageRepo.savedStages.isEmpty)
        #expect(mockProgressRepo.recordedBatchCalls.isEmpty)

        let checkpointProgress = try await mockStageRepo.fetchStageProgress(stageId: "checkpoint_deck_daily")
        #expect(checkpointProgress == nil)
    }

    @Test("Successful fast-track checkpoint (>=85%) completes stages via FastTrackUnitUseCase")
    func testSuccessfulFastTrackMarksCheckpointAndAllStagesCompleted() async throws {
        let mockDataSource = MockVocabularyDataSource()
        let mockStageRepo = MockStageProgressRepository()
        let mockProgressRepo = MockUserProgressRepository()
        let fastTrackUseCase = FastTrackUnitUseCase(
            dataSource: mockDataSource,
            stageRepo: mockStageRepo,
            progressRepo: mockProgressRepo
        )
        let mockCompleteLessonUseCase = MockCompleteLessonUseCase()

        let vm = LessonLearningViewModel(
            stageId: "checkpoint_deck_daily",
            deckId: "deck_daily",
            words: makeSampleWords(),
            isFastTrack: true,
            completeLessonUseCase: mockCompleteLessonUseCase,
            ttsService: MockTextToSpeechService(),
            soundEffectService: MockSoundEffectService(),
            speechEngine: MockResilientReflexSpeechEngine()
        )

        // Simulate 100% correct answers
        while !vm.isSummaryStep {
            if let item = vm.currentExerciseItem {
                vm.submitAnswer(isCorrect: true, for: item)
            }
            vm.advanceStep()
        }

        #expect(vm.isSummaryStep == true)
        #expect(vm.summary != nil)
        let accuracy = vm.summary?.accuracyFraction ?? 0.0
        #expect(accuracy >= 0.85)

        // 1. LessonLearningViewModel finishLesson skipped completeLessonUseCase
        #expect(mockCompleteLessonUseCase.executeCallCount == 0)
        #expect(vm.completionTask == nil)

        // 2. HomepageView runs fastTrackUnitUseCase on passing score
        let result = try await fastTrackUseCase.execute(deckId: "deck_daily", scorePercentage: accuracy)
        #expect(result.isSuccess == true)

        // 3. Verify repository state: checkpoint and subtopic stages completed
        #expect(mockStageRepo.savedStages.contains(where: { $0.stageId == "checkpoint_deck_daily" && $0.isCompleted }))
        #expect(mockProgressRepo.recordedBatchCalls.count >= 1)
    }

    @Test("Standard lesson (isFastTrack == false) persists completion normally")
    func testStandardLessonPersistsViaCompleteLessonUseCase() async throws {
        let mockCompleteLessonUseCase = MockCompleteLessonUseCase()

        let vm = LessonLearningViewModel(
            stageId: "stage_daily_1",
            deckId: "deck_daily",
            words: makeSampleWords(),
            isFastTrack: false,
            completeLessonUseCase: mockCompleteLessonUseCase,
            ttsService: MockTextToSpeechService(),
            soundEffectService: MockSoundEffectService(),
            speechEngine: MockResilientReflexSpeechEngine()
        )

        while !vm.isSummaryStep {
            if let item = vm.currentExerciseItem {
                vm.submitAnswer(isCorrect: true, for: item)
            }
            vm.advanceStep()
        }

        #expect(vm.isSummaryStep == true)
        #expect(vm.completionTask != nil)

        let completionResult = try await vm.awaitCompletion()
        #expect(completionResult != nil)
        #expect(mockCompleteLessonUseCase.executeCallCount == 1)
        #expect(vm.isCompleted == true)
    }
}
