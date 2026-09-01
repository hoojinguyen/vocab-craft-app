import AppIntents
import Foundation
#if canImport(SwiftData)
import SwiftData
#endif
import WidgetKit
#if !WIDGET_EXTENSION && canImport(VocabCraftApp)
@testable import VocabCraftApp
#endif

public struct MarkLearnedIntent: AppIntent {
    public static var title: LocalizedStringResource = "app.widget.intent.mark_learned.title"
    public static var description = IntentDescription("app.widget.intent.mark_learned.description")

    public init() {}

    #if canImport(SwiftDataMacros)
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
        var fetchDescriptor = FetchDescriptor<UserWordProgress>(predicate: #Predicate { $0.wordId == wordId })
        fetchDescriptor.fetchLimit = 1
        let existingProgress = try context.fetch(fetchDescriptor).first

        if let progress = existingProgress {
            let srsResult = SRSEngine.calculateNextInterval(
                currentMastery: progress.masteryLevel,
                easeFactor: progress.easeFactor,
                isCorrect: true,
                responseTimeMs: 1500
            )
            progress.masteryLevel = min(5, max(1, srsResult.nextMastery))
            progress.easeFactor = srsResult.easeFactor
            progress.intervalDays = srsResult.intervalDays
            progress.lastReviewDate = Date()
            progress.nextReviewDate = Calendar.current.date(byAdding: .day, value: srsResult.intervalDays, to: Date()) ?? Date()
            progress.totalReviews += 1
        } else {
            let srsResult = SRSEngine.calculateNextInterval(
                currentMastery: 0,
                easeFactor: 2.5,
                isCorrect: true,
                responseTimeMs: 1500
            )
            let newProgress = UserWordProgress(
                wordId: wordId,
                masteryLevel: min(5, max(1, srsResult.nextMastery)),
                easeFactor: srsResult.easeFactor,
                intervalDays: srsResult.intervalDays,
                nextReviewDate: Calendar.current.date(byAdding: .day, value: srsResult.intervalDays, to: Date()) ?? Date(),
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
    #else
    @MainActor
    @discardableResult
    public func perform() async throws -> some IntentResult {
        return .result()
    }
    #endif
}
