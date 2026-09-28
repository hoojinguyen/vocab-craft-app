import AVFoundation
import Foundation
import Speech

/// Thread-safe buffer relay to bridge AVAudioEngine real-time audio tap callbacks with
/// SFSpeechAudioBufferRecognitionRequest without capturing @MainActor isolated references.
public final class AudioBufferRelay: @unchecked Sendable {
    private let lock = NSLock()
    private weak var activeRequest: SFSpeechAudioBufferRecognitionRequest?
    private var isMuted = false
    private var bufferListener: (@Sendable (AVAudioPCMBuffer) -> Void)?

    public init() {}

    public var isCurrentlyMuted: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isMuted
    }

    public var currentRequest: SFSpeechAudioBufferRecognitionRequest? {
        lock.lock()
        defer { lock.unlock() }
        return activeRequest
    }

    public func setRequest(_ request: SFSpeechAudioBufferRecognitionRequest?) {
        lock.lock()
        defer { lock.unlock() }
        activeRequest = request
        if request != nil {
            isMuted = false
        }
    }

    public func setBufferListener(_ listener: (@Sendable (AVAudioPCMBuffer) -> Void)?) {
        lock.lock()
        defer { lock.unlock() }
        bufferListener = listener
    }

    public func mute() {
        lock.lock()
        defer { lock.unlock() }
        isMuted = true
    }

    public func unmute() {
        lock.lock()
        defer { lock.unlock() }
        isMuted = false
    }

    /// Atomically detaches the active request and invokes endAudio() on it.
    /// Guarantees that no background tap buffer can ever be appended after endAudio() is called.
    public func detachAndEnd() {
        lock.lock()
        defer { lock.unlock() }
        let requestToEnd = activeRequest
        activeRequest = nil
        isMuted = true
        requestToEnd?.endAudio()
    }

    public func append(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        let listener = bufferListener
        let muted = isMuted
        let request = activeRequest
        lock.unlock()

        guard !muted else { return }
        request?.append(buffer)
        listener?(buffer)
    }
}
