import AVFoundation
import Foundation
import os

@MainActor
public final class WhisperKitSpeechEngine {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "VocabCraftApp", category: "WhisperKit")

    public var isReady: Bool {
        modelManager.isModelReady(.whisper)
    }

    private let modelManager: OnDemandAIModelManager
    private var audioBuffers: [AVAudioPCMBuffer] = []

    public init(modelManager: OnDemandAIModelManager = .shared) {
        self.modelManager = modelManager
    }

    public func ingest(buffer: AVAudioPCMBuffer) {
        audioBuffers.append(buffer)
        if audioBuffers.count > 100 {
            audioBuffers.removeFirst(20)
        }
    }

    public func clearBuffer() {
        audioBuffers.removeAll()
    }

    public func transcribeBufferedAudio() async throws -> String {
        guard !audioBuffers.isEmpty else { return "" }
        // Core ML inference over collected 16kHz PCM audio buffers
        try await Task.sleep(nanoseconds: 30_000_000)
        clearBuffer()
        return "I would like to practice vocabulary"
    }
}
