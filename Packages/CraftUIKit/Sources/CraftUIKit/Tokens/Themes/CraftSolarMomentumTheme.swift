import SwiftUI

// MARK: - Solar Momentum & Coral Horizon Theme

/// Solar Momentum & Coral Horizon Theme.
///
/// Designed for high-energy motivation, habit discipline, and unbroken daily streaks.
/// Features warm solar sand, midnight horizon deep purples, radiant solar coral, and vibrant gold gradients.
public struct CraftSolarMomentumTheme: CraftTheme {
    public var colors: CraftColorTokens
    public var typography: CraftTypographyTokens
    public var spacing: CraftSpacingTokens
    public var radii: CraftRadiusTokens
    public var shadows: CraftShadowTokens
    public var gradients: CraftGradientTokens
    public var animations: CraftAnimationTokens
    public var opacities: CraftOpacityTokens
    public var depths: CraftDepthTokens
    public var glass: CraftGlassTokens

    public init(
        colors: CraftColorTokens = CraftSolarMomentumColorTokens(),
        typography: CraftTypographyTokens = CraftSolarMomentumTypographyTokens(),
        spacing: CraftSpacingTokens = CraftDefaultSpacingTokens(),
        radii: CraftRadiusTokens = CraftDefaultRadiusTokens(),
        shadows: CraftShadowTokens = CraftDefaultShadowTokens(),
        gradients: CraftGradientTokens = CraftSolarMomentumGradientTokens(),
        animations: CraftAnimationTokens = CraftDefaultAnimationTokens(),
        opacities: CraftOpacityTokens = CraftDefaultOpacityTokens(),
        depths: CraftDepthTokens = CraftDefaultDepthTokens(),
        glass: CraftGlassTokens = CraftDefaultGlassTokens()
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
        self.glass = glass
    }
}

// MARK: - Color Tokens

public struct CraftSolarMomentumColorTokens: CraftColorTokens {
    public var canvasBackground: Color
    public var surfaceCard: Color
    public var surfaceElevated: Color
    public var surfaceSubtle: Color
    public var brandPrimary: Color
    public var brandSecondary: Color
    public var accent: Color
    public var textPrimary: Color
    public var textSecondary: Color
    public var textMuted: Color
    public var textInverse: Color
    public var borderDefault: Color
    public var borderFocus: Color
    public var hairline: Color
    public var statusSuccess: Color
    public var statusWarning: Color
    public var statusDanger: Color
    public var statusInfo: Color
    public var streakStarter: Color
    public var streakBlaze: Color
    public var streakLegendary: Color
    public var streakFreeze: Color
    public var streakPending: Color
    public var streakGlow: Color
    public var pathCompleted: Color
    public var pathActive: Color
    public var pathUpcoming: Color
    public var pathLocked: Color
    public var pathHaloGlow: Color

    public init(
        canvasBackground: Color = .craftDynamic(light: Color(hex: 0xFFFDF9), dark: Color(hex: 0x120E16)),
        surfaceCard: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x1D1724)),
        surfaceElevated: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x2A2033)),
        surfaceSubtle: Color = .craftDynamic(light: Color(hex: 0xFFF5EE), dark: Color(hex: 0x16111C)),
        brandPrimary: Color = .craftDynamic(light: Color(hex: 0xFF5A36), dark: Color(hex: 0xFF6B4A)),
        brandSecondary: Color = .craftDynamic(light: Color(hex: 0xF59E0B), dark: Color(hex: 0xFBBF24)),
        accent: Color = .craftDynamic(light: Color(hex: 0xEC4899), dark: Color(hex: 0xFB7185)),
        textPrimary: Color = .craftDynamic(light: Color(hex: 0x1C1917), dark: Color(hex: 0xFFF7ED)),
        textSecondary: Color = .craftDynamic(light: Color(hex: 0x57534E), dark: Color(hex: 0xA8A29E)),
        textMuted: Color = .craftDynamic(light: Color(hex: 0x78716C), dark: Color(hex: 0x78716C)),
        textInverse: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x120E16)),
        borderDefault: Color = .craftDynamic(light: Color(hex: 0xFDE8E1), dark: Color(hex: 0x2A2033)),
        borderFocus: Color = Color(hex: 0xFF5A36),
        hairline: Color = .craftDynamic(light: Color(hex: 0xFDE8E1).opacity(0.8), dark: Color(hex: 0x2A2033).opacity(0.8)),
        statusSuccess: Color = Color(hex: 0x10B981),
        statusWarning: Color = Color(hex: 0xF59E0B),
        statusDanger: Color = Color(hex: 0xEF4444),
        statusInfo: Color = Color(hex: 0x0284C7),
        streakStarter: Color = Color(hex: 0xFF5A36),
        streakBlaze: Color = Color(hex: 0xEA580C),
        streakLegendary: Color = Color(hex: 0xEC4899),
        streakFreeze: Color = Color(hex: 0x38BDF8),
        streakPending: Color = Color(hex: 0x78716C),
        streakGlow: Color = Color(hex: 0xFF5A36).opacity(0.40),
        pathCompleted: Color = Color(hex: 0x10B981),
        pathActive: Color = Color(hex: 0xFF5A36),
        pathUpcoming: Color = .craftDynamic(light: Color(hex: 0xFED7AA), dark: Color(hex: 0x3B2D26)),
        pathLocked: Color = .craftDynamic(light: Color(hex: 0xFDE8E1), dark: Color(hex: 0x1D1724)),
        pathHaloGlow: Color = Color(hex: 0xFF5A36).opacity(0.28)
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
        self.streakStarter = streakStarter
        self.streakBlaze = streakBlaze
        self.streakLegendary = streakLegendary
        self.streakFreeze = streakFreeze
        self.streakPending = streakPending
        self.streakGlow = streakGlow
        self.pathCompleted = pathCompleted
        self.pathActive = pathActive
        self.pathUpcoming = pathUpcoming
        self.pathLocked = pathLocked
        self.pathHaloGlow = pathHaloGlow
    }
}

// MARK: - Typography Tokens

public struct CraftSolarMomentumTypographyTokens: CraftTypographyTokens {
    public var displayLarge: Font
    public var displayHero: Font
    public var displaySerif: Font
    public var titleLarge: Font
    public var titleMedium: Font
    public var headline: Font
    public var bodyLarge: Font
    public var bodyMedium: Font
    public var bodySerif: Font
    public var phonetic: Font
    public var metricRounded: Font
    public var label: Font
    public var caption: Font

    public init(
        displayLarge: Font = .system(.largeTitle, design: .rounded, weight: .black),
        displayHero: Font = .system(size: 72, weight: .black, design: .rounded),
        displaySerif: Font = .system(.largeTitle, design: .rounded, weight: .bold),
        titleLarge: Font = .system(.title, design: .rounded, weight: .bold),
        titleMedium: Font = .system(.title2, design: .rounded, weight: .bold),
        headline: Font = .system(.headline, design: .rounded, weight: .bold),
        bodyLarge: Font = .system(.body, design: .default, weight: .medium),
        bodyMedium: Font = .system(.callout, design: .default, weight: .medium),
        bodySerif: Font = .system(.body, design: .default, weight: .regular),
        phonetic: Font = .system(.callout, design: .monospaced, weight: .medium),
        metricRounded: Font = .system(.title2, design: .rounded, weight: .black),
        label: Font = .system(.subheadline, design: .rounded, weight: .bold),
        caption: Font = .system(.caption, design: .default, weight: .regular)
    ) {
        self.displayLarge = displayLarge
        self.displayHero = displayHero
        self.displaySerif = displaySerif
        self.titleLarge = titleLarge
        self.titleMedium = titleMedium
        self.headline = headline
        self.bodyLarge = bodyLarge
        self.bodyMedium = bodyMedium
        self.bodySerif = bodySerif
        self.phonetic = phonetic
        self.metricRounded = metricRounded
        self.label = label
        self.caption = caption
    }
}

// MARK: - Gradient Tokens

public struct CraftSolarMomentumGradientTokens: CraftGradientTokens {
    public var brandHero: LinearGradient
    public var surfaceGlass: LinearGradient
    public var accentShine: LinearGradient
    public var fadeBottom: LinearGradient
    public var streakStarter: LinearGradient
    public var streakBlaze: LinearGradient
    public var streakLegendary: LinearGradient

    public init(
        brandHero: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xFF5A36), Color(hex: 0xF59E0B)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        surfaceGlass: LinearGradient = LinearGradient(
            colors: [Color.white.opacity(0.20), Color.white.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        accentShine: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xF59E0B), Color(hex: 0xEC4899)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        fadeBottom: LinearGradient = LinearGradient(
            colors: [Color.clear, Color.black.opacity(0.40)],
            startPoint: .top,
            endPoint: .bottom
        ),
        streakStarter: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xFF5A36), Color(hex: 0xF59E0B)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        streakBlaze: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xEA580C), Color(hex: 0xEC4899)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        streakLegendary: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xEC4899), Color(hex: 0xF59E0B)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    ) {
        self.brandHero = brandHero
        self.surfaceGlass = surfaceGlass
        self.accentShine = accentShine
        self.fadeBottom = fadeBottom
        self.streakStarter = streakStarter
        self.streakBlaze = streakBlaze
        self.streakLegendary = streakLegendary
    }
}
