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

// MARK: - Icon Rendering Mode

/// SF Symbol rendering modes ensuring depth and visual hierarchy.
public enum CraftIconRenderingMode: Sendable, Equatable {
    /// Apple hierarchical rendering with layered opacities (Recommended default)
    case hierarchical
    /// Flat single-color rendering
    case monochrome
    /// Multi-color symbol rendering using asset colors
    case multicolor
}

// MARK: - CraftIcon Component

/// A standardized SF Symbol icon component adhering to theme size scales, semantic colors,
/// hierarchical depth rendering, and optical weight harmonization.
public struct CraftIcon: View {
    @Environment(\.craftTheme) private var theme

    public let name: String
    public let symbol: CraftSymbol?
    public let size: CraftIconSize
    public let color: Color?
    public let renderingMode: CraftIconRenderingMode
    public let weight: Font.Weight
    public let accessibilityLabel: String?

    public init(
        _ symbol: CraftSymbol,
        size: CraftIconSize = .md,
        color: Color? = nil,
        renderingMode: CraftIconRenderingMode = .hierarchical,
        weight: Font.Weight = .semibold,
        accessibilityLabel: String? = nil
    ) {
        self.symbol = symbol
        self.name = symbol.rawValue
        self.size = size
        self.color = color
        self.renderingMode = renderingMode
        self.weight = weight
        self.accessibilityLabel = accessibilityLabel
    }

    public init(
        _ name: String,
        size: CraftIconSize = .md,
        color: Color? = nil,
        renderingMode: CraftIconRenderingMode = .hierarchical,
        weight: Font.Weight = .semibold,
        accessibilityLabel: String? = nil
    ) {
        self.symbol = CraftSymbol(rawValue: name)
        self.name = name
        self.size = size
        self.color = color
        self.renderingMode = renderingMode
        self.weight = weight
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        Group {
            if let accessibilityLabel {
                iconView
                    .accessibilityLabel(accessibilityLabel)
            } else {
                iconView
                    .accessibilityHidden(true)
            }
        }
        .font(.system(size: size.pointSize, weight: weight))
        .foregroundStyle(color ?? theme.colors.textPrimary)
    }

    @ViewBuilder
    private var iconView: some View {
        let baseImage = Image(systemName: name)
        switch renderingMode {
        case .hierarchical:
            baseImage.symbolRenderingMode(.hierarchical)
        case .monochrome:
            baseImage.symbolRenderingMode(.monochrome)
        case .multicolor:
            baseImage.symbolRenderingMode(.multicolor)
        }
    }
}
