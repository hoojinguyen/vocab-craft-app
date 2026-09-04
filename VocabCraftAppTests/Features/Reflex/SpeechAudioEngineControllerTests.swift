import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("SpeechAudioEngineController Tests")
struct SpeechAudioEngineControllerTests {
    @Test("Concurrent prepare requests perform one hardware setup")
    func concurrentPrepareCoalesces() async throws {
        let hardware = MockSpeechAudioHardware()
        let controller = SpeechAudioEngineController(hardware: hardware)

        async let first: Void = controller.prepare(relay: AudioBufferRelay())
        async let second: Void = controller.prepare(relay: AudioBufferRelay())
        _ = try await (first, second)

        #expect(await hardware.prepareCallCount == 1)
        #expect(await controller.state == .ready)
    }

    @Test("Repeated pause stops hardware once")
    func pauseIsIdempotent() async throws {
        let hardware = MockSpeechAudioHardware()
        let controller = SpeechAudioEngineController(hardware: hardware)
        try await controller.prepare(relay: AudioBufferRelay())

        await controller.pause()
        await controller.pause()

        #expect(await hardware.pauseCallCount == 1)
        #expect(await controller.state == .ready)
    }

    @Test("Repeated resume starts hardware once")
    func resumeIsIdempotent() async throws {
        let hardware = MockSpeechAudioHardware()
        let controller = SpeechAudioEngineController(hardware: hardware)
        try await controller.prepare(relay: AudioBufferRelay())
        await controller.pause()

        try await controller.resume()
        try await controller.resume()

        #expect(await hardware.resumeCallCount == 1)
        #expect(await controller.state == .ready)
    }

    @Test("Repeated teardown releases hardware once")
    func teardownIsIdempotent() async {
        let hardware = MockSpeechAudioHardware()
        let controller = SpeechAudioEngineController(hardware: hardware)
        try? await controller.prepare(relay: AudioBufferRelay())

        await controller.teardown()
        await controller.teardown()

        #expect(await hardware.teardownCallCount == 1)
        #expect(await controller.state == .idle)
    }

    @Test("Teardown during preparation leaves the controller idle")
    func teardownDuringPrepareStaysIdle() async {
        let hardware = MockSpeechAudioHardware(blockPreparation: true)
        let controller = SpeechAudioEngineController(hardware: hardware)
        let prepareTask = Task {
            try? await controller.prepare(relay: AudioBufferRelay())
        }

        await hardware.waitUntilPreparationStarts()
        let teardownTask = Task {
            await controller.teardown()
        }
        while await controller.state != .idle {
            await Task.yield()
        }
        await hardware.completePreparation()
        await prepareTask.value
        await teardownTask.value

        #expect(await hardware.prepareCallCount == 1)
        #expect(await hardware.teardownCallCount == 1)
        #expect(await !hardware.isPrepared)
        #expect(await controller.state == .idle)
    }

    @Test("Teardown during preparation causes prepare to throw CancellationError")
    func teardownDuringPrepareThrowsCancellationError() async {
        let hardware = MockSpeechAudioHardware(blockPreparation: true)
        let controller = SpeechAudioEngineController(hardware: hardware)
        let prepareTask = Task {
            try await controller.prepare(relay: AudioBufferRelay())
        }

        await hardware.waitUntilPreparationStarts()
        let teardownTask = Task {
            await controller.teardown()
        }
        while await controller.state != .idle {
            await Task.yield()
        }
        await hardware.completePreparation()
        await teardownTask.value

        await #expect(throws: CancellationError.self) {
            try await prepareTask.value
        }
        #expect(await controller.state == .idle)
    }

    @Test("Pause during preparation pauses hardware upon completion")
    func pauseDuringPreparationPausesHardwareOnCompletion() async throws {
        let hardware = MockSpeechAudioHardware(blockPreparation: true)
        let controller = SpeechAudioEngineController(hardware: hardware)
        let prepareTask = Task {
            try await controller.prepare(relay: AudioBufferRelay())
        }

        await hardware.waitUntilPreparationStarts()
        await controller.pause()
        await hardware.completePreparation()
        try await prepareTask.value

        #expect(await controller.state == .ready)
        #expect(await hardware.pauseCallCount == 1)
    }

    @Test("Resume during preparation un-pauses hardware before completion")
    func resumeDuringPreparationCancelsPause() async throws {
        let hardware = MockSpeechAudioHardware(blockPreparation: true)
        let controller = SpeechAudioEngineController(hardware: hardware)
        let prepareTask = Task {
            try await controller.prepare(relay: AudioBufferRelay())
        }

        await hardware.waitUntilPreparationStarts()
        await controller.pause()
        try await controller.resume()
        await hardware.completePreparation()
        try await prepareTask.value

        #expect(await controller.state == .ready)
        #expect(await hardware.pauseCallCount == 0)
    }

    @Test("Prepare after failure retries hardware setup cleanly")
    func prepareAfterFailureRetriesHardwareSetup() async throws {
        let hardware = MockSpeechAudioHardware(failCount: 1)
        let controller = SpeechAudioEngineController(hardware: hardware)

        await #expect(throws: Error.self) {
            try await controller.prepare(relay: AudioBufferRelay())
        }
        #expect(await controller.state == .failed)

        try await controller.prepare(relay: AudioBufferRelay())
        #expect(await controller.state == .ready)
        #expect(await hardware.prepareCallCount == 2)
    }
}

private actor MockSpeechAudioHardware: SpeechAudioHardware {
    private(set) var prepareCallCount = 0
    private(set) var resumeCallCount = 0
    private(set) var pauseCallCount = 0
    private(set) var teardownCallCount = 0
    private(set) var isPrepared = false
    private let blockPreparation: Bool
    private var failCount: Int
    private var preparationStarted = false
    private var preparationStartWaiters: [CheckedContinuation<Void, Never>] = []
    private var preparationContinuation: CheckedContinuation<Void, Never>?

    init(blockPreparation: Bool = false, failCount: Int = 0) {
        self.blockPreparation = blockPreparation
        self.failCount = failCount
    }

    func prepare(relay: AudioBufferRelay) async throws {
        prepareCallCount += 1
        if failCount > 0 {
            failCount -= 1
            throw NSError(domain: "MockAudioHardware", code: -1)
        }
        preparationStarted = true
        preparationStartWaiters.forEach { $0.resume() }
        preparationStartWaiters.removeAll()

        if blockPreparation {
            await withCheckedContinuation { continuation in
                preparationContinuation = continuation
            }
        } else {
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        isPrepared = true
    }

    func resume() async throws {
        resumeCallCount += 1
    }

    func pause() async {
        pauseCallCount += 1
    }

    func teardown() async {
        teardownCallCount += 1
        isPrepared = false
    }

    func waitUntilPreparationStarts() async {
        guard !preparationStarted else {
            return
        }

        await withCheckedContinuation { continuation in
            preparationStartWaiters.append(continuation)
        }
    }

    func completePreparation() {
        preparationContinuation?.resume()
        preparationContinuation = nil
    }
}
#endif
