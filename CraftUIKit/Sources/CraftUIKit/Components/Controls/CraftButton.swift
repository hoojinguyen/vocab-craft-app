import SwiftUI

// MARK: - Button Enums

/// Visual style variants for Craft buttons.
public enum CraftButtonVariant: String, Sendable, CaseIterable {
    case primary
    case secondary
    case outline
    case ghost
    case danger
    case tactile
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

    private var verticalPadding: CGFloat {
        switch size {
        case .sm: return 8
        case .md: return 12
        case .lg: return 16
        }
    }

    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let bottomLipOffset = theme.depths.depthMd
        let depressOffset = (variant == .tactile && isPressed) ? bottomLipOffset : 0

        ZStack {
            if variant == .tactile {
                // Bottom 3D Lip/Bevel
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(theme.colors.brandSecondary)
                    .offset(y: bottomLipOffset)
            }

            // Top Tactile Surface & Content
            HStack(spacing: theme.spacing.xs) {
                if isLoading {
                    CraftSpinner(size: size.iconSize, color: foregroundColor(isPressed: isPressed))
                }
                configuration.label
                    .font(theme.typography.font(for: size.typographyStyle))
                    .foregroundStyle(foregroundColor(isPressed: isPressed))
                    .opacity(isLoading ? 0.8 : 1.0)
            }
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .frame(minHeight: size.height)
            .background(backgroundSurface(isPressed: isPressed))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(borderOverlay(isPressed: isPressed))
            .offset(y: depressOffset)
        }
        .padding(.bottom, variant == .tactile ? bottomLipOffset : 0)
        .opacity(isEnabled ? 1.0 : 0.5)
        .scaleEffect(scaleEffect(isPressed: isPressed))
        .animation(theme.animations.springSnappy, value: isPressed)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .onChange(of: configuration.isPressed) { _, isPressed in
            #if os(iOS)
            if isPressed && variant == .tactile {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.prepare()
                generator.impactOccurred()
            }
            #endif
        }
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .sm: return theme.radii.sm
        case .md: return theme.radii.md
        case .lg: return theme.radii.lg
        }
    }

    private func scaleEffect(isPressed: Bool) -> CGFloat {
        guard isPressed && !reduceMotion else { return 1.0 }
        switch variant {
        case .tactile:
            return 0.99
        default:
            return 0.97
        }
    }

    private func foregroundColor(isPressed: Bool) -> Color {
        switch variant {
        case .primary, .tactile:
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
    private func backgroundSurface(isPressed: Bool) -> some View {
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
        case .tactile:
            LinearGradient(
                colors: [
                    theme.colors.brandPrimary,
                    theme.colors.brandPrimary.opacity(0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
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
        case .tactile:
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    theme.depths.topHighlight,
                    lineWidth: 1
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

    static func craftTactile(size: CraftButtonSize = .md, isLoading: Bool = false) -> CraftButtonStyle {
        CraftButtonStyle(variant: .tactile, size: size, isLoading: isLoading)
    }
}

// MARK: - CraftButton View

/// A tactile, composable button component styled with Craft design tokens.
public struct CraftButton: View {
    @Environment(\.craftTheme) private var theme

    private let titleKey: LocalizedStringKey?
    private let rawTitle: String?
    private let isVerbatim: Bool
    public let iconName: String?
    public let iconPosition: CraftButtonIconPosition
    public let variant: CraftButtonVariant
    public let size: CraftButtonSize
    public let isLoading: Bool
    public let isUppercase: Bool
    public let tracking: CGFloat?
    public let isFullWidth: Bool
    public let action: () -> Void

    public var title: String? {
        rawTitle
    }

    public init(
        _ title: String,
        iconName: String? = nil,
        iconPosition: CraftButtonIconPosition = .leading,
        variant: CraftButtonVariant = .primary,
        size: CraftButtonSize = .md,
        isLoading: Bool = false,
        isUppercase: Bool = false,
        tracking: CGFloat? = nil,
        isFullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.isVerbatim = false
        self.iconName = iconName
        self.iconPosition = iconPosition
        self.variant = variant
        self.size = size
        self.isLoading = isLoading
        self.isUppercase = isUppercase
        self.tracking = tracking
        self.isFullWidth = isFullWidth
        self.action = action
    }

    public init(
        _ titleKey: LocalizedStringKey,
        iconName: String? = nil,
        iconPosition: CraftButtonIconPosition = .leading,
        variant: CraftButtonVariant = .primary,
        size: CraftButtonSize = .md,
        isLoading: Bool = false,
        isUppercase: Bool = false,
        tracking: CGFloat? = nil,
        isFullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.titleKey = titleKey
        self.rawTitle = nil
        self.isVerbatim = false
        self.iconName = iconName
        self.iconPosition = iconPosition
        self.variant = variant
        self.size = size
        self.isLoading = isLoading
        self.isUppercase = isUppercase
        self.tracking = tracking
        self.isFullWidth = isFullWidth
        self.action = action
    }

    public init(
        verbatim title: String,
        iconName: String? = nil,
        iconPosition: CraftButtonIconPosition = .leading,
        variant: CraftButtonVariant = .primary,
        size: CraftButtonSize = .md,
        isLoading: Bool = false,
        isUppercase: Bool = false,
        tracking: CGFloat? = nil,
        isFullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.isVerbatim = true
        self.iconName = iconName
        self.iconPosition = iconPosition
        self.variant = variant
        self.size = size
        self.isLoading = isLoading
        self.isUppercase = isUppercase
        self.tracking = tracking
        self.isFullWidth = isFullWidth
        self.action = action
    }

    public var body: some View {
        Button(action: {
            guard !isLoading else { return }
            action()
        }) {
            HStack(spacing: theme.spacing.xs) {
                if let iconName, iconPosition == .leading, !isLoading {
                    CraftIcon(iconName, size: size.iconSize)
                }

                titleView

                if let iconName, iconPosition == .trailing, !isLoading {
                    CraftIcon(iconName, size: size.iconSize)
                }
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
        }
        .buttonStyle(CraftButtonStyle(variant: variant, size: size, isLoading: isLoading))
        .disabled(isLoading)
    }

    @ViewBuilder
    private var titleView: some View {
        if let titleKey {
            Text(titleKey)
                .textCase(isUppercase ? .uppercase : nil)
                .tracking(tracking ?? 0)
        } else if let rawTitle {
            if isVerbatim {
                Text(verbatim: isUppercase ? rawTitle.uppercased() : rawTitle)
                    .tracking(tracking ?? 0)
            } else {
                Text(rawTitle)
                    .textCase(isUppercase ? .uppercase : nil)
                    .tracking(tracking ?? 0)
            }
        }
    }
}

#Preview("CraftButton") {
    ScrollView {
        VStack(spacing: 24) {
            // Variants
            VStack(spacing: 12) {
                Text("Variants (MD)").font(.headline)
                CraftButton("Primary", variant: .primary) {}
                CraftButton("Secondary", variant: .secondary) {}
                CraftButton("Outline", variant: .outline) {}
                CraftButton("Ghost", variant: .ghost) {}
                CraftButton("Danger", variant: .danger) {}
            }
            
            // Sizes
            VStack(spacing: 12) {
                Text("Sizes").font(.headline)
                CraftButton("Small", size: .sm) {}
                CraftButton("Medium", size: .md) {}
                CraftButton("Large", size: .lg) {}
            }
            
            // States & Icons
            VStack(spacing: 12) {
                Text("States & Icons").font(.headline)
                CraftButton("Loading", isLoading: true) {}
                CraftButton("Leading Icon", iconName: "star", iconPosition: .leading) {}
                CraftButton("Trailing Icon", iconName: "arrow.right", iconPosition: .trailing) {}
                CraftButton("Disabled") {}.disabled(true)
            }
        }
        .padding()
    }
}
