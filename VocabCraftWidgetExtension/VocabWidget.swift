import WidgetKit
import SwiftUI
import SwiftData

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
        if let entry = fetchCurrentEntry() {
            completion(entry)
        } else {
            completion(makePlaceholder())
        }
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<VocabWidgetEntry>) -> Void) {
        let entry = fetchCurrentEntry() ?? makePlaceholder()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    public func fetchCurrentEntry(in container: ModelContainer? = nil) -> VocabWidgetEntry? {
        guard let targetContainer = container ?? (try? SharedAppGroupContainer.createContainer()) else {
            return nil
        }
        let context = ModelContext(targetContainer)
        guard let state = try? context.fetch(FetchDescriptor<WidgetCurrentState>()).first else {
            return nil
        }

        let wordId = state.currentWordId
        let allProgress = (try? context.fetch(FetchDescriptor<UserWordProgress>())) ?? []
        let mastery = allProgress.first(where: { $0.wordId == wordId })?.masteryLevel ?? 0

        return VocabWidgetEntry(
            date: state.lastUpdated,
            lemma: state.lemma,
            ipaUs: state.ipaUs,
            definitionVi: state.definitionVi,
            exampleEn: state.exampleEn,
            masteryLevel: mastery
        )
    }
}

#if !canImport(XCTest)
@main
#endif
public struct VocabWidget: Widget {
    public let kind: String = "VocabWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VocabWidgetProvider()) { entry in
            VocabWidgetView(entry: entry)
        }
        .configurationDisplayName("VocabCraft Reflex Widget")
        .description("Học từ vựng và mẫu câu phản xạ liên tục trên Màn hình chính.")
        #if os(iOS)
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryInline])
        #else
        .supportedFamilies([.systemSmall, .systemMedium])
        #endif
    }
}
