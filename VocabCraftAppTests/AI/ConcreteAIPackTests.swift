import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Concrete AI Packs Tests")
@MainActor
struct ConcreteAIPackTests {
    @Test("GeminiCloudPack reports needsApiKey when key is missing")
    func testGeminiPackNeedsApiKey() {
        let suiteName = "test_gemini_pack_\(UUID().uuidString)"
        let store = UserSettingsStore(userDefaults: UserDefaults(suiteName: suiteName)!)
        store.geminiApiKey = ""
        let pack = GeminiCloudPack(settingsStore: store)
        #expect(pack.status == .needsApiKey(providerName: "Google Gemini"))
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    @Test("GeminiCloudPack reports ready when key is present")
    func testGeminiPackReady() {
        let suiteName = "test_gemini_pack_ready_\(UUID().uuidString)"
        let store = UserSettingsStore(userDefaults: UserDefaults(suiteName: suiteName)!)
        store.geminiApiKey = "test-api-key-123"
        let pack = GeminiCloudPack(settingsStore: store)
        #expect(pack.status == .ready)
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    @Test("GeminiCloudPack resolves providers correctly when configured")
    func testGeminiPackResolvesProviders() throws {
        let suiteName = "test_gemini_pack_resolve_\(UUID().uuidString)"
        let store = UserSettingsStore(userDefaults: UserDefaults(suiteName: suiteName)!)
        store.geminiApiKey = "test-api-key-123"
        let pack = GeminiCloudPack(settingsStore: store)
        #expect(pack.identifier == .geminiCloud)
        #expect(pack.supportedVoices.count >= 2)
        #expect(pack.defaultVoice.id == "gemini-aoede")

        let llm = try pack.makeLLMProvider()
        #expect(llm.providerIdentifier == "gemini-flash")

        let tts = try pack.makeTTSEngine()
        #expect(tts.engineName == "Gemini Studio TTS")

        let stt = try pack.makeSTTEngine()
        #expect(stt.engineName == "Apple Speech Recognition")
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    @Test("GeminiCloudPack fails fast when resolving without API key")
    func testGeminiPackResolvingWithoutKeyThrows() {
        let suiteName = "test_gemini_pack_nokey_\(UUID().uuidString)"
        let store = UserSettingsStore(userDefaults: UserDefaults(suiteName: suiteName)!)
        store.geminiApiKey = ""
        let pack = GeminiCloudPack(settingsStore: store)

        #expect(throws: AIPackError.apiKeyRequired(providerName: "Google Gemini")) {
            try pack.makeLLMProvider()
        }
        #expect(throws: AIPackError.apiKeyRequired(providerName: "Google Gemini")) {
            try pack.makeTTSEngine()
        }
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    @Test("OfflineAIPack reports needsDownload with ~975MB when any model is missing")
    func testOfflineAIPackCombinedStatus() {
        let missingLlama = OfflineAIPack(
            isKokoroReady: { true },
            isWhisperReady: { true },
            isLlamaReady: { false }
        )
        #expect(missingLlama.status == .needsDownload(sizeDescription: "~975MB"))

        let missingKokoro = OfflineAIPack(
            isKokoroReady: { false },
            isWhisperReady: { true },
            isLlamaReady: { true }
        )
        #expect(missingKokoro.status == .needsDownload(sizeDescription: "~975MB"))

        let missingWhisper = OfflineAIPack(
            isKokoroReady: { true },
            isWhisperReady: { false },
            isLlamaReady: { true }
        )
        #expect(missingWhisper.status == .needsDownload(sizeDescription: "~975MB"))

        let allReady = OfflineAIPack(
            isKokoroReady: { true },
            isWhisperReady: { true },
            isLlamaReady: { true }
        )
        #expect(allReady.status == .ready)
    }

    @Test("OfflineAIPack makeLLMProvider throws downloadRequired when Llama is not downloaded")
    func testOfflineAIPackLLMThrowsWhenNotDownloaded() {
        let pack = OfflineAIPack(
            isKokoroReady: { true },
            isWhisperReady: { true },
            isLlamaReady: { false }
        )
        #expect(throws: AIPackError.downloadRequired(packName: "Llama 3.2 1B", sizeDescription: "~740MB")) {
            try pack.makeLLMProvider()
        }
    }

    @Test("OfflineAIPack reports needsDownload when models are not downloaded")
    func testOfflinePackNeedsDownload() {
        let pack = OfflineAIPack(
            isKokoroReady: { false },
            isWhisperReady: { false },
            isLlamaReady: { false }
        )
        if case .needsDownload(let size) = pack.status {
            #expect(size == "~975MB")
        } else {
            Issue.record("Expected .needsDownload status for OfflineAIPack")
        }
    }

    @Test("OfflineAIPack reports ready when all models are ready")
    func testOfflinePackReady() {
        let pack = OfflineAIPack(
            isKokoroReady: { true },
            isWhisperReady: { true },
            isLlamaReady: { true }
        )
        #expect(pack.status == .ready)
        #expect(pack.identifier == .offlineAI)
        #expect(pack.defaultVoice.id == "kokoro-nova")
    }

    @Test("OfflineAIPack provides Nova, Orion, Sarah, and Michael neural voices")
    func testOfflineAIPackSupportedVoices() {
        let pack = OfflineAIPack(
            isKokoroReady: { true },
            isWhisperReady: { true },
            isLlamaReady: { true }
        )
        let voices = pack.supportedVoices
        #expect(voices.count == 4)

        let nova = voices.first(where: { $0.id == "kokoro-nova" })
        #expect(nova?.displayName == "Nova (af_bella)")
        #expect(nova?.voiceConfig.gender == .female)
        #expect(nova?.voiceConfig.style == .friendly)
        #expect(nova?.sampleText == "Hello! I'm Nova, your AI practice partner.")

        let orion = voices.first(where: { $0.id == "kokoro-orion" })
        #expect(orion?.displayName == "Orion (am_adam)")
        #expect(orion?.voiceConfig.gender == .male)
        #expect(orion?.voiceConfig.style == .friendly)
        #expect(orion?.sampleText == "Hey there! Orion here, ready to help you practice.")

        let sarah = voices.first(where: { $0.id == "kokoro-sarah" })
        #expect(sarah?.displayName == "Sarah (af_sarah)")
        #expect(sarah?.voiceConfig.gender == .female)
        #expect(sarah?.voiceConfig.style == .expressive)
        #expect(sarah?.sampleText == "Hi! I'm Sarah, excited to explore new vocabulary with you.")

        let michael = voices.first(where: { $0.id == "kokoro-michael" })
        #expect(michael?.displayName == "Michael (am_michael)")
        #expect(michael?.voiceConfig.gender == .male)
        #expect(michael?.voiceConfig.style == .authoritative)
        #expect(michael?.sampleText == "Greetings. Michael here, let's strengthen your language skills.")

        #expect(pack.defaultVoice == nova)
    }

    @Test("OfflineAIPack fails fast when creating engines without downloaded models")
    func testOfflinePackThrowsWhenEnginesNotDownloaded() {
        let pack = OfflineAIPack(
            isKokoroReady: { false },
            isWhisperReady: { false },
            isLlamaReady: { false }
        )
        #expect(throws: AIPackError.downloadRequired(packName: "Kokoro TTS", sizeDescription: "~85MB")) {
            try pack.makeTTSEngine()
        }
        #expect(throws: AIPackError.downloadRequired(packName: "WhisperKit", sizeDescription: "~150MB")) {
            try pack.makeSTTEngine()
        }
        #expect(throws: AIPackError.downloadRequired(packName: "Llama 3.2 1B", sizeDescription: "~740MB")) {
            try pack.makeLLMProvider()
        }
    }

    @Test("OfflineAIPack provides working engines when models are downloaded")
    func testOfflinePackProvidesEnginesWhenReady() throws {
        let pack = OfflineAIPack(
            isKokoroReady: { true },
            isWhisperReady: { true },
            isLlamaReady: { true }
        )
        let tts = try pack.makeTTSEngine()
        #expect(tts.engineName == "Kokoro Neural TTS")
        let stt = try pack.makeSTTEngine()
        #expect(stt.engineName == "WhisperKit On-Device STT")
        let llm = try pack.makeLLMProvider()
        #expect(llm.providerIdentifier == "llama-3.2-1b-local")
    }

    @Test("LlamaLocalLLMProvider throws downloadRequired when not ready")
    func testLlamaLocalLLMProviderThrowsDownloadRequiredWhenNotReady() async {
        let provider = LlamaLocalLLMProvider(isReadyProvider: { false })
        do {
            let _: RoleplayTurnOutput = try await provider.sendStructuredMessage(
                messages: [LLMChatMessage(role: .user, content: "hi")],
                systemPrompt: "sys",
                responseSchema: RoleplayTurnOutput.self
            )
            Issue.record("Expected sendStructuredMessage to throw downloadRequired")
        } catch let error as AIPackError {
            #expect(error == .downloadRequired(packName: "Llama 3.2 1B", sizeDescription: "~740MB"))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("LlamaLocalLLMProvider decodes structured response when worker succeeds")
    func testLlamaLocalLLMProviderDecodesValidResponse() async throws {
        let worker = LlamaInferenceWorker(bypassInferenceForTesting: true)
        let provider = LlamaLocalLLMProvider(worker: worker, isReadyProvider: { true })
        let result: RoleplayTurnOutput = try await provider.sendStructuredMessage(
            messages: [LLMChatMessage(role: .user, content: "Can I have an espresso?")],
            systemPrompt: "You are a barista",
            responseSchema: RoleplayTurnOutput.self
        )
        #expect(!result.characterReply.isEmpty)
        #expect(!result.isConcluded)
    }

    @Test("LlamaLocalLLMProvider rethrows CancellationError untouched")
    func testLlamaLocalLLMProviderRethrowsCancellation() async {
        let task = Task {
            let worker = LlamaInferenceWorker(bypassInferenceForTesting: true)
            let provider = LlamaLocalLLMProvider(worker: worker, isReadyProvider: { true })
            try Task.checkCancellation()
            let _: RoleplayTurnOutput = try await provider.sendStructuredMessage(
                messages: [LLMChatMessage(role: .user, content: "hi")],
                systemPrompt: "sys",
                responseSchema: RoleplayTurnOutput.self
            )
        }
        task.cancel()
        do {
            _ = try await task.value
            Issue.record("Expected task to throw CancellationError")
        } catch is CancellationError {
            // Success: CancellationError propagated directly
        } catch {
            Issue.record("Expected CancellationError but got \(error)")
        }
    }

    @Test("LlamaLocalLLMProvider wraps non-AIPack errors into llmFailed")
    func testLlamaLocalLLMProviderWrapsGenericError() async {
        let worker = LlamaInferenceWorker(bypassInferenceForTesting: true)
        let provider = LlamaLocalLLMProvider(worker: worker, isReadyProvider: { true })
        struct UnmatchedSchema: Decodable, Sendable {
            let requiredMissingField: Int
        }
        do {
            let _: UnmatchedSchema = try await provider.sendStructuredMessage(
                messages: [LLMChatMessage(role: .user, content: "hi")],
                systemPrompt: "sys",
                responseSchema: UnmatchedSchema.self
            )
            Issue.record("Expected sendStructuredMessage to throw llmFailed")
        } catch let error as AIPackError {
            if case .llmFailed(let packName, _) = error {
                #expect(packName == "Offline AI Pack")
            } else {
                Issue.record("Expected .llmFailed, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("AppleDefaultPack provides default configuration and system engines")
    func testAppleDefaultPackConfiguration() throws {
        let pack = AppleDefaultPack()
        #expect(pack.identifier == .appleDefault)
        #expect(pack.defaultVoice.id == "apple-default-female")

        let tts = try pack.makeTTSEngine()
        #expect(tts.engineName == "Apple Enhanced TTS")
        let stt = try pack.makeSTTEngine()
        #expect(stt.engineName == "Apple Speech Recognition")
    }

    @Test("AppleFoundationModelLLMProvider identifies correctly and handles unsupported OS")
    func testAppleFoundationModelProvider() async {
        let provider = AppleFoundationModelLLMProvider()
        #expect(provider.providerIdentifier == "apple-foundation-models")
        do {
            let _: String = try await provider.sendStructuredMessage(
                messages: [LLMChatMessage(role: .user, content: "hi")],
                systemPrompt: "sys",
                responseSchema: String.self
            )
            Issue.record("Expected sendStructuredMessage to throw")
        } catch let error as AIPackError {
            if case .deviceNotSupported = error {
                // Success
            } else {
                Issue.record("Expected .deviceNotSupported, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("KokoroTTSEngineAdapter throws downloadRequired when not ready")
    func testKokoroTTSEngineAdapterThrowsDownloadRequiredWhenNotReady() async {
        let adapter = KokoroTTSEngineAdapter(isReadyProvider: { false })
        let voice = VoiceConfiguration(gender: .female, style: .friendly)
        do {
            try await adapter.synthesizeAndPlay(text: "Hello", voice: voice)
            Issue.record("Expected synthesizeAndPlay to throw downloadRequired")
        } catch let error as AIPackError {
            #expect(error == .downloadRequired(packName: "Kokoro TTS", sizeDescription: "~85MB"))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("KokoroTTSEngineAdapter maps voice configurations to personas and wraps errors without silent fallback")
    func testKokoroTTSEngineAdapterMapsPersonasAndErrors() async throws {
        let mock = MockKokoroSynthesizer()
        let adapter = KokoroTTSEngineAdapter(underlyingEngine: mock, isReadyProvider: { true })

        // 1. Nova (.female, .friendly) -> .friendlyFemale
        try await adapter.synthesizeAndPlay(text: "Hello Nova", voice: VoiceConfiguration(gender: .female, style: .friendly))
        #expect(mock.lastSynthesizedText == "Hello Nova")
        #expect(mock.lastSynthesizedPersona == .friendlyFemale)

        // 2. Orion (.male, .friendly) -> .friendlyMale
        try await adapter.synthesizeAndPlay(text: "Hello Orion", voice: VoiceConfiguration(gender: .male, style: .friendly))
        #expect(mock.lastSynthesizedText == "Hello Orion")
        #expect(mock.lastSynthesizedPersona == .friendlyMale)

        // 3. Sarah (.female, .expressive) -> .expressiveFemale
        try await adapter.synthesizeAndPlay(text: "Hello Sarah", voice: VoiceConfiguration(gender: .female, style: .expressive))
        #expect(mock.lastSynthesizedText == "Hello Sarah")
        #expect(mock.lastSynthesizedPersona == .expressiveFemale)

        // 4. Michael (.male, .authoritative) -> .authoritativeMale
        try await adapter.synthesizeAndPlay(text: "Hello Michael", voice: VoiceConfiguration(gender: .male, style: .authoritative))
        #expect(mock.lastSynthesizedText == "Hello Michael")
        #expect(mock.lastSynthesizedPersona == .authoritativeMale)

        // Error wrapping: Non-AIPackError wrapped into .ttsFailed
        struct DummyPlaybackError: LocalizedError {
            var errorDescription: String? { "Audio output failed" }
        }
        mock.errorToThrow = DummyPlaybackError()
        do {
            try await adapter.synthesizeAndPlay(text: "Fail test", voice: VoiceConfiguration(gender: .female, style: .friendly))
            Issue.record("Expected synthesizeAndPlay to throw")
        } catch let error as AIPackError {
            #expect(error == .ttsFailed(packName: "Offline AI Pack", underlyingMessage: "Audio output failed"))
        }

        // AIPackError rethrown without wrapping
        mock.errorToThrow = AIPackError.downloadRequired(packName: "Kokoro TTS", sizeDescription: "~85MB")
        do {
            try await adapter.synthesizeAndPlay(text: "Fail test", voice: VoiceConfiguration(gender: .female, style: .friendly))
            Issue.record("Expected synthesizeAndPlay to throw downloadRequired")
        } catch let error as AIPackError {
            #expect(error == .downloadRequired(packName: "Kokoro TTS", sizeDescription: "~85MB"))
        }

        // CancellationError rethrown directly without being wrapped into .ttsFailed
        mock.errorToThrow = CancellationError()
        do {
            try await adapter.synthesizeAndPlay(text: "Cancel test", voice: VoiceConfiguration(gender: .female, style: .friendly))
            Issue.record("Expected synthesizeAndPlay to throw CancellationError")
        } catch is CancellationError {
            // Success: CancellationError propagated directly
        } catch {
            Issue.record("Expected CancellationError but got \(error)")
        }
    }
}

@MainActor
private final class MockKokoroSynthesizer: KokoroAudioSynthesizing {
    var isSpeaking: Bool = false
    var isReady: Bool = true
    var lastSynthesizedText: String?
    var lastSynthesizedPersona: VoicePersona?
    var errorToThrow: (any Error)?

    func synthesizeAndPlay(text: String, persona: VoicePersona) async throws {
        lastSynthesizedText = text
        lastSynthesizedPersona = persona
        if let error = errorToThrow {
            throw error
        }
    }

    func stop() {
        isSpeaking = false
    }
}
