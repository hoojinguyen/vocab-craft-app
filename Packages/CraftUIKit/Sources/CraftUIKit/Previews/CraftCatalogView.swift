import SwiftUI

// MARK: - Catalog Theme & Option Models

/// Available themes for the CraftUIKit interactive catalog gallery.
public enum CatalogThemeType: String, CaseIterable, Identifiable, Sendable {
    case kyotoMatcha = "Kyoto Matcha Zen"
    case aiAcoustic = "AI Acoustic Obsidian"
    case oxfordHeritage = "Oxford Heritage"
    case solarMomentum = "Solar Momentum"
    case tactileClay = "Tactile Clay Mochi"
    case editorial = "Warm Editorial"
    case neoArcade = "Neo-Arcade"
    case nordicZen = "Nordic Zen"
    case defaultSlate = "Default Slate"
    case emeraldTeal = "Emerald Teal"

    public var id: String { rawValue }

    public var theme: any CraftTheme {
        switch self {
        case .kyotoMatcha:
            return CraftKyotoMatchaTheme()
        case .aiAcoustic:
            return CraftAIAcousticTheme()
        case .oxfordHeritage:
            return CraftOxfordHeritageTheme()
        case .solarMomentum:
            return CraftSolarMomentumTheme()
        case .tactileClay:
            return CraftTactileClayTheme()
        case .editorial:
            return CraftEditorialTheme()
        case .neoArcade:
            return CraftNeoArcadeTheme()
        case .nordicZen:
            return CraftNordicZenTheme()
        case .defaultSlate:
            return CraftDefaultTheme()
        case .emeraldTeal:
            return CraftEmeraldTheme()
        }
    }
}

/// Color scheme appearance options for the gallery.
public enum CatalogColorScheme: String, CaseIterable, Identifiable, Sendable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    public var id: String { rawValue }

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Language options for testing localized strings and string catalogs across the gallery.
public enum CatalogLanguage: String, CaseIterable, Identifiable, Sendable {
    case english = "English"
    case vietnamese = "Tiếng Việt"

    public var id: String { rawValue }

    public var code: String {
        switch self {
        case .english: return "en"
        case .vietnamese: return "vi"
        }
    }
}

/// Demo tab item model for showcasing `CraftFloatingTabBar`.
public enum CatalogTabItem: String, CaseIterable, Identifiable, CraftTabItemProtocol {
    case home = "Home"
    case study = "Study"
    case practice = "Practice"
    case profile = "Profile"

    public var id: String { rawValue }
    public var title: String { rawValue }
    public var symbol: String {
        switch self {
        case .home: return "house"
        case .study: return "character.book.closed"
        case .practice: return "bolt.fill"
        case .profile: return "person.crop.circle"
        }
    }

    public var badgeCount: Int? {
        switch self {
        case .practice: return 3
        default: return nil
        }
    }

    public var showsTitle: Bool { false }
    public var showsSymbol: Bool { true }
}

/// Interactive preset options for demonstrating domain-specific `CraftEmptyState` illustrations and copy.
public enum CatalogEmptyStatePreset: String, CaseIterable, Identifiable, Sendable {
    case study = "Study Cards"
    case search = "Search Results"
    case bookmark = "Bookmarks"

    public var id: String { rawValue }

    public var symbol: CraftSymbol {
        switch self {
        case .study: return .study
        case .search: return .search
        case .bookmark: return .bookmark
        }
    }

    public var title: String {
        switch self {
        case .study: return "No Study Cards"
        case .search: return "No Results Found"
        case .bookmark: return "No Bookmarks Saved"
        }
    }

    public var message: String {
        switch self {
        case .study: return "Create your first vocabulary card to start reviewing."
        case .search: return "No vocabulary words matched your query. Try broadening your keywords."
        case .bookmark: return "Save challenging vocabulary words during quizzes to review them here later."
        }
    }

    public var buttonTitle: String {
        switch self {
        case .study: return "Add Word"
        case .search: return "Clear Search"
        case .bookmark: return "Browse Words"
        }
    }

    public var buttonSymbol: CraftSymbol {
        switch self {
        case .study: return .add
        case .search: return .clear
        case .bookmark: return .list
        }
    }
}

public enum CatalogFeedbackPreset: String, CaseIterable, Identifiable, Sendable {
    case success = "Tactile 3D Success"
    case error = "Tactile 3D Error"
    case warning = "Outlined Warning"
    case elevated = "Elevated Success"
    case glass = "Liquid Glass Info"
    case flat = "Flat Success"

    public var id: String { rawValue }

    public var status: CraftFeedbackStatus {
        switch self {
        case .success, .elevated, .flat: return .success
        case .error: return .error
        case .warning: return .warning
        case .glass: return .info
        }
    }

    public var title: String {
        switch self {
        case .success, .elevated, .flat: return "Correct!"
        case .error: return "Incorrect"
        case .warning: return "Almost!"
        case .glass: return "Explanation"
        }
    }

    public var message: String? {
        switch self {
        case .success, .flat: return "Great job! Keep the streak going."
        case .error: return "Correct answer: Phenomenon (/fəˈnɒmɪnən/)"
        case .warning: return "Review the pronunciation of the last word."
        case .glass: return "Liquid Glass translucent surface with refraction tint."
        case .elevated: return "Elevated depth surface with layered shadows."
        }
    }

    public var secondaryActionTitle: String? {
        switch self {
        case .error: return "Explain"
        default: return nil
        }
    }

    public var surfaceStyle: CraftSurfaceStyle? {
        switch self {
        case .glass: return .glass
        case .elevated: return .elevated
        case .warning: return .outlined
        case .flat: return .flat
        case .success, .error: return .tactile3D
        }
    }
}

/// Interactive preset options for showcasing Streak Gamification tiers.
public enum CatalogStreakTierPreset: String, CaseIterable, Identifiable, Sendable {
    case starter = "Starter (3d)"
    case blaze = "Blaze (14d)"
    case legendary = "Legendary (45d)"

    public var id: String { rawValue }

    public var days: Int {
        switch self {
        case .starter: return 3
        case .blaze: return 14
        case .legendary: return 45
        }
    }

    public var tier: CraftStreakTier {
        switch self {
        case .starter: return .starter
        case .blaze: return .blaze
        case .legendary: return .legendary
        }
    }

    public var nextMilestone: Int {
        switch self {
        case .starter: return 7
        case .blaze: return 21
        case .legendary: return 50
        }
    }

    public var bestStreak: Int {
        switch self {
        case .starter: return 7
        case .blaze: return 30
        case .legendary: return 60
        }
    }
}

/// Interactive preset options for RowPattern in the catalog.
public enum CatalogRowPatternPreset: String, CaseIterable, Identifiable, Sendable {
    case standard = "Standard (1-2-1)"
    case wave = "Wave (1-2-3-2-1)"
    case linear = "Linear (1-1-1)"
    case pairs = "Pairs (2-2)"

    public var id: String { rawValue }

    public var pattern: RowPattern {
        switch self {
        case .standard: return .standard
        case .wave: return .wave
        case .linear: return .custom([1])
        case .pairs: return .custom([2])
        }
    }
}

/// Interactive preset options for SerpentineWinding in the catalog.
public enum CatalogWindingPreset: String, CaseIterable, Identifiable, Sendable {
    case standard = "Standard"
    case gentle = "Gentle"
    case linear = "Linear"

    public var id: String { rawValue }

    public var winding: SerpentineWinding {
        switch self {
        case .standard: return .standard
        case .gentle: return .gentle
        case .linear: return .linear
        }
    }
}

/// Interactive preset options for showcasing Voice Match & Pronunciation Assessment.
public enum CatalogVoiceMatchPreset: String, CaseIterable, Identifiable, Sendable {
    case idle = "Idle"
    case listening = "Listening"
    case evaluatedSuccess = "Evaluated (95%)"
    case evaluatedWarning = "Evaluated (60%)"

    public var id: String { rawValue }

    public var originText: String {
        "It was a good job."
    }

    public var subtitle: String {
        "Đó là một công việc tốt."
    }

    public var speechState: CraftSpeechState {
        switch self {
        case .idle:
            return .idle
        case .listening:
            return .listening(audioLevels: [0.15, 0.45, 0.85, 0.6, 0.95, 0.7, 0.35, 0.5])
        case .evaluatedSuccess:
            return .evaluated(overallScore: 95)
        case .evaluatedWarning:
            return .evaluated(overallScore: 60)
        }
    }

    public var actualText: String? {
        switch self {
        case .idle:
            return nil
        case .listening:
            return "It was a"
        case .evaluatedSuccess:
            return "It was a good job"
        case .evaluatedWarning:
            return "It was nice job"
        }
    }
}

public enum CatalogLearningPathMockData {
    public static var defaultSections: [LessonSection] {
        let section1Nodes = [
            LessonNodeModel(
                id: "u1_n1",
                title: "Chào hỏi & Làm quen",
                subtitle: "10 từ mới • 3m",
                iconName: "hand.wave.fill",
                state: .completed,
                kind: .standard,
                xpReward: 15,
                stars: 3
            ),
            LessonNodeModel(
                id: "u1_n2",
                title: "Bảng chữ cái & Phát âm",
                subtitle: "12 ký tự • 4m",
                iconName: "textformat",
                state: .completed,
                kind: .standard,
                xpReward: 20,
                stars: 3
            ),
            LessonNodeModel(
                id: "u1_n3",
                title: "Số đếm & Thời gian",
                subtitle: "15 từ vựng • 5m",
                iconName: "number",
                state: .active,
                kind: .standard,
                progress: 0.6,
                xpReward: 25,
                badgeCount: 2
            ),
            LessonNodeModel(
                id: "u1_n4",
                title: "Từ vựng Đồ ăn & Đồ uống",
                subtitle: "18 từ vựng • 5m",
                iconName: "fork.knife",
                state: .upcoming,
                kind: .standard,
                xpReward: 25
            ),
            LessonNodeModel(
                id: "u1_n5",
                title: "Thử thách Ngữ pháp Checkpoint",
                subtitle: "Bài kiểm tra nhanh",
                iconName: "crown.fill",
                state: .bonus,
                kind: .checkpoint,
                xpReward: 50,
                badgeText: "HOT"
            ),
            LessonNodeModel(
                id: "u1_n6",
                title: "Rương Báu Hoàn Thành Chặng 1",
                subtitle: "Mở khóa phần thưởng",
                iconName: "gift.fill",
                state: .bonus,
                kind: .treasureChest,
                xpReward: 100
            )
        ]

        let section2Nodes = [
            LessonNodeModel(
                id: "u2_n1",
                title: "Hỏi đường & Di chuyển",
                subtitle: "15 từ mới • 5m",
                iconName: "map.fill",
                state: .locked,
                kind: .standard,
                xpReward: 30
            ),
            LessonNodeModel(
                id: "u2_n2",
                title: "Mua sắm & Giá cả",
                subtitle: "20 từ mới • 6m",
                iconName: "cart.fill",
                state: .locked,
                kind: .standard,
                xpReward: 30
            ),
            LessonNodeModel(
                id: "u2_n3",
                title: "Khách sạn & Du lịch",
                subtitle: "18 từ mới • 5m",
                iconName: "bed.double.fill",
                state: .locked,
                kind: .standard,
                xpReward: 35
            ),
            LessonNodeModel(
                id: "u2_n4",
                title: "Rương Báu Hoàn Thành Chặng 2",
                subtitle: "Mở khóa phần thưởng",
                iconName: "gift.fill",
                state: .bonus,
                kind: .treasureChest,
                xpReward: 150
            )
        ]

        return [
            LessonSection(
                id: "sec_1",
                title: "Unit 1: Khởi đầu (Foundations)",
                subtitle: "Nắm vững ngữ âm và các mẫu câu cơ bản",
                level: "BEGINNER • LEVEL 1",
                progressText: "2/6",
                progressValue: 0.5,
                bannerIcon: "sparkles",
                nodes: section1Nodes,
                winding: .standard,
                connectorStyle: .dashed,
                rowPattern: .standard
            ),
            LessonSection(
                id: "sec_2",
                title: "Unit 2: Giao tiếp Hàng ngày (Daily Conversations)",
                subtitle: "Tình huống giao tiếp thực tế và ứng dụng",
                level: "INTERMEDIATE • LEVEL 2",
                progressText: "0/4",
                progressValue: 0.0,
                bannerIcon: "bubble.left.and.bubble.right.fill",
                nodes: section2Nodes,
                winding: .gentle,
                connectorStyle: .solid,
                rowPattern: .wave
            )
        ]
    }

    /// Sample multi-state curriculum sections specifically configured for the Fluid Journey showcase.
    public static var fluidJourneySections: [LessonSection] {
        let deck1Nodes = [
            LessonNodeModel(
                id: "fj_node_active",
                title: "Chào hỏi & Làm quen",
                subtitle: "10 từ mới • 3m",
                iconName: "heart.fill",
                state: .active,
                kind: .standard,
                xpReward: 20
            ),
            LessonNodeModel(
                id: "fj_node_completed",
                title: "Thói quen & Cảm xúc",
                subtitle: "Đã hoàn thành",
                iconName: "flame.fill",
                state: .completed,
                kind: .standard,
                xpReward: 30,
                stars: 3
            ),
            LessonNodeModel(
                id: "fj_node_inprogress",
                title: "Giao tiếp & Ứng xử",
                subtitle: "Đang học dở dang",
                iconName: "bubble.left.fill",
                state: .inProgress,
                kind: .standard,
                progress: 0.65,
                xpReward: 25
            ),
            LessonNodeModel(
                id: "fj_node_locked",
                title: "Từ vựng Công sở",
                subtitle: "Chưa mở khóa",
                iconName: "briefcase.fill",
                state: .locked,
                kind: .standard,
                xpReward: 35
            ),
            LessonNodeModel(
                id: "fj_node_bonus",
                title: "Checkpoint Đấu Boss",
                subtitle: "Thử thách tổng hợp",
                iconName: "crown.fill",
                state: .bonus,
                kind: .checkpoint,
                xpReward: 100
            )
        ]

        let deck2Nodes = [
            LessonNodeModel(
                id: "fj_node_deck2_1",
                title: "Đàm phán & Hợp đồng",
                subtitle: "15 từ mới • 5m",
                iconName: "chart.line.uptrend.xyaxis",
                state: .locked,
                kind: .standard,
                xpReward: 40
            )
        ]

        return [
            LessonSection(
                id: "deck_giao_tiep",
                title: "Giao Tiếp Hằng Ngày",
                subtitle: "A2 · B1 • 5 Bài học",
                level: "A2 · B1",
                progressText: "1/5",
                progressValue: 0.35,
                bannerIcon: "bubble.left.and.bubble.right.fill",
                nodes: deck1Nodes,
                winding: .standard,
                connectorStyle: .dashed,
                rowPattern: .standard
            ),
            LessonSection(
                id: "deck_cong_so",
                title: "Công Sở & Kinh Doanh",
                subtitle: "B1 · B2 • Chuyên ngành",
                level: "B1 · B2",
                progressText: "0/1",
                progressValue: 0.0,
                bannerIcon: "briefcase.fill",
                nodes: deck2Nodes,
                winding: .standard,
                connectorStyle: .dashed,
                rowPattern: .standard
            )
        ]
    }
}

// MARK: - Custom Emerald Theme

/// Custom Emerald & Teal theme demonstrating CraftUIKit's customizable theming engine.
public struct CraftEmeraldTheme: CraftTheme {
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
        colors: CraftColorTokens = CraftEmeraldColorTokens(),
        typography: CraftTypographyTokens = CraftDefaultTypographyTokens(),
        spacing: CraftSpacingTokens = CraftDefaultSpacingTokens(),
        radii: CraftRadiusTokens = CraftDefaultRadiusTokens(),
        shadows: CraftShadowTokens = CraftDefaultShadowTokens(),
        gradients: CraftGradientTokens = CraftEmeraldGradientTokens(),
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

/// Emerald & Teal color tokens.
public struct CraftEmeraldColorTokens: CraftColorTokens {
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

    public init(
        canvasBackground: Color = .craftDynamic(light: Color(hex: 0xF0FDF4), dark: Color(hex: 0x022C22)),
        surfaceCard: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x064E3B).opacity(0.7)),
        surfaceElevated: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x065F46)),
        surfaceSubtle: Color = .craftDynamic(light: Color(hex: 0xDCFCE7), dark: Color(hex: 0x064E3B).opacity(0.4)),
        brandPrimary: Color = Color(hex: 0x10B981),
        brandSecondary: Color = Color(hex: 0x14B8A6),
        accent: Color = Color(hex: 0xF59E0B),
        textPrimary: Color = .craftDynamic(light: Color(hex: 0x064E3B), dark: Color(hex: 0xECFDF5)),
        textSecondary: Color = .craftDynamic(light: Color(hex: 0x047857), dark: Color(hex: 0xA7F3D0)),
        textMuted: Color = .craftDynamic(light: Color(hex: 0x34D399), dark: Color(hex: 0x6EE7B7)),
        textInverse: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x022C22)),
        borderDefault: Color = .craftDynamic(light: Color(hex: 0xA7F3D0), dark: Color(hex: 0x065F46)),
        borderFocus: Color = Color(hex: 0x10B981),
        hairline: Color = .craftDynamic(light: Color(hex: 0xA7F3D0).opacity(0.8), dark: Color(hex: 0x065F46).opacity(0.8)),
        statusSuccess: Color = Color(hex: 0x10B981),
        statusWarning: Color = Color(hex: 0xF59E0B),
        statusDanger: Color = Color(hex: 0xEF4444),
        statusInfo: Color = Color(hex: 0x06B6D4)
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
    }
}

/// Emerald & Teal gradient tokens.
public struct CraftEmeraldGradientTokens: CraftGradientTokens {
    public var brandHero: LinearGradient
    public var surfaceGlass: LinearGradient
    public var accentShine: LinearGradient
    public var fadeBottom: LinearGradient

    public init(
        brandHero: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x10B981), Color(hex: 0x14B8A6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        surfaceGlass: LinearGradient = LinearGradient(
            colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        accentShine: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xF59E0B), Color(hex: 0xFCD34D)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        fadeBottom: LinearGradient = LinearGradient(
            colors: [Color.clear, Color.black.opacity(0.4)],
            startPoint: .top,
            endPoint: .bottom
        )
    ) {
        self.brandHero = brandHero
        self.surfaceGlass = surfaceGlass
        self.accentShine = accentShine
        self.fadeBottom = fadeBottom
    }
}

// MARK: - Root CraftCatalogView

/// An interactive design system gallery and component showcase view for CraftUIKit.
public struct CraftCatalogView: View {
    @State private var selectedThemeType: CatalogThemeType = .defaultSlate
    @State private var selectedColorScheme: CatalogColorScheme = .system
    @State private var selectedSurfaceStyle: CraftSurfaceStyle = .elevated
    @State private var selectedLanguage: CatalogLanguage = .english

    public init() {}

    public var body: some View {
        CraftCatalogContentView(
            selectedThemeType: $selectedThemeType,
            selectedColorScheme: $selectedColorScheme,
            selectedSurfaceStyle: $selectedSurfaceStyle,
            selectedLanguage: $selectedLanguage
        )
        .craftTheme(selectedThemeType.theme)
        .craftSurfaceStyle(selectedSurfaceStyle)
        .preferredColorScheme(selectedColorScheme.colorScheme)
        .environment(\.locale, Locale(identifier: selectedLanguage.code))
    }
}

// MARK: - Catalog Content View

private struct CraftCatalogContentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.craftTheme) private var theme

    @Binding var selectedThemeType: CatalogThemeType
    @Binding var selectedColorScheme: CatalogColorScheme
    @Binding var selectedSurfaceStyle: CraftSurfaceStyle
    @Binding var selectedLanguage: CatalogLanguage

    // Interactive States
    @State private var isButtonLoading: Bool = false
    @State private var iconButtonCounter: Int = 0
    @State private var customPressCount: Int = 0
    @State private var isShimmerActive: Bool = true
    @State private var selectedPills: Set<String> = ["Vocabulary", "Grammar"]
    @State private var searchQuery: String = ""
    @State private var textInput: String = "Design System"
    @State private var passwordInput: String = "SecretPass123"
    @State private var errorInput: String = "Invalid Email"
    @State private var toggleNotifications: Bool = true
    @State private var toggleHaptics: Bool = true
    @State private var stepperValue: Int = 12
    @State private var progressValue: Double = 0.65

    // Overlays
    @State private var isToastPresented: Bool = false
    @State private var toastTitle: String = "Craft Toast Notification"
    @State private var toastMessage: String = "Action completed successfully!"
    @State private var toastStyle: CraftToastStyle = .success
    @State private var toastSurfaceStyle: CraftSurfaceStyle = .elevated
    @State private var toastPosition: CraftToastPosition = .top
    @State private var isBottomSheetPresented: Bool = false
    @State private var isConfirmDialogPresented: Bool = false
    @State private var isDangerDialogPresented: Bool = false
    @State private var isGlassDialogPresented: Bool = false
    @State private var bentoCardTapped: String? = nil

    // Section 8 - Empty State Presets
    @State private var selectedEmptyPreset: CatalogEmptyStatePreset = .study

    // CraftFeedbackSheet Preset & Presentation States
    @State private var selectedFeedbackPreset: CatalogFeedbackPreset = .success
    @State private var isFeedbackSheetPresented: Bool = false

    // Section 10 - Metrics & Progression
    @State private var masteredCount: Double = 45
    @State private var reviewingCount: Double = 30
    @State private var learningCount: Double = 25
    @State private var selectedRoadmapStep: Int = 2

    // Section 11 - 3D Flip Card & Multiple Choice Quiz
    @State private var isCardFlipped: Bool = false
    @State private var flipAxis: Axis = .horizontal
    @State private var selectedQuizChoice: String? = nil
    @State private var selectedChoicePrefixStyle: CraftChoicePrefixStyle = .circle
    @State private var isQuizSubmitted: Bool = false

    // Section 12 - Navigation TabBar
    @State private var selectedTab: CatalogTabItem = .home
    @State private var showCenterFAB: Bool = true
    @State private var fabTapCount: Int = 0

    // Section 13 - Audio & Motion FX States
    @State private var isWaveformRecording: Bool = false
    @State private var isSparkleTriggered: Bool = false
    @State private var isConfettiTriggered: Bool = false
    @State private var isCountdownPresented: Bool = false
    @State private var waveformLevels: [CGFloat] = [0.1, 0.3, 0.6, 0.9, 0.7, 0.4, 0.8, 0.5, 0.2, 0.6, 0.85, 0.4, 0.7, 0.3, 0.5, 0.2]

    // Universal Activity & Streak Tracker States
    @State private var selectedStreakPreset: CatalogStreakTierPreset = .blaze
    @State private var isStreakCompletedToday: Bool = false
    @State private var isCelebrationSheetPresented: Bool = false
    @State private var streakCardStyle: CraftCardStyle = .tactile3D

    // Universal Journey Path States
    @State private var selectedRowPatternPreset: CatalogRowPatternPreset = .standard
    @State private var selectedWindingPreset: CatalogWindingPreset = .standard
    @State private var showLearningCelebration: Bool = true
    @State private var scrollToActiveNode: Bool = false
    @State private var selectedLearningNodeID: String = "u1_n3"
    @State private var learningSections: [LessonSection] = CatalogLearningPathMockData.defaultSections

    // Section 7 - Voice Match & Pronunciation Assessment States
    @State private var selectedVoicePreset: CatalogVoiceMatchPreset = .idle

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: theme.spacing.lg) {
                        // Section 0: Theme, Appearance, Surface Style & Language Toolbar
                        CatalogThemeHeaderView(
                            selectedThemeType: $selectedThemeType,
                            selectedColorScheme: $selectedColorScheme,
                            selectedSurfaceStyle: $selectedSurfaceStyle,
                            selectedLanguage: $selectedLanguage
                        )

                        // a. Tokens & Theming Section
                        CatalogTokensThemingSection()

                        // b. Atoms Section
                        CatalogAtomsSection(
                            iconButtonCounter: $iconButtonCounter,
                            selectedLanguage: selectedLanguage
                        )

                        // c. Controls Section
                        CatalogControlsSection(
                            isButtonLoading: $isButtonLoading,
                            customPressCount: $customPressCount,
                            searchQuery: $searchQuery,
                            textInput: $textInput,
                            passwordInput: $passwordInput,
                            errorInput: $errorInput,
                            stepperValue: $stepperValue,
                            toggleNotifications: $toggleNotifications,
                            toggleHaptics: $toggleHaptics,
                            selectedPills: $selectedPills,
                            selectedQuizChoice: $selectedQuizChoice,
                            selectedChoicePrefixStyle: $selectedChoicePrefixStyle,
                            isQuizSubmitted: $isQuizSubmitted,
                            onSubmitQuiz: submitQuiz,
                            onResetQuiz: resetQuiz
                        )
                        .id("buttons")

                        // d. Containers & Overlays Section
                        CatalogContainersOverlaysSection(
                            bentoCardTapped: $bentoCardTapped,
                            isShimmerActive: $isShimmerActive,
                            progressValue: $progressValue,
                            selectedEmptyPreset: $selectedEmptyPreset,
                            masteredCount: $masteredCount,
                            reviewingCount: $reviewingCount,
                            learningCount: $learningCount,
                            selectedRoadmapStep: $selectedRoadmapStep,
                            isCardFlipped: $isCardFlipped,
                            flipAxis: $flipAxis,
                            selectedTab: $selectedTab,
                            showCenterFAB: $showCenterFAB,
                            fabTapCount: $fabTapCount,
                            toastStyle: $toastStyle,
                            toastSurfaceStyle: $toastSurfaceStyle,
                            toastPosition: $toastPosition,
                            isToastPresented: $isToastPresented,
                            isBottomSheetPresented: $isBottomSheetPresented,
                            isConfirmDialogPresented: $isConfirmDialogPresented,
                            isDangerDialogPresented: $isDangerDialogPresented,
                            isGlassDialogPresented: $isGlassDialogPresented,
                            selectedFeedbackPreset: $selectedFeedbackPreset,
                            isFeedbackSheetPresented: $isFeedbackSheetPresented,
                            onEmptyAction: {
                                toastStyle = .info
                                toastSurfaceStyle = .elevated
                                isToastPresented = true
                            },
                            onFabTap: {
                                fabTapCount += 1
                                toastStyle = .success
                                toastSurfaceStyle = .glass
                                isToastPresented = true
                            }
                        )
                        .id("overlays")

                        // e. Universal Journey Path Section
                        CatalogJourneyPathSection(
                            selectedRowPatternPreset: $selectedRowPatternPreset,
                            selectedWindingPreset: $selectedWindingPreset,
                            showCelebration: $showLearningCelebration,
                            scrollToActive: $scrollToActiveNode,
                            sections: $learningSections,
                            selectedNodeID: $selectedLearningNodeID,
                            onNodeSelected: { node in
                                toastStyle = .info
                                toastSurfaceStyle = .elevated
                                isToastPresented = true
                            },
                            onStartLesson: { node in
                                toastStyle = .success
                                toastSurfaceStyle = .glass
                                isConfettiTriggered = true
                                isToastPresented = true
                            },
                            onTriggerCelebration: {
                                isConfettiTriggered = true
                                toastStyle = .success
                                toastSurfaceStyle = .glass
                                isToastPresented = true
                            }
                        )
                        .id("learning_path")

                        // e.1. Fluid Journey (Tactile 3D) Section
                        CatalogFluidJourneySection(
                            toastStyle: $toastStyle,
                            toastSurfaceStyle: $toastSurfaceStyle,
                            isToastPresented: $isToastPresented,
                            toastTitle: $toastTitle,
                            toastMessage: $toastMessage
                        )
                        .id("fluid_journey")

                        // f. Universal Activity & Streak Tracker Section
                        CatalogActivityStreakSection(
                            selectedPreset: $selectedStreakPreset,
                            selectedSurfaceStyle: $selectedSurfaceStyle,
                            isCompletedToday: $isStreakCompletedToday,
                            isCelebrationPresented: $isCelebrationSheetPresented,
                            cardStyle: $streakCardStyle,
                            waveformLevels: $waveformLevels,
                            isWaveformRecording: $isWaveformRecording,
                            isSparkleTriggered: $isSparkleTriggered,
                            isConfettiTriggered: $isConfettiTriggered,
                            isCountdownPresented: $isCountdownPresented,
                            onBadgeTap: {
                                isCelebrationSheetPresented = true
                            },
                            onCardTap: {
                                toastTitle = "Streak Card Tapped"
                                toastMessage = "Card-level tap triggered. Opening streak details modal."
                                toastStyle = .info
                                toastSurfaceStyle = streakCardStyle.surfaceStyle ?? selectedSurfaceStyle
                                isToastPresented = true
                            },
                            onFreezeTap: {
                                toastTitle = "Freeze Shield"
                                toastMessage = "Protected by streak freeze shield token. 🛡️"
                                toastStyle = .info
                                toastSurfaceStyle = streakCardStyle.surfaceStyle ?? selectedSurfaceStyle
                                isToastPresented = true
                            },
                            onDayTap: { day in
                                toastTitle = "Day \(day.weekdaySymbol)"
                                let statusDesc: String
                                switch day.status {
                                case .completed:
                                    statusDesc = "Completed daily goal! 🔥"
                                    toastStyle = .success
                                case .pending:
                                    statusDesc = day.isToday ? "Goal pending for today. Keep going! ⚡️" : "Pending completion."
                                    toastStyle = .warning
                                case .saved:
                                    statusDesc = "Preserved with a freeze shield! 🛡️"
                                    toastStyle = .info
                                case .missed:
                                    statusDesc = "Missed daily goal."
                                    toastStyle = .danger
                                case .upcoming:
                                    statusDesc = "Upcoming day in weekly cycle."
                                    toastStyle = .info
                                }
                                toastMessage = statusDesc
                                toastSurfaceStyle = streakCardStyle.surfaceStyle ?? selectedSurfaceStyle
                                isToastPresented = true
                            }
                        )
                        .id("streak")

                        // g. Voice Match & Pronunciation Assessment Section
                        CatalogVoiceMatchSection(
                            selectedPreset: $selectedVoicePreset,
                            toastStyle: $toastStyle,
                            toastSurfaceStyle: $toastSurfaceStyle,
                            toastTitle: $toastTitle,
                            toastMessage: $toastMessage,
                            isToastPresented: $isToastPresented
                        )
                        .id("voice_match")
                    }
                    .padding(.horizontal, theme.spacing.base)
                    .padding(.vertical, theme.spacing.lg)
                }
                .onAppear {
                    let args = ProcessInfo.processInfo.arguments
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(300))
                        if args.contains("-catalog-scroll-buttons") {
                            withAnimation { scrollProxy.scrollTo("buttons", anchor: .top) }
                        } else if args.contains("-catalog-scroll-streak") {
                            withAnimation { scrollProxy.scrollTo("streak", anchor: .top) }
                        } else if args.contains("-catalog-scroll-path") {
                            withAnimation { scrollProxy.scrollTo("learning_path", anchor: .top) }
                        } else if args.contains("-catalog-scroll-fluid") {
                            withAnimation { scrollProxy.scrollTo("fluid_journey", anchor: .top) }
                        } else if args.contains("-catalog-scroll-feedback") || args.contains("-catalog-scroll-overlays") {
                            withAnimation { scrollProxy.scrollTo("overlays", anchor: .top) }
                        } else if args.contains("-catalog-scroll-voice") {
                            withAnimation { scrollProxy.scrollTo("voice_match", anchor: .top) }
                        }
                    }
                }
            }
            .background(theme.colors.canvasBackground.ignoresSafeArea())
            .navigationTitle(Text(verbatim: "CraftUIKit Gallery"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.colors.canvasBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CraftLocalized.string("craft.common.action.close")) {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $isCelebrationSheetPresented) {
            CraftCelebrationSheet(
                currentValue: selectedStreakPreset.days,
                previousValue: max(0, selectedStreakPreset.days - 1),
                cycleDays: [
                    CraftActivityDay(id: "1", weekdaySymbol: "T2", status: .completed),
                    CraftActivityDay(id: "2", weekdaySymbol: "T3", status: selectedStreakPreset == .starter ? .missed : .completed),
                    CraftActivityDay(id: "3", weekdaySymbol: "T4", status: selectedStreakPreset == .blaze ? .saved : .completed),
                    CraftActivityDay(id: "4", weekdaySymbol: "T5", status: isStreakCompletedToday ? .completed : .pending, isToday: true),
                    CraftActivityDay(id: "5", weekdaySymbol: "T6", status: .upcoming),
                    CraftActivityDay(id: "6", weekdaySymbol: "T7", status: .upcoming),
                    CraftActivityDay(id: "7", weekdaySymbol: "CN", status: .upcoming)
                ],
                surfaceStyle: selectedSurfaceStyle,
                onContinue: {
                    isCelebrationSheetPresented = false
                }
            )
            .presentationDetents([.fraction(0.74), .large])
            .presentationDragIndicator(.visible)
        }
        .craftSparkle(isTriggered: $isSparkleTriggered, particleCount: 25)
        .craftConfetti(isTriggered: $isConfettiTriggered, particleCount: 35)
        .craftCountdown(
            isPresented: $isCountdownPresented,
            startNumber: 3,
            title: "Speed Challenge Countdown",
            goText: "GO!"
        ) {
            toastTitle = "Countdown Complete"
            toastMessage = "Speed challenge started!"
            toastStyle = .success
            toastSurfaceStyle = .glass
            isToastPresented = true
            isConfettiTriggered = true
        }
        .craftToast(
            isPresented: $isToastPresented,
            message: toastMessage,
            title: toastTitle,
            iconName: toastStyle.defaultIconName,
            style: toastStyle,
            surfaceStyle: toastSurfaceStyle,
            duration: 3.0,
            position: toastPosition
        )
        .craftBottomSheet(
            isPresented: $isBottomSheetPresented,
            title: "Modal Bottom Sheet"
        ) {
            VStack(spacing: theme.spacing.base) {
                CraftText(
                    "This is an interactive CraftBottomSheet component. It supports drag dismissal, rounded corners, and customizable detents.",
                    style: .bodyMedium,
                    color: theme.colors.textSecondary
                )

                CraftButton("Dismiss Sheet", variant: .secondary, size: .md) {
                    isBottomSheetPresented = false
                }
            }
        }
        .craftDialog(
            isPresented: $isConfirmDialogPresented,
            title: "Confirm Action",
            message: "Would you like to apply these changes to your CraftUIKit workspace?",
            iconName: "questionmark.circle.fill",
            primaryButtonTitle: CraftLocalized.string("craft.common.action.confirm", language: selectedLanguage.code),
            primaryButtonVariant: .primary,
            primaryAction: {
                toastStyle = .success
                toastSurfaceStyle = .elevated
                isToastPresented = true
            },
            cancelButtonTitle: CraftLocalized.string("craft.common.action.cancel", language: selectedLanguage.code)
        )
        .craftDialog(
            isPresented: $isDangerDialogPresented,
            title: "Delete Resource?",
            message: "This operation is irreversible. All associated data will be permanently purged.",
            iconName: "trash.fill",
            primaryButtonTitle: "Delete",
            primaryButtonVariant: .danger,
            primaryAction: {
                toastStyle = .danger
                toastSurfaceStyle = .elevated
                isToastPresented = true
            },
            cancelButtonTitle: CraftLocalized.string("craft.common.action.cancel", language: selectedLanguage.code)
        )
        .craftDialog(
            isPresented: $isGlassDialogPresented,
            title: "Liquid Glass Dialog",
            message: "Translucent backdrop and frosted material surface with specular reflection.",
            iconName: "sparkles",
            primaryButtonTitle: CraftLocalized.string("craft.common.action.confirm", language: selectedLanguage.code),
            primaryButtonVariant: .primary,
            primaryAction: {
                toastStyle = .success
                toastSurfaceStyle = .glass
                isToastPresented = true
            },
            cancelButtonTitle: CraftLocalized.string("craft.common.action.close", language: selectedLanguage.code),
            style: .glass,
            backdrop: .material
        )
        .craftFeedbackSheet(
            isPresented: $isFeedbackSheetPresented,
            status: selectedFeedbackPreset.status,
            title: selectedFeedbackPreset.title,
            message: selectedFeedbackPreset.message,
            surfaceStyle: selectedFeedbackPreset.surfaceStyle,
            onContinue: {
                isFeedbackSheetPresented = false
            }
        )
    }

    private func submitQuiz() {
        guard selectedQuizChoice != nil else { return }
        isQuizSubmitted = true
        if selectedQuizChoice == "B" {
            isConfettiTriggered = true
            toastStyle = .success
            toastSurfaceStyle = .glass
            isToastPresented = true
        } else {
            toastStyle = .danger
            toastSurfaceStyle = .elevated
            isToastPresented = true
        }
    }

    private func resetQuiz() {
        selectedQuizChoice = nil
        isQuizSubmitted = false
    }
}

// MARK: - Section 0: Theme, Appearance, Surface Style & Language Header

private struct CatalogThemeHeaderView: View {
    @Environment(\.craftTheme) private var theme
    @Binding var selectedThemeType: CatalogThemeType
    @Binding var selectedColorScheme: CatalogColorScheme
    @Binding var selectedSurfaceStyle: CraftSurfaceStyle
    @Binding var selectedLanguage: CatalogLanguage

    var body: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                HStack {
                    CraftIcon("paintbrush.fill", size: .md, color: theme.colors.brandPrimary)
                    CraftText("Theme, Surface Style & Localization", style: .headline, color: theme.colors.textPrimary)
                }

                CraftDivider()

                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    // Theme Picker
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        CraftText("Theme Palette", style: .label, color: theme.colors.textSecondary)
                        Picker(selection: $selectedThemeType, label: Text(verbatim: "Theme")) {
                            ForEach(CatalogThemeType.allCases) { type in
                                Text(verbatim: type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Appearance Scheme Picker
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        CraftText("Color Scheme", style: .label, color: theme.colors.textSecondary)
                        Picker(selection: $selectedColorScheme, label: Text(verbatim: "Appearance")) {
                            ForEach(CatalogColorScheme.allCases) { scheme in
                                Text(verbatim: scheme.rawValue).tag(scheme)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Surface Style Selector Toolbar
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        CraftText("Global Surface Style", style: .label, color: theme.colors.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: theme.spacing.xs) {
                                ForEach(CraftSurfaceStyle.allCases, id: \.self) { style in
                                    Button(action: {
                                        withAnimation(theme.animations.springSmooth) {
                                            selectedSurfaceStyle = style
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            if selectedSurfaceStyle == style {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 11, weight: .bold))
                                            }
                                            Text(style.rawValue.capitalized)
                                                .font(.system(.subheadline, design: .rounded, weight: selectedSurfaceStyle == style ? .bold : .medium))
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedSurfaceStyle == style
                                                ? theme.colors.brandPrimary
                                                : theme.colors.surfaceSubtle
                                        )
                                        .foregroundStyle(
                                            selectedSurfaceStyle == style
                                                ? Color.white
                                                : theme.colors.textPrimary
                                        )
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(
                                                    selectedSurfaceStyle == style
                                                        ? theme.colors.brandPrimary
                                                        : theme.colors.borderDefault,
                                                    lineWidth: 1
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    // Language Selector Toolbar
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        CraftText("Showcase Language", style: .label, color: theme.colors.textSecondary)
                        Picker(selection: $selectedLanguage, label: Text(verbatim: "Language")) {
                            ForEach(CatalogLanguage.allCases) { lang in
                                Text(verbatim: lang.rawValue).tag(lang)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    HStack(spacing: theme.spacing.sm) {
                        CraftBadge("Depth Engine", symbol: .sparkles, variant: .subtle, tone: .primary, size: .sm)
                        CraftText("sm: \(Int(theme.depths.depthSm))pt • md: \(Int(theme.depths.depthMd))pt • lg: \(Int(theme.depths.depthLg))pt", style: .caption, color: theme.colors.textSecondary)
                    }
                    .padding(.top, 2)
                }
            }
        }
    }
}

// MARK: - Section 1: Tokens & Theming Showcase

private struct CatalogTokensThemingSection: View {
    @Environment(\.craftTheme) private var theme

    var body: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                CatalogSectionHeader(title: "1. Tokens & Theming Engine", iconName: "slider.horizontal.3")

                // Color Tokens Swatches
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("Semantic Color Tokens Palette", style: .headline)
                    CraftText("Dynamic light/dark contrast compliant tokens with zero hardcoded values.", style: .caption, color: theme.colors.textMuted)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.xs) {
                        colorSwatch(title: "brandPrimary", color: theme.colors.brandPrimary)
                        colorSwatch(title: "brandSecondary", color: theme.colors.brandSecondary)
                        colorSwatch(title: "accent", color: theme.colors.accent)
                        colorSwatch(title: "surfaceCard", color: theme.colors.surfaceCard)
                        colorSwatch(title: "surfaceElevated", color: theme.colors.surfaceElevated)
                        colorSwatch(title: "surfaceSubtle", color: theme.colors.surfaceSubtle)
                        colorSwatch(title: "textPrimary", color: theme.colors.textPrimary)
                        colorSwatch(title: "textSecondary", color: theme.colors.textSecondary)
                        colorSwatch(title: "borderDefault", color: theme.colors.borderDefault)
                        colorSwatch(title: "borderFocus", color: theme.colors.borderFocus)
                        colorSwatch(title: "statusSuccess", color: theme.colors.statusSuccess)
                        colorSwatch(title: "statusDanger", color: theme.colors.statusDanger)
                    }
                }

                CraftDivider()

                // Depth & Glass Tokens
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("Depth & Liquid Glass Tokens", style: .headline)

                    HStack(spacing: theme.spacing.sm) {
                        VStack(alignment: .leading, spacing: 4) {
                            CraftText("3D Depth Extrusions", style: .label, color: theme.colors.textSecondary)
                            CraftText("• sm: \(Int(theme.depths.depthSm))pt (Day Nodes, Pills)", style: .caption, color: theme.colors.textMuted)
                            CraftText("• md: \(Int(theme.depths.depthMd))pt (Cards, Path Nodes)", style: .caption, color: theme.colors.textMuted)
                            CraftText("• lg: \(Int(theme.depths.depthLg))pt (Hero Buttons)", style: .caption, color: theme.colors.textMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(theme.spacing.sm)
                        .background(theme.colors.surfaceSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radii.sm))

                        VStack(alignment: .leading, spacing: 4) {
                            CraftText("Glass Engine", style: .label, color: theme.colors.textSecondary)
                            CraftText("• Tint Opacity: \(String(format: "%.2f", theme.glass.tintOpacity))", style: .caption, color: theme.colors.textMuted)
                            CraftText("• Material: UltraThin Material", style: .caption, color: theme.colors.textMuted)
                            CraftText("• Specular Gradient Stroke", style: .caption, color: theme.colors.textMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(theme.spacing.sm)
                        .background(theme.colors.surfaceSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radii.sm))
                    }
                }

                CraftDivider()

                // Typography Scales
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("Typography Scales & Specialized Axes", style: .headline)
                    CraftText("Display Hero (72pt Black)", style: .displayHero, color: theme.colors.brandPrimary)
                    CraftText("Display Large (Rounded)", style: .displayLarge)
                    CraftText("Title Large (Rounded)", style: .titleLarge)
                    CraftText("Title Medium (Rounded)", style: .titleMedium)
                    CraftText("Headline Text (Rounded)", style: .headline)
                    CraftText("Body Large Typography Scale", style: .bodyLarge)
                    CraftText("Body Medium standard readability paragraph style.", style: .bodyMedium, color: theme.colors.textSecondary)
                    CraftText("Label Style (Rounded)", style: .label, color: theme.colors.textMuted)
                    CraftText("Caption helper text style", style: .caption, color: theme.colors.textMuted)

                    CraftDivider()
                        .padding(.vertical, 4)

                    CraftText("Domain Specialized Axes", style: .headline)
                    CraftText("Serendipity", style: .displaySerif, color: theme.colors.brandPrimary)
                    CraftText("/ˌser.ənˈdɪp.ə.ti/", style: .phonetic, color: theme.colors.textSecondary)
                    CraftText("Finding valuable or agreeable things not sought for.", style: .bodySerif, color: theme.colors.textPrimary)
                    HStack(spacing: 8) {
                        CraftText("Score: 9,850 XP", style: .metricRounded, color: theme.colors.accent)
                        CraftBadge("Top 1%", symbol: .trophy, variant: .solid, tone: .warning, size: .sm)
                    }
                }

                CraftDivider()

                // SF Symbol Tokens Grid
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    CraftText("CraftSymbol Design Tokens (SF Symbols 5+)", style: .headline)
                    CraftText("Type-safe, curated domain icons with hierarchical rendering", style: .caption, color: theme.colors.textSecondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.sm) {
                        symbolBadge(symbol: .study, label: "Study")
                        symbolBadge(symbol: .practice, label: "Practice")
                        symbolBadge(symbol: .mastery, label: "Mastery")
                        symbolBadge(symbol: .sparkles, label: "Sparkles")
                        symbolBadge(symbol: .streak, label: "Streak")
                        symbolBadge(symbol: .bookmark, label: "Bookmark")
                        symbolBadge(symbol: .trophy, label: "Trophy")
                        symbolBadge(symbol: .lightbulb, label: "Insight")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func colorSwatch(title: String, color: Color) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(theme.colors.borderDefault.opacity(0.5), lineWidth: 0.5)
                )

            Text(title)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .lineLimit(1)
                .foregroundColor(theme.colors.textSecondary)
        }
    }

    @ViewBuilder
    private func symbolBadge(symbol: CraftSymbol, label: String) -> some View {
        VStack(spacing: 4) {
            CraftIcon(symbol, size: .md, color: theme.colors.brandPrimary, renderingMode: .hierarchical, weight: .semibold)
            Text(label)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.spacing.xs)
        .background(theme.colors.surfaceSubtle)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.sm))
    }
}

// MARK: - Section 2: Atoms Showcase

private struct CatalogAtomsSection: View {
    @Environment(\.craftTheme) private var theme
    @Binding var iconButtonCounter: Int
    let selectedLanguage: CatalogLanguage

    private var markdownSample: AttributedString {
        (try? AttributedString(markdown: "Rich **Markdown** with *italics*, ~~strikethrough~~, and `inline code` formatted text.")) ?? AttributedString("Markdown Text")
    }

    var body: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                CatalogSectionHeader(title: "2. Atoms (Text, Badges, IconButtons, Dividers, Spinners)", iconName: "atom")

                // CraftText Atom Showcase
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("CraftText Rich Formats & Tracking", style: .headline)
                    CraftText(markdownSample, style: .bodyMedium, color: theme.colors.textPrimary)

                    CraftText("EXPANDED TRACKING (2.0pt)", style: .label, color: theme.colors.brandPrimary, tracking: 2.0)
                    CraftText("Line-spaced text block with 8pt line spacing for enhanced readability across multi-line educational explanations.", style: .bodyMedium, color: theme.colors.textSecondary, lineSpacing: 8)
                }

                CraftDivider()

                // CraftBadge 5 Surface Styles, Shapes & Tints
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    CraftText("CraftBadge (5 Surface Styles, Shapes & Custom Tints)", style: .headline)

                    // 5 Surface Styles
                    VStack(alignment: .leading, spacing: 6) {
                        CraftText("Surface Styles", style: .caption, color: theme.colors.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: theme.spacing.xs) {
                                CraftBadge("Flat", symbol: .study, style: .flat)
                                CraftBadge("Elevated", symbol: .mastery, tone: .success, style: .elevated)
                                CraftBadge("Outlined", symbol: .bookmark, tone: .warning, style: .outlined)
                                CraftBadge("Tactile 3D", symbol: .streak, tone: .danger, style: .tactile3D)
                                CraftBadge("Glass", symbol: .sparkles, tone: .primary, style: .glass)
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    // Shapes & Custom Tints
                    VStack(alignment: .leading, spacing: 6) {
                        CraftText("Shapes & Custom Tint Overrides", style: .caption, color: theme.colors.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: theme.spacing.xs) {
                                CraftBadge("Capsule", shape: .capsule, customTint: Color.purple)
                                CraftBadge("Rounded (8pt)", shape: .roundedRectangle(radius: 8), customTint: Color.teal)
                                CraftBadge("Pink Solid", variant: .solid, shape: .capsule, customTint: Color.pink)
                                CraftBadge("Small (sm)", size: .sm, customTint: Color.orange)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                CraftDivider()

                // CraftIconButton 5 Surface Styles, Shapes & 44pt Touch Targets
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        CraftText("CraftIconButton (5 Styles, Shapes & States)", style: .headline)
                        Spacer()
                        CraftText("Taps: \(iconButtonCounter)", style: .caption, color: theme.colors.brandPrimary)
                    }

                    // Styles Row
                    HStack(spacing: theme.spacing.sm) {
                        CraftIconButton(symbol: .favoriteFill, size: .md, shape: .circle, style: .glass, accessibilityLabel: "Favorite") {
                            iconButtonCounter += 1
                        }
                        CraftIconButton(symbol: .bookmarkFill, size: .md, shape: .circle, style: .tactile3D, accessibilityLabel: "Bookmark") {
                            iconButtonCounter += 1
                        }
                        CraftIconButton(symbol: .share, size: .md, shape: .square, style: .elevated, accessibilityLabel: "Share") {
                            iconButtonCounter += 1
                        }
                        CraftIconButton(symbol: .deleteFill, size: .md, shape: .roundedRectangle(radius: 8), variant: .danger, accessibilityLabel: "Delete") {
                            iconButtonCounter += 1
                        }
                        CraftIconButton(symbol: .settings, size: .md, shape: .circle, variant: .ghost, accessibilityLabel: "Settings") {
                            iconButtonCounter += 1
                        }
                    }

                    // States Row
                    HStack(spacing: theme.spacing.sm) {
                        CraftIconButton(symbol: .favoriteFill, size: .md, shape: .circle, isSelected: true, accessibilityLabel: "Favorite Active") {
                            iconButtonCounter += 1
                        }
                        CraftIconButton(symbol: .bookmarkFill, size: .md, shape: .circle, isLoading: true, accessibilityLabel: "Loading") {}
                        CraftIconButton(symbol: .audio, size: .md, shape: .square, accessibilityLabel: "Disabled") {
                            iconButtonCounter += 1
                        }
                        .disabled(true)
                    }
                }

                CraftDivider()

                // CraftDivider Styles
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("CraftDivider (Solid, Dashed & Gradient)", style: .headline)

                    VStack(spacing: 8) {
                        HStack {
                            CraftText("Solid Hairline", style: .caption, color: theme.colors.textMuted)
                            Spacer()
                        }
                        CraftDivider(style: .solid)

                        HStack {
                            CraftText("Dashed (6pt dash, 4pt gap)", style: .caption, color: theme.colors.textMuted)
                            Spacer()
                        }
                        CraftDivider(style: .dashed(dash: 6, gap: 4))

                        HStack {
                            CraftText("Brand Hero Gradient", style: .caption, color: theme.colors.textMuted)
                            Spacer()
                        }
                        CraftDivider(style: .gradient(theme.gradients.brandHero))
                    }
                }

                CraftDivider()

                // CraftSpinner Scales
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("CraftSpinner Indicators", style: .headline)
                    HStack(spacing: theme.spacing.lg) {
                        VStack {
                            CraftSpinner(size: .sm, color: theme.colors.brandPrimary)
                            CraftText("sm (14pt)", style: .caption, color: theme.colors.textMuted)
                        }
                        VStack {
                            CraftSpinner(size: .md, color: theme.colors.brandSecondary)
                            CraftText("md (18pt)", style: .caption, color: theme.colors.textMuted)
                        }
                        VStack {
                            CraftSpinner(size: .lg, color: theme.colors.accent)
                            CraftText("lg (24pt)", style: .caption, color: theme.colors.textMuted)
                        }
                        VStack {
                            CraftSpinner(size: .xl, color: theme.colors.statusSuccess)
                            CraftText("xl (32pt)", style: .caption, color: theme.colors.textMuted)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Section 3: Controls Showcase

private struct CatalogControlsSection: View {
    @Environment(\.craftTheme) private var theme
    @Binding var isButtonLoading: Bool
    @Binding var customPressCount: Int
    @Binding var searchQuery: String
    @Binding var textInput: String
    @Binding var passwordInput: String
    @Binding var errorInput: String
    @Binding var stepperValue: Int
    @Binding var toggleNotifications: Bool
    @Binding var toggleHaptics: Bool
    @Binding var selectedPills: Set<String>
    @Binding var selectedQuizChoice: String?
    @Binding var selectedChoicePrefixStyle: CraftChoicePrefixStyle
    @Binding var isQuizSubmitted: Bool
    let onSubmitQuiz: () -> Void
    let onResetQuiz: () -> Void

    @State private var selectedPracticeChoice: String? = "It's a nice day."

    private let filterChips = [
        ("Vocabulary", "character.book.closed.fill", 14),
        ("Grammar", "doc.text.fill", 8),
        ("Listening", "headphones", 22),
        ("Idioms", "quote.bubble.fill", 5)
    ]

    private let practiceOptions = [
        "It's a nice day.",
        "He was a nurse.",
        "It's a stressful job.",
        "It was a good job."
    ]

    var body: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                CatalogSectionHeader(title: "3. Controls (Buttons, Quiz Choice, Inputs, Toggles, Pills)", iconName: "hand.tap.fill")

                // CraftButton 5 Surface Styles & Custom Gradients
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        CraftText("CraftButton (5 Surface Styles & Loading States)", style: .headline)
                        Spacer()
                        CraftSwitch(isOn: $isButtonLoading)
                    }

                    VStack(spacing: theme.spacing.xs) {
                        CraftButton(
                            "TACTILE 3D BUTTON",
                            iconName: "bolt.fill",
                            iconPosition: .trailing,
                            variant: .tactile,
                            size: .lg,
                            isLoading: isButtonLoading,
                            isUppercase: true,
                            tracking: 1.2,
                            isFullWidth: true
                        ) {}

                        HStack(spacing: theme.spacing.xs) {
                            CraftButton("Elevated", variant: .primary, size: .md, isLoading: isButtonLoading, style: .elevated) {}
                                .frame(maxWidth: .infinity)
                            CraftButton("Glass Frosted", variant: .primary, size: .md, isLoading: isButtonLoading, style: .glass) {}
                                .frame(maxWidth: .infinity)
                        }

                        HStack(spacing: theme.spacing.xs) {
                            CraftButton("Outlined", variant: .outline, size: .md, isLoading: isButtonLoading, style: .outlined) {}
                                .frame(maxWidth: .infinity)
                            CraftButton("Flat Subtle", variant: .secondary, size: .md, isLoading: isButtonLoading, style: .flat) {}
                                .frame(maxWidth: .infinity)
                        }

                        CraftButton(
                            "Sunset Accent Gradient",
                            iconName: "sparkles",
                            variant: .primary,
                            size: .md,
                            isLoading: isButtonLoading,
                            customGradient: theme.gradients.accentShine
                        ) {}
                        .frame(maxWidth: .infinity)
                    }
                }

                CraftDivider()

                // CraftChoiceCard 5 Surface Styles & Quiz Simulation
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        CraftText("CraftChoiceCard (5 Styles, Feedback & Zero Hex Colors)", style: .headline)
                        Spacer()
                        if isQuizSubmitted {
                            Button(action: onResetQuiz) {
                                Text(verbatim: "Reset Quiz")
                            }
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.brandPrimary)
                        }
                    }

                    // Interactive Prefix Style Picker
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        CraftText("Prefix Style", style: .label, color: theme.colors.textSecondary)
                        Picker(selection: $selectedChoicePrefixStyle, label: Text(verbatim: "Prefix Style")) {
                            ForEach(CraftChoicePrefixStyle.allCases, id: \.self) { prefixStyle in
                                Text(verbatim: prefixStyleTitle(for: prefixStyle)).tag(prefixStyle)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    CraftText("What is the closest synonym for 'Ephemeral'?", style: .bodyMedium, color: theme.colors.textSecondary)

                    VStack(spacing: theme.spacing.sm) {
                        CraftChoiceCard(prefix: "A", prefixStyle: selectedChoicePrefixStyle, title: "Permanent", subtitle: "Enduring and perpetual across eras", state: choiceState(for: "A"), style: .tactile3D) {
                            selectChoice("A")
                        }
                        CraftChoiceCard(prefix: "B", prefixStyle: selectedChoicePrefixStyle, title: "Transitory", subtitle: "Fleeting and brief in existence", state: choiceState(for: "B"), style: .glass) {
                            selectChoice("B")
                        }
                        CraftChoiceCard(prefix: "C", prefixStyle: selectedChoicePrefixStyle, title: "Immutable", subtitle: "Completely rigid and unchangeable", state: choiceState(for: "C"), style: .elevated) {
                            selectChoice("C")
                        }
                        CraftChoiceCard(prefix: "D", prefixStyle: selectedChoicePrefixStyle, title: "Dormant", subtitle: "Temporarily inactive or asleep", state: choiceState(for: "D"), style: .outlined) {
                            selectChoice("D")
                        }
                        CraftChoiceCard(prefix: "E", prefixStyle: selectedChoicePrefixStyle, title: "Perennial", subtitle: "Continually recurring across seasons", state: choiceState(for: "E"), style: .flat) {
                            selectChoice("E")
                        }
                    }

                    if !isQuizSubmitted {
                        CraftButton("Submit Answer", iconName: "checkmark.circle.fill", variant: .tactile, size: .md, action: onSubmitQuiz)
                            .frame(maxWidth: .infinity)
                            .disabled(selectedQuizChoice == nil)
                            .padding(.top, theme.spacing.xs)
                    }
                }

                CraftDivider()

                // Minimalist Centered Practice Option Cards (Video / Listening Quiz)
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("CraftChoiceCard (Centered Practice & Video Quiz)", style: .headline)
                    CraftText("Select what you heard in the clip:", style: .bodyMedium, color: theme.colors.textSecondary)

                    VStack(spacing: theme.spacing.sm) {
                        ForEach(practiceOptions, id: \.self) { option in
                            CraftChoiceCard(
                                prefix: nil,
                                prefixStyle: .none,
                                title: option,
                                textAlignment: .center,
                                state: selectedPracticeChoice == option ? .selected : .idle,
                                style: .tactile3D,
                                showsStatusIndicator: false
                            ) {
                                selectedPracticeChoice = option
                            }
                        }
                    }
                }

                CraftDivider()

                // CraftTextField & CraftSearchBar
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("CraftTextField (Standard, Recessed, Underlined, Glass)", style: .headline)

                    CraftTextField(placeholder: "Standard with leading icon", text: $textInput, label: "Standard Field", leadingIcon: "folder.fill", style: .standard)
                    CraftTextField(placeholder: "Recessed field style", text: $textInput, label: "Recessed Field", leadingIcon: "pencil", style: .recessed)
                    CraftTextField(placeholder: "Underlined minimal field", text: $textInput, label: "Underlined Field", leadingIcon: "character.cursor.ibeam", style: .underlined)
                    CraftTextField(placeholder: "Liquid glass input field", text: $textInput, label: "Glass Field", leadingIcon: "sparkles", style: .glass)
                    CraftTextField(placeholder: "Enter password", text: $passwordInput, label: "Secure Input", leadingIcon: "lock.fill", isSecure: true)
                    CraftTextField(placeholder: "Enter email", text: $errorInput, label: "Error State", errorMessage: errorInput.contains("@") ? nil : "Invalid email address format", leadingIcon: "envelope.fill")

                    CraftDivider()

                    CraftText("CraftSearchBar (7 Styles, 3 Sizes, Haptics & Micro-Interactions)", style: .headline)

                    CraftSearchBar(
                        text: $searchQuery,
                        placeholder: "Search in .flat style (md)...",
                        size: .md,
                        style: .flat,
                        shape: .capsule,
                        onCancel: { searchQuery = "" }
                    )

                    CraftSearchBar(
                        text: $searchQuery,
                        placeholder: "Search in .elevated style (lg)...",
                        size: .lg,
                        style: .elevated,
                        shape: .roundedRectangle(radius: 16),
                        trailingIcon: "slider.horizontal.3",
                        trailingAction: {},
                        onCancel: { searchQuery = "" }
                    )

                    CraftSearchBar(
                        text: $searchQuery,
                        placeholder: "Search in .tactile3D style (md)...",
                        size: .md,
                        style: .tactile3D,
                        shape: .roundedRectangle(radius: 14),
                        customTint: theme.colors.brandPrimary,
                        onCancel: { searchQuery = "" }
                    )

                    CraftSearchBar(
                        text: $searchQuery,
                        placeholder: "Search in .glass style (sm)...",
                        size: .sm,
                        style: .glass,
                        shape: .capsule,
                        onCancel: { searchQuery = "" }
                    )
                }

                CraftDivider()

                // CraftPill & CraftStepper & CraftToggle
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("CraftPill (5 Surface Styles Multi-Select)", style: .headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: theme.spacing.xs) {
                            ForEach(filterChips, id: \.0) { chip in
                                let isSelected = selectedPills.contains(chip.0)
                                CraftPill(chip.0, iconName: chip.1, count: chip.2, isSelected: isSelected, style: .glass) {
                                    if isSelected { selectedPills.remove(chip.0) } else { selectedPills.insert(chip.0) }
                                }
                            }
                        }
                    }

                    CraftDivider()

                    CraftStepper(value: $stepperValue, range: 1...50, step: 1, unit: "words/day", label: "Daily Vocabulary Goal")

                    CraftDivider()

                    VStack(spacing: theme.spacing.xs) {
                        CraftToggle(isOn: $toggleNotifications, title: "Push Notifications", subtitle: "Receive daily review reminders and streak alerts", iconName: "bell.badge.fill")
                        CraftToggle(isOn: $toggleHaptics, title: "Haptic Feedback", subtitle: "Provide tactile responses for card swipes and taps", iconName: "waveform")
                    }
                }
            }
        }
    }

    private func prefixStyleTitle(for style: CraftChoicePrefixStyle) -> String {
        switch style {
        case .circle: return "Circle"
        case .roundedSquare: return "Rounded"
        case .minimal: return "Minimal"
        case .none: return "None"
        }
    }

    private func selectChoice(_ choice: String) {
        guard !isQuizSubmitted else { return }
        selectedQuizChoice = choice
    }

    private func choiceState(for choice: String) -> CraftChoiceState {
        if !isQuizSubmitted {
            return selectedQuizChoice == choice ? .selected : .idle
        }
        if choice == "B" {
            return .correct
        } else if selectedQuizChoice == choice {
            return .wrong
        } else {
            return .disabled
        }
    }
}

// MARK: - Section 4: Containers & Overlays Showcase

private struct CatalogContainersOverlaysSection: View {
    @Environment(\.craftTheme) private var theme
    @State private var actionCardSurfaceStyle: CraftSurfaceStyle = .tactile3D
    @Binding var bentoCardTapped: String?
    @Binding var isShimmerActive: Bool
    @Binding var progressValue: Double
    @Binding var selectedEmptyPreset: CatalogEmptyStatePreset
    @Binding var masteredCount: Double
    @Binding var reviewingCount: Double
    @Binding var learningCount: Double
    @Binding var selectedRoadmapStep: Int
    @Binding var isCardFlipped: Bool
    @Binding var flipAxis: Axis
    @Binding var selectedTab: CatalogTabItem
    @Binding var showCenterFAB: Bool
    @Binding var fabTapCount: Int
    @Binding var toastStyle: CraftToastStyle
    @Binding var toastSurfaceStyle: CraftSurfaceStyle
    @Binding var toastPosition: CraftToastPosition
    @Binding var isToastPresented: Bool
    @Binding var isBottomSheetPresented: Bool
    @Binding var isConfirmDialogPresented: Bool
    @Binding var isDangerDialogPresented: Bool
    @Binding var isGlassDialogPresented: Bool
    @Binding var selectedFeedbackPreset: CatalogFeedbackPreset
    @Binding var isFeedbackSheetPresented: Bool
    let onEmptyAction: () -> Void
    let onFabTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.base) {
            CatalogSectionHeader(title: "4. Containers & Action Cards (Cards, ActionCards, FlipCard, Rows, Dialogs, Toasts, TabBar, Feedback Sheet)", iconName: "square.stack.3d.up.fill")

            // CraftCard 5 Surface Styles Bento Grid
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                CraftCard(style: .tactile3D, isPressable: true, action: { bentoCardTapped = "Tactile 3D Hero Card" }) {
                    HStack {
                        VStack(alignment: .leading, spacing: theme.spacing.xs) {
                            CraftBadge("Tactile 3D", symbol: .sparkles, variant: .solid, tone: .primary)
                            CraftText("Physical Tactile 3D Container", style: .headline)
                            CraftText("Extruded bevel, top specular highlight, and interactive mechanical press.", style: .caption, color: theme.colors.textSecondary)
                        }
                        Spacer()
                        CraftIcon(.sparkles, size: .xl, color: theme.colors.brandPrimary)
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.sm) {
                    CraftCard(style: .glass, isPressable: true, action: { bentoCardTapped = "Frosted Glass Card" }) {
                        VStack(alignment: .leading, spacing: 4) {
                            CraftBadge("Glass Frosted", tone: .primary, style: .glass)
                            CraftText("Frosted Glass", style: .headline)
                            CraftText("Material blur & refraction", style: .caption, color: theme.colors.textSecondary)
                        }
                    }

                    CraftCard(style: .elevated, isPressable: true, action: { bentoCardTapped = "Elevated Card" }) {
                        VStack(alignment: .leading, spacing: 4) {
                            CraftBadge("Elevated", tone: .success)
                            CraftText("Elevated Shadow", style: .headline)
                            CraftText("Layered depth shadow", style: .caption, color: theme.colors.textSecondary)
                        }
                    }

                    CraftCard(style: .outlined, isPressable: true, action: { bentoCardTapped = "Outlined Card" }) {
                        VStack(alignment: .leading, spacing: 4) {
                            CraftBadge("Outlined", tone: .warning)
                            CraftText("Border Outlined", style: .headline)
                            CraftText("Crisp stroke boundary", style: .caption, color: theme.colors.textSecondary)
                        }
                    }

                    CraftCard(style: .flat, isPressable: true, action: { bentoCardTapped = "Flat Card" }) {
                        VStack(alignment: .leading, spacing: 4) {
                            CraftBadge("Flat", tone: .neutral)
                            CraftText("Flat Subtle", style: .headline)
                            CraftText("Subtle surface fill", style: .caption, color: theme.colors.textSecondary)
                        }
                    }
                }

                if let bentoCardTapped {
                    CraftText("Last Pressed: \(bentoCardTapped)", style: .caption, color: theme.colors.brandPrimary)
                }
            }

            // CraftActionCard 5 Surface Styles & Multi-Modality Bento Grid
            CraftCard(style: .elevated) {
                VStack(alignment: .leading, spacing: theme.spacing.base) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            CraftText("CraftActionCard (Bento Action Cards & Mode Launchers)", style: .headline)
                            Spacer()
                            CraftBadge("5 Surface Styles", symbol: .sparkles, variant: .subtle, tone: .primary, size: .sm)
                        }
                        CraftText("Interactive Bento action cards designed for practice drills and learning modes with 3D mechanical press depression, Liquid Glass, badges, and custom accents.", style: .caption, color: theme.colors.textSecondary)
                    }

                    // Interactive Surface Style Switcher for Action Cards
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        CraftText("Action Card Surface Style", style: .label, color: theme.colors.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: theme.spacing.xs) {
                                ForEach(CraftSurfaceStyle.allCases, id: \.self) { style in
                                    Button(action: {
                                        withAnimation(theme.animations.springSmooth) {
                                            actionCardSurfaceStyle = style
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            if actionCardSurfaceStyle == style {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 11, weight: .bold))
                                            }
                                            Text(style.rawValue.capitalized)
                                                .font(.system(.subheadline, design: .rounded, weight: actionCardSurfaceStyle == style ? .bold : .medium))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            actionCardSurfaceStyle == style
                                                ? theme.colors.brandPrimary
                                                : theme.colors.surfaceSubtle
                                        )
                                        .foregroundStyle(
                                            actionCardSurfaceStyle == style
                                                ? Color.white
                                                : theme.colors.textPrimary
                                        )
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(
                                                    actionCardSurfaceStyle == style
                                                        ? theme.colors.brandPrimary
                                                        : theme.colors.borderDefault,
                                                    lineWidth: 1
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    // 4 Modality Cards 2x2 Bento Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.sm) {
                        CraftActionCard(
                            title: "Luyện phát âm",
                            subtitle: "AI Speech Recognition & Voice Feedback",
                            symbol: .mic,
                            badgeText: "AI EVAL",
                            badgeIcon: "sparkles",
                            accentColor: Color(hex: 0x06B6D4),
                            style: actionCardSurfaceStyle
                        ) {
                            bentoCardTapped = "Speaking Mode Action Card"
                        }

                        CraftActionCard(
                            title: "Luyện phản xạ gõ",
                            subtitle: "Timed typing drill & instant validation",
                            symbol: .practice,
                            badgeText: "6.0s",
                            badgeIcon: "stopwatch.fill",
                            accentColor: Color(hex: 0xF59E0B),
                            style: actionCardSurfaceStyle
                        ) {
                            bentoCardTapped = "Typing Speed Drill Action Card"
                        }

                        CraftActionCard(
                            title: "Trắc nghiệm nhanh",
                            subtitle: "SRS 4-option contextual definition drill",
                            symbol: .list,
                            badgeText: "SRS x2",
                            badgeIcon: "bolt.fill",
                            accentColor: Color(hex: 0x8B5CF6),
                            style: actionCardSurfaceStyle
                        ) {
                            bentoCardTapped = "Multiple Choice Action Card"
                        }

                        CraftActionCard(
                            title: "Luyện nghe bắt từ",
                            subtitle: "Native speaker phonetics & audio dictation",
                            symbol: .audio,
                            badgeText: "NATIVE",
                            badgeIcon: "speaker.wave.3.fill",
                            accentColor: Color(hex: 0x10B981),
                            style: actionCardSurfaceStyle
                        ) {
                            bentoCardTapped = "Listening Audio Action Card"
                        }
                    }

                    // Full-width Hero Action Card
                    CraftActionCard(
                        title: "Thử thách Đố vui Hàng ngày",
                        subtitle: "Hoàn thành 20 câu hỏi phản xạ trong 2 phút để nhận token đóng băng chuỗi.",
                        symbol: .streak,
                        badgeText: "EXP x3",
                        badgeIcon: "flame.fill",
                        accentColor: Color(hex: 0xEC4899),
                        style: actionCardSurfaceStyle
                    ) {
                        bentoCardTapped = "Daily Surge Challenge Hero Card"
                    }
                }
            }

            // CraftFlipCard 3D Double Sided
            CraftCard(style: .elevated) {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    CraftText("CraftFlipCard (3D Double-Sided with Specular Glare)", style: .headline)

                    HStack {
                        CraftText("Rotation Axis", style: .caption, color: theme.colors.textSecondary)
                        Spacer()
                        Picker(selection: $flipAxis, label: Text(verbatim: "Axis")) {
                            Text(verbatim: "Horizontal").tag(Axis.horizontal)
                            Text(verbatim: "Vertical").tag(Axis.vertical)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 170)
                    }

                    CraftFlipCard(
                        isFlipped: $isCardFlipped,
                        axis: flipAxis,
                        edgeThickness: 3,
                        showSpecularGlare: true,
                        isTapToFlipEnabled: true
                    ) {
                        CraftCard(style: .outlined) {
                            VStack(spacing: theme.spacing.sm) {
                                HStack {
                                    CraftBadge("Vocabulary Card", symbol: .study, variant: .subtle, tone: .primary)
                                    Spacer()
                                    CraftIcon(.audio, size: .sm, color: theme.colors.brandPrimary)
                                }
                                Spacer()
                                CraftText("Ephemeral", style: .displaySerif, color: theme.colors.textPrimary)
                                CraftText("/ɪˈfem.ər.əl/", style: .phonetic, color: theme.colors.textSecondary)
                                Spacer()
                                HStack(spacing: 4) {
                                    CraftIcon(.flip, size: .sm, color: theme.colors.textSecondary)
                                    CraftText("Tap to reveal definition (3D Flip)", style: .caption, color: theme.colors.textSecondary)
                                }
                            }
                            .frame(height: 140)
                            .frame(maxWidth: .infinity)
                        }
                    } back: {
                        CraftCard(style: .gradient) {
                            VStack(spacing: theme.spacing.sm) {
                                HStack {
                                    CraftBadge("Definition", symbol: .sparkles, variant: .solid, tone: .neutral)
                                    Spacer()
                                    CraftIcon(.sparkles, size: .sm, color: .white)
                                }
                                Spacer()
                                CraftText("Lasting for a very short time; transitory; fleeting.", style: .headline, color: .white)
                                    .multilineTextAlignment(.center)
                                Spacer()
                                HStack(spacing: 4) {
                                    CraftIcon(.flip, size: .sm, color: .white.opacity(0.8))
                                    CraftText("Tap to flip back", style: .caption, color: .white.opacity(0.8))
                                }
                            }
                            .frame(height: 140)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }

            // CraftListRow & CraftEmptyState
            CraftCard(style: .elevated) {
                VStack(alignment: .leading, spacing: theme.spacing.base) {
                    CraftText("CraftListRow Components", style: .headline)
                    VStack(spacing: 0) {
                        CraftListRow(title: "Mastered Words", subtitle: "142 vocabulary items fully retained", iconName: "checkmark.seal.fill", iconColor: theme.colors.statusSuccess, showChevron: true) {
                            CraftBadge("Level 4", symbol: .mastery, tone: .success)
                        }
                        CraftDivider()
                        CraftListRow(title: "Spaced Repetition Deck", subtitle: "18 cards scheduled for review today", iconName: "clock.arrow.circlepath", iconColor: theme.colors.brandPrimary, showChevron: true) {
                            CraftBadge("18 due", symbol: .sparkles, variant: .solid, tone: .primary)
                        }
                    }
                    .background(theme.colors.surfaceCard)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))

                    CraftDivider()

                    CraftText("CraftEmptyState (Layered Squircle Illustrations)", style: .headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: theme.spacing.xs) {
                            ForEach(CatalogEmptyStatePreset.allCases) { preset in
                                Button(action: {
                                    withAnimation(theme.animations.springSmooth) {
                                        selectedEmptyPreset = preset
                                    }
                                }) {
                                    Text(preset.rawValue)
                                        .font(.system(.caption, design: .rounded, weight: selectedEmptyPreset == preset ? .bold : .medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedEmptyPreset == preset ? theme.colors.brandPrimary : theme.colors.surfaceSubtle)
                                        .foregroundStyle(selectedEmptyPreset == preset ? Color.white : theme.colors.textPrimary)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(
                                                    selectedEmptyPreset == preset ? theme.colors.brandPrimary : theme.colors.borderDefault,
                                                    lineWidth: 1
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    CraftCard(style: .outlined) {
                        CraftEmptyState(symbol: selectedEmptyPreset.symbol, title: selectedEmptyPreset.title, message: selectedEmptyPreset.message, buttonTitle: selectedEmptyPreset.buttonTitle, buttonSymbol: selectedEmptyPreset.buttonSymbol, buttonAction: onEmptyAction)
                            .frame(maxWidth: .infinity)
                    }
                }
            }

            // Progress, Rings & Segmented Bar
            CraftCard(style: .elevated) {
                VStack(alignment: .leading, spacing: theme.spacing.base) {
                    CraftText("CraftProgressBar & CraftProgressRing", style: .headline)
                    CraftProgressBar(progress: progressValue, height: 10)
                    CraftProgressBar(currentStep: 3, totalSteps: 5, height: 8)

                    HStack(spacing: theme.spacing.xl) {
                        CraftProgressRing(progress: progressValue, lineWidth: 8, size: 70)
                        CraftProgressRing(progress: 0.85, lineWidth: 8, size: 70, tintColor: theme.colors.statusSuccess) {
                            CraftIcon("flame.fill", size: .sm, color: theme.colors.statusWarning)
                        }
                        CraftProgressRing(progress: 0.45, lineWidth: 8, size: 70, tintColor: theme.colors.statusInfo) {
                            CraftIcon("bolt.fill", size: .sm, color: theme.colors.statusInfo)
                        }
                    }

                    CraftDivider()

                    CraftText("CraftSegmentedBar Distribution", style: .headline)
                    CraftSegmentedBar(
                        items: [
                            CraftSegmentItem(id: "1", label: "Mastered", value: masteredCount, color: theme.colors.statusSuccess),
                            CraftSegmentItem(id: "2", label: "Reviewing", value: reviewingCount, color: theme.colors.brandPrimary),
                            CraftSegmentItem(id: "3", label: "Learning", value: learningCount, color: theme.colors.statusWarning)
                        ],
                        height: 12,
                        cornerRadius: 6,
                        showLegend: true,
                        showPercentages: true
                    )
                }
            }

            // Step Roadmap
            CraftCard(style: .elevated) {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("CraftStepNode (Interactive Roadmap)", style: .headline)
                    VStack(spacing: 0) {
                        CraftStepNode(title: "Foundations & Phonetics", subtitle: "Alphabet and pronunciation rules", state: selectedRoadmapStep > 1 ? .completed : (selectedRoadmapStep == 1 ? .active : .upcoming), stepNumber: 1, onTap: { selectedRoadmapStep = 1 })
                        CraftStepNode(title: "Intermediate Lexicon", subtitle: "Collocations & dialogues", state: selectedRoadmapStep > 2 ? .completed : (selectedRoadmapStep == 2 ? .active : .upcoming), stepNumber: 2, onTap: { selectedRoadmapStep = 2 })
                        CraftStepNode(title: "Advanced Mastery", subtitle: "Idioms & nuance", state: selectedRoadmapStep == 3 ? .active : .locked, stepNumber: 3, isLast: true, onTap: { selectedRoadmapStep = 3 })
                    }
                }
            }

            // Dialogs & Toasts Controls
            CraftCard(style: .elevated) {
                VStack(alignment: .leading, spacing: theme.spacing.base) {
                    CraftText("CraftDialog & CraftToast Overlays", style: .headline)

                    HStack(spacing: theme.spacing.xs) {
                        CraftButton("Info Toast", variant: .outline, size: .sm) {
                            toastStyle = .info
                            toastSurfaceStyle = .elevated
                            isToastPresented = true
                        }
                        CraftButton("Glass Toast", variant: .outline, size: .sm) {
                            toastStyle = .success
                            toastSurfaceStyle = .glass
                            isToastPresented = true
                        }
                        CraftButton("Danger Toast", variant: .outline, size: .sm) {
                            toastStyle = .danger
                            toastSurfaceStyle = .elevated
                            isToastPresented = true
                        }
                    }

                    HStack(spacing: theme.spacing.xs) {
                        CraftButton("Confirm Dialog", variant: .primary, size: .sm) { isConfirmDialogPresented = true }
                            .frame(maxWidth: .infinity)
                        CraftButton("Danger Dialog", variant: .danger, size: .sm) { isDangerDialogPresented = true }
                            .frame(maxWidth: .infinity)
                    }

                    HStack(spacing: theme.spacing.xs) {
                        CraftButton("Glass Modal", variant: .secondary, size: .sm) { isGlassDialogPresented = true }
                            .frame(maxWidth: .infinity)
                        CraftButton("Bottom Sheet", variant: .outline, size: .sm) { isBottomSheetPresented = true }
                            .frame(maxWidth: .infinity)
                    }
                }
            }

            // CraftFeedbackSheet Interactive Showcase
            CraftCard(style: .elevated) {
                VStack(alignment: .leading, spacing: theme.spacing.base) {
                    CraftText("CraftFeedbackSheet (Assessment & Response Feedback)", style: .headline)
                    CraftText("Interactive modal feedback bottom sheet with semantic status styling, tactile action button, sensory haptics, and Liquid Glass surfaces.", style: .caption, color: theme.colors.textSecondary)

                    // Preset Switcher
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        CraftText("Preset State", style: .label, color: theme.colors.textSecondary)
                        Picker(selection: $selectedFeedbackPreset, label: Text(verbatim: "Feedback Preset")) {
                            ForEach(CatalogFeedbackPreset.allCases) { preset in
                                Text(verbatim: preset.rawValue).tag(preset)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Inline Preview of Selected Preset
                    CraftCard(style: selectedFeedbackPreset.surfaceStyle == .glass ? .glass : .outlined) {
                        CraftFeedbackSheet(
                            status: selectedFeedbackPreset.status,
                            title: selectedFeedbackPreset.title,
                            message: selectedFeedbackPreset.message,
                            secondaryActionTitle: selectedFeedbackPreset.secondaryActionTitle,
                            style: selectedFeedbackPreset.surfaceStyle,
                            onSecondaryAction: {
                                toastStyle = .warning
                                toastSurfaceStyle = selectedFeedbackPreset.surfaceStyle ?? .elevated
                                isToastPresented = true
                            },
                            onContinue: {
                                toastStyle = selectedFeedbackPreset.status == .error ? .danger : (selectedFeedbackPreset.status == .warning ? .warning : .success)
                                toastSurfaceStyle = selectedFeedbackPreset.surfaceStyle ?? .elevated
                                isToastPresented = true
                            }
                        ) {
                            if selectedFeedbackPreset == .error {
                                CraftFeedbackHintCard("Hint: Remember the Greek root 'phainomenon'.")
                            }
                        }
                    }

                    // Presentation Trigger Buttons
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        CraftText("Test Docked Sheet Presentation", style: .label, color: theme.colors.textSecondary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.xs) {
                            CraftButton("Success Sheet", iconName: "checkmark.circle.fill", variant: .tactile, size: .sm, customTint: theme.colors.statusSuccess) {
                                selectedFeedbackPreset = .success
                                isFeedbackSheetPresented = true
                            }

                            CraftButton("Error Sheet", iconName: "xmark.circle.fill", variant: .tactile, size: .sm, customTint: theme.colors.statusDanger) {
                                selectedFeedbackPreset = .error
                                isFeedbackSheetPresented = true
                            }

                            CraftButton("Warning Sheet", iconName: "exclamationmark.circle.fill", variant: .tactile, size: .sm, customTint: theme.colors.statusWarning) {
                                selectedFeedbackPreset = .warning
                                isFeedbackSheetPresented = true
                            }

                            CraftButton("Liquid Glass", iconName: "sparkles", variant: .tactile, size: .sm, customTint: theme.colors.brandPrimary) {
                                selectedFeedbackPreset = .glass
                                isFeedbackSheetPresented = true
                            }
                        }
                    }
                }
            }

            // CraftFloatingTabBar
            CraftCard(style: .elevated) {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("CraftFloatingTabBar (Liquid Glass Capsule)", style: .headline)
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: theme.radii.lg)
                            .fill(theme.colors.surfaceSubtle.opacity(0.4))
                            .frame(height: 160)

                        VStack(spacing: 4) {
                            Spacer()
                            CraftIcon(selectedTab.symbol, size: .lg, color: theme.colors.brandPrimary)
                            CraftText("Active: \(selectedTab.title) Screen", style: .headline, color: theme.colors.textPrimary)
                            Spacer()
                        }
                        .padding(.bottom, 60)
                        .frame(height: 160)

                        CraftFloatingTabBar(selectedItem: $selectedTab, items: CatalogTabItem.allCases, style: .glass, centerAction: showCenterFAB ? onFabTap : nil, centerSymbol: CraftSymbol.add.rawValue, centerTitle: "Add")
                            .padding(.bottom, 4)
                    }

                    CraftFloatingTabBar(selectedItem: $selectedTab, items: CatalogTabItem.allCases, style: .glass, presentation: .compact, centerAction: showCenterFAB ? onFabTap : nil, centerSymbol: CraftSymbol.add.rawValue, centerTitle: "Add")
                }
            }
        }
    }
}

// MARK: - Section 5: Universal Journey Path Showcase

private struct CatalogJourneyPathSection: View {
    @Environment(\.craftTheme) private var theme
    @Binding var selectedRowPatternPreset: CatalogRowPatternPreset
    @Binding var selectedWindingPreset: CatalogWindingPreset
    @Binding var showCelebration: Bool
    @Binding var scrollToActive: Bool
    @Binding var sections: [LessonSection]
    @Binding var selectedNodeID: String
    let onNodeSelected: (LessonNodeModel) -> Void
    let onStartLesson: (LessonNodeModel) -> Void
    let onTriggerCelebration: () -> Void

    private let sampleShapes: [CraftNodeShape] = [.circle, .hexagon, .diamond, .squircle, .star]
    private let sampleSurfaceStyles: [CraftSurfaceStyle] = [.tactile3D, .glass, .elevated, .outlined, .flat]

    var body: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                CatalogSectionHeader(title: "5. Universal Journey Path (5 Shapes, 5 Surfaces, Halo Glow, Portal)", iconName: "map.fill")

                // CraftPathNode 5 Shapes x 5 Surface Styles Showcase Matrix
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    CraftText("CraftPathNode Matrix (5 Geometric Shapes & 5 Surface Styles)", style: .headline)
                    CraftText("Showcasing Circle, Hexagon, Diamond, Squircle, and Star shapes paired with tactile3D, glass, elevated, outlined, and flat surfaces.", style: .caption, color: theme.colors.textSecondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: theme.spacing.md) {
                            ForEach(0..<sampleShapes.count, id: \.self) { idx in
                                let shape = sampleShapes[idx]
                                let style = sampleSurfaceStyles[idx]
                                let model = CraftPathNodeModel(
                                    id: "matrix_node_\(idx)",
                                    title: "\(shape.rawValue.capitalized)",
                                    subtitle: "\(style.rawValue)",
                                    state: idx == 1 ? .active : (idx == 0 ? .completed : (idx == 4 ? .bonus : .inProgress)),
                                    shape: shape,
                                    surfaceStyle: style,
                                    icon: .system(idx == 4 ? "star.fill" : "book.fill"),
                                    progress: idx == 3 ? 0.65 : nil,
                                    stars: idx == 0 ? 3 : nil
                                )

                                VStack(spacing: 4) {
                                    CraftPathNode(model: model, calloutText: "START")
                                }
                            }
                        }
                        .padding(.vertical, theme.spacing.sm)
                        .padding(.horizontal, theme.spacing.xs)
                    }
                }

                CraftDivider()

                // Section Header Portal View Showcase
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("Section Header Portal (Unit Header)", style: .headline)
                    CraftJourneySectionView(
                        section: CraftJourneySection(
                            id: "portal_preview",
                            title: "Unit 1: Foundations & Phonetics",
                            subtitle: "Master English phonetics and 200 high-frequency core words",
                            levelText: "BEGINNER • LEVEL 1",
                            progressText: "4/8 Complete",
                            progressValue: 0.5,
                            bannerIcon: .system("sparkles"),
                            nodes: [
                                CraftPathNodeModel(id: "p1", title: "Phonetics", state: .completed, shape: .circle, surfaceStyle: .tactile3D, stars: 3),
                                CraftPathNodeModel(id: "p2", title: "Greetings", state: .active, shape: .squircle, surfaceStyle: .tactile3D)
                            ]
                        )
                    )
                }

                CraftDivider()

                // Interactive Learning Path
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("Interactive Multi-Node Path & Snake Connectors", style: .headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: theme.spacing.xs) {
                            ForEach(CatalogRowPatternPreset.allCases) { preset in
                                Button(action: {
                                    withAnimation(theme.animations.springSmooth) {
                                        selectedRowPatternPreset = preset
                                    }
                                }) {
                                    Text(preset.rawValue)
                                        .font(.system(.caption, design: .rounded, weight: selectedRowPatternPreset == preset ? .bold : .medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedRowPatternPreset == preset ? theme.colors.brandPrimary : theme.colors.surfaceSubtle)
                                        .foregroundStyle(selectedRowPatternPreset == preset ? Color.white : theme.colors.textPrimary)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(
                                                    selectedRowPatternPreset == preset ? theme.colors.brandPrimary : theme.colors.borderDefault,
                                                    lineWidth: 1
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    CraftLearningPath(
                        sections: sections,
                        winding: selectedWindingPreset.winding,
                        rowPattern: selectedRowPatternPreset.pattern,
                        onNodeTap: { tapped in
                            selectedNodeID = tapped.id
                            onNodeSelected(tapped)
                        },
                        onStartLesson: onStartLesson,
                        showDetailModal: true,
                        scrollToActive: scrollToActive,
                        showCelebration: showCelebration
                    )
                    .frame(height: 480)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radii.md)
                            .stroke(theme.colors.borderDefault, lineWidth: 1)
                    )
                }
            }
        }
    }
}

// MARK: - Section 5.1: Fluid Journey (Tactile 3D) Showcase

private struct CatalogFluidJourneySection: View {
    @Environment(\.craftTheme) private var theme
    @Binding var toastStyle: CraftToastStyle
    @Binding var toastSurfaceStyle: CraftSurfaceStyle
    @Binding var isToastPresented: Bool
    @Binding var toastTitle: String
    @Binding var toastMessage: String

    @State private var fluidSurfaceStyle: CraftSurfaceStyle = .tactile3D
    @State private var selectedNodeTitle: String = "Chào hỏi & Làm quen"

    private let sampleSurfaceStyles: [CraftSurfaceStyle] = [.tactile3D, .elevated, .glass, .outlined, .flat]

    var body: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                CatalogSectionHeader(
                    title: "5.1. Fluid Journey (Tactile 3D & Ethereal Path)",
                    iconName: "point.topleft.down.curvedto.point.bottomright.up"
                )

                CraftText(
                    "Features 88pt tactile 3D lesson nodes, centered opening, floating speech bubble callouts, semantic icon preservation with corner checkmark badges, and sticky deck headers.",
                    style: .caption,
                    color: theme.colors.textSecondary
                )

                // Surface Style Switcher
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("Surface Style Switcher", style: .headline)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: theme.spacing.xs) {
                            ForEach(sampleSurfaceStyles, id: \.self) { style in
                                Button {
                                    withAnimation(theme.animations.springSmooth) {
                                        fluidSurfaceStyle = style
                                    }
                                } label: {
                                    Text(style.rawValue.capitalized)
                                        .font(.system(.caption, design: .rounded, weight: fluidSurfaceStyle == style ? .bold : .medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(fluidSurfaceStyle == style ? theme.colors.brandPrimary : theme.colors.surfaceSubtle)
                                        .foregroundStyle(fluidSurfaceStyle == style ? Color.white : theme.colors.textPrimary)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(
                                                    fluidSurfaceStyle == style ? theme.colors.brandPrimary : theme.colors.borderDefault,
                                                    lineWidth: 1
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                // Interactive Journey Container
                CraftFluidJourney(
                    sections: CatalogLearningPathMockData.fluidJourneySections,
                    surfaceStyle: fluidSurfaceStyle,
                    onNodeTap: { node in
                        selectedNodeTitle = node.title
                        toastTitle = "Bài học"
                        toastMessage = node.title
                        toastStyle = .info
                        toastSurfaceStyle = fluidSurfaceStyle
                        isToastPresented = true
                    },
                    onStartLesson: { node in
                        toastTitle = "Bắt đầu học"
                        toastMessage = node.title
                        toastStyle = .success
                        toastSurfaceStyle = fluidSurfaceStyle
                        isToastPresented = true
                    }
                )
                .frame(height: 520)
                .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radii.lg)
                        .stroke(theme.colors.borderDefault, lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Section 6: Universal Activity & Streak Tracker Showcase

private struct CatalogActivityStreakSection: View {
    @Environment(\.craftTheme) private var theme
    @Binding var selectedPreset: CatalogStreakTierPreset
    @Binding var selectedSurfaceStyle: CraftSurfaceStyle
    @Binding var isCompletedToday: Bool
    @Binding var isCelebrationPresented: Bool
    @Binding var cardStyle: CraftCardStyle
    @Binding var waveformLevels: [CGFloat]
    @Binding var isWaveformRecording: Bool
    @Binding var isSparkleTriggered: Bool
    @Binding var isConfettiTriggered: Bool
    @Binding var isCountdownPresented: Bool
    let onBadgeTap: () -> Void
    let onCardTap: () -> Void
    let onFreezeTap: () -> Void
    let onDayTap: (CraftActivityDay) -> Void

    var body: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                CatalogSectionHeader(
                    title: "6. Universal Activity & Streak Tracker (7-Day Bento & Celebration Modal)",
                    iconName: CraftSymbol.streak.rawValue
                )

                // Streak Controls: Preset, Card Style, Completed Today
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    // Preset Selector
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        CraftText("Streak Tier Preset", style: .headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: theme.spacing.xs) {
                                ForEach(CatalogStreakTierPreset.allCases) { preset in
                                    Button(action: {
                                        withAnimation(theme.animations.springSmooth) {
                                            selectedPreset = preset
                                        }
                                    }) {
                                        Text(preset.rawValue)
                                            .font(.system(.caption, design: .rounded, weight: selectedPreset == preset ? .bold : .medium))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(selectedPreset == preset ? theme.colors.brandPrimary : theme.colors.surfaceSubtle)
                                            .foregroundStyle(selectedPreset == preset ? Color.white : theme.colors.textPrimary)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .strokeBorder(
                                                        selectedPreset == preset ? theme.colors.brandPrimary : theme.colors.borderDefault,
                                                        lineWidth: 1
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    // Card Style Selector (All 6 Styles)
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        CraftText("Streak Card Style (All 6 Styles)", style: .label, color: theme.colors.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: theme.spacing.xs) {
                                ForEach(CraftCardStyle.allCases, id: \.self) { style in
                                    Button(action: {
                                        withAnimation(theme.animations.springSmooth) {
                                            cardStyle = style
                                            if let surf = style.surfaceStyle {
                                                selectedSurfaceStyle = surf
                                            }
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            if cardStyle == style {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 10, weight: .bold))
                                            }
                                            Text(style.rawValue.capitalized)
                                                .font(.system(.caption, design: .rounded, weight: cardStyle == style ? .bold : .medium))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            cardStyle == style
                                                ? theme.colors.brandPrimary
                                                : theme.colors.surfaceSubtle
                                        )
                                        .foregroundStyle(
                                            cardStyle == style
                                                ? Color.white
                                                : theme.colors.textPrimary
                                        )
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(
                                                    cardStyle == style
                                                        ? theme.colors.brandPrimary
                                                        : theme.colors.borderDefault,
                                                    lineWidth: 1
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    CraftToggle(
                        isOn: $isCompletedToday,
                        title: "Goal Completed Today",
                        subtitle: "Toggles active flame vs. pending breathing pulse node",
                        iconName: "checkmark.circle.fill"
                    )
                }

                CraftDivider()

                // CraftStreakBadge Showcase
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    HStack {
                        CraftText("CraftStreakBadge Indicators", style: .headline)
                        Spacer()
                        CraftText("Tap to celebrate", style: .caption, color: theme.colors.brandPrimary)
                    }

                    // Active Selection (sm & md)
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        CraftText("Active Style (\(selectedSurfaceStyle.rawValue.capitalized))", style: .label, color: theme.colors.textSecondary)
                        HStack(spacing: theme.spacing.lg) {
                            CraftStreakBadge(
                                count: selectedPreset.days,
                                tier: selectedPreset.tier,
                                isCompletedToday: isCompletedToday,
                                size: .sm,
                                style: selectedSurfaceStyle,
                                onTap: onBadgeTap
                            )
                            CraftStreakBadge(
                                count: selectedPreset.days,
                                tier: selectedPreset.tier,
                                isCompletedToday: isCompletedToday,
                                size: .md,
                                style: selectedSurfaceStyle,
                                onTap: onBadgeTap
                            )
                        }
                    }

                    // All Surface Styles Matrix (sm & md)
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        CraftText("All Surface Styles (.sm & .md)", style: .label, color: theme.colors.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: theme.spacing.md) {
                                ForEach(CraftSurfaceStyle.allCases, id: \.self) { style in
                                    VStack(spacing: theme.spacing.xs) {
                                        CraftText(style.rawValue.capitalized, style: .caption, color: theme.colors.textSecondary)
                                        HStack(spacing: theme.spacing.xs) {
                                            CraftStreakBadge(
                                                count: selectedPreset.days,
                                                tier: selectedPreset.tier,
                                                isCompletedToday: isCompletedToday,
                                                size: .sm,
                                                style: style,
                                                onTap: onBadgeTap
                                            )
                                            CraftStreakBadge(
                                                count: selectedPreset.days,
                                                tier: selectedPreset.tier,
                                                isCompletedToday: isCompletedToday,
                                                size: .md,
                                                style: style,
                                                onTap: onBadgeTap
                                            )
                                        }
                                    }
                                    .padding(theme.spacing.xs)
                                    .background(selectedSurfaceStyle == style ? theme.colors.brandPrimary.opacity(0.08) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                CraftDivider()

                // Universal 7-Day Bento Card (CraftStreakCard)
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("CraftStreakCard (7-Day Bento Dashboard Widget)", style: .headline)
                    CraftText("Tap card for details, or tap day nodes/shield. Active Style: .\(cardStyle.rawValue)", style: .caption, color: theme.colors.textSecondary)

                    CraftStreakCard(
                        data: streakData,
                        cardStyle: cardStyle,
                        onTap: onCardTap,
                        onFreezeTap: onFreezeTap,
                        onMilestoneTap: { isCelebrationPresented = true },
                        onDayTap: { streakDay in
                            onDayTap(streakDay.asActivityDay)
                        }
                    )
                }

                CraftDivider()

                // All 6 Surface Styles Comparison Showcase
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("All 6 Surface Styles (Live Comparison)", style: .headline)
                    CraftText("Scroll horizontally to preview each style variant", style: .caption, color: theme.colors.textSecondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: theme.spacing.base) {
                            ForEach(CraftCardStyle.allCases, id: \.self) { style in
                                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                                    HStack {
                                        CraftText(style.rawValue.capitalized, style: .label)
                                        if cardStyle == style {
                                            CraftBadge("Active", variant: .subtle, tone: .primary, size: .sm)
                                        }
                                    }
                                    CraftStreakCard(
                                        data: streakData,
                                        cardStyle: style,
                                        onTap: onCardTap,
                                        onFreezeTap: onFreezeTap,
                                        onMilestoneTap: { isCelebrationPresented = true },
                                        onDayTap: { streakDay in
                                            onDayTap(streakDay.asActivityDay)
                                        }
                                    )
                                    .frame(width: 320)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                CraftDivider()

                // Celebration Sheet Modal Trigger
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("CraftCelebrationSheet Modal Trigger", style: .headline)
                    CraftButton(
                        "Launch Celebration Modal (\(selectedPreset.days) Days - \(selectedSurfaceStyle.rawValue.capitalized))",
                        iconName: "party.popper.fill",
                        variant: .tactile,
                        size: .md,
                        isFullWidth: true
                    ) {
                        isCelebrationPresented = true
                    }
                }

                CraftDivider()

                // Audio Visualizer & Motion FX
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        CraftText("CraftWaveformView & Celebration FX", style: .headline)
                        Spacer()
                        CraftSwitch(isOn: $isWaveformRecording)
                    }

                    HStack {
                        CraftWaveformView(audioLevels: waveformLevels, barCount: 16, isRecording: isWaveformRecording)
                        Spacer()
                        CraftButton("Randomize", iconName: "dice.fill", variant: .outline, size: .sm) {
                            waveformLevels = (0..<16).map { _ in CGFloat.random(in: 0.05...1.0) }
                        }
                    }

                    HStack(spacing: theme.spacing.sm) {
                        CraftButton("Sparkles", iconName: "sparkles", variant: .primary, size: .sm) { isSparkleTriggered = true }
                            .frame(maxWidth: .infinity)
                        CraftButton("Confetti", iconName: "party.popper.fill", variant: .secondary, size: .sm) { isConfettiTriggered = true }
                            .frame(maxWidth: .infinity)
                        CraftButton("3-2-1 Countdown", iconName: "timer", variant: .outline, size: .sm) { isCountdownPresented = true }
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private var streakData: CraftStreakData {
        CraftStreakData(
            currentStreak: selectedPreset.days,
            bestStreak: selectedPreset.bestStreak,
            freezeTokens: 2,
            maxFreezeTokens: 3,
            nextMilestoneDays: selectedPreset.nextMilestone,
            isCompletedToday: isCompletedToday,
            weekDays: sampleStreakDays
        )
    }

    private var sampleStreakDays: [CraftStreakDay] {
        [
            CraftStreakDay(id: "1", weekdaySymbol: "T2", status: .completed),
            CraftStreakDay(id: "2", weekdaySymbol: "T3", status: selectedPreset == .starter ? .missed : .completed),
            CraftStreakDay(id: "3", weekdaySymbol: "T4", status: selectedPreset == .blaze ? .frozen : .completed),
            CraftStreakDay(id: "4", weekdaySymbol: "T5", status: isCompletedToday ? .completed : .pending, isToday: true),
            CraftStreakDay(id: "5", weekdaySymbol: "T6", status: .upcoming),
            CraftStreakDay(id: "6", weekdaySymbol: "T7", status: .upcoming),
            CraftStreakDay(id: "7", weekdaySymbol: "CN", status: .upcoming)
        ]
    }
}

// MARK: - Section 7: Voice Match & Pronunciation Assessment Showcase

private struct CatalogVoiceMatchSection: View {
    @Environment(\.craftTheme) private var theme
    @Binding var selectedPreset: CatalogVoiceMatchPreset
    @Binding var toastStyle: CraftToastStyle
    @Binding var toastSurfaceStyle: CraftSurfaceStyle
    @Binding var toastTitle: String
    @Binding var toastMessage: String
    @Binding var isToastPresented: Bool

    @State private var interactiveState: CraftSpeechState = .idle
    @State private var interactiveActualText: String? = nil
    @State private var isCustomInteractive: Bool = false

    private var activeSpeechState: CraftSpeechState {
        if isCustomInteractive {
            return interactiveState
        }
        return selectedPreset.speechState
    }

    private var activeActualText: String? {
        if isCustomInteractive {
            return interactiveActualText
        }
        return selectedPreset.actualText
    }

    var body: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                CatalogSectionHeader(
                    title: "7. Voice Match & Speech Evaluation (CraftVoiceMatchCard)",
                    iconName: "waveform.badge.mic"
                )

                // Voice Preset Selector
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("Voice Evaluation State Presets", style: .headline)
                    CraftText("Select a preset or tap the microphone in the live card to cycle states.", style: .caption, color: theme.colors.textSecondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: theme.spacing.xs) {
                            ForEach(CatalogVoiceMatchPreset.allCases) { preset in
                                Button(action: {
                                    withAnimation(theme.animations.springSmooth) {
                                        isCustomInteractive = false
                                        selectedPreset = preset
                                    }
                                }) {
                                    Text(preset.rawValue)
                                        .font(.system(.caption, design: .rounded, weight: (!isCustomInteractive && selectedPreset == preset) ? .bold : .medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background((!isCustomInteractive && selectedPreset == preset) ? theme.colors.brandPrimary : theme.colors.surfaceSubtle)
                                        .foregroundStyle((!isCustomInteractive && selectedPreset == preset) ? Color.white : theme.colors.textPrimary)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(
                                                    (!isCustomInteractive && selectedPreset == preset) ? theme.colors.brandPrimary : theme.colors.borderDefault,
                                                    lineWidth: 1
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                CraftDivider()

                // Live Interactive Voice Match Card
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        CraftText("Interactive Voice Match Card", style: .headline)
                        Spacer()
                        if isCustomInteractive {
                            CraftBadge("Interactive Mode", symbol: .sparkles, variant: .solid, tone: .primary, size: .sm)
                        }
                    }

                    CraftVoiceMatchCard(
                        originText: selectedPreset.originText,
                        actualText: activeActualText,
                        subtitle: selectedPreset.subtitle,
                        speechState: activeSpeechState,
                        onTapMic: {
                            handleMicTap()
                        }
                    )
                }

                CraftDivider()

                // Individual Token Chips State Matrix
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("CraftSpeechWordToken Status Chips", style: .headline)
                    CraftText("Visual feedback tokens with dynamic background and border tints across evaluation states.", style: .caption, color: theme.colors.textSecondary)

                    CraftSpeechWordFlowLayout(spacing: theme.spacing.xs, lineSpacing: theme.spacing.xs) {
                        CraftSpeechWordTokenView(token: CraftSpeechWordToken(targetWord: "matched", status: .matched, confidence: 0.98))
                        CraftSpeechWordTokenView(token: CraftSpeechWordToken(targetWord: "fuzzy", status: .fuzzy, confidence: 0.65))
                        CraftSpeechWordTokenView(token: CraftSpeechWordToken(targetWord: "mismatched", status: .mismatched, confidence: 0.2))
                        CraftSpeechWordTokenView(token: CraftSpeechWordToken(targetWord: "pending", status: .pending))
                    }
                    .padding(.vertical, theme.spacing.xs)
                }

                CraftDivider()

                // Tactile Mic Hub Matrix
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("CraftTactileMicHubView States", style: .headline)
                    CraftText("Idle, listening breathing wave, analyzing spinner, and completed evaluation retry.", style: .caption, color: theme.colors.textSecondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.md) {
                        VStack(spacing: theme.spacing.xs) {
                            CraftTactileMicHubView(speechState: .idle, onTapMic: {})
                            CraftText("Idle", style: .caption, color: theme.colors.textMuted)
                        }

                        VStack(spacing: theme.spacing.xs) {
                            CraftTactileMicHubView(speechState: .listening(audioLevels: [0.3, 0.7, 0.9]), onTapMic: {})
                            CraftText("Listening", style: .caption, color: theme.colors.textMuted)
                        }

                        VStack(spacing: theme.spacing.xs) {
                            CraftTactileMicHubView(speechState: .processing, onTapMic: {})
                            CraftText("Processing", style: .caption, color: theme.colors.textMuted)
                        }

                        VStack(spacing: theme.spacing.xs) {
                            CraftTactileMicHubView(speechState: .evaluated(overallScore: 92), onTapMic: {})
                            CraftText("Retry", style: .caption, color: theme.colors.textMuted)
                        }
                    }
                    .padding(.vertical, theme.spacing.xs)
                }
            }
        }
    }

    private func handleMicTap() {
        withAnimation(theme.animations.springSmooth) {
            let currentState = activeSpeechState
            isCustomInteractive = true
            switch currentState {
            case .idle:
                interactiveState = .listening(audioLevels: [0.2, 0.6, 0.85, 0.5, 0.9, 0.4])
                interactiveActualText = "It was a"
                toastTitle = "Listening Started"
                toastMessage = "Simulated speech recognition active."
                toastStyle = .info
                toastSurfaceStyle = .glass
                isToastPresented = true
            case .listening:
                interactiveState = .evaluated(overallScore: 95)
                interactiveActualText = "It was a good job"
                toastTitle = "Evaluation Complete"
                toastMessage = "Overall Score: 95%"
                toastStyle = .success
                toastSurfaceStyle = .glass
                isToastPresented = true
            case .evaluated:
                // From evaluated (Try again), immediately start listening again in 1 tap!
                interactiveState = .listening(audioLevels: [0.3, 0.7, 0.85, 0.6, 0.9, 0.5])
                interactiveActualText = "It was"
                toastTitle = "Listening Started"
                toastMessage = "Try again speech recognition active."
                toastStyle = .info
                toastSurfaceStyle = .glass
                isToastPresented = true
            case .processing:
                interactiveState = .idle
                interactiveActualText = nil
                toastTitle = "Reset to Idle"
                toastMessage = "Ready for voice input."
                toastStyle = .info
                toastSurfaceStyle = .elevated
                isToastPresented = true
            }
        }
    }
}

// MARK: - Section Header Helper

private struct CatalogSectionHeader: View {
    @Environment(\.craftTheme) private var theme
    let title: String
    let iconName: String

    var body: some View {
        HStack(spacing: theme.spacing.xs) {
            CraftIcon(iconName, size: .md, color: theme.colors.brandPrimary)
            CraftText(title, style: .titleMedium, color: theme.colors.textPrimary)
            Spacer()
        }
    }
}

// MARK: - Xcode Preview

#if canImport(PreviewsMacros)
#Preview("CraftCatalogView - Light") {
    CraftCatalogView()
}
#endif

#if canImport(PreviewsMacros)
#Preview("CraftCatalogView - Dark") {
    CraftCatalogView()
        .preferredColorScheme(.dark)
}
#endif
