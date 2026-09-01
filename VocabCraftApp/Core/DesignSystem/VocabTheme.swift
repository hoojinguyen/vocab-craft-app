import CraftUIKit
import SwiftUI

// MARK: - Vocab Color Tokens

/// VocabCraft brand-aligned color tokens conforming to `CraftColorTokens`.
public struct VocabColorTokens: CraftColorTokens {
    // Canvas & Backgrounds
    public var canvasBackground: Color
    public var surfaceCard: Color
    public var surfaceElevated: Color
    public var surfaceSubtle: Color

    // Brand & Action
    public var brandPrimary: Color
    public var brandSecondary: Color
    public var accent: Color

    // Text & Ink
    public var textPrimary: Color
    public var textSecondary: Color
    public var textMuted: Color
    public var textInverse: Color

    // Borders & Lines
    public var borderDefault: Color
    public var borderFocus: Color
    public var hairline: Color

    // Status & Feedback
    public var statusSuccess: Color
    public var statusWarning: Color
    public var statusDanger: Color
    public var statusInfo: Color

    public init(
        canvasBackground: Color = .vocabCanvas,
        surfaceCard: Color = .vocabSurfaceCard,
        surfaceElevated: Color = .vocabSurfaceCard,
        surfaceSubtle: Color = .vocabSurfaceSoft,
        brandPrimary: Color = .vocabHeroTeal,
        brandSecondary: Color = .vocabHeroAccent,
        accent: Color = .vocabPeach,
        textPrimary: Color = .vocabInk,
        textSecondary: Color = .vocabMuted,
        textMuted: Color = .vocabMuted,
        textInverse: Color = .vocabCanvas,
        borderDefault: Color = .vocabHairline,
        borderFocus: Color = .vocabHeroAccent,
        hairline: Color = .vocabHairline,
        statusSuccess: Color = .vocabMint,
        statusWarning: Color = .vocabPeach,
        statusDanger: Color = .vocabCoral,
        statusInfo: Color = .vocabLavender
    ) {
        self.canvasBackground = canvasBackground
        self.surfaceCard = surfaceCard
        self.surfaceElevated = surfaceElevated
        self.surfaceSubtle = surfaceSubtle
        self.brandPrimary = brandPrimary
        self.brandSecondary = brandSecondary
        self.accent = accent
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.textMuted = textMuted
        self.textInverse = textInverse
        self.borderDefault = borderDefault
        self.borderFocus = borderFocus
        self.hairline = hairline
        self.statusSuccess = statusSuccess
        self.statusWarning = statusWarning
        self.statusDanger = statusDanger
        self.statusInfo = statusInfo
    }
}

// MARK: - Vocab Gradient Tokens

/// VocabCraft brand-aligned gradient tokens conforming to `CraftGradientTokens`.
public struct VocabGradientTokens: CraftGradientTokens {
    public var brandHero: LinearGradient
    public var surfaceGlass: LinearGradient
    public var accentShine: LinearGradient
    public var fadeBottom: LinearGradient

    public init(
        brandHero: LinearGradient = LinearGradient(
            colors: [.vocabHeroTeal, .vocabHeroAccent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        surfaceGlass: LinearGradient = LinearGradient(
            colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        accentShine: LinearGradient = LinearGradient(
            colors: [.vocabPeach, .vocabCoral],
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

// MARK: - Vocab Theme

/// The core theme for VocabCraftApp conforming to `CraftTheme`.
public struct VocabTheme: CraftTheme {
    public var colors: CraftColorTokens
    public var typography: CraftTypographyTokens
    public var spacing: CraftSpacingTokens
    public var radii: CraftRadiusTokens
    public var shadows: CraftShadowTokens
    public var gradients: CraftGradientTokens
    public var animations: CraftAnimationTokens
    public var opacities: CraftOpacityTokens
    public var depths: CraftDepthTokens

    public init(
        colors: CraftColorTokens = VocabColorTokens(),
        typography: CraftTypographyTokens = CraftDefaultTypographyTokens(),
        spacing: CraftSpacingTokens = CraftDefaultSpacingTokens(),
        radii: CraftRadiusTokens = CraftDefaultRadiusTokens(),
        shadows: CraftShadowTokens = CraftDefaultShadowTokens(),
        gradients: CraftGradientTokens = VocabGradientTokens(),
        animations: CraftAnimationTokens = CraftDefaultAnimationTokens(),
        opacities: CraftOpacityTokens = CraftDefaultOpacityTokens(),
        depths: CraftDepthTokens = CraftDefaultDepthTokens()
    ) {
        self.colors = colors
        self.typography = typography
        self.spacing = spacing
        self.radii = radii
        self.shadows = shadows
        self.gradients = gradients
        self.animations = animations
        self.opacities = opacities
        self.depths = depths
    }
}

// MARK: - Bento Card Button Style

/// Tactile spring scale interaction button style used across interactive cards.
public struct BentoCardButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
