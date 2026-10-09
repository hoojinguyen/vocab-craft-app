import Foundation
import os
import SpeechKit

/// Abstraction protocol for sherpa-onnx runtime synthesis.
public protocol SherpaOnnxOfflineTtsWrapper: Sendable {
    func initialize(modelDirectory: URL) throws
    func generate(text: String, speakerId: Int, speed: Float) throws -> [Float]
    func unload()
}

public extension SherpaOnnxOfflineTtsWrapper {
    func unload() {}
}

extension SherpaKokoroTTSWrapper: SherpaOnnxOfflineTtsWrapper {}

/// Background actor handling model loading and 24kHz PCM sample generation for Kokoro TTS.
public actor KokoroInferenceWorker {
    public static let sampleRate: Int = 24000
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "VocabCraftApp", category: "KokoroInference")

    public static let requiredModelFiles = [
        "model.onnx",
        "voices.bin",
        "tokens.txt",
        "espeak-ng-data"
    ]

    private let modelDirectory: URL
    private let ttsWrapper: (any SherpaOnnxOfflineTtsWrapper)?
    private var isInitialized: Bool = false

    public init(
        modelDirectory: URL? = nil,
        ttsWrapper: (any SherpaOnnxOfflineTtsWrapper)? = nil
    ) {
        if let dir = modelDirectory {
            self.modelDirectory = dir
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
            self.modelDirectory = appSupport.appendingPathComponent("VocabCraft/AIModels/kokoro", isDirectory: true)
        }
        self.ttsWrapper = ttsWrapper ?? SherpaKokoroTTSWrapper()
    }

    public var isModelReady: Bool {
        Self.requiredModelFiles.allSatisfy {
            FileManager.default.fileExists(atPath: modelDirectory.appendingPathComponent($0).path)
        }
    }

    public func loadModelIfNeeded() throws {
        guard !isInitialized else { return }
        guard isModelReady else {
            throw AIPackError.downloadRequired(packName: "Kokoro TTS", sizeDescription: "~85MB")
        }
        if let wrapper = ttsWrapper {
            do {
                try wrapper.initialize(modelDirectory: modelDirectory)
            } catch let error as AIPackError {
                throw error
            } catch {
                Self.logger.error("KokoroInferenceWorker failed to initialize TTS wrapper: \(error.localizedDescription)")
                throw AIPackError.ttsFailed(packName: "Kokoro TTS", underlyingMessage: error.localizedDescription)
            }
        }
        isInitialized = true
        Self.logger.info("KokoroInferenceWorker initialized successfully at \(self.modelDirectory.path)")
    }

    public func unload() {
        ttsWrapper?.unload()
        isInitialized = false
        Self.logger.info("KokoroInferenceWorker unloaded model")
    }

    /// Generates raw 24kHz mono PCM float samples off the main thread.
    public func generateSamples(text: String, speakerId: Int = 0, speed: Float = 1.0) throws -> [Float] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        try loadModelIfNeeded()

        if let wrapper = ttsWrapper {
            do {
                return try wrapper.generate(text: trimmed, speakerId: speakerId, speed: speed)
            } catch let error as AIPackError {
                throw error
            } catch {
                Self.logger.error("KokoroInferenceWorker synthesis failed: \(error.localizedDescription)")
                throw AIPackError.ttsFailed(packName: "Kokoro TTS", underlyingMessage: error.localizedDescription)
            }
        }

        throw AIPackError.ttsFailed(packName: "Kokoro TTS", underlyingMessage: "No TTS wrapper available")
    }

    /// Generates standard 24kHz 16-bit mono WAV Data container for the synthesized text.
    public func generateAudioData(text: String, speakerId: Int = 0, speed: Float = 1.0) throws -> Data {
        let samples = try generateSamples(text: text, speakerId: speakerId, speed: speed)
        guard !samples.isEmpty else { return Data() }
        return Self.convertSamplesToWAV(samples: samples, sampleRate: Self.sampleRate)
    }

    /// Produces clean synthesized 24kHz PCM tone data tailored to speaker characteristics.
    /// Retained solely for audio pipeline unit test verification fixtures.
    public static func synthesizeToneSamples(text: String, speakerId: Int = 0, speed: Float = 1.0) -> [Float] {
        let rate = Double(sampleRate)
        let effectiveSpeed = max(0.5, Double(speed))
        let duration = max(0.1, min(1.5, Double(text.count) * 0.04)) / effectiveSpeed
        let sampleCount = max(240, Int(rate * duration))

        let baseFreq: Double
        switch speakerId {
        case 0: baseFreq = 330.0  // af_bella (Nova, Warm Female)
        case 1: baseFreq = 370.0  // af_sarah (Sarah, Expressive Female)
        case 2: baseFreq = 220.0  // am_adam (Orion, Natural Male)
        case 3: baseFreq = 196.0  // am_michael (Michael, Authoritative Male)
        default: baseFreq = 300.0
        }

        var samples = [Float](repeating: 0, count: sampleCount)
        let twoPi = 2.0 * Double.pi
        let attackCount = min(sampleCount / 4, Int(rate * 0.010))
        let decayCount = min(sampleCount / 4, Int(rate * 0.015))

        for index in 0..<sampleCount {
            let time = Double(index) / rate
            var envelope = 1.0
            if index < attackCount {
                envelope = Double(index) / Double(max(1, attackCount))
            } else if index > sampleCount - decayCount {
                envelope = Double(sampleCount - index) / Double(max(1, decayCount))
            }

            let primary = sin(twoPi * baseFreq * time) * 0.3
            let harmonic = sin(twoPi * (baseFreq * 2.0) * time) * 0.05
            samples[index] = Float((primary + harmonic) * envelope)
        }

        return samples
    }

    /// Converts raw [Float] PCM samples to a standard 44-byte RIFF WAV container (16-bit mono PCM).
    public static func convertSamplesToWAV(samples: [Float], sampleRate: Int = 24000) -> Data {
        let numChannels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let byteRate: UInt32 = UInt32(sampleRate) * UInt32(numChannels) * UInt32(bitsPerSample / 8)
        let blockAlign: UInt16 = numChannels * (bitsPerSample / 8)
        let subchunk2Size: UInt32 = UInt32(samples.count * 2)
        let chunkSize: UInt32 = 36 + subchunk2Size

        var data = Data(capacity: 44 + Int(subchunk2Size))

        // RIFF header
        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        var chunkSizeLE = chunkSize.littleEndian
        data.append(Data(bytes: &chunkSizeLE, count: 4))
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"

        // "fmt " subchunk
        data.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        var subchunk1Size: UInt32 = UInt32(16).littleEndian
        data.append(Data(bytes: &subchunk1Size, count: 4))
        var audioFormat: UInt16 = UInt16(1).littleEndian // PCM
        data.append(Data(bytes: &audioFormat, count: 2))
        var channelsLE = numChannels.littleEndian
        data.append(Data(bytes: &channelsLE, count: 2))
        var sampleRateLE = UInt32(sampleRate).littleEndian
        data.append(Data(bytes: &sampleRateLE, count: 4))
        var byteRateLE = byteRate.littleEndian
        data.append(Data(bytes: &byteRateLE, count: 4))
        var blockAlignLE = blockAlign.littleEndian
        data.append(Data(bytes: &blockAlignLE, count: 2))
        var bitsPerSampleLE = bitsPerSample.littleEndian
        data.append(Data(bytes: &bitsPerSampleLE, count: 2))

        // "data" subchunk
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        var subchunk2SizeLE = subchunk2Size.littleEndian
        data.append(Data(bytes: &subchunk2SizeLE, count: 4))

        // PCM 16-bit little-endian samples
        for sample in samples {
            let clamped = max(-1.0, min(1.0, sample))
            let intSample: Int16
            if clamped < 0 {
                intSample = Int16(clamped * 32768.0)
            } else {
                intSample = Int16(clamped * 32767.0)
            }
            var leSample = intSample.littleEndian
            data.append(Data(bytes: &leSample, count: 2))
        }

        return data
    }

    public static func speakerId(for persona: VoicePersona) -> Int {
        switch persona {
        case .friendlyFemale: return 0 // af_bella (Nova)
        case .expressiveFemale: return 1 // af_sarah (Sarah)
        case .friendlyMale: return 2 // am_adam (Orion)
        case .authoritativeMale: return 3 // am_michael (Michael)
        }
    }

    public static func speakerId(for name: String) -> Int {
        switch name.lowercased() {
        case "af_bella", "nova", "kokoro-nova": return 0
        case "af_sarah", "sarah", "kokoro-sarah": return 1
        case "am_adam", "orion", "kokoro-orion": return 2
        case "am_michael", "michael", "kokoro-michael": return 3
        default: return 0
        }
    }

    public static func speakerName(for persona: VoicePersona) -> String {
        switch persona {
        case .friendlyFemale: return "af_bella"
        case .friendlyMale: return "am_adam"
        case .expressiveFemale: return "af_sarah"
        case .authoritativeMale: return "am_michael"
        }
    }
}
