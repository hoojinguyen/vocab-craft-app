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
                .modifier(
                    ShimmerAnimatableModifier(
                        phase: phase,
                        highlightColor: theme.colors.surfaceElevated.opacity(0.5),
                        reduceMotion: reduceMotion
                    )
                )
                .onAppear {
                    startAnimation()
                }
                .onChange(of: reduceMotion) { _, newValue in
                    if !newValue {
                        startAnimation()
                    }
                }
        } else {
            content
        }
    }

    private func startAnimation() {
        guard !reduceMotion else { return }
        phase = -1.0
        withAnimation(
            .linear(duration: duration)
            .repeatForever(autoreverses: bounce)
        ) {
            phase = 1.0
        }
    }
}

// MARK: - Isolated Animatable Modifier

private struct ShimmerAnimatableModifier: AnimatableModifier {
    var phase: CGFloat
    let highlightColor: Color
    let reduceMotion: Bool

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let height = proxy.size.height

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


#if canImport(PreviewsMacros)
#Preview("ShimmerModifier") {
    VStack(spacing: 24) {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.2))
            .frame(height: 100)
            .craftShimmer(isActive: true)
            
        HStack(spacing: 16) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .craftShimmer(isActive: true, bounce: true)
                
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 160, height: 16)
                    
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 16)
            }
            .craftShimmer(isActive: true)
            Spacer()
        }
    }
    .padding()
}
#endif
