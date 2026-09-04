import SwiftUI

// MARK: - AI Acoustic & Cyber Obsidian Theme

/// AI Acoustic & Cyber Obsidian Theme.
///
/// Designed for conversational AI, speech recognition, and real-time pronunciation acoustics.
/// Features sonic cobalt blues, obsidian deep blacks, glowing cyan/emerald waveforms, and ultra-precise typography.
public struct CraftAIAcousticTheme: CraftTheme {
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
    public var journeySurfaceStyle: CraftSurfaceStyle { .glass }

    public init(
        colors: CraftColorTokens = CraftAIAcousticColorTokens(),
        typography: CraftTypographyTokens = CraftAIAcousticTypographyTokens(),
        spacing: CraftSpacingTokens = CraftDefaultSpacingTokens(),
        radii: CraftRadiusTokens = CraftDefaultRadiusTokens(),
        shadows: CraftShadowTokens = CraftDefaultShadowTokens(),
        gradients: CraftGradientTokens = CraftAIAcousticGradientTokens(),
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

public struct CraftAIAcousticColorTokens: CraftColorTokens {
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
        canvasBackground: Color = .craftDynamic(light: Color(hex: 0xF4F6FB), dark: Color(hex: 0x090D16)),
        surfaceCard: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x111827)),
        surfaceElevated: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x1F2937)),
        surfaceSubtle: Color = .craftDynamic(light: Color(hex: 0xEEF2F9), dark: Color(hex: 0x0D1424)),
        brandPrimary: Color = .craftDynamic(light: Color(hex: 0x1D4ED8), dark: Color(hex: 0x3B82F6)),
        brandSecondary: Color = .craftDynamic(light: Color(hex: 0x4F46E5), dark: Color(hex: 0x06B6D4)),
        accent: Color = .craftDynamic(light: Color(hex: 0x06B6D4), dark: Color(hex: 0x10B981)),
        textPrimary: Color = .craftDynamic(light: Color(hex: 0x0F172A), dark: Color(hex: 0xF8FAFC)),
        textSecondary: Color = .craftDynamic(light: Color(hex: 0x475569), dark: Color(hex: 0x94A3B8)),
        textMuted: Color = .craftDynamic(light: Color(hex: 0x64748B), dark: Color(hex: 0x64748B)),
        textInverse: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x090D16)),
        borderDefault: Color = .craftDynamic(light: Color(hex: 0xE2E8F0), dark: Color(hex: 0x1E293B)),
        borderFocus: Color = .craftDynamic(light: Color(hex: 0x1D4ED8), dark: Color(hex: 0x3B82F6)),
        hairline: Color = .craftDynamic(light: Color(hex: 0xE2E8F0).opacity(0.8), dark: Color(hex: 0x1E293B).opacity(0.8)),
        statusSuccess: Color = .craftDynamic(light: Color(hex: 0x059669), dark: Color(hex: 0x34D399)),
        statusWarning: Color = .craftDynamic(light: Color(hex: 0xD97706), dark: Color(hex: 0xFBBF24)),
        statusDanger: Color = .craftDynamic(light: Color(hex: 0xDC2626), dark: Color(hex: 0xF87171)),
        statusInfo: Color = .craftDynamic(light: Color(hex: 0x0284C7), dark: Color(hex: 0x06B6D4)),
        streakStarter: Color = .craftDynamic(light: Color(hex: 0x1D4ED8), dark: Color(hex: 0x3B82F6)),
        streakBlaze: Color = .craftDynamic(light: Color(hex: 0x7C3AED), dark: Color(hex: 0x8B5CF6)),
        streakLegendary: Color = .craftDynamic(light: Color(hex: 0x0891B2), dark: Color(hex: 0x06B6D4)),
        streakFreeze: Color = .craftDynamic(light: Color(hex: 0x0284C7), dark: Color(hex: 0x38BDF8)),
        streakPending: Color = .craftDynamic(light: Color(hex: 0x64748B), dark: Color(hex: 0x475569)),
        streakGlow: Color = .craftDynamic(light: Color(hex: 0x1D4ED8).opacity(0.35), dark: Color(hex: 0x3B82F6).opacity(0.40)),
        pathCompleted: Color = .craftDynamic(light: Color(hex: 0x059669), dark: Color(hex: 0x34D399)),
        pathActive: Color = .craftDynamic(light: Color(hex: 0x1D4ED8), dark: Color(hex: 0x3B82F6)),
        pathUpcoming: Color = .craftDynamic(light: Color(hex: 0xCBD5E1), dark: Color(hex: 0x334155)),
        pathLocked: Color = .craftDynamic(light: Color(hex: 0xE2E8F0), dark: Color(hex: 0x1E293B)),
        pathHaloGlow: Color = .craftDynamic(light: Color(hex: 0x1D4ED8).opacity(0.25), dark: Color(hex: 0x3B82F6).opacity(0.30))
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

public struct CraftAIAcousticTypographyTokens: CraftTypographyTokens {
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
        displayLarge: Font = .system(.largeTitle, design: .default, weight: .bold),
        displayHero: Font = .system(size: 70, weight: .black, design: .default),
        displaySerif: Font = .system(.largeTitle, design: .default, weight: .bold),
        titleLarge: Font = .system(.title, design: .default, weight: .bold),
        titleMedium: Font = .system(.title2, design: .default, weight: .semibold),
        headline: Font = .system(.headline, design: .default, weight: .semibold),
        bodyLarge: Font = .system(.body, design: .default, weight: .regular),
        bodyMedium: Font = .system(.callout, design: .default, weight: .regular),
        bodySerif: Font = .system(.body, design: .default, weight: .regular),
        phonetic: Font = .system(.callout, design: .monospaced, weight: .medium),
        metricRounded: Font = .system(.title2, design: .monospaced, weight: .bold),
        label: Font = .system(.subheadline, design: .default, weight: .semibold),
        caption: Font = .system(.caption, design: .monospaced, weight: .regular)
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

public struct CraftAIAcousticGradientTokens: CraftGradientTokens {
    public var brandHero: LinearGradient
    public var surfaceGlass: LinearGradient
    public var accentShine: LinearGradient
    public var fadeBottom: LinearGradient
    public var streakStarter: LinearGradient
    public var streakBlaze: LinearGradient
    public var streakLegendary: LinearGradient

    public init(
        brandHero: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x1D4ED8), Color(hex: 0x06B6D4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        surfaceGlass: LinearGradient = LinearGradient(
            colors: [Color.white.opacity(0.14), Color.white.opacity(0.02)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        accentShine: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x06B6D4), Color(hex: 0x10B981)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        fadeBottom: LinearGradient = LinearGradient(
            colors: [Color.clear, Color.black.opacity(0.5)],
            startPoint: .top,
            endPoint: .bottom
        ),
        streakStarter: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x3B82F6), Color(hex: 0x6366F1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        streakBlaze: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x6366F1), Color(hex: 0xEC4899)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        streakLegendary: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x06B6D4), Color(hex: 0x10B981)],
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
