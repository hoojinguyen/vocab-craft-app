import SwiftUI

// MARK: - Specular Glare Modifier

/// An animatable view modifier that sweeps a specular glare reflection gradient across the card surface during 3D rotation.
public struct CraftSpecularGlareModifier: AnimatableModifier {
    public var progress: Double // 0.0 (front resting) -> 1.0 (back resting)
    public let axis: Axis
    public let cornerRadius: CGFloat
    public let isEnabled: Bool

    public var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    public init(progress: Double, axis: Axis = .horizontal, cornerRadius: CGFloat = 16, isEnabled: Bool = true) {
        self.progress = progress
        self.axis = axis
        self.cornerRadius = cornerRadius
        self.isEnabled = isEnabled
    }

    public func body(content: Content) -> some View {
        content
            .overlay {
                if isEnabled {
                    GeometryReader { geometry in
                        let size = geometry.size
                        // Sinusoidal bell curve peak at progress = 0.5 (90 degrees midpoint of rotation)
                        let glareIntensity = sin(max(0, min(progress, 1.0)) * .pi)

                        if glareIntensity > 0.001 {
                            let beamDimension = max(size.width, size.height) * 0.9
                            let totalSpan = (axis == .horizontal ? size.width : size.height) + beamDimension
                            let offsetPos = (progress * totalSpan) - (beamDimension * 0.5)

                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.0),
                                    .init(color: Color.white.opacity(0.08 * glareIntensity), location: 0.2),
                                    .init(color: Color.white.opacity(0.40 * glareIntensity), location: 0.5),
                                    .init(color: Color.white.opacity(0.08 * glareIntensity), location: 0.8),
                                    .init(color: .clear, location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(
                                width: axis == .horizontal ? beamDimension * 0.6 : size.width * 1.5,
                                height: axis == .horizontal ? size.height * 1.5 : beamDimension * 0.6
                            )
                            .rotationEffect(.degrees(axis == .horizontal ? 25 : 65))
                            .offset(
                                x: axis == .horizontal ? offsetPos - (size.width * 0.2) : 0,
                                y: axis == .vertical ? offsetPos - (size.height * 0.2) : 0
                            )
                            .blendMode(.plusLighter)
                            .allowsHitTesting(false)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                }
            }
    }
}

// MARK: - CraftFlipCard Component

/// An interactive 3D container component that flips between a front and back view
/// with double-sided rendering, back-face culling, simulated edge thickness, dynamic specular glare,
/// spring physics, and sensory feedback.
public struct CraftFlipCard<Front: View, Back: View>: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding public var isFlipped: Bool
    public let axis: Axis
    public let edgeThickness: CGFloat
    public let showSpecularGlare: Bool
    public let cornerRadius: CGFloat
    public let front: Front
    public let back: Back

    public init(
        isFlipped: Binding<Bool>,
        axis: Axis = .horizontal,
        edgeThickness: CGFloat = 2,
        showSpecularGlare: Bool = true,
        cornerRadius: CGFloat = 16,
        @ViewBuilder front: () -> Front,
        @ViewBuilder back: () -> Back
    ) {
        self._isFlipped = isFlipped
        self.axis = axis
        self.edgeThickness = edgeThickness
        self.showSpecularGlare = showSpecularGlare
        self.cornerRadius = cornerRadius
        self.front = front()
        self.back = back()
    }

    public var body: some View {
        let progress = isFlipped ? 1.0 : 0.0

        ZStack {
            // Front Card Face with simulated edge thickness & specular glare
            ZStack {
                if edgeThickness > 0 && !reduceMotion {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(theme.colors.borderDefault)
                        .offset(
                            x: axis == .horizontal ? edgeThickness * 0.8 : 0,
                            y: axis == .vertical ? edgeThickness * 0.8 : 0
                        )
                }

                front
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(theme.depths.topHighlight, lineWidth: 1)
                    )
                    .modifier(
                        CraftSpecularGlareModifier(
                            progress: progress,
                            axis: axis,
                            cornerRadius: cornerRadius,
                            isEnabled: showSpecularGlare && !reduceMotion
                        )
                    )
            }
            .opacity(isFlipped ? 0 : 1)
            .accessibilityHidden(isFlipped)
            .rotation3DEffect(
                reduceMotion ? .zero : .degrees(isFlipped ? 180 : 0),
                axis: rotationAxis,
                perspective: 0.5
            )

            // Back Card Face with simulated edge thickness & specular glare
            ZStack {
                if edgeThickness > 0 && !reduceMotion {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(theme.colors.borderDefault)
                        .offset(
                            x: axis == .horizontal ? -edgeThickness * 0.8 : 0,
                            y: axis == .vertical ? -edgeThickness * 0.8 : 0
                        )
                }

                back
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(theme.depths.topHighlight, lineWidth: 1)
                    )
                    .modifier(
                        CraftSpecularGlareModifier(
                            progress: progress,
                            axis: axis,
                            cornerRadius: cornerRadius,
                            isEnabled: showSpecularGlare && !reduceMotion
                        )
                    )
            }
            .opacity(isFlipped ? 1 : 0)
            .accessibilityHidden(!isFlipped)
            .rotation3DEffect(
                reduceMotion ? .zero : .degrees(isFlipped ? 0 : -180),
                axis: rotationAxis,
                perspective: 0.5
            )
        }
        .animation(theme.animations.springSmooth, value: isFlipped)
        .sensoryFeedback(.impact(weight: .medium), trigger: isFlipped)
        .accessibilityAction(named: "Flip card") {
            isFlipped.toggle()
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

#Preview("CraftFlipCard") {
    struct PreviewWrapper: View {
        @State private var isFlipped = false
        var body: some View {
            CraftFlipCard(isFlipped: $isFlipped) {
                CraftCard(style: .elevated) {
                    Text("Front")
                        .frame(maxWidth: .infinity, minHeight: 100)
                }
            } back: {
                CraftCard(style: .outlined) {
                    Text("Back")
                        .frame(maxWidth: .infinity, minHeight: 100)
                }
            }
            .padding()
        }
    }
    return PreviewWrapper()
}
