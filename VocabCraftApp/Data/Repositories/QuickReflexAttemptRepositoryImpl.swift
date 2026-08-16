import Foundation
import SwiftData

/// A SwiftData-backed store for quick-reflex learning attempts.
@MainActor
public final class QuickReflexAttemptRepositoryImpl: QuickReflexAttemptRepositoryProtocol {
    private let modelContext: ModelContext?

    /// Creates an attempt repository backed by the supplied model context.
    public init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }

    /// Saves a completed quick-reflex attempt.
    public func save(_ attempt: QuickReflexAttempt) async throws {
        guard let modelContext else { return }

        modelContext.insert(QuickReflexAttemptRecord(
            id: attempt.id,
            wordId: attempt.wordId,
            recallWordTimeMs: attempt.recallWordTimeMs,
            collocationTimeMs: attempt.collocationTimeMs,
            produceSentenceTimeMs: attempt.produceSentenceTimeMs,
            recallWordSucceeded: attempt.recallWordSucceeded,
            collocationSucceeded: attempt.collocationSucceeded,
            produceSentenceSucceeded: attempt.produceSentenceSucceeded,
            shadowPronunciationScore: attempt.shadowPronunciationScore,
            maxHintLevel: attempt.maxHintLevel,
            inputModeRawValue: rawValue(for: attempt.inputMode),
            retryCount: attempt.retryCount,
            confidenceRawValue: attempt.confidence.rawValue,
            timestamp: attempt.timestamp
        ))
        try modelContext.save()
    }

    /// Returns the newest attempt whose word recall stage succeeded for a word.
    public func mostRecentSuccessfulAttempt(for wordId: Int64) async throws -> QuickReflexAttempt? {
        guard let modelContext else { return nil }

        var descriptor = FetchDescriptor<QuickReflexAttemptRecord>(
            predicate: #Predicate { $0.wordId == wordId && $0.recallWordSucceeded }
        )
        descriptor.sortBy = [SortDescriptor(\.timestamp, order: .reverse)]
        descriptor.fetchLimit = 1

        return try modelContext.fetch(descriptor).first.map(makeAttempt(from:))
    }

    private func makeAttempt(from record: QuickReflexAttemptRecord) -> QuickReflexAttempt {
        QuickReflexAttempt(
            id: record.id,
            wordId: record.wordId,
            recallWordTimeMs: record.recallWordTimeMs,
            collocationTimeMs: record.collocationTimeMs,
            produceSentenceTimeMs: record.produceSentenceTimeMs,
            recallWordSucceeded: record.recallWordSucceeded,
            collocationSucceeded: record.collocationSucceeded,
            produceSentenceSucceeded: record.produceSentenceSucceeded,
            shadowPronunciationScore: record.shadowPronunciationScore,
            maxHintLevel: record.maxHintLevel,
            inputMode: inputMode(from: record.inputModeRawValue),
            retryCount: record.retryCount,
            confidence: QuickReflexConfidence(rawValue: record.confidenceRawValue) ?? .uncertain,
            timestamp: record.timestamp
        )
    }

    private func rawValue(for inputMode: QuickReflexInputMode) -> String {
        switch inputMode {
        case .voice:
            "voice"
        case .typing:
            "typing"
        }
    }

    private func inputMode(from rawValue: String) -> QuickReflexInputMode {
        rawValue == "typing" ? .typing : .voice
    }
}
