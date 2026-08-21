@testable import VocabCraftApp
import XCTest

final class ReflexBlitzModelsTests: XCTestCase {
    func testClozeSentenceGeneration() {
        let sentence = "Her fame proved to be ephemeral in the modern era."
        let lemma = "ephemeral"
        let cloze = ReflexClozeFormatter.formatCloze(sentenceEn: sentence, lemma: lemma)

        XCTAssertEqual(cloze, "Her fame proved to be [ _________ ] in the modern era.")
    }

    func testClozeSentenceGeneration_caseInsensitiveAndEmptyHandling() {
        let sentence = "Ephemeral moments define life. Yes, EPHEMERAL."
        let lemma = "ephemeral"
        let cloze = ReflexClozeFormatter.formatCloze(sentenceEn: sentence, lemma: lemma)
        XCTAssertEqual(cloze, "[ _________ ] moments define life. Yes, [ _________ ].")

        XCTAssertEqual(ReflexClozeFormatter.formatCloze(sentenceEn: "", lemma: "test"), "")
        XCTAssertEqual(ReflexClozeFormatter.formatCloze(sentenceEn: "Hello world", lemma: ""), "Hello world")
    }

    func testSpeedTierClassification() {
        XCTAssertEqual(ReflexSpeedTier.from(responseTimeMs: 1800, usedHint: false), .flash)
        XCTAssertEqual(ReflexSpeedTier.from(responseTimeMs: 2499, usedHint: false), .flash)
        XCTAssertEqual(ReflexSpeedTier.from(responseTimeMs: 2500, usedHint: false), .hinted)
        XCTAssertEqual(ReflexSpeedTier.from(responseTimeMs: 1800, usedHint: true), .hinted)
        XCTAssertEqual(ReflexSpeedTier.from(responseTimeMs: 3200, usedHint: true), .hinted)
        XCTAssertEqual(ReflexSpeedTier.from(responseTimeMs: 5999, usedHint: false), .hinted)
        XCTAssertEqual(ReflexSpeedTier.from(responseTimeMs: 6000, usedHint: false), .needsPractice)
        XCTAssertEqual(ReflexSpeedTier.from(responseTimeMs: 6500, usedHint: false), .needsPractice)
    }

    func testWordItemInitialization() {
        let item = ReflexBlitzWordItem(
            id: 42,
            lemma: "Serendipity",
            pos: "n",
            definitionVi: "Sự tình cờ may mắn",
            exampleSentenceEn: "It was pure serendipity that we met.",
            exampleSentenceVi: "Thật là một sự tình cờ may mắn khi chúng tôi gặp nhau."
        )

        XCTAssertEqual(item.id, 42)
        XCTAssertEqual(item.lemma, "Serendipity")
        XCTAssertEqual(item.pos, "n")
        XCTAssertEqual(item.definitionVi, "Sự tình cờ may mắn")
        XCTAssertEqual(item.exampleSentenceEn, "It was pure serendipity that we met.")
        XCTAssertEqual(item.exampleSentenceVi, "Thật là một sự tình cờ may mắn khi chúng tôi gặp nhau.")
        XCTAssertEqual(item.clozeSentenceEn, "It was pure [ _________ ] that we met.")
        XCTAssertEqual(item.initialLetterHint, "s... • n.")
    }

    func testAttemptModelPropertiesAndSpeedTier() {
        let attemptId = UUID()
        let now = Date()
        let attempt = ReflexBlitzAttempt(
            id: attemptId,
            wordId: 10,
            lemma: "resilience",
            responseTimeMs: 2000,
            usedHint: false,
            isCorrect: true,
            timestamp: now
        )

        XCTAssertEqual(attempt.id, attemptId)
        XCTAssertEqual(attempt.wordId, 10)
        XCTAssertEqual(attempt.lemma, "resilience")
        XCTAssertEqual(attempt.responseTimeMs, 2000)
        XCTAssertFalse(attempt.usedHint)
        XCTAssertTrue(attempt.isCorrect)
        XCTAssertEqual(attempt.timestamp, now)
        XCTAssertEqual(attempt.speedTier, .flash)
    }

    func testSessionSummaryCalculations() {
        let attempts = [
            ReflexBlitzAttempt(id: UUID(), wordId: 1, lemma: "ephemeral", responseTimeMs: 1500, usedHint: false, isCorrect: true, timestamp: Date()),
            ReflexBlitzAttempt(id: UUID(), wordId: 2, lemma: "serendipity", responseTimeMs: 2200, usedHint: false, isCorrect: true, timestamp: Date()),
            ReflexBlitzAttempt(id: UUID(), wordId: 3, lemma: "ubiquitous", responseTimeMs: 6200, usedHint: true, isCorrect: false, timestamp: Date())
        ]

        let summary = ReflexBlitzSessionSummary.create(from: attempts, maxCombo: 2)
        XCTAssertEqual(summary.totalWords, 3)
        XCTAssertEqual(summary.correctWords, 2)
        XCTAssertEqual(summary.averageResponseTimeMs, 3300)
        XCTAssertEqual(summary.maxComboStreak, 2)
        XCTAssertEqual(summary.weakWordAttempts.count, 1)
        XCTAssertEqual(summary.weakWordAttempts.first?.lemma, "ubiquitous")
        XCTAssertEqual(summary.speedRating, "🌱 Steady Learner")
    }

    func testSessionSummaryCalculations_perfectReflexMaster() {
        let attempts = [
            ReflexBlitzAttempt(id: UUID(), wordId: 1, lemma: "ephemeral", responseTimeMs: 1500, usedHint: false, isCorrect: true, timestamp: Date()),
            ReflexBlitzAttempt(id: UUID(), wordId: 2, lemma: "serendipity", responseTimeMs: 2200, usedHint: false, isCorrect: true, timestamp: Date())
        ]

        let summary = ReflexBlitzSessionSummary.create(from: attempts, maxCombo: 2)
        XCTAssertEqual(summary.totalWords, 2)
        XCTAssertEqual(summary.correctWords, 2)
        XCTAssertEqual(summary.weakWordAttempts.count, 0)
        XCTAssertEqual(summary.speedRating, "⚡️ Reflex Master")
    }

    func testSessionSummaryCalculations_swiftReflex() {
        let attempts = [
            ReflexBlitzAttempt(id: UUID(), wordId: 1, lemma: "a", responseTimeMs: 2000, usedHint: false, isCorrect: true, timestamp: Date()),
            ReflexBlitzAttempt(id: UUID(), wordId: 2, lemma: "b", responseTimeMs: 2200, usedHint: false, isCorrect: true, timestamp: Date()),
            ReflexBlitzAttempt(id: UUID(), wordId: 3, lemma: "c", responseTimeMs: 2100, usedHint: false, isCorrect: true, timestamp: Date()),
            ReflexBlitzAttempt(id: UUID(), wordId: 4, lemma: "d", responseTimeMs: 4500, usedHint: true, isCorrect: false, timestamp: Date())
        ]
        // total = 4, correct = 3 (75% >= 70%), avg = 10800 / 4 = 2700ms <= 4000ms
        let summary = ReflexBlitzSessionSummary.create(from: attempts, maxCombo: 3)
        XCTAssertEqual(summary.totalWords, 4)
        XCTAssertEqual(summary.correctWords, 3)
        XCTAssertEqual(summary.averageResponseTimeMs, 2700)
        XCTAssertEqual(summary.maxComboStreak, 3)
        XCTAssertEqual(summary.speedRating, "🔥 Swift Reflex")
        XCTAssertEqual(summary.weakWordAttempts.count, 1)
        XCTAssertEqual(summary.weakWordAttempts.first?.lemma, "d")
    }

    func testSessionSummaryCalculations_steadyLearnerAndEmpty() {
        let emptySummary = ReflexBlitzSessionSummary.create(from: [], maxCombo: 0)
        XCTAssertEqual(emptySummary.totalWords, 0)
        XCTAssertEqual(emptySummary.correctWords, 0)
        XCTAssertEqual(emptySummary.averageResponseTimeMs, 0)
        XCTAssertEqual(emptySummary.speedRating, "🌱 Steady Learner")

        let slowAttempts = [
            ReflexBlitzAttempt(id: UUID(), wordId: 1, lemma: "slow", responseTimeMs: 5000, usedHint: false, isCorrect: true, timestamp: Date()),
            ReflexBlitzAttempt(id: UUID(), wordId: 2, lemma: "slower", responseTimeMs: 7000, usedHint: true, isCorrect: false, timestamp: Date())
        ]
        let slowSummary = ReflexBlitzSessionSummary.create(from: slowAttempts, maxCombo: 1)
        XCTAssertEqual(slowSummary.speedRating, "🌱 Steady Learner")
        XCTAssertEqual(slowSummary.weakWordAttempts.count, 1) // Only 'slower' (incorrect and needsPractice)
    }

    func testReflexBlitzWordItemIPAPhoneticsAndCompletedSentence() {
        let word = ReflexBlitzWordItem(
            id: 10,
            lemma: "serendipity",
            pos: "n.",
            ipa: "/ˌser.ənˈdɪp.ə.ti/",
            definitionVi: "Sự may mắn bất ngờ",
            exampleSentenceEn: "Finding this was pure serendipity.",
            exampleSentenceVi: "Tìm thấy thứ này là may mắn bất ngờ."
        )
        XCTAssertEqual(word.ipa, "/ˌser.ənˈdɪp.ə.ti/")
        XCTAssertEqual(word.initialLetterHint, "s... • n.")
        XCTAssertEqual(word.completedSentenceWithTargetWord, "Finding this was pure serendipity.")
    }

    func testSummaryPreservesWeakWordIPAndDefinition() {
        let attempt = ReflexBlitzAttempt(
            wordId: 11,
            lemma: "resilient",
            pos: "adj.",
            ipa: "/rɪˈzɪl.jənt/",
            definitionVi: "Kiên cường, mau hồi phục",
            responseTimeMs: 6000,
            usedHint: true,
            isCorrect: false
        )
        let summary = ReflexBlitzSessionSummary.create(from: [attempt], maxCombo: 0)
        XCTAssertEqual(summary.weakWordAttempts.count, 1)
        XCTAssertEqual(summary.weakWordAttempts.first?.pos, "adj.")
        XCTAssertEqual(summary.weakWordAttempts.first?.ipa, "/rɪˈzɪl.jənt/")
        XCTAssertEqual(summary.weakWordAttempts.first?.definitionVi, "Kiên cường, mau hồi phục")
    }

    func testReflexBlitzModeProperties() {
        XCTAssertEqual(ReflexBlitzMode.multipleChoice.timeLimitSeconds, 4.5)
        XCTAssertEqual(ReflexBlitzMode.listening.timeLimitSeconds, 5.5)
        XCTAssertEqual(ReflexBlitzMode.speaking.timeLimitSeconds, 6.0)
        XCTAssertEqual(ReflexBlitzMode.typing.timeLimitSeconds, 7.5)

        XCTAssertEqual(ReflexBlitzMode.speaking.title, "Luyện nói")
        XCTAssertEqual(ReflexBlitzMode.typing.title, "Gõ từ")
        XCTAssertEqual(ReflexBlitzMode.multipleChoice.title, "Trắc nghiệm")
        XCTAssertEqual(ReflexBlitzMode.listening.title, "Phản xạ nghe")

        XCTAssertEqual(ReflexBlitzMode.speaking.id, "speaking")
        XCTAssertEqual(ReflexBlitzMode.allCases.count, 4)
    }

    func testReflexCardPhaseAndResult() {
        let activePhase = ReflexCardPhase.activeCountdown
        XCTAssertEqual(activePhase, .activeCountdown)

        let result = ReflexCardResult(
            isCorrect: true,
            responseTimeMs: 1200,
            isTimeout: false,
            selectedOption: "habit",
            typedText: nil,
            recognizedSpoken: nil
        )
        let reviewedPhase = ReflexCardPhase.reviewed(result: result)
        XCTAssertEqual(reviewedPhase, .reviewed(result: result))
        XCTAssertNotEqual(activePhase, reviewedPhase)
        XCTAssertEqual(result.isCorrect, true)
        XCTAssertEqual(result.responseTimeMs, 1200)
        XCTAssertFalse(result.isTimeout)
        XCTAssertEqual(result.selectedOption, "habit")
    }

    func testReflexBlitzOption() {
        let option = ReflexBlitzOption(text: "habit", isCorrect: true)
        XCTAssertFalse(option.id.isEmpty)
        XCTAssertEqual(option.text, "habit")
        XCTAssertTrue(option.isCorrect)
    }

    func testGenerateOptionsForMultipleChoice() {
        let words = ReflexBlitzWordItem.defaultStarterWords
        let target = words[0]
        let options = target.generateOptions(mode: .multipleChoice, allPool: words)
        XCTAssertEqual(options.count, 4)
        XCTAssertEqual(options.filter { $0.isCorrect }.count, 1)
        XCTAssertTrue(options.contains { $0.text == target.lemma && $0.isCorrect })

        let uniqueTexts = Set(options.map { $0.text })
        XCTAssertEqual(uniqueTexts.count, 4, "Options must not have duplicates")
    }

    func testGenerateOptionsForListening() {
        let words = ReflexBlitzWordItem.defaultStarterWords
        let target = words[0]
        let options = target.generateOptions(mode: .listening, allPool: words)
        XCTAssertEqual(options.count, 4)
        XCTAssertEqual(options.filter { $0.isCorrect }.count, 1)
        XCTAssertTrue(options.contains { $0.text == target.definitionVi && $0.isCorrect })

        let uniqueTexts = Set(options.map { $0.text })
        XCTAssertEqual(uniqueTexts.count, 4, "Options must not have duplicates")
    }

    func testGenerateOptionsSmallPoolFallback() {
        let words = [ReflexBlitzWordItem.defaultStarterWords[0]] // Pool size 1
        let target = words[0]
        let options = target.generateOptions(mode: .multipleChoice, allPool: words)
        XCTAssertEqual(options.count, 4)
        XCTAssertEqual(options.filter { $0.isCorrect }.count, 1)
        XCTAssertTrue(options.contains { $0.text == target.lemma && $0.isCorrect })
    }

    func testGenerateOptionsNonOptionModes() {
        let words = ReflexBlitzWordItem.defaultStarterWords
        let target = words[0]
        let speakingOptions = target.generateOptions(mode: .speaking, allPool: words)
        let typingOptions = target.generateOptions(mode: .typing, allPool: words)
        XCTAssertTrue(speakingOptions.isEmpty)
        XCTAssertTrue(typingOptions.isEmpty)
    }

    func testCuratedStarterWordsCount() {
        XCTAssertEqual(ReflexBlitzWordItem.defaultStarterWords.count, 12)
    }

    func testDefaultStarterWordsContainRealisticIPA() {
        let words = ReflexBlitzWordItem.defaultStarterWords
        XCTAssertEqual(words.count, 12)
        let expectedLemmas = [
            "habit", "improve", "focus", "create", "journey", "relax",
            "challenge", "protect", "connect", "energy", "simple", "success"
        ]
        let lemmas = words.map { $0.lemma }
        for expected in expectedLemmas {
            XCTAssertTrue(lemmas.contains(expected), "Missing expected lemma: \(expected)")
        }
        for word in words {
            XCTAssertFalse(word.ipa.isEmpty, "Word \(word.lemma) must have non-empty IPA")
            XCTAssertTrue(word.ipa.hasPrefix("/"), "Word \(word.lemma) IPA should start with /")
        }
    }
}
