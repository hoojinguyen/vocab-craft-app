import CraftUIKit
import SwiftUI
@testable import VocabCraftApp
import XCTest
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

    let mockVaultWord = VaultWordItem(
        id: 10,
        lemma: "meticulous",
        pos: "adj",
        phonetic: "/məˈtɪk.jə.ləs/",
        definitionVi: "Tỉ mỉ, kỹ lưỡng",
        exampleSentenceEn: "She is meticulous about her work.",
        exampleSentenceVi: "Cô ấy rất tỉ mỉ trong công việc của mình.",
        cefrLevel: "C1",
        isMastered: false,
        isBookmarked: true,
        correctStreak: 2,
        practicedModes: [.speaking, .typing],
        lastPracticedAt: Date()
    )

    // MARK: - CraftSegmentedControl in Vault Tests
    func test_vaultCraftSegmentedControl_rendersAndUpdatesSelection() {
        var selectedFilter: VaultTabFilter = .notMastered
        var didCallSelect = false
        var receivedFilter: VaultTabFilter?

        let binding = Binding<VaultTabFilter>(
            get: { selectedFilter },
            set: { selectedFilter = $0 }
        )

        let options: [CraftSegmentOption<VaultTabFilter>] = [
            CraftSegmentOption(.notMastered, title: "Chưa thuộc", count: 12),
            CraftSegmentOption(.mastered, title: "Đã thuộc", count: 8),
            CraftSegmentOption(.bookmarked, title: "Đã lưu", count: 3)
        ]

        let view = CraftSegmentedControl(
            selection: binding,
            options: options,
            style: .glass,
            onSelect: { filter in
                didCallSelect = true
                receivedFilter = filter
            }
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif

        view.onSelect?(.mastered)
        XCTAssertTrue(didCallSelect)
        XCTAssertEqual(receivedFilter, .mastered)
    }

    // MARK: - CraftButton in Vault Tests
    func test_vaultPracticeButton_triggersAction() {
        var didTrigger = false
        let view = CraftButton(
            verbatim: AppStrings.Vault.actionPracticeText,
            variant: .primary,
            size: .lg,
            isFullWidth: true
        ) {
            didTrigger = true
        }

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif

        view.action()
        XCTAssertTrue(didTrigger)
    }

    func test_vaultPracticeButton_withDisabledState_rendersCorrectly() {
        let view = CraftButton(
            verbatim: AppStrings.Vault.actionPracticeText,
            variant: .primary,
            size: .lg,
            isFullWidth: true
        ) {}
        .disabled(true)

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif
    }

    // MARK: - VaultWordRowView Tests (Active Recall)
    func test_vaultWordRowView_activeRecall_callbacksTriggered() {
        var didTapRow = false
        var didTapBookmark = false

        let view = VaultWordRowView(
            word: mockVaultWord,
            onTap: { didTapRow = true },
            onBookmarkTap: { didTapBookmark = true }
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif

        view.onTap()
        XCTAssertTrue(didTapRow)

        view.onBookmarkTap?()
        XCTAssertTrue(didTapBookmark)
    }

    func test_vaultWordRowView_masteredWord_rendersCleanly() {
        let masteredWord = VaultWordItem(
            id: 20,
            lemma: "eloquent",
            pos: "adj",
            phonetic: "/ˈel.ə.kwənt/",
            definitionVi: "Hùng biện, lưu loát",
            cefrLevel: "C1",
            isMastered: true,
            isBookmarked: false,
            correctStreak: 5
        )

        let view = VaultWordRowView(
            word: masteredWord,
            onTap: {},
            onBookmarkTap: {}
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif

        XCTAssertTrue(masteredWord.isMastered)
    }

    // MARK: - VaultWordDetailSheet Tests
    func test_vaultWordDetailSheet_rendersAndTriggersCallbacks() {
        var didPlayAudio = false
        var didToggleBookmark = false

        let view = VaultWordDetailSheet(
            word: mockVaultWord,
            onPlayAudio: { didPlayAudio = true },
            onToggleBookmark: { didToggleBookmark = true }
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif

        view.onPlayAudio()
        XCTAssertTrue(didPlayAudio)

        view.onToggleBookmark()
        XCTAssertTrue(didToggleBookmark)
    }

    func test_vaultWordDetailSheet_masteredWordWithoutBookmark_rendersProperly() {
        let masteredWord = VaultWordItem(
            id: 101,
            lemma: "serendipity",
            pos: "noun",
            phonetic: "/ˌser.ənˈdɪp.ə.ti/",
            definitionVi: "Sự tình cờ may mắn",
            exampleSentenceEn: "Finding this book was pure serendipity.",
            exampleSentenceVi: "Tìm thấy cuốn sách này là một sự may mắn thuần túy.",
            cefrLevel: "C2",
            isMastered: true,
            isBookmarked: false,
            correctStreak: 7,
            practicedModes: [.speaking, .listening, .typing],
            lastPracticedAt: Date()
        )

        let view = VaultWordDetailSheet(
            word: masteredWord,
            onPlayAudio: {},
            onToggleBookmark: {}
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif

        XCTAssertTrue(masteredWord.isMastered)
        XCTAssertFalse(masteredWord.isBookmarked)
    }

    func test_vaultWordDetailSheet_minimalWordWithoutExamplesOrModes_rendersProperly() {
        let minimalWord = VaultWordItem(
            id: 102,
            lemma: "ephemeral",
            pos: "adj",
            phonetic: "/ɪˈfem.ər.əl/",
            definitionVi: "Phù du, chóng tàn",
            exampleSentenceEn: "",
            exampleSentenceVi: "",
            cefrLevel: nil,
            isMastered: false,
            isBookmarked: false,
            correctStreak: 0,
            practicedModes: [],
            lastPracticedAt: nil
        )

        let view = VaultWordDetailSheet(
            word: minimalWord,
            onPlayAudio: {},
            onToggleBookmark: {}
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif

        XCTAssertFalse(minimalWord.isMastered)
        XCTAssertFalse(minimalWord.isBookmarked)
        XCTAssertTrue(minimalWord.practicedModes.isEmpty)
    }

    func test_vaultWordDetailSheet_isPlayingAudioTrue_rendersProperly() {
        let view = VaultWordDetailSheet(
            word: mockVaultWord,
            isPlayingAudio: true,
            onPlayAudio: {},
            onToggleBookmark: {}
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif

        XCTAssertTrue(view.isPlayingAudio)
    }

    // MARK: - VocabularyView Integration Tests
    func test_vocabularyView_initializationWithViewModel() {
        let vm = PersonalVaultViewModel(mockWords: [mockVaultWord])
        let view = VocabularyView(vaultViewModel: vm)

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif
    }

    // MARK: - Legacy View Backward Compatibility Tests
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
