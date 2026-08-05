import XCTest
import SwiftUI
@testable import VocabCraftApp

final class VocabularyViewTests: XCTestCase {
    func testVocabularyViewInitializationAndTabSwitch() {
        let view = VocabularyView()
        XCTAssertNotNil(view.body)
    }
}
