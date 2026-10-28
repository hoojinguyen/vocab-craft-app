import Foundation
#if canImport(SwiftDataMacros) || canImport(SwiftData)
import SwiftData
import Testing
@testable import VocabCraftApp
#if SWIFT_PACKAGE
@testable import VocabCraftWidgetExtension
#endif

@MainActor
@Suite("WidgetDueQuery")
struct WidgetDueQueryTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private var startOfDay: Date { Calendar.current.startOfDay(for: now) }

    private func insertRow(_ id: Int64, lastReview: Date, totalReviews: Int = 1, in context: ModelContext) throws {
        context.insert(
            UserWordProgress(
                wordId: id,
                masteryLevel: 1,
                easeFactor: 2.5,
                intervalDays: 1,
                nextReviewDate: now.addingTimeInterval(86_400),
                lastReviewDate: lastReview,
                totalReviews: totalReviews
            )
        )
        try context.save()
    }

    @Test func countsRowsPracticedSinceStartOfDay() throws {
        let context = ModelContext(try SharedAppGroupContainer.createContainer(inMemory: true))
        try insertRow(1, lastReview: startOfDay, in: context)
        try insertRow(2, lastReview: now, in: context)
        try insertRow(3, lastReview: startOfDay.addingTimeInterval(-1), in: context)
        try insertRow(4, lastReview: now.addingTimeInterval(-86_400), in: context)

        #expect(try WidgetDueQuery.practicedCount(since: startOfDay, in: context) == 2)
    }

    @Test func emptyStoreCountsZero() throws {
        let context = ModelContext(try SharedAppGroupContainer.createContainer(inMemory: true))

        #expect(try WidgetDueQuery.practicedCount(since: startOfDay, in: context) == 0)
    }

    @Test func bookmarkOnlyRowsAreNotPracticed() throws {
        let context = ModelContext(try SharedAppGroupContainer.createContainer(inMemory: true))
        try insertRow(1, lastReview: now, totalReviews: 0, in: context)
        try insertRow(2, lastReview: now, totalReviews: 1, in: context)

        #expect(try WidgetDueQuery.practicedCount(since: startOfDay, in: context) == 1)
    }
}
#endif
