import Foundation
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

@MainActor
public final class MockResetUserProgressUseCase: ResetUserProgressUseCaseProtocol {
    public var didCallReset: Bool = false
    public var shouldThrowError: Bool = false

    public init() {}

    public func executeResetAllProgress() async throws {
        if shouldThrowError {
            throw NSError(domain: "MockResetUserProgressUseCase", code: -1, userInfo: [NSLocalizedDescriptionKey: "Reset progress failed"])
        }
        didCallReset = true
    }
}

@MainActor
final class SettingsViewModelTests: XCTestCase {
    private func makeSUT(resetProgressUseCase: ResetUserProgressUseCaseProtocol? = nil) -> SettingsViewModel {
        let store = UserSettingsStore()
        let tts = MockTextToSpeechService()
        return SettingsViewModel(store: store, ttsService: tts, resetProgressUseCase: resetProgressUseCase)
    }

    func testLegacyVoiceKeysAreReadAfterRename() throws {
        let suiteName = "Task2VoiceSettings.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("apple-daniel", forKey: "roleplay_voice_id")
        defaults.set(1.1, forKey: "roleplay_speech_rate")
        defaults.set(0.95, forKey: "roleplay_speech_pitch")
        let store = UserSettingsStore(defaults: defaults)
        XCTAssertEqual(store.voiceProfileId, "apple-daniel")
        XCTAssertEqual(store.speechRate, 1.1)
        XCTAssertEqual(store.speechPitch, 0.95)
        store.voiceProfileId = "apple-ava"
        store.speechRate = 0.9
        store.speechPitch = 1.05
        XCTAssertEqual(defaults.string(forKey: "roleplay_voice_id"), "apple-ava")
        XCTAssertEqual(defaults.double(forKey: "roleplay_speech_rate"), 0.9)
        XCTAssertEqual(defaults.double(forKey: "roleplay_speech_pitch"), 1.05)
    }

    func testSettingsViewModelInitialization() {
        let vm = makeSUT()
        XCTAssertFalse(vm.isPlayingAudio)
        XCTAssertEqual(vm.cacheSizeString, "12.4 MB")
    }

    func testClearCache() {
        let vm = makeSUT()
        vm.clearCache()
        XCTAssertEqual(vm.cacheSizeString, "0.0 MB")
    }

    func testAudioPreviewExecution() {
        let vm = makeSUT()
        vm.playAudioPreview()
        XCTAssertTrue(vm.isPlayingAudio)
    }

    func testResetSRSProgress() async {
        let mockUseCase = MockResetUserProgressUseCase()
        let vm = makeSUT(resetProgressUseCase: mockUseCase)
        vm.store.dailyGoalCount = 30
        await vm.resetSRSProgress()
        XCTAssertEqual(vm.store.dailyGoalCount, 15)
        XCTAssertTrue(mockUseCase.didCallReset)
    }

    func testResetSRSProgressCallsUseCase() async throws {
        let mockUseCase = MockResetUserProgressUseCase()
        let store = UserSettingsStore()
        let viewModel = SettingsViewModel(
            store: store,
            ttsService: MockTextToSpeechService(),
            resetProgressUseCase: mockUseCase
        )

        await viewModel.resetSRSProgress()
        XCTAssertTrue(mockUseCase.didCallReset)
    }

    func testRoleplayVoicePreviewExecution() {
        let vm = makeSUT()
        XCTAssertFalse(vm.isPlayingRoleplayAudio)

        vm.playRoleplayVoicePreview()
        XCTAssertTrue(vm.isPlayingRoleplayAudio)

        vm.stopRoleplayVoicePreview()
        XCTAssertFalse(vm.isPlayingRoleplayAudio)
    }

    func testToggleRoleplayVoicePreview() {
        let vm = makeSUT()
        XCTAssertFalse(vm.isPlayingRoleplayAudio)

        vm.playRoleplayVoicePreview()
        XCTAssertTrue(vm.isPlayingRoleplayAudio)

        // Calling again toggles and stops playback
        vm.playRoleplayVoicePreview()
        XCTAssertFalse(vm.isPlayingRoleplayAudio)
    }
}
