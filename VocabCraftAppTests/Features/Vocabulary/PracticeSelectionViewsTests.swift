import SwiftUI
import Testing
@testable import VocabCraftApp
#if canImport(UIKit)
import UIKit
#endif

@Suite("PracticeSelectionViews Tests")
struct PracticeSelectionViewsTests {
    let mockWords = [
        VaultWordItem(
            id: 1,
            lemma: "resilience",
            pos: "n.",
            phonetic: "/rɪˈzɪl.jəns/",
            definitionVi: "Khả năng phục hồi, kiên cường",
            exampleSentenceEn: "Her resilience is inspiring.",
            exampleSentenceVi: "Sự kiên cường của cô ấy thật truyền cảm hứng.",
            cefrLevel: "B2",
            isMastered: false,
            isBookmarked: true,
            correctStreak: 1,
            practicedModes: [.multipleChoice]
        ),
        VaultWordItem(
            id: 2,
            lemma: "diligent",
            pos: "adj.",
            phonetic: "/ˈdɪl.ɪ.dʒənt/",
            definitionVi: "Chăm chỉ, siêng năng",
            exampleSentenceEn: "He is a diligent student.",
            exampleSentenceVi: "Anh ấy là một học sinh chăm chỉ.",
            cefrLevel: "B1",
            isMastered: true,
            isBookmarked: false,
            correctStreak: 3,
            practicedModes: [.multipleChoice, .speaking]
        )
    ]

    @Test("PracticeSelectionRow kích hoạt onToggle và onAudioTap callback")
    @MainActor
    func testPracticeSelectionRowCallbacks() {
        var toggleTriggered = false
        var audioTriggered = false

        let row = PracticeSelectionRow(
            word: mockWords[0],
            isSelected: false,
            onToggle: {
                toggleTriggered = true
            },
            onAudioTap: {
                audioTriggered = true
            }
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: row)
        #expect(host.view != nil)
        #endif

        row.onToggle()
        #expect(toggleTriggered == true)

        row.onAudioTap?()
        #expect(audioTriggered == true)
    }

    @Test("PracticeSelectionView hiển thị và thực hiện Chọn tất cả / Bắt đầu luyện tập")
    @MainActor
    func testPracticeSelectionViewStartPractice() async {
        let vm = PersonalVaultViewModel(mockWords: mockWords)
        var startedWords: [VaultWordItem] = []
        var closeTriggered = false

        let view = PracticeSelectionView(
            vaultViewModel: vm,
            onStartPractice: { words in
                startedWords = words
            },
            onClose: {
                closeTriggered = true
            }
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        #expect(host.view != nil)
        #endif

        #expect(vm.selectedWordIds.isEmpty)
        #expect(startedWords.isEmpty)

        // Select all words
        vm.selectAll()
        #expect(vm.selectedWordIds.count == 2)
        #expect(vm.selectedWords.count == 2)

        view.onStartPractice(vm.selectedWords)
        #expect(startedWords.count == 2)
        #expect(startedWords.map(\.id) == [1, 2])

        view.onClose?()
        #expect(closeTriggered == true)
    }

    @Test("PracticeSelectionView chuyển đổi tab bộ lọc VaultTabFilter")
    @MainActor
    func testPracticeSelectionViewTabFilter() {
        let vm = PersonalVaultViewModel(mockWords: mockWords)
        let view = PracticeSelectionView(
            vaultViewModel: vm,
            onStartPractice: { _ in }
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        #expect(host.view != nil)
        #endif

        #expect(vm.vaultTabFilter == .notMastered)
        vm.setVaultFilter(.mastered)
        #expect(vm.vaultTabFilter == .mastered)
    }
}
