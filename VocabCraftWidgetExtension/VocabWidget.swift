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

public struct VocabWidgetProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> VocabWidgetEntry {
        makePlaceholder()
    }

    public func makePlaceholder() -> VocabWidgetEntry {
        VocabWidgetEntry.placeholder(at: Date())
    }

    public func getSnapshot(in context: Context, completion: @escaping (VocabWidgetEntry) -> Void) {
        #if canImport(SwiftDataMacros) || canImport(SwiftData)
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
        #if canImport(SwiftDataMacros) || canImport(SwiftData)
        let entry = fetchCurrentEntry() ?? makePlaceholder()
        #else
        let entry = makePlaceholder()
        #endif
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    #if canImport(SwiftDataMacros) || canImport(SwiftData)
    public func fetchCurrentEntry(in container: ModelContainer? = nil) -> VocabWidgetEntry? {
        guard let targetContainer = container ?? WidgetContainerHolder.sharedContainer else {
            return nil
        }
        let context = ModelContext(targetContainer)
        guard let state = try? context.fetch(FetchDescriptor<WidgetCurrentState>()).first else {
            return nil
        }

        return VocabWidgetEntry(
            date: state.lastUpdated,
            card: WidgetCard(
                wordId: state.currentWordId,
                lemma: state.lemma,
                ipa: state.ipaUs,
                definitionVi: state.definitionVi,
                exampleEn: state.exampleEn,
                source: .recent
            ),
            mode: .passive,
            dueCount: 0
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
