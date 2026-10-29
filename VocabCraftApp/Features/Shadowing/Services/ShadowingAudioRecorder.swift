@preconcurrency import AVFoundation
import Foundation

@MainActor
protocol AudioRecordingDevice: AnyObject {
    var isRecording: Bool { get }

    func record() -> Bool
    func stop()
}

enum ShadowingAudioRecorderError: Error, Equatable {
    case failedToStartRecording
}

typealias AudioRecorderFactory = @MainActor (URL) throws -> any AudioRecordingDevice

@MainActor
private final class AVAudioRecordingDevice: AudioRecordingDevice {
    private let recorder: AVAudioRecorder

    init(url: URL) throws {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        recorder = try AVAudioRecorder(url: url, settings: settings)
    }

    var isRecording: Bool {
        recorder.isRecording
    }

    func record() -> Bool {
        recorder.record()
    }

    func stop() {
        recorder.stop()
    }
}

private final class AudioPlayerTransferBox: @unchecked Sendable {
    let player: AVAudioPlayer

    init(_ player: AVAudioPlayer) {
        self.player = player
    }
}

@MainActor
public final class ShadowingAudioRecorder: NSObject, AVAudioPlayerDelegate {
    private var audioRecorder: (any AudioRecordingDevice)?
    private var audioPlayer: AVAudioPlayer?
    private var playbackFinishedHandler: (@Sendable () -> Void)?
    private let audioRecorderFactory: AudioRecorderFactory

    public private(set) var lastRecordedURL: URL?

    public var isRecording: Bool {
        audioRecorder?.isRecording ?? false
    }

    public var isPlaying: Bool {
        audioPlayer?.isPlaying ?? false
    }

    override public init() {
        audioRecorderFactory = { url in
            try AVAudioRecordingDevice(url: url)
        }
        super.init()
    }

    init(audioRecorderFactory: @escaping AudioRecorderFactory) {
        self.audioRecorderFactory = audioRecorderFactory
        super.init()
    }

    public func startRecording(sentenceId: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("shadowing_\(sentenceId)_\(UUID().uuidString).m4a")

        let recorder = try audioRecorderFactory(fileURL)
        guard recorder.record() else {
            recorder.stop()
            throw ShadowingAudioRecorderError.failedToStartRecording
        }

        self.audioRecorder = recorder
        self.lastRecordedURL = fileURL
        return fileURL
    }

    public func stopRecording() {
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
