import Foundation
@testable import VocabCraftApp

actor FakeLiveTransport: LiveTransport {
    private var continuation: AsyncThrowingStream<Data, Error>.Continuation?
    private var connectError: LiveTransportError?
    private var shouldSuspendAudio = false
    private var audioSendContinuation: CheckedContinuation<Void, Error>?
    private(set) var audioSendFinished = false
    private var shouldSuspendWrapUp = false
    private var wrapUpSendContinuation: CheckedContinuation<Void, Never>?
    private var didStartWrapUpSend = false
    private(set) var sent: [LiveClientMessage] = []
    private(set) var connectCount = 0
    private(set) var closeCount = 0

    init(connectError: LiveTransportError? = nil) {
        self.connectError = connectError
    }

    func connect(apiKey: String) async throws -> AsyncThrowingStream<Data, Error> {
        connectCount += 1
        if let connectError {
            self.connectError = nil
            throw connectError
        }
        continuation?.finish()
        let (stream, nextContinuation) = AsyncThrowingStream<Data, Error>.makeStream()
        continuation = nextContinuation
        return stream
    }

    func send(_ message: LiveClientMessage) async throws {
        sent.append(message)
        if case .audio = message, shouldSuspendAudio {
            shouldSuspendAudio = false
            defer { audioSendFinished = true }
            try await withCheckedThrowingContinuation { audioSendContinuation = $0 }
        }
        guard case let .hiddenText(text) = message,
              text == SpeakingPromptBuilder.wrapUpRequest,
              shouldSuspendWrapUp else { return }
        didStartWrapUpSend = true
        await withCheckedContinuation { continuation in
            wrapUpSendContinuation = continuation
        }
    }

    func close() async {
        closeCount += 1
        continuation?.finish()
        continuation = nil
    }

    func emit(_ data: Data) {
        continuation?.yield(data)
    }

    func fail(_ error: Error) {
        continuation?.finish(throwing: error)
        continuation = nil
    }

    func suspendNextAudioSend() { shouldSuspendAudio = true }
    func audioSendStarted() -> Bool { audioSendContinuation != nil }
    func failSuspendedAudioSend(_ error: Error) {
        audioSendContinuation?.resume(throwing: error)
        audioSendContinuation = nil
    }

    func suspendWrapUpSend() {
        shouldSuspendWrapUp = true
    }

    func wrapUpSendStarted() -> Bool {
        didStartWrapUpSend
    }

    func resumeWrapUpSend() {
        shouldSuspendWrapUp = false
        wrapUpSendContinuation?.resume()
        wrapUpSendContinuation = nil
    }
}

struct TestSpeakingInstant: InstantProtocol {
    var offset: Duration

    func advanced(by duration: Duration) -> Self { Self(offset: offset + duration) }
    func duration(to other: Self) -> Duration { other.offset - offset }
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.offset < rhs.offset }
}

final class TestSpeakingClock: Clock, @unchecked Sendable {
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
        let clock = ContinuousClock()
        let waitDeadline = clock.now.advanced(by: .seconds(3))
        while clock.now < waitDeadline {
            if pendingDeadlines.contains(deadline) { return }
            try? await clock.sleep(for: .milliseconds(1))
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
