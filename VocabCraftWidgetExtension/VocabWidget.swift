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
        VocabWidgetEntry.placeholder(at: Date(), themePreset: store.loadThemePreset())
    }

    public func getSnapshot(in context: Context, completion: @escaping (VocabWidgetEntry) -> Void) {
        // WidgetKit does not annotate the handler @Sendable; it is invoked exactly once, so the capture is safe.
        nonisolated(unsafe) let done = completion
        let surface = WidgetSurface(family: context.family)
        Task { @MainActor in
            let now = Date()
            let first = makeTimeline(now: now, surface: surface).entries.first
            done(first ?? VocabWidgetEntry.placeholder(at: now, themePreset: store.loadThemePreset()))
        }
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<VocabWidgetEntry>) -> Void) {
        // WidgetKit does not annotate the handler @Sendable; it is invoked exactly once, so the capture is safe.
        nonisolated(unsafe) let done = completion
        let surface = WidgetSurface(family: context.family)
        Task { @MainActor in
            done(makeTimeline(now: Date(), surface: surface))
        }
    }

    @MainActor
    func makeTimeline(now: Date, surface: WidgetSurface = .homeScreen) -> Timeline<VocabWidgetEntry> {
        let deck = store.loadDeck()
        var interaction = store.loadInteraction()
        let themePreset = store.loadThemePreset()

        var dueWordIds: Set<Int64> = []
        var nextDueDate: Date?
        var dueQuerySucceeded = false
        var practicedToday = 0
        #if canImport(SwiftDataMacros) || canImport(SwiftData)
        if let container {
            practicedToday = (try? WidgetDueQuery.practicedCount(
                since: Calendar.current.startOfDay(for: now),
                in: ModelContext(container)
            )) ?? 0
        }
        if let deck, let container {
            let context = ModelContext(container)
            if let status = try? WidgetDueQuery.dueStatus(
                for: deck.cards.map(\.wordId),
                in: context,
                now: now
            ) {
                dueWordIds = status.due
                nextDueDate = status.nextDueDate
                dueQuerySucceeded = true
            }
        }
        #endif

        if dueQuerySucceeded, let revealedId = interaction.revealedWordId, !dueWordIds.contains(revealedId) {
            // Stale reveal state: the word is no longer due, so it must not reopen on the answer side later.
            interaction = .empty
            try? store.saveInteraction(.empty)
        }

        let plan = WidgetTimelineBuilder.build(
            deck: deck,
            dueWordIds: dueWordIds,
            nextDueDate: nextDueDate,
            interaction: interaction,
            practicedToday: practicedToday,
            themePreset: themePreset,
            surface: surface,
            now: now
        )
        // With a deck but unreadable due status, keep the state untouched and retry soon.
        // Without a deck the app reloads timelines once it writes one, so the builder's policy stands.
        // The lock screen ignores due status, so it never needs the retry.
        let deckPresent = deck?.cards.isEmpty == false
        let policy: TimelineReloadPolicy = (surface == .homeScreen && deckPresent && !dueQuerySucceeded)
            ? .after(now.addingTimeInterval(Self.retryInterval))
            : Self.reloadPolicy(for: plan.reload)
        return Timeline(entries: plan.entries, policy: policy)
    }

    /// Retry delay when the due query could not run (seconds).
    static let retryInterval: TimeInterval = 300

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
