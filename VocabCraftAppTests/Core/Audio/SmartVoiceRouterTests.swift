import AVFoundation
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Apple app speech routing")
@MainActor
struct SmartVoiceRouterTests {
    @Test("Conversation stays on Apple even when a Gemini key is stored")
    func appleOnlyWithStoredKey() async throws {
        let suite = "Task2AppleOnly.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = UserSettingsStore(defaults: defaults)
        store.geminiApiKey = "test-unused-key"
        let service = TextToSpeechService(settingsStore: store)
        await service.speakAsync(text: "Hello", context: .conversation())
        #expect(service.lastActiveEngine == .apple)
        #expect(!service.isSpeaking)
    }

    @Test("Selected profile, rate and pitch apply to app pronunciation")
    func selectedAppleProfileAppliesToPronunciation() async throws {
        let suite = "Task2AppleProfile.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = UserSettingsStore(defaults: defaults)
        store.voiceProfileId = "apple-daniel"
        store.speechRate = 1.1
        store.speechPitch = 0.95
        let service = TextToSpeechService(settingsStore: store)
        service.speak(text: "Good day", rate: 0.8, locale: "en-GB")
        await service.playbackStartTask?.value
        let utterance = try #require(service.currentUtterance)
        #expect(utterance.speechString == "Good day")
        #expect(abs(utterance.rate - AVSpeechUtteranceDefaultSpeechRate * 0.98 * 0.8 * 1.1) < 0.001)
        #expect(abs(utterance.pitchMultiplier - 0.95) < 0.001)
        #expect(service.lastActiveEngine == .apple)
        service.stop()
        await service.playbackReleaseTask?.value
        #expect(!service.isSpeaking)
    }

    @Test("Cancelled asynchronous speech releases state and leases")
    func cancelledSpeechReleasesState() async {
        let coordinator = AudioSessionCoordinator()
        let service = TextToSpeechService(audioSessionCoordinator: coordinator)
        let task = Task { await service.speakAsync(text: "Cancelled speech") }
        task.cancel()
        await task.value
        await service.playbackReleaseTask?.value
        #expect(!service.isSpeaking)
        #expect(await coordinator.activeLeaseCount == 0)
    }

    @Test("Cancelled voice preview releases state and leases")
    func cancelledPreviewReleasesState() async {
        let coordinator = AudioSessionCoordinator()
        let service = TextToSpeechService(audioSessionCoordinator: coordinator)
        let task = Task { await service.previewVoice(profile: VoiceProfileCatalog.defaultProfile) }
        task.cancel()
        await task.value
        await service.playbackReleaseTask?.value
        #expect(!service.isSpeaking)
        #expect(await coordinator.activeLeaseCount == 0)
    }

    @Test("Every selectable voice can preview and release its playback lease")
    func previewsReleasePlayback() async {
        let coordinator = AudioSessionCoordinator()
        let service = TextToSpeechService(audioSessionCoordinator: coordinator)
        for profile in VoiceProfileCatalog.profiles {
            await service.previewVoice(profile: profile, rate: 0.9, pitch: 1.05)
            #expect(service.lastActiveEngine == .apple)
            #expect(!service.isSpeaking)
            #expect(await coordinator.activeLeaseCount == 0)
        }
    }
}
