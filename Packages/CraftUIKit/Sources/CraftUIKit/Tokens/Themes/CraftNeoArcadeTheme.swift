import SwiftUI

// MARK: - Neo-Arcade Theme

/// Neo-Arcade Hyper-Vibrant Theme.
///
/// High-energy gamification theme with Cyber Lime, Electric Indigo, and Midnight Navy
/// palettes paired with 100% SF Pro Rounded typography and bouncy spring physics.
public struct CraftNeoArcadeTheme: CraftTheme {
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
        colors: CraftColorTokens = CraftNeoArcadeColorTokens(),
        typography: CraftTypographyTokens = CraftNeoArcadeTypographyTokens(),
        spacing: CraftSpacingTokens = CraftDefaultSpacingTokens(),
        radii: CraftRadiusTokens = CraftDefaultRadiusTokens(),
        shadows: CraftShadowTokens = CraftDefaultShadowTokens(),
        gradients: CraftGradientTokens = CraftNeoArcadeGradientTokens(),
        animations: CraftAnimationTokens = CraftNeoArcadeAnimationTokens(),
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

// MARK: - Neo-Arcade Color Tokens

public struct CraftNeoArcadeColorTokens: CraftColorTokens {
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
        canvasBackground: Color = .craftDynamic(light: Color(hex: 0xF8FAFC), dark: Color(hex: 0x0B0F19)),
        surfaceCard: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x141C2E)),
        surfaceElevated: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x1E293B)),
        surfaceSubtle: Color = .craftDynamic(light: Color(hex: 0xF1F5F9), dark: Color(hex: 0x0F172A)),
        brandPrimary: Color = .craftDynamic(light: Color(hex: 0x84CC16), dark: Color(hex: 0xA3E635)),
        brandSecondary: Color = .craftDynamic(light: Color(hex: 0x06B6D4), dark: Color(hex: 0x22D3EE)),
        accent: Color = .craftDynamic(light: Color(hex: 0x6366F1), dark: Color(hex: 0x818CF8)),
        textPrimary: Color = .craftDynamic(light: Color(hex: 0x0F172A), dark: Color(hex: 0xF8FAFC)),
        textSecondary: Color = .craftDynamic(light: Color(hex: 0x475569), dark: Color(hex: 0x94A3B8)),
        textMuted: Color = .craftDynamic(light: Color(hex: 0x64748B), dark: Color(hex: 0x64748B)),
        textInverse: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x0B0F19)),
        borderDefault: Color = .craftDynamic(light: Color(hex: 0xE2E8F0), dark: Color(hex: 0x1E293B)),
        borderFocus: Color = .craftDynamic(light: Color(hex: 0x65A30D), dark: Color(hex: 0x84CC16)),
        hairline: Color = .craftDynamic(light: Color(hex: 0xE2E8F0).opacity(0.8), dark: Color(hex: 0x1E293B).opacity(0.8)),
        statusSuccess: Color = .craftDynamic(light: Color(hex: 0x16A34A), dark: Color(hex: 0x22C55E)),
        statusWarning: Color = .craftDynamic(light: Color(hex: 0xD97706), dark: Color(hex: 0xF59E0B)),
        statusDanger: Color = .craftDynamic(light: Color(hex: 0xDC2626), dark: Color(hex: 0xEF4444)),
        statusInfo: Color = .craftDynamic(light: Color(hex: 0x0891B2), dark: Color(hex: 0x06B6D4)),
        streakStarter: Color = .craftDynamic(light: Color(hex: 0x65A30D), dark: Color(hex: 0x84CC16)),
        streakBlaze: Color = .craftDynamic(light: Color(hex: 0xD97706), dark: Color(hex: 0xF59E0B)),
        streakLegendary: Color = .craftDynamic(light: Color(hex: 0x4F46E5), dark: Color(hex: 0x6366F1)),
        streakFreeze: Color = .craftDynamic(light: Color(hex: 0x0284C7), dark: Color(hex: 0x38BDF8)),
        streakPending: Color = .craftDynamic(light: Color(hex: 0x94A3B8), dark: Color(hex: 0x64748B)),
        streakGlow: Color = .craftDynamic(light: Color(hex: 0x65A30D).opacity(0.30), dark: Color(hex: 0x84CC16).opacity(0.35)),
        pathCompleted: Color = .craftDynamic(light: Color(hex: 0x16A34A), dark: Color(hex: 0x22C55E)),
        pathActive: Color = .craftDynamic(light: Color(hex: 0x65A30D), dark: Color(hex: 0x84CC16)),
        pathUpcoming: Color = .craftDynamic(light: Color(hex: 0xCBD5E1), dark: Color(hex: 0x334155)),
        pathLocked: Color = .craftDynamic(light: Color(hex: 0xE2E8F0), dark: Color(hex: 0x1E293B)),
        pathHaloGlow: Color = .craftDynamic(light: Color(hex: 0x65A30D).opacity(0.20), dark: Color(hex: 0x84CC16).opacity(0.25))
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

// MARK: - Neo-Arcade Typography Tokens

/// 100% SF Pro Rounded typography for maximum playfulness and friendly punchiness.
public struct CraftNeoArcadeTypographyTokens: CraftTypographyTokens {
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
        bodyLarge: Font = .system(.body, design: .rounded, weight: .medium),
        bodyMedium: Font = .system(.callout, design: .rounded, weight: .medium),
        bodySerif: Font = .system(.body, design: .rounded, weight: .regular),
        phonetic: Font = .system(.callout, design: .monospaced, weight: .medium),
        metricRounded: Font = .system(.title2, design: .rounded, weight: .black),
        label: Font = .system(.subheadline, design: .rounded, weight: .bold),
        caption: Font = .system(.caption, design: .rounded, weight: .medium)
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

// MARK: - Neo-Arcade Gradient Tokens

public struct CraftNeoArcadeGradientTokens: CraftGradientTokens {
    public var brandHero: LinearGradient
    public var surfaceGlass: LinearGradient
    public var accentShine: LinearGradient
    public var fadeBottom: LinearGradient
    public var streakStarter: LinearGradient
    public var streakBlaze: LinearGradient
    public var streakLegendary: LinearGradient

    public init(
        brandHero: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x84CC16), Color(hex: 0x06B6D4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        surfaceGlass: LinearGradient = LinearGradient(
            colors: [Color.white.opacity(0.22), Color.white.opacity(0.06)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        accentShine: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x6366F1), Color(hex: 0x818CF8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        fadeBottom: LinearGradient = LinearGradient(
            colors: [Color.clear, Color.black.opacity(0.4)],
            startPoint: .top,
            endPoint: .bottom
        ),
        streakStarter: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x84CC16), Color(hex: 0x65A30D)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        streakBlaze: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xF59E0B), Color(hex: 0xEA580C)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        streakLegendary: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x6366F1), Color(hex: 0xA855F7)],
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

// MARK: - Neo-Arcade Animation Tokens

public struct CraftNeoArcadeAnimationTokens: CraftAnimationTokens {
    public var springSnappy: Animation
    public var springSmooth: Animation
    public var springBouncy: Animation
    public var springGentle: Animation
    public var springInteractive: Animation

    public init(
        springSnappy: Animation = .spring(response: 0.18, dampingFraction: 0.60),
        springSmooth: Animation = .spring(response: 0.30, dampingFraction: 0.80),
        springBouncy: Animation = .spring(response: 0.38, dampingFraction: 0.50),
        springGentle: Animation = .spring(response: 0.50, dampingFraction: 0.85),
        springInteractive: Animation = .spring(response: 0.12, dampingFraction: 0.78)
    ) {
        self.springSnappy = springSnappy
        self.springSmooth = springSmooth
        self.springBouncy = springBouncy
        self.springGentle = springGentle
        self.springInteractive = springInteractive
    }
}
