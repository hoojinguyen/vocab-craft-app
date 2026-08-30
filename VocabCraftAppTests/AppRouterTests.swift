import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("AppRouter Navigation Tests")
@MainActor
struct AppRouterTests {
    @Test("AppRouter initializes with default home tab")
    func testInitialTab() {
        let router = AppRouter()
        #expect(router.selectedTab == .home)
    }

    @Test("AppRouter changes tabs correctly")
    func testTabSelection() {
        let router = AppRouter()
        router.navigateToVocabulary()
        #expect(router.selectedTab == .vocabulary)

        router.navigateToReflex()
        #expect(router.selectedTab == .reflex)

        router.navigateToSettings()
        #expect(router.selectedTab == .settings)

        router.navigateToHome()
        #expect(router.selectedTab == .home)
    }

    @Test("AppRouter handles deep links accurately")
    func testDeepLinks() {
        let router = AppRouter()

        router.handleDeepLink(url: URL(string: "vocabcraft://reflex")!)
        #expect(router.selectedTab == .reflex)

        router.handleDeepLink(url: URL(string: "vocabcraft://vocabulary")!)
        #expect(router.selectedTab == .vocabulary)

        router.handleDeepLink(url: URL(string: "vocabcraft://settings")!)
        #expect(router.selectedTab == .settings)

        router.handleDeepLink(url: URL(string: "vocabcraft://unknown")!)
        #expect(router.selectedTab == .home)
    }
}
#endif
