import CraftUIKit
import SwiftUI

/// Large Title navigation header for the Zen Learning Path Homepage.
///
/// Features:
/// - Apple Books-inspired Large Title ("Home" / `AppStrings.Home.title`).
/// - Trailing status controls:
///   1. `CraftStreakBadge`: Compact pill showing current streak days (`size: .sm`).
///   2. `CraftProgressRing`: 36pt circular goal progress ring showing completed words count (`8/10`).
///   3. User Profile Avatar: 36pt circular button with user initials.
public struct HomeTopHeaderView: View {
    @Environment(\.craftTheme) private var theme

    public let userName: String
    public let streakDays: Int
    public let dailyWordsLearned: Int
    public let dailyWordsGoal: Int
    public var onAvatarTap: (() -> Void)?
    public var onStreakTap: (() -> Void)?

    public init(
        userName: String,
        streakDays: Int,
        dailyWordsLearned: Int,
        dailyWordsGoal: Int,
        onAvatarTap: (() -> Void)? = nil,
        onStreakTap: (() -> Void)? = nil
    ) {
        self.userName = userName
        self.streakDays = streakDays
        self.dailyWordsLearned = dailyWordsLearned
        self.dailyWordsGoal = dailyWordsGoal
        self.onAvatarTap = onAvatarTap
        self.onStreakTap = onStreakTap
    }

    private var userInitials: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = trimmed.components(separatedBy: " ").filter { !$0.isEmpty }
        if components.count >= 2, let first = components.first?.first, let last = components.last?.first {
            return "\(first)\(last)".uppercased()
        } else if let firstChar = trimmed.first {
            return "\(firstChar)".uppercased()
        }
        return "U"
    }

    private var dailyGoalProgress: Double {
        guard dailyWordsGoal > 0 else { return 0.0 }
        return Double(dailyWordsLearned) / Double(dailyWordsGoal)
    }

    private var isGoalCompletedToday: Bool {
        dailyWordsGoal > 0 && dailyWordsLearned >= dailyWordsGoal
    }

    public var body: some View {
        CraftPageHeader(
            AppStrings.Home.title,
            alignment: .leading,
            enableScrollFade: true
        ) {
            trailingActionsGroup
        }
    }

    private var trailingActionsGroup: some View {
        HStack(spacing: theme.spacing.sm) {
            // 1. Streak Flame Badge
            CraftStreakBadge(
                count: streakDays,
                tier: CraftStreakTier.tier(for: streakDays),
                isCompletedToday: isGoalCompletedToday,
                size: .sm,
                onTap: onStreakTap
            )

            // 2. Daily Goal Progress Ring (36pt)
            CraftProgressRing(
                progress: dailyGoalProgress,
                lineWidth: 2.5,
                size: 36,
                tintColor: theme.colors.brandPrimary,
                trackColor: theme.colors.surfaceSubtle,
                animated: true,
                accessibilityLabel: AppStrings.Home.dailyGoalA11y(completed: dailyWordsLearned, goal: dailyWordsGoal)
            ) {
                Text(AppStrings.Home.dailyGoalCount(completed: dailyWordsLearned, goal: dailyWordsGoal))
                    .font(theme.typography.caption.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            // 3. User Avatar Button
            avatarButton
        }
    }

    // MARK: - Avatar Button

    private var avatarButton: some View {
        Button(action: { onAvatarTap?() }) {
            ZStack {
                Circle()
                    .fill(theme.gradients.brandHero)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
                    )
                    .craftShadow(theme.shadows.sm)

                Text(userInitials)
                    .font(theme.typography.caption.weight(.bold))
                    .foregroundStyle(theme.colors.textInverse)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(userName)
        .accessibilityHint(AppStrings.Settings.profileActionViewText)
    }
}

#if canImport(PreviewsMacros)
#Preview("HomeTopHeaderView") {
    VStack(spacing: 24) {
        HomeTopHeaderView(
            userName: "Hooji N.",
            streakDays: 14,
            dailyWordsLearned: 8,
            dailyWordsGoal: 10
        )

        HomeTopHeaderView(
            userName: "Sarah Connor",
            streakDays: 30,
            dailyWordsLearned: 10,
            dailyWordsGoal: 10
        )

        HomeTopHeaderView(
            userName: "Alex",
            streakDays: 3,
            dailyWordsLearned: 2,
            dailyWordsGoal: 10
        )
    }
    .background(Color.vocabCanvas)
}
#endif
