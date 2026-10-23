import AppIntents
import Foundation
#if canImport(SwiftData)
import SwiftData
#endif
import WidgetKit
#if !WIDGET_EXTENSION && canImport(VocabCraftApp)
import VocabCraftApp
#endif

public struct GradeCardIntent: AppIntent {
    public static let title: LocalizedStringResource = "app.widget.intent.grade.title"
    public static let description = IntentDescription("app.widget.intent.grade.description")

    @Parameter(title: "Word")
    public var wordId: Int

    @Parameter(title: "Remembered")
    public var remembered: Bool

    public init() {}

    public init(wordId: Int64, remembered: Bool) {
        self.wordId = Int(wordId)
        self.remembered = remembered
    }

    #if canImport(SwiftDataMacros) || canImport(SwiftData)
    /// Grades the revealed card. The interaction state is cleared only when the grade was applied;
    /// a rejected grade leaves it untouched, and a thrown error propagates without touching it.
    @MainActor
    public func perform(store: WidgetDeckStore, context: ModelContext, now: Date) throws {
        let applied = try WidgetReviewRecorder.grade(
            wordId: Int64(wordId),
            remembered: remembered,
            interaction: store.loadInteraction(),
            now: now,
            in: context
        )
        if applied {
            try store.saveInteraction(.empty)
        }
    }

    @MainActor
    public func perform() async throws -> some IntentResult {
        if let container = WidgetContainerHolder.sharedContainer {
            try perform(store: .appGroup(), context: ModelContext(container), now: Date())
        }
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.vocab)
        return .result()
    }
    #else
    @MainActor
    public func perform() async throws -> some IntentResult {
        .result()
    }
    #endif
}
