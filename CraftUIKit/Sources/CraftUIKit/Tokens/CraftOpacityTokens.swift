import Foundation

// MARK: - Opacity Token Protocol

/// Standardized opacity tokens for consistent transparency across the design system.
public protocol CraftOpacityTokens: Sendable {
    /// Subtle backgrounds and tints (0.06)
    var subtle: Double { get }
    /// Muted tinted backgrounds (0.12)
    var muted: Double { get }
    /// Medium overlays and disabled borders (0.3)
    var medium: Double { get }
    /// Scrim backdrop dimming (0.4)
    var scrim: Double { get }
    /// Disabled states (0.5)
    var disabled: Double { get }
}

// MARK: - Default Implementation

/// Default opacity scale tokens.
public struct CraftDefaultOpacityTokens: CraftOpacityTokens {
    public var subtle: Double
    public var muted: Double
    public var medium: Double
    public var scrim: Double
    public var disabled: Double

    public init(
        subtle: Double = 0.06,
        muted: Double = 0.12,
        medium: Double = 0.3,
        scrim: Double = 0.4,
        disabled: Double = 0.5
    ) {
        self.subtle = subtle
        self.muted = muted
        self.medium = medium
        self.scrim = scrim
        self.disabled = disabled
    }
}
