@preconcurrency import AVFoundation
import Foundation

private final class AudioPlayerTransferBox: @unchecked Sendable {
    let player: AVAudioPlayer

    init(_ player: AVAudioPlayer) {
        self.player = player
    }
}

@MainActor
public final class ShadowingAudioRecorder: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var playbackFinishedHandler: (@Sendable () -> Void)?
    private var isActivelyRecording: Bool = false

    public private(set) var lastRecordedURL: URL?

    public var isRecording: Bool {
        if let recorder = audioRecorder, recorder.isRecording {
            return true
        }
        return isActivelyRecording
    }

    public var isPlaying: Bool {
        audioPlayer?.isPlaying ?? false
    }

    override public init() {
        super.init()
    }

    public func startRecording(sentenceId: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("shadowing_\(sentenceId)_\(UUID().uuidString).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder.delegate = self
        recorder.record()
        self.audioRecorder = recorder
        self.lastRecordedURL = fileURL
        self.isActivelyRecording = true
        return fileURL
    }

    public func stopRecording() {
        isActivelyRecording = false
        audioRecorder?.stop()
        audioRecorder = nil
    }

    public func playRecordedAudio(from url: URL, onFinished: (@Sendable () -> Void)? = nil) throws {
        audioPlayer?.stop()
        playbackFinishedHandler = onFinished

        let player = try AVAudioPlayer(contentsOf: url)
        player.delegate = self
        self.audioPlayer = player
        player.play()
    }

    public func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        playbackFinishedHandler = nil
    }

    // MARK: - AVAudioPlayerDelegate

    public nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                self.handlePlaybackFinished(for: player)
            }
        } else {
            let box = AudioPlayerTransferBox(player)
            Task { @MainActor in
                self.handlePlaybackFinished(for: box.player)
            }
        }
    }

    public nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                self.handleDecodeError(for: player)
            }
        } else {
            let box = AudioPlayerTransferBox(player)
            Task { @MainActor in
                self.handleDecodeError(for: box.player)
            }
        }
    }

    private func handlePlaybackFinished(for player: AVAudioPlayer) {
        guard self.audioPlayer === player else { return }
        let handler = self.playbackFinishedHandler
        self.stopPlayback()
        handler?()
    }

    private func handleDecodeError(for player: AVAudioPlayer) {
        guard self.audioPlayer === player else { return }
        self.stopPlayback()
    }
}
