import Foundation
#if canImport(Testing)
import Testing
#endif
#if canImport(XCTest)
import XCTest
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("PracticeDrillPlanGenerator Tests")
struct PracticeDrillPlanGeneratorTests {
    @Test("Generates immutable plan with balanced modes")
    func testPlanGenerationBalance() {
        let generator = PracticeDrillPlanGenerator()
        let words = (1...12).map { id in
            VaultWordItem(id: Int64(id), lemma: "word\(id)", pos: "n", definitionVi: "nghĩa \(id)")
        }
        let plan = generator.generatePlan(from: words)
        #expect(plan.items.count == 12)

        let modes = plan.items.map(\.assignedMode)
        let uniqueModes = Set(modes)
        #expect(uniqueModes.count == 4)

        // All 4 modes should be distributed evenly (3 each for 12 items)
        let speakingCount = modes.filter { $0 == .speaking }.count
        let typingCount = modes.filter { $0 == .typing }.count
        let mcCount = modes.filter { $0 == .multipleChoice }.count
        let listeningCount = modes.filter { $0 == .listening }.count
        #expect(speakingCount == 3)
        #expect(typingCount == 3)
        #expect(mcCount == 3)
        #expect(listeningCount == 3)
    }

    @Test("Respects individual word lowest success mode when possible")
    func testTargetModeAssignment() {
        let generator = PracticeDrillPlanGenerator()
        let wordWithTypingNeed = VaultWordItem(
            id: 1,
            lemma: "craft",
            pos: "n",
            definitionVi: "thủ công",
            modeStats: ModeSuccessStats(speaking: 10, typing: 0, multipleChoice: 10, listening: 10)
        )
        let plan = generator.generatePlan(from: [wordWithTypingNeed])
        #expect(plan.items.first?.assignedMode == .typing)
    }

    @Test("Empty input words generates empty session plan")
    func testEmptyWordsListGeneratesEmptyPlan() {
        let generator = PracticeDrillPlanGenerator()
        let plan = generator.generatePlan(from: [])
        #expect(plan.isEmpty)
        #expect(plan.items.isEmpty)
        #expect(plan.count == 0)
    }

    @Test("Pre-generates options for multipleChoice and listening modes, empty options for typing and speaking")
    func testOptionsGenerationByMode() {
        let generator = PracticeDrillPlanGenerator()
        let words = [
            VaultWordItem(
                id: 1,
                lemma: "apple",
                pos: "n",
                definitionVi: "quả táo",
                exampleSentenceEn: "I eat an apple daily.",
                modeStats: ModeSuccessStats(speaking: 5, typing: 5, multipleChoice: 0, listening: 5)
            ),
            VaultWordItem(
                id: 2,
                lemma: "banana",
                pos: "n",
                definitionVi: "quả chuối",
                exampleSentenceEn: "Monkeys love banana fruit.",
                modeStats: ModeSuccessStats(speaking: 5, typing: 0, multipleChoice: 5, listening: 5)
            ),
            VaultWordItem(
                id: 3,
                lemma: "orange",
                pos: "n",
                definitionVi: "quả cam",
                exampleSentenceEn: "Orange juice is fresh.",
                modeStats: ModeSuccessStats(speaking: 5, typing: 5, multipleChoice: 5, listening: 0)
            ),
            VaultWordItem(
                id: 4,
                lemma: "grape",
                pos: "n",
                definitionVi: "quả nho",
                exampleSentenceEn: "Purple grapes are sweet.",
                modeStats: ModeSuccessStats(speaking: 0, typing: 5, multipleChoice: 5, listening: 5)
            )
        ]

        let plan = generator.generatePlan(from: words)
        #expect(plan.items.count == 4)

        for item in plan.items {
            #expect(!item.hintBadgeText.isEmpty)
            #expect(!item.clozeStages.maskedWordString.isEmpty)

            switch item.assignedMode {
            case .multipleChoice, .listening:
                #expect(item.options.count == 4)
                #expect(item.options.contains(where: { $0.isCorrect }))
                #expect(item.eliminatedOptionId != nil)
            case .speaking, .typing:
                #expect(item.options.isEmpty)
                #expect(item.eliminatedOptionId == nil)
            }
        }
    }

    @Test("Generated plan item IDs are unique across session")
    func testUniquePlanItemIds() {
        let generator = PracticeDrillPlanGenerator()
        let words = (1...8).map { id in
            VaultWordItem(id: Int64(id), lemma: "word\(id)", pos: "n", definitionVi: "nghĩa \(id)")
        }
        let plan = generator.generatePlan(from: words)
        let ids = plan.items.map(\.id)
        let uniqueIds = Set(ids)
        #expect(uniqueIds.count == ids.count)
    }

    @Test("Avoids 3 or more consecutive identical modes when balancing")
    func testAvoidsConsecutiveRuns() {
        let generator = PracticeDrillPlanGenerator()
        let words = (1...16).map { id in
            VaultWordItem(id: Int64(id), lemma: "word\(id)", pos: "n", definitionVi: "nghĩa \(id)")
        }
        let plan = generator.generatePlan(from: words)
        let modes = plan.items.map(\.assignedMode)

        for i in 2..<modes.count {
            let threeInARow = (modes[i] == modes[i - 1] && modes[i] == modes[i - 2])
            #expect(!threeInARow)
        }
    }

    @Test("Balances across multiple modes even when all words share the same single weakest mode")
    func testAllWordsShareSameWeakestMode() {
        let generator = PracticeDrillPlanGenerator()
        let words = (1...12).map { id in
            VaultWordItem(
                id: Int64(id),
                lemma: "word\(id)",
                pos: "n",
                definitionVi: "nghĩa \(id)",
                modeStats: ModeSuccessStats(speaking: 10, typing: 0, multipleChoice: 10, listening: 10)
            )
        }
        let plan = generator.generatePlan(from: words)
        let modes = plan.items.map(\.assignedMode)
        let uniqueModes = Set(modes)

        // Phải phân bổ ra nhiều mode thay vì 100% typing
        #expect(uniqueModes.count >= 3)

        // Không bao giờ lặp lại 3 lần liên tiếp cùng 1 mode
        for i in 2..<modes.count {
            let threeInARow = (modes[i] == modes[i - 1] && modes[i] == modes[i - 2])
            #expect(!threeInARow)
        }
    }
}
#endif

final class PracticeDrillPlanGeneratorXCTestCase: XCTestCase {
    func testPlanGenerationBalance() {
        let generator = PracticeDrillPlanGenerator()
        let words = (1...12).map { id in
            VaultWordItem(id: Int64(id), lemma: "word\(id)", pos: "n", definitionVi: "nghĩa \(id)")
        }
        let plan = generator.generatePlan(from: words)
        XCTAssertEqual(plan.items.count, 12)
        let modes = plan.items.map(\.assignedMode)
        let uniqueModes = Set(modes)
        XCTAssertEqual(uniqueModes.count, 4)
    }

    func testTargetModeAssignment() {
        let generator = PracticeDrillPlanGenerator()
        let wordWithTypingNeed = VaultWordItem(
            id: 1,
            lemma: "craft",
            pos: "n",
            definitionVi: "thủ công",
            modeStats: ModeSuccessStats(speaking: 10, typing: 0, multipleChoice: 10, listening: 10)
        )
        let plan = generator.generatePlan(from: [wordWithTypingNeed])
        XCTAssertEqual(plan.items.first?.assignedMode, .typing)
    }
}
