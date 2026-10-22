#if canImport(SwiftDataMacros) || canImport(SwiftData)
import Foundation
import SwiftData
@testable import VocabCraftApp
import XCTest

final class GuidedPracticeMigrationTests: XCTestCase {
    private var tempDirectory: URL!
    private var storeURL: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try! FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        storeURL = tempDirectory.appendingPathComponent("test_guided_practice_migration.sqlite")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Test 1: V2 -> V3 Migration Preserves SourceDeck & SRS

    @MainActor
    func test_v2ToV3PreservesSourceAndSRS() throws {
        // Step 1: Arrange V2 baseline data on disk
        let baselineDate1 = Date(timeIntervalSince1970: 1_700_000_000)
        let baselineDate2 = Date(timeIntervalSince1970: 1_699_000_000)
        let sessionID = UUID()
        let attemptID = UUID()

        let v2Schema = Schema(versionedSchema: SchemaV2.self)
        let v2Config = ModelConfiguration(schema: v2Schema, url: storeURL)
        let v2Container = try ModelContainer(for: v2Schema, migrationPlan: AppMigrationPlan.self, configurations: [v2Config])

        let baselineWord = SchemaV2.UserWordProgress(
            wordId: 101,
            cefrLevel: "B1",
            masteryLevel: 3,
            isBookmarked: true,
            easeFactor: 2.4,
            intervalDays: 14,
            nextReviewDate: baselineDate1,
            lastReviewDate: baselineDate2,
            totalReviews: 8,
            needsReview: true,
            mistakeCount: 2,
            sourceDeckId: "deck_travel_essential",
            sourceNodeId: "node_day_5",
            consecutiveCorrectStreak: 4,
            practicedModesRaw: "flashcard,quiz",
            isMastered: false,
            modeSuccessCountsRaw: "flashcard:3,quiz:1"
        )
        v2Container.mainContext.insert(baselineWord)

        let baselineStage = SchemaV2.UserStageProgress(
            stageId: "stage_travel_1",
            deckId: "deck_travel_essential",
            isCompleted: true,
            score: 90,
            progressFraction: 1.0,
            completedAt: baselineDate1
        )
        v2Container.mainContext.insert(baselineStage)

        let baselineReflex = SchemaV2.ReflexSessionLog(
            id: sessionID,
            drillId: 301,
            responseTimeMs: 750,
            accuracyScore: 0.9,
            timestamp: baselineDate1
        )
        v2Container.mainContext.insert(baselineReflex)

        let baselineWidget = SchemaV2.WidgetCurrentState(
            id: "current",
            currentWordId: 101,
            lemma: "journey",
            ipaUs: "/ˈdʒɜː.ni/",
            definitionVi: "chuyến đi",
            exampleEn: "Safe journey!",
            lastUpdated: baselineDate1
        )
        v2Container.mainContext.insert(baselineWidget)

        let baselineAttempt = SchemaV2.QuickReflexAttemptRecord(
            id: attemptID,
            wordId: 101,
            recallWordTimeMs: 300,
            collocationTimeMs: 250,
            produceSentenceTimeMs: 600,
            recallWordSucceeded: true,
            collocationSucceeded: true,
            produceSentenceSucceeded: true,
            shadowPronunciationScore: 0.88,
            maxHintLevel: 1,
            inputModeRawValue: "voice",
            retryCount: 0,
            confidenceRawValue: "high",
            timestamp: baselineDate1
        )
        v2Container.mainContext.insert(baselineAttempt)

        try v2Container.mainContext.save()

        // Step 2: Open exact same SQLite store with SchemaV3 using AppMigrationPlan
        let v3Schema = Schema(versionedSchema: SchemaV3.self)
        let v3Config = ModelConfiguration(schema: v3Schema, url: storeURL)
        let v3Container = try ModelContainer(for: v3Schema, migrationPlan: AppMigrationPlan.self, configurations: [v3Config])

        // Step 3: Verify UserWordProgress preserves all SRS and source metadata
        let wordDesc = FetchDescriptor<SchemaV3.UserWordProgress>(predicate: #Predicate { $0.wordId == 101 })
        let words = try v3Container.mainContext.fetch(wordDesc)
        XCTAssertEqual(words.count, 1)

        let migrated = try XCTUnwrap(words.first)
        // Mandatory assertions specified by brief
        XCTAssertEqual(migrated.sourceDeckId, baselineWord.sourceDeckId)
        XCTAssertEqual(migrated.nextReviewDate, baselineWord.nextReviewDate)
        XCTAssertEqual(migrated.masteryLevel, baselineWord.masteryLevel)

        // Comprehensive attribute equality checks
        XCTAssertEqual(migrated.wordId, baselineWord.wordId)
        XCTAssertEqual(migrated.cefrLevel, baselineWord.cefrLevel)
        XCTAssertEqual(migrated.isBookmarked, baselineWord.isBookmarked)
        XCTAssertEqual(migrated.easeFactor, baselineWord.easeFactor)
        XCTAssertEqual(migrated.intervalDays, baselineWord.intervalDays)
        XCTAssertEqual(migrated.lastReviewDate, baselineWord.lastReviewDate)
        XCTAssertEqual(migrated.totalReviews, baselineWord.totalReviews)
        XCTAssertEqual(migrated.needsReview, baselineWord.needsReview)
        XCTAssertEqual(migrated.mistakeCount, baselineWord.mistakeCount)
        XCTAssertEqual(migrated.sourceNodeId, baselineWord.sourceNodeId)
        XCTAssertEqual(migrated.consecutiveCorrectStreak, baselineWord.consecutiveCorrectStreak)
        XCTAssertEqual(migrated.correctStreak, baselineWord.correctStreak)
        XCTAssertEqual(migrated.practicedModesRaw, baselineWord.practicedModesRaw)
        XCTAssertEqual(migrated.isMastered, baselineWord.isMastered)
        XCTAssertEqual(migrated.modeSuccessCountsRaw, baselineWord.modeSuccessCountsRaw)

        // Step 4: Verify existing UserStageProgress is preserved
        let stageDesc = FetchDescriptor<SchemaV3.UserStageProgress>(predicate: #Predicate { $0.stageId == "stage_travel_1" })
        let stages = try v3Container.mainContext.fetch(stageDesc)
        XCTAssertEqual(stages.count, 1)
        let migratedStage = try XCTUnwrap(stages.first)
        XCTAssertEqual(migratedStage.deckId, "deck_travel_essential")
        XCTAssertEqual(migratedStage.isCompleted, true)
        XCTAssertEqual(migratedStage.score, 90)
        XCTAssertEqual(migratedStage.progressFraction, 1.0)
        XCTAssertEqual(migratedStage.completedAt, baselineDate1)

        // Step 5: Verify ReflexSessionLog is preserved
        let reflexDesc = FetchDescriptor<SchemaV3.ReflexSessionLog>(predicate: #Predicate { $0.id == sessionID })
        let reflexes = try v3Container.mainContext.fetch(reflexDesc)
        XCTAssertEqual(reflexes.count, 1)
        let migratedReflex = try XCTUnwrap(reflexes.first)
        XCTAssertEqual(migratedReflex.drillId, 301)
        XCTAssertEqual(migratedReflex.responseTimeMs, 750)
        XCTAssertEqual(migratedReflex.accuracyScore, 0.9)
        XCTAssertEqual(migratedReflex.timestamp, baselineDate1)

        // Step 6: Verify WidgetCurrentState is preserved
        let widgetDesc = FetchDescriptor<SchemaV3.WidgetCurrentState>(predicate: #Predicate { $0.id == "current" })
        let widgets = try v3Container.mainContext.fetch(widgetDesc)
        XCTAssertEqual(widgets.count, 1)
        let migratedWidget = try XCTUnwrap(widgets.first)
        XCTAssertEqual(migratedWidget.currentWordId, 101)
        XCTAssertEqual(migratedWidget.lemma, "journey")
        XCTAssertEqual(migratedWidget.ipaUs, "/ˈdʒɜː.ni/")
        XCTAssertEqual(migratedWidget.definitionVi, "chuyến đi")
        XCTAssertEqual(migratedWidget.exampleEn, "Safe journey!")
        XCTAssertEqual(migratedWidget.lastUpdated, baselineDate1)

        // Step 7: Verify QuickReflexAttemptRecord is preserved
        let attemptDesc = FetchDescriptor<SchemaV3.QuickReflexAttemptRecord>(predicate: #Predicate { $0.id == attemptID })
        let attempts = try v3Container.mainContext.fetch(attemptDesc)
        XCTAssertEqual(attempts.count, 1)
        let migratedAttempt = try XCTUnwrap(attempts.first)
        XCTAssertEqual(migratedAttempt.wordId, 101)
        XCTAssertEqual(migratedAttempt.recallWordTimeMs, 300)
        XCTAssertEqual(migratedAttempt.collocationTimeMs, 250)
        XCTAssertEqual(migratedAttempt.produceSentenceTimeMs, 600)
        XCTAssertEqual(migratedAttempt.recallWordSucceeded, true)
        XCTAssertEqual(migratedAttempt.collocationSucceeded, true)
        XCTAssertEqual(migratedAttempt.produceSentenceSucceeded, true)
        XCTAssertEqual(migratedAttempt.shadowPronunciationScore, 0.88)
        XCTAssertEqual(migratedAttempt.maxHintLevel, 1)
        XCTAssertEqual(migratedAttempt.inputModeRawValue, "voice")
        XCTAssertEqual(migratedAttempt.retryCount, 0)
        XCTAssertEqual(migratedAttempt.confidenceRawValue, "high")
        XCTAssertEqual(migratedAttempt.timestamp, baselineDate1)
    }

    // MARK: - Test 2: V1 -> V3 Multi-Hop Lightweight Migration Preserves Historical Records

    @MainActor
    func test_v1ToV3PreservesHistoricalRecords() throws {
        // Step 1: Arrange SchemaV1 store on disk
        let date1 = Date(timeIntervalSince1970: 1_700_000_000)
        let sessionID = UUID()

        let v1Schema = Schema(versionedSchema: SchemaV1.self)
        let v1Config = ModelConfiguration(schema: v1Schema, url: storeURL)
        let v1Container = try ModelContainer(for: v1Schema, configurations: [v1Config])

        let v1Word = SchemaV1.UserWordProgress(
            wordId: 202,
            repetitionLevel: 2,
            interval: 5.0,
            easeFactor: 2.7,
            nextReviewDate: date1,
            isBookmarked: true,
            isMastered: false,
            correctStreak: 3,
            mistakeCount: 1,
            lastReviewedAt: date1,
            modeSuccessCountsRaw: "s:2"
        )
        v1Container.mainContext.insert(v1Word)

        let v1Session = SchemaV1.ReflexSessionLog(
            id: sessionID,
            drillId: 404,
            responseTimeMs: 820,
            accuracyScore: 0.95,
            timestamp: date1
        )
        v1Container.mainContext.insert(v1Session)

        let v1Widget = SchemaV1.WidgetCurrentState(
            id: "current",
            activeWord: "perseverance",
            phonetic: "/ˌpɜː.sɪˈvɪə.rəns/",
            meaningVi: "sự kiên trì",
            exampleSentence: "Success requires perseverance.",
            updatedAt: date1
        )
        v1Container.mainContext.insert(v1Widget)
        try v1Container.mainContext.save()

        // Step 2: Open directly with SchemaV3 via AppMigrationPlan (V1 -> V2 -> V3 lightweight chain)
        let v3Schema = Schema(versionedSchema: SchemaV3.self)
        let v3Config = ModelConfiguration(schema: v3Schema, url: storeURL)
        let v3Container = try ModelContainer(for: v3Schema, migrationPlan: AppMigrationPlan.self, configurations: [v3Config])

        // Step 3: Verify migrated UserWordProgress
        let wordDesc = FetchDescriptor<SchemaV3.UserWordProgress>(predicate: #Predicate { $0.wordId == 202 })
        let words = try v3Container.mainContext.fetch(wordDesc)
        XCTAssertEqual(words.count, 1)

        let migrated = try XCTUnwrap(words.first)
        XCTAssertEqual(migrated.wordId, 202)
        XCTAssertEqual(migrated.nextReviewDate, date1)
        XCTAssertEqual(migrated.easeFactor, 2.7)
        XCTAssertEqual(migrated.consecutiveCorrectStreak, 3)
        XCTAssertEqual(migrated.isBookmarked, true)
        XCTAssertEqual(migrated.isMastered, false)
        XCTAssertEqual(migrated.mistakeCount, 1)

        // Step 4: Verify ReflexSessionLog
        let reflexDesc = FetchDescriptor<SchemaV3.ReflexSessionLog>(predicate: #Predicate { $0.id == sessionID })
        let reflexes = try v3Container.mainContext.fetch(reflexDesc)
        XCTAssertEqual(reflexes.count, 1)
        XCTAssertEqual(reflexes.first?.drillId, 404)
        XCTAssertEqual(reflexes.first?.responseTimeMs, 820)

        // Step 5: Verify WidgetCurrentState
        let widgetDesc = FetchDescriptor<SchemaV3.WidgetCurrentState>(predicate: #Predicate { $0.id == "current" })
        let widgets = try v3Container.mainContext.fetch(widgetDesc)
        XCTAssertEqual(widgets.count, 1)
        XCTAssertEqual(widgets.first?.lemma, "perseverance")
        XCTAssertEqual(widgets.first?.definitionVi, "sự kiên trì")
    }

    // MARK: - Test 3: All 6 New SchemaV3 Records Inserted, Fetched, and Reopened

    @MainActor
    func test_schemaV3_allSixNewRecordsCanBeInsertedFetchedAndReopened() throws {
        let v3Schema = Schema(versionedSchema: SchemaV3.self)
        let v3Config = ModelConfiguration(schema: v3Schema, url: storeURL)
        let v3Container = try ModelContainer(for: v3Schema, migrationPlan: AppMigrationPlan.self, configurations: [v3Config])

        let sampleJSON = try JSONEncoder().encode(["key": "test_payload"])
        let fixtures = try seedSchemaV3Records(in: v3Container, payload: sampleJSON)

        // Reopen store in a brand new ModelContainer
        let reopenedContainer = try ModelContainer(for: v3Schema, migrationPlan: AppMigrationPlan.self, configurations: [v3Config])

        try verifySessionAndTurnRecords(in: reopenedContainer, fixtures: fixtures, payload: sampleJSON)
        try verifyExposureAndPresentationRecords(in: reopenedContainer, fixtures: fixtures, payload: sampleJSON)
        try verifyEvidenceAndProgressRecords(in: reopenedContainer, fixtures: fixtures, payload: sampleJSON)
    }

    private struct SchemaV3Fixtures {
        let sessionId: UUID
        let turnId: UUID
        let exposureId: UUID
        let presentationId: UUID
        let evidenceId: UUID
        let timestamp: Date
    }

    @MainActor
    private func seedSchemaV3Records(in container: ModelContainer, payload: Data) throws -> SchemaV3Fixtures {
        let sessionId = UUID()
        let turnId = UUID()
        let exposureId = UUID()
        let presentationId = UUID()
        let evidenceId = UUID()
        let timestamp = Date(timeIntervalSince1970: 1_710_000_000)

        // 1. PracticeSessionRecord
        let sessionRecord = SchemaV3.PracticeSessionRecord(
            id: sessionId,
            revision: 2,
            statusRaw: "active",
            initialInputModeRaw: "voice",
            policyVersion: 1,
            startedAt: timestamp,
            completedAt: nil,
            payloadJSON: payload,
            formatVersion: 1
        )
        container.mainContext.insert(sessionRecord)

        // 2. PracticeTurnRecord
        let turnRecord = SchemaV3.PracticeTurnRecord(
            id: turnId,
            sessionId: sessionId,
            sequence: 1,
            speakerRaw: "learner",
            inputModeRaw: "voice",
            sessionRevision: 2,
            timestamp: timestamp,
            payloadJSON: payload,
            formatVersion: 1
        )
        container.mainContext.insert(turnRecord)

        // 3. SupportExposureRecord
        let exposureRecord = SchemaV3.SupportExposureRecord(
            id: exposureId,
            sessionId: sessionId,
            turnId: turnId,
            targetWordIdsRaw: "101,102",
            levelRaw: "visualScaffold",
            originRaw: "characterTurn",
            channelRaw: "visual",
            presentedAt: timestamp,
            payloadJSON: payload,
            formatVersion: 1
        )
        container.mainContext.insert(exposureRecord)

        // 4. PracticePresentationRecord
        let presentationRecord = SchemaV3.PracticePresentationRecord(
            id: presentationId,
            sessionId: sessionId,
            turnId: turnId,
            statusRaw: "pending",
            channelRaw: "visual",
            proposedLevelRaw: "scaffolded",
            possibleWordIdsRaw: "101,102",
            payloadJSON: payload,
            formatVersion: 1
        )
        container.mainContext.insert(presentationRecord)

        // 5. WordUseEvidenceRecord
        let evidenceRecord = SchemaV3.WordUseEvidenceRecord(
            id: evidenceId,
            sessionId: sessionId,
            turnId: turnId,
            wordId: 101,
            objectiveId: "obj_greet",
            usageVerdictRaw: "appropriate",
            intentVerdictRaw: "achieved",
            transcriptReliabilityRaw: "usable",
            inputModeRaw: "voice",
            statusRaw: "valid",
            primed: false,
            timestamp: timestamp,
            payloadJSON: payload,
            formatVersion: 1
        )
        container.mainContext.insert(evidenceRecord)

        // 6. CommunicationProgressRecord
        let progressRecord = SchemaV3.CommunicationProgressRecord(
            wordId: 101,
            inputModeRaw: "voice",
            stageRaw: "independentProduction",
            lastIndependentUseAt: timestamp,
            nextPracticeAt: timestamp.addingTimeInterval(86400),
            policyVersion: 1,
            payloadJSON: payload,
            formatVersion: 1
        )
        container.mainContext.insert(progressRecord)

        try container.mainContext.save()
        return SchemaV3Fixtures(
            sessionId: sessionId,
            turnId: turnId,
            exposureId: exposureId,
            presentationId: presentationId,
            evidenceId: evidenceId,
            timestamp: timestamp
        )
    }

    @MainActor
    private func verifySessionAndTurnRecords(
        in container: ModelContainer,
        fixtures: SchemaV3Fixtures,
        payload: Data
    ) throws {
        let targetSessionId = fixtures.sessionId
        let fetchedSessions = try container.mainContext.fetch(FetchDescriptor<SchemaV3.PracticeSessionRecord>(
            predicate: #Predicate { $0.id == targetSessionId }
        ))
        XCTAssertEqual(fetchedSessions.count, 1)
        let session = try XCTUnwrap(fetchedSessions.first)
        XCTAssertEqual(session.id, fixtures.sessionId)
        XCTAssertEqual(session.revision, 2)
        XCTAssertEqual(session.statusRaw, "active")
        XCTAssertEqual(session.initialInputModeRaw, "voice")
        XCTAssertEqual(session.policyVersion, 1)
        XCTAssertEqual(session.startedAt, fixtures.timestamp)
        XCTAssertNil(session.completedAt)
        XCTAssertEqual(session.payloadJSON, payload)
        XCTAssertEqual(session.formatVersion, 1)

        let targetTurnId = fixtures.turnId
        let fetchedTurns = try container.mainContext.fetch(FetchDescriptor<SchemaV3.PracticeTurnRecord>(
            predicate: #Predicate { $0.id == targetTurnId }
        ))
        XCTAssertEqual(fetchedTurns.count, 1)
        let turn = try XCTUnwrap(fetchedTurns.first)
        XCTAssertEqual(turn.id, fixtures.turnId)
        XCTAssertEqual(turn.sessionId, fixtures.sessionId)
        XCTAssertEqual(turn.sequence, 1)
        XCTAssertEqual(turn.speakerRaw, "learner")
        XCTAssertEqual(turn.inputModeRaw, "voice")
        XCTAssertEqual(turn.sessionRevision, 2)
        XCTAssertEqual(turn.timestamp, fixtures.timestamp)
        XCTAssertEqual(turn.payloadJSON, payload)
        XCTAssertEqual(turn.formatVersion, 1)
    }

    @MainActor
    private func verifyExposureAndPresentationRecords(
        in container: ModelContainer,
        fixtures: SchemaV3Fixtures,
        payload: Data
    ) throws {
        let targetExposureId = fixtures.exposureId
        let fetchedExposures = try container.mainContext.fetch(FetchDescriptor<SchemaV3.SupportExposureRecord>(
            predicate: #Predicate { $0.id == targetExposureId }
        ))
        XCTAssertEqual(fetchedExposures.count, 1)
        let exposure = try XCTUnwrap(fetchedExposures.first)
        XCTAssertEqual(exposure.id, fixtures.exposureId)
        XCTAssertEqual(exposure.sessionId, fixtures.sessionId)
        XCTAssertEqual(exposure.turnId, fixtures.turnId)
        XCTAssertEqual(exposure.targetWordIdsRaw, "101,102")
        XCTAssertEqual(exposure.levelRaw, "visualScaffold")
        XCTAssertEqual(exposure.originRaw, "characterTurn")
        XCTAssertEqual(exposure.channelRaw, "visual")
        XCTAssertEqual(exposure.presentedAt, fixtures.timestamp)
        XCTAssertEqual(exposure.payloadJSON, payload)
        XCTAssertEqual(exposure.formatVersion, 1)

        let targetPresentationId = fixtures.presentationId
        let fetchedPresentations = try container.mainContext.fetch(FetchDescriptor<SchemaV3.PracticePresentationRecord>(
            predicate: #Predicate { $0.id == targetPresentationId }
        ))
        XCTAssertEqual(fetchedPresentations.count, 1)
        let presentation = try XCTUnwrap(fetchedPresentations.first)
        XCTAssertEqual(presentation.id, fixtures.presentationId)
        XCTAssertEqual(presentation.sessionId, fixtures.sessionId)
        XCTAssertEqual(presentation.turnId, fixtures.turnId)
        XCTAssertEqual(presentation.statusRaw, "pending")
        XCTAssertEqual(presentation.channelRaw, "visual")
        XCTAssertEqual(presentation.proposedLevelRaw, "scaffolded")
        XCTAssertEqual(presentation.possibleWordIdsRaw, "101,102")
        XCTAssertEqual(presentation.payloadJSON, payload)
        XCTAssertEqual(presentation.formatVersion, 1)
    }

    @MainActor
    private func verifyEvidenceAndProgressRecords(
        in container: ModelContainer,
        fixtures: SchemaV3Fixtures,
        payload: Data
    ) throws {
        let targetEvidenceId = fixtures.evidenceId
        let fetchedEvidences = try container.mainContext.fetch(FetchDescriptor<SchemaV3.WordUseEvidenceRecord>(
            predicate: #Predicate { $0.id == targetEvidenceId }
        ))
        XCTAssertEqual(fetchedEvidences.count, 1)
        let evidence = try XCTUnwrap(fetchedEvidences.first)
        XCTAssertEqual(evidence.id, fixtures.evidenceId)
        XCTAssertEqual(evidence.sessionId, fixtures.sessionId)
        XCTAssertEqual(evidence.turnId, fixtures.turnId)
        XCTAssertEqual(evidence.wordId, 101)
        XCTAssertEqual(evidence.objectiveId, "obj_greet")
        XCTAssertEqual(evidence.usageVerdictRaw, "appropriate")
        XCTAssertEqual(evidence.intentVerdictRaw, "achieved")
        XCTAssertEqual(evidence.transcriptReliabilityRaw, "usable")
        XCTAssertEqual(evidence.inputModeRaw, "voice")
        XCTAssertEqual(evidence.statusRaw, "valid")
        XCTAssertEqual(evidence.primed, false)
        XCTAssertEqual(evidence.timestamp, fixtures.timestamp)
        XCTAssertEqual(evidence.payloadJSON, payload)
        XCTAssertEqual(evidence.formatVersion, 1)

        let fetchedProgresses = try container.mainContext.fetch(FetchDescriptor<SchemaV3.CommunicationProgressRecord>(
            predicate: #Predicate { $0.logicalKey == "101_voice" }
        ))
        XCTAssertEqual(fetchedProgresses.count, 1)
        let progress = try XCTUnwrap(fetchedProgresses.first)
        XCTAssertEqual(progress.logicalKey, "101_voice")
        XCTAssertEqual(progress.wordId, 101)
        XCTAssertEqual(progress.inputModeRaw, "voice")
        XCTAssertEqual(progress.stageRaw, "independentProduction")
        XCTAssertEqual(progress.lastIndependentUseAt, fixtures.timestamp)
        XCTAssertEqual(progress.nextPracticeAt, fixtures.timestamp.addingTimeInterval(86400))
        XCTAssertEqual(progress.policyVersion, 1)
        XCTAssertEqual(progress.payloadJSON, payload)
        XCTAssertEqual(progress.formatVersion, 1)
    }

    // MARK: - Test 4: Reopen Retains Pending PracticePresentationRecord

    @MainActor
    func test_reopenRetainsPendingPracticePresentationRecord() throws {
        let v3Schema = Schema(versionedSchema: SchemaV3.self)
        let v3Config = ModelConfiguration(schema: v3Schema, url: storeURL)
        let v3Container = try ModelContainer(for: v3Schema, migrationPlan: AppMigrationPlan.self, configurations: [v3Config])

        let presentationId = UUID()
        let sessionId = UUID()

        let pendingPresentation = SchemaV3.PracticePresentationRecord(
            id: presentationId,
            sessionId: sessionId,
            turnId: nil,
            statusRaw: "pending",
            channelRaw: "visual",
            proposedLevelRaw: "contextPrompt",
            possibleWordIdsRaw: "201,202,203",
            payloadJSON: Data([0x01, 0x02]),
            formatVersion: 1
        )
        v3Container.mainContext.insert(pendingPresentation)
        try v3Container.mainContext.save()

        // Reopen store from disk
        let reopened = try ModelContainer(for: v3Schema, migrationPlan: AppMigrationPlan.self, configurations: [v3Config])
        let fetched = try reopened.mainContext.fetch(FetchDescriptor<SchemaV3.PracticePresentationRecord>(
            predicate: #Predicate { $0.statusRaw == "pending" }
        ))

        XCTAssertEqual(fetched.count, 1)
        let item = try XCTUnwrap(fetched.first)
        XCTAssertEqual(item.id, presentationId)
        XCTAssertEqual(item.sessionId, sessionId)
        XCTAssertNil(item.turnId)
        XCTAssertEqual(item.statusRaw, "pending")
        XCTAssertEqual(item.channelRaw, "visual")
        XCTAssertEqual(item.proposedLevelRaw, "contextPrompt")
        XCTAssertEqual(item.possibleWordIdsRaw, "201,202,203")
    }

    // MARK: - Test 5: Payload With Unsupported FormatVersion Fails Explicitly Without Resetting Store

    @MainActor
    func test_payloadWithUnsupportedFormatVersionFailsWithTypedErrorWithoutResettingStore() throws {
        let v3Schema = Schema(versionedSchema: SchemaV3.self)
        let v3Config = ModelConfiguration(schema: v3Schema, url: storeURL)
        let v3Container = try ModelContainer(for: v3Schema, migrationPlan: AppMigrationPlan.self, configurations: [v3Config])

        // Insert a normal word progress
        let word = SchemaV3.UserWordProgress(
            wordId: 555,
            cefrLevel: "A2",
            masteryLevel: 2,
            isBookmarked: false,
            easeFactor: 2.5,
            intervalDays: 7,
            nextReviewDate: Date(timeIntervalSince1970: 1_700_000_000)
        )
        v3Container.mainContext.insert(word)

        // Insert a PracticeSessionRecord with unsupported formatVersion = 99
        let unsupportedSessionId = UUID()
        let unsupportedSession = SchemaV3.PracticeSessionRecord(
            id: unsupportedSessionId,
            revision: 1,
            statusRaw: "completed",
            initialInputModeRaw: "voice",
            policyVersion: 1,
            startedAt: Date(),
            completedAt: Date(),
            payloadJSON: Data([0xDE, 0xAD, 0xBE, 0xEF]),
            formatVersion: 99
        )
        v3Container.mainContext.insert(unsupportedSession)
        try v3Container.mainContext.save()

        // Reopen container via SharedAppGroupContainer store URL
        let reopenedContainer = try ModelContainer(for: v3Schema, migrationPlan: AppMigrationPlan.self, configurations: [v3Config])

        // Verify the store opened cleanly, is NOT corrupted, and NOT reset
        let words = try reopenedContainer.mainContext.fetch(FetchDescriptor<SchemaV3.UserWordProgress>(
            predicate: #Predicate { $0.wordId == 555 }
        ))
        XCTAssertEqual(words.count, 1, "Existing user word progress must not be lost or reset")

        // Fetch the record with unsupported version
        let sessions = try reopenedContainer.mainContext.fetch(FetchDescriptor<SchemaV3.PracticeSessionRecord>(
            predicate: #Predicate { $0.id == unsupportedSessionId }
        ))
        XCTAssertEqual(sessions.count, 1)
        let session = try XCTUnwrap(sessions.first)

        // Validating payload format version must fail explicitly with typed error
        XCTAssertThrowsError(try session.validatePayloadFormatVersion()) { error in
            guard let payloadError = error as? PracticePayloadError else {
                XCTFail("Expected PracticePayloadError, got \(error)")
                return
            }
            XCTAssertEqual(
                payloadError,
                PracticePayloadError.unsupportedFormatVersion(
                    recordType: "PracticeSessionRecord",
                    found: 99,
                    supported: 1
                )
            )
        }
    }
}
#endif
