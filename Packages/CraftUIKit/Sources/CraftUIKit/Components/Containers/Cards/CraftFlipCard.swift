import SwiftUI

// MARK: - Card Side & 3D Flip Modifier

/// Identifies the active side of a 3D flip card face.
public enum CraftCardSide: String, Sendable, CaseIterable {
    case front
    case back
}

/// An animatable view modifier providing true mathematical back-face culling and continuous 3D rotation.
public struct Craft3DFlipModifier: AnimatableModifier {
    public var progress: Double // 0.0 (front resting) -> 1.0 (back resting)
    public let side: CraftCardSide
    public let axis: Axis
    public let perspective: CGFloat
    public let reduceMotion: Bool

    public var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    public var isVisible: Bool {
        side == .front ? progress < 0.5 : progress >= 0.5
    }

    public var currentDegrees: Double {
        if reduceMotion { return 0 }
        switch side {
        case .front:
            return progress * 180.0
        case .back:
            return (progress - 1.0) * 180.0
        }
    }

    public var rotationAxis: (x: CGFloat, y: CGFloat, z: CGFloat) {
        switch axis {
        case .horizontal: return (x: 0, y: 1, z: 0)
        case .vertical: return (x: 1, y: 0, z: 0)
        }
    }

    public init(
        progress: Double,
        side: CraftCardSide,
        axis: Axis = .horizontal,
        perspective: CGFloat = 0.45,
        reduceMotion: Bool = false
    ) {
        self.progress = progress
        self.side = side
        self.axis = axis
        self.perspective = perspective
        self.reduceMotion = reduceMotion
    }

    public func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1.0 : 0.0)
            .allowsHitTesting(isVisible)
            .rotation3DEffect(
                .degrees(currentDegrees),
                axis: rotationAxis,
                perspective: perspective
            )
    }
}

// MARK: - Specular Glare Modifier

/// An animatable view modifier that sweeps a specular glare reflection gradient across the card surface during 3D rotation,
/// dynamically adapting contrast for Light and Dark color schemes.
public struct CraftSpecularGlareModifier: AnimatableModifier {
    public var progress: Double // 0.0 (front resting) -> 1.0 (back resting)
    public let axis: Axis
    public let cornerRadius: CGFloat
    public let isEnabled: Bool
    public let colorScheme: ColorScheme

    public var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    public init(
        progress: Double,
        axis: Axis = .horizontal,
        cornerRadius: CGFloat = 16,
        isEnabled: Bool = true,
        colorScheme: ColorScheme = .dark
    ) {
        self.progress = progress
        self.axis = axis
        self.cornerRadius = cornerRadius
        self.isEnabled = isEnabled
        self.colorScheme = colorScheme
    }

    public func body(content: Content) -> some View {
        content
            .overlay {
                if isEnabled {
                    GeometryReader { geometry in
                        let size = geometry.size
                        let clamped = max(0, min(progress, 1.0))
                        // Sinusoidal bell curve peak at progress = 0.5 (90 degrees midpoint of rotation)
                        let glareIntensity = sin(clamped * .pi)

                        if glareIntensity > 0.001 {
                            let beamDimension = max(size.width, size.height) * 1.1
                            let totalSpan = (axis == .horizontal ? size.width : size.height) + beamDimension
                            let offsetPos = (clamped * totalSpan) - (beamDimension * 0.5)

                            glareGradient(intensity: glareIntensity)
                                .frame(
                                    width: axis == .horizontal ? beamDimension * 0.55 : size.width * 1.6,
                                    height: axis == .horizontal ? size.height * 1.6 : beamDimension * 0.55
                                )
                                .rotationEffect(.degrees(axis == .horizontal ? 25 : 65))
                                .offset(
                                    x: axis == .horizontal ? offsetPos - (size.width * 0.2) : 0,
                                    y: axis == .vertical ? offsetPos - (size.height * 0.2) : 0
                                )
                                .blendMode(colorScheme == .dark ? .plusLighter : .overlay)
                                .allowsHitTesting(false)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                }
            }
    }

    @ViewBuilder
    private func glareGradient(intensity: Double) -> some View {
        if colorScheme == .dark {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: Color.white.opacity(0.12 * intensity), location: 0.25),
                    .init(color: Color.white.opacity(0.45 * intensity), location: 0.50),
                    .init(color: Color.white.opacity(0.12 * intensity), location: 0.75),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: Color.black.opacity(0.06 * intensity), location: 0.2),
                    .init(color: Color.white.opacity(0.60 * intensity), location: 0.5),
                    .init(color: Color.black.opacity(0.06 * intensity), location: 0.8),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - CraftFlipCard Component

/// An interactive 3D container component that flips between a front and back view
/// with double-sided rendering, instantaneous back-face culling (zero ghosting),
/// simulated edge thickness, adaptive specular glare, configurable perspective,
/// built-in tap gestures, custom spring physics, and sensory feedback.
public struct CraftFlipCard<Front: View, Back: View>: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    @Binding public var isFlipped: Bool
    public let axis: Axis
    public let edgeThickness: CGFloat
    public let showSpecularGlare: Bool
    public let showsHighlightBorder: Bool
    public let isTapToFlipEnabled: Bool
    public let cornerRadius: CGFloat
    public let perspective: CGFloat
    public let animation: Animation?
    public let front: Front
    public let back: Back

    public init(
        isFlipped: Binding<Bool>,
        axis: Axis = .horizontal,
        edgeThickness: CGFloat = 2,
        showSpecularGlare: Bool = true,
        showsHighlightBorder: Bool = false,
        isTapToFlipEnabled: Bool = true,
        cornerRadius: CGFloat = 16,
        perspective: CGFloat = 0.45,
        animation: Animation? = nil,
        @ViewBuilder front: () -> Front,
        @ViewBuilder back: () -> Back
    ) {
        self._isFlipped = isFlipped
        self.axis = axis
        self.edgeThickness = edgeThickness
        self.showSpecularGlare = showSpecularGlare
        self.showsHighlightBorder = showsHighlightBorder
        self.isTapToFlipEnabled = isTapToFlipEnabled
        self.cornerRadius = cornerRadius
        self.perspective = perspective
        self.animation = animation
        self.front = front()
        self.back = back()
    }

    public var body: some View {
        let progress = isFlipped ? 1.0 : 0.0
        let effectiveAnimation = animation ?? theme.animations.springSmooth

        ZStack {
            // Front Card Face with zero-ghosting backface culling & glare
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
                    .overlay {
                        if showsHighlightBorder {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .strokeBorder(theme.depths.topHighlight, lineWidth: 1)
                        }
                    }
                    .modifier(
                        CraftSpecularGlareModifier(
                            progress: progress,
                            axis: axis,
                            cornerRadius: cornerRadius,
                            isEnabled: showSpecularGlare && !reduceMotion,
                            colorScheme: colorScheme
                        )
                    )
            }
            .modifier(
                Craft3DFlipModifier(
                    progress: progress,
                    side: .front,
                    axis: axis,
                    perspective: perspective,
                    reduceMotion: reduceMotion
                )
            )
            .accessibilityHidden(isFlipped)

            // Back Card Face with zero-ghosting backface culling & glare
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
                    .overlay {
                        if showsHighlightBorder {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .strokeBorder(theme.depths.topHighlight, lineWidth: 1)
                        }
                    }
                    .modifier(
                        CraftSpecularGlareModifier(
                            progress: progress,
                            axis: axis,
                            cornerRadius: cornerRadius,
                            isEnabled: showSpecularGlare && !reduceMotion,
                            colorScheme: colorScheme
                        )
                    )
            }
            .modifier(
                Craft3DFlipModifier(
                    progress: progress,
                    side: .back,
                    axis: axis,
                    perspective: perspective,
                    reduceMotion: reduceMotion
                )
            )
            .accessibilityHidden(!isFlipped)
        }
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        .onTapGesture {
            if isTapToFlipEnabled {
                withAnimation(effectiveAnimation) {
                    isFlipped.toggle()
                }
            }
        }
        .animation(effectiveAnimation, value: isFlipped)
        .sensoryFeedback(.impact(weight: .medium), trigger: isFlipped)
        .accessibilityAction(
            named: CraftLocalized.string(isFlipped ? "craft.flipcard.flip_to_front_action" : "craft.flipcard.flip_to_back_action")
        ) {
            withAnimation(effectiveAnimation) {
                isFlipped.toggle()
            }
        }
        .accessibilityHint(
            CraftLocalized.string(isFlipped ? "craft.flipcard.back_side_hint" : "craft.flipcard.front_side_hint")
        )
    }
}

#Preview("CraftFlipCard") {
    struct PreviewWrapper: View {
        @State private var isFlipped = false
        var body: some View {
            CraftFlipCard(
                isFlipped: $isFlipped,
                perspective: 0.6,
                animation: .spring(response: 0.5, dampingFraction: 0.7)
            ) {
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
