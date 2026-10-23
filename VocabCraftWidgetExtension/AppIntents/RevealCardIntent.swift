import AppIntents
import Foundation
import WidgetKit
#if !WIDGET_EXTENSION && canImport(VocabCraftApp)
import VocabCraftApp
#endif

public struct RevealCardIntent: AppIntent {
    public static let title: LocalizedStringResource = "app.widget.intent.reveal.title"
    public static let description = IntentDescription("app.widget.intent.reveal.description")

    @Parameter(title: "Word")
    public var wordId: Int

    public init() {}

    public init(wordId: Int64) {
        self.wordId = Int(wordId)
    }

    /// Records which card the user flipped, and when, so grading can derive response time.
    @MainActor
    public func perform(store: WidgetDeckStore, now: Date) throws {
        try store.saveInteraction(
            WidgetInteractionState(revealedWordId: Int64(wordId), revealedAt: now)
        )
    }

    @MainActor
    public func perform() async throws -> some IntentResult {
        try perform(store: .appGroup(), now: Date())
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.vocab)
        return .result()
    }
}
