import Foundation
import Testing
@testable import VocabCraftApp

struct AnalyzeSpeakingSessionUseCaseTests {
    @Test func concurrentExecuteRunsAnalyzerOnce() async throws {
        let snapshot = speakingSnapshot(audioFileName: "session.m4a", learnerTurns: 2)
        let fixture = try analysisFixture()
        let repository = InMemorySpeakingRepository(sessions: [snapshot])
        let analyzer = ScriptedSpeakingAnalyzer(analysis: fixture, delay: .milliseconds(100))
        let storage = try temporaryStorage(files: ["session.m4a"])
        defer { removeTemporaryStorage(storage) }
        let useCase = AnalyzeSpeakingSessionUseCase(repository: repository, analyzer: analyzer, storage: storage)

        async let first = useCase.execute(sessionId: snapshot.id)
        async let second = useCase.execute(sessionId: snapshot.id)
        let statuses = await [first, second]

        #expect(statuses == [.analyzed, .analyzed])
        #expect(await analyzer.callCount == 1)
    }

    @Test func cancellingOneCallerDoesNotCancelSharedAnalysis() async throws {
        let snapshot = speakingSnapshot(audioFileName: "session.m4a", learnerTurns: 2)
        let analyzer = ScriptedSpeakingAnalyzer(analysis: try analysisFixture(), delay: .milliseconds(150))
        let storage = try temporaryStorage(files: ["session.m4a"])
        defer { removeTemporaryStorage(storage) }
        let useCase = AnalyzeSpeakingSessionUseCase(
            repository: InMemorySpeakingRepository(sessions: [snapshot]), analyzer: analyzer,
            storage: storage
        )

        let cancelledCaller = Task { await useCase.execute(sessionId: snapshot.id) }
        try await Task.sleep(for: .milliseconds(20))
        cancelledCaller.cancel()
        let remainingCaller = Task { await useCase.execute(sessionId: snapshot.id) }

        #expect(await cancelledCaller.value == .analyzed)
        #expect(await remainingCaller.value == .analyzed)
        #expect(await analyzer.callCount == 1)
    }

    @Test func shortSessionIsMarkedTooShortWithoutCallingAnalyzer() async throws {
        let snapshot = speakingSnapshot(audioFileName: "session.m4a", learnerTurns: 1)
        let repository = InMemorySpeakingRepository(sessions: [snapshot])
        let analyzer = ScriptedSpeakingAnalyzer(analysis: try analysisFixture())
        let storage = try temporaryStorage(files: ["session.m4a"])
        defer { removeTemporaryStorage(storage) }
        let useCase = AnalyzeSpeakingSessionUseCase(repository: repository, analyzer: analyzer, storage: storage)

        let status = await useCase.execute(sessionId: snapshot.id)

        #expect(status == .tooShort)
        #expect(await analyzer.callCount == 0)
        let saved = try await repository.session(id: snapshot.id)
        #expect(saved?.status == .tooShort)
    }

    @Test func failureThenRetrySucceedsWithSingleRecord() async throws {
        let snapshot = speakingSnapshot(audioFileName: "session.m4a", learnerTurns: 2)
        let repository = InMemorySpeakingRepository(sessions: [snapshot])
        let analyzer = ScriptedSpeakingAnalyzer(analysis: try analysisFixture(), failuresBeforeSuccess: 1)
        let storage = try temporaryStorage(files: ["session.m4a"])
        defer { removeTemporaryStorage(storage) }
        let useCase = AnalyzeSpeakingSessionUseCase(repository: repository, analyzer: analyzer, storage: storage)

        #expect(await useCase.execute(sessionId: snapshot.id) == .analysisFailed)
        let failedSession = try await repository.session(id: snapshot.id)
        #expect(failedSession?.analysis == nil)
        #expect(await useCase.execute(sessionId: snapshot.id) == .analyzed)
        let sessions = try await repository.sessions(limit: nil)
        #expect(sessions.count == 1)
        #expect(await analyzer.callCount == 2)
    }

    @Test func missingAudioFileFailsAndPreservesAudioMissingState() async throws {
        let snapshot = speakingSnapshot(audioFileName: "missing.m4a", learnerTurns: 2)
        let repository = InMemorySpeakingRepository(sessions: [snapshot])
        let analyzer = ScriptedSpeakingAnalyzer(analysis: try analysisFixture())
        let storage = try temporaryStorage()
        defer { removeTemporaryStorage(storage) }
        let useCase = AnalyzeSpeakingSessionUseCase(repository: repository, analyzer: analyzer, storage: storage)

        let status = await useCase.execute(sessionId: snapshot.id)

        #expect(status == .analysisFailed)
        #expect(await analyzer.callCount == 0)
        let failedSession = try await repository.session(id: snapshot.id)
        #expect(failedSession?.audioFileName == nil)
    }

    @Test func missingAudioFileNameFailsWithoutCallingAnalyzer() async throws {
        let snapshot = speakingSnapshot(audioFileName: nil, learnerTurns: 2)
        let repository = InMemorySpeakingRepository(sessions: [snapshot])
        let analyzer = ScriptedSpeakingAnalyzer(analysis: try analysisFixture())
        let storage = try temporaryStorage()
        defer { removeTemporaryStorage(storage) }
        let useCase = AnalyzeSpeakingSessionUseCase(repository: repository, analyzer: analyzer, storage: storage)

        #expect(await useCase.execute(sessionId: snapshot.id) == .analysisFailed)
        #expect(await analyzer.callCount == 0)
        let saved = try await repository.session(id: snapshot.id)
        #expect(saved?.status == .analysisFailed)
        #expect(saved?.audioFileName == nil)
    }

    @Test func pruningDeletesDetachedFiles() async throws {
        let snapshots = (0..<22).map { index in
            speakingSnapshot(
                startedAt: Date(timeIntervalSince1970: TimeInterval(index)),
                audioFileName: "session-\(index).m4a",
                learnerTurns: index == 21 ? 2 : 0
            )
        }
        let repository = InMemorySpeakingRepository(sessions: snapshots)
        let analyzer = ScriptedSpeakingAnalyzer(analysis: try analysisFixture())
        let fileNames = snapshots.compactMap(\.audioFileName)
        let storage = try temporaryStorage(files: fileNames)
        defer { removeTemporaryStorage(storage) }
        let useCase = AnalyzeSpeakingSessionUseCase(repository: repository, analyzer: analyzer, storage: storage)

        #expect(await useCase.execute(sessionId: snapshots.last!.id) == .analyzed)

        #expect(!FileManager.default.fileExists(atPath: storage.url(for: "session-0.m4a").path))
        #expect(!FileManager.default.fileExists(atPath: storage.url(for: "session-1.m4a").path))
        #expect(FileManager.default.fileExists(atPath: storage.url(for: "session-2.m4a").path))
        let sessions = try await repository.sessions(limit: nil)
        #expect(sessions.filter { $0.audioFileName != nil }.count == 20)
    }
}

private actor InMemorySpeakingRepository: SpeakingRepositoryProtocol {
    private var storedSessions: [UUID: SpeakingSessionSnapshot]

    init(sessions: [SpeakingSessionSnapshot]) {
        storedSessions = Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0) })
    }

    func save(_ session: SpeakingSessionSnapshot) async throws {
        storedSessions[session.id] = session
    }

    func session(id: UUID) async throws -> SpeakingSessionSnapshot? {
        storedSessions[id]
    }

    func sessions(limit: Int?) async throws -> [SpeakingSessionSnapshot] {
        let ordered = storedSessions.values.sorted { $0.startedAt > $1.startedAt }
        guard let limit else { return ordered }
        return Array(ordered.prefix(max(0, limit)))
    }

    func updateAnalysis(sessionId: UUID, status: SpeakingSessionStatus, analysis: SpeakingAnalysis?) async throws {
        guard var session = storedSessions[sessionId] else { return }
        session.status = status
        session.analysis = analysis
        storedSessions[sessionId] = session
    }

    func savePhrase(_ phrase: SavedPhrase) async throws -> Bool { false }
    func phrases() async throws -> [SavedPhrase] { [] }
    func deletePhrase(id: UUID) async throws {}

    func detachAudio(keepingLatest count: Int) async throws -> [String] {
        let ordered = storedSessions.values.sorted { $0.startedAt > $1.startedAt }
        var detached: [String] = []
        for snapshot in ordered.dropFirst(max(0, count)) {
            guard var session = storedSessions[snapshot.id], let fileName = session.audioFileName else { continue }
            session.audioFileName = nil
            storedSessions[session.id] = session
            detached.append(fileName)
        }
        return detached
    }
}

private actor ScriptedSpeakingAnalyzer: SpeakingAnalyzing {
    private let analysis: SpeakingAnalysis
    private let delay: Duration
    private var failuresRemaining: Int
    private(set) var callCount = 0

    init(analysis: SpeakingAnalysis, failuresBeforeSuccess: Int = 0, delay: Duration = .zero) {
        self.analysis = analysis
        failuresRemaining = failuresBeforeSuccess
        self.delay = delay
    }

    func analyze(_ session: SpeakingSessionSnapshot, audioURL: URL) async throws -> SpeakingAnalysis {
        callCount += 1
        if delay > .zero { try await Task.sleep(for: delay) }
        if failuresRemaining > 0 {
            failuresRemaining -= 1
            throw SpeakingAnalysisError.network
        }
        return analysis
    }
}

private func speakingSnapshot(
    id: UUID = UUID(),
    startedAt: Date = Date(),
    audioFileName: String?,
    learnerTurns: Int
) -> SpeakingSessionSnapshot {
    var session = SpeakingSessionSnapshot.fixture(id: id, startedAt: startedAt, audioFileName: audioFileName)
    session = SpeakingSessionSnapshot(
        id: session.id, plan: session.plan, startedAt: session.startedAt, duration: session.duration,
        status: session.status, endReason: session.endReason, hintCount: session.hintCount,
        audioFileName: session.audioFileName,
        turns: (0..<learnerTurns).map { index in
            SpeakingTurn(index: index, speaker: .learner, text: "I would like a latte.", startOffset: 1, endOffset: 2)
        },
        analysis: session.analysis
    )
    return session
}

private func analysisFixture() throws -> SpeakingAnalysis {
    try JSONDecoder().decode(SpeakingAnalysis.self, from: SpeakingFixtures.data("analysis-valid.json"))
}

private func temporaryStorage(files: [String] = []) throws -> SpeakingAudioStorage {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("speaking-use-case-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    for fileName in files {
        try Data([1]).write(to: directory.appendingPathComponent(fileName))
    }
    return SpeakingAudioStorage(directory: directory)
}

private func removeTemporaryStorage(_ storage: SpeakingAudioStorage) {
    let directory = storage.url(for: "temporary-file").deletingLastPathComponent()
    try? FileManager.default.removeItem(at: directory)
}
