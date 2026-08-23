import Foundation

// MARK: - Spacing Token Protocol

/// Standardized layout spacing scale tokens.
public protocol CraftSpacingTokens: Sendable {
    /// Extra-small spacing (4pt)
    var xs: CGFloat { get }
    /// Small spacing (8pt)
    var sm: CGFloat { get }
    /// Medium spacing (12pt)
    var md: CGFloat { get }
    /// Base standard spacing (16pt)
    var base: CGFloat { get }
    /// Large spacing (24pt)
    var lg: CGFloat { get }
    /// Extra-large spacing (32pt)
    var xl: CGFloat { get }
    /// Double extra-large spacing (48pt)
    var xxl: CGFloat { get }

    // Learning Path Connectors & Grid
    var pathDotDiameter: CGFloat { get }
    var pathDotSpacing: CGFloat { get }
    var pathTurnRadius: CGFloat { get }
    var pathEdgeInset: CGFloat { get }
    var pathRowSpacing: CGFloat { get }
}

public extension CraftSpacingTokens {
    var pathDotDiameter: CGFloat { 5.0 }
    var pathDotSpacing: CGFloat { 7.0 }
    var pathTurnRadius: CGFloat { 32.0 }
    var pathEdgeInset: CGFloat { 28.0 }
    var pathRowSpacing: CGFloat { 60.0 }
}

// MARK: - Default Implementation

/// Default 4pt/8pt harmonic spacing scale tokens.
public struct CraftDefaultSpacingTokens: CraftSpacingTokens {
    public var xs: CGFloat
    public var sm: CGFloat
    public var md: CGFloat
    public var base: CGFloat
    public var lg: CGFloat
    public var xl: CGFloat
    public var xxl: CGFloat

    // Learning Path Connectors & Grid
    public var pathDotDiameter: CGFloat
    public var pathDotSpacing: CGFloat
    public var pathTurnRadius: CGFloat
    public var pathEdgeInset: CGFloat
    public var pathRowSpacing: CGFloat

    public init(
        xs: CGFloat = 4,
        sm: CGFloat = 8,
        md: CGFloat = 12,
        base: CGFloat = 16,
        lg: CGFloat = 24,
        xl: CGFloat = 32,
        xxl: CGFloat = 48,
        pathDotDiameter: CGFloat = 5.0,
        pathDotSpacing: CGFloat = 7.0,
        pathTurnRadius: CGFloat = 32.0,
        pathEdgeInset: CGFloat = 28.0,
        pathRowSpacing: CGFloat = 60.0
    ) {
        self.xs = xs
        self.sm = sm
        self.md = md
        self.base = base
        self.lg = lg
        self.xl = xl
        self.xxl = xxl
        self.pathDotDiameter = pathDotDiameter
        self.pathDotSpacing = pathDotSpacing
        self.pathTurnRadius = pathTurnRadius
        self.pathEdgeInset = pathEdgeInset
        self.pathRowSpacing = pathRowSpacing
    }
}
