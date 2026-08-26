import SwiftUI

// MARK: - Shadow Model

/// Represents a standardized drop shadow configuration.
public struct CraftShadow: Sendable, Equatable {
    public var color: Color
    public var radius: CGFloat
    public var x: CGFloat
    public var y: CGFloat

    public init(
        color: Color = Color.black.opacity(0.1),
        radius: CGFloat,
        x: CGFloat = 0,
        y: CGFloat = 0
    ) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

// MARK: - Shadow Token Protocol

/// Elevation and drop shadow tokens.
public protocol CraftShadowTokens: Sendable {
    /// Small subtle shadow
    var sm: CraftShadow { get }
    /// Medium card shadow
    var md: CraftShadow { get }
    /// Large elevated surface shadow
    var lg: CraftShadow { get }
    /// Extra-large modal/popover shadow
    var xl: CraftShadow { get }
}

// MARK: - Default Implementation

/// Default shadow tokens.
public struct CraftDefaultShadowTokens: CraftShadowTokens {
    public var sm: CraftShadow
    public var md: CraftShadow
    public var lg: CraftShadow
    public var xl: CraftShadow

    public init(
        sm: CraftShadow = CraftShadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2),
        md: CraftShadow = CraftShadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4),
        lg: CraftShadow = CraftShadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8),
        xl: CraftShadow = CraftShadow(color: Color.black.opacity(0.16), radius: 24, x: 0, y: 12)
    ) {
        self.sm = sm
        self.md = md
        self.lg = lg
        self.xl = xl
    }
}

// MARK: - View Extension

public extension View {
    /// Applies a `CraftShadow` to the view.
    func craftShadow(_ shadow: CraftShadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}
