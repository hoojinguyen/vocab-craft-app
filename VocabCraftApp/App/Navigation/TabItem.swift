import CraftUIKit
import Foundation
import SwiftUI

public enum TabItem: Int, CaseIterable, Identifiable, Sendable, CraftTabItemProtocol {
    case home = 0
    case vocabulary = 1
    case search = 4 // Tra từ
    case reflex = 2 // Phản xạ
    case settings = 3 // Cài đặt

    public var id: Int { rawValue }

    public var title: String { "" }

    public var titleKey: LocalizedStringKey? {
        switch self {
        case .home: return AppStrings.Tabs.home
        case .vocabulary: return AppStrings.Tabs.vocabulary
        case .search: return AppStrings.Tabs.search
        case .reflex: return AppStrings.Tabs.reflex
        case .settings: return AppStrings.Tabs.settings
        }
    }

    public var symbol: String {
        switch self {
        case .home: return CraftSymbol.homeFill.rawValue
        case .vocabulary: return CraftSymbol.booksFill.rawValue
        case .search: return CraftSymbol.search.rawValue
        case .reflex: return CraftSymbol.practice.rawValue
        case .settings: return CraftSymbol.settingsFill.rawValue
        }
    }

    public var badgeCount: Int? { nil }

    public var showsTitle: Bool { false }
    public var showsSymbol: Bool { true }

    /// The 4 standard navigation tabs rendered on the dock sides.
    public static var navigationTabs: [TabItem] {
        [.home, .vocabulary, .search, .settings]
    }
}
