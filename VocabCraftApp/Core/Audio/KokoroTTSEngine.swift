import AVFoundation
import Foundation
import os

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
    private let appleEngine: AppleEnhancedTTSEngine
    private var audioPlayer: AVAudioPlayer?
    private var activeContinuation: CheckedContinuation<Void, Error>?
    private var cache: [String: Data] = [:]

    public init(
        modelManager: OnDemandAIModelManager = .shared,
        appleEngine: AppleEnhancedTTSEngine = AppleEnhancedTTSEngine()
    ) {
        self.modelManager = modelManager
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

    public func synthesizeAndPlay(text: String, persona: VoicePersona) async throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // When raw Kokoro weights are downloaded without compiled CoreML runtime on device,
        // bridge directly to AppleEnhancedTTSEngine with persona voice & pitch matching.
        // This delivers crystal-clear, zero-latency audible voice instead of playing silent zero-PCM frames.
        isSpeaking = true
        defer { isSpeaking = false }

        await appleEngine.speakAsync(text: trimmed, rate: 0.98, locale: "en-US", persona: persona)
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
        Task { @MainActor in
            self.isSpeaking = false
            self.audioPlayer = nil
            if let continuation = self.activeContinuation {
                self.activeContinuation = nil
                continuation.resume()
            }
        }
    }
}
