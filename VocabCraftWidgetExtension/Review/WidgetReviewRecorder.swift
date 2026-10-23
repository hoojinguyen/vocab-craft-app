import Foundation
#if canImport(SwiftDataMacros) || canImport(SwiftData)
import SwiftData
#endif
#if !WIDGET_EXTENSION && canImport(VocabCraftApp)
import VocabCraftApp
#endif

public enum WidgetReviewRecorder {
    public static let responseTimeRange = 1_000...10_000

    #if canImport(SwiftDataMacros) || canImport(SwiftData)
    /// Applies a widget flashcard grade to an existing progress row.
    /// Returns `false` (writing nothing) when the word was not revealed, has no row, or is no longer due.
    @MainActor
    @discardableResult
    public static func grade(
        wordId: Int64,
        remembered: Bool,
        interaction: WidgetInteractionState,
        now: Date,
        in context: ModelContext
    ) throws -> Bool {
        guard interaction.revealedWordId == wordId, let revealedAt = interaction.revealedAt else {
            return false
        }

        var descriptor = FetchDescriptor<UserWordProgress>(predicate: #Predicate { $0.wordId == wordId })
        descriptor.fetchLimit = 1
        guard let progress = try context.fetch(descriptor).first else { return false }
        guard progress.nextReviewDate <= now else { return false }

        let elapsedMs = Int((now.timeIntervalSince(revealedAt) * 1000).rounded())
        let responseTimeMs = min(responseTimeRange.upperBound, max(responseTimeRange.lowerBound, elapsedMs))

        let result = SRSEngine.calculateNextInterval(
            currentMastery: progress.masteryLevel,
            easeFactor: progress.easeFactor,
            isCorrect: remembered,
            responseTimeMs: responseTimeMs
        )
        progress.masteryLevel = min(5, max(0, result.nextMastery))
        progress.easeFactor = result.easeFactor
        progress.intervalDays = result.intervalDays
        progress.nextReviewDate = Calendar.current.date(byAdding: .day, value: result.intervalDays, to: now)
            ?? now.addingTimeInterval(TimeInterval(result.intervalDays) * 86_400)
        progress.lastReviewDate = now
        progress.totalReviews += 1

        if remembered {
            progress.needsReview = false
            progress.consecutiveCorrectStreak += 1
        } else {
            progress.needsReview = true
            progress.mistakeCount += 1
            progress.consecutiveCorrectStreak = 0
        }

        try context.save()
        return true
    }
    #endif
}
