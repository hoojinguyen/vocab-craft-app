import Foundation
@testable import VocabCraftApp

final class FakeSpeakingAudioIO: SpeakingAudioIO, @unchecked Sendable {
    private let lock = NSLock()
    private var capture: (@Sendable (Data) -> Void)?
    private var lastCapture: (@Sendable (Data) -> Void)?
    private var playing = false
    private var captureFailures = 0
    private var storedPlayback: [Data] = []
    private var storedFlushCount = 0
    private var storedStartCount = 0
    private var storedStopCount = 0
    private var storedRouteRestartCount = 0
    var startError: Error?
    var routeRestartError: Error?

    var isPlaying: Bool { lock.withLock { playing } }
    var captureOverflowCount: Int { lock.withLock { captureFailures } }
    var playback: [Data] { lock.withLock { storedPlayback } }
    var flushCount: Int { lock.withLock { storedFlushCount } }
    var startCount: Int { lock.withLock { storedStartCount } }
    var stopCount: Int { lock.withLock { storedStopCount } }
    var routeRestartCount: Int { lock.withLock { storedRouteRestartCount } }

    func start(onCapture: @escaping @Sendable (Data) -> Void) async throws {
        if let startError { throw startError }
        lock.withLock {
            capture = onCapture
            lastCapture = onCapture
            storedStartCount += 1
        }
    }

    func enqueuePlayback(_ pcm24k: Data) {
        lock.withLock {
            storedPlayback.append(pcm24k)
            if !pcm24k.isEmpty { playing = true }
        }
    }

    func flushPlayback() {
        lock.withLock {
            storedFlushCount += 1
            playing = false
        }
    }

    func stop() async {
        lock.withLock {
            storedStopCount += 1
            capture = nil
            playing = false
        }
    }

    func restartAfterRouteChange() async throws {
        if let routeRestartError { throw routeRestartError }
        lock.withLock { storedRouteRestartCount += 1 }
    }

    func emitCapture(_ data: Data) {
        let callback = lock.withLock { capture }
        callback?(data)
    }

    func emitStaleCapture(_ data: Data) {
        let callback = lock.withLock { lastCapture }
        callback?(data)
    }

    func incrementCaptureOverflow() {
        lock.withLock { captureFailures += 1 }
    }

    func setPlaying(_ value: Bool) {
        lock.withLock { playing = value }
    }
}
