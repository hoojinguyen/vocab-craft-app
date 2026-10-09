import Foundation
import Testing
@testable import VocabCraftApp

@Suite("ScenarioDialogueState Tests")
struct ScenarioDialogueStateTests {
    @Test("DiningState identifies completed state correctly")
    func testDiningStateCompletion() {
        let state = ScenarioDialogueState.dining(.completed)
        #expect(state.isCompleted == true)

        let activeState = ScenarioDialogueState.dining(.ordering)
        #expect(activeState.isCompleted == false)
    }

    @Test("TravelState identifies completed state correctly")
    func testTravelStateCompletion() {
        let state = ScenarioDialogueState.travel(.completed)
        #expect(state.isCompleted == true)

        let activeState = ScenarioDialogueState.travel(.reservationCheck)
        #expect(activeState.isCompleted == false)
    }

    @Test("InterviewState and DailyLifeState identify completed state correctly")
    func testInterviewAndDailyLifeStateCompletion() {
        let interview = ScenarioDialogueState.interview(.completed)
        #expect(interview.isCompleted == true)

        let activeInterview = ScenarioDialogueState.interview(.greeting)
        #expect(activeInterview.isCompleted == false)

        let daily = ScenarioDialogueState.dailyLife(.completed)
        #expect(daily.isCompleted == true)

        let activeDaily = ScenarioDialogueState.dailyLife(.sharing)
        #expect(activeDaily.isCompleted == false)
    }
}
