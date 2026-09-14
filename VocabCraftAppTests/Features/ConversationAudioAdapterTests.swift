import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Conversation audio adapter")
@MainActor
struct ConversationAudioAdapterTests {
    @Test("permission denial returns an actionable result without acquiring capture audio")
    func permissionDeniedDoesNotAcquireAudio() async {
        let recognizer = TestConversationRecognizer(isAuthorized: false)
        let coordinator = TestConversationAudioCoordinator()
        let adapter = makeAdapter(recognizer: recognizer, coordinator: coordinator)

        let result = await adapter.capture(
            targetSentence: "What is our next milestone?",
            contextualPhrases: ["What is our next milestone?", "milestone"],
            onListening: {},
            onPartial: { _ in }
        )

        #expect(result == .permissionDenied)
        #expect(await coordinator.acquiredIntentsSnapshot().isEmpty)
        #expect(recognizer.startCount == 0)
    }

    @Test("partial recognition updates display but cannot complete capture")
    func partialDoesNotCompleteCapture() async {
        let recognizer = TestConversationRecognizer()
        let coordinator = TestConversationAudioCoordinator()
        let sleeper = TestConversationSleeper()
        let adapter = makeAdapter(recognizer: recognizer, coordinator: coordinator, sleeper: sleeper)
        var partials: [String] = []

        let task = Task {
            await adapter.capture(
                targetSentence: "What is our next milestone?",
                contextualPhrases: ["What is our next milestone?", "milestone"],
                onListening: {},
                onPartial: { partials.append($0) }
            )
        }
        await recognizer.waitUntilStarted()
        recognizer.sendPartial("What is our next")
        await Task.yield()

        #expect(partials == ["What is our next"])
        #expect(!task.isCancelled)
        #expect(recognizer.isRunning)

        recognizer.sendFinal("What is our next milestone")
        let result = await task.value
        #expect(result == .transcript("What is our next milestone"))
        #expect(await coordinator.releasedLeaseCount() == 1)
    }

    @Test("cancellation while capture is active stops recognition and releases its lease before returning")
    func cancellationStopsAndReleases() async {
        let recognizer = TestConversationRecognizer()
        let coordinator = TestConversationAudioCoordinator()
        let adapter = makeAdapter(recognizer: recognizer, coordinator: coordinator)

        let task = Task {
            let result = await adapter.capture(
                targetSentence: "What is our next milestone?",
                contextualPhrases: ["What is our next milestone?"],
                onListening: {},
                onPartial: { _ in }
            )
            await coordinator.recordEvent("caller-after-capture")
            return result
        }
        await recognizer.waitUntilStarted()
        task.cancel()
        let result = await task.value

        #expect(result == .cancelled)
        #expect(recognizer.stopCount == 1)
        #expect(await coordinator.releasedLeaseCount() == 1)
        let events = await coordinator.eventsSnapshot()
        #expect(events == ["acquire", "release", "caller-after-capture"])
    }

    @Test("invoking play while capture is active cancels capture and stops recognition")
    func playCancelsActiveCapture() async {
        let recognizer = TestConversationRecognizer()
        let coordinator = TestConversationAudioCoordinator()
        let adapter = makeAdapter(recognizer: recognizer, coordinator: coordinator)

        let captureTask = Task {
            await adapter.capture(
                targetSentence: "What is our next milestone?",
                contextualPhrases: ["What is our next milestone?"],
                onListening: {},
                onPartial: { _ in }
            )
        }
        await recognizer.waitUntilStarted()

        let playResult = await adapter.play(text: "Hello from partner")

        #expect(playResult == .finished)
        #expect(await captureTask.value == .cancelled)
        #expect(recognizer.stopCount == 1)
        #expect(!recognizer.isRunning)
        #expect(await coordinator.releasedLeaseCount() == 1)
    }

    @Test("stop while authorization is pending prevents a late capture")
    func stopWhileAuthorizationIsPending() async {
        let recognizer = TestConversationRecognizer(suspendsAuthorization: true)
        let coordinator = TestConversationAudioCoordinator()
        let adapter = makeAdapter(
            recognizer: recognizer,
            coordinator: coordinator,
            sleeper: TestConversationSleeper(immediateDurations: [.seconds(4)])
        )
        let task = Task {
            await adapter.capture(
                targetSentence: "What is our next milestone?",
                contextualPhrases: ["What is our next milestone?"],
                onListening: {},
                onPartial: { _ in }
            )
        }
        await recognizer.waitUntilAuthorizationRequested()

        adapter.stop()
        recognizer.resumeAuthorization(isAuthorized: true)

        #expect(await task.value == .cancelled)
        #expect(await coordinator.acquiredIntentsSnapshot().isEmpty)
        #expect(recognizer.startCount == 0)
    }

    @Test("stop while capture lease is pending releases the late lease without starting")
    func stopWhileCaptureLeaseIsPending() async {
        let recognizer = TestConversationRecognizer()
        let coordinator = TestConversationAudioCoordinator(suspendsAcquire: true)
        let adapter = makeAdapter(
            recognizer: recognizer,
            coordinator: coordinator,
            sleeper: TestConversationSleeper(immediateDurations: [.seconds(4)])
        )
        let task = Task {
            await adapter.capture(
                targetSentence: "What is our next milestone?",
                contextualPhrases: ["What is our next milestone?"],
                onListening: {},
                onPartial: { _ in }
            )
        }
        await coordinator.waitUntilAcquireRequested()

        adapter.stop()
        await coordinator.resumeAcquire()

        #expect(await task.value == .cancelled)
        #expect(await coordinator.releasedLeaseCount() == 1)
        #expect(recognizer.startCount == 0)
    }

    @Test("initial silence ends capture only after capture starts")
    func initialSilenceEndsCapture() async {
        let recognizer = TestConversationRecognizer()
        let sleeper = TestConversationSleeper(immediateDurations: [.seconds(4)])
        let adapter = makeAdapter(recognizer: recognizer, sleeper: sleeper)

        let result = await adapter.capture(
            targetSentence: "What is our next milestone?",
            contextualPhrases: ["What is our next milestone?"],
            onListening: {},
            onPartial: { _ in }
        )

        #expect(result == .silence)
        #expect(recognizer.startCount == 1)
    }

    @Test("trailing inactivity returns the latest non-final transcript")
    func trailingInactivityCompletesUtterance() async {
        let recognizer = TestConversationRecognizer()
        let sleeper = TestConversationSleeper(immediateDurations: [.milliseconds(1_500)])
        let adapter = makeAdapter(recognizer: recognizer, sleeper: sleeper)
        let task = Task {
            await adapter.capture(
                targetSentence: "What is our next milestone?",
                contextualPhrases: ["What is our next milestone?"],
                onListening: {},
                onPartial: { _ in }
            )
        }
        await recognizer.waitUntilStarted()
        recognizer.sendPartial("What is our next milestone")

        #expect(await task.value == .transcript("What is our next milestone"))
    }

    @Test("maximum duration returns silence when no transcript exists")
    func maximumDurationBoundsCapture() async {
        let recognizer = TestConversationRecognizer()
        let sleeper = TestConversationSleeper(immediateDurations: [.seconds(20)])
        let adapter = makeAdapter(recognizer: recognizer, sleeper: sleeper)

        let result = await adapter.capture(
            targetSentence: "What is our next milestone?",
            contextualPhrases: ["What is our next milestone?"],
            onListening: {},
            onPartial: { _ in }
        )

        #expect(result == .silence)
        #expect(recognizer.stopCount == 1)
    }

    @Test("capture stops player and awaits teardown before acquiring lease")
    func captureStopsPlayerAndAwaitsTeardownBeforeAcquire() async {
        let player = TestConversationPlayer()
        let recognizer = TestConversationRecognizer()
        let coordinator = TestConversationAudioCoordinator()
        let adapter = ConversationAudioAdapter(
            player: player,
            recognizer: recognizer,
            audioSessionCoordinator: coordinator,
            sleeper: TestConversationSleeper(immediateDurations: [.seconds(4)]),
            capturePolicy: .init(initialSilence: .seconds(4), trailingInactivity: .seconds(1), maximumDuration: .seconds(5))
        )

        let result = await adapter.capture(
            targetSentence: "What is our next milestone?",
            contextualPhrases: ["What is our next milestone?"],
            onListening: {},
            onPartial: { _ in }
        )

        #expect(result == .silence)
        #expect(player.stopCount == 1)
        #expect(player.teardownCount == 1)
        let coordinatorFirstEvent = await coordinator.eventsSnapshot().first
        #expect(coordinatorFirstEvent == "acquire")
        #expect(player.events == ["stop", "teardown"])
    }

    @Test("stop while player teardown is suspended prevents lease acquisition")
    func stopWhilePlayerTeardownIsSuspendedPreventsAcquire() async {
        let player = TestConversationPlayer(suspendsTeardown: true)
        let recognizer = TestConversationRecognizer()
        let coordinator = TestConversationAudioCoordinator()
        let adapter = ConversationAudioAdapter(
            player: player,
            recognizer: recognizer,
            audioSessionCoordinator: coordinator,
            sleeper: TestConversationSleeper()
        )

        let task = Task {
            await adapter.capture(
                targetSentence: "What is our next milestone?",
                contextualPhrases: ["What is our next milestone?"],
                onListening: {},
                onPartial: { _ in }
            )
        }

        let didRequest = await player.waitUntilTeardownRequested(timeoutNanoseconds: 500_000_000)
        #expect(didRequest, "Player teardown should have been requested before acquire")
        adapter.stop()
        if didRequest {
            player.resumeTeardown()
        }

        #expect(await task.value == .cancelled)
        #expect(await coordinator.acquiredIntentsSnapshot().isEmpty)
        #expect(recognizer.startCount == 0)
    }

    @Test("unchanging transcripts do not reset trailing inactivity timer")
    func unchangingTranscriptsDoNotResetTrailingTimer() async {
        let recognizer = TestConversationRecognizer()
        let sleeper = TestConversationSleeper()
        let adapter = makeAdapter(recognizer: recognizer, sleeper: sleeper)
        let task = Task {
            await adapter.capture(
                targetSentence: "What is our next milestone?",
                contextualPhrases: ["What is our next milestone?"],
                onListening: {},
                onPartial: { _ in }
            )
        }
        await recognizer.waitUntilStarted()

        // First partial triggers trailing timer
        recognizer.sendPartial("What is")
        await sleeper.waitUntilSleeping(for: .milliseconds(1_500))
        #expect(await sleeper.sleepCount(for: .milliseconds(1_500)) == 1)

        // Sending identical partial MUST NOT schedule another trailing timer
        recognizer.sendPartial("What is")
        await Task.yield()
        #expect(await sleeper.sleepCount(for: .milliseconds(1_500)) == 1)

        // Sending changed partial schedules a new trailing timer
        recognizer.sendPartial("What is our next")
        await Task.yield()
        #expect(await sleeper.sleepCount(for: .milliseconds(1_500)) == 2)

        task.cancel()
        _ = await task.value
    }

    @Test("empty partial does not cancel initial silence")
    func emptyPartialDoesNotCancelInitialSilence() async {
        let recognizer = TestConversationRecognizer()
        let sleeper = TestConversationSleeper()
        let adapter = makeAdapter(recognizer: recognizer, sleeper: sleeper)
        let task = Task {
            await adapter.capture(
                targetSentence: "What is our next milestone?",
                contextualPhrases: ["What is our next milestone?"],
                onListening: {},
                onPartial: { _ in }
            )
        }
        await recognizer.waitUntilStarted()
        await sleeper.waitUntilSleeping(for: .seconds(4))

        // Send empty partials
        recognizer.sendPartial("")
        recognizer.sendPartial("   \n\t")
        await Task.yield()

        // Initial silence timer must still be intact (1 waiter for 4s)
        let waiterCount = await sleeper.waiterCount(for: .seconds(4))
        #expect(waiterCount == 1)
        if waiterCount == 1 {
            // Advance initial silence timer
            await sleeper.advance(duration: .seconds(4))
            let result = await task.value
            #expect(result == .silence)
        } else {
            task.cancel()
            _ = await task.value
        }
    }

    @Test("stale callbacks from old attempts do not affect new attempt")
    func staleCallbacksFromOldAttemptDoNotAffectNewAttempt() async {
        let recognizer = TestConversationRecognizer()
        let coordinator = TestConversationAudioCoordinator()
        let sleeper = TestConversationSleeper()
        let adapter = makeAdapter(recognizer: recognizer, coordinator: coordinator, sleeper: sleeper)

        // First attempt
        let task1 = Task {
            await adapter.capture(
                targetSentence: "First sentence",
                contextualPhrases: ["First"],
                onListening: {},
                onPartial: { _ in }
            )
        }
        await recognizer.waitUntilStarted()
        adapter.stop()
        #expect(await task1.value == .cancelled)

        // Second attempt
        var secondPartials: [String] = []
        let task2 = Task {
            await adapter.capture(
                targetSentence: "Second sentence",
                contextualPhrases: ["Second"],
                onListening: {},
                onPartial: { secondPartials.append($0) }
            )
        }
        await recognizer.waitUntilStarted()
        #expect(recognizer.startCount == 2)

        // Stale callbacks from attempt 0
        recognizer.sendPartial("stale partial", attemptIndex: 0)
        recognizer.sendFinal("stale final", attemptIndex: 0)
        recognizer.sendError(.failed, attemptIndex: 0)
        await Task.yield()

        // Second attempt was unaffected
        #expect(secondPartials.isEmpty)
        #expect(!task2.isCancelled)

        // Complete attempt 1 properly
        recognizer.sendFinal("Second sentence valid", attemptIndex: 1)
        let result = await task2.value
        #expect(result == .transcript("Second sentence valid"))
        #expect(await coordinator.releasedLeaseCount() == 2)
    }

    @Test("duplicated final results are ignored and release lease once")
    func duplicatedFinalResultsAreIgnored() async {
        let recognizer = TestConversationRecognizer()
        let coordinator = TestConversationAudioCoordinator()
        let adapter = makeAdapter(recognizer: recognizer, coordinator: coordinator)

        let task = Task {
            await adapter.capture(
                targetSentence: "What is our next milestone?",
                contextualPhrases: ["What is our next milestone?"],
                onListening: {},
                onPartial: { _ in }
            )
        }
        await recognizer.waitUntilStarted()

        recognizer.sendFinal("What is our next milestone")
        recognizer.sendFinal("Duplicate final")
        let result = await task.value

        #expect(result == .transcript("What is our next milestone"))
        #expect(await coordinator.releasedLeaseCount() == 1)
    }

    @Test("final following error is ignored")
    func finalFollowingErrorIsIgnored() async {
        let recognizer = TestConversationRecognizer()
        let coordinator = TestConversationAudioCoordinator()
        let adapter = makeAdapter(recognizer: recognizer, coordinator: coordinator)

        let task = Task {
            await adapter.capture(
                targetSentence: "What is our next milestone?",
                contextualPhrases: ["What is our next milestone?"],
                onListening: {},
                onPartial: { _ in }
            )
        }
        await recognizer.waitUntilStarted()

        recognizer.sendError(.failed)
        recognizer.sendFinal("Late final")
        let result = await task.value

        #expect(result == .failed)
        #expect(await coordinator.releasedLeaseCount() == 1)
    }

    @Test("error following final is ignored")
    func errorFollowingFinalIsIgnored() async {
        let recognizer = TestConversationRecognizer()
        let coordinator = TestConversationAudioCoordinator()
        let adapter = makeAdapter(recognizer: recognizer, coordinator: coordinator)

        let task = Task {
            await adapter.capture(
                targetSentence: "What is our next milestone?",
                contextualPhrases: ["What is our next milestone?"],
                onListening: {},
                onPartial: { _ in }
            )
        }
        await recognizer.waitUntilStarted()

        recognizer.sendFinal("Milestone complete")
        recognizer.sendError(.failed)
        let result = await task.value

        #expect(result == .transcript("Milestone complete"))
        #expect(await coordinator.releasedLeaseCount() == 1)
    }

    private func makeAdapter(
        player: TestConversationPlayer = TestConversationPlayer(),
        recognizer: TestConversationRecognizer = TestConversationRecognizer(),
        coordinator: TestConversationAudioCoordinator = TestConversationAudioCoordinator(),
        sleeper: TestConversationSleeper = TestConversationSleeper()
    ) -> ConversationAudioAdapter {
        ConversationAudioAdapter(
            player: player,
            recognizer: recognizer,
            audioSessionCoordinator: coordinator,
            sleeper: sleeper,
            capturePolicy: .init(
                initialSilence: .seconds(4),
                trailingInactivity: .milliseconds(1_500),
                maximumDuration: .seconds(20)
            )
        )
    }
}

@MainActor
private final class TestConversationPlayer: ConversationSpeechPlaying {
    let suspendsTeardown: Bool
    private(set) var playCount = 0
    private(set) var stopCount = 0
    private(set) var teardownCount = 0
    private(set) var events: [String] = []
    private var teardownContinuation: CheckedContinuation<Void, Never>?
    private(set) var didRequestTeardown = false

    init(suspendsTeardown: Bool = false) {
        self.suspendsTeardown = suspendsTeardown
    }

    func play(text: String, locale: String) async -> ConversationPlaybackResult {
        playCount += 1
        events.append("play")
        return .finished
    }

    func stop() {
        stopCount += 1
        events.append("stop")
    }

    func teardown() async {
        didRequestTeardown = true
        teardownCount += 1
        events.append("teardown")
        if suspendsTeardown {
            await withCheckedContinuation { teardownContinuation = $0 }
        }
    }

    @discardableResult
    func waitUntilTeardownRequested(timeoutNanoseconds: UInt64 = 1_000_000_000) async -> Bool {
        let start = DispatchTime.now().uptimeNanoseconds
        while !didRequestTeardown {
            if DispatchTime.now().uptimeNanoseconds - start > timeoutNanoseconds { return false }
            await Task.yield()
        }
        return true
    }

    func resumeTeardown() {
        teardownContinuation?.resume()
        teardownContinuation = nil
    }
}

@MainActor
private final class TestConversationRecognizer: ConversationSpeechRecognizing {
    struct Attempt {
        let contextualPhrases: [String]
        let onPartial: @MainActor @Sendable (String) -> Void
        let onFinal: @MainActor @Sendable (String) -> Void
        let onError: @MainActor @Sendable (ConversationRecognitionError) -> Void
    }

    var isAuthorized: Bool
    let suspendsAuthorization: Bool
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var isRunning = false
    private(set) var attempts: [Attempt] = []
    private var authorizationContinuation: CheckedContinuation<Bool, Never>?
    private(set) var didRequestAuthorization = false

    init(isAuthorized: Bool = true, suspendsAuthorization: Bool = false) {
        self.isAuthorized = isAuthorized
        self.suspendsAuthorization = suspendsAuthorization
    }

    func requestAuthorization() async -> Bool {
        didRequestAuthorization = true
        guard suspendsAuthorization else { return isAuthorized }
        return await withCheckedContinuation { authorizationContinuation = $0 }
    }

    func start(
        contextualPhrases: [String],
        onPartial: @escaping @MainActor @Sendable (String) -> Void,
        onFinal: @escaping @MainActor @Sendable (String) -> Void,
        onError: @escaping @MainActor @Sendable (ConversationRecognitionError) -> Void
    ) throws {
        startCount += 1
        isRunning = true
        attempts.append(Attempt(
            contextualPhrases: contextualPhrases,
            onPartial: onPartial,
            onFinal: onFinal,
            onError: onError
        ))
    }

    func stop() {
        guard isRunning else { return }
        stopCount += 1
        isRunning = false
    }

    func sendPartial(_ transcript: String, attemptIndex: Int? = nil) {
        let index = attemptIndex ?? (attempts.count - 1)
        guard attempts.indices.contains(index) else { return }
        attempts[index].onPartial(transcript)
    }

    func sendFinal(_ transcript: String, attemptIndex: Int? = nil) {
        let index = attemptIndex ?? (attempts.count - 1)
        guard attempts.indices.contains(index) else { return }
        attempts[index].onFinal(transcript)
    }

    func sendError(_ error: ConversationRecognitionError, attemptIndex: Int? = nil) {
        let index = attemptIndex ?? (attempts.count - 1)
        guard attempts.indices.contains(index) else { return }
        attempts[index].onError(error)
    }

    @discardableResult
    func waitUntilStarted(timeoutNanoseconds: UInt64 = 1_000_000_000) async -> Bool {
        let start = DispatchTime.now().uptimeNanoseconds
        while !isRunning {
            if DispatchTime.now().uptimeNanoseconds - start > timeoutNanoseconds { return false }
            await Task.yield()
        }
        return true
    }

    @discardableResult
    func waitUntilAuthorizationRequested(timeoutNanoseconds: UInt64 = 1_000_000_000) async -> Bool {
        let start = DispatchTime.now().uptimeNanoseconds
        while !didRequestAuthorization {
            if DispatchTime.now().uptimeNanoseconds - start > timeoutNanoseconds { return false }
            await Task.yield()
        }
        return true
    }

    func resumeAuthorization(isAuthorized: Bool) {
        authorizationContinuation?.resume(returning: isAuthorized)
        authorizationContinuation = nil
    }
}

private actor TestConversationAudioCoordinator: AudioSessionCoordinating {
    private(set) var acquiredIntents: [AudioSessionIntent] = []
    private(set) var releasedLeases: [AudioSessionLease] = []
    private(set) var events: [String] = []
    private let suspendsAcquire: Bool
    private var acquireContinuation: CheckedContinuation<Void, Never>?
    private var didRequestAcquire = false

    init(suspendsAcquire: Bool = false) {
        self.suspendsAcquire = suspendsAcquire
    }

    func acquire(_ intent: AudioSessionIntent) async throws -> AudioSessionLease {
        didRequestAcquire = true
        events.append("acquire")
        if suspendsAcquire {
            await withCheckedContinuation { acquireContinuation = $0 }
        }
        acquiredIntents.append(intent)
        return AudioSessionLease(generation: UInt(acquiredIntents.count), intent: intent)
    }

    func release(_ lease: AudioSessionLease) async {
        events.append("release")
        releasedLeases.append(lease)
    }

    func recordEvent(_ event: String) {
        events.append(event)
    }

    func acquiredIntentsSnapshot() -> [AudioSessionIntent] { acquiredIntents }
    func releasedLeaseCount() -> Int { releasedLeases.count }
    func releasedLeasesSnapshot() -> [AudioSessionLease] { releasedLeases }
    func eventsSnapshot() -> [String] { events }

    @discardableResult
    func waitUntilAcquireRequested(timeoutNanoseconds: UInt64 = 1_000_000_000) async -> Bool {
        let start = DispatchTime.now().uptimeNanoseconds
        while !didRequestAcquire {
            if DispatchTime.now().uptimeNanoseconds - start > timeoutNanoseconds { return false }
            await Task.yield()
        }
        return true
    }

    func resumeAcquire() {
        acquireContinuation?.resume()
        acquireContinuation = nil
    }
}

private actor TestConversationSleeper: ConversationSleeping {
    private struct Waiter {
        let id: UUID
        let duration: Duration
        let continuation: CheckedContinuation<Void, Error>
    }

    private let immediateDurations: Set<Duration>
    private(set) var sleepCalls: [Duration] = []
    private var waiters: [Waiter] = []

    init(immediateDurations: Set<Duration> = []) {
        self.immediateDurations = immediateDurations
    }

    func sleep(for duration: Duration) async throws {
        let id = UUID()
        sleepCalls.append(duration)
        if immediateDurations.contains(duration) { return }
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                if Task.isCancelled {
                    continuation.resume(throwing: CancellationError())
                } else {
                    waiters.append(Waiter(id: id, duration: duration, continuation: continuation))
                }
            }
        } onCancel: {
            Task { [self] in
                await self.removeAndCancelWaiter(id: id)
            }
        }
    }

    func removeAndCancelWaiter(id: UUID) {
        if let index = waiters.firstIndex(where: { $0.id == id }) {
            let waiter = waiters.remove(at: index)
            waiter.continuation.resume(throwing: CancellationError())
        }
    }

    func sleepCount(for duration: Duration) -> Int {
        sleepCalls.filter { $0 == duration }.count
    }

    func waiterCount(for duration: Duration) -> Int {
        waiters.filter { $0.duration == duration }.count
    }

    func advance(duration: Duration) {
        if let index = waiters.firstIndex(where: { $0.duration == duration }) {
            let waiter = waiters.remove(at: index)
            waiter.continuation.resume()
        }
    }

    @discardableResult
    func waitUntilSleeping(for duration: Duration, timeoutNanoseconds: UInt64 = 1_000_000_000) async -> Bool {
        let start = DispatchTime.now().uptimeNanoseconds
        while !waiters.contains(where: { $0.duration == duration }) {
            if DispatchTime.now().uptimeNanoseconds - start > timeoutNanoseconds { return false }
            await Task.yield()
        }
        return true
    }
}
