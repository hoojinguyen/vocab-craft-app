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
        let simulatedEngine = WhisperKitSpeechEngine(modelManager: manager, simulatedTranscript: "I want a croissant")
        #expect(simulatedEngine.isReady)

        let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
        buffer.frameLength = 1024

        simulatedEngine.ingest(buffer: buffer)
        let simulatedTranscript = try await simulatedEngine.transcribeBufferedAudio()
        #expect(simulatedTranscript == "I want a croissant")

        let defaultEngine = WhisperKitSpeechEngine(modelManager: manager)
        defaultEngine.ingest(buffer: buffer)
        let defaultTranscript = try await defaultEngine.transcribeBufferedAudio()
        #expect(defaultTranscript.isEmpty)
    }

    @Test("WhisperKit engine starts listening and yields simulated transcript")
    @MainActor
    func testStartListeningWithSimulatedTranscript() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let manager = OnDemandAIModelManager(modelsDirectory: tempDir)
        let simulatedEngine = WhisperKitSpeechEngine(modelManager: manager, simulatedTranscript: "Good morning")

        var received: String?
        simulatedEngine.startListening(
            onResult: { text in received = text },
            onError: { _ in }
        )
        simulatedEngine.stopListening()

        #expect(received == "Good morning")
    }
}
