import Foundation
import Observation
import SwiftUI

/// App-wide Navigation Router managing Tab selection and Deep Linking.
@MainActor
@Observable
public final class AppRouter {
    public var selectedTab: TabItem
    public var navigationPath: NavigationPath

    public init(initialTab: TabItem = .home) {
        self.selectedTab = initialTab
        self.navigationPath = NavigationPath()
    }

    public func selectTab(_ tab: TabItem) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            selectedTab = tab
        }
    }

    public func navigateToHome() {
        selectTab(.home)
    }

    public func navigateToVocabulary() {
        selectTab(.vocabulary)
    }

    public func navigateToReflex() {
        selectTab(.reflex)
    }

    public func navigateToSettings() {
        selectTab(.settings)
    }

    public func handleDeepLink(url: URL) {
        guard url.scheme == "vocabcraft" else { return }
        switch url.host {
        case "reflex":
            selectTab(.reflex)
        case "vocabulary":
            selectTab(.vocabulary)
        case "settings":
            selectTab(.settings)
        default:
            selectTab(.home)
        }
    }
}
