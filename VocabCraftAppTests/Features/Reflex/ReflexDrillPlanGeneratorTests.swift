import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Reflex Drill Plan Generator Tests")
struct ReflexDrillPlanGeneratorTests {
    @Test("Generates session plan with matching count and mode")
    func testPlanGeneration() {
        let pool = ReflexBlitzWordItem.defaultStarterWords
        let plan = ReflexDrillPlanGenerator.generatePlan(words: pool, mode: .multipleChoice)
        #expect(plan.count == pool.count)
        #expect(plan.mode == .multipleChoice)
    }

    @Test("Generates empty plan when input words pool is empty")
    func testEmptyPoolGeneratesEmptyPlan() {
        let emptyWords: [ReflexBlitzWordItem] = []
        let plan = ReflexDrillPlanGenerator.generatePlan(words: emptyWords, mode: .multipleChoice)
        #expect(plan.isEmpty)
        #expect(plan.items.isEmpty)
        #expect(plan.mode == .multipleChoice)
    }

    @Test("Distractor elimination selects an incorrect option")
    func testDistractorElimination() {
        let pool = ReflexBlitzWordItem.defaultStarterWords
        let plan = ReflexDrillPlanGenerator.generatePlan(words: pool, mode: .multipleChoice)
        for item in plan.items {
            if let elimId = item.eliminatedOptionId {
                let eliminatedOption = item.options.first { $0.id == elimId }
                #expect(eliminatedOption != nil)
                #expect(eliminatedOption?.isCorrect == false)
            }
        }
    }

    @Test("Correct option positions are uniformly distributed over multiple runs")
    func testOptionDistributionUniformity() {
        let pool = ReflexBlitzWordItem.defaultStarterWords
        var positionCounts = [0, 0, 0, 0]
        for _ in 0..<100 {
            let plan = ReflexDrillPlanGenerator.generatePlan(words: pool, mode: .multipleChoice)
            for item in plan.items {
                positionCounts[item.correctOptionIndex] += 1
            }
        }
        // Over 1200 total questions, each position (0..3) should have at least 150 appearances
        for count in positionCounts {
            #expect(count > 150)
        }
    }

    @Test("Typing and speaking modes generate plan items without options")
    func testNonOptionModes() {
        let pool = ReflexBlitzWordItem.defaultStarterWords
        let typingPlan = ReflexDrillPlanGenerator.generatePlan(words: pool, mode: .typing)
        #expect(typingPlan.count == pool.count)
        #expect(typingPlan.mode == .typing)

        for item in typingPlan.items {
            #expect(item.options.isEmpty)
            #expect(item.eliminatedOptionId == nil)
            #expect(item.correctOptionIndex == 0)
            #expect(!item.hintBadgeText.isEmpty)
            #expect(!item.clozeStages.maskedWordString.isEmpty)
        }

        let speakingPlan = ReflexDrillPlanGenerator.generatePlan(words: pool, mode: .speaking)
        #expect(speakingPlan.count == pool.count)
        #expect(speakingPlan.mode == .speaking)
        for item in speakingPlan.items {
            #expect(item.options.isEmpty)
            #expect(item.eliminatedOptionId == nil)
        }
    }

    @Test("Listening mode pre-generates 4 options and hint badge")
    func testListeningModePlanGeneration() {
        let pool = ReflexBlitzWordItem.defaultStarterWords
        let plan = ReflexDrillPlanGenerator.generatePlan(words: pool, mode: .listening)
        #expect(plan.count == pool.count)
        #expect(plan.mode == .listening)

        for item in plan.items {
            #expect(item.options.count == 4)
            #expect(item.options.contains { $0.isCorrect })
            #expect(item.eliminatedOptionId != nil)
            #expect(!item.hintBadgeText.isEmpty)
            #expect(!item.id.isEmpty)
        }
    }
}
