import Foundation
import SpeechKit

@MainActor
public final class ShadowingSessionCoordinator {
    private let audioCoordinator: any AudioSessionCoordinating
    private var activeLease: AudioSessionLease?
    public let recorder: ShadowingAudioRecorder

    public var currentIntent: AudioSessionIntent? {
        activeLease?.intent
    }

    public init(
        audioCoordinator: any AudioSessionCoordinating = NoOpAudioSessionCoordinator(),
        recorder: ShadowingAudioRecorder = ShadowingAudioRecorder()
    ) {
        self.audioCoordinator = audioCoordinator
        self.recorder = recorder
    }

    public func prepareForNativePlayback() async throws {
        if let lease = activeLease {
            await audioCoordinator.release(lease)
            activeLease = nil
        }
        activeLease = try await audioCoordinator.acquire(.playback)
    }

    public func prepareForSpeechCapture() async throws {
        if let lease = activeLease {
            await audioCoordinator.release(lease)
            activeLease = nil
        }
        activeLease = try await audioCoordinator.acquire(.speechCapture)
    }

    public func releaseAll() async {
        if let lease = activeLease {
            await audioCoordinator.release(lease)
            activeLease = nil
        }
        recorder.stopRecording()
        recorder.stopPlayback()
    }
}
