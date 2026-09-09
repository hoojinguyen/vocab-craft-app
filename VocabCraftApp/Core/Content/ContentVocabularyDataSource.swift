import Foundation
import os

/// Adapter exposing SQLite ContentRepository as a VocabularyDataSourceProtocol for seamless offline learning.
public final class ContentVocabularyDataSource: VocabularyDataSourceProtocol, Sendable {
    private let repository: any ContentRepository
    private let cacheLock = OSAllocatedUnfairLock(initialState: [Int64: TopicWordDTO]())

    public init(repository: any ContentRepository) {
        self.repository = repository
    }

    public func fetchTopicDecks() async throws -> [TopicDeckDTO] {
        let decks = try await repository.fetchDecks()
        return decks.map { deck in
            TopicDeckDTO(
                id: deck.id.rawValue.uuidString.lowercased(),
                title: deck.titleVI.isEmpty ? deck.titleEN : deck.titleVI,
                iconName: Self.mapIconName(deck.iconKey),
                badgeColorHex: "#3B82F6",
                cefrLevel: deck.cefrLevels.first?.rawValue ?? "A1",
                sortOrder: 0
            )
        }
    }

    public func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO] {
        guard let deckID = DeckID(uuidString: deckId) else {
            return []
        }
        let lessons = try await repository.fetchLessons(deckID: deckID)
        return lessons.map { lesson in
            SubTopicStageDTO(
                id: lesson.id.rawValue.uuidString.lowercased(),
                deckId: deckId,
                title: lesson.titleVI.isEmpty ? lesson.titleEN : lesson.titleVI,
                iconName: Self.mapIconName(lesson.iconKey),
                sortOrder: lesson.sortOrder
            )
        }
    }

    public func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO] {
        if stageId.hasPrefix("checkpoint_") {
            let deckIdStr = String(stageId.dropFirst("checkpoint_".count))
            guard let deckID = DeckID(uuidString: deckIdStr) else {
                return []
            }
            let lessons = try await repository.fetchLessons(deckID: deckID)
            var allSenseIDs: [SenseID] = []
            for lesson in lessons {
                let content = try await repository.fetchLessonContent(lessonID: lesson.id)
                allSenseIDs.append(contentsOf: content.senses.map(\.senseID))
            }
            let senses = try await repository.fetchSenses(ids: allSenseIDs)
            let words = senses.map { Self.mapToTopicWord(sense: $0, stageId: stageId) }
            cacheLock.withLock { dict in
                for word in words { dict[word.id] = word }
            }
            return words
        }

        guard let lessonID = LessonID(uuidString: stageId) else {
            return []
        }
        let detail = try await repository.fetchLessonContent(lessonID: lessonID)
        let senses = try await repository.fetchSenses(ids: detail.senses.map(\.senseID))
        let words = senses.map { Self.mapToTopicWord(sense: $0, stageId: stageId) }
        cacheLock.withLock { dict in
            for word in words { dict[word.id] = word }
        }
        return words
    }

    public func searchWords(query: String) async throws -> [TopicWordDTO] {
        let result = try await repository.search(query: query, limit: 30, cursor: nil)
        let senses = try await repository.fetchSenses(ids: result.senses.map(\.senseID))
        return senses.map { Self.mapToTopicWord(sense: $0, stageId: "") }
    }

    public func fetchWordById(id: Int64) async throws -> TopicWordDTO? {
        if let cached = cacheLock.withLock({ $0[id] }) {
            return cached
        }
        let allWords = try await fetchAllWordsMap()
        return allWords[id]
    }

    public func fetchWordsByIds(ids: Set<Int64>) async throws -> [TopicWordDTO] {
        guard !ids.isEmpty else { return [] }
        let allWords = try await fetchAllWordsMap()
        return ids.compactMap { allWords[$0] }
    }

    public func fetchAllWordsMap() async throws -> [Int64: TopicWordDTO] {
        let cached = cacheLock.withLock { $0 }
        if !cached.isEmpty {
            return cached
        }
        let decks = try await repository.fetchDecks()
        var allWords: [Int64: TopicWordDTO] = [:]
        for deck in decks {
            let lessons = try await repository.fetchLessons(deckID: deck.id)
            for lesson in lessons {
                let stageId = lesson.id.rawValue.uuidString.lowercased()
                let content = try await repository.fetchLessonContent(lessonID: lesson.id)
                let senses = try await repository.fetchSenses(ids: content.senses.map(\.senseID))
                for sense in senses {
                    let word = Self.mapToTopicWord(sense: sense, stageId: stageId)
                    allWords[word.id] = word
                }
            }
        }
        cacheLock.withLock { $0 = allWords }
        return allWords
    }

    private static func mapToTopicWord(sense: SenseDetail, stageId: String) -> TopicWordDTO {
        let stableId = deterministicInt64(from: sense.id.rawValue)
        return TopicWordDTO(
            id: stableId,
            stageId: stageId,
            lemma: sense.headword,
            phonetic: sense.ipa ?? sense.pronunciations.first?.ipa ?? "",
            pos: sense.partOfSpeech.rawValue,
            cefrLevel: sense.cefrLevel.rawValue,
            definitionVi: sense.definitionVI,
            definitionEn: sense.definitionEN,
            exampleEn: sense.examples.first?.textEN ?? "",
            exampleVi: sense.examples.first?.textVI ?? ""
        )
    }

    private static func deterministicInt64(from uuid: UUID) -> Int64 {
        var u = uuid.uuid
        return withUnsafeBytes(of: &u) { raw in
            let partOne = raw.load(fromByteOffset: 0, as: UInt64.self)
            let partTwo = raw.load(fromByteOffset: 8, as: UInt64.self)
            return Int64(bitPattern: partOne ^ partTwo)
        }
    }

    private static func mapIconName(_ iconKey: String) -> String {
        switch iconKey {
        case "book_open": return "book.fill"
        case "bookmark": return "bookmark.fill"
        case "graduation_cap": return "graduationcap.fill"
        case "plane": return "airplane"
        case "chat": return "bubble.left.and.bubble.right.fill"
        case "sparkles": return "sparkles"
        case "compass": return "safari.fill"
        case "star": return "star.fill"
        default: return iconKey.isEmpty ? "book.fill" : iconKey
        }
    }
}
