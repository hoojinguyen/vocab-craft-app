import CraftUIKit
import SwiftUI

/// Outer card container view for Reflex modes with Bento styling, token-driven shadows,
/// and haptic shake feedback on incorrect answers.
public struct ReflexCardContainerView<Content: View>: View {
    @Environment(\.craftTheme) private var theme

    public let isReviewed: Bool
    public let isCorrect: Bool
    public let isTimeout: Bool
    public let timerStage: ReflexBlitzTimerStage
    @ViewBuilder public let content: () -> Content

    @State private var shakeOffset: CGFloat = 0

    public init(
        isReviewed: Bool = false,
        isCorrect: Bool = false,
        isTimeout: Bool = false,
        timerStage: ReflexBlitzTimerStage = .steady,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isReviewed = isReviewed
        self.isCorrect = isCorrect
        self.isTimeout = isTimeout
        self.timerStage = timerStage
        self.content = content
    }

    public var cardBorderColor: Color {
        theme.colors.hairline.opacity(0.4)
    }

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            content()
        }
        .padding(theme.spacing.lg)
        .frame(maxWidth: .infinity)
        .background(theme.colors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.xl, style: .continuous)
                .stroke(cardBorderColor, lineWidth: 1)
        )
        .shadow(color: theme.shadows.lg.color, radius: theme.shadows.lg.radius, x: theme.shadows.lg.x, y: theme.shadows.lg.y)
        .offset(x: shakeOffset)
        .padding(.horizontal, theme.spacing.base)
        .onChange(of: isReviewed) { _, reviewed in
            if reviewed && !isCorrect {
                withAnimation(.spring(response: 0.15, dampingFraction: 0.2, blendDuration: 0.15)) {
                    shakeOffset = 6
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(150))
                    shakeOffset = 0
                }
            }
        }
    }
}
