import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Practice Summary Retrospective Tests")
@MainActor
struct PracticeSummaryTests {
    @Test("Summary model strictly excludes legacy fluency score and XP awards")
    func summaryExcludesFluencyScoreAndXP() {
        let summary = PracticeSummary(
            sessionId: UUID(),
            status: .completed,
            objectiveResults: [
                PracticeObjectiveResult(objectiveId: "order_food", intentVerdict: .achieved, opportunityObserved: true)
            ],
            perWordProgress: [],
            evidenceIds: [UUID()],
            persisted: true
        )

        // Reflection verification to ensure no legacy gamification properties leaked into domain contract
        let mirror = Mirror(reflecting: summary)
        let propertyNames = mirror.children.compactMap(\.label)

        #expect(!propertyNames.contains("fluency"))
        #expect(!propertyNames.contains("fluencyScore"))
        #expect(!propertyNames.contains("xp"))
        #expect(!propertyNames.contains("xpEarned"))
        #expect(!propertyNames.contains("masteryIncrement"))

        #expect(propertyNames.contains("sessionId"))
        #expect(propertyNames.contains("status"))
        #expect(propertyNames.contains("objectiveResults"))
        #expect(propertyNames.contains("perWordProgress"))
        #expect(propertyNames.contains("evidenceIds"))
        #expect(propertyNames.contains("persisted"))
    }

    @Test("Partial session marks unattempted objectives as notObserved, never failed")
    func partialSessionMarksUnattemptedObjectivesAsNotObserved() {
        let achievedResult = PracticeObjectiveResult(
            objectiveId: "order_food",
            intentVerdict: .achieved,
            opportunityObserved: true
        )
        let unattemptedResult = PracticeObjectiveResult(
            objectiveId: "express_gratitude",
            intentVerdict: .notYet,
            opportunityObserved: false
        )
        let attemptedNotYetResult = PracticeObjectiveResult(
            objectiveId: "ask_recommendation",
            intentVerdict: .notYet,
            opportunityObserved: true
        )

        // 1. In a partial session: unattempted objective MUST be notObserved
        let unattemptedDisplay = PracticeSummaryView.objectiveStatus(
            for: unattemptedResult,
            sessionStatus: .partial
        )
        #expect(unattemptedDisplay == .notObserved)

        // 2. In a partial session: attempted but not achieved is notYet
        let attemptedDisplay = PracticeSummaryView.objectiveStatus(
            for: attemptedNotYetResult,
            sessionStatus: .partial
        )
        #expect(attemptedDisplay == .notYet)

        // 3. In a completed session: attempted achieved is achieved
        let completedAchieved = PracticeSummaryView.objectiveStatus(
            for: achievedResult,
            sessionStatus: .completed
        )
        #expect(completedAchieved == .achieved)
    }

    @Test("Evidence rows distinguish voice, typed, and edited modalities")
    func evidenceRowsDistinguishVoiceTextAndEdited() {
        let voiceTitle = PracticeSummaryView.inputModeBadgeTitle(for: .voice)
        let typedTitle = PracticeSummaryView.inputModeBadgeTitle(for: .typed)
        let editedTitle = PracticeSummaryView.inputModeBadgeTitle(for: .editedTranscript)

        #expect(voiceTitle == AppStrings.GuidedPractice.modeVoice)
        #expect(typedTitle == AppStrings.GuidedPractice.modeTyped)
        #expect(editedTitle == AppStrings.GuidedPractice.modeEdited)

        #expect(voiceTitle != typedTitle)
        #expect(typedTitle != editedTitle)
    }

    @Test("Evidence rows display quoted span and support status")
    func evidenceRowsDisplayQuotedSpanAndSupport() {
        let evidenceWithSpan = WordUseEvidence(
            id: UUID(),
            sessionId: UUID(),
            turnId: UUID(),
            wordId: 4,
            objectiveId: "order_food",
            usageVerdict: .appropriate,
            intentVerdict: .achieved,
            transcriptReliability: .usable,
            supportExposureIds: [UUID()],
            primed: true,
            contextFamily: .dining,
            inputMode: .voice,
            quotedSpan: "delicious coffee",
            timestamp: Date()
        )

        let formattedSpan = PracticeSummaryView.formattedQuotedSpan(for: evidenceWithSpan)
        #expect(formattedSpan == "\"delicious coffee\"")

        let primedBadge = PracticeSummaryView.supportBadgeTitle(primed: evidenceWithSpan.primed)
        #expect(primedBadge == AppStrings.GuidedPractice.supportPrimed)

        let unprimedBadge = PracticeSummaryView.supportBadgeTitle(primed: false)
        #expect(unprimedBadge == AppStrings.GuidedPractice.supportIndependent)

        let evidenceEmptySpan = WordUseEvidence(
            id: UUID(),
            sessionId: UUID(),
            turnId: UUID(),
            wordId: 4,
            objectiveId: "order_food",
            usageVerdict: .appropriate,
            intentVerdict: .achieved,
            transcriptReliability: .usable,
            primed: false,
            contextFamily: .dining,
            inputMode: .typed,
            quotedSpan: nil,
            timestamp: Date()
        )
        #expect(PracticeSummaryView.formattedQuotedSpan(for: evidenceEmptySpan) == nil)
    }
}
