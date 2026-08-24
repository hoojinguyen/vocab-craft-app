import SwiftUI

// MARK: - Badge Enums

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
/// with WCAG AAA contrast assurance and hierarchical icon rendering.
public struct CraftBadge: View {
    @Environment(\.craftTheme) private var theme

    private let titleKey: LocalizedStringKey?
    private let rawTitle: String?
    private let isVerbatim: Bool
    public let iconName: String?
    public let symbol: CraftSymbol?
    public let variant: CraftBadgeVariant
    public let tone: CraftBadgeTone
    public let size: CraftBadgeSize

    public var title: String? {
        rawTitle
    }

    public init(
        _ title: String,
        symbol: CraftSymbol,
        variant: CraftBadgeVariant = .subtle,
        tone: CraftBadgeTone = .primary,
        size: CraftBadgeSize = .md
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.isVerbatim = false
        self.symbol = symbol
        self.iconName = symbol.rawValue
        self.variant = variant
        self.tone = tone
        self.size = size
    }

    public init(
        _ title: String,
        iconName: String? = nil,
        variant: CraftBadgeVariant = .subtle,
        tone: CraftBadgeTone = .primary,
        size: CraftBadgeSize = .md
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.isVerbatim = false
        self.symbol = iconName.flatMap { CraftSymbol(rawValue: $0) }
        self.iconName = iconName
        self.variant = variant
        self.tone = tone
        self.size = size
    }

    public init(
        _ titleKey: LocalizedStringKey,
        symbol: CraftSymbol,
        variant: CraftBadgeVariant = .subtle,
        tone: CraftBadgeTone = .primary,
        size: CraftBadgeSize = .md
    ) {
        self.titleKey = titleKey
        self.rawTitle = nil
        self.isVerbatim = false
        self.symbol = symbol
        self.iconName = symbol.rawValue
        self.variant = variant
        self.tone = tone
        self.size = size
    }

    public init(
        _ titleKey: LocalizedStringKey,
        iconName: String? = nil,
        variant: CraftBadgeVariant = .subtle,
        tone: CraftBadgeTone = .primary,
        size: CraftBadgeSize = .md
    ) {
        self.titleKey = titleKey
        self.rawTitle = nil
        self.isVerbatim = false
        self.symbol = iconName.flatMap { CraftSymbol(rawValue: $0) }
        self.iconName = iconName
        self.variant = variant
        self.tone = tone
        self.size = size
    }

    public init(
        verbatim title: String,
        symbol: CraftSymbol,
        variant: CraftBadgeVariant = .subtle,
        tone: CraftBadgeTone = .primary,
        size: CraftBadgeSize = .md
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.isVerbatim = true
        self.symbol = symbol
        self.iconName = symbol.rawValue
        self.variant = variant
        self.tone = tone
        self.size = size
    }

    public init(
        verbatim title: String,
        iconName: String? = nil,
        variant: CraftBadgeVariant = .subtle,
        tone: CraftBadgeTone = .primary,
        size: CraftBadgeSize = .md
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.isVerbatim = true
        self.symbol = iconName.flatMap { CraftSymbol(rawValue: $0) }
        self.iconName = iconName
        self.variant = variant
        self.tone = tone
        self.size = size
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
        switch variant {
        case .solid:
            // High contrast assurance: Warning (yellow/amber) needs dark ink, not white
            if tone == .warning {
                return theme.colors.textPrimary
            }
            return .white
        case .subtle, .outline:
            return toneColor
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

    public var body: some View {
        HStack(spacing: 4) {
            if let iconName {
                CraftIcon(
                    iconName,
                    size: size == .sm ? .sm : .md,
                    color: foregroundColor,
                    renderingMode: variant == .solid ? .monochrome : .hierarchical,
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
        .background(backgroundView)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch variant {
        case .solid:
            Capsule().fill(toneColor)
        case .subtle:
            Capsule()
                .fill(toneColor.opacity(0.14))
                .overlay(
                    Capsule()
                        .strokeBorder(toneColor.opacity(0.24), lineWidth: 1)
                )
        case .outline:
            Capsule().strokeBorder(toneColor, lineWidth: 1)
        }
    }
}

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
        }
        .padding()
    }
}
