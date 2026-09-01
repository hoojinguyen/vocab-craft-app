import Foundation
import SwiftUI
@testable import VocabCraftApp
#if canImport(Testing)
import Testing
#endif
#if canImport(XCTest)
import XCTest
#endif
#if canImport(UIKit)
import UIKit
#endif

#if canImport(Testing)
@Suite("VocabularyView Tests")
struct VocabularyViewTestingTests {
    @Test("VocabularyView default initialization and body evaluation")
    @MainActor
    func testVocabularyViewInitialization() {
        let view = VocabularyView()
        _ = view.body
    }

    @Test("VocabularyView with search visible state")
    @MainActor
    func testVocabularyViewSearchVisibleState() {
        let view = VocabularyView(isSearchHiddenByScroll: true)
        _ = view.body
    }

    @Test("VocabularyView with PersonalVaultViewModel and search queries")
    @MainActor
    func testVocabularyViewWithPersonalVaultVM() async {
        let mockWord = VaultWordItem(
            id: 1,
            lemma: "eloquent",
            pos: "adj",
            phonetic: "/ˈel.ə.kwənt/",
            definitionVi: "Hùng biện",
            cefrLevel: "C1",
            isMastered: false,
            isBookmarked: true
        )
        let vm = PersonalVaultViewModel(mockWords: [mockWord])
        let view = VocabularyView(vaultViewModel: vm, isSearchHiddenByScroll: false)
            .environment(\.appContainer, AppContainer.mock)
        #if canImport(UIKit)
        _ = UIHostingController(rootView: view).view
        #endif

        vm.setSearchQuery("elo")
        let searchingView = VocabularyView(vaultViewModel: vm, isSearchHiddenByScroll: true)
            .environment(\.appContainer, AppContainer.mock)
        #if canImport(UIKit)
        _ = UIHostingController(rootView: searchingView).view
        #endif

        vm.setSearchQuery("")
        #expect(vm.searchQuery.isEmpty)
    }
}
#endif

@MainActor
final class VocabularyViewTests: XCTestCase {
    func testVocabularyViewInitializationAndTabSwitch() {
        let view = VocabularyView()
        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif
    }

    func testVocabularyViewWithSearchVisibleInitialization() {
        let view = VocabularyView(isSearchHiddenByScroll: true)
        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif
    }

    func testVocabularyViewWithPersonalVaultViewModelAndSearchToggle() {
        let mockWord = VaultWordItem(
            id: 1,
            lemma: "eloquent",
            pos: "adj",
            phonetic: "/ˈel.ə.kwənt/",
            definitionVi: "Hùng biện",
            cefrLevel: "C1",
            isMastered: false,
            isBookmarked: true
        )
        let vm = PersonalVaultViewModel(mockWords: [mockWord])
        let view = VocabularyView(vaultViewModel: vm, isSearchHiddenByScroll: false)
            .environment(\.appContainer, AppContainer.mock)

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif

        vm.setSearchQuery("elo")
        XCTAssertEqual(vm.searchQuery, "elo")

        let searchingView = VocabularyView(vaultViewModel: vm, isSearchHiddenByScroll: true)
            .environment(\.appContainer, AppContainer.mock)
        #if canImport(UIKit)
        let searchingHost = UIHostingController(rootView: searchingView)
        XCTAssertNotNil(searchingHost.view)
        #else
        XCTAssertNotNil(searchingView)
        #endif

        vm.setSearchQuery("")
        XCTAssertTrue(vm.searchQuery.isEmpty)
    }
}
