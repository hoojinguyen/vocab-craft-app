import SwiftUI

/// Integrated Homepage view showcasing Bento grid layout, dark mode aesthetic, and liquid glass navigation.
public struct HomepageView: View {
    public let userName: String
    public let streakDays: Int
    public let dailyGoalProgress: Double
    public let dueCardsCount: Int
    public let totalWords: Int
    public let retentionPercentage: Double
    public let unreadNotifications: Bool

    @State private var searchText: String = ""
    @State private var selectedTab: TabItem = .home

    public init(
        userName: String = "Hooji N.",
        streakDays: Int = 14,
        dailyGoalProgress: Double = 0.75,
        dueCardsCount: Int = 24,
        totalWords: Int = 1420,
        retentionPercentage: Double = 0.85,
        unreadNotifications: Bool = true
    ) {
        self.userName = userName
        self.streakDays = streakDays
        self.dailyGoalProgress = dailyGoalProgress
        self.dueCardsCount = dueCardsCount
        self.totalWords = totalWords
        self.retentionPercentage = retentionPercentage
        self.unreadNotifications = unreadNotifications
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color.vocabCanvas
                .ignoresSafeArea()

            switch selectedTab {
            case .home:
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        HeaderView(
                            userName: userName,
                            streakDays: streakDays,
                            dailyGoalProgress: dailyGoalProgress,
                            unreadNotifications: unreadNotifications
                        )

                        MobileSearchView(
                            searchText: $searchText,
                            onVoiceSearchTapped: {}
                        )

                        SRSMemoryHeroCard(
                            totalWords: totalWords,
                            retentionPercentage: retentionPercentage
                        )

                        ActionCardsGrid(
                            dueCardsCount: dueCardsCount,
                            onReflexTap: {},
                            onQueueTap: {}
                        )

                        CEFRDistributionCard()

                        Spacer(minLength: 100)
                    }
                    .padding(.top)
                }
            case .vocabulary:
                VocabularyView()
            case .reflex, .settings:
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        HeaderView(
                            userName: userName,
                            streakDays: streakDays,
                            dailyGoalProgress: dailyGoalProgress,
                            unreadNotifications: unreadNotifications
                        )

                        Spacer(minLength: 100)
                    }
                    .padding(.top)
                }
            }

            LiquidGlassTabBar(selectedTab: $selectedTab)
        }
    }
}
