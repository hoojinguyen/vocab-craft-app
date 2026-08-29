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

    public var axisX: CGFloat {
        axis == .vertical ? 1 : 0
    }

    public var axisY: CGFloat {
        axis == .horizontal ? 1 : 0
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
                axis: (x: axisX, y: axisY, z: 0),
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
/// first-class surface styling (.tactile3D, .elevated, .outlined, .flat, .glass),
/// simulated edge thickness, adaptive specular glare, configurable perspective,
/// optional perimeter shadow highlight, built-in tap gestures, custom spring physics, and sensory feedback.
public struct CraftFlipCard<Front: View, Back: View>: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    @Binding public var isFlipped: Bool
    public let style: CraftCardStyle
    public let axis: Axis
    public let edgeThickness: CGFloat
    public let showSpecularGlare: Bool
    public let showsHighlightBorder: Bool
    public let highlightShadowColor: Color?
    public let isTapToFlipEnabled: Bool
    public let cornerRadius: CGFloat?
    public let padding: CGFloat?
    public let customTint: Color?
    public let customGradient: LinearGradient?
    public let perspective: CGFloat
    public let animation: Animation?
    public let front: Front
    public let back: Back

    public init(
        isFlipped: Binding<Bool>,
        style: CraftCardStyle = .tactile3D,
        axis: Axis = .horizontal,
        edgeThickness: CGFloat = 0,
        showSpecularGlare: Bool = true,
        showsHighlightBorder: Bool = false,
        highlightShadowColor: Color? = nil,
        isTapToFlipEnabled: Bool = true,
        cornerRadius: CGFloat? = nil,
        padding: CGFloat? = nil,
        customTint: Color? = nil,
        customGradient: LinearGradient? = nil,
        perspective: CGFloat = 0.5,
        animation: Animation? = nil,
        @ViewBuilder front: () -> Front,
        @ViewBuilder back: () -> Back
    ) {
        self._isFlipped = isFlipped
        self.style = style
        self.axis = axis
        self.edgeThickness = edgeThickness
        self.showSpecularGlare = showSpecularGlare
        self.showsHighlightBorder = showsHighlightBorder
        self.highlightShadowColor = highlightShadowColor
        self.isTapToFlipEnabled = isTapToFlipEnabled
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.customTint = customTint
        self.customGradient = customGradient
        self.perspective = perspective
        self.animation = animation
        self.front = front()
        self.back = back()
    }

    /// Convenience initializer supporting `CraftSurfaceStyle`.
    public init(
        isFlipped: Binding<Bool>,
        surfaceStyle: CraftSurfaceStyle,
        axis: Axis = .horizontal,
        edgeThickness: CGFloat = 0,
        showSpecularGlare: Bool = true,
        showsHighlightBorder: Bool = false,
        highlightShadowColor: Color? = nil,
        isTapToFlipEnabled: Bool = true,
        cornerRadius: CGFloat? = nil,
        padding: CGFloat? = nil,
        customTint: Color? = nil,
        customGradient: LinearGradient? = nil,
        perspective: CGFloat = 0.5,
        animation: Animation? = nil,
        @ViewBuilder front: () -> Front,
        @ViewBuilder back: () -> Back
    ) {
        self.init(
            isFlipped: isFlipped,
            style: CraftCardStyle(surfaceStyle: surfaceStyle),
            axis: axis,
            edgeThickness: edgeThickness,
            showSpecularGlare: showSpecularGlare,
            showsHighlightBorder: showsHighlightBorder,
            highlightShadowColor: highlightShadowColor,
            isTapToFlipEnabled: isTapToFlipEnabled,
            cornerRadius: cornerRadius,
            padding: padding,
            customTint: customTint,
            customGradient: customGradient,
            perspective: perspective,
            animation: animation,
            front: front,
            back: back
        )
    }

    @State private var synchronizedHeight: CGFloat = 0

    public var body: some View {
        let progress = isFlipped ? 1.0 : 0.0
        let effectiveAnimation = animation ?? theme.animations.springSmooth
        let radius = cornerRadius ?? theme.radii.lg
        let contentPadding = padding ?? theme.spacing.base
        let depth = (style == .tactile3D) ? theme.depths.depthMd : 0

        ZStack {
            // Front Card Face with zero-ghosting backface culling & glare
            cardFaceContainer(front, radius: radius, contentPadding: contentPadding, depth: depth)
                .modifier(
                    CraftSpecularGlareModifier(
                        progress: progress,
                        axis: axis,
                        cornerRadius: radius,
                        isEnabled: showSpecularGlare && !reduceMotion,
                        colorScheme: colorScheme
                    )
                )
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
            cardFaceContainer(back, radius: radius, contentPadding: contentPadding, depth: depth)
                .modifier(
                    CraftSpecularGlareModifier(
                        progress: progress,
                        axis: axis,
                        cornerRadius: radius,
                        isEnabled: showSpecularGlare && !reduceMotion,
                        colorScheme: colorScheme
                    )
                )
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
        .onPreferenceChange(CraftCardFaceHeightPreferenceKey.self) { measuredHeight in
            if measuredHeight > 0 && abs(synchronizedHeight - measuredHeight) > 0.5 {
                synchronizedHeight = measuredHeight
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
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

    @ViewBuilder
    private func cardFaceContainer<V: View>(
        _ content: V,
        radius: CGFloat,
        contentPadding: CGFloat,
        depth: CGFloat
    ) -> some View {
        let topFace = content
            .padding(contentPadding)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: CraftCardFaceHeightPreferenceKey.self, value: geo.size.height)
                }
            )
            .frame(maxWidth: .infinity)
            .frame(minHeight: synchronizedHeight > 0 ? synchronizedHeight : nil, alignment: .center)
            .background(surfaceBackground(radius: radius))
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(surfaceBorderOverlay(radius: radius))
            .modifier(ShadowModifier(style: style, theme: theme))

        let cardView: some View = topFace
            .background {
                if style == .tactile3D {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(theme.colors.borderDefault)
                        .offset(y: depth)
                }
            }
            .padding(.bottom, style == .tactile3D ? depth : 0)

        if let highlightShadowColor {
            cardView
                .shadow(color: highlightShadowColor, radius: 10, x: 0, y: 3)
        } else {
            cardView
        }
    }

    @ViewBuilder
    private func surfaceBackground(radius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        if style == .glass {
            ZStack {
                shape.fill(.ultraThinMaterial)
                if let customGradient {
                    shape.fill(customGradient)
                } else if let customTint {
                    shape.fill(customTint.opacity(theme.glass.tintOpacity))
                } else {
                    shape.fill(theme.colors.surfaceCard.opacity(theme.glass.tintOpacity))
                }
            }
        } else if let customGradient {
            shape.fill(customGradient)
        } else if let customTint {
            shape.fill(customTint)
        } else {
            switch style {
            case .flat:
                shape.fill(theme.colors.surfaceSubtle)
            case .elevated:
                shape.fill(theme.colors.surfaceElevated)
            case .outlined:
                shape.fill(theme.colors.surfaceCard)
            case .gradient:
                shape.fill(theme.gradients.brandHero)
            case .tactile3D:
                shape.fill(theme.colors.surfaceCard)
            case .glass:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func surfaceBorderOverlay(radius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        switch style {
        case .outlined:
            if showsHighlightBorder {
                ZStack {
                    shape.strokeBorder(theme.colors.borderDefault, lineWidth: 1)
                    shape.strokeBorder(theme.depths.topHighlight, lineWidth: 1)
                }
            } else {
                shape.strokeBorder(theme.colors.borderDefault, lineWidth: 1)
            }
        case .elevated:
            ZStack {
                shape.strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: .craftDynamic(light: Color.white.opacity(0.7), dark: Color.white.opacity(0.16)), location: 0.0),
                            .init(color: .craftDynamic(light: theme.colors.hairline.opacity(0.4), dark: Color.white.opacity(0.04)), location: 0.5),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                if showsHighlightBorder {
                    shape.strokeBorder(theme.depths.topHighlight, lineWidth: 1)
                }
            }
        case .tactile3D:
            ZStack {
                shape.strokeBorder(theme.colors.borderDefault, lineWidth: 1)
                shape.strokeBorder(theme.depths.topHighlight, lineWidth: 1)
            }
        case .glass:
            ZStack {
                shape.strokeBorder(theme.glass.borderGradient, lineWidth: 1)
                shape.strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
            }
        case .flat, .gradient:
            if showsHighlightBorder {
                shape.strokeBorder(theme.depths.topHighlight, lineWidth: 1)
            } else {
                EmptyView()
            }
        }
    }
}

// MARK: - Card Face Height Preference Key

private struct CraftCardFaceHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Private Shadow Modifier

private struct ShadowModifier: ViewModifier {
    let style: CraftCardStyle
    let theme: CraftTheme

    func body(content: Content) -> some View {
        switch style {
        case .elevated:
            content.craftShadow(theme.shadows.md)
        case .glass:
            content.craftShadow(theme.shadows.sm)
        case .flat, .outlined, .gradient, .tactile3D:
            content
        }
    }
}

#Preview("CraftFlipCard") {
    struct PreviewWrapper: View {
        @State private var isFlipped = false
        var body: some View {
            CraftFlipCard(
                isFlipped: $isFlipped,
                style: .tactile3D,
                perspective: 0.6,
                animation: .spring(response: 0.5, dampingFraction: 0.7)
            ) {
                Text("Front")
                    .frame(maxWidth: .infinity, minHeight: 100)
            } back: {
                Text("Back")
                    .frame(maxWidth: .infinity, minHeight: 100)
            }
            .padding()
        }
    }
    return PreviewWrapper()
}
