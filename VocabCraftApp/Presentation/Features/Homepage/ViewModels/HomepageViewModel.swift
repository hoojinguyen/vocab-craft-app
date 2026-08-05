import Foundation
import Observation

/// State model for HomepageView
public struct HomepageState: Equatable {
    public var userName: String
    public var streakDays: Int
    public var dailyGoalProgress: Double
    public var dueCardsCount: Int
    public var totalWords: Int
    public var retentionPercentage: Double
    public var unreadNotifications: Bool
    public var searchText: String
    public var selectedTab: TabItem

    public init(
        userName: String = "Hooji N.",
        streakDays: Int = 14,
        dailyGoalProgress: Double = 0.75,
        dueCardsCount: Int = 24,
        totalWords: Int = 1420,
        retentionPercentage: Double = 0.85,
        unreadNotifications: Bool = true,
        searchText: String = "",
        selectedTab: TabItem = .home
    ) {
        self.userName = userName
        self.streakDays = streakDays
        self.dailyGoalProgress = dailyGoalProgress
        self.dueCardsCount = dueCardsCount
        self.totalWords = totalWords
        self.retentionPercentage = retentionPercentage
        self.unreadNotifications = unreadNotifications
        self.searchText = searchText
        self.selectedTab = selectedTab
    }
}

@MainActor
@Observable
public final class HomepageViewModel {
    public private(set) var state: HomepageState
    
    public var searchText: String {
        get { state.searchText }
        set { state.searchText = newValue }
    }
    
    public var selectedTab: TabItem {
        get { state.selectedTab }
        set { state.selectedTab = newValue }
    }

    public init(initialState: HomepageState = HomepageState()) {
        self.state = initialState
    }

    public func selectTab(_ tab: TabItem) {
        state.selectedTab = tab
    }

    public func updateSearchText(_ text: String) {
        state.searchText = text
    }

    public func performVoiceSearch() {
        // Trigger voice search intent
    }
}
