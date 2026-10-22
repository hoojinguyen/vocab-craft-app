import Foundation
@testable import VocabCraftApp

/// Anchor class used for bundle localization or test fixture resource resolution.
public final class PracticeFixtureBundleAnchor: NSObject, @unchecked Sendable {}

/// Centralized test fixtures providing deterministic domain snapshots and helpers.
public enum PracticeFixtures {

    public static let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    public static func difficulty(
        taskConstraints: Int = 0,
        characterDirectness: Int = 0,
        contextNovelty: Int = 0
    ) -> PracticeDifficulty {
        // Force try is safe here because arguments default to 0 within valid 0...2 range
        // swiftlint:disable:next force_try
        try! PracticeDifficulty(
            taskConstraints: taskConstraints,
            characterDirectness: characterDirectness,
            contextNovelty: contextNovelty
        )
    }

    public static func wordSnapshot(
        wordId: Int64 = 101,
        lemma: String = "menu",
        definitionEn: String = "a list of the food available in a restaurant",
        definitionVi: String = "thực đơn đồ ăn trong nhà hàng",
        sourceDeckId: String? = "deck_food_01",
        sourceNodeId: String? = "node_dining_01"
    ) -> PracticeWordSnapshot {
        PracticeWordSnapshot(
            wordId: wordId,
            lemma: lemma,
            definitionEn: definitionEn,
            definitionVi: definitionVi,
            sourceDeckId: sourceDeckId,
            sourceNodeId: sourceNodeId
        )
    }

    public static func mission(
        wordIds: [Int64] = [101],
        contextFamily: PracticeContextFamily = .dining,
        difficulty customDifficulty: PracticeDifficulty? = nil,
        policyVersion: Int = 1
    ) throws -> PracticeMission {
        let diff = customDifficulty ?? difficulty()
        let snapshots = wordIds.map { id in
            wordSnapshot(wordId: id, lemma: "word_\(id)")
        }
        return try PracticeMission(
            id: UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")!,
            templateId: "dining_restaurant_basic",
            templateVersion: 1,
            targetWordIds: wordIds,
            wordSnapshots: snapshots,
            objectiveIds: ["order_food", "ask_bill"],
            contextFamily: contextFamily,
            difficulty: diff,
            selectionReasons: [.communicationDue],
            policyVersion: policyVersion,
            createdAt: baseDate
        )
    }

    public static func session(
        id: UUID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
        mission customMission: PracticeMission? = nil,
        revision: Int = 1,
        initialInputMode: PracticeInputMode = .voice
    ) -> PracticeSession {
        // swiftlint:disable:next force_try
        let activeMission = customMission ?? (try! mission(wordIds: [101]))
        let checkpoint = PracticeCheckpoint(
            pendingTurnId: nil,
            requestId: nil,
            presentationIntents: [],
            exposureUncertainWordIds: [],
            currentSupportLevel: .none,
            objectiveResults: [
                PracticeObjectiveResult(
                    objectiveId: "order_food",
                    intentVerdict: .achieved,
                    opportunityObserved: true
                )
            ],
            difficultyOutcomes: []
        )

        return PracticeSession(
            id: id,
            missionSnapshot: activeMission,
            status: .inProgress,
            startedAt: baseDate,
            completedAt: nil,
            checkpoint: checkpoint,
            revision: revision,
            initialInputMode: initialInputMode,
            policyVersion: 1
        )
    }

    public static func evidence(
        sessionId: UUID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
        at timestamp: Date = baseDate,
        mode: PracticeInputMode = .voice,
        primed: Bool = false,
        wordId: Int64 = 101,
        turnId: UUID = UUID(uuidString: "44444444-5555-6666-7777-888888888888")!,
        objectiveId: String = "order_food",
        usageVerdict: PracticeUsageVerdict = .appropriate,
        intentVerdict: PracticeIntentVerdict = .achieved,
        transcriptReliability: PracticeTranscriptReliability = .usable,
        supportExposureIds: [UUID] = [],
        contextFamily: PracticeContextFamily = .dining
    ) -> WordUseEvidence {
        WordUseEvidence(
            id: UUID(uuidString: "55555555-6666-7777-8888-999999999999")!,
            sessionId: sessionId,
            turnId: turnId,
            wordId: wordId,
            objectiveId: objectiveId,
            usageVerdict: usageVerdict,
            intentVerdict: intentVerdict,
            transcriptReliability: transcriptReliability,
            supportExposureIds: supportExposureIds,
            primed: primed,
            contextFamily: contextFamily,
            inputMode: mode,
            quotedSpan: "I would like to see the menu",
            assessmentVersion: 1,
            providerIdentity: "deterministic_fixture",
            status: .valid,
            timestamp: timestamp,
            turnRevision: 1,
            opportunityId: "opp_order_food_1"
        )
    }

    public static func learningContext(wordIds: [Int64] = [101]) -> PracticeLearningContext {
        let snapshots = wordIds.map { id in wordSnapshot(wordId: id) }
        let progress = wordIds.map { id in
            UserWordProgressData(
                wordId: id,
                cefrLevel: "A2",
                masteryLevel: 1,
                totalReviews: 3,
                sourceDeckId: "deck_food_01",
                sourceNodeId: "node_dining_01"
            )
        }
        let commProgress = wordIds.map { id in
            CommunicationProgress(
                wordId: id,
                inputMode: .voice,
                stage: .practicing,
                independentEvidenceIds: [],
                lastIndependentUseAt: nil,
                nextPracticeAt: baseDate.addingTimeInterval(86_400),
                recentOutcome: nil,
                policyVersion: 1
            )
        }
        let ev = wordIds.map { id in
            evidence(wordId: id)
        }

        return PracticeLearningContext(
            words: snapshots,
            progress: progress,
            communication: commProgress,
            evidence: ev,
            recentReflexWordIds: Set(wordIds)
        )
    }

    public static func sessionSnapshot(
        revision: Int = 1,
        wordId: Int64 = 101,
        sessionId: UUID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
    ) -> PracticeSessionSnapshot {
        // swiftlint:disable:next force_try
        let activeMission = try! mission(wordIds: [wordId])
        let activeSession = session(
            id: sessionId,
            mission: activeMission,
            revision: revision,
            initialInputMode: .voice
        )
        let turn = PracticeTurn(
            id: UUID(uuidString: "33333333-4444-5555-6666-777777777777")!,
            sessionId: sessionId,
            sequence: 1,
            speaker: .learner,
            inputMode: .voice,
            originalText: "Could I have the menu please?",
            acceptedText: "Could I have the menu please?",
            transcriptStatus: .final,
            generationStatus: .succeeded,
            requestId: "req-001",
            sessionRevision: revision,
            timestamp: baseDate
        )
        let ev = evidence(sessionId: sessionId, at: baseDate, mode: .voice, primed: false, wordId: wordId)
        let comm = CommunicationProgress(
            wordId: wordId,
            inputMode: .voice,
            stage: .independentFamiliar,
            independentEvidenceIds: [ev.id],
            lastIndependentUseAt: baseDate,
            nextPracticeAt: baseDate.addingTimeInterval(259_200),
            recentOutcome: PracticeOpportunityOutcome(
                wordId: wordId,
                objectiveId: "order_food",
                success: true,
                supportLevel: .none,
                primed: false
            ),
            policyVersion: 1
        )
        let intent = PracticePresentationIntent(
            id: UUID(uuidString: "66666666-7777-8888-9999-000000000000")!,
            sessionId: sessionId,
            turnId: turn.id,
            content: "You could ask for the menu",
            channel: .visual,
            possibleWordIds: [wordId],
            proposedLevel: .intent,
            status: .pending
        )

        return PracticeSessionSnapshot(
            session: activeSession,
            turns: [turn],
            exposures: [],
            evidence: [ev],
            progress: [comm],
            pendingPresentations: [intent]
        )
    }
}
