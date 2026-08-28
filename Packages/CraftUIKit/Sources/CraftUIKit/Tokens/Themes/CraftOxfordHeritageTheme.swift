import SwiftUI

// MARK: - Oxford Heritage & Ivory Press Theme

/// Oxford Heritage & Ivory Press Theme.
///
/// Designed for IELTS 8.0+, academic masterclasses, and executive language acquisition.
/// Features ivory parchment, midnight library depths, Oxford navy, wax seal gold, and high-contrast New York serif headings.
public struct CraftOxfordHeritageTheme: CraftTheme {
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
        colors: CraftColorTokens = CraftOxfordHeritageColorTokens(),
        typography: CraftTypographyTokens = CraftOxfordHeritageTypographyTokens(),
        spacing: CraftSpacingTokens = CraftDefaultSpacingTokens(),
        radii: CraftRadiusTokens = CraftDefaultRadiusTokens(),
        shadows: CraftShadowTokens = CraftDefaultShadowTokens(),
        gradients: CraftGradientTokens = CraftOxfordHeritageGradientTokens(),
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

public struct CraftOxfordHeritageColorTokens: CraftColorTokens {
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
        canvasBackground: Color = .craftDynamic(light: Color(hex: 0xFBF8F2), dark: Color(hex: 0x0C121D)),
        surfaceCard: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x141E2F)),
        surfaceElevated: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x1D2A40)),
        surfaceSubtle: Color = .craftDynamic(light: Color(hex: 0xF3EDE0), dark: Color(hex: 0x0F1726)),
        brandPrimary: Color = .craftDynamic(light: Color(hex: 0x0A2540), dark: Color(hex: 0x60A5FA)),
        brandSecondary: Color = .craftDynamic(light: Color(hex: 0x8B1E2D), dark: Color(hex: 0xF43F5E)),
        accent: Color = .craftDynamic(light: Color(hex: 0xC59B27), dark: Color(hex: 0xEAB308)),
        textPrimary: Color = .craftDynamic(light: Color(hex: 0x18181B), dark: Color(hex: 0xF8FAFC)),
        textSecondary: Color = .craftDynamic(light: Color(hex: 0x4A5568), dark: Color(hex: 0xA0AEC0)),
        textMuted: Color = .craftDynamic(light: Color(hex: 0x718096), dark: Color(hex: 0x718096)),
        textInverse: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x0C121D)),
        borderDefault: Color = .craftDynamic(light: Color(hex: 0xE2D9C8), dark: Color(hex: 0x1E2C44)),
        borderFocus: Color = .craftDynamic(light: Color(hex: 0x0A2540), dark: Color(hex: 0x60A5FA)),
        hairline: Color = .craftDynamic(light: Color(hex: 0xE2D9C8).opacity(0.8), dark: Color(hex: 0x1E2C44).opacity(0.8)),
        statusSuccess: Color = .craftDynamic(light: Color(hex: 0x059669), dark: Color(hex: 0x34D399)),
        statusWarning: Color = .craftDynamic(light: Color(hex: 0xB45309), dark: Color(hex: 0xFBBF24)),
        statusDanger: Color = .craftDynamic(light: Color(hex: 0x991B1B), dark: Color(hex: 0xF87171)),
        statusInfo: Color = .craftDynamic(light: Color(hex: 0x0284C7), dark: Color(hex: 0x38BDF8)),
        streakStarter: Color = .craftDynamic(light: Color(hex: 0xB45309), dark: Color(hex: 0xFBBF24)),
        streakBlaze: Color = .craftDynamic(light: Color(hex: 0x8B1E2D), dark: Color(hex: 0xF43F5E)),
        streakLegendary: Color = .craftDynamic(light: Color(hex: 0x6D28D9), dark: Color(hex: 0xA78BFA)),
        streakFreeze: Color = .craftDynamic(light: Color(hex: 0x0284C7), dark: Color(hex: 0x38BDF8)),
        streakPending: Color = .craftDynamic(light: Color(hex: 0x94A3B8), dark: Color(hex: 0x718096)),
        streakGlow: Color = .craftDynamic(light: Color(hex: 0xB45309).opacity(0.30), dark: Color(hex: 0xFBBF24).opacity(0.35)),
        pathCompleted: Color = .craftDynamic(light: Color(hex: 0x059669), dark: Color(hex: 0x34D399)),
        pathActive: Color = .craftDynamic(light: Color(hex: 0x0A2540), dark: Color(hex: 0x60A5FA)),
        pathUpcoming: Color = .craftDynamic(light: Color(hex: 0xCBD5E1), dark: Color(hex: 0x334155)),
        pathLocked: Color = .craftDynamic(light: Color(hex: 0xE2D9C8), dark: Color(hex: 0x141E2F)),
        pathHaloGlow: Color = .craftDynamic(light: Color(hex: 0xB45309).opacity(0.20), dark: Color(hex: 0xFBBF24).opacity(0.25))
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

public struct CraftOxfordHeritageTypographyTokens: CraftTypographyTokens {
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
        displayHero: Font = .system(size: 74, weight: .bold, design: .serif),
        displaySerif: Font = .system(.largeTitle, design: .serif, weight: .bold),
        titleLarge: Font = .system(.title, design: .serif, weight: .bold),
        titleMedium: Font = .system(.title2, design: .serif, weight: .bold),
        headline: Font = .system(.headline, design: .serif, weight: .semibold),
        bodyLarge: Font = .system(.body, design: .default, weight: .regular),
        bodyMedium: Font = .system(.callout, design: .default, weight: .regular),
        bodySerif: Font = .system(.body, design: .serif, weight: .regular),
        phonetic: Font = .system(.callout, design: .monospaced, weight: .regular),
        metricRounded: Font = .system(.title2, design: .serif, weight: .bold),
        label: Font = .system(.subheadline, design: .serif, weight: .medium),
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

public struct CraftOxfordHeritageGradientTokens: CraftGradientTokens {
    public var brandHero: LinearGradient
    public var surfaceGlass: LinearGradient
    public var accentShine: LinearGradient
    public var fadeBottom: LinearGradient
    public var streakStarter: LinearGradient
    public var streakBlaze: LinearGradient
    public var streakLegendary: LinearGradient

    public init(
        brandHero: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x0A2540), Color(hex: 0x1E3A8A)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        surfaceGlass: LinearGradient = LinearGradient(
            colors: [Color.white.opacity(0.18), Color.white.opacity(0.04)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        accentShine: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xC59B27), Color(hex: 0xEAB308)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        fadeBottom: LinearGradient = LinearGradient(
            colors: [Color.clear, Color.black.opacity(0.45)],
            startPoint: .top,
            endPoint: .bottom
        ),
        streakStarter: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xC59B27), Color(hex: 0xB45309)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        streakBlaze: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x8B1E2D), Color(hex: 0x991B1B)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        streakLegendary: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x7C3AED), Color(hex: 0xC59B27)],
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
