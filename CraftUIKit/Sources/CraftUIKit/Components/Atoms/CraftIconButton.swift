import SwiftUI

// MARK: - Icon Button Enums

/// Shape options for icon buttons.
public enum CraftIconButtonShape: String, Sendable, CaseIterable {
    case circle
    case square
}

/// Visual style variants for icon buttons.
public enum CraftIconButtonVariant: String, Sendable, CaseIterable {
    case filled
    case subtle
    case outline
    case ghost
}

// MARK: - CraftIconButton Component

/// A tactile icon button meeting Apple HIG 44pt minimum touch target requirements.
public struct CraftIconButton: View {
    @Environment(\.craftTheme) private var theme

    public let iconName: String
    public let size: CraftIconSize
    public let shape: CraftIconButtonShape
    public let variant: CraftIconButtonVariant
    public let accessibilityLabel: String
    public let minTouchTarget: CGFloat = 44
    public let action: () -> Void

    public init(
        iconName: String,
        size: CraftIconSize = .md,
        shape: CraftIconButtonShape = .circle,
        variant: CraftIconButtonVariant = .subtle,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) {
        self.iconName = iconName
        self.size = size
        self.shape = shape
        self.variant = variant
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    private var visualDimension: CGFloat {
        switch size {
        case .sm: return 32
        case .md: return 40
        case .lg: return 48
        case .xl: return 56
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .filled:
            return .white
        case .subtle, .outline, .ghost:
            return theme.colors.textPrimary
        }
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                backgroundShapeView

                CraftIcon(iconName, size: size, color: foregroundColor)
            }
            .frame(width: visualDimension, height: visualDimension)
            .frame(minWidth: minTouchTarget, minHeight: minTouchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.craftPress(scale: 0.94))
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var backgroundShapeView: some View {
        switch shape {
        case .circle:
            switch variant {
            case .filled:
                Circle().fill(theme.colors.brandPrimary)
            case .subtle:
                Circle().fill(theme.colors.surfaceSubtle)
            case .outline:
                Circle().strokeBorder(theme.colors.borderDefault, lineWidth: 1)
            case .ghost:
                Color.clear
            }
        case .square:
            switch variant {
            case .filled:
                RoundedRectangle(cornerRadius: theme.radii.md).fill(theme.colors.brandPrimary)
            case .subtle:
                RoundedRectangle(cornerRadius: theme.radii.md).fill(theme.colors.surfaceSubtle)
            case .outline:
                RoundedRectangle(cornerRadius: theme.radii.md).strokeBorder(theme.colors.borderDefault, lineWidth: 1)
            case .ghost:
                Color.clear
            }
        }
    }
}
