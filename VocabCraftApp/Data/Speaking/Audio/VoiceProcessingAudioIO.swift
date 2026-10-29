import AVFoundation
import Foundation

struct SpeakingCaptureSamples: Sendable {
    let sampleRate: Double
    let channels: [[Float]]

    var frameCount: Int { channels.first?.count ?? 0 }
}

public enum SpeakingAudioIOError: Error {
    case invalidInputFormat
    case captureNotStarted
}

/// Owns the duplex engine graph. Engine and player operations are serialized on one queue.
public final class VoiceProcessingAudioIO: SpeakingAudioIO, @unchecked Sendable {
    private let graphQueue = DispatchQueue(label: "app.vocabcraft.speaking.audio-graph")
    private let captureQueue = DispatchQueue(label: "app.vocabcraft.speaking.capture-conversion")
    private let captureStateLock = NSLock()
    private let playbackStateLock = NSLock()
    private var engine: AVAudioEngine?
    private var player: AVAudioPlayerNode?
    private var captureHandler: (@Sendable (Data) -> Void)?
    private var pendingPlaybackCount = 0
    private var pendingPlaybackFrames = 0
    private var playbackOverflows = 0
    private var playbackGeneration: UInt64 = 0
    private let maximumPlaybackFrames = 48_000
    private var pendingCaptureFrames = 0
    private var captureOverflows = 0
    private var captureGeneration: UInt64 = 0

    public init() {}

    deinit {
        graphQueue.sync {
            stopGraph()
        }
    }

    public func start(onCapture: @escaping @Sendable (Data) -> Void) async throws {
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
            let shouldAccept = playbackStateLock.withLock {
                Self.canSchedulePlayback(pendingFrames: pendingPlaybackFrames, incomingFrames: Int(buffer.frameLength), maximumFrames: maximumPlaybackFrames)
            }
            guard shouldAccept else {
                player.stop()
                clearPendingPlayback()
                playbackStateLock.withLock { playbackOverflows += 1 }
                player.play()
                return
            }
            let frames = Int(buffer.frameLength)
            let generation = playbackStateLock.withLock { () -> UInt64 in
                pendingPlaybackCount += 1
                pendingPlaybackFrames += frames
                return playbackGeneration
            }
            player.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [weak self] _ in
                self?.playbackDidFinish(generation: generation, frames: frames)
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

    public var playbackOverflowCount: Int {
        playbackStateLock.withLock { playbackOverflows }
    }

    public var captureOverflowCount: Int {
        captureStateLock.withLock { captureOverflows }
    }

    static func canSchedulePlayback(pendingFrames: Int, incomingFrames: Int, maximumFrames: Int) -> Bool {
        incomingFrames > 0 && pendingFrames + incomingFrames <= maximumFrames
    }

    static func canQueueCapture(pendingFrames: Int, incomingFrames: Int, maximumFrames: Int) -> Bool {
        incomingFrames > 0 && pendingFrames + incomingFrames <= maximumFrames
    }

    static func ownedCaptureSamples(from buffer: AVAudioPCMBuffer) -> SpeakingCaptureSamples? {
        guard buffer.format.commonFormat == .pcmFormatFloat32,
              !buffer.format.isInterleaved,
              buffer.frameLength > 0,
              let channelData = buffer.floatChannelData
        else {
            return nil
        }
        let frameCount = Int(buffer.frameLength)
        let channels = (0..<Int(buffer.format.channelCount)).map { channel in
            Array(UnsafeBufferPointer(start: channelData[channel], count: frameCount))
        }
        return SpeakingCaptureSamples(sampleRate: buffer.format.sampleRate, channels: channels)
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
        let maxCaptureFrames = Int(inputFormat.sampleRate * 2)
        input.installTap(onBus: 0, bufferSize: 1_024, format: inputFormat) { [weak self] buffer, _ in
            guard let self else { return }
            guard let ownedSamples = Self.ownedCaptureSamples(from: buffer) else {
                self.captureStateLock.withLock { self.captureOverflows += 1 }
                return
            }
            let reservation = self.captureStateLock.withLock { () -> UInt64? in
                guard Self.canQueueCapture(
                    pendingFrames: self.pendingCaptureFrames,
                    incomingFrames: ownedSamples.frameCount,
                    maximumFrames: maxCaptureFrames
                ) else {
                    self.captureOverflows += 1
                    return nil
                }
                self.pendingCaptureFrames += ownedSamples.frameCount
                return self.captureGeneration
            }
            guard let generation = reservation else { return }

            self.captureQueue.async { [self] in
                defer {
                    self.captureStateLock.withLock {
                        self.pendingCaptureFrames = max(0, self.pendingCaptureFrames - ownedSamples.frameCount)
                    }
                }
                guard self.captureStateLock.withLock({ generation == self.captureGeneration }),
                      let copiedBuffer = Self.pcmBuffer(from: ownedSamples),
                      let pcm = try? PCMConverter(inputFormat: copiedBuffer.format).pcm16kMono(from: copiedBuffer),
                      !pcm.isEmpty,
                      self.captureStateLock.withLock({ generation == self.captureGeneration })
                else { return }
                captureHandler(pcm)
            }
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
        captureStateLock.withLock { captureGeneration &+= 1 }
        if let engine {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
            engine.reset()
        }
        player?.stop()
        player = nil
        engine = nil
    }

    private static func pcmBuffer(from samples: SpeakingCaptureSamples) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: samples.sampleRate,
            channels: AVAudioChannelCount(samples.channels.count)
        ),
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.frameCount)),
        let destination = buffer.floatChannelData
        else { return nil }
        buffer.frameLength = AVAudioFrameCount(samples.frameCount)
        for channel in samples.channels.indices {
            destination[channel].update(from: samples.channels[channel], count: samples.frameCount)
        }
        return buffer
    }

    private func playbackDidFinish(generation: UInt64, frames: Int) {
        playbackStateLock.withLock {
            guard generation == playbackGeneration else { return }
            pendingPlaybackCount = max(0, pendingPlaybackCount - 1)
            pendingPlaybackFrames = max(0, pendingPlaybackFrames - frames)
        }
    }

    private func clearPendingPlayback() {
        playbackStateLock.withLock {
            playbackGeneration &+= 1
            pendingPlaybackCount = 0
            pendingPlaybackFrames = 0
        }
    }
}
