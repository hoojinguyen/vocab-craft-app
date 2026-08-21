import SwiftUI
import XCTest
@testable import VocabCraftApp
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class PersonalVaultViewsTests: XCTestCase {
    let mockWord = PersonalWord(
        id: 1,
        lemma: "Resilience",
        phonetic: "/rɪˈzɪl.jəns/",
        pos: "noun",
        cefrLevel: "B2",
        definitionVi: "Khả năng phục hồi, kiên cường",
        definitionEn: "The capacity to recover quickly from difficulties",
        exampleEn: "Her resilience helped her overcome difficulties.",
        exampleVi: "Sự kiên cường giúp cô ấy vượt qua khó khăn.",
        masteryLevel: 3,
        isBookmarked: true,
        needsReview: true,
        sourceDeckTitle: "Giao Tiếp Hằng Ngày",
        sourceStageTitle: "Chặng 1: Thói quen & Cảm xúc"
    )

    func test_personalVaultHeroCard_withWeakWords_triggersAction() {
        var didTrigger = false
        let metrics = PersonalVaultMetrics(totalWords: 10, needsReviewCount: 3, masteredCount: 5, bookmarkedCount: 2)
        let view = PersonalVaultHeroCard(metrics: metrics, onStartSmartReview: {
            didTrigger = true
        })

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif

        view.onStartSmartReview()
        XCTAssertTrue(didTrigger)
    }

    func test_personalVaultHeroCard_withZeroWeakWords_rendersCleanSummary() {
        let metrics = PersonalVaultMetrics(totalWords: 10, needsReviewCount: 0, masteredCount: 10, bookmarkedCount: 3)
        let view = PersonalVaultHeroCard(metrics: metrics, onStartSmartReview: {})

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif
    }

    func test_personalSearchFilterBar_invokesCallbacks() {
        var query = ""
        var selectedFilter: PersonalVaultFilter = .all
        let metrics = PersonalVaultMetrics(totalWords: 15, needsReviewCount: 3, masteredCount: 8, bookmarkedCount: 4)

        let binding = Binding<String>(
            get: { query },
            set: { query = $0 }
        )

        let view = PersonalSearchFilterBar(
            searchQuery: binding,
            selectedFilter: selectedFilter,
            metrics: metrics,
            onFilterChanged: { filter in
                selectedFilter = filter
            }
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif

        view.onFilterChanged(.needsReview)
        XCTAssertEqual(selectedFilter, .needsReview)
    }

    func test_cleanWordCardView_renderingAndCallbacks() {
        var isExpandedTapped = false
        var isAudioTapped = false
        var isBookmarkTapped = false

        let view = CleanWordCardView(
            word: mockWord,
            isExpanded: true,
            onTap: { isExpandedTapped = true },
            onAudioTap: { isAudioTapped = true },
            onBookmarkTap: { isBookmarkTapped = true }
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif

        view.onTap()
        XCTAssertTrue(isExpandedTapped)

        view.onAudioTap()
        XCTAssertTrue(isAudioTapped)

        view.onBookmarkTap()
        XCTAssertTrue(isBookmarkTapped)
    }

    func test_smartReviewSessionView_initializationAndDismiss() {
        var didDismiss = false
        let container = AppContainer.mock
        let viewModel = SmartReviewViewModel(
            weakWords: [mockWord],
            reviewUseCase: container.reviewWeakWordsUseCase,
            ttsService: container.ttsService
        )

        let view = SmartReviewSessionView(
            viewModel: viewModel,
            onDismiss: { didDismiss = true }
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif

        view.onDismiss()
        XCTAssertTrue(didDismiss)
    }
}
