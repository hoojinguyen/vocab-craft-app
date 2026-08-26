import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - CraftCelebrationSheet Component

/// A celebratory modal sheet presented when the user achieves a milestone, extends a streak, or completes an activity goal.
public struct CraftCelebrationSheet: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.craftSurfaceStyle) private var environmentSurfaceStyle
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let currentValue: Int
    public let previousValue: Int
    public let unit: String
    public let unitKey: String?
    public let cycleDays: [CraftActivityDay]
    public let icon: CraftNodeIcon
    public let surfaceStyle: CraftSurfaceStyle?
    public let customAccessibilityLabel: String?
    public let customAccessibilityHint: String?
    public let onContinue: () -> Void

    @State private var isParticleActive: Bool = false
    @State private var heroScale: CGFloat = 0.2
    @State private var heroOpacity: Double = 0.0
    @State private var displayedValue: Int
    @State private var contentOpacity: Double = 0.0

    /// Visual tier derived from the current value count.
    public var tier: CraftActivityTier {
        CraftActivityTier.tier(for: currentValue)
    }

    /// Indicates whether this value increment represents a significant milestone.
    public var isMilestone: Bool {
        let milestoneDays: Set<Int> = [7, 14, 21, 30, 50, 60, 90, 100, 180, 365]
        let tierChanged = CraftActivityTier.tier(for: currentValue) != CraftActivityTier.tier(for: previousValue)
        return milestoneDays.contains(currentValue) || (currentValue > 0 && currentValue % 50 == 0) || tierChanged
    }

    public init(
        currentValue: Int,
        previousValue: Int,
        unitKey: String? = nil,
        unit: String = "days",
        cycleDays: [CraftActivityDay] = [],
        icon: CraftNodeIcon = .system(CraftSymbol.streak.rawValue),
        surfaceStyle: CraftSurfaceStyle? = nil,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        onContinue: @escaping () -> Void
    ) {
        self.currentValue = currentValue
        self.previousValue = previousValue
        self.unitKey = unitKey
        self.unit = unit
        self.cycleDays = cycleDays
        self.icon = icon
        self.surfaceStyle = surfaceStyle
        self.customAccessibilityLabel = accessibilityLabel
        self.customAccessibilityHint = accessibilityHint
        self.onContinue = onContinue
        self._displayedValue = State(initialValue: previousValue)
    }

    public var body: some View {
        ZStack {
            // Particle burst (Confetti for milestone, Sparkles for regular celebration)
            CraftSparkleView(
                isTriggered: $isParticleActive,
                style: isMilestone ? .confetti : .sparkles,
                particleCount: isMilestone ? 40 : 25
            )

            VStack(spacing: theme.spacing.base) {
                // Top Grab Handle Indicator
                Capsule()
                    .fill(theme.colors.borderDefault)
                    .frame(width: 36, height: 4)
                    .padding(.top, theme.spacing.xs)
                    .accessibilityHidden(true)

                // Hero Flame & Count Up Section
                heroFlameSection
                    .padding(.top, 2)

                // Motivational Text Section
                motivationalTextSection

                // 7-Day Mini Track (if available)
                if !cycleDays.isEmpty {
                    cycleTrackSection
                }

                Spacer(minLength: theme.spacing.xs)

                // Continue Action Button
                continueButton
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.bottom, theme.spacing.base)
            .frame(maxWidth: .infinity)
        }
        .craftSurface(
            style: surfaceStyle ?? environmentSurfaceStyle,
            shape: RoundedRectangle(cornerRadius: theme.radii.xl)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.xl)
                .strokeBorder(theme.depths.topHighlight, lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelString)
        .accessibilityHint(accessibilityHintString)
        .task {
            await triggerAppearSequence()
        }
    }

    // MARK: - Hero Flame Section

    private var heroFlameSection: some View {
        VStack(spacing: theme.spacing.sm) {
            ZStack {
                // Multi-stop luminous ambient bloom
                RadialGradient(
                    colors: [
                        tierBaseColor.opacity(0.30),
                        tierBaseColor.opacity(0.12),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 20,
                    endRadius: 70
                )
                .frame(width: 140, height: 140)

                // Inner circle background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                tierBaseColor.opacity(0.20),
                                tierBaseColor.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 104, height: 104)
                    .overlay(
                        Circle()
                            .strokeBorder(theme.depths.topHighlight, lineWidth: 1.5)
                    )
                    .craftShadow(theme.shadows.md)

                // Hero Icon with Tier Gradient
                if icon.isSystem {
                    Image(systemName: icon.name)
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(tierGradient)
                } else {
                    Image(icon.name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                }
            }
            .scaleEffect(reduceMotion ? 1.0 : heroScale)
            .opacity(reduceMotion ? 1.0 : heroOpacity)

            // Animated Counter
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(displayedValue)")
                    .font(theme.typography.displayHero)
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: false))
                    .foregroundStyle(theme.colors.textPrimary)

                Text(resolvedUnit.uppercased())
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(tierBaseColor)
            }
            .opacity(reduceMotion ? 1.0 : contentOpacity)
        }
    }

    // MARK: - Motivational Text Section

    private var motivationalTextSection: some View {
        VStack(spacing: theme.spacing.xs) {
            Text(titleText)
                .font(theme.typography.titleLarge)
                .fontWeight(.bold)
                .foregroundStyle(theme.colors.textPrimary)
                .multilineTextAlignment(.center)

            Text(motivationalMessage)
                .font(theme.typography.bodyMedium)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, theme.spacing.sm)
        }
        .opacity(reduceMotion ? 1.0 : contentOpacity)
    }

    private var resolvedUnit: String {
        if let unitKey {
            return CraftLocalized.string(unitKey)
        }
        return unit
    }

    private var titleText: String {
        if isMilestone {
            return CraftLocalized.format("craft.streak.milestoneTitle", currentValue)
        } else {
            return CraftLocalized.string("craft.streak.celebrationTitle")
        }
    }

    private var motivationalMessage: String {
        switch tier {
        case .starter:
            if currentValue <= 1 {
                return CraftLocalized.string("craft.streak.msgStarter1")
            } else {
                return CraftLocalized.string("craft.streak.msgStarter")
            }
        case .blaze:
            if isMilestone {
                return CraftLocalized.string("craft.streak.msgBlazeMilestone")
            } else {
                return CraftLocalized.string("craft.streak.msgBlaze")
            }
        case .legendary:
            if isMilestone {
                return CraftLocalized.string("craft.streak.msgLegendaryMilestone")
            } else {
                return CraftLocalized.string("craft.streak.msgLegendary")
            }
        }
    }

    // MARK: - Cycle Track Section

    private var cycleTrackSection: some View {
        VStack(spacing: theme.spacing.xs) {
            HStack(spacing: theme.spacing.xs) {
                ForEach(cycleDays) { day in
                    VStack(spacing: 4) {
                        Text(day.weekdaySymbol)
                            .font(theme.typography.caption)
                            .fontWeight(day.isToday ? .bold : .medium)
                            .foregroundStyle(day.isToday ? theme.colors.textPrimary : theme.colors.textMuted)

                        dayNode(for: day)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, theme.spacing.sm)
            .padding(.horizontal, theme.spacing.xs)
            .background(theme.colors.surfaceSubtle.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.lg)
                    .strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
            )
        }
        .opacity(reduceMotion ? 1.0 : contentOpacity)
    }

    @ViewBuilder
    private func dayNode(for day: CraftActivityDay) -> some View {
        let size: CGFloat = 28
        let depth = theme.depths.depthSm

        ZStack {
            if day.isToday || day.status == .completed {
                ZStack {
                    // 3D bottom rim
                    Circle()
                        .fill(tierRimColor)
                        .frame(width: size, height: size)
                        .offset(y: depth)

                    // Top face
                    Circle()
                        .fill(tierGradient)
                        .frame(width: size, height: size)
                        .overlay(
                            Circle()
                                .strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
                        )
                        .overlay(
                            Image(systemName: CraftSymbol.streak.rawValue)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        )
                }
                .frame(width: size, height: size + depth)
                .craftShadow(theme.shadows.sm)
            } else {
                switch day.status {
                case .saved:
                    ZStack {
                        Circle()
                            .fill(theme.colors.streakFreeze.opacity(0.35))
                            .frame(width: size, height: size)
                            .offset(y: depth)

                        Circle()
                            .fill(theme.colors.streakFreeze.opacity(0.14))
                            .frame(width: size, height: size)
                            .overlay(
                                Circle()
                                    .strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
                            )
                            .overlay(
                                Image(systemName: "snowflake")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(theme.colors.streakFreeze)
                            )
                    }
                    .frame(width: size, height: size + depth)

                case .missed:
                    Circle()
                        .fill(theme.colors.surfaceSubtle)
                        .frame(width: size, height: size)
                        .overlay(
                            Circle()
                                .strokeBorder(theme.colors.borderDefault.opacity(0.4), lineWidth: 0.5)
                        )
                        .overlay(
                            Circle()
                                .fill(theme.colors.textMuted.opacity(0.4))
                                .frame(width: 4, height: 4)
                        )

                case .upcoming:
                    Circle()
                        .strokeBorder(theme.colors.borderDefault.opacity(0.7), lineWidth: 1.0)
                        .frame(width: size, height: size)

                case .pending:
                    Circle()
                        .strokeBorder(theme.colors.streakPending, style: StrokeStyle(lineWidth: 1.2, dash: [3, 2]))
                        .frame(width: size, height: size)
                        .overlay(
                            Circle()
                                .strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
                        )

                case .completed:
                    EmptyView()
                }
            }
        }
        .frame(width: size, height: size + depth)
    }

    // MARK: - Continue Action Button

    private var continueButton: some View {
        CraftButton(
            CraftLocalized.string("craft.streak.continueAction"),
            iconName: CraftSymbol.chevronRight.rawValue,
            iconPosition: .trailing,
            variant: .tactile,
            size: .lg,
            isFullWidth: true,
            action: onContinue
        )
        .opacity(reduceMotion ? 1.0 : contentOpacity)
    }

    // MARK: - Animation & Lifecycle Sequence

    @MainActor
    private func triggerAppearSequence() async {
        #if os(iOS)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.prepare()
        impact.impactOccurred()
        #endif

        if reduceMotion {
            displayedValue = currentValue
            heroScale = 1.0
            heroOpacity = 1.0
            contentOpacity = 1.0
            return
        }

        isParticleActive = true

        withAnimation(theme.animations.springBouncy) {
            heroScale = 1.0
            heroOpacity = 1.0
        }

        withAnimation(theme.animations.springSmooth.delay(0.15)) {
            contentOpacity = 1.0
        }

        if previousValue < currentValue {
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }

            let stepDelay = max(30_000_000, 400_000_000 / UInt64(max(1, currentValue - previousValue)))
            #if os(iOS)
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.prepare()
            #endif
            for val in (previousValue + 1)...currentValue {
                displayedValue = val
                #if os(iOS)
                selectionFeedback.selectionChanged()
                #endif
                try? await Task.sleep(nanoseconds: stepDelay)
                guard !Task.isCancelled else { return }
            }
        } else {
            displayedValue = currentValue
        }
    }

    // MARK: - Visual Helpers

    private var tierGradient: LinearGradient {
        switch tier {
        case .starter:
            return theme.gradients.streakStarter
        case .blaze:
            return theme.gradients.streakBlaze
        case .legendary:
            return theme.gradients.streakLegendary
        }
    }

    private var tierBaseColor: Color {
        switch tier {
        case .starter:
            return theme.colors.brandPrimary
        case .blaze:
            return theme.colors.accent
        case .legendary:
            return theme.colors.statusDanger
        }
    }

    private var tierRimColor: Color {
        switch tier {
        case .starter:
            return theme.colors.brandPrimary.opacity(0.85)
        case .blaze:
            return theme.colors.accent.opacity(0.85)
        case .legendary:
            return Color.purple.opacity(0.85)
        }
    }

    // MARK: - Accessibility Strings

    private var accessibilityLabelString: String {
        if let customAccessibilityLabel {
            return customAccessibilityLabel
        }
        let milestonePrefix = isMilestone ? "Chúc mừng đạt cột mốc! " : "Chúc mừng! "
        return "\(milestonePrefix)Chuỗi \(currentValue) ngày học liên tiếp. Cấp độ \(tier.rawValue). \(motivationalMessage)"
    }

    private var accessibilityHintString: String {
        if let customAccessibilityHint {
            return customAccessibilityHint
        }
        return "Chạm vào nút Tiếp tục học để đóng màn hình chúc mừng."
    }
}
