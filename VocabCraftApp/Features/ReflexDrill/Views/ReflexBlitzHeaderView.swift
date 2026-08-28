import CraftUIKit
import SwiftUI

public struct ReflexBlitzHeaderView: View {
    @Environment(\.craftTheme) private var theme

    public let currentIndex: Int
    public let totalCount: Int
    public let comboStreak: Int
    public let fractionRemaining: Double
    public let timerStage: ReflexBlitzTimerStage
    public let mode: ReflexBlitzMode
    public let attempts: [ReflexBlitzAttempt]
    public let wordStartTime: Date?
    public let timeLimitSeconds: Double
    public let isTimerActive: Bool
    public let onClose: () -> Void
    public let onSkip: () -> Void
    public var showSkipInHeader: Bool

    public var timerBarColor: Color {
        switch timerStage {
        case .steady:
            return theme.colors.brandPrimary
        case .warning:
            return theme.colors.statusWarning
        case .urgent:
            return theme.colors.statusDanger
        }
    }

    public init(
        currentIndex: Int,
        totalCount: Int,
        comboStreak: Int,
        fractionRemaining: Double = 1.0,
        timerStage: ReflexBlitzTimerStage = .steady,
        mode: ReflexBlitzMode = .speaking,
        attempts: [ReflexBlitzAttempt] = [],
        wordStartTime: Date? = nil,
        timeLimitSeconds: Double = 6.0,
        isTimerActive: Bool = false,
        onClose: @escaping () -> Void,
        onSkip: @escaping () -> Void = {},
        showSkipInHeader: Bool = false
    ) {
        self.currentIndex = currentIndex
        self.totalCount = totalCount
        self.comboStreak = comboStreak
        self.fractionRemaining = fractionRemaining
        self.timerStage = timerStage
        self.mode = mode
        self.attempts = attempts
        self.wordStartTime = wordStartTime
        self.timeLimitSeconds = timeLimitSeconds
        self.isTimerActive = isTimerActive
        self.onClose = onClose
        self.onSkip = onSkip
        self.showSkipInHeader = showSkipInHeader
    }

    public var body: some View {
        VStack(spacing: theme.spacing.sm) {
            // Top Action & Progress Bar Row (Perfect 3-Column Balance)
            HStack(alignment: .center) {
                // Leading: Close button (CraftIconButton)
                CraftIconButton(
                    iconName: "xmark",
                    size: .sm,
                    shape: .circle,
                    variant: .subtle,
                    style: .glass,
                    accessibilityLabel: CraftLocalized.string("craft.common.action.close"),
                    action: onClose
                )

                Spacer(minLength: theme.spacing.xs)

                // Center: Segmented Progress Bar & Step Counter
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

                // Trailing: Combo Streak Badge or Balanced Placeholder
                if comboStreak >= 2 {
                    CraftStreakBadge(
                        count: comboStreak,
                        isCompletedToday: true,
                        size: .sm,
                        style: .glass,
                        accessibilityLabel: String(localized: "app.reflex.blitz.combo_streak_a11y_format", defaultValue: "Combo streak %lld")
                    )
                    .transition(.scale.combined(with: .opacity))
                } else if showSkipInHeader {
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
                    // Invisible 44x44 placeholder to keep center segmented bar mathematically centered
                    Color.clear
                        .frame(width: 44, height: 44)
                        .accessibilityHidden(true)
                }
            }

            // Smooth Linear Countdown Timer Bar Anchored Under Header
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

    public func segmentColor(for index: Int) -> Color {
        if index < attempts.count {
            return attempts[index].isCorrect ? theme.colors.statusSuccess : theme.colors.statusDanger
        } else if index == currentIndex {
            return theme.colors.brandPrimary
        } else {
            return theme.colors.surfaceSubtle.opacity(0.4)
        }
    }
}
