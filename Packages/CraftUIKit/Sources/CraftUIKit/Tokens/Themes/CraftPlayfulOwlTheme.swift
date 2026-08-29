import SwiftUI

// MARK: - Playful Owl Theme (Duolingo-inspired)

/// Playful Owl Theme — Duolingo-inspired gamification aesthetic.
///
/// Designed with chunky 3D tactile buttons, fully rounded typography, vibrant animal-named
/// color palette (Feather Green, Macaw Blue, Cardinal Red, Bee Yellow, Fox Orange, Beetle Purple),
/// and extra bouncy spring animations that make learning feel like a game.
public struct CraftPlayfulOwlTheme: CraftTheme {
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
        colors: CraftColorTokens = CraftPlayfulOwlColorTokens(),
        typography: CraftTypographyTokens = CraftPlayfulOwlTypographyTokens(),
        spacing: CraftSpacingTokens = CraftDefaultSpacingTokens(),
        radii: CraftRadiusTokens = CraftDefaultRadiusTokens(),
        shadows: CraftShadowTokens = CraftPlayfulOwlShadowTokens(),
        gradients: CraftGradientTokens = CraftPlayfulOwlGradientTokens(),
        animations: CraftAnimationTokens = CraftPlayfulOwlAnimationTokens(),
        opacities: CraftOpacityTokens = CraftDefaultOpacityTokens(),
        depths: CraftDepthTokens = CraftPlayfulOwlDepthTokens(),
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

/// Duolingo-inspired color palette using the animal-named color system.
///
/// Feather Green (#58CC02) anchors the brand, with Macaw Blue, Cardinal Red,
/// Bee Yellow, Fox Orange, and Beetle Purple as vibrant accents.
public struct CraftPlayfulOwlColorTokens: CraftColorTokens {
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
        // Canvas & Backgrounds — Snow white / dark warm gray
        canvasBackground: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x1A1A1A)),
        surfaceCard: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x2D2D2D)),
        surfaceElevated: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x353535)),
        surfaceSubtle: Color = .craftDynamic(light: Color(hex: 0xF7F7F7), dark: Color(hex: 0x232323)),

        // Brand — Feather Green & Mask Green
        brandPrimary: Color = .craftDynamic(light: Color(hex: 0x58CC02), dark: Color(hex: 0x6BD600)),
        brandSecondary: Color = .craftDynamic(light: Color(hex: 0x89E219), dark: Color(hex: 0x89E219)),

        // Accent — Bee Yellow
        accent: Color = .craftDynamic(light: Color(hex: 0xFFC800), dark: Color(hex: 0xFFC800)),

        // Text — Eel dark / Snow light
        textPrimary: Color = .craftDynamic(light: Color(hex: 0x4B4B4B), dark: Color(hex: 0xF5F5F5)),
        textSecondary: Color = .craftDynamic(light: Color(hex: 0x777777), dark: Color(hex: 0xAFAFAF)),
        textMuted: Color = .craftDynamic(light: Color(hex: 0xAFAFAF), dark: Color(hex: 0x777777)),
        textInverse: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x1A1A1A)),

        // Borders
        borderDefault: Color = .craftDynamic(light: Color(hex: 0xE5E5E5), dark: Color(hex: 0x3A3A3A)),
        borderFocus: Color = .craftDynamic(light: Color(hex: 0x58CC02), dark: Color(hex: 0x6BD600)),
        hairline: Color = .craftDynamic(
            light: Color(hex: 0xE5E5E5).opacity(0.8),
            dark: Color(hex: 0x3A3A3A).opacity(0.8)
        ),

        // Status — Macaw, Fox, Cardinal
        statusSuccess: Color = .craftDynamic(light: Color(hex: 0x58CC02), dark: Color(hex: 0x89E219)),
        statusWarning: Color = .craftDynamic(light: Color(hex: 0xFF9600), dark: Color(hex: 0xFFC800)),
        statusDanger: Color = .craftDynamic(light: Color(hex: 0xFF4B4B), dark: Color(hex: 0xFF6B6B)),
        statusInfo: Color = .craftDynamic(light: Color(hex: 0x1CB0F6), dark: Color(hex: 0x1CB0F6)),

        // Streak — Fox Orange, Beetle Purple, Macaw Blue
        streakStarter: Color = .craftDynamic(light: Color(hex: 0x58CC02), dark: Color(hex: 0x89E219)),
        streakBlaze: Color = .craftDynamic(light: Color(hex: 0xFF9600), dark: Color(hex: 0xFFC800)),
        streakLegendary: Color = .craftDynamic(light: Color(hex: 0xCE82FF), dark: Color(hex: 0xCE82FF)),
        streakFreeze: Color = .craftDynamic(light: Color(hex: 0x1CB0F6), dark: Color(hex: 0x1CB0F6)),
        streakPending: Color = .craftDynamic(light: Color(hex: 0xAFAFAF), dark: Color(hex: 0x777777)),
        streakGlow: Color = .craftDynamic(
            light: Color(hex: 0xFFC800).opacity(0.35),
            dark: Color(hex: 0xFFC800).opacity(0.40)
        ),

        // Learning Path
        pathCompleted: Color = .craftDynamic(light: Color(hex: 0x58CC02), dark: Color(hex: 0x89E219)),
        pathActive: Color = .craftDynamic(light: Color(hex: 0x58CC02), dark: Color(hex: 0x89E219)),
        pathUpcoming: Color = .craftDynamic(light: Color(hex: 0xE5E5E5), dark: Color(hex: 0x3A3A3A)),
        pathLocked: Color = .craftDynamic(light: Color(hex: 0xF0F0F0), dark: Color(hex: 0x2A2A2A)),
        pathHaloGlow: Color = .craftDynamic(
            light: Color(hex: 0x58CC02).opacity(0.20),
            dark: Color(hex: 0x89E219).opacity(0.25)
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

/// Fully rounded typography evoking Duolingo's Feather Bold + DIN Next Rounded pairing.
///
/// Uses SF Rounded across all axes with heavier weights for display/headline
/// to capture the chunky, playful character of Duolingo's type hierarchy.
public struct CraftPlayfulOwlTypographyTokens: CraftTypographyTokens {
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
        displaySerif: Font = .system(.largeTitle, design: .rounded, weight: .black),
        titleLarge: Font = .system(.title, design: .rounded, weight: .bold),
        titleMedium: Font = .system(.title2, design: .rounded, weight: .bold),
        headline: Font = .system(.headline, design: .rounded, weight: .bold),
        bodyLarge: Font = .system(.body, design: .rounded, weight: .regular),
        bodyMedium: Font = .system(.callout, design: .rounded, weight: .regular),
        bodySerif: Font = .system(.body, design: .rounded, weight: .regular),
        phonetic: Font = .system(.callout, design: .monospaced, weight: .regular),
        metricRounded: Font = .system(.title2, design: .rounded, weight: .black),
        label: Font = .system(.subheadline, design: .rounded, weight: .semibold),
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

/// Vibrant green-to-lime gradients echoing Duolingo's brand energy.
public struct CraftPlayfulOwlGradientTokens: CraftGradientTokens {
    public var brandHero: LinearGradient
    public var surfaceGlass: LinearGradient
    public var accentShine: LinearGradient
    public var fadeBottom: LinearGradient
    public var streakStarter: LinearGradient
    public var streakBlaze: LinearGradient
    public var streakLegendary: LinearGradient

    public init(
        brandHero: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x58CC02), Color(hex: 0x89E219)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        surfaceGlass: LinearGradient = LinearGradient(
            colors: [Color.white.opacity(0.22), Color.white.opacity(0.06)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        accentShine: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xFFC800), Color(hex: 0xFF9600)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        fadeBottom: LinearGradient = LinearGradient(
            colors: [Color.clear, Color.black.opacity(0.4)],
            startPoint: .top,
            endPoint: .bottom
        ),
        streakStarter: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x58CC02), Color(hex: 0x89E219)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        streakBlaze: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xFF9600), Color(hex: 0xFFC800)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        streakLegendary: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xCE82FF), Color(hex: 0x1CB0F6)],
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

// MARK: - Shadow Tokens

/// Duolingo-signature chunky flat bottom-shadow creating a tactile 3D button feel.
///
/// Uses zero blur radius with pure vertical offset for a clean "raised slab" look.
/// The 4px medium shadow is the signature Duolingo depth.
public struct CraftPlayfulOwlShadowTokens: CraftShadowTokens {
    public var sm: CraftShadow
    public var md: CraftShadow
    public var lg: CraftShadow
    public var xl: CraftShadow

    public init(
        sm: CraftShadow = CraftShadow(color: Color.black.opacity(0.12), radius: 0, x: 0, y: 2),
        md: CraftShadow = CraftShadow(color: Color.black.opacity(0.14), radius: 0, x: 0, y: 4),
        lg: CraftShadow = CraftShadow(color: Color.black.opacity(0.14), radius: 2, x: 0, y: 6),
        xl: CraftShadow = CraftShadow(color: Color.black.opacity(0.18), radius: 4, x: 0, y: 8)
    ) {
        self.sm = sm
        self.md = md
        self.lg = lg
        self.xl = xl
    }
}

// MARK: - Depth Tokens

/// Enhanced tactile depth with strong bevel highlights for Duolingo's chunky button aesthetic.
public struct CraftPlayfulOwlDepthTokens: CraftDepthTokens {
    public var depthSm: CGFloat
    public var depthMd: CGFloat
    public var depthLg: CGFloat
    public var topHighlight: LinearGradient

    public init(
        depthSm: CGFloat = 2,
        depthMd: CGFloat = 4,
        depthLg: CGFloat = 6,
        topHighlight: LinearGradient = LinearGradient(
            colors: [Color.white.opacity(0.40), Color.white.opacity(0.10), Color.clear],
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

/// Extra bouncy spring animations for Duolingo's playful, game-like feel.
///
/// Lower damping fractions create more bounce and overshoot, making UI interactions
/// feel energetic and rewarding — especially celebrations and streak milestones.
public struct CraftPlayfulOwlAnimationTokens: CraftAnimationTokens {
    public var springSnappy: Animation
    public var springSmooth: Animation
    public var springBouncy: Animation
    public var springGentle: Animation
    public var springInteractive: Animation

    public init(
        springSnappy: Animation = .spring(response: 0.20, dampingFraction: 0.65),
        springSmooth: Animation = .spring(response: 0.35, dampingFraction: 0.80),
        springBouncy: Animation = .spring(response: 0.45, dampingFraction: 0.52),
        springGentle: Animation = .spring(response: 0.55, dampingFraction: 0.88),
        springInteractive: Animation = .spring(response: 0.15, dampingFraction: 0.78)
    ) {
        self.springSnappy = springSnappy
        self.springSmooth = springSmooth
        self.springBouncy = springBouncy
        self.springGentle = springGentle
        self.springInteractive = springInteractive
    }
}
