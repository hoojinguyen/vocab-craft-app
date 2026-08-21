import SwiftUI
@testable import VocabCraftApp
import XCTest
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class TopicRoadmapViewTests: XCTestCase {
    func testTopicRoadmapViewInstantiation() {
        var backCalled = false
        var selectedStage: SubTopicStage?

        let view = TopicRoadmapView(
            deckId: "deck_daily",
            deckTitle: "Giao Tiếp Hằng Ngày",
            onBack: { backCalled = true },
            onStageSelected: { stage in selectedStage = stage }
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif

        XCTAssertFalse(backCalled)
        XCTAssertNil(selectedStage)
    }

    func testTopicRoadmapViewWithViewModelInjection() async {
        let container = AppContainer.mock
        let vm = container.makeTopicRoadmapViewModel(deckId: "deck_business")
        await vm.loadRoadmap()

        let view = TopicRoadmapView(
            deckId: "deck_business",
            deckTitle: "Công Sở & Kinh Doanh",
            viewModel: vm,
            onBack: {}
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif

        XCTAssertEqual(vm.stages.count, 2)
    }
}
