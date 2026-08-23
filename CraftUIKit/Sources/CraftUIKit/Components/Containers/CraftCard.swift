import SwiftUI

// MARK: - Card Style

/// Visual style variants for Craft cards.
public enum CraftCardStyle: String, Sendable, CaseIterable {
    case flat
    case elevated
    case outlined
    case gradient
    case tactile3D
}

// MARK: - Tactile Card Button Style

/// Button style providing tactile 3D mechanical press feedback with bottom extrusion depression.
public struct CraftTactileCardButtonStyle: ButtonStyle {
    public let depth: CGFloat
    public let radius: CGFloat
    public let bottomColor: Color
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(depth: CGFloat = 4, radius: CGFloat = 16, bottomColor: Color = .clear) {
        self.depth = depth
        self.radius = radius
        self.bottomColor = bottomColor
    }

    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let depressOffset = isPressed ? depth : 0

        ZStack {
            // Bottom 3D Bevel / Extrusion
            RoundedRectangle(cornerRadius: radius)
                .fill(bottomColor)
                .offset(y: depth)

            // Top Card Face
            configuration.label
                .offset(y: depressOffset)
        }
        .padding(.bottom, depth)
        .scaleEffect(isPressed && !reduceMotion ? 0.99 : 1.0)
        .animation(theme.animations.springSnappy, value: isPressed)
        .onChange(of: configuration.isPressed) { _, pressed in
            #if os(iOS)
            if pressed {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
            }
            #endif
        }
    }
}

// MARK: - ButtonStyle Extension

public extension ButtonStyle where Self == CraftTactileCardButtonStyle {
    static func craftTactileCard(depth: CGFloat = 4, radius: CGFloat = 16, bottomColor: Color = .clear) -> CraftTactileCardButtonStyle {
        CraftTactileCardButtonStyle(depth: depth, radius: radius, bottomColor: bottomColor)
    }
}

// MARK: - CraftCard Component

/// A flexible, theme-driven container card supporting flat, elevated, outlined, gradient, and tactile3D styles,
/// with optional tactile press effects for interactive cards (such as Bento grid layouts).
public struct CraftCard<Content: View>: View {
    @Environment(\.craftTheme) private var theme

    public let style: CraftCardStyle
    public let isPressable: Bool
    public let cornerRadius: CGFloat?
    public let padding: CGFloat?
    public let customGradient: LinearGradient?
    public let action: (() -> Void)?
    public let content: Content

    public init(
        style: CraftCardStyle = .flat,
        isPressable: Bool = false,
        cornerRadius: CGFloat? = nil,
        padding: CGFloat? = nil,
        customGradient: LinearGradient? = nil,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.isPressable = isPressable || action != nil
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.customGradient = customGradient
        self.action = action
        self.content = content()
    }

    public var body: some View {
        let radius = cornerRadius ?? theme.radii.lg
        let contentPadding = padding ?? theme.spacing.base
        let depth = (style == .tactile3D) ? theme.depths.depthMd : 0

        let cardFace = content
            .padding(contentPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundView(radius: radius))
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .overlay(borderOverlay(radius: radius))
            .modifier(ShadowModifier(style: style, theme: theme))

        if isPressable || action != nil {
            if style == .tactile3D {
                Button(action: { action?() }) {
                    cardFace
                }
                .buttonStyle(CraftTactileCardButtonStyle(depth: depth, radius: radius, bottomColor: theme.colors.borderDefault))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityAddTraits(.isButton)
            } else {
                Button(action: { action?() }) {
                    cardFace
                }
                .buttonStyle(.craftPress(scale: 0.98))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityAddTraits(.isButton)
            }
        } else {
            if style == .tactile3D {
                ZStack {
                    // Bottom 3D Lip / Extrusion
                    RoundedRectangle(cornerRadius: radius)
                        .fill(theme.colors.borderDefault)
                        .offset(y: depth)

                    // Top Card Face
                    cardFace
                }
                .padding(.bottom, depth)
            } else {
                cardFace
            }
        }
    }

    @ViewBuilder
    private func backgroundView(radius: CGFloat) -> some View {
        switch style {
        case .flat:
            theme.colors.surfaceSubtle
        case .elevated:
            theme.colors.surfaceElevated
        case .outlined:
            theme.colors.surfaceCard
        case .gradient:
            customGradient ?? theme.gradients.brandHero
        case .tactile3D:
            theme.colors.surfaceCard
        }
    }

    @ViewBuilder
    private func borderOverlay(radius: CGFloat) -> some View {
        switch style {
        case .outlined:
            RoundedRectangle(cornerRadius: radius)
                .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
        case .elevated:
            RoundedRectangle(cornerRadius: radius)
                .strokeBorder(
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
        case .tactile3D:
            ZStack {
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(theme.depths.topHighlight, lineWidth: 1)
            }
        case .flat, .gradient:
            EmptyView()
        }
    }
}

private struct ShadowModifier: ViewModifier {
    let style: CraftCardStyle
    let theme: CraftTheme

    func body(content: Content) -> some View {
        if style == .elevated {
            content.craftShadow(theme.shadows.md)
        } else {
            content
        }
    }
}

#Preview("CraftCard") {
    ScrollView {
        VStack(spacing: 24) {
            CraftCard(style: .flat) {
                Text("Flat Card")
            }
            CraftCard(style: .elevated) {
                Text("Elevated Card")
            }
            CraftCard(style: .outlined) {
                Text("Outlined Card")
            }
            CraftCard(style: .gradient) {
                Text("Gradient Card")
                    .foregroundStyle(.white)
            }
            CraftCard(style: .tactile3D, isPressable: true) {
                Text("Tactile 3D Card")
            }
        }
        .padding()
    }
}
