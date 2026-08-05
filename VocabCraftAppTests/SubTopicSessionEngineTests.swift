import XCTest
@testable import VocabCraftApp

final class SubTopicSessionEngineTests: XCTestCase {
    func testEngineInitializationAndScoring() {
        let words = [
            TopicWord(id: "w1", english: "Algorithm", phonetic: "/ˈæl.ɡə.rɪ.ðəm/", vietnamese: "Thuật toán"),
            TopicWord(id: "w2", english: "Automation", phonetic: "/ˌɔː.təˈmeɪ.ʃən/", vietnamese: "Tự động hóa")
        ]
        let engine = SubTopicSessionEngine(words: words)

        XCTAssertEqual(engine.currentWord?.english, "Algorithm")
        XCTAssertEqual(engine.attemptsLeft, 2)
        XCTAssertEqual(engine.xpEarned, 0)
        XCTAssertFalse(engine.isSessionComplete)

        // Correct answer on first try
        let result = engine.submitAnswer(selectedVietnamese: "Thuật toán")
        XCTAssertTrue(result.isCorrect)
        XCTAssertEqual(engine.xpEarned, 10)
        XCTAssertEqual(engine.comboCount, 1)
        XCTAssertEqual(engine.correctCount, 1)
    }

    func testTwoWrongAttemptsEnqueuesRetry() {
        let words = [
            TopicWord(id: "w1", english: "Algorithm", phonetic: "/ˈæl.ɡə.rɪ.ðəm/", vietnamese: "Thuật toán")
        ]
        let engine = SubTopicSessionEngine(words: words)

        // First wrong attempt
        let res1 = engine.submitAnswer(selectedVietnamese: "Sai 1")
        XCTAssertFalse(res1.isCorrect)
        XCTAssertEqual(engine.attemptsLeft, 1)
        XCTAssertEqual(res1.attemptsRemaining, 1)
        XCTAssertEqual(res1.xpDelta, 0)

        // Second wrong attempt
        let res2 = engine.submitAnswer(selectedVietnamese: "Sai 2")
        XCTAssertFalse(res2.isCorrect)
        XCTAssertEqual(engine.attemptsLeft, 0)
        XCTAssertEqual(res2.attemptsRemaining, 0)
        XCTAssertEqual(engine.xpEarned, -5)
        XCTAssertEqual(engine.comboCount, 0)
        XCTAssertEqual(engine.retryQueue.count, 1)
    }

    func testSecondAttemptCorrectScoring() {
        let words = [
            TopicWord(id: "w1", english: "Algorithm", phonetic: "/ˈæl.ɡə.rɪ.ðəm/", vietnamese: "Thuật toán")
        ]
        let engine = SubTopicSessionEngine(words: words)

        let res1 = engine.submitAnswer(selectedVietnamese: "Wrong")
        XCTAssertFalse(res1.isCorrect)

        let res2 = engine.submitAnswer(selectedVietnamese: "Thuật toán")
        XCTAssertTrue(res2.isCorrect)
        XCTAssertEqual(res2.xpDelta, 5)
        XCTAssertEqual(engine.xpEarned, 5)
        XCTAssertEqual(engine.comboCount, 1)
    }

    func testAdvanceToNextWordFlushesRetryQueueAtEnd() {
        let words = [
            TopicWord(id: "w1", english: "Algorithm", phonetic: "/ˈæl.ɡə.rɪ.ðəm/", vietnamese: "Thuật toán"),
            TopicWord(id: "w2", english: "Automation", phonetic: "/ˌɔː.təˈmeɪ.ʃən/", vietnamese: "Tự động hóa")
        ]
        let engine = SubTopicSessionEngine(words: words)

        // Fail word 1 twice
        _ = engine.submitAnswer(selectedVietnamese: "Wrong 1")
        _ = engine.submitAnswer(selectedVietnamese: "Wrong 2")
        XCTAssertEqual(engine.retryQueue.count, 1)

        engine.advanceToNextWord()
        XCTAssertEqual(engine.currentIndex, 1)
        XCTAssertEqual(engine.currentWord?.english, "Automation")
        XCTAssertEqual(engine.attemptsLeft, 2)

        // Correct word 2
        _ = engine.submitAnswer(selectedVietnamese: "Tự động hóa")
        engine.advanceToNextWord()

        // At end of original activeWords list, retryQueue should be flushed into activeWords
        XCTAssertEqual(engine.currentIndex, 2)
        XCTAssertEqual(engine.currentWord?.english, "Algorithm")
        XCTAssertTrue(engine.retryQueue.isEmpty)
        XCTAssertFalse(engine.isSessionComplete)

        // Solve retried word
        _ = engine.submitAnswer(selectedVietnamese: "Thuật toán")
        engine.advanceToNextWord()

        XCTAssertTrue(engine.isSessionComplete)
        XCTAssertNil(engine.currentWord)
    }
}
