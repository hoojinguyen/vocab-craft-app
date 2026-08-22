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
        XCTAssertNotNil(view.viewModel)
    }

    func testProfileHeaderCardInitialization() {
        let card = ProfileHeaderCard(userName: "Hooji N.", userLevel: "B2 Intermediate", streakDays: 14)
        XCTAssertEqual(card.userName, "Hooji N.")
        XCTAssertEqual(card.userLevel, "B2 Intermediate")
        XCTAssertEqual(card.streakDays, 14)
    }

    func testSettingsRowViewInitialization() {
        let row = SettingsRowView(iconName: "target", iconColor: .blue, title: "Test Goal") {
            Text("Value")
        }
        XCTAssertEqual(row.title, "Test Goal")
        XCTAssertEqual(row.iconName, "target")
    }

    func testSettingsViewBodyRendering() {
        let store = UserSettingsStore()
        let tts = MockTextToSpeechService()
        let vm = SettingsViewModel(store: store, ttsService: tts)
        let view = SettingsView(viewModel: vm)
        let body = view.body
        XCTAssertNotNil(body)
    }

    func testSettingsViewNotificationEnabledBodyRendering() {
        let store = UserSettingsStore()
        store.isNotificationEnabled = true
        let tts = MockTextToSpeechService()
        let vm = SettingsViewModel(store: store, ttsService: tts)
        let view = SettingsView(viewModel: vm)
        let body = view.body
        XCTAssertNotNil(body)
    }
}
