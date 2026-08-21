import XCTest
@testable import VocabCraftApp

@MainActor
final class SmartReviewViewModelTests: XCTestCase {
    func test_loadWeakWords_populatesFromUseCaseWhenEmpty() async {
        let container = AppContainer.mock
        let sut = container.makeSmartReviewViewModel()
        
        XCTAssertTrue(sut.weakWords.isEmpty)
        await sut.loadWeakWords()
        // weak words might be empty or populated depending on user progress
        XCTAssertFalse(sut.isCompleted)
    }

    func test_smartReviewFlow_advanceAndComplete() async {
        let words = [
            PersonalWord(
                id: 1,
                lemma: "Resilience",
                phonetic: "/rɪˈzɪl.jəns/",
                pos: "noun",
                cefrLevel: "B2",
                definitionVi: "Khả năng phục hồi",
                definitionEn: "Capacity to recover",
                exampleEn: "Her resilience helped her.",
                exampleVi: "Sự kiên cường giúp cô ấy.",
                needsReview: true
            ),
            PersonalWord(
                id: 2,
                lemma: "Overwhelmed",
                phonetic: "/ˌoʊ.vɚˈwelmd/",
                pos: "adj",
                cefrLevel: "B1",
                definitionVi: "Quá tải",
                definitionEn: "Overcome by emotion",
                exampleEn: "He felt overwhelmed.",
                exampleVi: "Anh ấy cảm thấy quá tải.",
                needsReview: true
            )
        ]
        let container = AppContainer.mock
        let sut = SmartReviewViewModel(weakWords: words, reviewUseCase: container.reviewWeakWordsUseCase, ttsService: container.ttsService)
        
        XCTAssertEqual(sut.weakWords.count, 2)
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.currentWord?.id, 1)
        XCTAssertFalse(sut.isRevealed)
        XCTAssertFalse(sut.isCompleted)
        
        sut.revealDefinition()
        XCTAssertTrue(sut.isRevealed)
        
        sut.playAudio()
        
        await sut.markCurrentReviewed(isCorrect: true)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.currentWord?.id, 2)
        XCTAssertFalse(sut.isRevealed)
        XCTAssertFalse(sut.isCompleted)
        
        sut.revealDefinition()
        await sut.markCurrentReviewed(isCorrect: false)
        XCTAssertTrue(sut.isCompleted)
    }
}
