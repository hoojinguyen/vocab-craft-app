import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - CraftStreakCelebrationSheet Component

/// A celebratory modal sheet presented when the user extends or hits a milestone streak.
/// Features a pop-in hero flame icon, particle effects (sparkles/confetti), count-up animation,
/// mini 7-day progress track, motivational badge/messages, and a primary action button.
public struct CraftStreakCelebrationSheet: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let currentStreak: Int
    public let previousStreak: Int
    public let weekDays: [CraftStreakDay]
    public let customAccessibilityLabel: String?
    public let customAccessibilityHint: String?
    public let onContinue: () -> Void

    @State private var isParticleActive: Bool = false
    @State private var heroScale: CGFloat = 0.2
    @State private var heroOpacity: Double = 0.0
    @State private var displayedStreak: Int
    @State private var contentOpacity: Double = 0.0

    /// Visual tier derived from the current streak count.
    public var tier: CraftStreakTier {
        CraftStreakTier.tier(for: currentStreak)
    }

    /// Indicates whether this streak increment represents a significant milestone.
    public var isMilestone: Bool {
        let milestoneDays: Set<Int> = [7, 14, 21, 30, 50, 60, 90, 100, 180, 365]
        let tierChanged = CraftStreakTier.tier(for: currentStreak) != CraftStreakTier.tier(for: previousStreak)
        return milestoneDays.contains(currentStreak) || (currentStreak > 0 && currentStreak % 50 == 0) || tierChanged
    }

    public init(
        currentStreak: Int,
        previousStreak: Int,
        weekDays: [CraftStreakDay] = [],
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        onContinue: @escaping () -> Void
    ) {
        self.currentStreak = currentStreak
        self.previousStreak = previousStreak
        self.weekDays = weekDays
        self.customAccessibilityLabel = accessibilityLabel
        self.customAccessibilityHint = accessibilityHint
        self.onContinue = onContinue
        self._displayedStreak = State(initialValue: previousStreak)
    }

    public var body: some View {
        ZStack {
            // Particle burst (Confetti for milestone, Sparkles for streak extension)
            CraftSparkleView(
                isTriggered: $isParticleActive,
                style: isMilestone ? .confetti : .sparkles,
                particleCount: isMilestone ? 40 : 25
            )

            VStack(spacing: theme.spacing.lg) {
                // Top Grab Handle Indicator
                Capsule()
                    .fill(theme.colors.borderDefault)
                    .frame(width: 36, height: 4)
                    .padding(.top, theme.spacing.xs)
                    .accessibilityHidden(true)

                Spacer(minLength: theme.spacing.xs)

                // Hero Flame & Count Up Section
                heroFlameSection

                // Motivational Text Section
                motivationalTextSection

                // 7-Day Mini Track (if available)
                if !weekDays.isEmpty {
                    weekTrackSection
                }

                Spacer(minLength: theme.spacing.sm)

                // Continue Action Button
                continueButton
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.bottom, theme.spacing.xl)
            .frame(maxWidth: .infinity)
        }
        .background(theme.colors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.xl))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.xl)
                .strokeBorder(theme.colors.borderDefault.opacity(0.4), lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.xl)
                .strokeBorder(theme.depths.topHighlight, lineWidth: 1.5)
        )
        .craftShadow(theme.shadows.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelString)
        .accessibilityHint(accessibilityHintString)
        .onAppear {
            triggerAppearSequence()
        }
    }

    // MARK: - Hero Flame Section

    private var heroFlameSection: some View {
        VStack(spacing: theme.spacing.sm) {
            ZStack {
                // Outer subtle glow halo
                Circle()
                    .fill(tierBaseColor.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .blur(radius: 8)

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

                // Large Flame Icon with Tier Gradient
                Image(systemName: CraftSymbol.streak.rawValue)
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(tierGradient)
            }
            .scaleEffect(reduceMotion ? 1.0 : heroScale)
            .opacity(reduceMotion ? 1.0 : heroOpacity)

            // Animated Streak Counter
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(displayedStreak)")
                    .font(theme.typography.displayHero)
                    .monospacedDigit()
                    .foregroundStyle(theme.colors.textPrimary)

                Text("NGÀY")
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
                .padding(.horizontal, theme.spacing.sm)
        }
        .opacity(reduceMotion ? 1.0 : contentOpacity)
    }

    private var titleText: String {
        if isMilestone {
            return "Cột mốc \(currentStreak) ngày!"
        } else {
            return "Chuỗi ngày rực lửa!"
        }
    }

    private var motivationalMessage: String {
        switch tier {
        case .starter:
            if currentStreak <= 1 {
                return "Khởi đầu tuyệt vời! Hãy duy trì thói quen học mỗi ngày nhé."
            } else {
                return "Tuyệt vời! Bạn đang xây dựng một thói quen học tập vững chắc."
            }
        case .blaze:
            if isMilestone {
                return "Đẳng cấp! Bạn đã đạt chuỗi rực lửa, tiếp tục duy trì đà tiến bộ này!"
            } else {
                return "Phong độ tuyệt vời! Ngọn lửa học tập của bạn đang rực sáng."
            }
        case .legendary:
            if isMilestone {
                return "Huyền thoại! Bạn đã chinh phục cột mốc đỉnh cao với sự kiên trì phi thường!"
            } else {
                return "Không thể ngăn cản! Bạn là tấm gương học tập đầy cảm hứng."
            }
        }
    }

    // MARK: - 7-Day Mini Track Section

    private var weekTrackSection: some View {
        VStack(spacing: theme.spacing.xs) {
            HStack(spacing: theme.spacing.xs) {
                ForEach(weekDays) { day in
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
    private func dayNode(for day: CraftStreakDay) -> some View {
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
                case .frozen:
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
            "Tiếp tục học",
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

    private func triggerAppearSequence() {
        #if os(iOS)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.prepare()
        impact.impactOccurred()
        #endif

        if reduceMotion {
            displayedStreak = currentStreak
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

        if previousStreak < currentStreak {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 200_000_000)
                guard !Task.isCancelled else { return }

                let stepDelay = max(30_000_000, 400_000_000 / UInt64(max(1, currentStreak - previousStreak)))
                for val in (previousStreak + 1)...currentStreak {
                    displayedStreak = val
                    #if os(iOS)
                    let selectionFeedback = UISelectionFeedbackGenerator()
                    selectionFeedback.selectionChanged()
                    #endif
                    try? await Task.sleep(nanoseconds: stepDelay)
                    guard !Task.isCancelled else { return }
                }
            }
        } else {
            displayedStreak = currentStreak
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
            return Color(hex: 0x8B5CF6)
        }
    }

    private var tierRimColor: Color {
        switch tier {
        case .starter:
            return Color(hex: 0xC2410C)
        case .blaze:
            return Color(hex: 0xB45309)
        case .legendary:
            return Color(hex: 0x6D28D9)
        }
    }

    // MARK: - Accessibility Strings

    private var accessibilityLabelString: String {
        if let customAccessibilityLabel {
            return customAccessibilityLabel
        }
        let milestonePrefix = isMilestone ? "Chúc mừng đạt cột mốc! " : "Chúc mừng! "
        return "\(milestonePrefix)Chuỗi \(currentStreak) ngày học liên tiếp. Cấp độ \(tier.rawValue). \(motivationalMessage)"
    }

    private var accessibilityHintString: String {
        if let customAccessibilityHint {
            return customAccessibilityHint
        }
        return "Chạm vào nút Tiếp tục học để đóng màn hình chúc mừng."
    }
}

// MARK: - Previews

#Preview("Celebration Sheet - Milestone 7") {
    let mockDays: [CraftStreakDay] = [
        .init(id: "1", weekdaySymbol: "T2", status: .completed),
        .init(id: "2", weekdaySymbol: "T3", status: .completed),
        .init(id: "3", weekdaySymbol: "T4", status: .completed),
        .init(id: "4", weekdaySymbol: "T5", status: .completed),
        .init(id: "5", weekdaySymbol: "T6", status: .completed),
        .init(id: "6", weekdaySymbol: "T7", status: .completed),
        .init(id: "7", weekdaySymbol: "CN", status: .completed, isToday: true)
    ]

    CraftStreakCelebrationSheet(
        currentStreak: 7,
        previousStreak: 6,
        weekDays: mockDays,
        onContinue: {}
    )
    .padding()
}

#Preview("Celebration Sheet - Legendary 30") {
    CraftStreakCelebrationSheet(
        currentStreak: 30,
        previousStreak: 29,
        weekDays: [],
        onContinue: {}
    )
    .padding()
}
