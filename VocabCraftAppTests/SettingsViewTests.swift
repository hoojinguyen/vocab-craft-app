import XCTest
import SwiftUI
@testable import VocabCraftApp

@MainActor
final class SettingsViewTests: XCTestCase {
    func testSettingsViewInitialization() {
        let vm = SettingsViewModel()
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
