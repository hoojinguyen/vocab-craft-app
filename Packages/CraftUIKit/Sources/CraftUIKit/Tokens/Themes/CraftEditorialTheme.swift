import SwiftUI

// MARK: - Warm Editorial Theme

/// Warm Editorial & Tactile Glass Theme.
///
/// Blends dictionary-grade editorial typography (New York Serif display) with
/// organic warm linen/obsidian backgrounds and iOS 26 Liquid Glass depth.
public struct CraftEditorialTheme: CraftTheme {
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
        colors: CraftColorTokens = CraftEditorialColorTokens(),
        typography: CraftTypographyTokens = CraftEditorialTypographyTokens(),
        spacing: CraftSpacingTokens = CraftDefaultSpacingTokens(),
        radii: CraftRadiusTokens = CraftDefaultRadiusTokens(),
        shadows: CraftShadowTokens = CraftDefaultShadowTokens(),
        gradients: CraftGradientTokens = CraftEditorialGradientTokens(),
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

// MARK: - Editorial Color Tokens

/// Warm Linen, Obsidian Botanical, Deep Teal, and Apricot color tokens.
public struct CraftEditorialColorTokens: CraftColorTokens {
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
        canvasBackground: Color = .craftDynamic(light: Color(hex: 0xFAF9F5), dark: Color(hex: 0x121615)),
        surfaceCard: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x1A2220)),
        surfaceElevated: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x242F2C)),
        surfaceSubtle: Color = .craftDynamic(light: Color(hex: 0xF3EFE6), dark: Color(hex: 0x161D1B)),
        brandPrimary: Color = .craftDynamic(light: Color(hex: 0x0D9488), dark: Color(hex: 0x14B8A6)),
        brandSecondary: Color = .craftDynamic(light: Color(hex: 0x059669), dark: Color(hex: 0x10B981)),
        accent: Color = .craftDynamic(light: Color(hex: 0xF97316), dark: Color(hex: 0xFB923C)),
        textPrimary: Color = .craftDynamic(light: Color(hex: 0x131E1B), dark: Color(hex: 0xF4FDF9)),
        textSecondary: Color = .craftDynamic(light: Color(hex: 0x4A5E58), dark: Color(hex: 0x9EB3AC)),
        textMuted: Color = .craftDynamic(light: Color(hex: 0x6E857E), dark: Color(hex: 0x6E857E)),
        textInverse: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x121615)),
        borderDefault: Color = .craftDynamic(light: Color(hex: 0xE2DDD5), dark: Color(hex: 0x242F2C)),
        borderFocus: Color = .craftDynamic(light: Color(hex: 0x0D9488), dark: Color(hex: 0x14B8A6)),
        hairline: Color = .craftDynamic(light: Color(hex: 0xE2DDD5).opacity(0.8), dark: Color(hex: 0x242F2C).opacity(0.8)),
        statusSuccess: Color = .craftDynamic(light: Color(hex: 0x059669), dark: Color(hex: 0x34D399)),
        statusWarning: Color = .craftDynamic(light: Color(hex: 0xD97706), dark: Color(hex: 0xFBBF24)),
        statusDanger: Color = .craftDynamic(light: Color(hex: 0xDC2626), dark: Color(hex: 0xF87171)),
        statusInfo: Color = .craftDynamic(light: Color(hex: 0x0EA5E9), dark: Color(hex: 0x38BDF8)),
        streakStarter: Color = .craftDynamic(light: Color(hex: 0xF97316), dark: Color(hex: 0xFB923C)),
        streakBlaze: Color = .craftDynamic(light: Color(hex: 0xEA580C), dark: Color(hex: 0xF97316)),
        streakLegendary: Color = .craftDynamic(light: Color(hex: 0x7C3AED), dark: Color(hex: 0xA78BFA)),
        streakFreeze: Color = .craftDynamic(light: Color(hex: 0x0284C7), dark: Color(hex: 0x38BDF8)),
        streakPending: Color = .craftDynamic(light: Color(hex: 0x94A3B8), dark: Color(hex: 0x64748B)),
        streakGlow: Color = .craftDynamic(light: Color(hex: 0xF97316).opacity(0.35), dark: Color(hex: 0xFB923C).opacity(0.40)),
        pathCompleted: Color = .craftDynamic(light: Color(hex: 0x059669), dark: Color(hex: 0x34D399)),
        pathActive: Color = .craftDynamic(light: Color(hex: 0x0D9488), dark: Color(hex: 0x14B8A6)),
        pathUpcoming: Color = .craftDynamic(light: Color(hex: 0xCBD5E1), dark: Color(hex: 0x334155)),
        pathLocked: Color = .craftDynamic(light: Color(hex: 0xE2E8F0), dark: Color(hex: 0x1E293B)),
        pathHaloGlow: Color = .craftDynamic(light: Color(hex: 0x0D9488).opacity(0.20), dark: Color(hex: 0x14B8A6).opacity(0.25))
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

// MARK: - Editorial Typography Tokens

/// Multi-axis typography pairing Serif headings with rounded metrics and clean body ink.
public struct CraftEditorialTypographyTokens: CraftTypographyTokens {
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
        displayHero: Font = .system(size: 72, weight: .bold, design: .serif),
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

// MARK: - Editorial Gradient Tokens

public struct CraftEditorialGradientTokens: CraftGradientTokens {
    public var brandHero: LinearGradient
    public var surfaceGlass: LinearGradient
    public var accentShine: LinearGradient
    public var fadeBottom: LinearGradient
    public var streakStarter: LinearGradient
    public var streakBlaze: LinearGradient
    public var streakLegendary: LinearGradient

    public init(
        brandHero: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x0D9488), Color(hex: 0x059669)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        surfaceGlass: LinearGradient = LinearGradient(
            colors: [Color.white.opacity(0.18), Color.white.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        accentShine: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xF97316), Color(hex: 0xFBBF24)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        fadeBottom: LinearGradient = LinearGradient(
            colors: [Color.clear, Color.black.opacity(0.4)],
            startPoint: .top,
            endPoint: .bottom
        ),
        streakStarter: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xF97316), Color(hex: 0xEA580C)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        streakBlaze: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xEA580C), Color(hex: 0xDC2626)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        streakLegendary: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x8B5CF6), Color(hex: 0x06B6D4)],
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
