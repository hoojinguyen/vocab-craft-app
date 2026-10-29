import AVFoundation
import Foundation

public protocol SpeakingAudioIO: AnyObject, Sendable {
    /// Delivers owned PCM16 LE, mono 16 kHz bytes. The payload can safely outlive the tap callback.
    func start(onCapture: @escaping @Sendable (Data) -> Void) async throws
    func enqueuePlayback(_ pcm24k: Data)
    func flushPlayback()
    var isPlaying: Bool { get }
    var captureOverflowCount: Int { get }
    func stop() async
    func restartAfterRouteChange() async throws
}
