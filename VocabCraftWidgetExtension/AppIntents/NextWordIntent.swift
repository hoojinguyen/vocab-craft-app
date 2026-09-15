import AppIntents
import Foundation
#if canImport(SwiftData)
import SwiftData
#endif
import WidgetKit
#if !WIDGET_EXTENSION && canImport(VocabCraftApp)
import VocabCraftApp
#endif

public struct NextWordIntent: AppIntent {
    public static let title: LocalizedStringResource = "app.widget.intent.next_word.title"
    public static let description = IntentDescription("app.widget.intent.next_word.description")

    public init() {}

    #if canImport(SwiftDataMacros) || canImport(SwiftData)
    @MainActor
    @discardableResult
    public func perform() async throws -> some IntentResult {
        let container = try SharedAppGroupContainer.createContainer()
        let context = container.mainContext
        return try await perform(in: context)
    }

    @MainActor
    @discardableResult
    public func perform(in context: ModelContext) async throws -> some IntentResult {
        let states = try context.fetch(FetchDescriptor<WidgetCurrentState>())
        let existingState = states.first

        // Word rotation across featured vocabulary
        // swiftlint:disable:next large_tuple
        let words: [(Int64, String, String, String, String)] = [
            (101, "Abandon", "/əˈbæn.dən/", "Từ bỏ, ruồng bỏ", "He decided to abandon the plan."),
            (102, "Brilliant", "/ˈbrɪl.jənt/", "Rực rỡ, xuất sắc", "She gave a brilliant performance."),
            (103, "Resilient", "/rɪˈzɪl.jənt/", "Kiên cường, phục hồi nhanh", "The team was remarkably resilient."),
            (104, "Eloquent", "/ˈel.ə.kwənt/", "Hùng hồn, trôi chảy", "An eloquent speech inspired everyone."),
            (105, "Persistent", "/pəˈsɪs.tənt/", "Bền bỉ, nhẫn nại", "Success comes with persistent effort.")
        ]
        let currentId = existingState?.currentWordId ?? 0
        let nextIndex = ((words.firstIndex(where: { $0.0 == currentId }) ?? -1) + 1) % words.count
        let selected = words[nextIndex]
        let newWordId = selected.0
        let lemma = selected.1
        let ipaUs = selected.2
        let definitionVi = selected.3
        let exampleEn = selected.4

        if let state = existingState {
            state.currentWordId = newWordId
            state.lemma = lemma
            state.ipaUs = ipaUs
            state.definitionVi = definitionVi
            state.exampleEn = exampleEn
            state.lastUpdated = Date()
        } else {
            let newState = WidgetCurrentState(
                currentWordId: newWordId,
                lemma: lemma,
                ipaUs: ipaUs,
                definitionVi: definitionVi,
                exampleEn: exampleEn,
                lastUpdated: Date()
            )
            context.insert(newState)
        }

        try context.save()
        WidgetCenter.shared.reloadTimelines(ofKind: "VocabWidget")
        return .result()
    }
    #else
    @MainActor
    @discardableResult
    public func perform() async throws -> some IntentResult {
        return .result()
    }
    #endif
}
