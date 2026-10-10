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
    @Environment(\.locale) private var locale

    public let userName: String
    public let streakDays: Int
    public let dailyWordsLearned: Int
    public let dailyWordsGoal: Int
    public let activeLearningPath: LearningPathDTO?
    public var onAvatarTap: (() -> Void)?
    public var onStreakTap: (() -> Void)?
    public var onProgressTap: (() -> Void)?

    public init(
        userName: String,
        streakDays: Int,
        dailyWordsLearned: Int,
        dailyWordsGoal: Int,
        activeLearningPath: LearningPathDTO? = nil,
        onAvatarTap: (() -> Void)? = nil,
        onStreakTap: (() -> Void)? = nil,
        onProgressTap: (() -> Void)? = nil
    ) {
        self.userName = userName
        self.streakDays = streakDays
        self.dailyWordsLearned = dailyWordsLearned
        self.dailyWordsGoal = dailyWordsGoal
        self.activeLearningPath = activeLearningPath
        self.onAvatarTap = onAvatarTap
        self.onStreakTap = onStreakTap
        self.onProgressTap = onProgressTap
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
        VStack(alignment: .leading, spacing: 0) {
            CraftPageHeader(
                AppStrings.Home.title,
                alignment: .leading,
                enableScrollFade: false
            ) {
                trailingActionsGroup
            }

            if let activeLearningPath {
                ActiveJourneyBadge(path: activeLearningPath)
            }
        }
    }

    private var trailingActionsGroup: some View {
        HStack(alignment: .center, spacing: theme.spacing.sm) {
            // 1. Streak Flame Badge
            CraftStreakBadge(
                count: streakDays,
                tier: CraftStreakTier.tier(for: streakDays),
                isCompletedToday: isGoalCompletedToday,
                size: .sm,
                onTap: onStreakTap
            )

            // 2. Daily Goal Progress Ring (36pt) - tappable to scroll to active
            if let onProgressTap {
                Button(action: {
                    CraftHaptics.shared.light()
                    onProgressTap()
                }) {
                    progressRingView
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(CraftLocalized.string("craft.learning_path.tap_to_scroll_unit_hint"))
            } else {
                progressRingView
            }

            // 3. User Avatar Button
            avatarButton
        }
    }

    private var progressRingView: some View {
        ZStack {
            Circle()
                .fill(theme.colors.surfaceCard)
                .frame(width: 36, height: 36)

            CraftProgressRing(
                progress: dailyGoalProgress,
                lineWidth: 2.5,
                size: 33.5,
                tintColor: theme.colors.brandPrimary,
                trackColor: theme.colors.borderDefault.opacity(0.4),
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
        }
        .frame(width: 36, height: 36)
        .craftShadow(theme.shadows.sm)
    }

    // MARK: - Avatar Button

    private var avatarButton: some View {
        Button(action: {
            onAvatarTap?()
        }) {
            ZStack {
                Circle()
                    .fill(theme.gradients.brandHero)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .strokeBorder(theme.colors.borderDefault.opacity(0.4), lineWidth: 1)
                    )
                    .craftShadow(theme.shadows.sm)

                Text(userInitials)
                    .font(theme.typography.caption.weight(.bold))
                    .foregroundStyle(theme.colors.textInverse)
            }
            .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(userName)
        .accessibilityHint(AppStrings.Settings.profileActionViewText)
    }
}

// MARK: - Active Journey Badge Subview

private struct ActiveJourneyBadge: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.locale) private var locale
    let path: LearningPathDTO

    var body: some View {
        HStack(alignment: .center, spacing: theme.spacing.xs) {
            CraftBadge(
                AppStrings.Home.learningPathBadge,
                symbol: CraftSymbol.sparkles,
                variant: .subtle,
                tone: .primary,
                size: .sm
            )

            Text(subtitleText)
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.bottom, theme.spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(AppStrings.Home.learningPathBadgeText): \(subtitleText)")
    }

    private var subtitleText: String {
        if let targetLevel = localizedLevels {
            return "\(localizedTitle) • \(targetLevel)"
        }
        return localizedTitle
    }

    private var localizedTitle: String {
        let isVietnamese = locale.identifier.hasPrefix("vi")
        if isVietnamese {
            return path.titleVi.isEmpty ? path.titleEn : path.titleVi
        } else {
            return path.titleEn.isEmpty ? path.titleVi : path.titleEn
        }
    }

    private var localizedLevels: String? {
        let min = path.targetLevelMin.trimmingCharacters(in: .whitespacesAndNewlines)
        let max = path.targetLevelMax.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !min.isEmpty else { return nil }
        if !max.isEmpty && min != max {
            return AppStrings.Home.learningPathLevel("\(min) - \(max)")
        } else {
            return AppStrings.Home.learningPathLevel(min)
        }
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
    .background(CraftDefaultTheme().colors.canvasBackground)
}
#endif
