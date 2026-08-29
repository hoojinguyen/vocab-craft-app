import SwiftUI

// MARK: - Smart Coach Theme (ELSA Speak-inspired)

/// Smart Coach Theme — ELSA Speak-inspired AI professional coaching aesthetic.
///
/// Designed with clean geometric sans-serif typography, ELSA Blue (#0483F0) as the
/// primary anchor, flat design without 3D depth effects, modern blue-to-teal gradients,
/// subtle ambient shadows, and smooth professional spring animations that convey
/// competence and trust in AI-powered language coaching.
public struct CraftSmartCoachTheme: CraftTheme {
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
        colors: CraftColorTokens = CraftSmartCoachColorTokens(),
        typography: CraftTypographyTokens = CraftSmartCoachTypographyTokens(),
        spacing: CraftSpacingTokens = CraftDefaultSpacingTokens(),
        radii: CraftRadiusTokens = CraftDefaultRadiusTokens(),
        shadows: CraftShadowTokens = CraftDefaultShadowTokens(),
        gradients: CraftGradientTokens = CraftSmartCoachGradientTokens(),
        animations: CraftAnimationTokens = CraftSmartCoachAnimationTokens(),
        opacities: CraftOpacityTokens = CraftDefaultOpacityTokens(),
        depths: CraftDepthTokens = CraftSmartCoachDepthTokens(),
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

/// ELSA Speak-inspired color palette anchored by ELSA Blue (#0483F0).
///
/// Features a focused functional palette: Blue for primary actions, Green for pronunciation
/// success, Yellow for highlights, and Deep Blue for dark containers. Designed for maximum
/// readability in a language learning context.
public struct CraftSmartCoachColorTokens: CraftColorTokens {
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
        // Canvas & Backgrounds — Pure white / deep dark (tonal elevation)
        canvasBackground: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x0F0F0F)),
        surfaceCard: Color = .craftDynamic(light: Color(hex: 0xF8F9FA), dark: Color(hex: 0x1A1A1A)),
        surfaceElevated: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x252525)),
        surfaceSubtle: Color = .craftDynamic(light: Color(hex: 0xF0F4F8), dark: Color(hex: 0x141414)),

        // Brand — ELSA Blue & Deep Brand Blue
        brandPrimary: Color = .craftDynamic(light: Color(hex: 0x0483F0), dark: Color(hex: 0x3B9EF5)),
        brandSecondary: Color = .craftDynamic(light: Color(hex: 0x042132), dark: Color(hex: 0x0C3A5A)),

        // Accent — ELSA Yellow
        accent: Color = .craftDynamic(light: Color(hex: 0xF0DA4C), dark: Color(hex: 0xF5E06A)),

        // Text — High contrast for readability
        textPrimary: Color = .craftDynamic(light: Color(hex: 0x1A1A1A), dark: Color(hex: 0xF5F5F5)),
        textSecondary: Color = .craftDynamic(light: Color(hex: 0x6B7280), dark: Color(hex: 0x9CA3AF)),
        textMuted: Color = .craftDynamic(light: Color(hex: 0x9CA3AF), dark: Color(hex: 0x6B7280)),
        textInverse: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x0F0F0F)),

        // Borders — Neutral cool gray
        borderDefault: Color = .craftDynamic(light: Color(hex: 0xE5E7EB), dark: Color(hex: 0x2A2A2A)),
        borderFocus: Color = .craftDynamic(light: Color(hex: 0x0483F0), dark: Color(hex: 0x3B9EF5)),
        hairline: Color = .craftDynamic(
            light: Color(hex: 0xE5E7EB).opacity(0.8),
            dark: Color(hex: 0x2A2A2A).opacity(0.8)
        ),

        // Status — Green for correct pronunciation, Blue for info
        statusSuccess: Color = .craftDynamic(light: Color(hex: 0x48DE82), dark: Color(hex: 0x5EE89A)),
        statusWarning: Color = .craftDynamic(light: Color(hex: 0xF0DA4C), dark: Color(hex: 0xF5E06A)),
        statusDanger: Color = .craftDynamic(light: Color(hex: 0xEF4444), dark: Color(hex: 0xF87171)),
        statusInfo: Color = .craftDynamic(light: Color(hex: 0x0483F0), dark: Color(hex: 0x3B9EF5)),

        // Streak
        streakStarter: Color = .craftDynamic(light: Color(hex: 0x0483F0), dark: Color(hex: 0x3B9EF5)),
        streakBlaze: Color = .craftDynamic(light: Color(hex: 0xF0DA4C), dark: Color(hex: 0xF5E06A)),
        streakLegendary: Color = .craftDynamic(light: Color(hex: 0x6366F1), dark: Color(hex: 0x818CF8)),
        streakFreeze: Color = .craftDynamic(light: Color(hex: 0x06B6D4), dark: Color(hex: 0x22D3EE)),
        streakPending: Color = .craftDynamic(light: Color(hex: 0x9CA3AF), dark: Color(hex: 0x6B7280)),
        streakGlow: Color = .craftDynamic(
            light: Color(hex: 0x0483F0).opacity(0.30),
            dark: Color(hex: 0x3B9EF5).opacity(0.35)
        ),

        // Learning Path
        pathCompleted: Color = .craftDynamic(light: Color(hex: 0x48DE82), dark: Color(hex: 0x48DE82)),
        pathActive: Color = .craftDynamic(light: Color(hex: 0x0483F0), dark: Color(hex: 0x3B9EF5)),
        pathUpcoming: Color = .craftDynamic(light: Color(hex: 0xD1D5DB), dark: Color(hex: 0x374151)),
        pathLocked: Color = .craftDynamic(light: Color(hex: 0xE5E7EB), dark: Color(hex: 0x1F1F1F)),
        pathHaloGlow: Color = .craftDynamic(
            light: Color(hex: 0x0483F0).opacity(0.18),
            dark: Color(hex: 0x3B9EF5).opacity(0.22)
        )
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

/// Clean geometric sans-serif typography inspired by ELSA's professional coaching interface.
///
/// Uses SF Pro default design axis for maximum readability, prioritizing clarity
/// for language learners reading phonetic transcriptions and pronunciation feedback.
public struct CraftSmartCoachTypographyTokens: CraftTypographyTokens {
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
        displayHero: Font = .system(size: 72, weight: .black, design: .default),
        displaySerif: Font = .system(.largeTitle, design: .serif, weight: .bold),
        titleLarge: Font = .system(.title, design: .default, weight: .bold),
        titleMedium: Font = .system(.title2, design: .default, weight: .semibold),
        headline: Font = .system(.headline, design: .default, weight: .semibold),
        bodyLarge: Font = .system(.body, design: .default, weight: .regular),
        bodyMedium: Font = .system(.callout, design: .default, weight: .regular),
        bodySerif: Font = .system(.body, design: .serif, weight: .regular),
        phonetic: Font = .system(.callout, design: .monospaced, weight: .regular),
        metricRounded: Font = .system(.title2, design: .rounded, weight: .bold),
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

// MARK: - Gradient Tokens

/// Modern blue-to-teal gradients echoing ELSA's AI-forward visual identity.
///
/// Features a Blue→Teal hero gradient (ELSA signature), Indigo→Violet premium accent,
/// and subtle frosted glass surfaces.
public struct CraftSmartCoachGradientTokens: CraftGradientTokens {
    public var brandHero: LinearGradient
    public var surfaceGlass: LinearGradient
    public var accentShine: LinearGradient
    public var fadeBottom: LinearGradient
    public var streakStarter: LinearGradient
    public var streakBlaze: LinearGradient
    public var streakLegendary: LinearGradient

    public init(
        brandHero: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x0483F0), Color(hex: 0x06B6D4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        surfaceGlass: LinearGradient = LinearGradient(
            colors: [Color.white.opacity(0.10), Color.white.opacity(0.02)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        accentShine: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x6366F1), Color(hex: 0x8B5CF6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        fadeBottom: LinearGradient = LinearGradient(
            colors: [Color.clear, Color.black.opacity(0.4)],
            startPoint: .top,
            endPoint: .bottom
        ),
        streakStarter: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x0483F0), Color(hex: 0x3B82F6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        streakBlaze: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xF0DA4C), Color(hex: 0xF59E0B)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        streakLegendary: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x6366F1), Color(hex: 0x06B6D4)],
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

// MARK: - Depth Tokens

/// Flat depth tokens — ELSA uses no 3D tactile effects, relying on tonal elevation instead.
public struct CraftSmartCoachDepthTokens: CraftDepthTokens {
    public var depthSm: CGFloat
    public var depthMd: CGFloat
    public var depthLg: CGFloat
    public var topHighlight: LinearGradient

    public init(
        depthSm: CGFloat = 0,
        depthMd: CGFloat = 0,
        depthLg: CGFloat = 0,
        topHighlight: LinearGradient = LinearGradient(
            colors: [Color.clear, Color.clear],
            startPoint: .top,
            endPoint: .bottom
        )
    ) {
        self.depthSm = depthSm
        self.depthMd = depthMd
        self.depthLg = depthLg
        self.topHighlight = topHighlight
    }
}

// MARK: - Animation Tokens

/// Smooth, professional spring animations for ELSA's coaching interface.
///
/// Higher damping fractions create controlled, precise movements that convey
/// competence and reliability — no playful bouncing, just polished transitions.
public struct CraftSmartCoachAnimationTokens: CraftAnimationTokens {
    public var springSnappy: Animation
    public var springSmooth: Animation
    public var springBouncy: Animation
    public var springGentle: Animation
    public var springInteractive: Animation

    public init(
        springSnappy: Animation = .spring(response: 0.25, dampingFraction: 0.80),
        springSmooth: Animation = .spring(response: 0.35, dampingFraction: 0.88),
        springBouncy: Animation = .spring(response: 0.40, dampingFraction: 0.72),
        springGentle: Animation = .spring(response: 0.55, dampingFraction: 0.92),
        springInteractive: Animation = .spring(response: 0.15, dampingFraction: 0.85)
    ) {
        self.springSnappy = springSnappy
        self.springSmooth = springSmooth
        self.springBouncy = springBouncy
        self.springGentle = springGentle
        self.springInteractive = springInteractive
    }
}
