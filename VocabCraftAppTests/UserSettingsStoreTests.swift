import XCTest
@testable import VocabCraftApp

final class UserSettingsStoreTests: XCTestCase {
    func testDefaultUserSettingsValues() {
        let store = UserSettingsStore()
        XCTAssertEqual(store.dailyGoalCount, 15)
        XCTAssertEqual(store.ttsVoiceGender, "US")
        XCTAssertEqual(store.ttsSpeed, 0.85)
        XCTAssertTrue(store.isHapticsEnabled)
        XCTAssertTrue(store.isSoundEffectsEnabled)
    }
}
