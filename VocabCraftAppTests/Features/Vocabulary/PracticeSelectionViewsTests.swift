import Foundation
import SwiftUI
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp
#if canImport(UIKit)
import UIKit
#endif

#if canImport(Testing)
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

    @Test("PracticeSelectionView thực hiện Smart Pick nhanh")
    @MainActor
    func testPracticeSelectionViewSmartPick() {
        let vm = PersonalVaultViewModel(mockWords: mockWords)
        let view = PracticeSelectionView(
            vaultViewModel: vm,
            onStartPractice: { _ in }
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        #expect(host.view != nil)
        #endif

        #expect(vm.selectedWordIds.isEmpty)
        let picked = vm.smartPickWords(targetCount: 1)
        #expect(picked.count == 1)
        #expect(vm.selectedWordIds.count == 1)
    }

    @Test("PracticeSelectionRow hiển thị modeStats và các trạng thái hoàn thành")
    @MainActor
    func testPracticeSelectionRowModeStats() {
        let wordWithStats = VaultWordItem(
            id: 10,
            lemma: "mastery",
            pos: "n.",
            definitionVi: "Sự thành thạo",
            modeStats: ModeSuccessStats(speaking: 1, typing: 0, multipleChoice: 2, listening: 0)
        )

        let row = PracticeSelectionRow(
            word: wordWithStats,
            isSelected: true,
            onToggle: {}
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: row)
        #expect(host.view != nil)
        #endif

        #expect(wordWithStats.modeStats.count(for: .speaking) == 1)
        #expect(wordWithStats.modeStats.count(for: .typing) == 0)
        #expect(wordWithStats.modeStats.count(for: .multipleChoice) == 2)
        #expect(wordWithStats.modeStats.count(for: .listening) == 0)
    }
}
#endif
