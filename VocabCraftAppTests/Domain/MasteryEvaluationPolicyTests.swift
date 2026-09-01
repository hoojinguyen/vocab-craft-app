import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("MasteryEvaluationPolicy Tests")
struct MasteryEvaluationPolicyTests {
    @Test("Not mastered when streak < 3 or only 1 mode is practiced")
    func testNotMasteredWhenStreakLowOrSingleMode() {
        // Attempt 1: correct with MultipleChoice
        let result1 = MasteryEvaluationPolicy.evaluate(
            currentStreak: 0,
            practicedModes: [],
            isCorrect: true,
            currentMode: .multipleChoice
        )
        #expect(result1.newStreak == 1)
        #expect(result1.newPracticedModes.contains(.multipleChoice))
        #expect(result1.isMastered == false)

        // Attempt 2: correct still with MultipleChoice (< 2 distinct modes)
        let result2 = MasteryEvaluationPolicy.evaluate(
            currentStreak: 2,
            practicedModes: [.multipleChoice],
            isCorrect: true,
            currentMode: .multipleChoice
        )
        #expect(result2.newStreak == 3)
        #expect(result2.isMastered == false) // Fails >= 2 distinct modes condition
    }

    @Test("Promoted to Mastered when streak >= 3 and has >= 2 distinct modes")
    func testMasteredWhenStreakThreeAndTwoModes() {
        let result = MasteryEvaluationPolicy.evaluate(
            currentStreak: 2,
            practicedModes: [.multipleChoice],
            isCorrect: true,
            currentMode: .speaking
        )
        #expect(result.newStreak == 3)
        #expect(result.newPracticedModes == [.multipleChoice, .speaking])
        #expect(result.isMastered == true)
    }

    @Test("Single wrong answer immediately resets streak to 0 and marks as unmastered")
    func testWrongAnswerResetsMastery() {
        let result = MasteryEvaluationPolicy.evaluate(
            currentStreak: 5,
            practicedModes: [.multipleChoice, .speaking, .typing],
            isCorrect: false,
            currentMode: .typing
        )
        #expect(result.newStreak == 0)
        #expect(result.newPracticedModes.isEmpty)
        #expect(result.isMastered == false)
    }
}
#endif
