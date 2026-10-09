import Foundation
import os
import SherpaOnnx

public enum SherpaKokoroError: LocalizedError, Sendable {
    case missingRequiredFiles(String)
    case engineCreationFailed(String)
    case notInitialized
    case generationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .missingRequiredFiles(let detail):
            return "Kokoro model files are missing or incomplete: \(detail)"
        case .engineCreationFailed(let detail):
            return "Failed to initialize Sherpa-ONNX TTS engine: \(detail)"
        case .notInitialized:
            return "Sherpa-ONNX TTS engine is not initialized."
        case .generationFailed(let detail):
            return "Sherpa-ONNX speech synthesis failed: \(detail)"
        }
    }
}

public final class SherpaKokoroTTSWrapper: @unchecked Sendable {
    private static let logger = Logger(subsystem: "com.hoojinguyen.vocabcraft.speechkit", category: "SherpaKokoroTTS")

    private var tts: SherpaOnnxOfflineTtsWrapper?
    private let lock = NSLock()

    public init() {}

    public var isInitialized: Bool {
        lock.lock()
        defer { lock.unlock() }
        return tts != nil
    }

    public func initialize(modelDirectory: URL) throws {
        lock.lock()
        defer { lock.unlock() }

        if tts != nil { return }

        let modelPath = modelDirectory.appendingPathComponent("model.onnx").path
        let voicesPath = modelDirectory.appendingPathComponent("voices.bin").path
        let tokensPath = modelDirectory.appendingPathComponent("tokens.txt").path
        let dataDirPath = modelDirectory.appendingPathComponent("espeak-ng-data").path

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: modelPath),
              fileManager.fileExists(atPath: voicesPath),
              fileManager.fileExists(atPath: tokensPath),
              fileManager.fileExists(atPath: dataDirPath) else {
            throw SherpaKokoroError.missingRequiredFiles(modelDirectory.path)
        }

        let kokoro = sherpaOnnxOfflineTtsKokoroModelConfig(
            model: modelPath,
            voices: voicesPath,
            tokens: tokensPath,
            dataDir: dataDirPath,
            lengthScale: 1.0
        )
        let modelConfig = sherpaOnnxOfflineTtsModelConfig(kokoro: kokoro, debug: 0)
        var ttsConfig = sherpaOnnxOfflineTtsConfig(model: modelConfig)

        let engine = SherpaOnnxOfflineTtsWrapper(config: &ttsConfig)
        guard engine.tts != nil else {
            throw SherpaKokoroError.engineCreationFailed("Failed to allocate SherpaOnnxOfflineTts engine")
        }

        self.tts = engine
        Self.logger.info("SherpaKokoroTTSWrapper initialized successfully at \(modelDirectory.path)")
    }

    public func generate(text: String, speakerId: Int = 0, speed: Float = 1.0) throws -> [Float] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        lock.lock()
        guard let engine = self.tts else {
            lock.unlock()
            throw SherpaKokoroError.notInitialized
        }
        lock.unlock()

        let audio = engine.generate(text: trimmed, sid: speakerId, speed: speed)
        guard audio.audio != nil else {
            throw SherpaKokoroError.generationFailed("No audio generated for text: \(trimmed)")
        }

        return audio.samples
    }

    public func unload() {
        lock.lock()
        defer { lock.unlock() }
        tts = nil
        Self.logger.info("SherpaKokoroTTSWrapper unloaded model memory")
    }
}
