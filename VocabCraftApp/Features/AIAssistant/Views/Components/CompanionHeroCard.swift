import CraftUIKit
import SwiftUI

/// Centerpiece Warm Companion card featuring tutor avatar with ambient pulse,
/// progress-based greeting, target vocabulary badges, and primary/subtle actions.
public struct CompanionHeroCard: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing: Bool = false

    public let scenario: RoleplayScenario
    public let wordsLearnedCount: Int
    public let onStartCall: () -> Void
    public let onStartChat: () -> Void

    public init(
        scenario: RoleplayScenario,
        wordsLearnedCount: Int,
        onStartCall: @escaping () -> Void,
        onStartChat: @escaping () -> Void
    ) {
        self.scenario = scenario
        self.wordsLearnedCount = wordsLearnedCount
        self.onStartCall = onStartCall
        self.onStartChat = onStartChat
    }

    public var body: some View {
        CraftCard(
            style: .outlined,
            cornerRadius: theme.radii.xl,
            padding: theme.spacing.lg
        ) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                headerView

                greetingView

                targetWordsView

                actionButtonsView
            }
        }
    }

    private var headerView: some View {
        HStack(spacing: theme.spacing.md) {
            avatarView

            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                CraftBadge(
                    AppStrings.AIAssistant.companionBadge,
                    symbol: .sparkles,
                    variant: .subtle,
                    tone: .primary,
                    size: .sm,
                    customTint: theme.colors.accent
                )

                Text(LocalizedStringKey(scenario.titleKey))
                    .font(theme.typography.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(1)
            }

            Spacer()
        }
    }

    private var avatarView: some View {
        ZStack {
            Circle()
                .stroke(
                    theme.colors.accent.opacity(isPulsing ? 0.45 : 0.15),
                    lineWidth: theme.depths.depthSm
                )
                .scaleEffect(isPulsing ? 1.12 : 1.0)

            Circle()
                .fill(theme.colors.accent.opacity(0.12))

            CraftIcon(
                scenario.iconSymbol.isEmpty ? CraftSymbol.sparkles.rawValue : scenario.iconSymbol,
                size: .md,
                color: theme.colors.accent
            )
        }
        .frame(width: theme.spacing.xxl, height: theme.spacing.xxl)
        .onAppear {
            startPulsingIfNeeded()
        }
        .onChange(of: reduceMotion) { _, newValue in
            if newValue {
                isPulsing = false
            } else {
                startPulsingIfNeeded()
            }
        }
    }

    private var greetingView: some View {
        Text(AppStrings.AIAssistant.companionGreetingKey(wordsCount: wordsLearnedCount))
            .font(theme.typography.bodyMedium)
            .foregroundStyle(theme.colors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var targetWordsView: some View {
        if !scenario.targetWordIds.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.xs) {
                    ForEach(scenario.targetWordIds, id: \.self) { word in
                        CraftBadge(
                            verbatim: word,
                            variant: .subtle,
                            tone: .neutral,
                            size: .sm
                        )
                    }
                }
            }
        }
    }

    private var actionButtonsView: some View {
        VStack(spacing: theme.spacing.xs) {
            CraftButton(
                AppStrings.AIAssistant.companionStartCall,
                iconName: CraftSymbol.mic.rawValue,
                variant: .primary,
                size: .lg,
                isFullWidth: true
            ) {
                onStartCall()
            }

            CraftButton(
                AppStrings.AIAssistant.companionStartChat,
                iconName: CraftSymbol.docText.rawValue,
                variant: .subtle,
                size: .md,
                isFullWidth: true
            ) {
                onStartChat()
            }
        }
        .padding(.top, theme.spacing.xs)
    }

    private func startPulsingIfNeeded() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
    }
}

#if DEBUG
#Preview("CompanionHeroCard") {
    let scenario = RoleplayScenario(
        id: "daily-cafe",
        titleKey: "app.ai_assistant.scenario.cafe.title",
        descriptionKey: "app.ai_assistant.scenario.cafe.desc",
        topic: .dining,
        difficulty: .beginner,
        characterName: "Alex",
        characterRole: "Barista",
        userRole: "Customer",
        initialGreeting: "Welcome to the coffee shop!",
        targetWordIds: ["latte", "croissant", "espresso"],
        iconSymbol: "cup.and.saucer"
    )

    ScrollView {
        CompanionHeroCard(
            scenario: scenario,
            wordsLearnedCount: 3,
            onStartCall: {},
            onStartChat: {}
        )
        .padding()
    }
}
#endif
