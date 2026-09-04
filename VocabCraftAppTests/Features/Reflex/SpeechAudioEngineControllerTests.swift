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
}

private actor MockSpeechAudioHardware: SpeechAudioHardware {
    private(set) var prepareCallCount = 0
    private(set) var resumeCallCount = 0
    private(set) var pauseCallCount = 0
    private(set) var teardownCallCount = 0

    func prepare(relay: AudioBufferRelay) async throws {
        prepareCallCount += 1
        try await Task.sleep(nanoseconds: 50_000_000)
    }

    func resume() async throws {
        resumeCallCount += 1
    }

    func pause() async {
        pauseCallCount += 1
    }

    func teardown() async {
        teardownCallCount += 1
    }
}
#endif
