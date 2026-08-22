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

    public init(
        _ name: String,
        size: CraftIconSize = .md,
        color: Color? = nil
    ) {
        self.name = name
        self.size = size
        self.color = color
    }

    public var body: some View {
        Image(systemName: name)
            .font(.system(size: size.pointSize))
            .foregroundColor(color ?? theme.colors.textPrimary)
    }
}
