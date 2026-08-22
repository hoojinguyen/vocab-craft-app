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

    public init(
        xs: CGFloat = 4,
        sm: CGFloat = 8,
        md: CGFloat = 12,
        base: CGFloat = 16,
        lg: CGFloat = 24,
        xl: CGFloat = 32,
        xxl: CGFloat = 48
    ) {
        self.xs = xs
        self.sm = sm
        self.md = md
        self.base = base
        self.lg = lg
        self.xl = xl
        self.xxl = xxl
    }
}
