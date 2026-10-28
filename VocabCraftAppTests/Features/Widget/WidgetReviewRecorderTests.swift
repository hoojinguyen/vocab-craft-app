import Foundation
#if canImport(SwiftDataMacros) || canImport(SwiftData)
import SwiftData
import Testing
@testable import VocabCraftApp
#if SWIFT_PACKAGE
@testable import VocabCraftWidgetExtension
#endif

@MainActor
@Suite("WidgetReviewRecorder")
struct WidgetReviewRecorderTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeContainer() throws -> ModelContainer {
        try SharedAppGroupContainer.createContainer(inMemory: true)
    }

    @discardableResult
    private func insertRow(
        _ id: Int64,
        mastery: Int = 1,
        nextReview: Date,
        in context: ModelContext
    ) throws -> UserWordProgress {
        let row = UserWordProgress(
            wordId: id,
            masteryLevel: mastery,
            easeFactor: 2.5,
            intervalDays: 1,
            nextReviewDate: nextReview,
            lastReviewDate: now.addingTimeInterval(-86_400),
            totalReviews: 4
        )
        context.insert(row)
        try context.save()
        return row
    }

    private func revealed(_ id: Int64, secondsAgo: TimeInterval) -> WidgetInteractionState {
        WidgetInteractionState(revealedWordId: id, revealedAt: now.addingTimeInterval(-secondsAgo))
    }

    @Test("dueStatusSplitsDueAndNext")
    func dueStatusSplitsDueAndNext() throws {
        let container = try makeContainer()
        defer { withExtendedLifetime(container) {} }
        let context = container.mainContext
        try insertRow(1, nextReview: now.addingTimeInterval(-60), in: context)
        try insertRow(2, nextReview: now.addingTimeInterval(3_600), in: context)

        let status = try WidgetDueQuery.dueStatus(for: [1, 2, 3], in: context, now: now)

        #expect(status.due == [1])
        #expect(status.nextDueDate == now.addingTimeInterval(3_600))
    }

    @Test("rememberedAdvancesSchedule")
    func rememberedAdvancesSchedule() throws {
        let container = try makeContainer()
        defer { withExtendedLifetime(container) {} }
        let context = container.mainContext
        let row = try insertRow(1, mastery: 1, nextReview: now.addingTimeInterval(-60), in: context)

        let applied = try WidgetReviewRecorder.grade(
            wordId: 1, remembered: true, interaction: revealed(1, secondsAgo: 3), now: now, in: context
        )

        #expect(applied)
        #expect(row.masteryLevel == 2)
        #expect(row.nextReviewDate > now)
        #expect(row.needsReview == false)
        #expect(row.totalReviews == 5)
        #expect(row.consecutiveCorrectStreak == 1)
        #expect(row.lastReviewDate == now)
    }

    @Test("forgotResetsAndFlags")
    func forgotResetsAndFlags() throws {
        let container = try makeContainer()
        defer { withExtendedLifetime(container) {} }
        let context = container.mainContext
        let row = try insertRow(1, mastery: 3, nextReview: now.addingTimeInterval(-60), in: context)
        row.consecutiveCorrectStreak = 2
        let mistakesBefore = row.mistakeCount

        let applied = try WidgetReviewRecorder.grade(
            wordId: 1, remembered: false, interaction: revealed(1, secondsAgo: 3), now: now, in: context
        )

        #expect(applied)
        #expect(row.masteryLevel == 0)
        #expect(row.needsReview == true)
        #expect(row.mistakeCount == mistakesBefore + 1)
        #expect(row.consecutiveCorrectStreak == 0)
        #expect(row.nextReviewDate == Calendar.current.date(byAdding: .day, value: 1, to: now))
        #expect(row.nextReviewDate > now)
    }

    @Test("responseTimeIsClamped")
    func responseTimeIsClamped() throws {
        let fast = SRSEngine.calculateNextInterval(
            currentMastery: 1, easeFactor: 2.5, isCorrect: true,
            responseTimeMs: WidgetReviewRecorder.responseTimeRange.lowerBound
        )
        let slow = SRSEngine.calculateNextInterval(
            currentMastery: 1, easeFactor: 2.5, isCorrect: true,
            responseTimeMs: WidgetReviewRecorder.responseTimeRange.upperBound
        )
        #expect(fast.easeFactor != slow.easeFactor)

        let container = try makeContainer()
        defer { withExtendedLifetime(container) {} }
        let context = container.mainContext
        let fastRow = try insertRow(1, nextReview: now, in: context)
        let slowRow = try insertRow(2, nextReview: now, in: context)

        try WidgetReviewRecorder.grade(
            wordId: 1, remembered: true, interaction: revealed(1, secondsAgo: 0), now: now, in: context
        )
        try WidgetReviewRecorder.grade(
            wordId: 2, remembered: true, interaction: revealed(2, secondsAgo: 60), now: now, in: context
        )

        #expect(fastRow.easeFactor == fast.easeFactor)
        #expect(slowRow.easeFactor == slow.easeFactor)
    }

    @Test("gradeWithoutRevealIsRejected")
    func gradeWithoutRevealIsRejected() throws {
        let container = try makeContainer()
        defer { withExtendedLifetime(container) {} }
        let context = container.mainContext
        let row = try insertRow(1, nextReview: now.addingTimeInterval(-60), in: context)

        let applied = try WidgetReviewRecorder.grade(
            wordId: 1, remembered: true, interaction: .empty, now: now, in: context
        )

        #expect(applied == false)
        #expect(row.masteryLevel == 1)
        #expect(row.totalReviews == 4)
        #expect(row.nextReviewDate == now.addingTimeInterval(-60))
    }

    @Test("gradeRejectedWhenNotDue")
    func gradeRejectedWhenNotDue() throws {
        let container = try makeContainer()
        defer { withExtendedLifetime(container) {} }
        let context = container.mainContext
        let future = now.addingTimeInterval(86_400)
        let row = try insertRow(1, nextReview: future, in: context)

        let applied = try WidgetReviewRecorder.grade(
            wordId: 1, remembered: true, interaction: revealed(1, secondsAgo: 3), now: now, in: context
        )

        #expect(applied == false)
        #expect(row.masteryLevel == 1)
        #expect(row.totalReviews == 4)
        #expect(row.nextReviewDate == future)
        #expect(row.lastReviewDate == now.addingTimeInterval(-86_400))
    }

    @Test("missingProgressInsertsNothing")
    func missingProgressInsertsNothing() throws {
        let container = try makeContainer()
        defer { withExtendedLifetime(container) {} }
        let context = container.mainContext
        try insertRow(1, nextReview: now, in: context)

        let applied = try WidgetReviewRecorder.grade(
            wordId: 99, remembered: true, interaction: revealed(99, secondsAgo: 3), now: now, in: context
        )

        #expect(applied == false)
        #expect(try context.fetch(FetchDescriptor<UserWordProgress>()).count == 1)
    }

    @Test("gradeAppliesAfterDeckRebuilt")
    func gradeAppliesAfterDeckRebuilt() throws {
        // The interaction state is independent of the deck: grading must work
        // even when no deck exists (e.g. the app rebuilt/cleared it meanwhile).
        let container = try makeContainer()
        defer { withExtendedLifetime(container) {} }
        let context = container.mainContext
        let row = try insertRow(1, mastery: 1, nextReview: now.addingTimeInterval(-60), in: context)

        let applied = try WidgetReviewRecorder.grade(
            wordId: 1, remembered: true, interaction: revealed(1, secondsAgo: 5), now: now, in: context
        )

        #expect(applied)
        #expect(row.masteryLevel == 2)
        #expect(row.totalReviews == 5)
    }
}
#endif
