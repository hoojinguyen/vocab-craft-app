import AVFoundation
import Foundation
import SpeechKit
import Testing
@testable import VocabCraftApp
#if canImport(UIKit)
import UIKit
#endif

@Suite("Speaking call controller")
@MainActor
struct SpeakingCallControllerTests {
    @Test func happyPathProducesPendingSnapshotAndAcknowledgesEndTool() async throws {
        let harness = try Harness()
        await harness.controller.start()
        await harness.emit("setup-complete")
        await waitUntil { harness.controller.phase == .live }

        await harness.emit("output-transcription")
        await harness.emit("turn-complete")
        await harness.emit("input-transcription")
        await harness.emit("output-transcription")
        await harness.emit("turn-complete")
        await harness.emit("input-transcription")
        await harness.emit("tool-call-end-session")
        await waitUntil { harness.controller.result != nil }

        let sent = await harness.transport.sent
        #expect(sent.first == .setup(LiveSetup(
            model: "models/gemini-3.8-live",
            voiceName: "Kore",
            systemInstruction: SpeakingPromptBuilder.systemInstruction(for: .fixture())
        )))
        #expect(sent.contains(.hiddenText(SpeakingPromptBuilder.openingTrigger)))
        #expect(sent.contains(.toolResponse(id: "c1", name: "end_session")))
        #expect(harness.controller.result?.status == .pendingAnalysis)
        #expect(harness.controller.result?.endReason == .aiEnded)
        #expect(harness.controller.result?.learnerTurnCount == 2)
        #expect(harness.audioSession.releasedCount == 1)
    }

    @Test func repeatedInterruptedEventsFlushPlaybackEveryTime() async throws {
        let harness = try Harness()
        await harness.startLive()

        for _ in 0..<3 { await harness.emit("interrupted") }
        await waitUntil { harness.audio.flushCount == 3 }

        #expect(harness.audio.flushCount == 3)
        await harness.controller.end()
    }

    @Test func clockSendsWrapUpAt330AndEndsAt390Seconds() async throws {
        let clock = TestSpeakingClock()
        let harness = try Harness(clock: clock)
        await harness.startLive()
        await clock.waitForSleeper(at: .seconds(1))

        clock.advance(by: .seconds(330))
        await waitUntil { harness.controller.elapsed >= 330 }
        await waitUntil { await harness.transport.sent.contains(.hiddenText(SpeakingPromptBuilder.wrapUpRequest)) }
        let sentAtWrapUp = await harness.transport.sent
        #expect(sentAtWrapUp.contains(.hiddenText(SpeakingPromptBuilder.wrapUpRequest)))
        #expect(harness.controller.result == nil)

        clock.advance(by: .seconds(60))
        await waitUntil { harness.controller.result?.endReason == .timeLimit }
        #expect(harness.controller.elapsed == 390)
    }

    @Test func unauthorizedOnConnectFailsWithoutSnapshotAndReleasesLeaseOnce() async throws {
        let harness = try Harness(connectError: LiveTransportError.unauthorized)
        await harness.controller.start()

        #expect(harness.controller.phase == .failed(.unauthorized))
        #expect(harness.controller.result == nil)
        #expect(harness.audioSession.acquiredIntents == [.duplexSpeech])
        #expect(harness.audioSession.releasedCount == 1)
    }

    @Test func interruptionWhileConnectingCleansUpWithoutSnapshot() async throws {
        let harness = try Harness()
        await harness.controller.start()
        harness.audioSession.emit(.interruptionBegan)
        await waitUntil { harness.controller.phase == .ended(.interrupted) }
        await waitUntil {
            let closeCount = await harness.transport.closeCount
            return harness.audioSession.releasedCount == 1 && closeCount == 1
        }

        #expect(harness.controller.result == nil)
        #expect(harness.audio.stopCount == 1)
    }

    #if canImport(UIKit)
    @Test func backgroundEntryEndsLiveCall() async throws {
        let harness = try Harness()
        await harness.startLive()

        harness.notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        await waitUntil { harness.controller.result != nil }

        #expect(harness.controller.result?.endReason == .interrupted)
        #expect(harness.audioSession.releasedCount == 1)
    }

    @Test func backgroundEntryNotificationDoesNotEndOtherController() async throws {
        let postingHarness = try Harness()
        let otherHarness = try Harness()
        await postingHarness.startLive()
        await otherHarness.startLive()

        postingHarness.notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        await waitUntil { postingHarness.controller.result != nil }
        try await ContinuousClock().sleep(for: .milliseconds(50))

        #expect(postingHarness.controller.result?.endReason == .interrupted)
        #expect(otherHarness.controller.result == nil)
        await otherHarness.controller.end()
    }
    #endif

    @Test func hintSendsHiddenTextAndIncrementsCountOnlyWhileLive() async throws {
        let harness = try Harness()
        await harness.controller.requestHint()
        #expect(harness.controller.hintCount == 0)

        await harness.startLive()
        await harness.controller.requestHint()

        #expect(harness.controller.hintCount == 1)
        #expect(await harness.transport.sent.contains(.hiddenText(SpeakingPromptBuilder.hintRequest)))
        await harness.controller.end()
    }

    @Test func audioInterruptionFinalizesPartialTurnsOnce() async throws {
        let harness = try Harness()
        await harness.startLive()
        await harness.emit("input-transcription")
        await waitUntil { !harness.controller.turns.isEmpty }
        harness.audioSession.emit(.interruptionBegan)
        await waitUntil { harness.controller.result != nil }

        #expect(harness.controller.result?.endReason == .interrupted)
        #expect(harness.controller.result?.turns.isEmpty == false)
        #expect(harness.audioSession.releasedCount == 1)
        harness.audioSession.emit(.interruptionBegan)
        #expect(harness.audioSession.releasedCount == 1)
    }

    @Test func setupTimeoutCleansUpWithoutSnapshot() async throws {
        let clock = TestSpeakingClock()
        let harness = try Harness(clock: clock)
        await harness.controller.start()
        await clock.waitForSleeper(at: .seconds(10))

        clock.advance(by: .seconds(10))
        await waitUntil { harness.controller.phase == .failed(.network) }
        await waitUntil {
            let closeCount = await harness.transport.closeCount
            return harness.audioSession.releasedCount == 1 && closeCount == 1
        }

        #expect(harness.controller.result == nil)
        #expect(harness.audio.stopCount == 1)
        let closeCount = await harness.transport.closeCount
        #expect(closeCount == 1)
        #expect(harness.audioSession.releasedCount == 1)
    }

    @Test func cancellationWhileConnectingReleasesLeaseExactlyOnce() async throws {
        let harness = try Harness()
        await harness.controller.start()
        await harness.controller.end()

        #expect(harness.controller.phase == .ended(.learnerEnded))
        #expect(harness.controller.result == nil)
        #expect(harness.audio.stopCount == 1)
        #expect(await harness.transport.closeCount == 1)
        #expect(harness.audioSession.releasedCount == 1)
    }

    @Test func fatalQuotaWhileLiveSavesPartialSessionWithoutReconnect() async throws {
        let harness = try Harness()
        await harness.startLive()
        await harness.emit("input-transcription")
        await harness.transport.fail(LiveTransportError.quotaExceeded)
        await waitUntil { harness.controller.result != nil }

        #expect(harness.controller.phase == .failed(.quotaExceeded))
        #expect(harness.controller.result?.endReason == .connectionLost)
        #expect(harness.controller.result?.turns.isEmpty == false)
        #expect(await harness.transport.connectCount == 1)
        #expect(harness.audioSession.releasedCount == 1)
    }

    @Test func goAwayResumesWithHandleWithoutRestartingAudio() async throws {
        let harness = try Harness()
        await harness.startLive()
        await harness.emit("session-resumption-update")
        await harness.emit("go-away")
        await waitUntil { await harness.transport.connectCount == 2 }
        await harness.emit("setup-complete")
        await waitUntil { harness.controller.phase == .live }

        let setupMessages = await harness.transport.sent.compactMap { message -> LiveSetup? in
            guard case let .setup(setup) = message else { return nil }
            return setup
        }
        #expect(setupMessages.count == 2)
        #expect(setupMessages.last?.resumptionHandle == "resume-2")
        #expect(harness.audio.startCount == 1)
        await harness.controller.end()
    }

    @Test func fatalQuotaDuringReconnectFinalizesWithoutAnotherConnection() async throws {
        let harness = try Harness()
        await harness.startLive()
        await harness.emit("session-resumption-update")
        await harness.emit("go-away")
        await waitUntil { await harness.transport.connectCount == 2 }
        await harness.transport.fail(LiveTransportError.quotaExceeded)
        await waitUntil { harness.controller.result != nil }

        #expect(harness.controller.phase == .failed(.quotaExceeded))
        #expect(harness.controller.result?.endReason == .connectionLost)
        let connectCount = await harness.transport.connectCount
        #expect(connectCount == 2)
        #expect(harness.audioSession.releasedCount == 1)
    }

    @Test func secondNetworkDropAfterResumeDoesNotOpenThirdSocket() async throws {
        let harness = try Harness()
        await harness.startLive()
        await harness.emit("session-resumption-update")
        await harness.transport.fail(LiveTransportError.network)
        await waitUntil { harness.controller.phase == .reconnecting }
        await waitUntil { await harness.transport.connectCount == 2 }
        await harness.emit("setup-complete")
        await waitUntil { harness.controller.phase == .live }
        await harness.transport.fail(LiveTransportError.network)
        await waitUntil { harness.controller.result != nil }

        #expect(harness.controller.result?.endReason == .connectionLost)
        let connectCount = await harness.transport.connectCount
        #expect(connectCount == 2)
        #expect(harness.audioSession.releasedCount == 1)
    }

    @Test func reconnectInterruptionFinalizesOnceAndReleasesLease() async throws {
        let harness = try Harness()
        await harness.startLive()
        await harness.emit("session-resumption-update")
        await harness.transport.fail(LiveTransportError.network)
        await waitUntil { harness.controller.phase == .reconnecting }
        harness.audioSession.emit(.interruptionBegan)
        await waitUntil { harness.controller.result != nil }

        #expect(harness.controller.result?.endReason == .interrupted)
        #expect(harness.audioSession.releasedCount == 1)
        #expect(harness.audio.stopCount == 1)
    }

    @Test func nonresumableUpdateClearsHandleBeforeGoAway() async throws {
        let harness = try Harness()
        await harness.startLive()
        await harness.emit("session-resumption-update")
        await harness.transport.emit(Data(#"{"sessionResumptionUpdate":{"resumable":false}}"#.utf8))
        await harness.emit("go-away")
        await waitUntil { harness.controller.result != nil }

        #expect(harness.controller.result?.endReason == .connectionLost)
        let connectCount = await harness.transport.connectCount
        #expect(connectCount == 1)
    }

    @Test func reconnectTimeoutFinalizesPartialSession() async throws {
        let clock = TestSpeakingClock()
        let harness = try Harness(clock: clock)
        await harness.startLive()
        await harness.emit("session-resumption-update")
        await harness.transport.fail(LiveTransportError.network)
        await waitUntil { harness.controller.phase == .reconnecting }
        await clock.waitForSleeper(at: .seconds(8))

        clock.advance(by: .seconds(8))
        await waitUntil { harness.controller.result != nil }

        #expect(harness.controller.result?.endReason == .connectionLost)
        #expect(harness.controller.result?.status == .pendingAnalysis)
    }

    @Test func staleCaptureCallbackIsIgnoredDuringReconnect() async throws {
        let harness = try Harness()
        await harness.startLive()
        let firstPacket = Data(repeating: 0x20, count: 3_200)
        harness.audio.emitCapture(firstPacket)
        await waitUntil { abs(harness.recorder.elapsed - 0.1) < 0.001 }
        await harness.emit("session-resumption-update")
        await harness.transport.fail(LiveTransportError.network)
        await waitUntil { harness.controller.phase == .reconnecting }

        harness.audio.emitStaleCapture(Data(repeating: 0, count: 3_200))

        #expect(abs(harness.recorder.elapsed - 0.1) < 0.001)
        await harness.controller.end()
    }

    @Test func microphonePacketsAreSentAndRecordedWithoutOneTaskPerPacket() async throws {
        let harness = try Harness()
        await harness.startLive()
        let packet = Data(repeating: 0x20, count: 3_200)
        harness.audio.emitCapture(packet)
        await waitUntil { await harness.transport.sent.contains(.audio(packet)) }

        #expect(abs(harness.recorder.elapsed - 0.1) < 0.001)
        #expect(await harness.transport.sent.contains(.audio(packet)))
        await harness.controller.end()
    }

    @Test func captureOverflowFinalizesInsteadOfSilentlyLosingLearnerAudio() async throws {
        let clock = TestSpeakingClock()
        let harness = try Harness(clock: clock)
        await harness.startLive()
        await clock.waitForSleeper(at: .seconds(1))
        harness.audio.incrementCaptureOverflow()
        clock.advance(by: .seconds(1))
        await waitUntil { harness.controller.result != nil }

        #expect(harness.controller.result?.endReason == .interrupted)
        #expect(harness.controller.phase == .failed(.microphoneDenied))
    }

    @Test func captureOverflowIsStillSurfacedWhenLearnerEndsBeforeTimerTick() async throws {
        let harness = try Harness()
        await harness.startLive()
        harness.audio.incrementCaptureOverflow()

        await harness.controller.end()

        #expect(harness.controller.phase == .failed(.microphoneDenied))
        #expect(harness.controller.result?.endReason == .interrupted)
    }

    @Test func routeChangesRestartAudioAndRouteFailureFinalizes() async throws {
        let harness = try Harness()
        await harness.startLive()
        harness.audioSession.emit(.routeChanged(reason: .oldDeviceUnavailable))
        await waitUntil { harness.audio.routeRestartCount == 1 }
        harness.audio.routeRestartError = SpeakingAudioIOError.invalidInputFormat
        harness.audioSession.emit(.routeChanged(reason: .newDeviceAvailable))
        await waitUntil { harness.controller.result != nil }

        #expect(harness.controller.result?.endReason == .interrupted)
        #expect(harness.audio.routeRestartCount == 1)
    }

    @Test func endToolWaitsForGoodbyePlaybackButIsBounded() async throws {
        let clock = TestSpeakingClock()
        let harness = try Harness(clock: clock)
        await harness.startLive()
        await harness.emit("audio-chunk")
        await harness.emit("tool-call-end-session")
        await waitUntil { await harness.transport.sent.contains(.toolResponse(id: "c1", name: "end_session")) }
        #expect(harness.controller.result == nil)

        harness.audio.setPlaying(false)
        await clock.waitForSleeper(at: .milliseconds(50))
        clock.advance(by: .milliseconds(50))
        await waitUntil { harness.controller.result != nil }
        #expect(harness.controller.result?.endReason == .aiEnded)
    }

    @Test func goodbyeDrainTimesOutAtTwoSeconds() async throws {
        let clock = TestSpeakingClock()
        let harness = try Harness(clock: clock)
        await harness.startLive()
        await harness.emit("audio-chunk")
        await harness.emit("tool-call-end-session")
        await waitUntil { await harness.transport.sent.contains(.toolResponse(id: "c1", name: "end_session")) }
        await clock.waitForSleeper(at: .milliseconds(50))

        clock.advance(by: .seconds(2))
        await waitUntil { harness.controller.result != nil }

        #expect(harness.controller.result?.endReason == .aiEnded)
    }

    @Test func learnerEndCancelsPendingGoodbyeDrain() async throws {
        let clock = TestSpeakingClock()
        let harness = try Harness(clock: clock)
        await harness.startLive()
        await harness.emit("audio-chunk")
        await harness.emit("tool-call-end-session")
        await waitUntil { await harness.transport.sent.contains(.toolResponse(id: "c1", name: "end_session")) }

        await harness.controller.end()

        #expect(harness.controller.result?.endReason == .learnerEnded)
    }

    private func waitUntil(
        timeout: Int = 2,
        _ predicate: @MainActor () async -> Bool
    ) async {
        for _ in 0..<(timeout * 1_000) {
            if await predicate() { return }
            try? await ContinuousClock().sleep(for: .milliseconds(1))
        }
    }
}

@MainActor
private struct Harness {
    let transport: FakeLiveTransport
    let audio: FakeSpeakingAudioIO
    let audioSession: FakeAudioSessionCoordinator
    let recorder: LearnerRecorder
    let notificationCenter: NotificationCenter
    let controller: SpeakingCallController

    init(clock: TestSpeakingClock = TestSpeakingClock(), connectError: LiveTransportError? = nil) throws {
        transport = FakeLiveTransport(connectError: connectError)
        audio = FakeSpeakingAudioIO()
        audioSession = FakeAudioSessionCoordinator()
        recorder = LearnerRecorder(storage: try Self.temporaryStorage())
        notificationCenter = NotificationCenter()
        controller = SpeakingCallController(
            plan: .fixture(), apiKey: "test-key", transport: transport, audio: audio,
            recorder: recorder, audioSession: audioSession, clock: clock,
            notificationCenter: notificationCenter, now: { Date(timeIntervalSince1970: 1_800_000_000) }
        )
    }

    func startLive() async {
        await controller.start()
        await emit("setup-complete")
        await waitUntil { controller.phase == .live }
    }

    func emit(_ fixture: String) async {
        if let data = try? SpeakingFixtures.data(fixture + ".json", subdirectory: "Fixtures/live") {
            await transport.emit(data)
        }
    }

    private func waitUntil(_ predicate: @MainActor () async -> Bool) async {
        for _ in 0..<2_000 {
            if await predicate() { return }
            try? await ContinuousClock().sleep(for: .milliseconds(1))
        }
    }

    private static func temporaryStorage() throws -> SpeakingAudioStorage {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("speaking-controller-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return SpeakingAudioStorage(directory: directory)
    }
}

private final class FakeAudioSessionCoordinator: AudioSessionCoordinating, @unchecked Sendable {
    private let lock = NSLock()
    private let continuation: AsyncStream<AudioSessionEvent>.Continuation
    private let stream: AsyncStream<AudioSessionEvent>
    private var intents: [AudioSessionIntent] = []
    private var releases: [AudioSessionLease] = []

    init() {
        (stream, continuation) = AsyncStream.makeStream()
    }

    var events: AsyncStream<AudioSessionEvent> { stream }
    var acquiredIntents: [AudioSessionIntent] { lock.withLock { intents } }
    var releasedCount: Int { lock.withLock { releases.count } }

    func acquire(_ intent: AudioSessionIntent) async throws -> AudioSessionLease {
        let lease = AudioSessionLease(generation: UInt(acquiredIntents.count + 1), intent: intent)
        lock.withLock { intents.append(intent) }
        return lease
    }

    func release(_ lease: AudioSessionLease) async {
        lock.withLock { releases.append(lease) }
    }

    func emit(_ event: AudioSessionEvent) {
        continuation.yield(event)
    }
}

private struct TestSpeakingInstant: InstantProtocol {
    var offset: Duration

    func advanced(by duration: Duration) -> Self { Self(offset: offset + duration) }
    func duration(to other: Self) -> Duration { other.offset - offset }
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.offset < rhs.offset }
}

private final class TestSpeakingClock: Clock, @unchecked Sendable {
    typealias Instant = TestSpeakingInstant
    private struct Sleeper {
        let deadline: Instant
        let continuation: CheckedContinuation<Void, any Error>
    }

    private let lock = NSLock()
    private var instant = Instant(offset: .zero)
    private var sleepers: [UUID: Sleeper] = [:]
    private var cancelled = Set<UUID>()

    var now: Instant { lock.withLock { instant } }
    var minimumResolution: Duration { .milliseconds(1) }
    var pendingSleeperCount: Int { lock.withLock { sleepers.count } }

    func sleep(until deadline: Instant, tolerance: Duration?) async throws {
        try Task.checkCancellation()
        let id = UUID()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let state = lock.withLock { () -> Int in
                    if cancelled.remove(id) != nil { return 2 }
                    guard instant < deadline else { return 1 }
                    sleepers[id] = Sleeper(deadline: deadline, continuation: continuation)
                    return 0
                }
                if state == 1 { continuation.resume() }
                if state == 2 { continuation.resume(throwing: CancellationError()) }
            }
        } onCancel: {
            cancel(id)
        }
    }

    func advance(by duration: Duration) {
        let ready = lock.withLock { () -> [CheckedContinuation<Void, any Error>] in
            instant = instant.advanced(by: duration)
            let due = sleepers.filter { $0.value.deadline <= instant }
            due.keys.forEach { sleepers.removeValue(forKey: $0) }
            return due.values.map(\.continuation)
        }
        ready.forEach { $0.resume() }
    }

    func waitForSleeper(at deadline: Duration) async {
        for _ in 0..<2_000 {
            if pendingDeadlines.contains(deadline) { return }
            await Task.yield()
        }
    }

    private var pendingDeadlines: [Duration] {
        lock.withLock { sleepers.values.map(\.deadline.offset) }
    }

    private func cancel(_ id: UUID) {
        let continuation = lock.withLock { () -> CheckedContinuation<Void, any Error>? in
            guard let sleeper = sleepers.removeValue(forKey: id) else {
                cancelled.insert(id)
                return nil
            }
            return sleeper.continuation
        }
        continuation?.resume(throwing: CancellationError())
    }
}
