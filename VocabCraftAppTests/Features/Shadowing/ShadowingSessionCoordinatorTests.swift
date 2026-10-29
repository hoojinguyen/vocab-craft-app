import AVFoundation
import Foundation
import SpeechKit
import Testing
@testable import VocabCraftApp

@Suite("Shadowing Session Coordinator Tests")
struct ShadowingSessionCoordinatorTests {
    @Test("Acquires playback lease when playing native audio and speechCapture when recording")
    @MainActor
    func testLeaseTransition() async throws {
        let mockCoordinator = MockAudioSessionCoordinator()
        let sessionCoordinator = makeTestShadowingSessionCoordinator(audioCoordinator: mockCoordinator)

        try await sessionCoordinator.prepareForNativePlayback()
        #expect(mockCoordinator.activeIntent == .playback)

        try await sessionCoordinator.prepareForSpeechCapture()
        #expect(mockCoordinator.activeIntent == .speechCapture)

        await sessionCoordinator.releaseAll()
        #expect(mockCoordinator.activeIntent == nil)
    }

    @Test("Releases previous lease when preparing multiple times")
    @MainActor
    func testReleasesPreviousLeaseOnSubsequentPrepare() async throws {
        let mockCoordinator = MockAudioSessionCoordinator()
        let sessionCoordinator = makeTestShadowingSessionCoordinator(audioCoordinator: mockCoordinator)

        try await sessionCoordinator.prepareForNativePlayback()
        #expect(mockCoordinator.activeIntent == .playback)
        #expect(mockCoordinator.releaseCallCount == 0)

        try await sessionCoordinator.prepareForSpeechCapture()
        #expect(mockCoordinator.activeIntent == .speechCapture)
        #expect(mockCoordinator.releaseCallCount == 1)

        await sessionCoordinator.releaseAll()
        #expect(mockCoordinator.activeIntent == nil)
        #expect(mockCoordinator.releaseCallCount == 2)
    }

    @Test("Propagates acquisition failure and leaves activeIntent nil")
    @MainActor
    func testAcquisitionFailureHandling() async throws {
        let mockCoordinator = MockAudioSessionCoordinator()
        mockCoordinator.shouldFailAcquire = true
        let sessionCoordinator = makeTestShadowingSessionCoordinator(audioCoordinator: mockCoordinator)

        await #expect(throws: MockAudioSessionCoordinator.MockError.simulatedFailure) {
            try await sessionCoordinator.prepareForNativePlayback()
        }
        #expect(mockCoordinator.activeIntent == nil)
    }

    @Test("ShadowingAudioRecorder generates unique .m4a file in temporary directory")
    @MainActor
    func testRecorderFileGeneration() throws {
        let state = FakeAudioRecordingDevice.State()
        let recorder = ShadowingAudioRecorder(audioRecorderFactory: { _ in
            FakeAudioRecordingDevice(state: state)
        })
        let sentenceId = "sent_test_123"

        let fileURL = try recorder.startRecording(sentenceId: sentenceId)
        #expect(fileURL.pathExtension == "m4a")
        #expect(fileURL.lastPathComponent.contains(sentenceId))
        #expect(recorder.lastRecordedURL == fileURL)
        #expect(state.createdCount == 1)
        #expect(recorder.isRecording)

        recorder.stopRecording()
        #expect(!recorder.isRecording)
    }

    @Test("Failed recorder start stops and releases the device")
    @MainActor
    func recorderStartFailureStopsAndReleasesDevice() {
        let state = FakeAudioRecordingDevice.State()
        weak var failedDevice: FakeAudioRecordingDevice?
        let recorder = ShadowingAudioRecorder(audioRecorderFactory: { _ in
            let device = FakeAudioRecordingDevice(state: state, startsSuccessfully: false)
            failedDevice = device
            return device
        })

        #expect(throws: ShadowingAudioRecorderError.failedToStartRecording) {
            try recorder.startRecording(sentenceId: "failed_start")
        }

        #expect(state.stopCallCount == 1)
        #expect(failedDevice == nil)
        #expect(!recorder.isRecording)
        #expect(recorder.lastRecordedURL == nil)
    }

    @Test("ShadowingAudioRecorder stopPlayback resets playing state")
    @MainActor
    func testRecorderStopPlayback() {
        let recorder = makeTestShadowingAudioRecorder()
        recorder.stopPlayback()
        #expect(!recorder.isPlaying)
    }
}

@MainActor
func makeTestShadowingSessionCoordinator(
    audioCoordinator: any AudioSessionCoordinating = NoOpAudioSessionCoordinator()
) -> ShadowingSessionCoordinator {
    let recorder = makeTestShadowingAudioRecorder()
    return ShadowingSessionCoordinator(audioCoordinator: audioCoordinator, recorder: recorder)
}

@MainActor
func makeTestShadowingAudioRecorder() -> ShadowingAudioRecorder {
    ShadowingAudioRecorder(audioRecorderFactory: { _ in
        FakeAudioRecordingDevice(state: FakeAudioRecordingDevice.State())
    })
}

@MainActor
final class FakeAudioRecordingDevice: AudioRecordingDevice {
    @MainActor
    final class State {
        var createdCount = 0
        var stopCallCount = 0
    }

    private let state: State
    private let startsSuccessfully: Bool
    private(set) var isRecording = false

    init(state: State, startsSuccessfully: Bool = true) {
        self.state = state
        self.startsSuccessfully = startsSuccessfully
        state.createdCount += 1
    }

    func record() -> Bool {
        isRecording = startsSuccessfully
        return startsSuccessfully
    }

    func stop() {
        state.stopCallCount += 1
        isRecording = false
    }
}

private final class MockAudioSessionCoordinator: AudioSessionCoordinating, @unchecked Sendable {
    enum MockError: Error, Equatable {
        case simulatedFailure
    }

    var activeIntent: AudioSessionIntent?
    var releaseCallCount: Int = 0
    var shouldFailAcquire: Bool = false
    var events: AsyncStream<AudioSessionEvent> { AsyncStream { $0.finish() } }

    func acquire(_ intent: AudioSessionIntent) async throws -> AudioSessionLease {
        if shouldFailAcquire {
            throw MockError.simulatedFailure
        }
        activeIntent = intent
        return AudioSessionLease(generation: 1, intent: intent)
    }

    func release(_ lease: AudioSessionLease) async {
        releaseCallCount += 1
        if activeIntent == lease.intent {
            activeIntent = nil
        }
    }
}
