import SwiftUI

// MARK: - Card Style

/// Visual style variants for Craft cards.
public enum CraftCardStyle: String, Sendable, CaseIterable {
    case flat
    case elevated
    case outlined
    case gradient
}

// MARK: - CraftCard Component

/// A flexible, theme-driven container card supporting flat, elevated, outlined, and gradient styles,
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

        let cardBody = content
            .padding(contentPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundView(radius: radius))
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .overlay(borderOverlay(radius: radius))
            .modifier(ShadowModifier(style: style, theme: theme))

        if isPressable || action != nil {
            Button(action: { action?() }) {
                cardBody
            }
            .buttonStyle(.craftPress(scale: 0.98))
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityAddTraits(.isButton)
        } else {
            cardBody
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
        }
        .padding()
    }
}
