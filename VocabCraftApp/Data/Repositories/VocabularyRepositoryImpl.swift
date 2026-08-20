import Foundation
import SwiftUI

/// Production repository implementation connecting SQLite dataset engine and SwiftData user progress actor.
@MainActor
public final class VocabularyRepositoryImpl: VocabularyRepositoryProtocol {
    private let datasetEngine: DatasetDataSourceProtocol?
    private let progressActor: UserProgressModelActor?

    /// Creates a production vocabulary repository with optional dataset engine and progress actor dependencies.
    ///
    /// - Parameters:
    ///   - datasetEngine: The SQLite dataset engine instance or mock implementing DatasetDataSourceProtocol.
    ///   - progressActor: The SwiftData background actor for user progress operations.
    public init(datasetEngine: DatasetDataSourceProtocol? = nil, progressActor: UserProgressModelActor? = nil) {
        self.datasetEngine = datasetEngine
        self.progressActor = progressActor
    }

    /// Fetches vocabulary word records up to the specified limit.
    public func fetchWordRecords(limit: Int) async throws -> [Word] {
        guard let engine = datasetEngine else { return [] }
        let records = engine.fetchWordRecords(limit: limit)
        return records.map { r in
            Word(
                id: r.id,
                lemma: r.lemma,
                pos: r.pos ?? "",
                ipaUs: r.ipaUs ?? "",
                cefrLevel: r.cefrLevel ?? "",
                definitionEn: r.definitionEn ?? "",
                definitionVi: r.definitionVi ?? "",
                example: r.example ?? ""
            )
        }
    }

    /// Fetches a single word by its unique database identifier.
    public func fetchWord(id: Int64) async throws -> Word? {
        guard let engine = datasetEngine, let r = engine.fetchWordById(id: id) else { return nil }
        return Word(
            id: r.id,
            lemma: r.lemma,
            pos: r.pos ?? "",
            ipaUs: r.ipaUs ?? "",
            cefrLevel: r.cefrLevel ?? "",
            definitionEn: r.definitionEn ?? "",
            definitionVi: r.definitionVi ?? "",
            example: r.example ?? ""
        )
    }

    /// Fetches reflex drill prompt records matching the specified CEFR level.
    public func fetchReflexDrillRecords(cefrLevel: String) async throws -> [ReflexDrillRecord] {
        guard let engine = datasetEngine, let record = engine.getRandomReflexDrill(cefrLevel: cefrLevel) else { return [] }
        return [record]
    }

    /// Searches vocabulary words matching the given query string.
    public func searchWords(query: String) async throws -> [Word] {
        guard let engine = datasetEngine else { return [] }
        let records = engine.searchWords(query: query)
        return records.map { r in
            Word(
                id: r.id,
                lemma: r.lemma,
                pos: r.pos ?? "",
                ipaUs: r.ipaUs ?? "",
                cefrLevel: r.cefrLevel ?? "",
                definitionEn: r.definitionEn ?? "",
                definitionVi: r.definitionVi ?? "",
                example: r.example ?? ""
            )
        }
    }

    /// Fetches daily suggested words.
    public func fetchSuggestedWords(limit: Int) async throws -> [SuggestedWord] {
        guard let engine = datasetEngine else { return MockVocabularyDataSource.shared.mockSuggestedWords }
        let records = engine.fetchWordRecords(limit: limit)
        if records.isEmpty {
            return MockVocabularyDataSource.shared.mockSuggestedWords
        }
        return records.map { r in
            SuggestedWord(
                id: String(r.id),
                lemma: r.lemma,
                pos: r.pos ?? "",
                ipaUs: r.ipaUs ?? "",
                cefrLevel: r.cefrLevel ?? "",
                definitionVi: r.definitionVi ?? "",
                definitionEn: r.definitionEn ?? "",
                example: r.example ?? "",
                isBookmarked: false,
                topicTag: "Từ vựng nổi bật"
            )
        }
    }

    /// Fetches available topic decks and their associated subtopic nodes.
    public func fetchTopicDecks() async throws -> [TopicDeck] {
        guard let engine = datasetEngine else { return MockVocabularyDataSource.shared.mockTopicDecks }
        let records = engine.fetchTopicDecks()
        if records.isEmpty {
            return MockVocabularyDataSource.shared.mockTopicDecks
        }
        
        let masteryMap = (try? await progressActor?.fetchAllMasteryLevels()) ?? [:]
        
        var decks: [TopicDeck] = []
        for r in records {
            // Need to compute wordCount and completionPercentage
            let nodeRecords = engine.fetchSubTopicNodes(deckId: r.id)
            var totalWords = 0
            var learnedWords = 0
            
            for nodeRecord in nodeRecords {
                let wordRecords = engine.fetchWordsForNode(nodeId: nodeRecord.id)
                totalWords += wordRecords.count
                
                for w in wordRecords {
                    if (masteryMap[w.id] ?? 0) >= 5 {
                        learnedWords += 1
                    }
                }
            }
            
            let percentage = totalWords > 0 ? Double(learnedWords) / Double(totalWords) : 0.0
            decks.append(TopicDeck(
                id: r.id,
                title: r.title,
                wordCount: totalWords,
                completionPercentage: percentage,
                badgeColor: Color(hex: r.badgeColorHex),
                iconName: r.iconName
            ))
        }
        return decks
    }
    
    /// Fetches the nodes for a specific topic deck.
    public func fetchTopicDeckDetails(deckId: String) async throws -> [SubTopicNode] {
        guard let engine = datasetEngine else { return SubTopicNode.sampleNodes }
        let nodeRecords = engine.fetchSubTopicNodes(deckId: deckId)
        if nodeRecords.isEmpty {
            return SubTopicNode.sampleNodes
        }
        
        let progressMap = (try? await progressActor?.fetchAllProgressSummaryMap()) ?? [:]
        
        var nodes: [SubTopicNode] = []
        var previousCompleted = true // First node is unlocked by default
        
        for nodeRecord in nodeRecords {
            let wordRecords = engine.fetchWordsForNode(nodeId: nodeRecord.id)
            var topicWords: [TopicWord] = []
            var learnedWords = 0
            
            for w in wordRecords {
                let summary = progressMap[w.id]
                let isMastered = (summary?.masteryLevel ?? 0) >= 5
                let isSaved = summary?.isBookmarked ?? false
                if isMastered { learnedWords += 1 }
                
                topicWords.append(TopicWord(
                    id: String(w.id),
                    english: w.lemma,
                    phonetic: w.ipaUs ?? "",
                    vietnamese: w.definitionVi ?? w.definitionEn ?? "",
                    example: w.example ?? "",
                    partOfSpeech: w.pos ?? "",
                    isMastered: isMastered,
                    isSavedToPersonalVault: isSaved
                ))
            }
            
            let totalWords = wordRecords.count
            let isCompleted = totalWords > 0 && learnedWords == totalWords
            
            let state: NodeState
            if isCompleted {
                state = .completed
            } else if previousCompleted {
                state = .active
            } else {
                state = .locked
            }
            
            previousCompleted = isCompleted
            
            nodes.append(SubTopicNode(
                id: nodeRecord.id,
                title: nodeRecord.title,
                iconName: nodeRecord.iconName,
                totalWords: totalWords,
                learnedWords: learnedWords,
                state: state,
                words: topicWords
            ))
        }
        return nodes
    }
}
