import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - Button Enums

/// Visual style variants for Craft buttons.
public enum CraftButtonVariant: String, Sendable, CaseIterable {
    case primary
    case secondary
    case outline
    case ghost
    case danger
}

/// Standardized sizes for Craft buttons.
public enum CraftButtonSize: String, Sendable, CaseIterable {
    case sm
    case md
    case lg

    /// Height in points corresponding to Apple HIG touch target guidelines.
    public var height: CGFloat {
        switch self {
        case .sm: return 32
        case .md: return 44
        case .lg: return 54
        }
    }

    /// Associated icon size for button slots.
    public var iconSize: CraftIconSize {
        switch self {
        case .sm: return .sm
        case .md: return .md
        case .lg: return .lg
        }
    }

    /// Standard typography style for the button label.
    public var typographyStyle: CraftTypographyStyle {
        switch self {
        case .sm: return .label
        case .md: return .headline
        case .lg: return .headline
        }
    }

    /// Horizontal padding in points.
    public var horizontalPadding: CGFloat {
        switch self {
        case .sm: return 12
        case .md: return 16
        case .lg: return 20
        }
    }
}

/// Slot position for button icons.
public enum CraftButtonIconPosition: String, Sendable, CaseIterable {
    case leading
    case trailing
}

// MARK: - Native ButtonStyle

/// A customizable SwiftUI `ButtonStyle` conforming to Craft design tokens.
public struct CraftButtonStyle: ButtonStyle {
    @Environment(\.craftTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public let variant: CraftButtonVariant
    public let size: CraftButtonSize
    public let isLoading: Bool

    public init(
        variant: CraftButtonVariant = .primary,
        size: CraftButtonSize = .md,
        isLoading: Bool = false
    ) {
        self.variant = variant
        self.size = size
        self.isLoading = isLoading
    }

    public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: theme.spacing.xs) {
            if isLoading {
                CraftSpinner(size: size.iconSize, color: foregroundColor(isPressed: configuration.isPressed))
            }
            configuration.label
                .font(theme.typography.font(for: size.typographyStyle))
                .foregroundColor(foregroundColor(isPressed: configuration.isPressed))
                .opacity(isLoading ? 0.8 : 1.0)
        }
        .frame(height: size.height)
        .padding(.horizontal, size.horizontalPadding)
        .background(backgroundView(isPressed: configuration.isPressed))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(borderOverlay(isPressed: configuration.isPressed))
        .opacity(isEnabled ? 1.0 : 0.5)
        .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
        .animation(theme.animations.springSnappy, value: configuration.isPressed)
        .contentShape(Rectangle())
        .frame(minHeight: 44)
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .sm: return theme.radii.sm
        case .md: return theme.radii.md
        case .lg: return theme.radii.lg
        }
    }

    private func foregroundColor(isPressed: Bool) -> Color {
        switch variant {
        case .primary:
            return theme.colors.textInverse
        case .secondary:
            return theme.colors.textPrimary
        case .outline:
            return theme.colors.brandPrimary
        case .ghost:
            return theme.colors.brandPrimary
        case .danger:
            return .white
        }
    }

    @ViewBuilder
    private func backgroundView(isPressed: Bool) -> some View {
        switch variant {
        case .primary:
            theme.colors.brandPrimary
                .opacity(isPressed ? 0.85 : 1.0)
        case .secondary:
            theme.colors.surfaceSubtle
                .opacity(isPressed ? 0.75 : 1.0)
        case .outline, .ghost:
            Color.clear
        case .danger:
            theme.colors.statusDanger
                .opacity(isPressed ? 0.85 : 1.0)
        }
    }

    @ViewBuilder
    private func borderOverlay(isPressed: Bool) -> some View {
        switch variant {
        case .outline:
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    theme.colors.borderDefault,
                    lineWidth: 1.5
                )
        case .primary, .secondary, .ghost, .danger:
            EmptyView()
        }
    }
}

// MARK: - ButtonStyle Convenience Extensions

public extension ButtonStyle where Self == CraftButtonStyle {
    static func craftPrimary(size: CraftButtonSize = .md, isLoading: Bool = false) -> CraftButtonStyle {
        CraftButtonStyle(variant: .primary, size: size, isLoading: isLoading)
    }

    static func craftSecondary(size: CraftButtonSize = .md, isLoading: Bool = false) -> CraftButtonStyle {
        CraftButtonStyle(variant: .secondary, size: size, isLoading: isLoading)
    }

    static func craftOutline(size: CraftButtonSize = .md, isLoading: Bool = false) -> CraftButtonStyle {
        CraftButtonStyle(variant: .outline, size: size, isLoading: isLoading)
    }

    static func craftGhost(size: CraftButtonSize = .md, isLoading: Bool = false) -> CraftButtonStyle {
        CraftButtonStyle(variant: .ghost, size: size, isLoading: isLoading)
    }

    static func craftDanger(size: CraftButtonSize = .md, isLoading: Bool = false) -> CraftButtonStyle {
        CraftButtonStyle(variant: .danger, size: size, isLoading: isLoading)
    }
}

// MARK: - CraftButton View

/// A tactile, composable button component styled with Craft design tokens.
public struct CraftButton: View {
    @Environment(\.craftTheme) private var theme

    public let title: String
    public let iconName: String?
    public let iconPosition: CraftButtonIconPosition
    public let variant: CraftButtonVariant
    public let size: CraftButtonSize
    public let isLoading: Bool
    public let action: () -> Void

    public init(
        _ title: String,
        iconName: String? = nil,
        iconPosition: CraftButtonIconPosition = .leading,
        variant: CraftButtonVariant = .primary,
        size: CraftButtonSize = .md,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.iconName = iconName
        self.iconPosition = iconPosition
        self.variant = variant
        self.size = size
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: {
            guard !isLoading else { return }
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
            #endif
            action()
        }) {
            HStack(spacing: theme.spacing.xs) {
                if let iconName, iconPosition == .leading, !isLoading {
                    CraftIcon(iconName, size: size.iconSize)
                }

                Text(title)

                if let iconName, iconPosition == .trailing, !isLoading {
                    CraftIcon(iconName, size: size.iconSize)
                }
            }
        }
        .buttonStyle(CraftButtonStyle(variant: variant, size: size, isLoading: isLoading))
        .disabled(isLoading)
    }
}
