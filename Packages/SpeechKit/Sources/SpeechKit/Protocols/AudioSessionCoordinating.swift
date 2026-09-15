import Foundation

/// Explicit audio session intent declared by consumers.
public enum AudioSessionIntent: Hashable, Sendable {
    /// Playback-only audio (e.g. Text-to-Speech pronunciation, audio cues).
    case playback
    /// Recording-only speech capture (e.g. speech-to-text assessment).
    case speechCapture
    /// Simultaneous input and output (e.g. interactive reflex drill with live voice & audio prompts).
    case duplexSpeech
}

/// Token representing an active lease on the coordinated audio session.
public struct AudioSessionLease: Hashable, Sendable {
    public let id: UUID
    public let generation: UInt
    public let intent: AudioSessionIntent

    public init(id: UUID = UUID(), generation: UInt, intent: AudioSessionIntent) {
        self.id = id
        self.generation = generation
        self.intent = intent
    }
}

/// Normalized system audio events broadcast by the coordinator.
public enum AudioSessionEvent: Sendable, Equatable {
    case interruptionBegan
    case interruptionEnded(shouldResume: Bool)
    case routeChanged(reason: RouteChangeReason)
    case mediaServicesReset

    public enum RouteChangeReason: Sendable, Equatable {
        case newDeviceAvailable
        case oldDeviceUnavailable
        case categoryChange
        case other
    }
}

/// Primary coordinator abstraction for managing shared audio session leases and events.
public protocol AudioSessionCoordinating: AnyObject, Sendable {
    /// Acquire an audio session lease for the given intent.
    func acquire(_ intent: AudioSessionIntent) async throws -> AudioSessionLease

    /// Release an active lease.
    func release(_ lease: AudioSessionLease) async

    /// Asynchronous stream of audio session events.
    var events: AsyncStream<AudioSessionEvent> { get }
}
