import Foundation

@MainActor
public final class VocabularyRepositoryImpl: VocabularyRepositoryProtocol {
    private let datasetEngine: DatasetEngine?
    private let progressActor: UserProgressModelActor?

    public init(datasetEngine: DatasetEngine? = nil, progressActor: UserProgressModelActor? = nil) {
        self.datasetEngine = datasetEngine
        self.progressActor = progressActor
    }

    public func fetchWordRecords(limit: Int) async throws -> [Word] {
        guard let engine = datasetEngine else { return [] }
        let records = engine.fetchWordRecords(limit: limit)
        return records.map { r in
            Word(
                id: r.id,
                lemma: r.lemma,
                pos: r.pos,
                ipaUs: r.ipaUs,
                cefrLevel: r.cefrLevel,
                definitionEn: r.definitionEn,
                definitionVi: r.definitionVi,
                example: r.example
            )
        }
    }

    public func fetchWord(id: Int64) async throws -> Word? {
        guard let engine = datasetEngine, let r = engine.fetchWordById(id: id) else { return nil }
        return Word(
            id: r.id,
            lemma: r.lemma,
            pos: r.pos,
            ipaUs: r.ipaUs,
            cefrLevel: r.cefrLevel,
            definitionEn: r.definitionEn,
            definitionVi: r.definitionVi,
            example: r.example
        )
    }

    public func fetchReflexDrillRecords(cefrLevel: String) async throws -> [ReflexDrillRecord] {
        guard let engine = datasetEngine, let record = engine.getRandomReflexDrill(cefrLevel: cefrLevel) else { return [] }
        return [record]
    }

    public func searchWords(query: String) async throws -> [Word] {
        guard let engine = datasetEngine else { return [] }
        let records = engine.searchWords(query: query)
        return records.map { r in
            Word(
                id: r.id,
                lemma: r.lemma,
                pos: r.pos,
                ipaUs: r.ipaUs,
                cefrLevel: r.cefrLevel,
                definitionEn: r.definitionEn,
                definitionVi: r.definitionVi,
                example: r.example
            )
        }
    }
}

