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
        let sessionCoordinator = ShadowingSessionCoordinator(audioCoordinator: mockCoordinator)

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
        let sessionCoordinator = ShadowingSessionCoordinator(audioCoordinator: mockCoordinator)

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
        let sessionCoordinator = ShadowingSessionCoordinator(audioCoordinator: mockCoordinator)

        await #expect(throws: MockAudioSessionCoordinator.MockError.simulatedFailure) {
            try await sessionCoordinator.prepareForNativePlayback()
        }
        #expect(mockCoordinator.activeIntent == nil)
    }

    @Test("ShadowingAudioRecorder generates unique .m4a file in temporary directory")
    @MainActor
    func testRecorderFileGeneration() throws {
        let recorder = ShadowingAudioRecorder()
        let sentenceId = "sent_test_123"

        let fileURL = try recorder.startRecording(sentenceId: sentenceId)
        #expect(fileURL.pathExtension == "m4a")
        #expect(fileURL.lastPathComponent.contains(sentenceId))
        #expect(recorder.lastRecordedURL == fileURL)

        recorder.stopRecording()
        #expect(!recorder.isRecording)
    }

    @Test("ShadowingAudioRecorder stopPlayback resets playing state")
    @MainActor
    func testRecorderStopPlayback() {
        let recorder = ShadowingAudioRecorder()
        recorder.stopPlayback()
        #expect(!recorder.isPlaying)
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
