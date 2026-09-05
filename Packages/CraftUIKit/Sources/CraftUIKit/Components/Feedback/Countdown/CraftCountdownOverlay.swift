import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - CraftCountdownOverlay

/// A fullscreen 3-2-1 countdown modal overlay before starting speed drills or reflex challenges,
/// featuring an opaque backdrop, ambient radial glow, hero SF Symbol, 92pt rounded typography,
/// spring bounce animations, haptic feedback ticks, and tap-to-skip gestures.
public struct CraftCountdownOverlay: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let startNumber: Int
    public let title: String?
    public let subtitle: String?
    public let iconName: String?
    public let tintColor: Color?
    public let goText: String
    public let onFinish: () -> Void

    @State private var sequence: CountdownSequence
    @State private var scale: CGFloat = 0.35
    @State private var opacity: Double = 0.0

    public init(
        startNumber: Int = 3,
        title: String? = nil,
        subtitle: String? = nil,
        iconName: String? = nil,
        tintColor: Color? = nil,
        goText: String = CraftLocalized.string("craft.countdown.go_text"),
        clock: CountdownClock = SystemCountdownClock(),
        haptics: (any CountdownHapticDriving)? = nil,
        onFinish: @escaping () -> Void
    ) {
        let clamped = max(1, startNumber)
        self.startNumber = clamped
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.tintColor = tintColor
        self.goText = goText
        self.onFinish = onFinish
        self._sequence = State(initialValue: CountdownSequence(
            startNumber: clamped,
            clock: clock,
            haptics: haptics ?? CountdownHapticDriver.shared,
            onFinish: onFinish
        ))
    }

    public init(
        sequence: CountdownSequence,
        title: String? = nil,
        subtitle: String? = nil,
        iconName: String? = nil,
        tintColor: Color? = nil,
        goText: String = CraftLocalized.string("craft.countdown.go_text"),
        onFinish: @escaping () -> Void
    ) {
        self.startNumber = sequence.startNumber
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.tintColor = tintColor
        self.goText = goText
        self.onFinish = onFinish
        if sequence.onFinish == nil {
            sequence.onFinish = onFinish
        }
        self._sequence = State(initialValue: sequence)
    }

    private var effectiveTint: Color {
        tintColor ?? theme.colors.brandPrimary
    }

    public var body: some View {
        ZStack {
            // Fullscreen 100% Opaque Backdrop
            theme.colors.canvasBackground
                .ignoresSafeArea()

            // Subtle Ambient Radial Glow centered behind the countdown
            RadialGradient(
                colors: [
                    (sequence.isShowingGo ? theme.colors.statusSuccess : effectiveTint).opacity(0.28),
                    (sequence.isShowingGo ? theme.colors.statusSuccess : effectiveTint).opacity(0.08),
                    Color.clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 260
            )
            .ignoresSafeArea()

            // Center Content
            VStack(spacing: theme.spacing.xl) {
                // Header section: Hero Icon, Title & Subtitle
                VStack(spacing: theme.spacing.sm) {
                    if let iconName = iconName {
                        Image(systemName: iconName)
                            .font(.system(size: 48, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(effectiveTint)
                            .symbolEffect(.pulse, options: .repeating, isActive: !reduceMotion)
                            .symbolEffectsRemoved(reduceMotion)
                            .padding(.bottom, theme.spacing.xs)
                            .accessibilityHidden(true)
                    }

                    if let title = title {
                        Text(title)
                            .font(theme.typography.titleLarge.bold())
                            .foregroundStyle(theme.colors.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, theme.spacing.lg)
                            .transition(.opacity)
                    }

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(theme.typography.bodyMedium)
                            .foregroundStyle(theme.colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, theme.spacing.xl)
                            .transition(.opacity)
                    }
                }

                // Grand Countdown Number or GO!
                ZStack {
                    Text(sequence.isShowingGo ? goText : "\(sequence.currentCount)")
                        .font(.system(size: 92, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: sequence.isShowingGo
                                    ? [theme.colors.statusSuccess, theme.colors.statusSuccess.opacity(0.85)]
                                    : [effectiveTint, theme.colors.accent],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(reduceMotion ? 1.0 : scale)
                        .opacity(opacity)
                }
                .frame(minHeight: 110)

                // Tap-to-skip subtle prompt
                Text(CraftLocalized.string("craft.countdown.tap_to_skip"))
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textMuted)
                    .padding(.top, theme.spacing.sm)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            sequence.skip()
        }
        .task {
            sequence.onTick = { _ in
                animateBounce()
            }
            sequence.onGo = {
                animateBounce()
            }
            animateBounce()
            await sequence.run()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(sequence.isShowingGo ? goText : CraftLocalized.format("craft.countdown.label_format", sequence.currentCount))
        .accessibilityHint(CraftLocalized.string("craft.countdown.tap_to_skip_hint"))
        .accessibilityAddTraits(.isButton)
    }

    private func animateBounce() {
        if reduceMotion {
            scale = 1.0
            opacity = 1.0
            return
        }

        scale = 0.35
        opacity = 0.2

        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            scale = 1.0
            opacity = 1.0
        }
    }
}

// MARK: - Countdown View Modifier

public struct CraftCountdownModifier: ViewModifier {
    @Binding public var isPresented: Bool
    public let startNumber: Int
    public let title: String?
    public let subtitle: String?
    public let iconName: String?
    public let tintColor: Color?
    public let goText: String
    public let onFinish: () -> Void

    public init(
        isPresented: Binding<Bool>,
        startNumber: Int = 3,
        title: String? = nil,
        subtitle: String? = nil,
        iconName: String? = nil,
        tintColor: Color? = nil,
        goText: String = CraftLocalized.string("craft.countdown.go_text"),
        onFinish: @escaping () -> Void
    ) {
        self._isPresented = isPresented
        self.startNumber = startNumber
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.tintColor = tintColor
        self.goText = goText
        self.onFinish = onFinish
    }

    public func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                CraftCountdownOverlay(
                    startNumber: startNumber,
                    title: title,
                    subtitle: subtitle,
                    iconName: iconName,
                    tintColor: tintColor,
                    goText: goText
                ) {
                    isPresented = false
                    onFinish()
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Presents a fullscreen countdown overlay before executing a drill or sprint challenge.
    ///
    /// - Parameters:
    ///   - isPresented: Binding controlling the presentation of the countdown overlay.
    ///   - startNumber: Starting integer count (default: 3).
    ///   - title: Optional contextual title (e.g. "Get Ready!").
    ///   - subtitle: Optional directive or prompt (e.g. "Translate fast!").
    ///   - iconName: Optional hero SF Symbol name.
    ///   - tintColor: Optional ambient tint color (defaults to brand primary).
    ///   - goText: Text displayed on countdown completion (default: localized "GO!").
    ///   - onFinish: Callback executed when the countdown completes or is skipped.
    /// - Returns: A view modified with the countdown modal overlay.
    func craftCountdown(
        isPresented: Binding<Bool>,
        startNumber: Int = 3,
        title: String? = nil,
        subtitle: String? = nil,
        iconName: String? = nil,
        tintColor: Color? = nil,
        goText: String = CraftLocalized.string("craft.countdown.go_text"),
        onFinish: @escaping () -> Void
    ) -> some View {
        modifier(CraftCountdownModifier(
            isPresented: isPresented,
            startNumber: startNumber,
            title: title,
            subtitle: subtitle,
            iconName: iconName,
            tintColor: tintColor,
            goText: goText,
            onFinish: onFinish
        ))
    }
}

// MARK: - Previews

#if canImport(PreviewsMacros)
#Preview("Countdown Overlay - Default") {
    CraftCountdownOverlay(
        startNumber: 3,
        title: "Speed Drill",
        subtitle: "Answer within 3 seconds!",
        iconName: "bolt.fill"
    ) {}
}
#endif

#if canImport(PreviewsMacros)
#Preview("Countdown Overlay - Minimal") {
    CraftCountdownOverlay(startNumber: 3) {}
}
#endif
