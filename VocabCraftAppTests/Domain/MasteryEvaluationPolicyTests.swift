import Testing
@testable import VocabCraftApp

@Suite("MasteryEvaluationPolicy Tests")
struct MasteryEvaluationPolicyTests {
    @Test("Chưa thuộc khi streak < 3 hoặc chỉ có 1 mode")
    func testNotMasteredWhenStreakLowOrSingleMode() {
        // Lần 1 đúng với MultipleChoice
        let result1 = MasteryEvaluationPolicy.evaluate(
            currentStreak: 0,
            practicedModes: [],
            isCorrect: true,
            currentMode: .multipleChoice
        )
        #expect(result1.newStreak == 1)
        #expect(result1.newPracticedModes.contains(.multipleChoice))
        #expect(result1.isMastered == false)
        
        // Lần 2 đúng vẫn với MultipleChoice (chưa đủ 2 chế độ khác nhau)
        let result2 = MasteryEvaluationPolicy.evaluate(
            currentStreak: 2,
            practicedModes: [.multipleChoice],
            isCorrect: true,
            currentMode: .multipleChoice
        )
        #expect(result2.newStreak == 3)
        #expect(result2.isMastered == false) // Sai điều kiện >= 2 modes
    }

    @Test("Thăng hạng Đã thuộc khi streak >= 3 và có >= 2 modes khác nhau")
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

    @Test("Sai 1 lần lập tức reset streak về 0 và chuyển về Chưa thuộc")
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
