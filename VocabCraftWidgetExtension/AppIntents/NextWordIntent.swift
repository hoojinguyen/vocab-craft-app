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
        try await perform(in: context, dataSource: BundledVocabularyDataSource())
    }

    @MainActor
    @discardableResult
    public func perform(
        in context: ModelContext,
        dataSource: VocabularyDataSourceProtocol
    ) async throws -> some IntentResult {
        let states = try context.fetch(FetchDescriptor<WidgetCurrentState>())
        let existingState = states.first

        let words = (try? await dataSource.searchWords(query: "")) ?? []
        guard !words.isEmpty else {
            return .result()
        }

        let currentId = existingState?.currentWordId ?? 0
        let nextIndex = ((words.firstIndex(where: { $0.id == currentId }) ?? -1) + 1) % words.count
        let selected = words[nextIndex]
        let newWordId = selected.id
        let lemma = selected.lemma
        let ipaUs = selected.phonetic
        let definitionVi = selected.definitionVi
        let exampleEn = selected.exampleEn

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
