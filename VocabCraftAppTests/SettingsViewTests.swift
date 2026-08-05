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
}
