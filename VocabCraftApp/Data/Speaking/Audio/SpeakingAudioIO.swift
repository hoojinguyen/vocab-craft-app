import AVFoundation
import Foundation

public protocol SpeakingAudioIO: AnyObject, Sendable {
    /// The buffer is callback-scoped. Copy or convert its samples synchronously before async transfer.
    func start(onCapture: @escaping @Sendable (AVAudioPCMBuffer) -> Void) async throws
    func enqueuePlayback(_ pcm24k: Data)
    func flushPlayback()
    var isPlaying: Bool { get }
    func stop() async
    func restartAfterRouteChange() async throws
}
