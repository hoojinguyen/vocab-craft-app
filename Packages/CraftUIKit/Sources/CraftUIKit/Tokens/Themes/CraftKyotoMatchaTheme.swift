import SwiftUI

// MARK: - Kyoto Matcha & Mindful Zen Theme

/// Kyoto Matcha & Mindful Zen Theme.
///
/// Designed to eliminate language anxiety and induce a focused, calm alpha state.
/// Features warm oatmeal milk, Hinoki forest darks, matcha sage green, and yuzu gold accents.
public struct CraftKyotoMatchaTheme: CraftTheme {
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
        colors: CraftColorTokens = CraftKyotoMatchaColorTokens(),
        typography: CraftTypographyTokens = CraftKyotoMatchaTypographyTokens(),
        spacing: CraftSpacingTokens = CraftDefaultSpacingTokens(),
        radii: CraftRadiusTokens = CraftDefaultRadiusTokens(),
        shadows: CraftShadowTokens = CraftDefaultShadowTokens(),
        gradients: CraftGradientTokens = CraftKyotoMatchaGradientTokens(),
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

public struct CraftKyotoMatchaColorTokens: CraftColorTokens {
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
        canvasBackground: Color = .craftDynamic(light: Color(hex: 0xF9F6F0), dark: Color(hex: 0x111A16)),
        surfaceCard: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x18241F)),
        surfaceElevated: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x22332C)),
        surfaceSubtle: Color = .craftDynamic(light: Color(hex: 0xEFEBE3), dark: Color(hex: 0x141F1A)),
        brandPrimary: Color = .craftDynamic(light: Color(hex: 0x3D6B52), dark: Color(hex: 0x52B788)),
        brandSecondary: Color = .craftDynamic(light: Color(hex: 0x2D4F3C), dark: Color(hex: 0x74C69D)),
        accent: Color = .craftDynamic(light: Color(hex: 0xE09F3E), dark: Color(hex: 0xF4A261)),
        textPrimary: Color = .craftDynamic(light: Color(hex: 0x242A27), dark: Color(hex: 0xF2F7F4)),
        textSecondary: Color = .craftDynamic(light: Color(hex: 0x5C6661), dark: Color(hex: 0xA3B3AB)),
        textMuted: Color = .craftDynamic(light: Color(hex: 0x85948C), dark: Color(hex: 0x6D7D75)),
        textInverse: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x111A16)),
        borderDefault: Color = .craftDynamic(light: Color(hex: 0xE3DED4), dark: Color(hex: 0x22332C)),
        borderFocus: Color = .craftDynamic(light: Color(hex: 0x3D6B52), dark: Color(hex: 0x52B788)),
        hairline: Color = .craftDynamic(light: Color(hex: 0xE3DED4).opacity(0.8), dark: Color(hex: 0x22332C).opacity(0.8)),
        statusSuccess: Color = .craftDynamic(light: Color(hex: 0x3D6B52), dark: Color(hex: 0x52B788)),
        statusWarning: Color = .craftDynamic(light: Color(hex: 0xD97706), dark: Color(hex: 0xE09F3E)),
        statusDanger: Color = .craftDynamic(light: Color(hex: 0xDC2626), dark: Color(hex: 0xE76F51)),
        statusInfo: Color = .craftDynamic(light: Color(hex: 0x2A6F97), dark: Color(hex: 0x457B9D)),
        streakStarter: Color = .craftDynamic(light: Color(hex: 0xD97706), dark: Color(hex: 0xE09F3E)),
        streakBlaze: Color = .craftDynamic(light: Color(hex: 0xC85A32), dark: Color(hex: 0xE76F51)),
        streakLegendary: Color = .craftDynamic(light: Color(hex: 0x52796F), dark: Color(hex: 0x84A98C)),
        streakFreeze: Color = .craftDynamic(light: Color(hex: 0x3D6B52), dark: Color(hex: 0x52B788)),
        streakPending: Color = .craftDynamic(light: Color(hex: 0x94A3B8), dark: Color(hex: 0x6D7D75)),
        streakGlow: Color = .craftDynamic(light: Color(hex: 0xD97706).opacity(0.30), dark: Color(hex: 0xE09F3E).opacity(0.35)),
        pathCompleted: Color = .craftDynamic(light: Color(hex: 0x3D6B52), dark: Color(hex: 0x52B788)),
        pathActive: Color = .craftDynamic(light: Color(hex: 0x3D6B52), dark: Color(hex: 0x52B788)),
        pathUpcoming: Color = .craftDynamic(light: Color(hex: 0xCCD5AE), dark: Color(hex: 0x2D4F3C)),
        pathLocked: Color = .craftDynamic(light: Color(hex: 0xE3DED4), dark: Color(hex: 0x18241F)),
        pathHaloGlow: Color = .craftDynamic(light: Color(hex: 0x3D6B52).opacity(0.18), dark: Color(hex: 0x52B788).opacity(0.22))
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

public struct CraftKyotoMatchaTypographyTokens: CraftTypographyTokens {
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
        displayLarge: Font = .system(.largeTitle, design: .serif, weight: .bold),
        displayHero: Font = .system(size: 68, weight: .bold, design: .serif),
        displaySerif: Font = .system(.largeTitle, design: .serif, weight: .bold),
        titleLarge: Font = .system(.title, design: .serif, weight: .bold),
        titleMedium: Font = .system(.title2, design: .serif, weight: .semibold),
        headline: Font = .system(.headline, design: .rounded, weight: .semibold),
        bodyLarge: Font = .system(.body, design: .default, weight: .regular),
        bodyMedium: Font = .system(.callout, design: .default, weight: .regular),
        bodySerif: Font = .system(.body, design: .serif, weight: .regular),
        phonetic: Font = .system(.callout, design: .monospaced, weight: .regular),
        metricRounded: Font = .system(.title2, design: .rounded, weight: .bold),
        label: Font = .system(.subheadline, design: .rounded, weight: .medium),
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

public struct CraftKyotoMatchaGradientTokens: CraftGradientTokens {
    public var brandHero: LinearGradient
    public var surfaceGlass: LinearGradient
    public var accentShine: LinearGradient
    public var fadeBottom: LinearGradient
    public var streakStarter: LinearGradient
    public var streakBlaze: LinearGradient
    public var streakLegendary: LinearGradient

    public init(
        brandHero: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x3D6B52), Color(hex: 0x52B788)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        surfaceGlass: LinearGradient = LinearGradient(
            colors: [Color.white.opacity(0.16), Color.white.opacity(0.04)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        accentShine: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xE09F3E), Color(hex: 0xF4A261)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        fadeBottom: LinearGradient = LinearGradient(
            colors: [Color.clear, Color.black.opacity(0.35)],
            startPoint: .top,
            endPoint: .bottom
        ),
        streakStarter: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xE09F3E), Color(hex: 0xE76F51)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        streakBlaze: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xE76F51), Color(hex: 0xD62828)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        streakLegendary: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x52B788), Color(hex: 0x2A9D8F)],
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
