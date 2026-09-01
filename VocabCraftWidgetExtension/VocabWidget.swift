#if canImport(SwiftData)
import SwiftData
#endif
import SwiftUI
import WidgetKit
#if !WIDGET_EXTENSION && canImport(VocabCraftApp)
@testable import VocabCraftApp
#endif

#if canImport(SwiftDataMacros)
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

public struct VocabWidgetProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> VocabWidgetEntry {
        makePlaceholder()
    }

    public func makePlaceholder() -> VocabWidgetEntry {
        VocabWidgetEntry(
            date: Date(),
            lemma: "Abandon",
            ipaUs: "/əˈbæn.dən/",
            definitionVi: "Từ bỏ, ruồng bỏ",
            exampleEn: "He decided to abandon the plan.",
            masteryLevel: 0
        )
    }

    public func getSnapshot(in context: Context, completion: @escaping (VocabWidgetEntry) -> Void) {
        #if canImport(SwiftDataMacros)
        if let entry = fetchCurrentEntry() {
            completion(entry)
        } else {
            completion(makePlaceholder())
        }
        #else
        completion(makePlaceholder())
        #endif
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<VocabWidgetEntry>) -> Void) {
        #if canImport(SwiftDataMacros)
        let entry = fetchCurrentEntry() ?? makePlaceholder()
        #else
        let entry = makePlaceholder()
        #endif
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    #if canImport(SwiftDataMacros)
    public func fetchCurrentEntry(in container: ModelContainer? = nil) -> VocabWidgetEntry? {
        guard let targetContainer = container ?? WidgetContainerHolder.sharedContainer else {
            return nil
        }
        let context = ModelContext(targetContainer)
        guard let state = try? context.fetch(FetchDescriptor<WidgetCurrentState>()).first else {
            return nil
        }

        let wordId = state.currentWordId
        var fetchDescriptor = FetchDescriptor<UserWordProgress>(predicate: #Predicate { $0.wordId == wordId })
        fetchDescriptor.fetchLimit = 1
        fetchDescriptor.propertiesToFetch = [\.masteryLevel]

        let mastery = (try? context.fetch(fetchDescriptor))?.first?.masteryLevel ?? 0

        return VocabWidgetEntry(
            date: state.lastUpdated,
            lemma: state.lemma,
            ipaUs: state.ipaUs,
            definitionVi: state.definitionVi,
            exampleEn: state.exampleEn,
            masteryLevel: mastery
        )
    }
    #endif
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
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryInline])
        #else
        .supportedFamilies([.systemSmall, .systemMedium])
        #endif
    }
}
