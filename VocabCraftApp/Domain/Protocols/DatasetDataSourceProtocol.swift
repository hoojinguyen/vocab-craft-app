import Foundation

/// Protocol abstracting SQLite Dataset operations for dependency inversion.
@MainActor
public protocol DatasetDataSourceProtocol: AnyObject {
    func getRandomReflexDrill(cefrLevel: String) -> ReflexDrillRecord?
    func getWordDetails(lemma: String) -> WordRecord?
    func fetchWordRecords(limit: Int, cefrLevel: String?) -> [WordRecord]
    func searchWords(query searchQuery: String) -> [WordRecord]
    func fetchWordById(id targetId: Int64) -> WordRecord?
    func getRandomWordForWidget() -> WordRecord?

    // Topic Decks
    func fetchTopicDecks() -> [TopicDeckRecord]
    func fetchSubTopicNodes(deckId: String) -> [SubTopicNodeRecord]
    func fetchWordsForNode(nodeId: String) -> [WordRecord]
}

public extension DatasetDataSourceProtocol {
    func fetchWordRecords(limit: Int) -> [WordRecord] {
        fetchWordRecords(limit: limit, cefrLevel: nil)
    }
}
