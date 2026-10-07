import Foundation
import Testing
@testable import VocabCraftApp

@Suite("AIPackRegistry Tests")
struct AIPackRegistryTests {
    @Test("Registry initializes with stored pack or fallback default")
    @MainActor
    func testRegistryInitialization() {
        let suiteName = "test_registry_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserSettingsStore(userDefaults: defaults)
        let pack = GeminiCloudPack(settingsStore: store)
        let registry = AIPackRegistry(packs: [pack], settingsStore: store)

        #expect(registry.packCatalog.count == 1)
        #expect(registry.activePackId == .geminiCloud)
    }

    @Test("Registry throws when selecting pack that needs API key")
    @MainActor
    func testSelectPackFailsWhenNotReady() {
        let suiteName = "test_registry_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserSettingsStore(userDefaults: defaults)
        store.geminiApiKey = ""
        let pack = GeminiCloudPack(settingsStore: store)
        let registry = AIPackRegistry(packs: [pack], settingsStore: store)

        #expect(throws: AIPackError.self) {
            try registry.selectPack(.geminiCloud)
        }
    }

    @Test("Registry persists active pack when selection succeeds")
    @MainActor
    func testSelectPackSucceedsWhenReady() throws {
        let suiteName = "test_registry_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserSettingsStore(userDefaults: defaults)
        store.geminiApiKey = "valid-key-xyz"
        let pack = GeminiCloudPack(settingsStore: store)
        let registry = AIPackRegistry(packs: [pack], settingsStore: store)

        try registry.selectPack(.geminiCloud)
        #expect(registry.activePackId == .geminiCloud)
        #expect(store.selectedAIPackId == AIPackIdentifier.geminiCloud.rawValue)
        #expect(registry.activePackIssue == nil)
    }

    @Test("Registry throws noPackAvailable when selecting unknown pack")
    @MainActor
    func testSelectUnknownPackThrows() {
        let suiteName = "test_registry_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserSettingsStore(userDefaults: defaults)
        let registry = AIPackRegistry(packs: [], settingsStore: store)

        #expect(throws: AIPackError.noPackAvailable) {
            try registry.selectPack(.geminiCloud)
        }
    }

    @Test("Failed pack selection does not mutate activePackId or store")
    @MainActor
    func testFailedSelectionPreservesActivePack() {
        let suiteName = "test_registry_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserSettingsStore(userDefaults: defaults)
        store.geminiApiKey = "initial-valid-key"
        let geminiPack = GeminiCloudPack(settingsStore: store)
        let offlinePack = OfflineAIPack(isKokoroReady: { false }, isWhisperReady: { false })
        let registry = AIPackRegistry(packs: [geminiPack, offlinePack], settingsStore: store)

        #expect(registry.activePackId == .geminiCloud)
        #expect(throws: AIPackError.self) {
            try registry.selectPack(.offlineAI)
        }
        #expect(registry.activePackId == .geminiCloud)
        #expect(store.selectedAIPackId == AIPackIdentifier.geminiCloud.rawValue)
    }

    @Test("Active services resolve properly when active pack is ready")
    @MainActor
    func testResolveActiveServicesSucceeds() throws {
        let suiteName = "test_registry_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserSettingsStore(userDefaults: defaults)
        store.geminiApiKey = "test-gemini-key"
        let pack = GeminiCloudPack(settingsStore: store)
        let registry = AIPackRegistry(packs: [pack], settingsStore: store)

        let llm = try registry.resolveActiveLLM()
        let tts = try registry.resolveActiveTTS()
        let stt = try registry.resolveActiveSTT()

        #expect(llm is GeminiLLMProvider)
        #expect(tts is GeminiTTSEngineAdapter)
        #expect(stt is AppleSTTEngineAdapter)
    }

    @Test("Resolving active services throws when pack becomes unready")
    @MainActor
    func testResolveActiveServicesThrowsWhenUnready() {
        let suiteName = "test_registry_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserSettingsStore(userDefaults: defaults)
        store.geminiApiKey = ""
        let pack = GeminiCloudPack(settingsStore: store)
        let registry = AIPackRegistry(packs: [pack], settingsStore: store)

        #expect(throws: AIPackError.apiKeyRequired(providerName: "Google Gemini")) {
            try registry.resolveActiveLLM()
        }
    }

    @Test("Revalidate active pack updates activePackIssue")
    @MainActor
    func testRevalidateActivePackUpdatesIssue() {
        let suiteName = "test_registry_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserSettingsStore(userDefaults: defaults)
        store.geminiApiKey = ""
        let pack = GeminiCloudPack(settingsStore: store)
        let registry = AIPackRegistry(packs: [pack], settingsStore: store)

        #expect(registry.activePackIssue == .apiKeyRequired(providerName: "Google Gemini"))

        store.geminiApiKey = "now-added-key"
        registry.revalidateActivePack()
        #expect(registry.activePackIssue == nil)
    }

    @Test("Pack catalog contains accurate metadata and active indicator")
    @MainActor
    func testPackCatalogMetadata() {
        let suiteName = "test_registry_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserSettingsStore(userDefaults: defaults)
        store.geminiApiKey = "key"
        let geminiPack = GeminiCloudPack(settingsStore: store)
        let offlinePack = OfflineAIPack(isKokoroReady: { true }, isWhisperReady: { true })
        let registry = AIPackRegistry(packs: [geminiPack, offlinePack], settingsStore: store)

        let catalog = registry.packCatalog
        #expect(catalog.count == 2)
        let activeEntry = catalog.first { $0.isActive }
        #expect(activeEntry?.identifier == .geminiCloud)
        #expect(activeEntry?.status == .ready)
    }
}
