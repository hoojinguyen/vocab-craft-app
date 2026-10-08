import AVFoundation
import Foundation
import Testing
@testable import VocabCraftApp

final class MockKokoroAudioEngine: KokoroAudioSynthesizing, @unchecked Sendable {
    var isSpeaking: Bool = false
    var isReady: Bool = true
    var synthesizeCallCount: Int = 0
    var lastSynthesizedText: String?
    var lastPersona: VoicePersona?

    func synthesizeAndPlay(text: String, persona: VoicePersona) async throws {
        synthesizeCallCount += 1
        lastSynthesizedText = text
        lastPersona = persona
        isSpeaking = true
    }

    func stop() {
        isSpeaking = false
    }
}

@Suite("KokoroTTSEngine Router Tests")
struct KokoroTTSEngineRouterTests {
    @Test("TextToSpeechService routes conversation to Kokoro engine when ready")
    @MainActor
    func testRoutesToKokoroWhenReady() async {
        let mockKokoro = MockKokoroAudioEngine()
        let mockApple = AppleEnhancedTTSEngine()
        let coordinator = AudioSessionCoordinator()
        let tts = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            appleEngine: mockApple,
            kokoroEngine: mockKokoro
        )

        await tts.speakAsync(text: "Hello from Kokoro!", context: .conversation(persona: .friendlyFemale, locale: "en-US"))

        #expect(mockKokoro.synthesizeCallCount == 1)
        #expect(mockKokoro.lastSynthesizedText == "Hello from Kokoro!")
        #expect(mockKokoro.lastPersona == .friendlyFemale)
        #expect(tts.lastActiveEngine == .kokoro)
    }

    @Test("TextToSpeechService falls back to AppleEngine when Kokoro is not ready")
    @MainActor
    func testFallbackToAppleWhenKokoroNotReady() async {
        let mockKokoro = MockKokoroAudioEngine()
        mockKokoro.isReady = false
        let mockApple = AppleEnhancedTTSEngine()
        let coordinator = AudioSessionCoordinator()
        let tts = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            appleEngine: mockApple,
            kokoroEngine: mockKokoro
        )

        await tts.speakAsync(text: "Fallback test", context: .conversation(persona: .friendlyFemale, locale: "en-US"))

        #expect(mockKokoro.synthesizeCallCount == 0)
        #expect(tts.lastActiveEngine == .apple)
    }
}

@Suite("KokoroTTSEngine Tests")
struct KokoroTTSEngineTests {
    private func createReadyModelDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let kokoroDir = tempDir.appendingPathComponent("kokoro")
        try FileManager.default.createDirectory(at: kokoroDir, withIntermediateDirectories: true)
        let required = ["model.onnx", "voices.bin", "tokens.txt", "espeak-ng-data"]
        for file in required {
            let path = kokoroDir.appendingPathComponent(file)
            if file == "espeak-ng-data" {
                try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
            } else {
                try "dummy".write(to: path, atomically: true, encoding: .utf8)
            }
        }
        return tempDir
    }

    @Test("Voice profile mapping maps personas to valid Kokoro speaker names")
    @MainActor
    func testVoiceProfileMapping() {
        let engine = KokoroTTSEngine()
        #expect(engine.voiceProfile(for: .friendlyFemale) == "af_bella")
        #expect(engine.voiceProfile(for: .friendlyMale) == "am_adam")
        #expect(engine.voiceProfile(for: .expressiveFemale) == "af_sarah")
        #expect(engine.voiceProfile(for: .authoritativeMale) == "am_michael")
    }

    @Test("Speaker ID mapping correctly maps personas and names")
    @MainActor
    func testSpeakerIdMapping() {
        let engine = KokoroTTSEngine()
        #expect(engine.speakerId(for: .friendlyFemale) == 0)
        #expect(engine.speakerId(for: .expressiveFemale) == 1)
        #expect(engine.speakerId(for: .friendlyMale) == 2)
        #expect(engine.speakerId(for: .authoritativeMale) == 3)

        #expect(KokoroInferenceWorker.speakerId(for: "nova") == 0)
        #expect(KokoroInferenceWorker.speakerId(for: "af_bella") == 0)
        #expect(KokoroInferenceWorker.speakerId(for: "sarah") == 1)
        #expect(KokoroInferenceWorker.speakerId(for: "af_sarah") == 1)
        #expect(KokoroInferenceWorker.speakerId(for: "orion") == 2)
        #expect(KokoroInferenceWorker.speakerId(for: "am_adam") == 2)
        #expect(KokoroInferenceWorker.speakerId(for: "michael") == 3)
        #expect(KokoroInferenceWorker.speakerId(for: "am_michael") == 3)
        #expect(KokoroInferenceWorker.speakerId(for: "unknown") == 0)
    }

    @Test("synthesizeAndPlay throws typed downloadRequired error when model is not ready")
    @MainActor
    func testSynthesizeThrowsWhenNotReady() async {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let manager = OnDemandAIModelManager(modelsDirectory: tempDir)
        let engine = KokoroTTSEngine(modelManager: manager)

        #expect(!engine.isReady)
        do {
            try await engine.synthesizeAndPlay(text: "Hello", persona: .friendlyFemale)
            Issue.record("Expected AIPackError.downloadRequired but no error was thrown")
        } catch let error as AIPackError {
            #expect(error == AIPackError.downloadRequired(packName: "Kokoro TTS", sizeDescription: "~85MB"))
        } catch {
            Issue.record("Expected AIPackError but got \(error)")
        }
    }

    @Test("KokoroInferenceWorker converts samples to valid 44-byte WAV header")
    func testWAVHeaderGeneration() throws {
        let samples: [Float] = [0.0, 0.5, -0.5, 1.0, -1.0]
        let wavData = KokoroInferenceWorker.convertSamplesToWAV(samples: samples, sampleRate: 24000)

        #expect(wavData.count == 44 + (samples.count * 2))
        #expect(wavData.prefix(4) == Data([0x52, 0x49, 0x46, 0x46])) // "RIFF"
        #expect(wavData[8..<12] == Data([0x57, 0x41, 0x56, 0x45])) // "WAVE"
        #expect(wavData[12..<16] == Data([0x66, 0x6D, 0x74, 0x20])) // "fmt "
        #expect(wavData[36..<40] == Data([0x64, 0x61, 0x74, 0x61])) // "data"

        let player = try AVAudioPlayer(data: wavData)
        #expect(player.numberOfChannels == 1)
    }

    @Test("KokoroInferenceWorker generates synthesized tone samples when model is ready")
    func testInferenceWorkerGenerateSamples() async throws {
        let tempDir = try createReadyModelDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let kokoroDir = tempDir.appendingPathComponent("kokoro")
        let worker = KokoroInferenceWorker(modelDirectory: kokoroDir)

        let isReady = await worker.isModelReady
        #expect(isReady)

        let samples = try await worker.generateSamples(text: "VocabCraft", speakerId: 0, speed: 1.0)
        #expect(!samples.isEmpty)
        #expect(samples.count >= 240)

        let wavData = try await worker.generateAudioData(text: "VocabCraft", speakerId: 2, speed: 1.0)
        #expect(wavData.count > 44)
    }

    @Test("KokoroInferenceWorker throws downloadRequired when model files are missing")
    func testInferenceWorkerThrowsWhenNotReady() async {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let worker = KokoroInferenceWorker(modelDirectory: tempDir)

        let isReady = await worker.isModelReady
        #expect(!isReady)

        await #expect(throws: AIPackError.self) {
            try await worker.generateSamples(text: "VocabCraft", speakerId: 0, speed: 1.0)
        }
    }

    @Test("synthesizeAndPlay executes playback lifecycle when model is ready")
    @MainActor
    func testSynthesizeAndPlayLifecycleWhenReady() async throws {
        let tempDir = try createReadyModelDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let manager = OnDemandAIModelManager(modelsDirectory: tempDir)
        let engine = KokoroTTSEngine(modelManager: manager)
        #expect(engine.isReady)

        // Empty text is a no-op
        try await engine.synthesizeAndPlay(text: "   ", persona: .friendlyFemale)
        #expect(!engine.isSpeaking)

        // Synthesis with valid text succeeds and halts cleanly
        let task = Task { @MainActor in
            try await engine.synthesizeAndPlay(text: "Hello, VocabCraft!", persona: .friendlyFemale)
        }

        // Allow task to initialize playback
        try await Task.sleep(nanoseconds: 10_000_000)
        engine.stop()
        #expect(!engine.isSpeaking)

        _ = try? await task.value
    }

    @Test("Delegate didFinishPlaying resets state and ignores stale callbacks")
    @MainActor
    func testDelegateDidFinishCallbacks() async throws {
        let samples = KokoroInferenceWorker.synthesizeToneSamples(text: "Test", speakerId: 0, speed: 1.0)
        let wavData = KokoroInferenceWorker.convertSamplesToWAV(samples: samples)
        let activePlayer = try AVAudioPlayer(data: wavData)
        let stalePlayer = try AVAudioPlayer(data: wavData)

        let engine = KokoroTTSEngine()
        engine.attachPlayerForTesting(activePlayer)
        #expect(engine.isSpeaking)

        // Stale player callback should be ignored
        engine.audioPlayerDidFinishPlaying(stalePlayer, successfully: true)
        await Task.yield()
        #expect(engine.isSpeaking)

        // Active player callback resets isSpeaking
        engine.audioPlayerDidFinishPlaying(activePlayer, successfully: true)
        await Task.yield()
        #expect(!engine.isSpeaking)
    }

    @Test("Delegate decodeError resets state and ignores stale callbacks")
    @MainActor
    func testDelegateDecodeErrorCallbacks() async throws {
        let samples = KokoroInferenceWorker.synthesizeToneSamples(text: "Test", speakerId: 0, speed: 1.0)
        let wavData = KokoroInferenceWorker.convertSamplesToWAV(samples: samples)
        let activePlayer = try AVAudioPlayer(data: wavData)
        let stalePlayer = try AVAudioPlayer(data: wavData)

        let engine = KokoroTTSEngine()
        engine.attachPlayerForTesting(activePlayer)
        #expect(engine.isSpeaking)

        // Stale player decode error should be ignored
        engine.audioPlayerDecodeErrorDidOccur(stalePlayer, error: nil)
        await Task.yield()
        #expect(engine.isSpeaking)

        // Active player decode error resets isSpeaking
        engine.audioPlayerDecodeErrorDidOccur(activePlayer, error: nil)
        await Task.yield()
        #expect(!engine.isSpeaking)
    }
}
