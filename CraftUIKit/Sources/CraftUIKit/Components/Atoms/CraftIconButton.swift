import SwiftUI

// MARK: - Icon Button Enums

/// Shape options for icon buttons.
public enum CraftIconButtonShape: Sendable, Equatable {
    case circle
    case square
    case roundedRectangle(radius: CGFloat)

    public static var allCases: [CraftIconButtonShape] {
        [.circle, .square, .roundedRectangle(radius: 8)]
    }
}

/// Visual style variants for icon buttons.
public enum CraftIconButtonVariant: String, Sendable, CaseIterable {
    case filled
    case subtle
    case outline
    case ghost
}

// MARK: - CraftIconButton Component

/// A tactile icon button meeting Apple HIG 44pt minimum touch target requirements,
/// supporting surface styles, custom shapes, and arbitrary tints.
public struct CraftIconButton: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.craftSurfaceStyle) private var environmentSurfaceStyle

    public let iconName: String
    public let symbol: CraftSymbol?
    public let size: CraftIconSize
    public let shape: CraftIconButtonShape
    public let variant: CraftIconButtonVariant
    public let style: CraftSurfaceStyle?
    public let customTint: Color?
    public let accessibilityLabel: String
    public let minTouchTarget: CGFloat = 44
    public let action: () -> Void

    public init(
        symbol: CraftSymbol,
        size: CraftIconSize = .md,
        shape: CraftIconButtonShape = .circle,
        variant: CraftIconButtonVariant = .subtle,
        style: CraftSurfaceStyle? = nil,
        customTint: Color? = nil,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) {
        self.symbol = symbol
        self.iconName = symbol.rawValue
        self.size = size
        self.shape = shape
        self.variant = variant
        self.style = style
        self.customTint = customTint
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public init(
        iconName: String,
        size: CraftIconSize = .md,
        shape: CraftIconButtonShape = .circle,
        variant: CraftIconButtonVariant = .subtle,
        style: CraftSurfaceStyle? = nil,
        customTint: Color? = nil,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) {
        self.symbol = CraftSymbol(rawValue: iconName)
        self.iconName = iconName
        self.size = size
        self.shape = shape
        self.variant = variant
        self.style = style
        self.customTint = customTint
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var effectiveTint: Color {
        customTint ?? theme.colors.brandPrimary
    }

    private var visualDimension: CGFloat {
        switch size {
        case .sm: return 32
        case .md: return 40
        case .lg: return 48
        case .xl: return 56
        }
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .sm: return theme.radii.sm
        case .md: return theme.radii.sm
        case .lg: return theme.radii.md
        case .xl: return theme.radii.lg
        }
    }

    private var foregroundColor: Color {
        if style != nil {
            return effectiveTint
        }
        switch variant {
        case .filled:
            return theme.colors.textInverse
        case .subtle:
            return effectiveTint
        case .outline, .ghost:
            return customTint ?? theme.colors.textPrimary
        }
    }

    private var resolvedSurfaceStyle: CraftSurfaceStyle? {
        if let style {
            return style
        }
        if variant == .subtle && environmentSurfaceStyle != .flat {
            return environmentSurfaceStyle
        }
        return nil
    }

    public var body: some View {
        Button(action: action) {
            surfaceDecorated(
                CraftIcon(
                    iconName,
                    size: size,
                    color: foregroundColor,
                    renderingMode: (variant == .filled && style == nil) ? .monochrome : .hierarchical,
                    weight: .semibold
                )
                .frame(width: visualDimension, height: visualDimension)
            )
            .frame(minWidth: minTouchTarget, minHeight: minTouchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.craftPress(scale: 0.94))
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private func surfaceDecorated<V: View>(_ content: V) -> some View {
        if let surfaceStyle = resolvedSurfaceStyle {
            switch shape {
            case .circle:
                content.craftSurface(
                    style: surfaceStyle,
                    shape: Circle(),
                    customTint: surfaceTint(for: surfaceStyle)
                )
            case .square:
                content.craftSurface(
                    style: surfaceStyle,
                    shape: RoundedRectangle(cornerRadius: cornerRadius),
                    customTint: surfaceTint(for: surfaceStyle)
                )
            case .roundedRectangle(let radius):
                content.craftSurface(
                    style: surfaceStyle,
                    shape: RoundedRectangle(cornerRadius: radius),
                    customTint: surfaceTint(for: surfaceStyle)
                )
            }
        } else {
            ZStack {
                backgroundShapeView
                content
            }
        }
    }

    private func surfaceTint(for style: CraftSurfaceStyle) -> Color? {
        if let customTint {
            return customTint
        }
        switch style {
        case .glass:
            return effectiveTint
        case .flat:
            return variant == .filled ? effectiveTint : effectiveTint.opacity(0.12)
        case .elevated, .outlined, .tactile3D:
            return variant == .filled ? effectiveTint : nil
        }
    }

    @ViewBuilder
    private var backgroundShapeView: some View {
        switch shape {
        case .circle:
            renderLegacyShape(Circle(), tint: effectiveTint)
        case .square:
            renderLegacyShape(RoundedRectangle(cornerRadius: cornerRadius), tint: effectiveTint)
        case .roundedRectangle(let radius):
            renderLegacyShape(RoundedRectangle(cornerRadius: radius), tint: effectiveTint)
        }
    }

    @ViewBuilder
    private func renderLegacyShape<S: InsettableShape>(_ s: S, tint: Color) -> some View {
        switch variant {
        case .filled:
            s.fill(tint)
        case .subtle:
            s.fill(tint.opacity(0.12))
        case .outline:
            s.strokeBorder(theme.colors.borderDefault, lineWidth: 1)
        case .ghost:
            Color.clear
        }
    }
}

#Preview("CraftIconButton") {
    VStack(spacing: 24) {
        ForEach(CraftIconButtonVariant.allCases, id: \.self) { variant in
            HStack(spacing: 16) {
                CraftIconButton(iconName: "star.fill", variant: variant, accessibilityLabel: "Star", action: {})
                CraftIconButton(iconName: "star.fill", variant: variant, accessibilityLabel: "Star Disabled", action: {})
                    .disabled(true)
            }
        }

        HStack(spacing: 16) {
            CraftIconButton(iconName: "sparkles", style: .glass, accessibilityLabel: "Glass", action: {})
            CraftIconButton(iconName: "flame.fill", style: .tactile3D, accessibilityLabel: "Tactile", action: {})
            CraftIconButton(iconName: "heart.fill", shape: .roundedRectangle(radius: 12), customTint: .pink, accessibilityLabel: "Heart", action: {})
        }
    }
    .padding()
}

