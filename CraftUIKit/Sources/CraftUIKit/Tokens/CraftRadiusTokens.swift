import Foundation

// MARK: - Radius Token Protocol

/// Standardized corner radius tokens.
public protocol CraftRadiusTokens: Sendable {
    /// Extra-small corner radius (4pt)
    var xs: CGFloat { get }
    /// Small corner radius (8pt)
    var sm: CGFloat { get }
    /// Medium corner radius (12pt)
    var md: CGFloat { get }
    /// Large corner radius (16pt)
    var lg: CGFloat { get }
    /// Extra-large corner radius (24pt)
    var xl: CGFloat { get }
    /// Fully rounded / capsule radius (9999pt)
    var full: CGFloat { get }
}

// MARK: - Default Implementation

/// Default corner radius scale tokens.
public struct CraftDefaultRadiusTokens: CraftRadiusTokens {
    public var xs: CGFloat
    public var sm: CGFloat
    public var md: CGFloat
    public var lg: CGFloat
    public var xl: CGFloat
    public var full: CGFloat

    public init(
        xs: CGFloat = 4,
        sm: CGFloat = 8,
        md: CGFloat = 12,
        lg: CGFloat = 16,
        xl: CGFloat = 24,
        full: CGFloat = 9999
    ) {
        self.xs = xs
        self.sm = sm
        self.md = md
        self.lg = lg
        self.xl = xl
        self.full = full
    }
}
