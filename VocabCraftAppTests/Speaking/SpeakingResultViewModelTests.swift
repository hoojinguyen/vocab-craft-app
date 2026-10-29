import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Speaking result view model")
@MainActor
struct SpeakingResultViewModelTests {
    @Test func doubleRetryRunsSingleAnalysis() async throws {
        let session = resultSession(status: .analysisFailed, audioFileName: "retry.m4a")
        let repository = ResultRepository(sessions: [session])
        let analyzer = ResultAnalyzer(analysis: try resultAnalysis(), delay: .milliseconds(80))
        let storage = try resultStorage(files: ["retry.m4a"])
        defer { removeResultStorage(storage) }
        let useCase = AnalyzeSpeakingSessionUseCase(repository: repository, analyzer: analyzer, storage: storage)
        let viewModel = SpeakingResultViewModel(
            sessionId: session.id, repository: repository, analyze: useCase, storage: storage
        )
        await viewModel.load()

        async let firstRetry = viewModel.retry()
        async let secondRetry = viewModel.retry()
        _ = await (firstRetry, secondRetry)

        #expect(await analyzer.callCount == 1)
        #expect(viewModel.session?.status == .analyzed)
    }

    @Test func savingSamePhraseTwiceKeepsOne() async throws {
        let session = resultSession(status: .analyzed, audioFileName: nil, analysis: try resultAnalysis())
        let repository = ResultRepository(sessions: [session])
        let storage = try resultStorage()
        defer { removeResultStorage(storage) }
        let useCase = AnalyzeSpeakingSessionUseCase(
            repository: repository,
            analyzer: ResultAnalyzer(analysis: try resultAnalysis()),
            storage: storage
        )
        let viewModel = SpeakingResultViewModel(
            sessionId: session.id, repository: repository, analyze: useCase, storage: storage
        )
        await viewModel.load()
        let correction = try #require(viewModel.session?.analysis?.corrections.first)

        async let firstSave = viewModel.save(correction: correction)
        async let secondSave = viewModel.save(correction: correction)
        _ = await (firstSave, secondSave)

        #expect(viewModel.savedSuggestions == [QuoteNormalizer.normalize(correction.corrected)])
        let phrases = try await repository.phrases()
        #expect(phrases.count == 1)
    }

    @Test func retryHiddenWhenAudioPruned() async throws {
        let session = resultSession(status: .analysisFailed, audioFileName: "pruned.m4a")
        let repository = ResultRepository(sessions: [session])
        let storage = try resultStorage()
        defer { removeResultStorage(storage) }
        let useCase = AnalyzeSpeakingSessionUseCase(
            repository: repository,
            analyzer: ResultAnalyzer(analysis: try resultAnalysis()),
            storage: storage
        )
        let viewModel = SpeakingResultViewModel(
            sessionId: session.id, repository: repository, analyze: useCase, storage: storage
        )

        await viewModel.load()

        #expect(!viewModel.canRetry)
    }

    @Test func pendingSessionTriggersAnalysisOnLoad() async throws {
        let session = resultSession(status: .pendingAnalysis, audioFileName: "pending.m4a")
        let repository = ResultRepository(sessions: [session])
        let analyzer = ResultAnalyzer(analysis: try resultAnalysis())
        let storage = try resultStorage(files: ["pending.m4a"])
        defer { removeResultStorage(storage) }
        let useCase = AnalyzeSpeakingSessionUseCase(repository: repository, analyzer: analyzer, storage: storage)
        let viewModel = SpeakingResultViewModel(
            sessionId: session.id, repository: repository, analyze: useCase, storage: storage
        )

        await viewModel.load()

        #expect(await analyzer.callCount == 1)
        #expect(viewModel.session?.status == .analyzed)
        #expect(viewModel.session?.analysis != nil)
    }

    @Test func failedAnalysisPersistenceLeavesPendingSpinnerAndRetryState() async throws {
        let session = resultSession(status: .pendingAnalysis, audioFileName: "pending.m4a")
        let repository = ResultRepository(sessions: [session], failingAnalysisUpdates: 1)
        let analyzer = ResultAnalyzer(analysis: try resultAnalysis())
        let storage = try resultStorage(files: ["pending.m4a"])
        defer { removeResultStorage(storage) }
        let useCase = AnalyzeSpeakingSessionUseCase(repository: repository, analyzer: analyzer, storage: storage)
        let viewModel = SpeakingResultViewModel(
            sessionId: session.id, repository: repository, analyze: useCase, storage: storage
        )

        await viewModel.load()

        #expect(!viewModel.isAnalyzing)
        #expect(viewModel.didFailAnalysisWhilePending)
        #expect(viewModel.canRetry)
        #expect(viewModel.session?.status == .pendingAnalysis)
        #expect(viewModel.session?.analysis == nil)

        await viewModel.retry()

        #expect(viewModel.session?.status == .analyzed)
        #expect(viewModel.session?.analysis != nil)
        #expect(!viewModel.didFailAnalysisWhilePending)
    }

    @Test func initialSessionReadFailureLeavesPendingSessionInRecoverableErrorState() async throws {
        let session = resultSession(status: .pendingAnalysis, audioFileName: "pending.m4a")
        let repository = ResultRepository(sessions: [session], failingSessionReadCall: 2)
        let analyzer = ResultAnalyzer(analysis: try resultAnalysis())
        let storage = try resultStorage(files: ["pending.m4a"])
        defer { removeResultStorage(storage) }
        let useCase = AnalyzeSpeakingSessionUseCase(repository: repository, analyzer: analyzer, storage: storage)
        let viewModel = SpeakingResultViewModel(
            sessionId: session.id, repository: repository, analyze: useCase, storage: storage
        )

        await viewModel.load()

        #expect(!viewModel.isAnalyzing)
        #expect(viewModel.didFailAnalysisWhilePending)
        #expect(viewModel.canRetry)
        #expect(await analyzer.callCount == 0)
        #expect(viewModel.session?.status == .pendingAnalysis)
        #expect(viewModel.session?.analysis == nil)
    }
}

private actor ResultRepository: SpeakingRepositoryProtocol {
    private var sessionsByID: [UUID: SpeakingSessionSnapshot]
    private var phrasesByID: [UUID: SavedPhrase] = [:]
    private var failingAnalysisUpdates: Int
    private let failingSessionReadCall: Int?
    private var sessionReadCallCount = 0

    init(
        sessions: [SpeakingSessionSnapshot],
        failingAnalysisUpdates: Int = 0,
        failingSessionReadCall: Int? = nil
    ) {
        sessionsByID = Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0) })
        self.failingAnalysisUpdates = failingAnalysisUpdates
        self.failingSessionReadCall = failingSessionReadCall
    }

    func save(_ session: SpeakingSessionSnapshot) async throws { sessionsByID[session.id] = session }
    func session(id: UUID) async throws -> SpeakingSessionSnapshot? {
        sessionReadCallCount += 1
        if sessionReadCallCount == failingSessionReadCall {
            throw ResultRepositoryError.sessionReadFailed
        }
        return sessionsByID[id]
    }
    func sessions(limit: Int?) async throws -> [SpeakingSessionSnapshot] {
        let all = sessionsByID.values.sorted { $0.startedAt > $1.startedAt }
        return limit.map { Array(all.prefix(max(0, $0))) } ?? all
    }
    func updateAnalysis(sessionId: UUID, status: SpeakingSessionStatus, analysis: SpeakingAnalysis?) async throws {
        if failingAnalysisUpdates > 0 {
            failingAnalysisUpdates -= 1
            throw ResultRepositoryError.analysisUpdateFailed
        }
        guard var session = sessionsByID[sessionId] else { return }
        session.status = status
        session.analysis = analysis
        sessionsByID[sessionId] = session
    }
    func savePhrase(_ phrase: SavedPhrase) async throws -> Bool {
        let key = QuoteNormalizer.normalize(phrase.suggestion)
        guard !phrasesByID.values.contains(where: { QuoteNormalizer.normalize($0.suggestion) == key }) else {
            return false
        }
        phrasesByID[phrase.id] = phrase
        return true
    }
    func phrases() async throws -> [SavedPhrase] { Array(phrasesByID.values) }
    func deletePhrase(id: UUID) async throws { phrasesByID[id] = nil }
    func detachAudio(keepingLatest count: Int) async throws -> [String] { [] }
}

private enum ResultRepositoryError: Error {
    case analysisUpdateFailed
    case sessionReadFailed
}

private actor ResultAnalyzer: SpeakingAnalyzing {
    private let analysis: SpeakingAnalysis
    private let delay: Duration
    private(set) var callCount = 0

    init(analysis: SpeakingAnalysis, delay: Duration = .zero) {
        self.analysis = analysis
        self.delay = delay
    }

    func analyze(_ session: SpeakingSessionSnapshot, audioURL: URL) async throws -> SpeakingAnalysis {
        callCount += 1
        if delay > .zero { try await Task.sleep(for: delay) }
        return analysis
    }
}

private func resultSession(
    status: SpeakingSessionStatus,
    audioFileName: String?,
    analysis: SpeakingAnalysis? = nil
) -> SpeakingSessionSnapshot {
    SpeakingSessionSnapshot(
        id: UUID(), plan: .fixture(), startedAt: Date(), duration: 90, status: status,
        endReason: .learnerEnded, hintCount: 0, audioFileName: audioFileName,
        turns: (0..<2).map { index in
            SpeakingTurn(index: index, speaker: .learner, text: "I would like a latte.", startOffset: 0, endOffset: 1)
        }, analysis: analysis
    )
}

private func resultAnalysis() throws -> SpeakingAnalysis {
    try JSONDecoder().decode(SpeakingAnalysis.self, from: SpeakingFixtures.data("analysis-valid.json"))
}

private func resultStorage(files: [String] = []) throws -> SpeakingAudioStorage {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("speaking-result-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    for fileName in files {
        try Data([1]).write(to: directory.appendingPathComponent(fileName))
    }
    return SpeakingAudioStorage(directory: directory)
}

private func removeResultStorage(_ storage: SpeakingAudioStorage) {
    try? FileManager.default.removeItem(at: storage.url(for: "placeholder").deletingLastPathComponent())
}
