import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - CraftCountdownOverlay

/// A fullscreen 3-2-1 countdown modal overlay before starting speed drills or reflex challenges,
/// with spring scale bounces, haptic feedback ticks, and celebratory GO completion.
public struct CraftCountdownOverlay: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let startNumber: Int
    public let title: String?
    public let goText: String
    public let onFinish: () -> Void

    @State private var currentCount: Int
    @State private var isShowingGo: Bool = false
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0.0

    public init(
        startNumber: Int = 3,
        title: String? = nil,
        goText: String = "GO!",
        onFinish: @escaping () -> Void
    ) {
        self.startNumber = max(1, startNumber)
        self.title = title
        self.goText = goText
        self.onFinish = onFinish
        self._currentCount = State(initialValue: max(1, startNumber))
    }

    public var body: some View {
        ZStack {
            // Fullscreen Backdrop
            theme.colors.canvasBackground
                .opacity(0.92)
                .ignoresSafeArea()

            VStack(spacing: theme.spacing.lg) {
                if let title = title {
                    CraftText(
                        title,
                        style: .titleMedium,
                        color: theme.colors.textSecondary
                    )
                    .transition(.opacity)
                }

                // Animated Number or GO!
                ZStack {
                    if isShowingGo {
                        CraftText(
                            goText,
                            style: .displayLarge,
                            color: theme.colors.statusSuccess
                        )
                        .font(.system(size: 72, weight: .black, design: .rounded))
                    } else {
                        CraftText(
                            "\(currentCount)",
                            style: .displayLarge,
                            color: theme.colors.brandPrimary
                        )
                        .font(.system(size: 96, weight: .heavy, design: .rounded))
                    }
                }
                .scaleEffect(reduceMotion ? 1.0 : scale)
                .opacity(opacity)
            }
        }
        .task {
            await runCountdown()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isShowingGo ? goText : "Countdown \(currentCount)")
    }

    // MARK: - Countdown Loop

    @MainActor
    private func runCountdown() async {
        for number in stride(from: startNumber, through: 1, by: -1) {
            currentCount = number
            isShowingGo = false
            triggerHapticTick(isFinal: false)
            animateBounce()

            // 0.85s delay per count
            try? await Task.sleep(nanoseconds: 850_000_000)
        }

        // Final GO!
        isShowingGo = true
        triggerHapticTick(isFinal: true)
        animateBounce()

        // 0.65s delay on GO before completion
        try? await Task.sleep(nanoseconds: 650_000_000)
        onFinish()
    }

    private func animateBounce() {
        if reduceMotion {
            opacity = 1.0
            return
        }

        scale = 0.4
        opacity = 0.2

        withAnimation(theme.animations.springBouncy) {
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
    public let goText: String
    public let onFinish: () -> Void

    public init(
        isPresented: Binding<Bool>,
        startNumber: Int = 3,
        title: String? = nil,
        goText: String = "GO!",
        onFinish: @escaping () -> Void
    ) {
        self._isPresented = isPresented
        self.startNumber = startNumber
        self.title = title
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
    ///   - goText: Text displayed on countdown completion (default: "GO!").
    ///   - onFinish: Callback executed when the countdown completes and "GO!" finishes animating.
    /// - Returns: A view modified with the countdown modal overlay.
    func craftCountdown(
        isPresented: Binding<Bool>,
        startNumber: Int = 3,
        title: String? = nil,
        goText: String = "GO!",
        onFinish: @escaping () -> Void
    ) -> some View {
        modifier(CraftCountdownModifier(
            isPresented: isPresented,
            startNumber: startNumber,
            title: title,
            goText: goText,
            onFinish: onFinish
        ))
    }
}

// MARK: - Previews

#Preview("Countdown Overlay") {
    CraftCountdownOverlay(startNumber: 3, title: "Speed Drill") {}
}
