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
            wordId: attempt.wordId,
            retrieveTimeMs: attempt.retrieveTimeMs,
            useTimeMs: attempt.useTimeMs,
            retrieveSucceeded: attempt.retrieveSucceeded,
            useSucceeded: attempt.useSucceeded,
            maxHintLevel: attempt.maxHintLevel,
            inputModeRawValue: rawValue(for: attempt.inputMode),
            retryCount: attempt.retryCount,
            confidenceRawValue: attempt.confidence.rawValue,
            timestamp: attempt.timestamp
        ))
        try modelContext.save()
    }

    /// Returns the newest attempt whose retrieval stage succeeded for a word.
    public func mostRecentSuccessfulAttempt(for wordId: Int64) async throws -> QuickReflexAttempt? {
        guard let modelContext else { return nil }

        var descriptor = FetchDescriptor<QuickReflexAttemptRecord>(
            predicate: #Predicate { $0.wordId == wordId && $0.retrieveSucceeded }
        )
        descriptor.sortBy = [SortDescriptor(\.timestamp, order: .reverse)]
        descriptor.fetchLimit = 1

        return try modelContext.fetch(descriptor).first.map(makeAttempt(from:))
    }

    private func makeAttempt(from record: QuickReflexAttemptRecord) -> QuickReflexAttempt {
        QuickReflexAttempt(
            wordId: record.wordId,
            retrieveTimeMs: record.retrieveTimeMs,
            useTimeMs: record.useTimeMs,
            retrieveSucceeded: record.retrieveSucceeded,
            useSucceeded: record.useSucceeded,
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
