import SwiftUI
import Testing
@testable import VocabCraftApp
#if canImport(UIKit)
import UIKit
#endif

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

    @Test("TopCarouselFlashcardView hiển thị thẻ từ và kích hoạt các callback")
    @MainActor
    func testTopCarouselFlashcardView() {
        var audioWord: VaultWordItem?
        var bookmarkWord: VaultWordItem?
        var selectedWord: VaultWordItem?

        let carousel = TopCarouselFlashcardView(
            words: mockWords,
            onAudioTap: { word in
                audioWord = word
            },
            onBookmarkTap: { word in
                bookmarkWord = word
            },
            onWordSelected: { word in
                selectedWord = word
            }
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: carousel)
        #expect(host.view != nil)
        #endif

        #expect(carousel.words.count == 2)
        carousel.onAudioTap?(mockWords[0])
        #expect(audioWord?.id == 1)

        carousel.onBookmarkTap?(mockWords[1])
        #expect(bookmarkWord?.id == 2)

        carousel.onWordSelected?(mockWords[0])
        #expect(selectedWord?.id == 1)
    }

    @Test("TopCarouselFlashcardView xử lý danh sách từ rỗng")
    @MainActor
    func testTopCarouselFlashcardViewEmpty() {
        let carousel = TopCarouselFlashcardView(words: [])

        #if canImport(UIKit)
        let host = UIHostingController(rootView: carousel)
        #expect(host.view != nil)
        #endif

        #expect(carousel.words.isEmpty)
    }

    @Test("VaultWordCardView hiển thị trạng thái thu gọn và mở rộng")
    @MainActor
    func testVaultWordCardView() {
        var tapCount = 0
        var audioCount = 0
        var bookmarkCount = 0

        let card = VaultWordCardView(
            word: mockWords[0],
            isExpanded: false,
            onTap: { tapCount += 1 },
            onAudioTap: { audioCount += 1 },
            onBookmarkTap: { bookmarkCount += 1 }
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: card)
        #expect(host.view != nil)
        #endif

        #expect(card.word.lemma == "resilience")
        #expect(card.isExpanded == false)

        card.onTap()
        #expect(tapCount == 1)

        card.onAudioTap()
        #expect(audioCount == 1)

        card.onBookmarkTap()
        #expect(bookmarkCount == 1)
    }

    @Test("VaultWordCardView hiển thị từ đã thuộc với checkmark badge")
    @MainActor
    func testVaultWordCardViewMastered() {
        let card = VaultWordCardView(
            word: mockWords[1],
            isExpanded: true,
            onTap: {},
            onAudioTap: {},
            onBookmarkTap: {}
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: card)
        #expect(host.view != nil)
        #endif

        #expect(card.word.isMastered == true)
        #expect(card.isExpanded == true)
    }

    @Test("VocabularyView khởi tạo và kết nối với PersonalVaultViewModel")
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
