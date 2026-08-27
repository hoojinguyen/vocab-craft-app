import SwiftUI

// MARK: - Nordic Zen Theme

/// Nordic Zen & Dynamic Void Theme.
///
/// Scandinavian minimalism emphasizing focus, ample whitespace, serene Celestial Violet,
/// and Frost Cyan accents with clean, lightweight typography.
public struct CraftNordicZenTheme: CraftTheme {
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
        colors: CraftColorTokens = CraftNordicZenColorTokens(),
        typography: CraftTypographyTokens = CraftNordicZenTypographyTokens(),
        spacing: CraftSpacingTokens = CraftDefaultSpacingTokens(),
        radii: CraftRadiusTokens = CraftDefaultRadiusTokens(),
        shadows: CraftShadowTokens = CraftDefaultShadowTokens(),
        gradients: CraftGradientTokens = CraftNordicZenGradientTokens(),
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

// MARK: - Nordic Zen Color Tokens

public struct CraftNordicZenColorTokens: CraftColorTokens {
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
        canvasBackground: Color = .craftDynamic(light: Color(hex: 0xF4F4F5), dark: Color(hex: 0x18181B)),
        surfaceCard: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x27272A)),
        surfaceElevated: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x3F3F46)),
        surfaceSubtle: Color = .craftDynamic(light: Color(hex: 0xE4E4E7), dark: Color(hex: 0x202023)),
        brandPrimary: Color = .craftDynamic(light: Color(hex: 0x8B5CF6), dark: Color(hex: 0xA78BFA)),
        brandSecondary: Color = .craftDynamic(light: Color(hex: 0x6D28D9), dark: Color(hex: 0xC4B5FD)),
        accent: Color = .craftDynamic(light: Color(hex: 0x06B6D4), dark: Color(hex: 0x38BDF8)),
        textPrimary: Color = .craftDynamic(light: Color(hex: 0x18181B), dark: Color(hex: 0xFAFAFA)),
        textSecondary: Color = .craftDynamic(light: Color(hex: 0x71717A), dark: Color(hex: 0xA1A1AA)),
        textMuted: Color = .craftDynamic(light: Color(hex: 0xA1A1AA), dark: Color(hex: 0x71717A)),
        textInverse: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x18181B)),
        borderDefault: Color = .craftDynamic(light: Color(hex: 0xE4E4E7), dark: Color(hex: 0x27272A)),
        borderFocus: Color = Color(hex: 0x8B5CF6),
        hairline: Color = .craftDynamic(light: Color(hex: 0xE4E4E7).opacity(0.8), dark: Color(hex: 0x27272A).opacity(0.8)),
        statusSuccess: Color = Color(hex: 0x10B981),
        statusWarning: Color = Color(hex: 0xF59E0B),
        statusDanger: Color = Color(hex: 0xEF4444),
        statusInfo: Color = Color(hex: 0x06B6D4),
        streakStarter: Color = Color(hex: 0x8B5CF6),
        streakBlaze: Color = Color(hex: 0xA855F7),
        streakLegendary: Color = Color(hex: 0x06B6D4),
        streakFreeze: Color = Color(hex: 0x38BDF8),
        streakPending: Color = Color(hex: 0x94A3B8),
        streakGlow: Color = Color(hex: 0x8B5CF6).opacity(0.30),
        pathCompleted: Color = Color(hex: 0x10B981),
        pathActive: Color = Color(hex: 0x8B5CF6),
        pathUpcoming: Color = .craftDynamic(light: Color(hex: 0xCBD5E1), dark: Color(hex: 0x334155)),
        pathLocked: Color = .craftDynamic(light: Color(hex: 0xE2E8F0), dark: Color(hex: 0x1E293B)),
        pathHaloGlow: Color = Color(hex: 0x8B5CF6).opacity(0.18)
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

// MARK: - Nordic Zen Typography Tokens

/// Minimalist, high-legibility SF Pro Default typography with elegant weights.
public struct CraftNordicZenTypographyTokens: CraftTypographyTokens {
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
        displayLarge: Font = .system(.largeTitle, design: .default, weight: .semibold),
        displayHero: Font = .system(size: 64, weight: .medium, design: .default),
        displaySerif: Font = .system(.largeTitle, design: .serif, weight: .medium),
        titleLarge: Font = .system(.title, design: .default, weight: .semibold),
        titleMedium: Font = .system(.title2, design: .default, weight: .medium),
        headline: Font = .system(.headline, design: .default, weight: .semibold),
        bodyLarge: Font = .system(.body, design: .default, weight: .regular),
        bodyMedium: Font = .system(.callout, design: .default, weight: .regular),
        bodySerif: Font = .system(.body, design: .serif, weight: .regular),
        phonetic: Font = .system(.callout, design: .monospaced, weight: .regular),
        metricRounded: Font = .system(.title2, design: .rounded, weight: .semibold),
        label: Font = .system(.subheadline, design: .default, weight: .medium),
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

// MARK: - Nordic Zen Gradient Tokens

public struct CraftNordicZenGradientTokens: CraftGradientTokens {
    public var brandHero: LinearGradient
    public var surfaceGlass: LinearGradient
    public var accentShine: LinearGradient
    public var fadeBottom: LinearGradient
    public var streakStarter: LinearGradient
    public var streakBlaze: LinearGradient
    public var streakLegendary: LinearGradient

    public init(
        brandHero: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x8B5CF6), Color(hex: 0x6D28D9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        surfaceGlass: LinearGradient = LinearGradient(
            colors: [Color.white.opacity(0.15), Color.white.opacity(0.04)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        accentShine: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x06B6D4), Color(hex: 0x38BDF8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        fadeBottom: LinearGradient = LinearGradient(
            colors: [Color.clear, Color.black.opacity(0.35)],
            startPoint: .top,
            endPoint: .bottom
        ),
        streakStarter: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x8B5CF6), Color(hex: 0x7C3AED)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        streakBlaze: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xA855F7), Color(hex: 0x9333EA)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        streakLegendary: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x06B6D4), Color(hex: 0x8B5CF6)],
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
