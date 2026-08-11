import XCTest
@testable import VocabCraftApp

@MainActor
final class StudySessionViewModelTests: XCTestCase {
    func testSubmitAnswerCorrectFlipsCardWithoutAutoAdvancing() async throws {
        let words = [
            TopicWord(id: "w1", english: "Automation", phonetic: "/ˌɔː.təˈmeɪ.ʃən/", vietnamese: "Sự tự động hóa"),
            TopicWord(id: "w2", english: "Algorithm", phonetic: "/ˈæl.ɡə.rɪ.ðəm/", vietnamese: "Thuật toán")
        ]
        let viewModel = StudySessionViewModel(words: words)

        XCTAssertEqual(viewModel.engine.currentIndex, 0)
        XCTAssertFalse(viewModel.isFlipped)

        // Submit correct answer
        viewModel.submitAnswer("Sự tự động hóa")

        XCTAssertTrue(viewModel.isFlipped)
        XCTAssertTrue(viewModel.isSuccess)
        XCTAssertEqual(viewModel.engine.currentIndex, 0)

        // Wait 1.6 seconds to ensure NO automatic advancement occurs via timer
        try await Task.sleep(for: .milliseconds(1600))
        XCTAssertEqual(viewModel.engine.currentIndex, 0, "Current index should NOT auto-advance to 1")

        // Manually call advanceToNext()
        viewModel.advanceToNext()
        XCTAssertEqual(viewModel.engine.currentIndex, 1, "Current index should advance to 1 after manual advanceToNext()")
        XCTAssertEqual(viewModel.engine.currentWord?.english, "Algorithm")
        XCTAssertFalse(viewModel.isFlipped)
    }

    func testSubmitAnswerIncorrectTwiceFlipsCardWithoutAutoAdvancing() async throws {
        let words = [
            TopicWord(id: "w1", english: "Automation", phonetic: "/ˌɔː.təˈmeɪ.ʃən/", vietnamese: "Sự tự động hóa"),
            TopicWord(id: "w2", english: "Algorithm", phonetic: "/ˈæl.ɡə.rɪ.ðəm/", vietnamese: "Thuật toán")
        ]
        let viewModel = StudySessionViewModel(words: words)

        // Submit wrong answer 1
        viewModel.submitAnswer("Thuật toán")
        XCTAssertFalse(viewModel.isSuccess)
        XCTAssertFalse(viewModel.isFlipped)
        XCTAssertEqual(viewModel.engine.currentIndex, 0)

        // Submit wrong answer 2 with a different wrong option (exhausts attempts)
        viewModel.submitAnswer("Hệ sinh thái")
        XCTAssertFalse(viewModel.isSuccess)
        XCTAssertTrue(viewModel.isFlipped)
        XCTAssertEqual(viewModel.engine.currentIndex, 0)

        // Wait 1.6 seconds to ensure NO automatic advancement occurs via timer
        try await Task.sleep(for: .milliseconds(1600))
        XCTAssertEqual(viewModel.engine.currentIndex, 0, "Current index should NOT auto-advance after failed attempts")

        // Manually call advanceToNext()
        viewModel.advanceToNext()
        XCTAssertEqual(viewModel.engine.currentIndex, 1)
    }
}
