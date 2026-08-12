@testable import VocabCraftApp
import XCTest

@MainActor
final class SettingsViewModelTests: XCTestCase {
    private func makeSUT() -> SettingsViewModel {
        let store = UserSettingsStore()
        let tts = MockTextToSpeechService()
        return SettingsViewModel(store: store, ttsService: tts)
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

    func testResetSRSProgress() {
        let vm = makeSUT()
        vm.store.dailyGoalCount = 30
        vm.resetSRSProgress()
        XCTAssertEqual(vm.store.dailyGoalCount, 15)
    }
}
