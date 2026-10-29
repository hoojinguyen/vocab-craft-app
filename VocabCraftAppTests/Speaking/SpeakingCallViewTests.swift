import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Speaking call view content")
struct SpeakingCallViewTests {
    @Test func liveShowsHintAndTimeLeft() {
        let content = SpeakingCallViewContent.make(phase: .live, elapsed: 300, duration: 360)

        #expect(content.timeLeft == 60)
        #expect(content.showsHint)
        #expect(!content.showsReconnecting)
        #expect(content.failure == nil)
        #expect(content.statusKey.isEmpty)
    }

    @Test func reconnectingHidesHintAndKeepsCountdown() {
        let content = SpeakingCallViewContent.make(phase: .reconnecting, elapsed: 310, duration: 360)

        #expect(!content.showsHint)
        #expect(content.showsReconnecting)
        #expect(content.timeLeft == 50)
        #expect(content.statusKey == "app.speaking.call.reconnecting")
    }

    @Test func failedQuotaExposesFailure() {
        let content = SpeakingCallViewContent.make(phase: .failed(.quotaExceeded), elapsed: 12, duration: 360)

        #expect(content.failure == .quotaExceeded)
        #expect(content.statusKey == "app.speaking.error.quota")
        #expect(content.timeLeft == nil)
        #expect(!content.showsHint)
    }

    @Test func liveCountdownNeverGoesBelowZero() {
        let content = SpeakingCallViewContent.make(phase: .live, elapsed: 400, duration: 360)

        #expect(content.timeLeft == 0)
    }

    @Test func endingWhileConnectingWithoutSnapshotDismisses() {
        #expect(
            SpeakingCallViewContent.shouldDismissAfterEndRequest(
                startingPhase: .connecting,
                resultingPhase: .ended(.learnerEnded),
                hasResult: false
            )
        )
    }

    @Test func endAfterSetupInterruptionStillDismisses() {
        #expect(SpeakingCallViewContent.shouldDismissAfterEndRequest(
            startingPhase: .ended(.interrupted),
            resultingPhase: .ended(.interrupted),
            hasResult: false
        ))
    }

    @Test func endingWithSnapshotPreservesResultFlow() {
        #expect(
            !SpeakingCallViewContent.shouldDismissAfterEndRequest(
                startingPhase: .connecting,
                resultingPhase: .ended(.learnerEnded),
                hasResult: true
            )
        )
    }

    @Test func liveTerminalWithoutSnapshotWaitsForFinalization() {
        #expect(!SpeakingCallViewContent.shouldDismissAfterEndRequest(
            startingPhase: .ended(.interrupted), resultingPhase: .ended(.interrupted),
            hasResult: false, hasBeenLive: true
        ))
    }

    @Test func connectionFailureKeepsFailureDialogVisible() {
        #expect(
            !SpeakingCallViewContent.shouldDismissAfterEndRequest(
                startingPhase: .connecting,
                resultingPhase: .failed(.quotaExceeded),
                hasResult: false
            )
        )
    }
}

@Suite("Speaking call completion")
@MainActor
struct SpeakingCallCompletionTests {
    @Test(arguments: [false, true])
    func suspendedAnalysisSavesFirstAndHonorsExit(exits: Bool) async throws {
        let storage = try completionStorage()
        defer { try? FileManager.default.removeItem(at: storage.url(for: "session.m4a").deletingLastPathComponent()) }
        let repository = CompletionRepository()
        let analyzer = SuspendedCompletionAnalyzer()
        let useCase = AnalyzeSpeakingSessionUseCase(repository: repository, analyzer: analyzer, storage: storage)
        let completion = SpeakingCallCompletion()
        let session = completionSession()
        var destinations: [UUID] = []
        let caller = Task {
            await completion.run(session, repository: repository, analyzer: useCase) { destinations.append($0) }
        }
        await analyzer.waitUntilStarted()
        let saved = try #require(try await repository.session(id: session.id))
        #expect(saved.status == .pendingAnalysis)
        #expect(saved.turns == session.turns)
        #expect(destinations.isEmpty)
        #expect(completion.phase == .analyzing)
        let content = SpeakingCallViewContent.make(
            phase: .ended(.learnerEnded), elapsed: 90, duration: 360, completionPhase: completion.phase
        )
        #expect(content.showsProgress)
        #expect(content.statusKey == "app.speaking.result.analyzing")
        if exits {
            #expect(completion.exit())
            caller.cancel() // SwiftUI cancels its task when the call view is dismissed.
        }
        await analyzer.finish()
        await caller.value

        #expect(try await repository.session(id: session.id)?.status == .analyzed)
        #expect(try await repository.session(id: session.id)?.analysis != nil)
        #expect(await analyzer.wasCancelled == false)
        #expect(destinations == (exits ? [] : [session.id]))
        #expect(completion.phase == .completed)
        // A later result load is safe and does not overwrite completed analysis.
        await completion.run(session, repository: repository, analyzer: useCase) { destinations.append($0) }
        #expect(await repository.saveCount == 1)
        #expect(destinations == (exits ? [] : [session.id]))
    }

    @Test func failedSaveDoesNotAnalyzeOrNavigateAndCanRetry() async throws {
        let storage = try completionStorage()
        defer { try? FileManager.default.removeItem(at: storage.url(for: "session.m4a").deletingLastPathComponent()) }
        let repository = CompletionRepository(failFirstSave: true)
        let analyzer = SuspendedCompletionAnalyzer()
        let useCase = AnalyzeSpeakingSessionUseCase(repository: repository, analyzer: analyzer, storage: storage)
        let completion = SpeakingCallCompletion()
        let session = completionSession()
        var destinations: [UUID] = []
        await completion.run(session, repository: repository, analyzer: useCase) { destinations.append($0) }

        #expect(completion.phase == .saveFailed)
        #expect(!completion.exit())
        #expect(await analyzer.started == false)
        #expect(destinations.isEmpty)
        let retry = Task {
            await completion.run(session, repository: repository, analyzer: useCase) { destinations.append($0) }
        }
        await analyzer.waitUntilStarted()
        await analyzer.finish()
        await retry.value
        #expect(destinations == [session.id])
        #expect(try await repository.session(id: session.id)?.status == .analyzed)
    }
}

private actor SuspendedCompletionAnalyzer: SpeakingAnalyzing {
    private var continuation: CheckedContinuation<Void, Never>?
    private var startedWaiters: [CheckedContinuation<Void, Never>] = []
    private(set) var started = false
    private(set) var wasCancelled = false

    func analyze(_ session: SpeakingSessionSnapshot, audioURL: URL) async throws -> SpeakingAnalysis {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            started = true
            startedWaiters.forEach { $0.resume() }
            startedWaiters = []
        }
        wasCancelled = Task.isCancelled
        return try JSONDecoder().decode(SpeakingAnalysis.self, from: SpeakingFixtures.data("analysis-valid.json"))
    }

    func waitUntilStarted() async {
        if started { return }
        await withCheckedContinuation { startedWaiters.append($0) }
    }

    func finish() { continuation?.resume(); continuation = nil }
}

private actor CompletionRepository: SpeakingRepositoryProtocol {
    private var saved: SpeakingSessionSnapshot?
    private var failFirstSave: Bool
    private(set) var saveCount = 0

    init(failFirstSave: Bool = false) { self.failFirstSave = failFirstSave }
    func save(_ session: SpeakingSessionSnapshot) async throws {
        if failFirstSave {
            failFirstSave = false
            throw SpeakingAnalysisError.network
        }
        saveCount += 1
        saved = session
    }
    func session(id: UUID) async throws -> SpeakingSessionSnapshot? { saved?.id == id ? saved : nil }
    func sessions(limit: Int?) async throws -> [SpeakingSessionSnapshot] { saved.map { [$0] } ?? [] }
    func updateAnalysis(sessionId: UUID, status: SpeakingSessionStatus, analysis: SpeakingAnalysis?) async throws {
        guard saved?.id == sessionId else { return }
        saved?.status = status
        saved?.analysis = analysis
    }
    func savePhrase(_ phrase: SavedPhrase) async throws -> Bool { false }
    func phrases() async throws -> [SavedPhrase] { [] }
    func deletePhrase(id: UUID) async throws {}
    func detachAudio(keepingLatest count: Int) async throws -> [String] { [] }
}

private func completionSession() -> SpeakingSessionSnapshot {
    SpeakingSessionSnapshot(
        id: UUID(), plan: .fixture(), startedAt: Date(), duration: 90, status: .pendingAnalysis,
        endReason: .learnerEnded, hintCount: 0, audioFileName: "session.m4a",
        turns: (0..<2).map { SpeakingTurn(index: $0, speaker: .learner, text: "A latte please", startOffset: 0, endOffset: 1) },
        analysis: nil
    )
}

private func completionStorage() throws -> SpeakingAudioStorage {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("speaking-completion-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try Data([1]).write(to: directory.appendingPathComponent("session.m4a"))
    return SpeakingAudioStorage(directory: directory)
}
