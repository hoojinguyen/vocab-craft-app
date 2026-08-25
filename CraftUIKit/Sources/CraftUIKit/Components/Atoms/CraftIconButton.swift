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
    case danger
}

// MARK: - CraftIconButtonStyle

/// Dedicated ButtonStyle handling interactive spring scale, tactile 3D depression,
/// 44x44pt touch targets, disabled state opacity, and sensory feedback.
public struct CraftIconButtonStyle: ButtonStyle {
    @Environment(\.craftTheme) private var theme
    @Environment(\.craftSurfaceStyle) private var environmentSurfaceStyle
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let size: CraftIconSize
    public let shape: CraftIconButtonShape
    public let variant: CraftIconButtonVariant
    public let style: CraftSurfaceStyle?
    public let customTint: Color?
    public let isSelected: Bool
    public let isLoading: Bool

    public init(
        size: CraftIconSize = .md,
        shape: CraftIconButtonShape = .circle,
        variant: CraftIconButtonVariant = .subtle,
        style: CraftSurfaceStyle? = nil,
        customTint: Color? = nil,
        isSelected: Bool = false,
        isLoading: Bool = false
    ) {
        self.size = size
        self.shape = shape
        self.variant = variant
        self.style = style
        self.customTint = customTint
        self.isSelected = isSelected
        self.isLoading = isLoading
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

    private var effectiveTint: Color {
        if variant == .danger {
            return theme.colors.statusDanger
        }
        return customTint ?? theme.colors.brandPrimary
    }

    private var resolvedSurfaceStyle: CraftSurfaceStyle? {
        if let style {
            return style
        }
        if environmentSurfaceStyle != .flat {
            return environmentSurfaceStyle
        }
        return nil
    }

    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed && isEnabled
        let isTactile = (resolvedSurfaceStyle == .tactile3D)

        surfaceContent(configuration: configuration, isPressed: isPressed)
            .frame(width: visualDimension, height: visualDimension)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .opacity(isEnabled ? (isLoading ? 0.8 : 1.0) : 0.4)
            .scaleEffect((isPressed && !reduceMotion && !isTactile) ? 0.94 : 1.0)
            .animation(theme.animations.springSnappy, value: isPressed)
            #if os(iOS)
            .sensoryFeedback(.impact(weight: .light, intensity: 0.75), trigger: isPressed)
            #endif
    }

    @ViewBuilder
    private func surfaceContent(configuration: Configuration, isPressed: Bool) -> some View {
        if let surfaceStyle = resolvedSurfaceStyle {
            switch shape {
            case .circle:
                configuration.label
                    .craftSurface(
                        style: surfaceStyle,
                        shape: Circle(),
                        customTint: resolvedSurfaceTint(for: surfaceStyle),
                        isPressed: isPressed
                    )
            case .square:
                configuration.label
                    .craftSurface(
                        style: surfaceStyle,
                        shape: RoundedRectangle(cornerRadius: cornerRadius),
                        customTint: resolvedSurfaceTint(for: surfaceStyle),
                        isPressed: isPressed
                    )
            case .roundedRectangle(let radius):
                configuration.label
                    .craftSurface(
                        style: surfaceStyle,
                        shape: RoundedRectangle(cornerRadius: radius),
                        customTint: resolvedSurfaceTint(for: surfaceStyle),
                        isPressed: isPressed
                    )
            }
        } else {
            ZStack {
                legacyBackgroundShape
                configuration.label
            }
        }
    }

    private func resolvedSurfaceTint(for style: CraftSurfaceStyle) -> Color? {
        if let customTint {
            return customTint
        }
        switch style {
        case .glass:
            return nil
        case .flat:
            return (variant == .filled || isSelected || variant == .danger) ? effectiveTint : effectiveTint.opacity(0.12)
        case .elevated, .outlined, .tactile3D:
            return (variant == .filled || isSelected || variant == .danger) ? effectiveTint : nil
        }
    }

    @ViewBuilder
    private var legacyBackgroundShape: some View {
        switch shape {
        case .circle:
            renderShape(Circle())
        case .square:
            renderShape(RoundedRectangle(cornerRadius: cornerRadius))
        case .roundedRectangle(let radius):
            renderShape(RoundedRectangle(cornerRadius: radius))
        }
    }

    @ViewBuilder
    private func renderShape<S: InsettableShape>(_ s: S) -> some View {
        switch variant {
        case .filled:
            s.fill(effectiveTint)
        case .subtle:
            s.fill(isSelected ? effectiveTint : effectiveTint.opacity(0.12))
        case .outline:
            if isSelected {
                s.fill(effectiveTint)
            } else {
                s.strokeBorder(customTint ?? theme.colors.borderDefault, lineWidth: 1.5)
            }
        case .ghost:
            if isSelected {
                s.fill(effectiveTint)
            } else {
                Color.clear
            }
        case .danger:
            s.fill(theme.colors.statusDanger)
        }
    }
}

// MARK: - CraftIconButton Component

/// A tactile icon button meeting Apple HIG 44pt minimum touch target requirements,
/// supporting surface styles, custom shapes, sensory haptics, selection, and loading states.
public struct CraftIconButton: View {
    @Environment(\.craftTheme) private var theme

    public let iconName: String
    public let symbol: CraftSymbol?
    public let size: CraftIconSize
    public let shape: CraftIconButtonShape
    public let variant: CraftIconButtonVariant
    public let style: CraftSurfaceStyle?
    public let customTint: Color?
    public let isSelected: Bool
    public let isLoading: Bool
    public let accessibilityLabel: String?
    public let accessibilityLabelKey: LocalizedStringKey?
    public let accessibilityHint: String?
    public let minTouchTarget: CGFloat = 44
    public let action: () -> Void

    // 1. Symbol + String A11y
    public init(
        symbol: CraftSymbol,
        size: CraftIconSize = .md,
        shape: CraftIconButtonShape = .circle,
        variant: CraftIconButtonVariant = .subtle,
        style: CraftSurfaceStyle? = nil,
        customTint: Color? = nil,
        isSelected: Bool = false,
        isLoading: Bool = false,
        accessibilityLabel: String,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void
    ) {
        self.symbol = symbol
        self.iconName = symbol.rawValue
        self.size = size
        self.shape = shape
        self.variant = variant
        self.style = style
        self.customTint = customTint
        self.isSelected = isSelected
        self.isLoading = isLoading
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityLabelKey = nil
        self.accessibilityHint = accessibilityHint
        self.action = action
    }

    // 2. Symbol + LocalizedStringKey A11y
    public init(
        symbol: CraftSymbol,
        size: CraftIconSize = .md,
        shape: CraftIconButtonShape = .circle,
        variant: CraftIconButtonVariant = .subtle,
        style: CraftSurfaceStyle? = nil,
        customTint: Color? = nil,
        isSelected: Bool = false,
        isLoading: Bool = false,
        accessibilityLabelKey: LocalizedStringKey,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void
    ) {
        self.symbol = symbol
        self.iconName = symbol.rawValue
        self.size = size
        self.shape = shape
        self.variant = variant
        self.style = style
        self.customTint = customTint
        self.isSelected = isSelected
        self.isLoading = isLoading
        self.accessibilityLabel = nil
        self.accessibilityLabelKey = accessibilityLabelKey
        self.accessibilityHint = accessibilityHint
        self.action = action
    }

    // 3. String iconName + String A11y
    public init(
        iconName: String,
        size: CraftIconSize = .md,
        shape: CraftIconButtonShape = .circle,
        variant: CraftIconButtonVariant = .subtle,
        style: CraftSurfaceStyle? = nil,
        customTint: Color? = nil,
        isSelected: Bool = false,
        isLoading: Bool = false,
        accessibilityLabel: String,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void
    ) {
        self.symbol = CraftSymbol(rawValue: iconName)
        self.iconName = iconName
        self.size = size
        self.shape = shape
        self.variant = variant
        self.style = style
        self.customTint = customTint
        self.isSelected = isSelected
        self.isLoading = isLoading
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityLabelKey = nil
        self.accessibilityHint = accessibilityHint
        self.action = action
    }

    // 4. String iconName + LocalizedStringKey A11y
    public init(
        iconName: String,
        size: CraftIconSize = .md,
        shape: CraftIconButtonShape = .circle,
        variant: CraftIconButtonVariant = .subtle,
        style: CraftSurfaceStyle? = nil,
        customTint: Color? = nil,
        isSelected: Bool = false,
        isLoading: Bool = false,
        accessibilityLabelKey: LocalizedStringKey,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void
    ) {
        self.symbol = CraftSymbol(rawValue: iconName)
        self.iconName = iconName
        self.size = size
        self.shape = shape
        self.variant = variant
        self.style = style
        self.customTint = customTint
        self.isSelected = isSelected
        self.isLoading = isLoading
        self.accessibilityLabel = nil
        self.accessibilityLabelKey = accessibilityLabelKey
        self.accessibilityHint = accessibilityHint
        self.action = action
    }

    public var effectiveTint: Color {
        if variant == .danger {
            return theme.colors.statusDanger
        }
        return customTint ?? theme.colors.brandPrimary
    }

    private var foregroundColor: Color {
        if let customTint {
            return isSelected ? theme.colors.textInverse : customTint
        }
        if style != nil {
            return isSelected ? theme.colors.textInverse : theme.colors.brandPrimary
        }
        switch variant {
        case .filled, .danger:
            return theme.colors.textInverse
        case .subtle, .outline, .ghost:
            return isSelected ? theme.colors.textInverse : theme.colors.brandPrimary
        }
    }

    public var body: some View {
        Button(action: {
            guard !isLoading else { return }
            action()
        }) {
            if isLoading {
                CraftSpinner(size: size, color: foregroundColor)
            } else {
                CraftIcon(
                    iconName,
                    size: size,
                    color: foregroundColor,
                    renderingMode: (variant == .filled && style == nil) ? .monochrome : .hierarchical,
                    weight: .semibold
                )
            }
        }
        .buttonStyle(
            CraftIconButtonStyle(
                size: size,
                shape: shape,
                variant: variant,
                style: style,
                customTint: customTint,
                isSelected: isSelected,
                isLoading: isLoading
            )
        )
        .disabled(isLoading)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .modifier(
            CraftIconButtonA11yModifier(
                label: accessibilityLabel,
                key: accessibilityLabelKey,
                hint: accessibilityHint
            )
        )
    }
}

// MARK: - Accessibility Helper Modifier

private struct CraftIconButtonA11yModifier: ViewModifier {
    let label: String?
    let key: LocalizedStringKey?
    let hint: String?

    func body(content: Content) -> some View {
        if let key {
            content
                .accessibilityLabel(key)
                .accessibilityHint(hint ?? "")
        } else if let label {
            content
                .accessibilityLabel(label)
                .accessibilityHint(hint ?? "")
        } else {
            content
                .accessibilityHint(hint ?? "")
        }
    }
}

// MARK: - Previews

#Preview("CraftIconButton") {
    VStack(spacing: 24) {
        ForEach(CraftIconButtonVariant.allCases, id: \.self) { variant in
            HStack(spacing: 16) {
                CraftIconButton(iconName: "star.fill", variant: variant, accessibilityLabel: "Star", action: {})
                CraftIconButton(iconName: "star.fill", variant: variant, isSelected: true, accessibilityLabel: "Star Selected", action: {})
                CraftIconButton(iconName: "star.fill", variant: variant, isLoading: true, accessibilityLabel: "Star Loading", action: {})
                CraftIconButton(iconName: "star.fill", variant: variant, accessibilityLabel: "Star Disabled", action: {})
                    .disabled(true)
            }
        }

        HStack(spacing: 16) {
            CraftIconButton(iconName: "sparkles", style: .glass, accessibilityLabel: "Glass", action: {})
            CraftIconButton(iconName: "flame.fill", style: .tactile3D, accessibilityLabel: "Tactile", action: {})
            CraftIconButton(iconName: "heart.fill", shape: .roundedRectangle(radius: 12), customTint: .pink, isSelected: true, accessibilityLabel: "Heart", action: {})
        }
    }
    .padding()
}
