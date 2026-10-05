import AVFoundation
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("WhisperKitSpeechEngine Tests")
struct WhisperKitSpeechEngineTests {
    @Test("WhisperKit engine reports ready status based on model availability")
    @MainActor
    func testModelAvailability() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let manager = OnDemandAIModelManager(modelsDirectory: tempDir)
        let engine = WhisperKitSpeechEngine(modelManager: manager)

        #expect(!engine.isReady)
    }

    @Test("WhisperKit engine buffers PCM audio and transcribes on speech conclusion")
    @MainActor
    func testAudioIngestionAndTranscription() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir.appendingPathComponent("whisper"), withIntermediateDirectories: true)
        try Data("dummy".utf8).write(to: tempDir.appendingPathComponent("whisper/model.bin"))

        let manager = OnDemandAIModelManager(modelsDirectory: tempDir)
        manager.refreshStatus()
        let engine = WhisperKitSpeechEngine(modelManager: manager)

        #expect(engine.isReady)

        let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
        buffer.frameLength = 1024

        engine.ingest(buffer: buffer)
        let transcript = try await engine.transcribeBufferedAudio()
        #expect(!transcript.isEmpty)
    }
}
