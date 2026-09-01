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
@Suite("VocabularyRedesignView Tests")
struct VocabularyRedesignViewTests {
    let mockWords = [
        VaultWordItem(
            id: 1,
            lemma: "resilience",
            pos: "n.",
            phonetic: "/rɪˈzɪl.jəns/",
            definitionVi: "Khả năng phục hồi, kiên cường",
            exampleSentenceEn: "Her resilience helped her overcome difficulties.",
            exampleSentenceVi: "Sự kiên cường của cô ấy đã giúp cô vượt qua khó khăn.",
            cefrLevel: "B2",
            isMastered: false,
            isBookmarked: true,
            correctStreak: 2,
            practicedModes: [.multipleChoice, .speaking]
        ),
        VaultWordItem(
            id: 2,
            lemma: "diligent",
            pos: "adj.",
            phonetic: "/ˈdɪl.ɪ.dʒənt/",
            definitionVi: "Chăm chỉ, siêng năng",
            exampleSentenceEn: "He is a diligent worker.",
            exampleSentenceVi: "Anh ấy là một người làm việc chăm chỉ.",
            cefrLevel: "B1",
            isMastered: true,
            isBookmarked: false,
            correctStreak: 3,
            practicedModes: [.multipleChoice, .speaking, .typing]
        )
    ]

    @Test("VaultWordRowView displays word and handles callbacks")
    @MainActor
    func testVaultWordRowView() {
        var tapCount = 0
        var bookmarkCount = 0

        let row = VaultWordRowView(
            word: mockWords[0],
            onTap: { tapCount += 1 },
            onBookmarkTap: { bookmarkCount += 1 }
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: row)
        #expect(host.view != nil)
        #endif

        #expect(row.word.lemma == "resilience")

        row.onTap()
        #expect(tapCount == 1)

        row.onBookmarkTap()
        #expect(bookmarkCount == 1)
    }

    @Test("VaultWordRowView displays mastered word")
    @MainActor
    func testVaultWordRowViewMastered() {
        let row = VaultWordRowView(
            word: mockWords[1],
            onTap: {},
            onBookmarkTap: {}
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: row)
        #expect(host.view != nil)
        #endif

        #expect(row.word.isMastered == true)
    }

    @Test("VocabularyView initializes and connects with PersonalVaultViewModel")
    @MainActor
    func testVocabularyViewInitialization() {
        let vm = PersonalVaultViewModel(mockWords: mockWords)
        let view = VocabularyView(vaultViewModel: vm)
            .environment(\.appContainer, AppContainer.mock)

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        #expect(host.view != nil)
        #endif

        #expect(vm.vaultWords.count == 2)
    }
}
#endif
