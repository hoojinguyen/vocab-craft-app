import Foundation
import SwiftData

@ModelActor
public actor SpeakingModelActor: SpeakingRepositoryProtocol {
    public func save(_ session: SpeakingSessionSnapshot) throws {
        let payload = try JSONEncoder().encode(session)
        if let record = try fetchSession(id: session.id) {
            record.startedAt = session.startedAt
            record.status = session.status.rawValue
            record.audioFileName = session.audioFileName
            record.payload = payload
            record.fluency = session.analysis?.scores.fluency.value
            record.grammar = session.analysis?.scores.grammar.value
            record.vocabulary = session.analysis?.scores.vocabulary.value
            record.pronunciation = session.analysis?.scores.pronunciation.value
        } else {
            modelContext.insert(SpeakingSessionRecord(
                id: session.id, startedAt: session.startedAt, status: session.status.rawValue,
                audioFileName: session.audioFileName, payload: payload,
                fluency: session.analysis?.scores.fluency.value, grammar: session.analysis?.scores.grammar.value,
                vocabulary: session.analysis?.scores.vocabulary.value,
                pronunciation: session.analysis?.scores.pronunciation.value
            ))
        }
        try modelContext.save()
    }

    public func session(id: UUID) throws -> SpeakingSessionSnapshot? {
        guard let record = try fetchSession(id: id) else { return nil }
        return try JSONDecoder().decode(SpeakingSessionSnapshot.self, from: record.payload)
    }

    public func sessions(limit: Int?) throws -> [SpeakingSessionSnapshot] {
        if let limit, limit <= 0 { return [] }
        var descriptor = FetchDescriptor<SpeakingSessionRecord>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        if let limit { descriptor.fetchLimit = limit }
        return try modelContext.fetch(descriptor).map {
            try JSONDecoder().decode(SpeakingSessionSnapshot.self, from: $0.payload)
        }
    }

    public func updateAnalysis(sessionId: UUID, status: SpeakingSessionStatus, analysis: SpeakingAnalysis?) throws {
        guard var snapshot = try session(id: sessionId) else { return }
        snapshot.status = status
        snapshot.analysis = analysis
        try save(snapshot)
    }

    public func savePhrase(_ phrase: SavedPhrase) throws -> Bool {
        // Task 12 replaces this temporary normalization with QuoteNormalizer.
        let key = phrase.suggestion.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let id = phrase.id
        var descriptor = FetchDescriptor<SavedPhraseRecord>(
            predicate: #Predicate { $0.dedupeKey == key || $0.id == id }
        )
        descriptor.fetchLimit = 1
        guard try modelContext.fetch(descriptor).isEmpty else { return false }
        modelContext.insert(SavedPhraseRecord(
            id: phrase.id, dedupeKey: key, payload: try JSONEncoder().encode(phrase), createdAt: phrase.createdAt
        ))
        try modelContext.save()
        return true
    }

    public func phrases() throws -> [SavedPhrase] {
        let descriptor = FetchDescriptor<SavedPhraseRecord>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor).map { try JSONDecoder().decode(SavedPhrase.self, from: $0.payload) }
    }

    public func deletePhrase(id: UUID) throws {
        let descriptor = FetchDescriptor<SavedPhraseRecord>(predicate: #Predicate { $0.id == id })
        for record in try modelContext.fetch(descriptor) { modelContext.delete(record) }
        try modelContext.save()
    }

    public func detachAudio(keepingLatest count: Int) throws -> [String] {
        let descriptor = FetchDescriptor<SpeakingSessionRecord>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        let records = try modelContext.fetch(descriptor).dropFirst(max(0, count))
        // Decode before mutating so a corrupt payload cannot leave a partially detached batch.
        let updates = try records.compactMap { record -> (SpeakingSessionRecord, (fileName: String, payload: Data))? in
            guard let fileName = record.audioFileName else { return nil }
            var snapshot = try JSONDecoder().decode(SpeakingSessionSnapshot.self, from: record.payload)
            snapshot.audioFileName = nil
            return (record, (fileName, try JSONEncoder().encode(snapshot)))
        }
        for (record, update) in updates {
            record.audioFileName = nil
            record.payload = update.payload
        }
        try modelContext.save()
        return updates.map { $0.1.fileName }
    }

    private func fetchSession(id: UUID) throws -> SpeakingSessionRecord? {
        var descriptor = FetchDescriptor<SpeakingSessionRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
