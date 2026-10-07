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
    private var simulatedTranscript: String?

    public init(modelManager: OnDemandAIModelManager = .shared, simulatedTranscript: String? = nil) {
        self.modelManager = modelManager
        self.simulatedTranscript = simulatedTranscript
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
        clearBuffer()
        if let simulated = simulatedTranscript {
            return simulated
        }
        // In uncompiled mode without CoreML Whisper pipeline, return empty string
        // so that the primary live transcript from SFSpeechRecognizer is safely preserved.
        return ""
    }

    public func startListening(
        onResult: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        if let simulated = simulatedTranscript {
            onResult(simulated)
        }
    }

    public func stopListening() {
        clearBuffer()
    }
}
