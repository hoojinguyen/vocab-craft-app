import Foundation

/// Standalone fallback coordinator that performs no audio session hardware mutations.
/// Suitable for previews, simulators, and unit testing environments.
public final class NoOpAudioSessionCoordinator: AudioSessionCoordinating, @unchecked Sendable {
    private var generation: UInt = 0
    private let lock = NSLock()

    public init() {}

    public func acquire(_ intent: AudioSessionIntent) async throws -> AudioSessionLease {
        let currentGen = lock.withLock { () -> UInt in
            generation += 1
            return generation
        }
        return AudioSessionLease(id: UUID(), generation: currentGen, intent: intent)
    }

    public func release(_ lease: AudioSessionLease) async {}

    public var events: AsyncStream<AudioSessionEvent> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}
