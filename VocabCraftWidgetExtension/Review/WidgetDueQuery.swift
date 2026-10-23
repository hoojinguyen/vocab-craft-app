import Foundation
#if canImport(SwiftDataMacros) || canImport(SwiftData)
import SwiftData
#endif
#if !WIDGET_EXTENSION && canImport(VocabCraftApp)
import VocabCraftApp
#endif

public enum WidgetDueQuery {
    #if canImport(SwiftDataMacros) || canImport(SwiftData)
    /// Due means `nextReviewDate <= now`. `needsReview` never makes a word due.
    /// `nextDueDate` is the earliest `nextReviewDate > now` among the given ids.
    @MainActor
    public static func dueStatus(
        for wordIds: [Int64],
        in context: ModelContext,
        now: Date
    ) throws -> (due: Set<Int64>, nextDueDate: Date?) {
        guard !wordIds.isEmpty else { return ([], nil) }
        let wanted = Array(Set(wordIds))
        let rows = try context.fetch(
            FetchDescriptor<UserWordProgress>(predicate: #Predicate { wanted.contains($0.wordId) })
        )

        var due: Set<Int64> = []
        var nextDueDate: Date?
        for row in rows {
            if row.nextReviewDate <= now {
                due.insert(row.wordId)
            } else if nextDueDate.map({ row.nextReviewDate < $0 }) ?? true {
                nextDueDate = row.nextReviewDate
            }
        }
        return (due, nextDueDate)
    }
    #endif
}
