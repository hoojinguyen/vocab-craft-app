import XCTest
@testable import VocabCraftApp

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testSettingsViewModelInitialization() {
        let store = UserSettingsStore()
        let vm = SettingsViewModel(store: store)
        XCTAssertFalse(vm.isPlayingAudio)
        XCTAssertEqual(vm.cacheSizeString, "12.4 MB")
    }

    func testClearCache() {
        let vm = SettingsViewModel()
        vm.clearCache()
        XCTAssertEqual(vm.cacheSizeString, "0.0 MB")
    }

    func testAudioPreviewExecution() {
        let vm = SettingsViewModel()
        vm.playAudioPreview()
        XCTAssertTrue(vm.isPlayingAudio)
    }

    func testResetSRSProgress() {
        let vm = SettingsViewModel()
        vm.store.dailyGoalCount = 30
        vm.resetSRSProgress()
        XCTAssertEqual(vm.store.dailyGoalCount, 15)
    }
}
