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
    public static var title: LocalizedStringResource = "app.widget.intent.next_word.title"
    public static var description = IntentDescription("app.widget.intent.next_word.description")

    public init() {}

    #if canImport(SwiftDataMacros)
    @MainActor
    @discardableResult
    public func perform() async throws -> some IntentResult {
        let container = try SharedAppGroupContainer.createContainer()
        let context = container.mainContext
        return try await perform(in: context)
    }

    @MainActor
    @discardableResult
    public func perform(in context: ModelContext, dbEngine: DatasetEngine? = nil) async throws -> some IntentResult {
        let engine = dbEngine ?? DatasetEngine()
        let randomWord = engine?.getRandomWordForWidget()

        let states = try context.fetch(FetchDescriptor<WidgetCurrentState>())
        let existingState = states.first

        let newWordId: Int64
        let lemma: String
        let ipaUs: String
        let definitionVi: String
        let exampleEn: String

        if let word = randomWord {
            newWordId = word.id
            lemma = word.lemma
            ipaUs = word.ipaUs ?? ""
            definitionVi = word.definitionVi ?? (word.definitionEn ?? "")
            exampleEn = word.example ?? ""
        } else {
            // Fallback word rotation if sqlite database is unavailable
            // swiftlint:disable:next large_tuple
            let fallbackWords: [(Int64, String, String, String, String)] = [
                (101, "Abandon", "/əˈbæn.dən/", "Từ bỏ, ruồng bỏ", "He decided to abandon the plan."),
                (102, "Brilliant", "/ˈbrɪl.jənt/", "Rực rỡ, xuất sắc", "She gave a brilliant performance."),
                (103, "Resilient", "/rɪˈzɪl.jənt/", "Kiên cường, phục hồi nhanh", "The team was remarkably resilient."),
                (104, "Eloquent", "/ˈel.ə.kwənt/", "Hùng hồn, trôi chảy", "An eloquent speech inspired everyone."),
                (105, "Persistent", "/pəˈsɪs.tənt/", "Bền bỉ, nhẫn nại", "Success comes with persistent effort.")
            ]
            let currentId = existingState?.currentWordId ?? 0
            let nextIndex = ((fallbackWords.firstIndex(where: { $0.0 == currentId }) ?? -1) + 1) % fallbackWords.count
            let selected = fallbackWords[nextIndex]
            newWordId = selected.0
            lemma = selected.1
            ipaUs = selected.2
            definitionVi = selected.3
            exampleEn = selected.4
        }

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
