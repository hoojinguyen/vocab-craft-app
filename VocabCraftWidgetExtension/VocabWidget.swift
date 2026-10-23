#if canImport(SwiftData)
import SwiftData
#endif
import SwiftUI
import WidgetKit
#if !WIDGET_EXTENSION && canImport(VocabCraftApp)
import VocabCraftApp
#endif

#if canImport(SwiftDataMacros) || canImport(SwiftData)
public enum WidgetContainerHolder {
    public static let sharedContainer: ModelContainer? = {
        let isTesting = NSClassFromString("XCTestCase") != nil
        if isTesting {
            return try? SharedAppGroupContainer.createContainer(inMemory: true)
        }
        return try? SharedAppGroupContainer.createContainer()
    }()
}
#endif

public struct VocabWidgetProvider: TimelineProvider, Sendable {
    private let store: WidgetDeckStore
    #if canImport(SwiftDataMacros) || canImport(SwiftData)
    private let container: ModelContainer?

    public init() {
        self.init(store: .appGroup(), container: WidgetContainerHolder.sharedContainer)
    }

    /// Injectable for tests. A `nil` container means nothing is due.
    init(store: WidgetDeckStore, container: ModelContainer?) {
        self.store = store
        self.container = container
    }
    #else
    public init() {
        self.store = .appGroup()
    }
    #endif

    public func placeholder(in context: Context) -> VocabWidgetEntry {
        VocabWidgetEntry.placeholder(at: Date())
    }

    public func getSnapshot(in context: Context, completion: @escaping (VocabWidgetEntry) -> Void) {
        // WidgetKit does not annotate the handler @Sendable; it is invoked exactly once, so the capture is safe.
        nonisolated(unsafe) let done = completion
        Task { @MainActor in
            let now = Date()
            let first = makeTimeline(now: now).entries.first
            done(first ?? VocabWidgetEntry.placeholder(at: now))
        }
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<VocabWidgetEntry>) -> Void) {
        // WidgetKit does not annotate the handler @Sendable; it is invoked exactly once, so the capture is safe.
        nonisolated(unsafe) let done = completion
        Task { @MainActor in
            done(makeTimeline(now: Date()))
        }
    }

    @MainActor
    func makeTimeline(now: Date) -> Timeline<VocabWidgetEntry> {
        let deck = store.loadDeck()
        var interaction = store.loadInteraction()

        var dueWordIds: Set<Int64> = []
        var nextDueDate: Date?
        #if canImport(SwiftDataMacros) || canImport(SwiftData)
        if let deck, let container {
            let context = ModelContext(container)
            if let status = try? WidgetDueQuery.dueStatus(
                for: deck.cards.map(\.wordId),
                in: context,
                now: now
            ) {
                dueWordIds = status.due
                nextDueDate = status.nextDueDate
            }
        }
        #endif

        if let revealedId = interaction.revealedWordId, !dueWordIds.contains(revealedId) {
            // Stale reveal state: the word is no longer due, so it must not reopen on the answer side later.
            interaction = .empty
            try? store.saveInteraction(.empty)
        }

        let plan = WidgetTimelineBuilder.build(
            deck: deck,
            dueWordIds: dueWordIds,
            nextDueDate: nextDueDate,
            interaction: interaction,
            now: now
        )
        return Timeline(entries: plan.entries, policy: Self.reloadPolicy(for: plan.reload))
    }

    static func reloadPolicy(for plan: WidgetReloadPlan) -> TimelineReloadPolicy {
        switch plan {
        case .atEnd: return .atEnd
        case .after(let date): return .after(date)
        }
    }
}

public struct VocabWidget: Widget {
    public let kind: String = "VocabWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VocabWidgetProvider()) { entry in
            VocabWidgetView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringKey("app.widget.display_name"))
        .description(LocalizedStringKey("app.widget.description"))
        #if os(iOS)
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
        #else
        .supportedFamilies([.systemSmall, .systemMedium])
        #endif
    }
}
