import SwiftUI

// MARK: - Tactile Clay & Sesame Mochi Theme

/// Tactile Clay & Sesame Mochi Theme.
///
/// Designed with tactile claymorphism, soft pill shapes, and playful yet premium ceramic textures.
/// Features sesame cream, dark truffle, warm terracotta clay, and pistachio accents with rounded geometry.
public struct CraftTactileClayTheme: CraftTheme {
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
        colors: CraftColorTokens = CraftTactileClayColorTokens(),
        typography: CraftTypographyTokens = CraftTactileClayTypographyTokens(),
        spacing: CraftSpacingTokens = CraftDefaultSpacingTokens(),
        radii: CraftRadiusTokens = CraftDefaultRadiusTokens(),
        shadows: CraftShadowTokens = CraftDefaultShadowTokens(),
        gradients: CraftGradientTokens = CraftTactileClayGradientTokens(),
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

public struct CraftTactileClayColorTokens: CraftColorTokens {
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
        canvasBackground: Color = .craftDynamic(light: Color(hex: 0xF6F3EE), dark: Color(hex: 0x171412)),
        surfaceCard: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x231F1C)),
        surfaceElevated: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x302A26)),
        surfaceSubtle: Color = .craftDynamic(light: Color(hex: 0xEFEBE3), dark: Color(hex: 0x1C1816)),
        brandPrimary: Color = .craftDynamic(light: Color(hex: 0xD96B43), dark: Color(hex: 0xF97316)),
        brandSecondary: Color = .craftDynamic(light: Color(hex: 0x65A30D), dark: Color(hex: 0x84CC16)),
        accent: Color = .craftDynamic(light: Color(hex: 0x4F46E5), dark: Color(hex: 0x818CF8)),
        textPrimary: Color = .craftDynamic(light: Color(hex: 0x292524), dark: Color(hex: 0xF5F5F4)),
        textSecondary: Color = .craftDynamic(light: Color(hex: 0x57534E), dark: Color(hex: 0xA8A29E)),
        textMuted: Color = .craftDynamic(light: Color(hex: 0x78716C), dark: Color(hex: 0x78716C)),
        textInverse: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x171412)),
        borderDefault: Color = .craftDynamic(light: Color(hex: 0xE5DFD5), dark: Color(hex: 0x302A26)),
        borderFocus: Color = .craftDynamic(light: Color(hex: 0xC2410C), dark: Color(hex: 0xF97316)),
        hairline: Color = .craftDynamic(light: Color(hex: 0xE5DFD5).opacity(0.8), dark: Color(hex: 0x302A26).opacity(0.8)),
        statusSuccess: Color = .craftDynamic(light: Color(hex: 0x4D7C0F), dark: Color(hex: 0x84CC16)),
        statusWarning: Color = .craftDynamic(light: Color(hex: 0xB45309), dark: Color(hex: 0xFBBF24)),
        statusDanger: Color = .craftDynamic(light: Color(hex: 0xB91C1C), dark: Color(hex: 0xF87171)),
        statusInfo: Color = .craftDynamic(light: Color(hex: 0x1D4ED8), dark: Color(hex: 0x60A5FA)),
        streakStarter: Color = .craftDynamic(light: Color(hex: 0xC2410C), dark: Color(hex: 0xF97316)),
        streakBlaze: Color = .craftDynamic(light: Color(hex: 0x9A3412), dark: Color(hex: 0xEA580C)),
        streakLegendary: Color = .craftDynamic(light: Color(hex: 0x4338CA), dark: Color(hex: 0x818CF8)),
        streakFreeze: Color = .craftDynamic(light: Color(hex: 0x0284C7), dark: Color(hex: 0x38BDF8)),
        streakPending: Color = .craftDynamic(light: Color(hex: 0x78716C), dark: Color(hex: 0xA8A29E)),
        streakGlow: Color = .craftDynamic(light: Color(hex: 0xC2410C).opacity(0.30), dark: Color(hex: 0xF97316).opacity(0.35)),
        pathCompleted: Color = .craftDynamic(light: Color(hex: 0x4D7C0F), dark: Color(hex: 0x84CC16)),
        pathActive: Color = .craftDynamic(light: Color(hex: 0xC2410C), dark: Color(hex: 0xF97316)),
        pathUpcoming: Color = .craftDynamic(light: Color(hex: 0xD6D3D1), dark: Color(hex: 0x44403C)),
        pathLocked: Color = .craftDynamic(light: Color(hex: 0xE5DFD5), dark: Color(hex: 0x231F1C)),
        pathHaloGlow: Color = .craftDynamic(light: Color(hex: 0xC2410C).opacity(0.18), dark: Color(hex: 0xF97316).opacity(0.22))
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

public struct CraftTactileClayTypographyTokens: CraftTypographyTokens {
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
        displayLarge: Font = .system(.largeTitle, design: .rounded, weight: .bold),
        displayHero: Font = .system(size: 70, weight: .bold, design: .rounded),
        displaySerif: Font = .system(.largeTitle, design: .rounded, weight: .bold),
        titleLarge: Font = .system(.title, design: .rounded, weight: .bold),
        titleMedium: Font = .system(.title2, design: .rounded, weight: .semibold),
        headline: Font = .system(.headline, design: .rounded, weight: .semibold),
        bodyLarge: Font = .system(.body, design: .rounded, weight: .regular),
        bodyMedium: Font = .system(.callout, design: .rounded, weight: .regular),
        bodySerif: Font = .system(.body, design: .default, weight: .regular),
        phonetic: Font = .system(.callout, design: .monospaced, weight: .regular),
        metricRounded: Font = .system(.title2, design: .rounded, weight: .bold),
        label: Font = .system(.subheadline, design: .rounded, weight: .medium),
        caption: Font = .system(.caption, design: .rounded, weight: .regular)
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

public struct CraftTactileClayGradientTokens: CraftGradientTokens {
    public var brandHero: LinearGradient
    public var surfaceGlass: LinearGradient
    public var accentShine: LinearGradient
    public var fadeBottom: LinearGradient
    public var streakStarter: LinearGradient
    public var streakBlaze: LinearGradient
    public var streakLegendary: LinearGradient

    public init(
        brandHero: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xD96B43), Color(hex: 0xEA580C)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        surfaceGlass: LinearGradient = LinearGradient(
            colors: [Color.white.opacity(0.18), Color.white.opacity(0.04)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        accentShine: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x65A30D), Color(hex: 0x84CC16)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        fadeBottom: LinearGradient = LinearGradient(
            colors: [Color.clear, Color.black.opacity(0.40)],
            startPoint: .top,
            endPoint: .bottom
        ),
        streakStarter: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xD96B43), Color(hex: 0xF97316)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        streakBlaze: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xEA580C), Color(hex: 0xDC2626)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        streakLegendary: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x4F46E5), Color(hex: 0x818CF8)],
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
