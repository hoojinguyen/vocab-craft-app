import CraftUIKit
import SwiftUI

/// Redesigned scenario card displaying roleplay scenario information, character role,
/// target word badge pills, and dual 44x44 circular action buttons (Voice and Text).
public struct ScenarioListCard: View {
    @Environment(\.craftTheme) private var theme

    public let scenario: RoleplayScenario
    public let onStartVoice: () -> Void
    public let onStartText: () -> Void

    public init(
        scenario: RoleplayScenario,
        onStartVoice: @escaping () -> Void,
        onStartText: @escaping () -> Void
    ) {
        self.scenario = scenario
        self.onStartVoice = onStartVoice
        self.onStartText = onStartText
    }

    public var body: some View {
        CraftCard(
            style: .outlined,
            cornerRadius: theme.radii.lg,
            padding: theme.spacing.md
        ) {
            HStack(spacing: theme.spacing.md) {
                iconView

                contentView

                Spacer(minLength: theme.spacing.xs)

                actionButtonsView
            }
        }
    }

    private var iconView: some View {
        CraftIcon(
            scenario.iconSymbol.isEmpty ? CraftSymbol.sparkles.rawValue : scenario.iconSymbol,
            size: .lg,
            color: theme.colors.brandPrimary
        )
        .frame(width: theme.spacing.xxl, height: theme.spacing.xxl)
        .background(theme.colors.brandPrimary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            Text(LocalizedStringKey(scenario.titleKey))
                .font(theme.typography.headline)
                .fontWeight(.bold)
                .foregroundStyle(theme.colors.textPrimary)
                .lineLimit(1)

            if !scenario.characterRole.isEmpty {
                Text(scenario.characterRole)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
                    .lineLimit(1)
            }

            if !scenario.targetWordIds.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: theme.spacing.xxs) {
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
    }

    private var actionButtonsView: some View {
        HStack(spacing: theme.spacing.xs) {
            CraftIconButton(
                symbol: .audio,
                size: .md,
                shape: .circle,
                variant: .subtle,
                accessibilityLabelKey: AppStrings.AIAssistant.startVoiceCall,
                action: onStartVoice
            )

            CraftIconButton(
                symbol: .docText,
                size: .md,
                shape: .circle,
                variant: .subtle,
                accessibilityLabelKey: AppStrings.AIAssistant.companionStartChat,
                action: onStartText
            )
        }
    }
}

#if DEBUG
#Preview("ScenarioListCard") {
    let scenario = RoleplayScenario(
        id: "cafe-ordering",
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

    VStack(spacing: 16) {
        ScenarioListCard(
            scenario: scenario,
            onStartVoice: {},
            onStartText: {}
        )
    }
    .padding()
}
#endif
