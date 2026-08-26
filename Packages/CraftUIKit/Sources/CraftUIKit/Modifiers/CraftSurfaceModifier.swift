import SwiftUI

// MARK: - CraftSurfaceModifier

/// A versatile, theme-driven modifier that applies background material/fill, clipping shape,
/// border overlays (with specular gradients and top-edge bevels), elevation shadows,
/// and tactile 3D physical press extrusion.
public struct CraftSurfaceModifier<S: Shape>: ViewModifier {
    @Environment(\.craftTheme) private var theme
    @Environment(\.craftSurfaceStyle) private var environmentStyle

    public let style: CraftSurfaceStyle?
    public let shape: S
    public let customTint: Color?
    public let customGradient: LinearGradient?
    public let isPressed: Bool
    public let depth: CGFloat?

    public init(
        style: CraftSurfaceStyle? = nil,
        shape: S,
        customTint: Color? = nil,
        customGradient: LinearGradient? = nil,
        isPressed: Bool = false,
        depth: CGFloat? = nil
    ) {
        self.style = style
        self.shape = shape
        self.customTint = customTint
        self.customGradient = customGradient
        self.isPressed = isPressed
        self.depth = depth
    }

    public var resolvedStyle: CraftSurfaceStyle {
        style ?? environmentStyle
    }

    public func body(content: Content) -> some View {
        let resolvedDepth = depth ?? theme.depths.depthMd
        let depressOffset = (resolvedStyle == .tactile3D && isPressed) ? resolvedDepth : 0

        let surfaceFace = content
            .background(backgroundView)
            .clipShape(shape)
            .overlay(borderOverlay)

        if resolvedStyle == .tactile3D {
            surfaceFace
                .offset(y: depressOffset)
                .background {
                    extrusionView
                        .offset(y: resolvedDepth)
                }
                .padding(.bottom, resolvedDepth)
                .animation(theme.animations.springSnappy, value: isPressed)
        } else {
            applyShadow(surfaceFace)
        }
    }

    // MARK: - Extrusion & Background Views

    @ViewBuilder
    private var extrusionView: some View {
        ZStack {
            shape.fill(theme.colors.borderDefault)
            if let customTint {
                shape.fill(customTint.opacity(0.35))
            }
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        if resolvedStyle == .glass {
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
        } else if resolvedStyle == .tactile3D {
            ZStack {
                shape.fill(theme.colors.surfaceCard)
                if let customGradient {
                    shape.fill(customGradient)
                } else if let customTint {
                    shape.fill(customTint)
                }
            }
        } else {
            if let customGradient {
                shape.fill(customGradient)
            } else if let customTint {
                shape.fill(customTint)
            } else {
                switch resolvedStyle {
                case .flat:
                    shape.fill(theme.colors.surfaceSubtle)
                case .elevated:
                    shape.fill(theme.colors.surfaceElevated)
                case .outlined:
                    shape.fill(theme.colors.surfaceCard)
                case .tactile3D:
                    shape.fill(theme.colors.surfaceCard)
                case .glass:
                    EmptyView()
                }
            }
        }
    }

    // MARK: - Border Overlay

    @ViewBuilder
    private var borderOverlay: some View {
        switch resolvedStyle {
        case .flat:
            EmptyView()
        case .elevated:
            shape.stroke(
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
        case .outlined:
            shape.stroke(theme.colors.borderDefault, lineWidth: 1)
        case .tactile3D:
            shape.stroke(
                LinearGradient(
                    stops: [
                        .init(color: .craftDynamic(light: Color.white.opacity(0.75), dark: Color.white.opacity(0.20)), location: 0.0),
                        .init(color: theme.colors.borderDefault.opacity(0.6), location: 0.4),
                        .init(color: theme.colors.borderDefault, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1
            )
        case .glass:
            ZStack {
                shape.stroke(theme.glass.borderGradient, lineWidth: 1)
                shape.stroke(theme.depths.topHighlight, lineWidth: 0.8)
            }
        }
    }

    // MARK: - Shadow

    @ViewBuilder
    private func applyShadow<V: View>(_ view: V) -> some View {
        switch resolvedStyle {
        case .elevated:
            view.craftShadow(theme.shadows.md)
        case .glass:
            view.craftShadow(theme.shadows.sm)
        case .flat, .outlined, .tactile3D:
            view
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Applies a unified theme-driven surface styling (background, clip shape, borders, shadows, and tactile 3D effects).
    ///
    /// - Parameters:
    ///   - style: The surface style variant (flat, elevated, outlined, tactile3D, glass). Defaults to the environment's `craftSurfaceStyle` (or `.flat`).
    ///   - shape: The bounding shape for clipping, borders, and background geometry.
    ///   - customTint: An optional custom tint color overriding theme surface color or tinting glass.
    ///   - customGradient: An optional custom gradient background.
    ///   - isPressed: Indicates tactile press depression state.
    ///   - depth: Optional custom extrusion depth for tactile3D style.
    /// - Returns: A view styled with the given surface configuration.
    func craftSurface<S: Shape>(
        style: CraftSurfaceStyle? = nil,
        shape: S,
        customTint: Color? = nil,
        customGradient: LinearGradient? = nil,
        isPressed: Bool = false,
        depth: CGFloat? = nil
    ) -> some View {
        modifier(
            CraftSurfaceModifier(
                style: style,
                shape: shape,
                customTint: customTint,
                customGradient: customGradient,
                isPressed: isPressed,
                depth: depth
            )
        )
    }
}

// MARK: - Previews

#Preview("CraftSurfaceModifier") {
    ScrollView {
        VStack(spacing: 24) {
            Text("Flat Surface")
                .padding()
                .craftSurface(style: .flat, shape: RoundedRectangle(cornerRadius: 12))

            Text("Elevated Surface")
                .padding()
                .craftSurface(style: .elevated, shape: RoundedRectangle(cornerRadius: 12))

            Text("Outlined Surface")
                .padding()
                .craftSurface(style: .outlined, shape: RoundedRectangle(cornerRadius: 12))

            Text("Tactile 3D Surface")
                .padding()
                .craftSurface(style: .tactile3D, shape: RoundedRectangle(cornerRadius: 12))

            Text("Glass Surface")
                .padding()
                .craftSurface(style: .glass, shape: Capsule())
        }
        .padding()
    }
}
