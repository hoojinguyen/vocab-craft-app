import SwiftUI

// MARK: - CraftCountdownStage

/// Lifecycle warning stage for a countdown timer based on remaining time fraction.
public enum CraftCountdownStage: String, CaseIterable, Sendable, Equatable, Hashable {
    /// Steady stage (remaining fraction > 40%)
    case steady
    /// Warning stage (15% < remaining fraction <= 40%)
    case warning
    /// Urgent stage (remaining fraction <= 15%)
    case urgent
}

// MARK: - CraftCountdownColorConfig

/// Color and glowing aura configuration for `CraftCountdownTimerBar`.
public struct CraftCountdownColorConfig: Sendable, Equatable {
    /// Optional color override for `.steady` stage. Defaults to `theme.colors.statusSuccess`.
    public var steady: Color?
    /// Optional color override for `.warning` stage. Defaults to `theme.colors.statusWarning`.
    public var warning: Color?
    /// Optional color override for `.urgent` stage. Defaults to `theme.colors.statusDanger`.
    public var urgent: Color?
    /// Optional background track color override. Defaults to `theme.colors.surfaceSubtle`.
    public var trackColor: Color?
    /// Whether to render a glowing aura shadow around the active progress bar. Defaults to `true`.
    public var showGlow: Bool
    /// Blur radius of the glowing aura shadow. Defaults to `6`.
    public var glowRadius: CGFloat

    public init(
        steady: Color? = nil,
        warning: Color? = nil,
        urgent: Color? = nil,
        trackColor: Color? = nil,
        showGlow: Bool = true,
        glowRadius: CGFloat = 6
    ) {
        self.steady = steady
        self.warning = warning
        self.urgent = urgent
        self.trackColor = trackColor
        self.showGlow = showGlow
        self.glowRadius = glowRadius
    }
}

// MARK: - CraftCountdownTimerBar

/// A linear countdown timer bar supporting Hybrid mode: Time-Driven and Fraction-Driven,
/// dynamic warning stage colors, glowing aura shadow, battery efficiency via paused TimelineView,
/// and VoiceOver accessibility.
public struct CraftCountdownTimerBar: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let progress: Double?
    public let stage: CraftCountdownStage?
    public let startDate: Date?
    public let timeLimit: TimeInterval?
    public let isActive: Bool
    public let height: CGFloat
    public let cornerRadius: CGFloat?
    public let colorConfig: CraftCountdownColorConfig
    public let animated: Bool
    public let onTimeout: (() -> Void)?

    private var isTimeDriven: Bool {
        progress == nil && timeLimit != nil
    }

    /// Composite equatable identifier for time-driven background task scheduling.
    private struct TimeDrivenTaskID: Equatable, Hashable {
        let isActive: Bool
        let startDate: Date
        let timeLimit: TimeInterval
    }

    /// Returns the clamped progress in [0.0, 1.0] range.
    public var clampedProgress: Double {
        if let progress = progress {
            return min(max(progress, 0.0), 1.0)
        }
        guard let timeLimit = timeLimit, timeLimit > 0 else { return 0.0 }
        let elapsed = Date().timeIntervalSince(startDate ?? Date())
        let remaining = max(0.0, timeLimit - elapsed)
        return min(max(remaining / timeLimit, 0.0), 1.0)
    }

    /// Derives the countdown stage for a given fraction value.
    /// - > 40%: .steady
    /// - 15% ... 40%: .warning
    /// - <= 15%: .urgent
    public static func deriveStage(for progress: Double) -> CraftCountdownStage {
        if progress > 0.40 {
            return .steady
        } else if progress > 0.15 {
            return .warning
        } else {
            return .urgent
        }
    }

    /// Initializes a Fraction-Driven countdown timer bar.
    public init(
        progress: Double,
        stage: CraftCountdownStage? = nil,
        height: CGFloat = 8,
        cornerRadius: CGFloat? = nil,
        colorConfig: CraftCountdownColorConfig = CraftCountdownColorConfig(),
        animated: Bool = true
    ) {
        self.progress = progress
        self.stage = stage
        self.startDate = nil
        self.timeLimit = nil
        self.isActive = false
        self.height = height
        self.cornerRadius = cornerRadius
        self.colorConfig = colorConfig
        self.animated = animated
        self.onTimeout = nil
    }

    /// Initializes a Time-Driven countdown timer bar.
    public init(
        startDate: Date = Date(),
        timeLimit: TimeInterval,
        isActive: Bool = true,
        stage: CraftCountdownStage? = nil,
        height: CGFloat = 8,
        cornerRadius: CGFloat? = nil,
        colorConfig: CraftCountdownColorConfig = CraftCountdownColorConfig(),
        animated: Bool = true,
        onTimeout: (() -> Void)? = nil
    ) {
        self.progress = nil
        self.stage = stage
        self.startDate = startDate
        self.timeLimit = timeLimit
        self.isActive = isActive
        self.height = height
        self.cornerRadius = cornerRadius
        self.colorConfig = colorConfig
        self.animated = animated
        self.onTimeout = onTimeout
    }

    public var body: some View {
        if let progress = progress {
            let clamped = min(max(progress, 0.0), 1.0)
            renderBar(fraction: clamped)
        } else if let timeLimit = timeLimit, let startDate = startDate {
            TimelineView(.animation(paused: !isActive)) { timeline in
                let elapsed = timeline.date.timeIntervalSince(startDate)
                let remaining = max(0.0, timeLimit - elapsed)
                let fraction = timeLimit > 0 ? min(max(remaining / timeLimit, 0.0), 1.0) : 0.0
                renderBar(fraction: fraction)
            }
            .task(id: TimeDrivenTaskID(isActive: isActive, startDate: startDate, timeLimit: timeLimit)) {
                guard isActive else { return }
                let elapsed = Date().timeIntervalSince(startDate)
                let remaining = timeLimit - elapsed
                if remaining <= 0 {
                    onTimeout?()
                    return
                }
                let nanoseconds = UInt64(remaining * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanoseconds)
                guard !Task.isCancelled else { return }
                if isActive {
                    onTimeout?()
                }
            }
        } else {
            renderBar(fraction: 0.0)
        }
    }

    // MARK: - Bar Rendering

    @ViewBuilder
    private func renderBar(fraction: Double) -> some View {
        let radius = cornerRadius ?? (height / 2)
        let currentStage = stage ?? Self.deriveStage(for: fraction)
        let fillColor = stageColor(for: currentStage)
        let track = colorConfig.trackColor ?? theme.colors.surfaceSubtle
        let animation = (isTimeDriven || !animated || reduceMotion) ? nil : theme.animations.springSmooth

        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background Track
                RoundedRectangle(cornerRadius: radius)
                    .fill(track)
                    .frame(height: height)

                // Filled Progress Bar with Glow
                if fraction > 0 {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(fillColor)
                        .frame(width: geometry.size.width * CGFloat(fraction), height: height)
                        .shadow(
                            color: colorConfig.showGlow ? fillColor.opacity(0.45) : .clear,
                            radius: colorConfig.showGlow ? colorConfig.glowRadius : 0,
                            x: 0,
                            y: 0
                        )
                        .animation(
                            animation,
                            value: fraction
                        )
                }
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(CraftLocalized.string("craft.countdown.time_remaining_label"))
        .accessibilityValue(CraftLocalized.format("craft.common.unit.percent_word_format", Int(round(fraction * 100))))
        .accessibilityAddTraits(.updatesFrequently)
    }

    private func stageColor(for stage: CraftCountdownStage) -> Color {
        switch stage {
        case .steady:
            return colorConfig.steady ?? theme.colors.statusSuccess
        case .warning:
            return colorConfig.warning ?? theme.colors.statusWarning
        case .urgent:
            return colorConfig.urgent ?? theme.colors.statusDanger
        }
    }
}

// MARK: - Previews

#if canImport(PreviewsMacros)
#Preview("CraftCountdownTimerBar - Stages") {
    VStack(spacing: 24) {
        CraftCountdownTimerBar(progress: 0.8)
        CraftCountdownTimerBar(progress: 0.3)
        CraftCountdownTimerBar(progress: 0.1)
    }
    .padding()
}
#endif

#if canImport(PreviewsMacros)
#Preview("CraftCountdownTimerBar - Time-Driven") {
    VStack(spacing: 24) {
        CraftCountdownTimerBar(timeLimit: 15, isActive: true)
    }
    .padding()
}
#endif
