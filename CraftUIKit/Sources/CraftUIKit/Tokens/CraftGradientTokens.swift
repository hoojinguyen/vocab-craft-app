import SwiftUI

// MARK: - Gradient Token Protocol

/// Standardized gradient tokens for hero banners, glass surfaces, highlights, and scrims.
public protocol CraftGradientTokens: Sendable {
    /// Vibrant brand hero gradient
    var brandHero: LinearGradient { get }
    /// Translucent frosted glass gradient
    var surfaceGlass: LinearGradient { get }
    /// Bright golden accent shine gradient
    var accentShine: LinearGradient { get }
    /// Bottom scrim fade gradient
    var fadeBottom: LinearGradient { get }
}

// MARK: - Default Implementation

/// Default gradient tokens.
public struct CraftDefaultGradientTokens: CraftGradientTokens {
    public var brandHero: LinearGradient
    public var surfaceGlass: LinearGradient
    public var accentShine: LinearGradient
    public var fadeBottom: LinearGradient

    public init(
        brandHero: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xE06D3B), Color(hex: 0xEA580C)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        surfaceGlass: LinearGradient = LinearGradient(
            colors: [Color.white.opacity(0.20), Color.white.opacity(0.06)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        accentShine: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xF59E0B), Color(hex: 0xFBBF24)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        fadeBottom: LinearGradient = LinearGradient(
            colors: [Color.clear, Color.black.opacity(0.4)],
            startPoint: .top,
            endPoint: .bottom
        )
    ) {
        self.brandHero = brandHero
        self.surfaceGlass = surfaceGlass
        self.accentShine = accentShine
        self.fadeBottom = fadeBottom
    }
}
