import SwiftUI
@testable import VocabCraftApp
import XCTest

@MainActor
final class SettingsViewTests: XCTestCase {
    func testSettingsViewInitialization() {
        let store = UserSettingsStore()
        let tts = MockTextToSpeechService()
        let vm = SettingsViewModel(store: store, ttsService: tts)
        let view = SettingsView(viewModel: vm)
        XCTAssertNotNil(view.body)
    }

    func testProfileHeaderCardInitialization() {
        let card = ProfileHeaderCard(userName: "Hooji N.", userLevel: "B2 Intermediate", streakDays: 14)
        XCTAssertEqual(card.userName, "Hooji N.")
        XCTAssertEqual(card.userLevel, "B2 Intermediate")
        XCTAssertEqual(card.streakDays, 14)
        XCTAssertNotNil(card.body)
    }

    func testSettingsRowViewInitialization() {
        let row = SettingsRowView(iconName: "target", iconColor: .blue, title: "Test Goal") {
            Text("Value")
        }
        XCTAssertEqual(row.title, "Test Goal")
        XCTAssertEqual(row.iconName, "target")
        XCTAssertNotNil(row.body)
    }
}
