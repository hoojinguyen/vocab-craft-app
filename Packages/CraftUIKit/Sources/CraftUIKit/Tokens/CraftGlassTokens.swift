import SwiftUI

// MARK: - Glass Token Protocol

/// Liquid glass tokens defining translucent materials, tint opacities, and specular border gradients.
public protocol CraftGlassTokens: Sendable {
    /// Opacity applied to background tint overlay for frosted glass surfaces.
    var tintOpacity: Double { get }
    /// Specular highlight gradient for subtle glass border reflections.
    var borderGradient: LinearGradient { get }
}

public extension CraftGlassTokens {
    var tintOpacity: Double { 0.15 }
    var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.35),
                Color.white.opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Default Implementation

/// Default glass design tokens.
public struct CraftDefaultGlassTokens: CraftGlassTokens {
    public var tintOpacity: Double
    public var borderGradient: LinearGradient

    public init(
        tintOpacity: Double = 0.15,
        borderGradient: LinearGradient = LinearGradient(
            colors: [
                Color.white.opacity(0.35),
                Color.white.opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    ) {
        self.tintOpacity = tintOpacity
        self.borderGradient = borderGradient
    }
}
