import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - CraftFlipCard Component

/// An interactive 3D container component that flips between a front and back view
/// with double-sided rendering, back-face culling, spring physics, and tactile haptic feedback.
public struct CraftFlipCard<Front: View, Back: View>: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding public var isFlipped: Bool
    public let axis: Axis
    public let front: Front
    public let back: Back

    public init(
        isFlipped: Binding<Bool>,
        axis: Axis = .horizontal,
        @ViewBuilder front: () -> Front,
        @ViewBuilder back: () -> Back
    ) {
        self._isFlipped = isFlipped
        self.axis = axis
        self.front = front()
        self.back = back()
    }

    public var body: some View {
        ZStack {
            front
                .opacity(isFlipped ? 0 : 1)
                .accessibilityHidden(isFlipped)
                .rotation3DEffect(
                    reduceMotion ? .zero : .degrees(isFlipped ? 180 : 0),
                    axis: rotationAxis,
                    perspective: 0.5
                )

            back
                .opacity(isFlipped ? 1 : 0)
                .accessibilityHidden(!isFlipped)
                .rotation3DEffect(
                    reduceMotion ? .zero : .degrees(isFlipped ? 0 : -180),
                    axis: rotationAxis,
                    perspective: 0.5
                )
        }
        .animation(theme.animations.springSmooth, value: isFlipped)
        .onChange(of: isFlipped) { _, _ in
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            #endif
        }
    }

    private var rotationAxis: (x: CGFloat, y: CGFloat, z: CGFloat) {
        switch axis {
        case .horizontal:
            return (x: 0, y: 1, z: 0)
        case .vertical:
            return (x: 1, y: 0, z: 0)
        }
    }
}
