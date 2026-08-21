@testable import VocabCraftApp
import XCTest

public final class MockResetUserProgressUseCase: ResetUserProgressUseCaseProtocol, @unchecked Sendable {
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
}
