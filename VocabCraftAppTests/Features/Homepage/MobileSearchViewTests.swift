import SwiftUI
@testable import VocabCraftApp
import XCTest

final class MobileSearchViewTests: XCTestCase {
    func testMobileSearchViewInitialization() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        var voiceTapped = false

        let view = MobileSearchView(
            searchText: binding,
            onVoiceSearchTapped: {
                voiceTapped = true
            }
        )

        XCTAssertEqual(view.searchText, "Hello")
        XCTAssertFalse(voiceTapped)
    }

    func testMobileSearchViewBindingUpdates() {
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })

        let view = MobileSearchView(
            searchText: binding,
            onVoiceSearchTapped: {}
        )

        view.searchText = "Vocab"
        XCTAssertEqual(text, "Vocab")
    }

    func testMobileSearchViewVoiceSearchCallbackTrigger() {
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })
        var voiceTapped = false

        let view = MobileSearchView(
            searchText: binding,
            onVoiceSearchTapped: {
                voiceTapped = true
            }
        )

        view.onVoiceSearchTapped()
        XCTAssertTrue(voiceTapped)
    }
}
