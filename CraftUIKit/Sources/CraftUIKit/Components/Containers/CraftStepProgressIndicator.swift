import SwiftUI

// MARK: - CraftStepStatus

/// Represents the status and visual appearance of a single step within `CraftStepProgressIndicator`.
public enum CraftStepStatus: Equatable, Sendable {
    /// Step has not been reached yet.
    case unreached
    /// Step is currently active/in progress.
    case active
    /// Step has been completed, with an indication of correctness (e.g. for quizzes or drills).
    case completed(isCorrect: Bool)
    /// Step uses a custom tint color.
    case custom(Color)
}

// MARK: - CraftStepCounterStyle

/// Format styles for the step counter text rendered below the capsules in `CraftStepProgressIndicator`.
public enum CraftStepCounterStyle: Equatable, Sendable, CaseIterable {
    /// Monospaced ratio format (e.g., "1 / 12").
    case ratio
    /// Localized phrase format (e.g., "Step 1 of 12" / "Bước 1 trên 12").
    case phrase
    /// Counter text is hidden.
    case hidden
}

// MARK: - CraftStepProgressIndicator Component

/// A discrete interval/step progress indicator displaying a series of capsules with dynamic status colors,
/// monospaced step counter formatting, smooth spring transitions, and accessible VoiceOver support.
public struct CraftStepProgressIndicator: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let steps: [CraftStepStatus]
    public let currentStep: Int
    public let height: CGFloat
    public let spacing: CGFloat
    public let showCounter: Bool
    public let counterStyle: CraftStepCounterStyle

    /// Total number of steps.
    public var totalSteps: Int {
        steps.count
    }

    /// 1-based display index for the current step clamped to valid bounds [0, totalSteps].
    public var displayStep: Int {
        guard totalSteps > 0 else { return 0 }
        return min(max(1, currentStep + 1), totalSteps)
    }

    /// Initializes a step progress indicator with an explicit array of step statuses.
    public init(
        steps: [CraftStepStatus],
        currentStep: Int,
        height: CGFloat = 4,
        spacing: CGFloat = 4,
        showCounter: Bool = true,
        counterStyle: CraftStepCounterStyle = .ratio
    ) {
        self.steps = steps
        self.currentStep = currentStep
        self.height = height
        self.spacing = spacing
        self.showCounter = showCounter
        self.counterStyle = counterStyle
    }

    /// Initializes a step progress indicator by computing statuses for a given total step count and active step index.
    public init(
        totalSteps: Int,
        currentStep: Int,
        height: CGFloat = 4,
        spacing: CGFloat = 4,
        showCounter: Bool = true,
        counterStyle: CraftStepCounterStyle = .ratio
    ) {
        let safeTotal = max(0, totalSteps)
        self.steps = (0..<safeTotal).map { index in
            if index < currentStep {
                return .completed(isCorrect: true)
            } else if index == currentStep {
                return .active
            } else {
                return .unreached
            }
        }
        self.currentStep = currentStep
        self.height = height
        self.spacing = spacing
        self.showCounter = showCounter
        self.counterStyle = counterStyle
    }

    /// Returns the semantic theme color corresponding to a `CraftStepStatus`.
    public func color(for status: CraftStepStatus) -> Color {
        switch status {
        case .unreached:
            return theme.colors.surfaceSubtle
        case .active:
            return theme.colors.brandPrimary
        case .completed(let isCorrect):
            return isCorrect ? theme.colors.statusSuccess : theme.colors.statusDanger
        case .custom(let customColor):
            return customColor
        }
    }

    public var body: some View {
        VStack(spacing: theme.spacing.xs) {
            // Segmented Interval Progress Capsules
            if !steps.isEmpty {
                HStack(spacing: spacing) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Capsule()
                            .fill(color(for: steps[index]))
                            .frame(height: height)
                            .frame(maxWidth: .infinity)
                    }
                }
                .animation(reduceMotion ? nil : theme.animations.springSmooth, value: steps)
            }

            // Optional Step Counter
            if showCounter && counterStyle != .hidden && totalSteps > 0 {
                counterView
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(CraftLocalized.string("craft.progress.label"))
        .accessibilityValue(accessibilityValueString)
    }

    @ViewBuilder
    private var counterView: some View {
        switch counterStyle {
        case .ratio:
            Text("\(displayStep) / \(totalSteps)")
                .font(theme.typography.caption)
                .monospacedDigit()
                .fontWeight(.bold)
                .foregroundStyle(theme.colors.textMuted)
        case .phrase:
            Text(CraftLocalized.format("craft.step_progress.a11y_value_format", displayStep, totalSteps))
                .font(theme.typography.caption)
                .monospacedDigit()
                .fontWeight(.bold)
                .foregroundStyle(theme.colors.textMuted)
        case .hidden:
            EmptyView()
        }
    }

    private var accessibilityValueString: String {
        if totalSteps == 0 {
            return CraftLocalized.string("craft.common.state.empty")
        }
        return CraftLocalized.format("craft.step_progress.a11y_value_format", displayStep, totalSteps)
    }
}

// MARK: - SwiftUI Preview

#Preview("CraftStepProgressIndicator") {
    VStack(spacing: 24) {
        CraftStepProgressIndicator(totalSteps: 10, currentStep: 2)

        CraftStepProgressIndicator(
            steps: [
                .completed(isCorrect: true),
                .completed(isCorrect: true),
                .completed(isCorrect: false),
                .active,
                .unreached,
                .unreached
            ],
            currentStep: 3,
            counterStyle: .phrase
        )

        CraftStepProgressIndicator(
            totalSteps: 5,
            currentStep: 4,
            showCounter: false
        )
    }
    .padding()
}
