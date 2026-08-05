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

    func testStrictSessionCompletionAndPassingThreshold() {
        let words = [
            TopicWord(id: "w1", english: "Algorithm", phonetic: "/ˈæl.ɡə.rɪ.ðəm/", vietnamese: "Thuật toán"),
            TopicWord(id: "w2", english: "Automation", phonetic: "/ˌɔː.təˈmeɪ.ʃən/", vietnamese: "Tự động hóa")
        ]
        let engine = SubTopicSessionEngine(words: words)

        // Fail word 1 twice
        _ = engine.submitAnswer(selectedVietnamese: "Wrong 1")
        _ = engine.submitAnswer(selectedVietnamese: "Wrong 2")

        engine.advanceToNextWord()
        XCTAssertEqual(engine.currentIndex, 1)
        XCTAssertEqual(engine.currentWord?.english, "Automation")
        XCTAssertEqual(engine.attemptsLeft, 2)

        // Correct word 2
        _ = engine.submitAnswer(selectedVietnamese: "Tự động hóa")
        engine.advanceToNextWord()

        // Session completes strictly after word count (2 words)
        XCTAssertEqual(engine.currentIndex, 2)
        XCTAssertTrue(engine.isSessionComplete)
        XCTAssertNil(engine.currentWord)

        // Accuracy is 50% (1/2 passed), so isPassed is false (<80%)
        XCTAssertEqual(engine.accuracyPercentage, 50)
        XCTAssertFalse(engine.isPassed)
    }


    func testDistractorGeneratorReturnsFourUniqueOptions() {
        let words = [
            TopicWord(id: "w1", english: "Automation", phonetic: "/ˌɔː.təˈmeɪ.ʃən/", vietnamese: "Sự tự động hóa", example: "Factory automation reduces costs.", partOfSpeech: "noun"),
            TopicWord(id: "w2", english: "Algorithm", phonetic: "/ˈæl.ɡə.rɪ.ðəm/", vietnamese: "Thuật toán", example: "The algorithm runs fast.", partOfSpeech: "noun"),
            TopicWord(id: "w3", english: "Ecosystem", phonetic: "/ˈiː.koʊˌsɪs.təm/", vietnamese: "Hệ sinh thái", example: "Protect the ecosystem.", partOfSpeech: "noun"),
            TopicWord(id: "w4", english: "Biodiversity", phonetic: "/ˌbaɪ.oʊ.daɪˈvɜːr.sə.ti/", vietnamese: "Đa dạng sinh học", example: "Forests have high biodiversity.", partOfSpeech: "noun")
        ]
        let engine = SubTopicSessionEngine(words: words)
        let options = engine.generateDistractors(for: words[0])

        XCTAssertEqual(options.count, 4)
        XCTAssertTrue(options.contains("Sự tự động hóa"))
        XCTAssertEqual(Set(options).count, 4, "Options must contain 4 distinct Vietnamese meanings without duplicates")
    }

    func testQuestionResultsTracksPassAndFail() {
        let words = [
            TopicWord(id: "1", english: "A", phonetic: "/a/", vietnamese: "Nghĩa A"),
            TopicWord(id: "2", english: "B", phonetic: "/b/", vietnamese: "Nghĩa B")
        ]
        let engine = SubTopicSessionEngine(words: words)

        // Submit correct for question 0
        let res1 = engine.submitAnswer(selectedVietnamese: "Nghĩa A")
        XCTAssertTrue(res1.isCorrect)
        XCTAssertEqual(engine.questionPassedResults[0], true)
        XCTAssertEqual(engine.passedCount, 1)

        engine.advanceToNextWord()

        // Submit incorrect twice for question 1
        _ = engine.submitAnswer(selectedVietnamese: "Sai")
        let res2 = engine.submitAnswer(selectedVietnamese: "Sai")
        XCTAssertFalse(res2.isCorrect)
        XCTAssertEqual(engine.questionPassedResults[1], false)

        // Accuracy should be 50% (1/2 passed)
        XCTAssertEqual(engine.accuracyPercentage, 50)
    }

    func testSecondAttemptCorrectMarksQuestionPassedGreen() {
        let words = [
            TopicWord(id: "1", english: "A", phonetic: "/a/", vietnamese: "Nghĩa A")
        ]
        let engine = SubTopicSessionEngine(words: words)

        // Attempt 1 wrong
        let res1 = engine.submitAnswer(selectedVietnamese: "Sai")
        XCTAssertFalse(res1.isCorrect)
        XCTAssertNil(engine.questionPassedResults[0])

        // Attempt 2 correct
        let res2 = engine.submitAnswer(selectedVietnamese: "Nghĩa A")
        XCTAssertTrue(res2.isCorrect)
        XCTAssertEqual(engine.questionPassedResults[0], true)
        XCTAssertEqual(engine.passedCount, 1)
        XCTAssertEqual(engine.accuracyPercentage, 100)
    }
}




