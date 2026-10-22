import Foundation
@testable import VocabCraftApp

/// Anchor class used for bundle localization or test fixture resource resolution.
public final class PracticeFixtureBundleAnchor: NSObject, @unchecked Sendable {}

/// Decodable representation of curated practice assessment test cases.
public struct PracticeAssessmentFixtureCase: Codable, Sendable {
    public let id: String
    public let description: String
    public let acceptedText: String
    public let inputMode: PracticeInputMode
    public let transcriptStatus: PracticeTranscriptStatus
    public let targetWordIds: [Int64]
    public let objectiveIds: [String]
    public let response: PracticeAIResponse
    public let exposures: [SupportExposure]
    public let uncertainWordIds: [Int64]
    public let expectedValid: Bool
    public let expectedUsageVerdict: PracticeUsageVerdict?
    public let expectedIntentVerdict: PracticeIntentVerdict?
    public let expectedReliability: PracticeTranscriptReliability?
    public let expectedPrimed: Bool?
    public let expectedQuotedSpan: String?
}

/// Centralized test fixtures providing deterministic domain snapshots and helpers.
public enum PracticeFixtures {
    public static let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    public static func loadAssessmentCases() throws -> [PracticeAssessmentFixtureCase] {
        let bundle: Bundle
        #if SWIFT_PACKAGE
        bundle = Bundle.module
        #else
        bundle = Bundle(for: PracticeFixtureBundleAnchor.self)
        #endif

        guard let url = bundle.url(forResource: "practice-assessment-cases", withExtension: "json") ??
                        bundle.url(forResource: "practice-assessment-cases", withExtension: "json", subdirectory: "Fixtures") ??
                        bundle.url(forResource: "practice-assessment-cases", withExtension: "json", subdirectory: "AI/GuidedPractice/Fixtures") else {
            throw PracticeFailure(code: .storage, message: "Missing practice-assessment-cases.json resource in test bundle")
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode([PracticeAssessmentFixtureCase].self, from: data)
    }

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

    public static func evidenceWithVersions(
        id: UUID = UUID(),
        sessionId: UUID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
        turnId: UUID = UUID(uuidString: "22222222-3333-4444-5555-666666666666")!,
        wordId: Int64 = 101,
        turnRevision: Int = 1,
        assessmentVersion: Int = 1,
        status: PracticeEvidenceStatus = .valid,
        timestamp: Date = baseDate
    ) -> WordUseEvidence {
        WordUseEvidence(
            id: id,
            sessionId: sessionId,
            turnId: turnId,
            wordId: wordId,
            objectiveId: "order_food",
            usageVerdict: .appropriate,
            intentVerdict: .achieved,
            transcriptReliability: .usable,
            supportExposureIds: [],
            primed: false,
            contextFamily: .dining,
            inputMode: .voice,
            quotedSpan: nil,
            assessmentVersion: assessmentVersion,
            providerIdentity: "test_evaluator",
            status: status,
            timestamp: timestamp,
            turnRevision: turnRevision,
            opportunityId: "opp-01"
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
        let evidenceList = wordIds.map { id in
            evidence(wordId: id)
        }

        return PracticeLearningContext(
            words: snapshots,
            progress: progress,
            communication: commProgress,
            evidence: evidenceList,
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
        let evidenceRecord = evidence(sessionId: sessionId, at: baseDate, mode: .voice, primed: false, wordId: wordId)
        let comm = CommunicationProgress(
            wordId: wordId,
            inputMode: .voice,
            stage: .independentFamiliar,
            independentEvidenceIds: [evidenceRecord.id],
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
            evidence: [evidenceRecord],
            progress: [comm],
            pendingPresentations: [intent]
        )
    }
}

// MARK: - SwiftData Test Storage Helpers

#if canImport(SwiftData)
import SwiftData

public struct PracticeTestSRSState: Equatable, Sendable {
    public let wordId: Int64
    public let cefrLevel: String
    public let masteryLevel: Int
    public let easeFactor: Double
    public let intervalDays: Int
    public let nextReviewDate: Date
    public let totalReviews: Int
    public let mistakeCount: Int
    public let sourceDeckId: String?
}

@MainActor
public enum PracticeTestStorage {
    public static func createContainer(storeURL: URL? = nil) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV3.self)
        if let storeURL {
            let config = ModelConfiguration(schema: schema, url: storeURL)
            return try ModelContainer(for: schema, migrationPlan: AppMigrationPlan.self, configurations: [config])
        } else {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [config])
        }
    }

    public static func seedBaselineSRS(in container: ModelContainer, wordId: Int64 = 101) throws -> PracticeTestSRSState {
        let baselineDate = Date(timeIntervalSince1970: 1_700_000_000)
        let srsWord = SchemaV3.UserWordProgress(
            wordId: wordId,
            cefrLevel: "B1",
            masteryLevel: 3,
            isBookmarked: true,
            easeFactor: 2.45,
            intervalDays: 14,
            nextReviewDate: baselineDate,
            lastReviewDate: baselineDate,
            totalReviews: 8,
            needsReview: false,
            mistakeCount: 2,
            sourceDeckId: "deck_culinary_art",
            sourceNodeId: "node_dining_01"
        )
        container.mainContext.insert(srsWord)
        try container.mainContext.save()

        return PracticeTestSRSState(
            wordId: srsWord.wordId,
            cefrLevel: srsWord.cefrLevel,
            masteryLevel: srsWord.masteryLevel,
            easeFactor: srsWord.easeFactor,
            intervalDays: srsWord.intervalDays,
            nextReviewDate: srsWord.nextReviewDate,
            totalReviews: srsWord.totalReviews,
            mistakeCount: srsWord.mistakeCount,
            sourceDeckId: srsWord.sourceDeckId
        )
    }

    public static func fetchSRSState(in container: ModelContainer, wordId: Int64 = 101) throws -> PracticeTestSRSState? {
        let descriptor = FetchDescriptor<SchemaV3.UserWordProgress>(
            predicate: #Predicate { $0.wordId == wordId }
        )
        guard let item = try container.mainContext.fetch(descriptor).first else {
            return nil
        }
        return PracticeTestSRSState(
            wordId: item.wordId,
            cefrLevel: item.cefrLevel,
            masteryLevel: item.masteryLevel,
            easeFactor: item.easeFactor,
            intervalDays: item.intervalDays,
            nextReviewDate: item.nextReviewDate,
            totalReviews: item.totalReviews,
            mistakeCount: item.mistakeCount,
            sourceDeckId: item.sourceDeckId
        )
    }
}
#endif
