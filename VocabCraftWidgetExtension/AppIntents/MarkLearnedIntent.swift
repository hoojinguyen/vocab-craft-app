import Foundation
import AppIntents
import WidgetKit
import SwiftData


public struct MarkLearnedIntent: AppIntent {
    public static var title: LocalizedStringResource = "Đã thuộc"
    public static var description = IntentDescription("Đánh dấu từ hiện tại đã thuộc")

    public init() {}

    @MainActor
    @discardableResult
    public func perform() async throws -> some IntentResult {
        let container = try SharedAppGroupContainer.createContainer()
        let context = container.mainContext
        return try await perform(in: context)
    }

    @MainActor
    @discardableResult
    public func perform(in context: ModelContext, dbEngine: DatasetEngine? = nil) async throws -> some IntentResult {
        let states = try context.fetch(FetchDescriptor<WidgetCurrentState>())
        guard let currentState = states.first else {
            // If no current state, trigger NextWordIntent to establish initial state
            try await NextWordIntent().perform(in: context, dbEngine: dbEngine)
            return .result()
        }

        let wordId = currentState.currentWordId
        let allProgress = try context.fetch(FetchDescriptor<UserWordProgress>())
        let existingProgress = allProgress.first(where: { $0.wordId == wordId })

        if let progress = existingProgress {
            let srsResult = SRSEngine.calculateNextInterval(
                currentMastery: progress.masteryLevel,
                easeFactor: progress.easeFactor,
                isCorrect: true,
                responseTimeMs: 1500
            )
            progress.masteryLevel = max(5, srsResult.nextMastery)
            progress.easeFactor = srsResult.easeFactor
            progress.intervalDays = srsResult.intervalDays
            progress.lastReviewDate = Date()
            progress.nextReviewDate = Calendar.current.date(byAdding: .day, value: srsResult.intervalDays, to: Date()) ?? Date()
            progress.totalReviews += 1
        } else {
            let newProgress = UserWordProgress(
                wordId: wordId,
                masteryLevel: 5,
                easeFactor: 2.5,
                intervalDays: 6,
                nextReviewDate: Calendar.current.date(byAdding: .day, value: 6, to: Date()) ?? Date(),
                lastReviewDate: Date(),
                totalReviews: 1
            )
            context.insert(newProgress)
        }

        try context.save()

        // Rotate to next word state
        try await NextWordIntent().perform(in: context, dbEngine: dbEngine)

        WidgetCenter.shared.reloadTimelines(ofKind: "VocabWidget")
        return .result()
    }
}
