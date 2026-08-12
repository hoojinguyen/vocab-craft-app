import Foundation

@MainActor
public final class VocabularyRepositoryImpl: VocabularyRepositoryProtocol {
    private let datasetEngine: DatasetEngine?

    public init(datasetEngine: DatasetEngine? = nil) {
        self.datasetEngine = datasetEngine
    }

    public func fetchWordRecords(limit: Int) async throws -> [Word] {
        guard let engine = datasetEngine, let record = engine.getRandomWordForWidget() else { return [] }
        let word = Word(
            id: record.id,
            lemma: record.lemma,
            pos: record.pos,
            ipaUs: record.ipaUs,
            cefrLevel: record.cefrLevel,
            definitionEn: record.definitionEn,
            definitionVi: record.definitionVi,
            example: record.example
        )
        return [word]
    }

    public func fetchWord(id: Int64) async throws -> Word? {
        guard let engine = datasetEngine, let record = engine.getRandomWordForWidget() else { return nil }
        return Word(
            id: record.id,
            lemma: record.lemma,
            pos: record.pos,
            ipaUs: record.ipaUs,
            cefrLevel: record.cefrLevel,
            definitionEn: record.definitionEn,
            definitionVi: record.definitionVi,
            example: record.example
        )
    }

    public func fetchReflexDrillRecords(cefrLevel: String) async throws -> [ReflexDrillRecord] {
        guard let engine = datasetEngine, let record = engine.getRandomReflexDrill(cefrLevel: cefrLevel) else { return [] }
        return [record]
    }

    public func searchWords(query: String) async throws -> [Word] {
        guard let engine = datasetEngine, let record = engine.getWordDetails(lemma: query) else { return [] }
        let word = Word(
            id: record.id,
            lemma: record.lemma,
            pos: record.pos,
            ipaUs: record.ipaUs,
            cefrLevel: record.cefrLevel,
            definitionEn: record.definitionEn,
            definitionVi: record.definitionVi,
            example: record.example
        )
        return [word]
    }
}
