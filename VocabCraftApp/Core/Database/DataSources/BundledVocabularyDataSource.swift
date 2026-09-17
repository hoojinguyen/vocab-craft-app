import Foundation

public final class BundledVocabularyDataSource: VocabularyDataSourceProtocol, Sendable {
    private let bundle: Bundle
    private let resourceName: String
    private let storage: Storage

    public init(bundle: Bundle = .main, resourceName: String = "vocabulary_catalog") {
        self.bundle = bundle
        self.resourceName = resourceName
        self.storage = Storage()
    }

    public func fetchAllDecks() async throws -> [TopicDeckDTO] {
        let catalog = try await getOrLoadCatalog()
        return catalog.decks
    }

    public func fetchDeck(id: String) async throws -> TopicDeckDTO? {
        let catalog = try await getOrLoadCatalog()
        return catalog.deckById[id]
    }

    public func fetchStages(for deckId: String) async throws -> [SubTopicStageDTO] {
        let catalog = try await getOrLoadCatalog()
        return catalog.stagesByDeck[deckId] ?? []
    }

    public func fetchWords(for stageId: String) async throws -> [TopicWordDTO] {
        let catalog = try await getOrLoadCatalog()
        return catalog.wordsByStage[stageId] ?? []
    }

    public func fetchWord(id: Int64) async throws -> TopicWordDTO? {
        let catalog = try await getOrLoadCatalog()
        return catalog.wordById[id]
    }

    public func searchWords(query: String) async throws -> [TopicWordDTO] {
        let catalog = try await getOrLoadCatalog()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return catalog.allWords }
        return catalog.allWords.filter {
            $0.lemma.localizedCaseInsensitiveContains(trimmed) ||
            $0.definitionVi.localizedCaseInsensitiveContains(trimmed) ||
            $0.definitionEn.localizedCaseInsensitiveContains(trimmed)
        }
    }

    // MARK: - VocabularyDataSourceProtocol

    public func fetchTopicDecks() async throws -> [TopicDeckDTO] {
        try await fetchAllDecks()
    }

    public func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO] {
        try await fetchStages(for: deckId)
    }

    public func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO] {
        try await fetchWords(for: stageId)
    }

    public func fetchWordById(id: Int64) async throws -> TopicWordDTO? {
        try await fetchWord(id: id)
    }

    public func fetchWordsByIds(ids: Set<Int64>) async throws -> [TopicWordDTO] {
        guard !ids.isEmpty else { return [] }
        let catalog = try await getOrLoadCatalog()
        return ids.sorted().compactMap { catalog.wordById[$0] }
    }

    public func fetchAllWordsMap() async throws -> [Int64: TopicWordDTO] {
        let catalog = try await getOrLoadCatalog()
        return catalog.wordById
    }

    /// Validates that the underlying catalog resource exists and can be successfully decoded.
    public func validateCatalog() throws {
        _ = try Self.loadAndIndex(bundle: bundle, resourceName: resourceName)
    }

    /// Provides canonical starter words for roadmap synthesis and onboarding fallbacks.
    public static func starterWords(forStageId stageId: String? = nil) -> [TopicWordDTO] {
        let catalog = try? loadAndIndex(bundle: .main, resourceName: "vocabulary_catalog")
        if let stageId, let words = catalog?.wordsByStage[stageId], !words.isEmpty {
            return words
        }
        if let words = catalog?.allWords, !words.isEmpty {
            return Array(words.prefix(3))
        }
        return [
            TopicWordDTO(
                id: 1,
                stageId: stageId ?? "stage_daily_1",
                lemma: "Resilience",
                phonetic: "/rɪˈzɪl.jəns/",
                pos: "noun",
                cefrLevel: "B2",
                definitionVi: "Khả năng phục hồi, kiên cường",
                definitionEn: "The capacity to recover quickly from difficulties",
                exampleEn: "Her resilience helped her overcome difficulties.",
                exampleVi: "Sự kiên cường giúp cô ấy vượt qua khó khăn."
            ),
            TopicWordDTO(
                id: 2,
                stageId: stageId ?? "stage_daily_1",
                lemma: "Overwhelmed",
                phonetic: "/ˌoʊ.vɚˈwelmd/",
                pos: "adjective",
                cefrLevel: "B1",
                definitionVi: "Bị ngợp, quá tải",
                definitionEn: "Completely overcome by emotions or tasks",
                exampleEn: "He felt overwhelmed by the workload.",
                exampleVi: "Anh ấy cảm thấy quá tải vì khối lượng công việc."
            ),
            TopicWordDTO(
                id: 3,
                stageId: stageId ?? "stage_daily_1",
                lemma: "Spontaneous",
                phonetic: "/spɑːnˈteɪ.ni.əs/",
                pos: "adjective",
                cefrLevel: "B2",
                definitionVi: "Tự phát, ngẫu hứng",
                definitionEn: "Performed or occurring as a result of a sudden impulse",
                exampleEn: "We took a spontaneous road trip.",
                exampleVi: "Chúng tôi đã có một chuyến đi phượt ngẫu hứng."
            )
        ]
    }

    // MARK: - Internal Storage & Loading

    private func getOrLoadCatalog() async throws -> IndexedCatalog {
        try await storage.getOrLoad(bundle: bundle, resourceName: resourceName)
    }

    fileprivate static func loadAndIndex(bundle: Bundle, resourceName: String) throws -> IndexedCatalog {
        let data = try loadData(bundle: bundle, resourceName: resourceName)
        let decoder = JSONDecoder()
        let catalog: VocabularyCatalogDTO
        do {
            catalog = try decoder.decode(VocabularyCatalogDTO.self, from: data)
        } catch {
            throw VocabularyCatalogError.decodingFailed(description: error.localizedDescription)
        }

        var allWords: [TopicWordDTO] = []
        var stagesByDeck: [String: [SubTopicStageDTO]] = [:]
        var stageById: [String: SubTopicStageDTO] = [:]
        var wordsByStage: [String: [TopicWordDTO]] = [:]
        var wordById: [Int64: TopicWordDTO] = [:]

        let sortedDecks = catalog.decks.sorted { $0.sortOrder < $1.sortOrder }
        var deckById: [String: TopicDeckDTO] = [:]

        for deck in sortedDecks {
            deckById[deck.id] = deck
            let sortedStages = deck.stages.sorted { $0.sortOrder < $1.sortOrder }
            stagesByDeck[deck.id] = sortedStages

            for stage in sortedStages {
                stageById[stage.id] = stage
                wordsByStage[stage.id] = stage.words

                for word in stage.words {
                    allWords.append(word)
                    wordById[word.id] = word
                }
            }
        }

        return IndexedCatalog(
            decks: sortedDecks,
            deckById: deckById,
            stagesByDeck: stagesByDeck,
            stageById: stageById,
            wordsByStage: wordsByStage,
            wordById: wordById,
            allWords: allWords
        )
    }

    private static func loadData(bundle: Bundle, resourceName: String) throws -> Data {
        if let url = findURL(bundle: bundle, resourceName: resourceName) {
            do {
                return try Data(contentsOf: url)
            } catch {
                throw VocabularyCatalogError.decodingFailed(description: error.localizedDescription)
            }
        }

        if resourceName == "vocabulary_catalog", let fallback = fallbackData() {
            return fallback
        }

        throw VocabularyCatalogError.resourceNotFound(name: resourceName, bundle: bundle.bundlePath)
    }

    private static func findURL(bundle: Bundle, resourceName: String) -> URL? {
        if let url = bundle.url(forResource: resourceName, withExtension: "json") {
            return url
        }

        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: resourceName, withExtension: "json") {
            return url
        }
        #endif

        if let url = Bundle.main.url(forResource: resourceName, withExtension: "json") {
            return url
        }

        let containingAppURL = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
        if let containingAppBundle = Bundle(url: containingAppURL),
           let url = containingAppBundle.url(forResource: resourceName, withExtension: "json") {
            return url
        }

        return nil
    }

    private static func fallbackData() -> Data? {
        let currentFilePath = URL(fileURLWithPath: #filePath)
        let candidateURL = currentFilePath
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/vocabulary_catalog.json")

        return try? Data(contentsOf: candidateURL)
    }
}

// MARK: - Supporting Types

private struct IndexedCatalog: Sendable {
    let decks: [TopicDeckDTO]
    let deckById: [String: TopicDeckDTO]
    let stagesByDeck: [String: [SubTopicStageDTO]]
    let stageById: [String: SubTopicStageDTO]
    let wordsByStage: [String: [TopicWordDTO]]
    let wordById: [Int64: TopicWordDTO]
    let allWords: [TopicWordDTO]
}

private actor Storage {
    private var cached: IndexedCatalog?

    func getOrLoad(bundle: Bundle, resourceName: String) throws -> IndexedCatalog {
        if let cached {
            return cached
        }
        let catalog = try BundledVocabularyDataSource.loadAndIndex(bundle: bundle, resourceName: resourceName)
        self.cached = catalog
        return catalog
    }
}
