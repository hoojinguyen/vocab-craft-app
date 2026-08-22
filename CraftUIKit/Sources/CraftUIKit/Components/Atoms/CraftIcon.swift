import SwiftUI

// MARK: - Icon Size

/// Standardized icon sizing scale.
public enum CraftIconSize: Sendable, CaseIterable, Equatable {
    case sm
    case md
    case lg
    case xl

    /// Standard point size for this icon scale.
    public var pointSize: CGFloat {
        switch self {
        case .sm: return 14
        case .md: return 18
        case .lg: return 24
        case .xl: return 32
        }
    }
}

// MARK: - CraftIcon Component

/// A standardized SF Symbol icon component adhering to theme size scales and semantic colors.
public struct CraftIcon: View {
    @Environment(\.craftTheme) private var theme

    public let name: String
    public let size: CraftIconSize
    public let color: Color?
    public let accessibilityLabel: String?

    public init(
        _ name: String,
        size: CraftIconSize = .md,
        color: Color? = nil,
        accessibilityLabel: String? = nil
    ) {
        self.name = name
        self.size = size
        self.color = color
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        Group {
            if let accessibilityLabel {
                Image(systemName: name)
                    .accessibilityLabel(accessibilityLabel)
            } else {
                Image(systemName: name)
                    .accessibilityHidden(true)
            }
        }
        .font(.system(size: size.pointSize))
        .foregroundStyle(color ?? theme.colors.textPrimary)
    }
}
