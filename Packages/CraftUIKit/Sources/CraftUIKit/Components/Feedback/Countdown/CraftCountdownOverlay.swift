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

    @State private var currentCount: Int
    @State private var isShowingGo: Bool = false
    @State private var scale: CGFloat = 0.35
    @State private var opacity: Double = 0.0
    @State private var isFinished: Bool = false

    public init(
        startNumber: Int = 3,
        title: String? = nil,
        subtitle: String? = nil,
        iconName: String? = nil,
        tintColor: Color? = nil,
        goText: String = CraftLocalized.string("craft.countdown.go_text"),
        onFinish: @escaping () -> Void
    ) {
        self.startNumber = max(1, startNumber)
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.tintColor = tintColor
        self.goText = goText
        self.onFinish = onFinish
        self._currentCount = State(initialValue: max(1, startNumber))
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
                    (isShowingGo ? theme.colors.statusSuccess : effectiveTint).opacity(0.28),
                    (isShowingGo ? theme.colors.statusSuccess : effectiveTint).opacity(0.08),
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
                    Text(isShowingGo ? goText : "\(currentCount)")
                        .font(.system(size: 92, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: isShowingGo
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
            skipCountdown()
        }
        .task {
            await runCountdown()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isShowingGo ? goText : CraftLocalized.format("craft.countdown.label_format", currentCount))
        .accessibilityHint(CraftLocalized.string("craft.countdown.tap_to_skip_hint"))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Skip Action

    @MainActor
    private func skipCountdown() {
        guard !isFinished else { return }
        isFinished = true
        triggerHapticTick(isFinal: true)
        onFinish()
    }

    // MARK: - Countdown Loop

    @MainActor
    private func runCountdown() async {
        for number in stride(from: startNumber, through: 1, by: -1) {
            guard !Task.isCancelled && !isFinished else { return }
            currentCount = number
            isShowingGo = false
            triggerHapticTick(isFinal: false)
            animateBounce()

            // 0.85s delay per count
            do {
                try await Task.sleep(nanoseconds: 850_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled && !isFinished else { return }
        }

        // Final GO!
        isShowingGo = true
        triggerHapticTick(isFinal: true)
        animateBounce()

        // 0.65s delay on GO before completion
        do {
            try await Task.sleep(nanoseconds: 650_000_000)
        } catch {
            return
        }
        guard !Task.isCancelled && !isFinished else { return }
        isFinished = true
        onFinish()
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

    private func triggerHapticTick(isFinal: Bool) {
        #if os(iOS)
        if isFinal {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        } else {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
        #endif
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

#Preview("Countdown Overlay - Default") {
    CraftCountdownOverlay(
        startNumber: 3,
        title: "Speed Drill",
        subtitle: "Answer within 3 seconds!",
        iconName: "bolt.fill"
    ) {}
}

#Preview("Countdown Overlay - Minimal") {
    CraftCountdownOverlay(startNumber: 3) {}
}
