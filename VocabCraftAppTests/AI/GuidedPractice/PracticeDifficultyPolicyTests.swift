import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Practice Difficulty Policy Tests")
struct PracticeDifficultyPolicyTests {
    private let policy = PracticeDifficultyPolicy()

    private func makeOutcome(
        opportunityId: String = UUID().uuidString,
        wordId: Int64 = 101,
        objectiveId: String = "test_obj",
        intent: PracticeIntentVerdict = .achieved,
        usage: PracticeUsageVerdict = .appropriate,
        support: PracticeSupportLevel = .none,
        primed: Bool = false,
        eligible: Bool = true
    ) -> PracticeOpportunityOutcome {
        PracticeOpportunityOutcome(
            opportunityId: opportunityId,
            wordId: wordId,
            objectiveId: objectiveId,
            intentVerdict: intent,
            usageVerdict: usage,
            supportLevel: support,
            primed: primed,
            eligible: eligible
        )
    }

    private func makeDifficulty(
        taskConstraints: Int = 0,
        characterDirectness: Int = 0,
        contextNovelty: Int = 0
    ) -> PracticeDifficulty {
        // Safe within tested 0...2 bounds
        // swiftlint:disable:next force_try
        try! PracticeDifficulty(
            taskConstraints: taskConstraints,
            characterDirectness: characterDirectness,
            contextNovelty: contextNovelty
        )
    }

    @Test("two successes increase difficulty in strict priority order: directness, constraints, novelty")
    func twoSuccessesIncreaseInPriorityOrder() {
        // Step 1: Base (0, 0, 0) -> characterDirectness increases to 1
        var diff = makeDifficulty(taskConstraints: 0, characterDirectness: 0, contextNovelty: 0)
        let outcomes1 = [makeOutcome(), makeOutcome()]
        var decision = policy.next(current: diff, outcomes: outcomes1)
        #expect(decision.difficulty.taskConstraints == 0)
        #expect(decision.difficulty.characterDirectness == 1)
        #expect(decision.difficulty.contextNovelty == 0)
        #expect(decision.suggestedSupport == .none)

        // Step 2: (0, 1, 0) -> characterDirectness increases to 2
        diff = decision.difficulty
        decision = policy.next(current: diff, outcomes: [makeOutcome(), makeOutcome()])
        #expect(decision.difficulty.taskConstraints == 0)
        #expect(decision.difficulty.characterDirectness == 2)
        #expect(decision.difficulty.contextNovelty == 0)

        // Step 3: (0, 2, 0) -> taskConstraints increases to 1
        diff = decision.difficulty
        decision = policy.next(current: diff, outcomes: [makeOutcome(), makeOutcome()])
        #expect(decision.difficulty.taskConstraints == 1)
        #expect(decision.difficulty.characterDirectness == 2)
        #expect(decision.difficulty.contextNovelty == 0)

        // Step 4: (1, 2, 0) -> taskConstraints increases to 2
        diff = decision.difficulty
        decision = policy.next(current: diff, outcomes: [makeOutcome(), makeOutcome()])
        #expect(decision.difficulty.taskConstraints == 2)
        #expect(decision.difficulty.characterDirectness == 2)
        #expect(decision.difficulty.contextNovelty == 0)

        // Step 5: (2, 2, 0) -> contextNovelty increases to 1
        diff = decision.difficulty
        decision = policy.next(current: diff, outcomes: [makeOutcome(), makeOutcome()])
        #expect(decision.difficulty.taskConstraints == 2)
        #expect(decision.difficulty.characterDirectness == 2)
        #expect(decision.difficulty.contextNovelty == 1)

        // Step 6: (2, 2, 1) -> contextNovelty increases to 2
        diff = decision.difficulty
        decision = policy.next(current: diff, outcomes: [makeOutcome(), makeOutcome()])
        #expect(decision.difficulty.taskConstraints == 2)
        #expect(decision.difficulty.characterDirectness == 2)
        #expect(decision.difficulty.contextNovelty == 2)
    }

    @Test("difficulty capped at max 2 on each axis and never exceeds 2")
    func maxDifficultyBoundsCannotExceedTwo() {
        let maxDiff = makeDifficulty(taskConstraints: 2, characterDirectness: 2, contextNovelty: 2)
        let outcomes = [makeOutcome(), makeOutcome()]
        let decision = policy.next(current: maxDiff, outcomes: outcomes)

        #expect(decision.difficulty.taskConstraints == 2)
        #expect(decision.difficulty.characterDirectness == 2)
        #expect(decision.difficulty.contextNovelty == 2)
        #expect(decision.suggestedSupport == .none)
    }

    @Test("two failures decrease task constraints first while constraints > 0")
    func twoFailuresReduceConstraintsFirst() {
        let diff = makeDifficulty(taskConstraints: 2, characterDirectness: 1, contextNovelty: 1)
        let failOutcomes = [
            makeOutcome(intent: .notYet, usage: .inappropriate),
            makeOutcome(intent: .notYet, usage: .inappropriate)
        ]

        let decision1 = policy.next(current: diff, outcomes: failOutcomes, currentSuggestedSupport: .none)
        #expect(decision1.difficulty.taskConstraints == 1)
        #expect(decision1.difficulty.characterDirectness == 1)
        #expect(decision1.difficulty.contextNovelty == 1)
        #expect(decision1.suggestedSupport == .none)

        let decision2 = policy.next(current: decision1.difficulty, outcomes: failOutcomes, currentSuggestedSupport: .none)
        #expect(decision2.difficulty.taskConstraints == 0)
        #expect(decision2.difficulty.characterDirectness == 1)
        #expect(decision2.difficulty.contextNovelty == 1)
        #expect(decision2.suggestedSupport == .none)
    }

    @Test("two failures with min constraints (0) increase suggested support sequentially")
    func minConstraintsTwoFailuresIncreaseSuggestedSupport() {
        let diff = makeDifficulty(taskConstraints: 0, characterDirectness: 1, contextNovelty: 1)
        let failOutcomes = [
            makeOutcome(intent: .notYet, usage: .inappropriate),
            makeOutcome(intent: .notYet, usage: .inappropriate)
        ]

        // none -> intent
        let decision1 = policy.next(current: diff, outcomes: failOutcomes, currentSuggestedSupport: .none)
        #expect(decision1.difficulty == diff)
        #expect(decision1.suggestedSupport == .intent)

        // intent -> lexical
        let decision2 = policy.next(current: diff, outcomes: failOutcomes, currentSuggestedSupport: .intent)
        #expect(decision2.difficulty == diff)
        #expect(decision2.suggestedSupport == .lexical)

        // lexical -> frame
        let decision3 = policy.next(current: diff, outcomes: failOutcomes, currentSuggestedSupport: .lexical)
        #expect(decision3.difficulty == diff)
        #expect(decision3.suggestedSupport == .frame)

        // frame -> model
        let decision4 = policy.next(current: diff, outcomes: failOutcomes, currentSuggestedSupport: .frame)
        #expect(decision4.difficulty == diff)
        #expect(decision4.suggestedSupport == .model)

        // model -> model (capped at model)
        let decision5 = policy.next(current: diff, outcomes: failOutcomes, currentSuggestedSupport: .model)
        #expect(decision5.difficulty == diff)
        #expect(decision5.suggestedSupport == .model)
    }

    @Test("mixed outcomes keep current difficulty and suggested support unchanged")
    func mixedOutcomesKeepCurrentLevel() {
        let diff = makeDifficulty(taskConstraints: 1, characterDirectness: 1, contextNovelty: 1)
        let mixed1 = [
            makeOutcome(intent: .achieved, usage: .appropriate),
            makeOutcome(intent: .notYet, usage: .inappropriate)
        ]
        let decision1 = policy.next(current: diff, outcomes: mixed1, currentSuggestedSupport: .intent)
        #expect(decision1.difficulty == diff)
        #expect(decision1.suggestedSupport == .intent)

        let mixed2 = [
            makeOutcome(intent: .notYet, usage: .inappropriate),
            makeOutcome(intent: .achieved, usage: .appropriate)
        ]
        let decision2 = policy.next(current: diff, outcomes: mixed2, currentSuggestedSupport: .intent)
        #expect(decision2.difficulty == diff)
        #expect(decision2.suggestedSupport == .intent)
    }

    @Test("fewer than two eligible outcomes maintain current difficulty and support")
    func fewerThanTwoEligibleOutcomesMaintainCurrent() {
        let diff = makeDifficulty(taskConstraints: 1, characterDirectness: 1, contextNovelty: 1)

        let emptyDecision = policy.next(current: diff, outcomes: [], currentSuggestedSupport: .lexical)
        #expect(emptyDecision.difficulty == diff)
        #expect(emptyDecision.suggestedSupport == .lexical)

        let singleOutcomeDecision = policy.next(
            current: diff,
            outcomes: [makeOutcome(intent: .achieved, usage: .appropriate)],
            currentSuggestedSupport: .lexical
        )
        #expect(singleOutcomeDecision.difficulty == diff)
        #expect(singleOutcomeDecision.suggestedSupport == .lexical)
    }

    @Test("technical failure is ineligible and does not affect adaptation")
    func technicalFailureDoesNotAffectAdaptation() {
        let diff = makeDifficulty(taskConstraints: 1, characterDirectness: 1, contextNovelty: 1)
        let outcomes = [
            makeOutcome(intent: .achieved, usage: .appropriate, eligible: true),
            makeOutcome(intent: .notYet, usage: .inappropriate, eligible: false)
        ]

        let decision = policy.next(current: diff, outcomes: outcomes, currentSuggestedSupport: .none)
        #expect(decision.difficulty == diff)
        #expect(decision.suggestedSupport == .none)
    }

    @Test("synonym use does not count as failure")
    func synonymDoesNotCountAsFailure() {
        let diff = makeDifficulty(taskConstraints: 1, characterDirectness: 1, contextNovelty: 1)
        // Synonym: communicative intent achieved, but target word not observed
        let synonymOutcome = makeOutcome(intent: .achieved, usage: .notObserved)
        let failOutcome = makeOutcome(intent: .notYet, usage: .inappropriate)

        let decision1 = policy.next(current: diff, outcomes: [failOutcome, synonymOutcome], currentSuggestedSupport: .none)
        #expect(decision1.difficulty == diff)
        #expect(decision1.suggestedSupport == .none)

        let decision2 = policy.next(current: diff, outcomes: [synonymOutcome, synonymOutcome], currentSuggestedSupport: .none)
        #expect(decision2.difficulty == diff)
        #expect(decision2.suggestedSupport == .none)
    }

    @Test("uncertain verdicts do not count as failure or success")
    func uncertainVerdictsDoNotCountAsFailure() {
        let diff = makeDifficulty(taskConstraints: 1, characterDirectness: 1, contextNovelty: 1)
        let uncertainOutcome = makeOutcome(intent: .uncertain, usage: .uncertain)
        let failOutcome = makeOutcome(intent: .notYet, usage: .inappropriate)

        let decision = policy.next(current: diff, outcomes: [failOutcome, uncertainOutcome], currentSuggestedSupport: .none)
        #expect(decision.difficulty == diff)
        #expect(decision.suggestedSupport == .none)
    }

    @Test("early exit with ineligible outcome does not count as failure")
    func earlyExitDoesNotTriggerFailure() {
        let diff = makeDifficulty(taskConstraints: 1, characterDirectness: 1, contextNovelty: 1)
        let earlyExit = makeOutcome(intent: .notYet, usage: .notObserved, eligible: false)
        let failOutcome = makeOutcome(intent: .notYet, usage: .inappropriate, eligible: true)

        let decision = policy.next(current: diff, outcomes: [failOutcome, earlyExit], currentSuggestedSupport: .none)
        #expect(decision.difficulty == diff)
        #expect(decision.suggestedSupport == .none)
    }

    @Test("deduplication by opportunityId prevents duplicate counting")
    func deduplicationByOpportunityId() {
        let diff = makeDifficulty(taskConstraints: 0, characterDirectness: 0, contextNovelty: 0)
        let oppId = "duplicate_opp_01"

        // Two identical outcomes with same opportunityId should deduplicate to 1 eligible -> unchanged
        let duplicates = [
            makeOutcome(opportunityId: oppId, intent: .achieved, usage: .appropriate),
            makeOutcome(opportunityId: oppId, intent: .achieved, usage: .appropriate)
        ]
        let decision1 = policy.next(current: diff, outcomes: duplicates)
        #expect(decision1.difficulty == diff)

        // Three outcomes where one is duplicated -> deduplicates to 2 unique successes -> escalates
        let threeOutcomes = [
            makeOutcome(opportunityId: oppId, intent: .achieved, usage: .appropriate),
            makeOutcome(opportunityId: oppId, intent: .achieved, usage: .appropriate),
            makeOutcome(opportunityId: "different_opp_02", intent: .achieved, usage: .appropriate)
        ]
        let decision2 = policy.next(current: diff, outcomes: threeOutcomes)
        #expect(decision2.difficulty.characterDirectness == 1)
    }

    @Test("success with high support or primed flag does not escalate difficulty")
    func successWithHighSupportOrPrimedDoesNotEscalate() {
        let diff = makeDifficulty(taskConstraints: 0, characterDirectness: 0, contextNovelty: 0)

        // Success with .frame support (> .intent) -> not valid success for escalation, not failure
        let supportedSuccesses = [
            makeOutcome(intent: .achieved, usage: .appropriate, support: .frame, primed: false),
            makeOutcome(intent: .achieved, usage: .appropriate, support: .frame, primed: false)
        ]
        let decision1 = policy.next(current: diff, outcomes: supportedSuccesses)
        #expect(decision1.difficulty == diff)
        #expect(decision1.suggestedSupport == .none)

        // Success when primed -> not valid success for escalation
        let primedSuccesses = [
            makeOutcome(intent: .achieved, usage: .appropriate, support: .none, primed: true),
            makeOutcome(intent: .achieved, usage: .appropriate, support: .none, primed: true)
        ]
        let decision2 = policy.next(current: diff, outcomes: primedSuccesses)
        #expect(decision2.difficulty == diff)
        #expect(decision2.suggestedSupport == .none)
    }
}
