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

/// A standardized badge and tag component displaying status, categories, or counts.
public struct CraftBadge: View {
    @Environment(\.craftTheme) private var theme

    public let title: String
    public let iconName: String?
    public let variant: CraftBadgeVariant
    public let tone: CraftBadgeTone
    public let size: CraftBadgeSize

    public init(
        _ title: String,
        iconName: String? = nil,
        variant: CraftBadgeVariant = .subtle,
        tone: CraftBadgeTone = .primary,
        size: CraftBadgeSize = .md
    ) {
        self.title = title
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
            return .white
        case .subtle, .outline:
            return toneColor
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .sm: return 6
        case .md: return 8
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .sm: return 2
        case .md: return 4
        }
    }

    private var font: Font {
        switch size {
        case .sm: return theme.typography.caption
        case .md: return theme.typography.label
        }
    }

    private var iconSize: CGFloat {
        switch size {
        case .sm: return 10
        case .md: return 12
        }
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let iconName {
                Image(systemName: iconName)
                    .font(.system(size: iconSize, weight: .semibold))
            }
            Text(title)
                .font(font)
                .fontWeight(.semibold)
        }
        .foregroundColor(foregroundColor)
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
            Capsule().fill(toneColor.opacity(0.15))
        case .outline:
            Capsule().strokeBorder(toneColor, lineWidth: 1)
        }
    }
}
