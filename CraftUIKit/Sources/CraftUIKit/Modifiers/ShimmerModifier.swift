import SwiftUI

// MARK: - Shimmer Modifier

/// A view modifier that sweeps an animated gradient across the view, indicating a loading skeleton state.
/// Respects accessibility reduce motion and adapts seamlessly to dark mode.
public struct CraftShimmerModifier: ViewModifier {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1.0

    public let isActive: Bool
    public let duration: Double
    public let bounce: Bool

    public init(isActive: Bool = true, duration: Double = 1.5, bounce: Bool = false) {
        self.isActive = isActive
        self.duration = duration
        self.bounce = bounce
    }

    public func body(content: Content) -> some View {
        if isActive {
            content
                .overlay(
                    GeometryReader { proxy in
                        let width = proxy.size.width
                        let height = proxy.size.height
                        let highlightColor = theme.colors.surfaceElevated.opacity(0.5)

                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: highlightColor, location: 0.5),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: max(width * 1.5, 100), height: max(height * 1.5, 100))
                        .offset(x: reduceMotion ? 0 : phase * (width + 100))
                        .blendMode(.screen)
                        .mask(content)
                    }
                )
                .onAppear {
                    guard !reduceMotion else { return }
                    withAnimation(
                        .linear(duration: duration)
                        .repeatForever(autoreverses: bounce)
                    ) {
                        phase = 1.0
                    }
                }
        } else {
            content
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Applies an animated shimmer loading sweep across the view.
    ///
    /// - Parameters:
    ///   - isActive: Whether the shimmer animation is actively running (default: true).
    ///   - duration: The duration in seconds for one complete shimmer cycle (default: 1.5).
    ///   - bounce: Whether the shimmer reverses back and forth (default: false).
    /// - Returns: A view with shimmering skeleton effect when active.
    func craftShimmer(isActive: Bool = true, duration: Double = 1.5, bounce: Bool = false) -> some View {
        modifier(CraftShimmerModifier(isActive: isActive, duration: duration, bounce: bounce))
    }
}

