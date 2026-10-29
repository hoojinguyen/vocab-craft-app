import AVFoundation
import Foundation

public enum SpeakingAudioIOError: Error {
    case invalidInputFormat
    case captureNotStarted
}

/// Owns the duplex engine graph. Engine and player operations are serialized on one queue.
public final class VoiceProcessingAudioIO: SpeakingAudioIO, @unchecked Sendable {
    private let graphQueue = DispatchQueue(label: "app.vocabcraft.speaking.audio-graph")
    private let playbackStateLock = NSLock()
    private var engine: AVAudioEngine?
    private var player: AVAudioPlayerNode?
    private var captureHandler: (@Sendable (AVAudioPCMBuffer) -> Void)?
    private var pendingPlaybackCount = 0
    private var playbackGeneration: UInt64 = 0

    public init() {}

    deinit {
        graphQueue.sync {
            stopGraph()
        }
    }

    public func start(onCapture: @escaping @Sendable (AVAudioPCMBuffer) -> Void) async throws {
        try graphQueue.sync {
            captureHandler = onCapture
            try rebuildGraph()
        }
    }

    public func enqueuePlayback(_ pcm24k: Data) {
        graphQueue.sync {
            guard let engine, engine.isRunning, let player,
                  let buffer = PCMConverter.playbackBuffer(fromPCM24k: pcm24k)
            else {
                return
            }
            let generation = playbackStateLock.withLock { () -> UInt64 in
                pendingPlaybackCount += 1
                return playbackGeneration
            }
            player.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [weak self] _ in
                self?.playbackDidFinish(generation: generation)
            }
            if !player.isPlaying {
                player.play()
            }
        }
    }

    public func flushPlayback() {
        graphQueue.sync {
            guard let player, engine?.isRunning == true else { return }
            player.stop()
            clearPendingPlayback()
            player.play()
        }
    }

    public var isPlaying: Bool {
        playbackStateLock.withLock { pendingPlaybackCount > 0 }
    }

    public func stop() async {
        graphQueue.sync {
            stopGraph()
            captureHandler = nil
        }
    }

    public func restartAfterRouteChange() async throws {
        try graphQueue.sync {
            try rebuildGraph()
        }
    }

    private func rebuildGraph() throws {
        stopGraph()

        let engine = AVAudioEngine()
        let input = engine.inputNode
        #if os(iOS)
        try input.setVoiceProcessingEnabled(true)
        #endif

        let inputFormat = input.outputFormat(forBus: 0)
        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0,
              let playbackFormat = AVAudioFormat(standardFormatWithSampleRate: 24_000, channels: 1)
        else {
            throw SpeakingAudioIOError.invalidInputFormat
        }
        guard let captureHandler else { throw SpeakingAudioIOError.captureNotStarted }

        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: playbackFormat)
        input.installTap(onBus: 0, bufferSize: 1_024, format: inputFormat) { buffer, _ in
            captureHandler(buffer)
        }

        do {
            engine.prepare()
            try engine.start()
        } catch {
            input.removeTap(onBus: 0)
            engine.stop()
            engine.reset()
            throw error
        }

        self.engine = engine
        self.player = player
    }

    private func stopGraph() {
        clearPendingPlayback()
        if let engine {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
            engine.reset()
        }
        player?.stop()
        player = nil
        engine = nil
    }

    private func playbackDidFinish(generation: UInt64) {
        playbackStateLock.withLock {
            guard generation == playbackGeneration else { return }
            pendingPlaybackCount = max(0, pendingPlaybackCount - 1)
        }
    }

    private func clearPendingPlayback() {
        playbackStateLock.withLock {
            playbackGeneration &+= 1
            pendingPlaybackCount = 0
        }
    }
}
