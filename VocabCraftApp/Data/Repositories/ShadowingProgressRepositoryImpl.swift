import Foundation

public final class ShadowingProgressRepositoryImpl: ShadowingProgressRepositoryProtocol, @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let storageKey: String
    private let lock = NSLock()
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "shadowing_progress_records"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func getProgress(videoId: String) async -> ShadowingProgressRecord? {
        lock.lock()
        defer { lock.unlock() }
        return loadRecordsLocked()[videoId]
    }

    public func getAllProgress() async -> [String: ShadowingProgressRecord] {
        lock.lock()
        defer { lock.unlock() }
        return loadRecordsLocked()
    }

    public func recordCompletion(
        videoId: String,
        score: Double,
        sentenceScores: [String: Double]
    ) async throws {
        lock.lock()
        defer { lock.unlock() }

        var records = loadRecordsLocked()
        let now = Date()

        if let existing = records[videoId] {
            var mergedSentenceScores = existing.sentenceScores
            for (key, val) in sentenceScores {
                mergedSentenceScores[key] = val
            }

            let updated = ShadowingProgressRecord(
                videoId: videoId,
                bestScore: max(existing.bestScore, score),
                lastCompletedAt: now,
                timesCompleted: existing.timesCompleted + 1,
                sentenceScores: mergedSentenceScores
            )
            records[videoId] = updated
        } else {
            let newRecord = ShadowingProgressRecord(
                videoId: videoId,
                bestScore: score,
                lastCompletedAt: now,
                timesCompleted: 1,
                sentenceScores: sentenceScores
            )
            records[videoId] = newRecord
        }

        try saveRecordsLocked(records)
    }

    private func loadRecordsLocked() -> [String: ShadowingProgressRecord] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return [:]
        }
        do {
            return try decoder.decode([String: ShadowingProgressRecord].self, from: data)
        } catch {
            return [:]
        }
    }

    private func saveRecordsLocked(_ records: [String: ShadowingProgressRecord]) throws {
        let data = try encoder.encode(records)
        userDefaults.set(data, forKey: storageKey)
    }
}
