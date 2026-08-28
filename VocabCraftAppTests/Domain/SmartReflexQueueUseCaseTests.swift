import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Smart Reflex Queue UseCase Tests")
struct SmartReflexQueueUseCaseTests {
    @Test("Queue selects max 10 words prioritizing weak words and current topic")
    func testSmartQueueSelectionAndShuffle() {
        let useCase = GenerateSmartReflexQueueUseCase()

        // Setup 20 mock items: 6 weak, 6 current topic, 4 SRS due, 4 mastered
        var allItems: [ReflexDrillItem] = []
        for i in 1...6 {
            allItems.append(ReflexDrillItem(
                id: "weak_\(i)",
                lemma: "weak\(i)",
                ipa: "/w/",
                definitionVi: "nghĩa \(i)",
                clozeSentenceEn: "Sentence [weak\(i)]",
                clozeSentenceVi: "Câu \(i)",
                mistakeCount: i,
                needsReview: true
            ))
        }
        for i in 1...6 {
            allItems.append(ReflexDrillItem(
                id: "topic_\(i)",
                lemma: "topic\(i)",
                ipa: "/t/",
                definitionVi: "chủ đề \(i)",
                clozeSentenceEn: "Sentence [topic\(i)]",
                clozeSentenceVi: "Câu \(i)",
                isMastered: false
            ))
        }
        for i in 1...4 {
            allItems.append(ReflexDrillItem(
                id: "mastered_\(i)",
                lemma: "mastered\(i)",
                ipa: "/m/",
                definitionVi: "thuộc \(i)",
                clozeSentenceEn: "Sentence [mastered\(i)]",
                clozeSentenceVi: "Câu \(i)",
                isMastered: true
            ))
        }

        let currentTopicSlice = Array(allItems[6..<12])
        let result = useCase.execute(
            allLearnedWords: allItems,
            currentTopicWords: currentTopicSlice,
            targetCount: 10
        )

        #expect(result.count == 10)
        let weakCount = result.filter { $0.needsReview || $0.mistakeCount > 0 }.count
        #expect(weakCount >= 1 && weakCount <= 5)

        // Ensure no duplicate IDs
        let uniqueIds = Set(result.map { $0.id })
        #expect(uniqueIds.count == 10)
    }

    @Test("Tier 1 selects up to 5 weak words prioritizing higher mistakeCount and older lastReviewDate")
    func testTier1WeakWordsOrdering() {
        let useCase = GenerateSmartReflexQueueUseCase()
        let now = Date()

        let weakItem1 = ReflexDrillItem(id: "w1", lemma: "w1", mistakeCount: 2, needsReview: true, lastReviewDate: now.addingTimeInterval(-1000))
        let weakItem2 = ReflexDrillItem(id: "w2", lemma: "w2", mistakeCount: 5, needsReview: true, lastReviewDate: now.addingTimeInterval(-200))
        let weakItem3 = ReflexDrillItem(id: "w3", lemma: "w3", mistakeCount: 5, needsReview: true, lastReviewDate: now.addingTimeInterval(-5000))
        let weakItem4 = ReflexDrillItem(id: "w4", lemma: "w4", mistakeCount: 1, needsReview: true, lastReviewDate: nil)
        let weakItem5 = ReflexDrillItem(id: "w5", lemma: "w5", mistakeCount: 4, needsReview: true, lastReviewDate: now)
        let weakItem6 = ReflexDrillItem(id: "w6", lemma: "w6", mistakeCount: 3, needsReview: true, lastReviewDate: now)
        let weakItem7 = ReflexDrillItem(id: "w7", lemma: "w7", mistakeCount: 0, needsReview: false, isMastered: true)

        let result = useCase.execute(
            allLearnedWords: [weakItem1, weakItem2, weakItem3, weakItem4, weakItem5, weakItem6, weakItem7],
            currentTopicWords: [],
            targetCount: 5
        )

        #expect(result.count == 5)
        let ids = Set(result.map { $0.id })
        // weakItem3 (mistakes: 5, older), weakItem2 (mistakes: 5, newer), weakItem5 (mistakes: 4), weakItem6 (mistakes: 3), weakItem1 (mistakes: 2)
        #expect(ids.contains("w3"))
        #expect(ids.contains("w2"))
        #expect(ids.contains("w5"))
        #expect(ids.contains("w6"))
        #expect(ids.contains("w1"))
        #expect(!ids.contains("w4")) // 6th weak word excluded when cap is 5
        #expect(!ids.contains("w7"))
    }

    @Test("Tier 2 selects up to 5 non-mastered topic words prioritizing lowest consecutive streak")
    func testTier2TopicWordsOrdering() {
        let useCase = GenerateSmartReflexQueueUseCase()

        let topicItem1 = ReflexDrillItem(id: "t1", lemma: "t1", isMastered: false, consecutiveCorrectStreak: 4)
        let topicItem2 = ReflexDrillItem(id: "t2", lemma: "t2", isMastered: false, consecutiveCorrectStreak: 0)
        let topicItem3 = ReflexDrillItem(id: "t3", lemma: "t3", isMastered: false, consecutiveCorrectStreak: 2)
        let topicItem4 = ReflexDrillItem(id: "t4", lemma: "t4", isMastered: false, consecutiveCorrectStreak: 1)
        let topicItem5 = ReflexDrillItem(id: "t5", lemma: "t5", isMastered: false, consecutiveCorrectStreak: 3)
        let topicItem6 = ReflexDrillItem(id: "t6", lemma: "t6", isMastered: false, consecutiveCorrectStreak: 5)
        let topicMastered = ReflexDrillItem(id: "tM", lemma: "tM", isMastered: true, consecutiveCorrectStreak: 10)

        let result = useCase.execute(
            allLearnedWords: [],
            currentTopicWords: [topicItem1, topicItem2, topicItem3, topicItem4, topicItem5, topicItem6, topicMastered],
            targetCount: 5
        )

        #expect(result.count == 5)
        let ids = Set(result.map { $0.id })
        #expect(ids.contains("t2")) // streak 0
        #expect(ids.contains("t4")) // streak 1
        #expect(ids.contains("t3")) // streak 2
        #expect(ids.contains("t5")) // streak 3
        #expect(ids.contains("t1")) // streak 4
        #expect(!ids.contains("t6")) // streak 5 (capped at 5)
        #expect(!ids.contains("tM")) // mastered
    }

    @Test("Tier 3 selects up to 5 SRS overdue words prioritizing oldest overdue date")
    func testTier3SRSDueWordsOrdering() {
        let useCase = GenerateSmartReflexQueueUseCase()
        let now = Date()

        let srsItem1 = ReflexDrillItem(id: "s1", lemma: "s1", isMastered: false, nextReviewDate: now.addingTimeInterval(-3600)) // 1h overdue
        let srsItem2 = ReflexDrillItem(id: "s2", lemma: "s2", isMastered: false, nextReviewDate: now.addingTimeInterval(-86400)) // 1d overdue (older)
        let srsItem3 = ReflexDrillItem(id: "s3", lemma: "s3", isMastered: false, nextReviewDate: now.addingTimeInterval(3600)) // not due yet
        let srsItem4 = ReflexDrillItem(id: "s4", lemma: "s4", isMastered: false, nextReviewDate: now.addingTimeInterval(-7200)) // 2h overdue

        let result = useCase.execute(
            allLearnedWords: [srsItem1, srsItem2, srsItem3, srsItem4],
            currentTopicWords: [],
            targetCount: 3
        )

        #expect(result.count == 3)
        let ids = Set(result.map { $0.id })
        #expect(ids.contains("s2"))
        #expect(ids.contains("s4"))
        #expect(ids.contains("s1"))
        #expect(!ids.contains("s3")) // not overdue
    }

    @Test("Tier 4 fills up remaining slots to reach targetCount")
    func testTier4FillUpRemaining() {
        let useCase = GenerateSmartReflexQueueUseCase()

        let weakItem = ReflexDrillItem(id: "w1", lemma: "w1", mistakeCount: 2, needsReview: true)
        let topicItem = ReflexDrillItem(id: "t1", lemma: "t1", isMastered: false, consecutiveCorrectStreak: 1)
        let masteredItem1 = ReflexDrillItem(id: "m1", lemma: "m1", isMastered: true)
        let masteredItem2 = ReflexDrillItem(id: "m2", lemma: "m2", isMastered: true)
        let masteredItem3 = ReflexDrillItem(id: "m3", lemma: "m3", isMastered: true)

        let result = useCase.execute(
            allLearnedWords: [weakItem, masteredItem1, masteredItem2, masteredItem3],
            currentTopicWords: [topicItem],
            targetCount: 5
        )

        #expect(result.count == 5)
        let ids = Set(result.map { $0.id })
        #expect(ids.contains("w1"))
        #expect(ids.contains("t1"))
        #expect(ids.contains("m1"))
        #expect(ids.contains("m2"))
        #expect(ids.contains("m3"))
    }

    @Test("Queue deduplicates words appearing in both allLearnedWords and currentTopicWords")
    func testDeduplication() {
        let useCase = GenerateSmartReflexQueueUseCase()

        let sharedWord = ReflexDrillItem(id: "shared", lemma: "shared", mistakeCount: 3, needsReview: true)
        let otherWord = ReflexDrillItem(id: "other", lemma: "other", isMastered: false)

        let result = useCase.execute(
            allLearnedWords: [sharedWord, otherWord],
            currentTopicWords: [sharedWord],
            targetCount: 10
        )

        #expect(result.count == 2)
        let ids = result.map { $0.id }
        #expect(ids.filter { $0 == "shared" }.count == 1)
    }

    @Test("Empty input returns empty array")
    func testEmptyInput() {
        let useCase = GenerateSmartReflexQueueUseCase()
        let result = useCase.execute(
            allLearnedWords: [],
            currentTopicWords: [],
            targetCount: 10
        )
        #expect(result.isEmpty)
    }
}
