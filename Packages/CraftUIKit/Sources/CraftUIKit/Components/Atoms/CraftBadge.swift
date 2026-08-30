import SwiftUI

// MARK: - Badge Enums

/// Shape options for badges.
public enum CraftBadgeShape: Sendable, Equatable {
    case capsule
    case roundedRectangle(radius: CGFloat)
}

/// Visual style variants for badges.
public enum CraftBadgeVariant: String, Sendable, CaseIterable {
    case solid
    case subtle
    case outline
}

/// Semantic tone indicating purpose or state of the badge.
public enum CraftBadgeTone: String, Sendable, CaseIterable {
    case primary
    case success
    case warning
    case danger
    case neutral
}

/// Standardized badge size options.
public enum CraftBadgeSize: String, Sendable, CaseIterable {
    case sm
    case md
}

// MARK: - CraftBadge Component

/// A standardized badge and tag component displaying status, categories, or counts
/// with WCAG AAA contrast assurance, surface styles, custom shapes, and hierarchical icon rendering.
public struct CraftBadge: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.craftSurfaceStyle) private var environmentSurfaceStyle

    private let titleKey: LocalizedStringKey?
    private let rawTitle: String?
    private let isVerbatim: Bool
    public let iconName: String?
    public let symbol: CraftSymbol?
    public let variant: CraftBadgeVariant
    public let tone: CraftBadgeTone
    public let size: CraftBadgeSize
    public let style: CraftSurfaceStyle?
    public let shape: CraftBadgeShape
    public let customTint: Color?

    public var title: String? {
        rawTitle
    }

    public init(
        _ title: String,
        symbol: CraftSymbol,
        variant: CraftBadgeVariant = .subtle,
        tone: CraftBadgeTone = .primary,
        size: CraftBadgeSize = .md,
        style: CraftSurfaceStyle? = nil,
        shape: CraftBadgeShape = .capsule,
        customTint: Color? = nil
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.isVerbatim = false
        self.symbol = symbol
        self.iconName = symbol.rawValue
        self.variant = variant
        self.tone = tone
        self.size = size
        self.style = style
        self.shape = shape
        self.customTint = customTint
    }

    public init(
        _ title: String,
        iconName: String? = nil,
        variant: CraftBadgeVariant = .subtle,
        tone: CraftBadgeTone = .primary,
        size: CraftBadgeSize = .md,
        style: CraftSurfaceStyle? = nil,
        shape: CraftBadgeShape = .capsule,
        customTint: Color? = nil
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.isVerbatim = false
        self.symbol = iconName.flatMap { CraftSymbol(rawValue: $0) }
        self.iconName = iconName
        self.variant = variant
        self.tone = tone
        self.size = size
        self.style = style
        self.shape = shape
        self.customTint = customTint
    }

    public init(
        _ titleKey: LocalizedStringKey,
        symbol: CraftSymbol,
        variant: CraftBadgeVariant = .subtle,
        tone: CraftBadgeTone = .primary,
        size: CraftBadgeSize = .md,
        style: CraftSurfaceStyle? = nil,
        shape: CraftBadgeShape = .capsule,
        customTint: Color? = nil
    ) {
        self.titleKey = titleKey
        self.rawTitle = nil
        self.isVerbatim = false
        self.symbol = symbol
        self.iconName = symbol.rawValue
        self.variant = variant
        self.tone = tone
        self.size = size
        self.style = style
        self.shape = shape
        self.customTint = customTint
    }

    public init(
        _ titleKey: LocalizedStringKey,
        iconName: String? = nil,
        variant: CraftBadgeVariant = .subtle,
        tone: CraftBadgeTone = .primary,
        size: CraftBadgeSize = .md,
        style: CraftSurfaceStyle? = nil,
        shape: CraftBadgeShape = .capsule,
        customTint: Color? = nil
    ) {
        self.titleKey = titleKey
        self.rawTitle = nil
        self.isVerbatim = false
        self.symbol = iconName.flatMap { CraftSymbol(rawValue: $0) }
        self.iconName = iconName
        self.variant = variant
        self.tone = tone
        self.size = size
        self.style = style
        self.shape = shape
        self.customTint = customTint
    }

    public init(
        verbatim title: String,
        symbol: CraftSymbol,
        variant: CraftBadgeVariant = .subtle,
        tone: CraftBadgeTone = .primary,
        size: CraftBadgeSize = .md,
        style: CraftSurfaceStyle? = nil,
        shape: CraftBadgeShape = .capsule,
        customTint: Color? = nil
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.isVerbatim = true
        self.symbol = symbol
        self.iconName = symbol.rawValue
        self.variant = variant
        self.tone = tone
        self.size = size
        self.style = style
        self.shape = shape
        self.customTint = customTint
    }

    public init(
        verbatim title: String,
        iconName: String? = nil,
        variant: CraftBadgeVariant = .subtle,
        tone: CraftBadgeTone = .primary,
        size: CraftBadgeSize = .md,
        style: CraftSurfaceStyle? = nil,
        shape: CraftBadgeShape = .capsule,
        customTint: Color? = nil
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.isVerbatim = true
        self.symbol = iconName.flatMap { CraftSymbol(rawValue: $0) }
        self.iconName = iconName
        self.variant = variant
        self.tone = tone
        self.size = size
        self.style = style
        self.shape = shape
        self.customTint = customTint
    }

    public var effectiveToneColor: Color {
        customTint ?? toneColor
    }

    private var toneColor: Color {
        switch tone {
        case .primary:
            return theme.colors.brandPrimary
        case .success:
            return theme.colors.statusSuccess
        case .warning:
            return theme.colors.statusWarning
        case .danger:
            return theme.colors.statusDanger
        case .neutral:
            return theme.colors.textMuted
        }
    }

    private var foregroundColor: Color {
        if style != nil {
            return effectiveToneColor
        }
        switch variant {
        case .solid:
            if customTint != nil {
                return .white
            }
            if tone == .warning {
                return theme.colors.textPrimary
            }
            return .white
        case .subtle, .outline:
            return effectiveToneColor
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .sm: return 8
        case .md: return 8
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .sm: return 4
        case .md: return 4
        }
    }

    private var font: Font {
        switch size {
        case .sm: return theme.typography.caption
        case .md: return theme.typography.label
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
        let content = HStack(spacing: 4) {
            if let iconName {
                CraftIcon(
                    iconName,
                    size: size == .sm ? .sm : .md,
                    color: foregroundColor,
                    renderingMode: (variant == .solid && style == nil) ? .monochrome : .hierarchical,
                    weight: .bold
                )
            }
            if let titleKey {
                Text(titleKey)
                    .font(font)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            } else if let rawTitle {
                if isVerbatim {
                    Text(verbatim: rawTitle)
                        .font(font)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                } else {
                    Text(rawTitle)
                        .font(font)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)

        surfaceDecorated(content)
    }

    @ViewBuilder
    private func surfaceDecorated<V: View>(_ content: V) -> some View {
        if let surfaceStyle = resolvedSurfaceStyle {
            switch shape {
            case .capsule:
                content.craftSurface(
                    style: surfaceStyle,
                    shape: Capsule(),
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
            switch shape {
            case .capsule:
                content.background(legacyBackground(Capsule()))
            case .roundedRectangle(let radius):
                content.background(legacyBackground(RoundedRectangle(cornerRadius: radius)))
            }
        }
    }

    private func surfaceTint(for style: CraftSurfaceStyle) -> Color? {
        if let customTint {
            return customTint
        }
        switch style {
        case .glass:
            return effectiveToneColor
        case .flat:
            return variant == .solid ? effectiveToneColor : effectiveToneColor.opacity(0.14)
        case .elevated, .outlined, .tactile3D:
            return variant == .solid ? effectiveToneColor : nil
        }
    }

    @ViewBuilder
    private func legacyBackground<S: InsettableShape>(_ shape: S) -> some View {
        switch variant {
        case .solid:
            shape.fill(effectiveToneColor)
        case .subtle:
            shape
                .fill(effectiveToneColor.opacity(0.14))
                .overlay(
                    shape.strokeBorder(effectiveToneColor.opacity(0.24), lineWidth: 1)
                )
        case .outline:
            shape.strokeBorder(effectiveToneColor, lineWidth: 1)
        }
    }
}

#if canImport(PreviewsMacros)
#Preview("CraftBadge") {
    ScrollView {
        VStack(spacing: 24) {
            ForEach(CraftBadgeVariant.allCases, id: \.self) { variant in
                VStack(spacing: 8) {
                    Text(variant.rawValue.capitalized)
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        ForEach(CraftBadgeTone.allCases, id: \.self) { tone in
                            CraftBadge(tone.rawValue.capitalized, iconName: "star.fill", variant: variant, tone: tone, size: .md)
                        }
                    }
                    HStack(spacing: 8) {
                        ForEach(CraftBadgeTone.allCases, id: \.self) { tone in
                            CraftBadge(tone.rawValue.capitalized, iconName: "star.fill", variant: variant, tone: tone, size: .sm)
                        }
                    }
                }
            }

            VStack(spacing: 8) {
                Text("Surface Styles")
                    .font(.headline)
                HStack(spacing: 8) {
                    CraftBadge("Glass", symbol: .sparkles, tone: .primary, style: .glass)
                    CraftBadge("Elevated", symbol: .mastery, tone: .success, style: .elevated)
                    CraftBadge("Tactile", symbol: .streak, tone: .warning, style: .tactile3D)
                    CraftBadge("Rounded", shape: .roundedRectangle(radius: 6), customTint: .purple)
                }
            }
        }
        .padding()
    }
}
#endif

