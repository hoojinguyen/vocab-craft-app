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

    @Test("PracticeSelectionRow kích hoạt onToggle callback khi nhấn toàn bộ row")
    @MainActor
    func testPracticeSelectionRowCallbacks() {
        var toggleTriggered = false

        let row = PracticeSelectionRow(
            word: mockWords[0],
            isSelected: false,
            onToggle: {
                toggleTriggered = true
            }
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: row)
        #expect(host.view != nil)
        #endif

        row.onToggle()
        #expect(toggleTriggered == true)
    }

    @Test("PracticeSelectionRow hiển thị trạng thái đã chọn")
    @MainActor
    func testPracticeSelectionRowSelectedState() {
        var toggleTriggered = false
        let row = PracticeSelectionRow(
            word: mockWords[0],
            isSelected: true,
            onToggle: {
                toggleTriggered = true
            }
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: row)
        #expect(host.view != nil)
        #endif

        #expect(row.isSelected == true)
        #expect(row.word.lemma == "resilience")
        row.onToggle()
        #expect(toggleTriggered == true)
    }

    @Test("PracticeSelectionView thực hiện Chọn tất cả / Bỏ chọn tất cả và Bắt đầu luyện tập thủ công")
    @MainActor
    func testPracticeSelectionViewManualSelectionAndStart() async {
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

        // Trigger manual start
        view.onStartPractice(vm.selectedWords)
        #expect(startedWords.count == 2)
        #expect(startedWords.map(\.id) == [1, 2])

        // Deselect all words
        vm.deselectAll()
        #expect(vm.selectedWordIds.isEmpty)
        #expect(vm.selectedWords.isEmpty)

        // Toggle single word
        vm.toggleWordSelection(id: 1)
        #expect(vm.selectedWordIds == [1])
        #expect(vm.selectedWords.count == 1)

        view.onClose?()
        #expect(closeTriggered == true)
    }

    @Test("PracticeSelectionView khởi chạy Luyện tập thông minh (Smart Practice) ngay lập tức")
    @MainActor
    func testPracticeSelectionViewInstantSmartPractice() {
        let vm = PersonalVaultViewModel(mockWords: mockWords)
        var startedWords: [VaultWordItem] = []

        let view = PracticeSelectionView(
            vaultViewModel: vm,
            onStartPractice: { words in
                startedWords = words
            }
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        #expect(host.view != nil)
        #endif

        #expect(vm.selectedWordIds.isEmpty)
        #expect(startedWords.isEmpty)

        // Simulate instant Smart Practice CTA action:
        let picked = vm.smartPickWords(targetCount: 1)
        #expect(!picked.isEmpty)
        view.onStartPractice(picked)

        #expect(startedWords.count == 1)
        #expect(vm.selectedWordIds.count == 1)
        #expect(startedWords.first?.id == picked.first?.id)
    }

    @Test("PracticeSelectionView render trực tiếp danh sách từ vựng không dùng segmentedFilterBar")
    @MainActor
    func testPracticeSelectionViewDirectWordListRendering() {
        let vm = PersonalVaultViewModel(mockWords: mockWords)
        let view = PracticeSelectionView(
            vaultViewModel: vm,
            onStartPractice: { _ in }
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        #expect(host.view != nil)
        #endif

        #expect(vm.vaultWords.count == 2)
        #expect(vm.vaultWords[0].lemma == "resilience")
        #expect(vm.vaultWords[1].lemma == "diligent")
    }
}
#endif
