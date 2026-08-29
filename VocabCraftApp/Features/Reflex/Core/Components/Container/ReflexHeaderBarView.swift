import CraftUIKit
import SwiftUI

/// Unified header bar for Reflex sessions featuring progress steps, combo streak badges,
/// smooth animated timer bars, and balanced action buttons.
public struct ReflexHeaderBarView: View {
    @Environment(\.craftTheme) private var theme

    public let currentIndex: Int
    public let totalCount: Int
    public let comboStreak: Int
    public let fractionRemaining: Double
    public let timerStage: ReflexBlitzTimerStage
    public let attempts: [ReflexBlitzAttempt]
    public let wordStartTime: Date?
    public let timeLimitSeconds: Double
    public let isTimerActive: Bool
    public let showSkipInHeader: Bool
    public let onClose: () -> Void
    public let onSkip: (() -> Void)?

    public init(
        currentIndex: Int,
        totalCount: Int,
        comboStreak: Int = 0,
        fractionRemaining: Double = 1.0,
        timerStage: ReflexBlitzTimerStage = .steady,
        attempts: [ReflexBlitzAttempt] = [],
        wordStartTime: Date? = nil,
        timeLimitSeconds: Double = 6.0,
        isTimerActive: Bool = false,
        showSkipInHeader: Bool = false,
        onClose: @escaping () -> Void,
        onSkip: (() -> Void)? = nil
    ) {
        self.currentIndex = currentIndex
        self.totalCount = totalCount
        self.comboStreak = comboStreak
        self.fractionRemaining = fractionRemaining
        self.timerStage = timerStage
        self.attempts = attempts
        self.wordStartTime = wordStartTime
        self.timeLimitSeconds = timeLimitSeconds
        self.isTimerActive = isTimerActive
        self.showSkipInHeader = showSkipInHeader
        self.onClose = onClose
        self.onSkip = onSkip
    }

    public var body: some View {
        VStack(spacing: theme.spacing.sm) {
            HStack(alignment: .center) {
                // Leading: Close button
                CraftIconButton(
                    iconName: "xmark",
                    size: .sm,
                    shape: .circle,
                    variant: .subtle,
                    style: nil,
                    customTint: theme.colors.textSecondary,
                    accessibilityLabel: CraftLocalized.string("craft.common.action.close"),
                    action: onClose
                )

                Spacer(minLength: theme.spacing.xs)

                // Center: Step progress indicator
                CraftStepProgressIndicator(
                    steps: (0..<totalCount).map { index in
                        if index < attempts.count {
                            return .completed(isCorrect: attempts[index].isCorrect)
                        } else if index == currentIndex {
                            return .active
                        } else {
                            return .unreached
                        }
                    },
                    currentStep: currentIndex,
                    height: 4,
                    spacing: 4,
                    showCounter: true,
                    counterStyle: .ratio
                )
                .frame(maxWidth: 160)

                Spacer(minLength: theme.spacing.xs)

                // Trailing: Combo streak badge or skip button or balanced placeholder
                if comboStreak >= 2 {
                    CraftStreakBadge(
                        count: comboStreak,
                        isCompletedToday: true,
                        size: .sm,
                        style: .glass,
                        accessibilityLabel: String(localized: "app.reflex.blitz.combo_streak_a11y_format", defaultValue: "Combo streak %lld")
                    )
                    .transition(.scale.combined(with: .opacity))
                } else if showSkipInHeader, let onSkip {
                    Button(action: onSkip) {
                        CraftText(
                            AppStrings.Common.skip,
                            style: .caption,
                            color: theme.colors.textMuted
                        )
                        .padding(.horizontal, theme.spacing.sm)
                        .padding(.vertical, theme.spacing.xs)
                        .craftSurface(style: .glass, shape: Capsule())
                    }
                    .buttonStyle(.craftPress(scale: 0.96))
                    .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                    .accessibilityLabel(String(localized: "app.reflex.blitz.skip_current_a11y", defaultValue: "Skip current word"))
                } else {
                    Color.clear
                        .frame(width: 44, height: 44)
                        .accessibilityHidden(true)
                }
            }

            // Countdown timer bar
            if isTimerActive {
                CraftCountdownTimerBar(
                    startDate: wordStartTime ?? Date(),
                    timeLimit: timeLimitSeconds,
                    isActive: isTimerActive,
                    height: 4.5,
                    colorConfig: CraftCountdownColorConfig(
                        steady: theme.colors.brandPrimary,
                        warning: theme.colors.statusWarning,
                        urgent: theme.colors.statusDanger,
                        trackColor: theme.colors.surfaceSubtle.opacity(0.3),
                        showGlow: true
                    )
                )
            } else {
                CraftCountdownTimerBar(
                    progress: fractionRemaining,
                    height: 4.5,
                    colorConfig: CraftCountdownColorConfig(
                        steady: theme.colors.brandPrimary,
                        warning: theme.colors.statusWarning,
                        urgent: theme.colors.statusDanger,
                        trackColor: theme.colors.surfaceSubtle.opacity(0.3),
                        showGlow: true
                    )
                )
            }
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.top, theme.spacing.xs)
        .padding(.bottom, theme.spacing.xs)
    }
}
