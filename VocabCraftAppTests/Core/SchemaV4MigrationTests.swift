import Foundation
import SwiftData
import Testing
@testable import VocabCraftApp

struct SchemaV4MigrationTests {
    @MainActor @Test func v3StoreWithPracticeDataMigratesAndKeepsProgress() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.sqlite")
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let reflexID = UUID()
        let attemptID = UUID()
        // This helper returns only values; the old context and container are released before reopening.
        try seedV3(url: url, date: date, reflexID: reflexID, attemptID: attemptID)
        let schema = Schema(versionedSchema: SchemaV4.self)
        let container = try ModelContainer(
            for: schema, migrationPlan: AppMigrationPlan.self,
            configurations: [ModelConfiguration(schema: schema, url: url)]
        )
        let context = container.mainContext
        defer { withExtendedLifetime(container) {} }
        let words = try context.fetch(FetchDescriptor<UserWordProgress>())
        #expect(words.count == 1)
        let word = try #require(words.first)
        #expect(word.wordId == 101 && word.masteryLevel == 3)
        #expect(word.nextReviewDate == date && word.lastReviewDate == date)
        #expect(word.cefrLevel == "B1" && word.isBookmarked && word.needsReview)
        #expect(word.easeFactor == 2.4 && word.intervalDays == 14 && word.totalReviews == 8)
        #expect(word.mistakeCount == 2 && word.consecutiveCorrectStreak == 4 && word.isMastered)
        #expect(word.sourceDeckId == "travel" && word.sourceNodeId == "day5")
        #expect(word.practicedModesRaw == "quiz" && word.modeSuccessCountsRaw == "{\"quiz\":4}")
        let stage = try #require(context.fetch(FetchDescriptor<UserStageProgress>()).first)
        #expect(stage.stageId == "stage1" && stage.deckId == "travel")
        #expect(stage.isCompleted && stage.score == 90 && stage.progressFraction == 1 && stage.completedAt == date)
        let reflex = try #require(context.fetch(FetchDescriptor<ReflexSessionLog>()).first)
        #expect(reflex.id == reflexID && reflex.drillId == 301 && reflex.responseTimeMs == 750)
        #expect(reflex.accuracyScore == 0.9 && reflex.timestamp == date)
        let widget = try #require(context.fetch(FetchDescriptor<WidgetCurrentState>()).first)
        #expect(widget.id == "current" && widget.currentWordId == 101 && widget.lemma == "journey")
        #expect(widget.ipaUs == "ipa" && widget.definitionVi == "chuyến đi")
        #expect(widget.exampleEn == "Safe journey!" && widget.lastUpdated == date)
        let attempt = try #require(context.fetch(FetchDescriptor<QuickReflexAttemptRecord>()).first)
        #expect(attempt.id == attemptID && attempt.wordId == 101)
        #expect(attempt.recallWordTimeMs == 300 && attempt.collocationTimeMs == 250 && attempt.produceSentenceTimeMs == 600)
        #expect(attempt.recallWordSucceeded && attempt.collocationSucceeded && attempt.produceSentenceSucceeded)
        #expect(attempt.shadowPronunciationScore == 0.88 && attempt.maxHintLevel == 1)
        #expect(attempt.inputModeRawValue == "voice" && attempt.retryCount == 2 && attempt.confidenceRawValue == "high")
        #expect(attempt.timestamp == date)
        #expect(try context.fetch(FetchDescriptor<SpeakingSessionRecord>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<SavedPhraseRecord>()).isEmpty)
        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path).allSatisfy { !$0.contains("backup") })
    }

    @MainActor
    private func seedV3(url: URL, date: Date, reflexID: UUID, attemptID: UUID) throws {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
        let context = container.mainContext
        defer { withExtendedLifetime(container) {} }
        context.insert(SchemaV3.UserWordProgress(
            wordId: 101, cefrLevel: "B1", masteryLevel: 3, isBookmarked: true, easeFactor: 2.4,
            intervalDays: 14, nextReviewDate: date, lastReviewDate: date, totalReviews: 8, needsReview: true,
            mistakeCount: 2, sourceDeckId: "travel", sourceNodeId: "day5", consecutiveCorrectStreak: 4,
            practicedModesRaw: "quiz", isMastered: true, modeSuccessCountsRaw: "{\"quiz\":4}"
        ))
        context.insert(SchemaV3.UserStageProgress(
            stageId: "stage1", deckId: "travel", isCompleted: true, score: 90, progressFraction: 1, completedAt: date
        ))
        context.insert(SchemaV3.ReflexSessionLog(
            id: reflexID, drillId: 301, responseTimeMs: 750, accuracyScore: 0.9, timestamp: date
        ))
        context.insert(SchemaV3.WidgetCurrentState(
            id: "current", currentWordId: 101, lemma: "journey", ipaUs: "ipa",
            definitionVi: "chuyến đi", exampleEn: "Safe journey!", lastUpdated: date
        ))
        context.insert(SchemaV3.QuickReflexAttemptRecord(
            id: attemptID, wordId: 101, recallWordTimeMs: 300, collocationTimeMs: 250, produceSentenceTimeMs: 600,
            recallWordSucceeded: true, collocationSucceeded: true, produceSentenceSucceeded: true,
            shadowPronunciationScore: 0.88, maxHintLevel: 1, inputModeRawValue: "voice", retryCount: 2,
            confidenceRawValue: "high", timestamp: date
        ))
        context.insert(SchemaV3.PracticeSessionRecord(statusRaw: "completed", initialInputModeRaw: "voice"))
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<SchemaV3.PracticeSessionRecord>()) == 1)
    }
}
