import SwiftUI

// MARK: - CraftPulsingAuraRing Component

/// An isolated pulsing aura ring that uses `PhaseAnimator` to animate breathing/pulsing
/// without triggering state changes or view invalidations on parent views.
public struct CraftPulsingAuraRing: View {
    public let color: Color
    public let size: CGFloat
    public let lineWidth: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(color: Color, size: CGFloat = 28, lineWidth: CGFloat = 2.5) {
        self.color = color
        self.size = size
        self.lineWidth = lineWidth
    }

    public var body: some View {
        if reduceMotion {
            Circle()
                .stroke(color.opacity(0.35), lineWidth: lineWidth)
                .frame(width: size, height: size)
        } else {
            PhaseAnimator([false, true]) { isExpanded in
                Circle()
                    .stroke(color.opacity(isExpanded ? 0.0 : 0.6), lineWidth: isExpanded ? lineWidth * 1.4 : lineWidth)
                    .scaleEffect(isExpanded ? 1.28 : 1.0)
                    .frame(width: size, height: size)
            } animation: { _ in
                .easeInOut(duration: 1.4)
            }
        }
    }
}

#Preview("CraftPulsingAuraRing") {
    HStack(spacing: 24) {
        CraftPulsingAuraRing(color: .orange, size: 36, lineWidth: 3.0)
        CraftPulsingAuraRing(color: .blue, size: 28, lineWidth: 2.5)
        CraftPulsingAuraRing(color: .green, size: 44, lineWidth: 4.0)
    }
    .padding()
}
