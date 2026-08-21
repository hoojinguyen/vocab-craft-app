import SwiftUI
@testable import VocabCraftApp
import XCTest
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class StageChallengeViewModelTests: XCTestCase {
    func test_submitAnswer_advancesQuestionAndTracksScore() {
        let words = VocabularySampleDataset.words.filter { $0.stageId == "stage_daily_1" }.map {
            TopicWord(id: "w\($0.id)", english: $0.lemma, phonetic: $0.phonetic, vietnamese: $0.definitionVi, example: $0.exampleEn, partOfSpeech: $0.pos)
        }
        let stage = SubTopicStage(id: "stage_daily_1", deckId: "deck_daily", title: "Chặng 1", iconName: "heart", sortOrder: 1, state: .active, words: words)
        let sut = StageChallengeViewModel(stage: stage, completeUseCase: AppContainer.mock.completeStageChallengeUseCase)

        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.questions.count, words.count)
        XCTAssertFalse(sut.isCompleted)
        XCTAssertNil(sut.summary)

        let initialQuestion = sut.currentQuestion
        XCTAssertNotNil(initialQuestion)

        sut.submitAnswer(initialQuestion?.correctAnswer ?? "")
        XCTAssertTrue(sut.lastAnswerCorrect)
        XCTAssertEqual(sut.results.count, 1)
        XCTAssertEqual(sut.results.first?.isCorrect, true)
        XCTAssertEqual(sut.results.first?.wordId, initialQuestion?.wordId)
    }

    func test_submitAnswer_incorrect_recordsWeakWord() {
        let words = [
            TopicWord(id: "w101", english: "Resilience", phonetic: "/rɪˈzɪl.jəns/", vietnamese: "Khả năng phục hồi", example: "Her resilience is strong."),
            TopicWord(id: "w102", english: "Overwhelmed", phonetic: "/ˌoʊ.vɚˈwelmd/", vietnamese: "Bị ngợp", example: "He was overwhelmed.")
        ]
        let stage = SubTopicStage(id: "stage_test", deckId: "deck_test", title: "Test Stage", iconName: "star", sortOrder: 1, state: .active, words: words)
        let sut = StageChallengeViewModel(stage: stage, completeUseCase: AppContainer.mock.completeStageChallengeUseCase)

        XCTAssertEqual(sut.currentIndex, 0)
        sut.submitAnswer("Wrong Answer")
        XCTAssertFalse(sut.lastAnswerCorrect)
        XCTAssertEqual(sut.results.count, 1)
        XCTAssertEqual(sut.results.first?.isCorrect, false)
        XCTAssertEqual(sut.results.first?.wordId, 101)
    }

    func test_questionGeneration_createsOptionsWithCorrectAnswer() {
        let words = [
            TopicWord(id: "1", english: "A", phonetic: "/a/", vietnamese: "Nghĩa A"),
            TopicWord(id: "2", english: "B", phonetic: "/b/", vietnamese: "Nghĩa B"),
            TopicWord(id: "3", english: "C", phonetic: "/c/", vietnamese: "Nghĩa C"),
            TopicWord(id: "4", english: "D", phonetic: "/d/", vietnamese: "Nghĩa D")
        ]
        let questions = StageChallengeViewModel.generateQuestions(from: words)
        XCTAssertEqual(questions.count, 4)

        for question in questions {
            XCTAssertTrue(question.options.contains(question.correctAnswer))
            XCTAssertFalse(question.prompt.isEmpty)
            XCTAssertFalse(question.hintPhonetic.isEmpty)
        }
    }

    func test_completeStage_persistsResultsAndSetsSummary() async {
        let words = [
            TopicWord(id: "1", english: "A", phonetic: "/a/", vietnamese: "Nghĩa A"),
            TopicWord(id: "2", english: "B", phonetic: "/b/", vietnamese: "Nghĩa B")
        ]
        let stage = SubTopicStage(id: "stage_daily_1", deckId: "deck_daily", title: "Chặng 1", iconName: "heart", sortOrder: 1, state: .active, words: words)
        let sut = StageChallengeViewModel(stage: stage, completeUseCase: AppContainer.mock.completeStageChallengeUseCase)

        sut.submitAnswer(sut.questions[0].correctAnswer)
        sut.nextQuestion()
        sut.submitAnswer("Sai")

        await sut.completeStage()

        XCTAssertTrue(sut.isCompleted)
        XCTAssertNotNil(sut.summary)
        XCTAssertEqual(sut.summary?.totalQuestions, 2)
        XCTAssertEqual(sut.summary?.correctCount, 1)
        XCTAssertEqual(sut.summary?.xpEarned, 10)
        XCTAssertEqual(sut.summary?.weakWordIds, [2])
    }

    func test_restartQuiz_resetsAllState() {
        let words = [
            TopicWord(id: "1", english: "A", phonetic: "/a/", vietnamese: "Nghĩa A"),
            TopicWord(id: "2", english: "B", phonetic: "/b/", vietnamese: "Nghĩa B")
        ]
        let stage = SubTopicStage(id: "stage_daily_1", deckId: "deck_daily", title: "Chặng 1", iconName: "heart", sortOrder: 1, state: .active, words: words)
        let sut = StageChallengeViewModel(stage: stage, completeUseCase: AppContainer.mock.completeStageChallengeUseCase)

        sut.submitAnswer(sut.questions[0].correctAnswer)
        XCTAssertEqual(sut.results.count, 1)

        sut.restartQuiz()
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertTrue(sut.results.isEmpty)
        XCTAssertFalse(sut.isCompleted)
        XCTAssertNil(sut.summary)
        XCTAssertNil(sut.selectedAnswer)
        XCTAssertFalse(sut.isAnswerSubmitted)
    }

    func test_playAudio_invokesTTS() {
        let words = [
            TopicWord(id: "1", english: "Resilience", phonetic: "/rɪˈzɪl.jəns/", vietnamese: "Khả năng phục hồi")
        ]
        let stage = SubTopicStage(id: "stage_daily_1", deckId: "deck_daily", title: "Chặng 1", iconName: "heart", sortOrder: 1, state: .active, words: words)
        let mockTTS = MockTextToSpeechService()
        let sut = StageChallengeViewModel(stage: stage, completeUseCase: AppContainer.mock.completeStageChallengeUseCase, ttsService: mockTTS)

        sut.playAudio()
        XCTAssertEqual(mockTTS.lastSpokenText, "Resilience")

        sut.playWordAudio(text: "Overwhelmed")
        XCTAssertEqual(mockTTS.lastSpokenText, "Overwhelmed")
    }

    func test_stagePreviewSheet_instantiation() {
        let words = [
            TopicWord(id: "1", english: "Resilience", phonetic: "/rɪˈzɪl.jəns/", vietnamese: "Khả năng phục hồi", example: "Her resilience helped her.")
        ]
        let stage = SubTopicStage(id: "stage_daily_1", deckId: "deck_daily", title: "Chặng 1: Thói quen & Cảm xúc", iconName: "heart", sortOrder: 1, state: .active, words: words)
        var startCalled = false
        var bookmarkedWord: TopicWord?

        let sheet = StagePreviewSheet(
            stage: stage,
            onStartChallenge: { startCalled = true },
            onToggleBookmark: { word in bookmarkedWord = word },
            onClose: {}
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: sheet)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(sheet)
        #endif

        XCTAssertFalse(startCalled)
        XCTAssertNil(bookmarkedWord)
    }

    func test_stageChallengeView_instantiation() {
        let words = [
            TopicWord(id: "1", english: "Resilience", phonetic: "/rɪˈzɪl.jəns/", vietnamese: "Khả năng phục hồi", example: "Her resilience helped her.")
        ]
        let stage = SubTopicStage(id: "stage_daily_1", deckId: "deck_daily", title: "Chặng 1", iconName: "heart", sortOrder: 1, state: .active, words: words)
        let vm = StageChallengeViewModel(stage: stage, completeUseCase: AppContainer.mock.completeStageChallengeUseCase)

        let view = StageChallengeView(
            viewModel: vm,
            onClose: {},
            onCompleted: { _ in }
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif
    }

    func test_stageSummarySheet_instantiation() {
        let summary = StageCompletionSummary(
            stageId: "stage_daily_1",
            totalQuestions: 7,
            correctCount: 6,
            xpEarned: 60,
            weakWordIds: [2]
        )
        var finishCalled = false
        var restartCalled = false

        let sheet = StageSummarySheet(
            summary: summary,
            onFinish: { finishCalled = true },
            onRestart: { restartCalled = true }
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: sheet)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(sheet)
        #endif

        XCTAssertFalse(finishCalled)
        XCTAssertFalse(restartCalled)
    }
}
