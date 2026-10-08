import AVFoundation
import Foundation
import os

private final class AudioPlayerTransferBox: @unchecked Sendable {
    let player: AVAudioPlayer

    init(_ player: AVAudioPlayer) {
        self.player = player
    }
}

@MainActor
public protocol KokoroAudioSynthesizing: AnyObject, Sendable {
    var isSpeaking: Bool { get }
    var isReady: Bool { get }
    func synthesizeAndPlay(text: String, persona: VoicePersona) async throws
    func stop()
}

@MainActor
public final class KokoroTTSEngine: NSObject, AVAudioPlayerDelegate, KokoroAudioSynthesizing, @unchecked Sendable {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "VocabCraftApp", category: "KokoroAudio")

    public private(set) var isSpeaking: Bool = false
    public var isReady: Bool {
        modelManager.isModelReady(.kokoro)
    }

    private let modelManager: OnDemandAIModelManager
    private let worker: KokoroInferenceWorker
    private let appleEngine: AppleEnhancedTTSEngine
    private var audioPlayer: AVAudioPlayer?
    private var activeContinuation: CheckedContinuation<Void, any Error>?

    public init(
        modelManager: OnDemandAIModelManager = .shared,
        worker: KokoroInferenceWorker? = nil,
        appleEngine: AppleEnhancedTTSEngine = AppleEnhancedTTSEngine()
    ) {
        self.modelManager = modelManager
        self.worker = worker ?? KokoroInferenceWorker(modelDirectory: modelManager.modelURL(for: .kokoro))
        self.appleEngine = appleEngine
        super.init()
    }

    public func voiceProfile(for persona: VoicePersona) -> String {
        switch persona {
        case .friendlyFemale: return "af_bella"
        case .friendlyMale: return "am_adam"
        case .authoritativeMale: return "am_michael"
        case .expressiveFemale: return "af_sarah"
        }
    }

    public func speakerId(for persona: VoicePersona) -> Int {
        KokoroInferenceWorker.speakerId(for: persona)
    }

    public func synthesizeAndPlay(text: String, persona: VoicePersona) async throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard isReady else {
            throw AIPackError.downloadRequired(packName: "Kokoro TTS", sizeDescription: "~85MB")
        }

        let speakerId = KokoroInferenceWorker.speakerId(for: persona)
        try await performSynthesisAndPlayback(text: trimmed, speakerId: speakerId)
    }

    public func synthesizeAndPlay(text: String, speaker: String) async throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard isReady else {
            throw AIPackError.downloadRequired(packName: "Kokoro TTS", sizeDescription: "~85MB")
        }

        let speakerId = KokoroInferenceWorker.speakerId(for: speaker)
        try await performSynthesisAndPlayback(text: trimmed, speakerId: speakerId)
    }

    private func performSynthesisAndPlayback(text: String, speakerId: Int, speed: Float = 1.0) async throws {
        stop()

        guard isReady else {
            throw AIPackError.downloadRequired(packName: "Kokoro TTS", sizeDescription: "~85MB")
        }

        try Task.checkCancellation()

        let wavData: Data
        do {
            wavData = try await worker.generateAudioData(text: text, speakerId: speakerId, speed: speed)
        } catch let packError as AIPackError {
            throw packError
        } catch {
            throw AIPackError.ttsFailed(packName: "Kokoro", underlyingMessage: error.localizedDescription)
        }

        try Task.checkCancellation()
        guard !wavData.isEmpty else { return }

        do {
            let player = try AVAudioPlayer(data: wavData)
            player.delegate = self
            player.prepareToPlay()
            self.audioPlayer = player
            self.isSpeaking = true

            try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                    self.activeContinuation = continuation
                    if !player.play() {
                        self.isSpeaking = false
                        self.audioPlayer = nil
                        self.activeContinuation = nil
                        continuation.resume()
                    }
                }
            } onCancel: {
                Task { @MainActor in
                    self.stop()
                }
            }
        } catch let packError as AIPackError {
            stop()
            throw packError
        } catch {
            stop()
            throw AIPackError.ttsFailed(packName: "Kokoro", underlyingMessage: error.localizedDescription)
        }
    }

    public func stop() {
        appleEngine.stop()
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
        audioPlayer = nil
        isSpeaking = false
        if let continuation = activeContinuation {
            activeContinuation = nil
            continuation.resume()
        }
    }

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
                self.handleDecodeError(for: player, error: error)
            }
        } else {
            let box = AudioPlayerTransferBox(player)
            Task { @MainActor in
                self.handleDecodeError(for: box.player, error: error)
            }
        }
    }

    private func handlePlaybackFinished(for player: AVAudioPlayer) {
        guard self.audioPlayer === player else { return }
        self.isSpeaking = false
        self.audioPlayer = nil
        if let continuation = self.activeContinuation {
            self.activeContinuation = nil
            continuation.resume()
        }
    }

    private func handleDecodeError(for player: AVAudioPlayer, error: (any Error)?) {
        guard self.audioPlayer === player else { return }
        self.isSpeaking = false
        self.audioPlayer = nil
        if let continuation = self.activeContinuation {
            self.activeContinuation = nil
            if let error = error {
                continuation.resume(throwing: AIPackError.ttsFailed(packName: "Kokoro", underlyingMessage: error.localizedDescription))
            } else {
                continuation.resume()
            }
        }
    }

    public func attachPlayerForTesting(_ player: AVAudioPlayer) {
        self.audioPlayer = player
        self.isSpeaking = true
        player.delegate = self
    }
}
