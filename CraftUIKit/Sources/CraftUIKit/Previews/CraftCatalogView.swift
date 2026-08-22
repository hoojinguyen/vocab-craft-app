import SwiftUI

// MARK: - Catalog Theme Models

/// Available themes for the CraftUIKit interactive catalog gallery.
public enum CatalogThemeType: String, CaseIterable, Identifiable, Sendable {
    case defaultSlate = "Default Slate"
    case emeraldTeal = "Emerald Teal"

    public var id: String { rawValue }

    public var theme: any CraftTheme {
        switch self {
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

private struct CatalogChipItem: Identifiable {
    var id: String { title }
    let title: String
    let iconName: String
    let count: Int
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

    public init(
        colors: CraftColorTokens = CraftEmeraldColorTokens(),
        typography: CraftTypographyTokens = CraftDefaultTypographyTokens(),
        spacing: CraftSpacingTokens = CraftDefaultSpacingTokens(),
        radii: CraftRadiusTokens = CraftDefaultRadiusTokens(),
        shadows: CraftShadowTokens = CraftDefaultShadowTokens(),
        gradients: CraftGradientTokens = CraftEmeraldGradientTokens(),
        animations: CraftAnimationTokens = CraftDefaultAnimationTokens(),
        opacities: CraftOpacityTokens = CraftDefaultOpacityTokens()
    ) {
        self.colors = colors
        self.typography = typography
        self.spacing = spacing
        self.radii = radii
        self.shadows = shadows
        self.gradients = gradients
        self.animations = animations
        self.opacities = opacities
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

    public init() {}

    public var body: some View {
        CraftCatalogContentView(
            selectedThemeType: $selectedThemeType,
            selectedColorScheme: $selectedColorScheme
        )
        .craftTheme(selectedThemeType.theme)
        .preferredColorScheme(selectedColorScheme.colorScheme)
    }
}

// MARK: - Catalog Content View

private struct CraftCatalogContentView: View {
    @Environment(\.craftTheme) private var theme

    @Binding var selectedThemeType: CatalogThemeType
    @Binding var selectedColorScheme: CatalogColorScheme

    // Phase 1 Interactive States
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
    @State private var toastStyle: CraftToastStyle = .success
    @State private var toastPosition: CraftToastPosition = .top
    @State private var isBottomSheetPresented: Bool = false
    @State private var isConfirmDialogPresented: Bool = false
    @State private var isDangerDialogPresented: Bool = false
    @State private var bentoCardTapped: String? = nil

    // Phase 2: Section 8 - Empty State Presets
    @State private var selectedEmptyPreset: CatalogEmptyStatePreset = .study

    // Phase 2: Section 10 - Metrics & Progression
    @State private var masteredCount: Double = 45
    @State private var reviewingCount: Double = 30
    @State private var learningCount: Double = 25
    @State private var selectedRoadmapStep: Int = 2

    // Phase 2: Section 11 - 3D Flip Card & Multiple Choice Quiz
    @State private var isCardFlipped: Bool = false
    @State private var flipAxis: Axis = .horizontal
    @State private var selectedQuizChoice: String? = nil
    @State private var isQuizSubmitted: Bool = false

    // Phase 2: Section 12 - Navigation TabBar
    @State private var selectedTab: CatalogTabItem = .home
    @State private var showCenterFAB: Bool = true
    @State private var fabTapCount: Int = 0

    // Phase 2: Section 13 - Audio & Motion FX States
    @State private var isWaveformRecording: Bool = false
    @State private var isSparkleTriggered: Bool = false
    @State private var isConfettiTriggered: Bool = false
    @State private var isCountdownPresented: Bool = false
    @State private var waveformLevels: [CGFloat] = [0.1, 0.3, 0.6, 0.9, 0.7, 0.4, 0.8, 0.5, 0.2, 0.6, 0.85, 0.4, 0.7, 0.3, 0.5, 0.2]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    CatalogThemeHeaderView(
                        selectedThemeType: $selectedThemeType,
                        selectedColorScheme: $selectedColorScheme
                    )

                    CatalogTypographySection(iconButtonCounter: $iconButtonCounter)

                    CatalogBadgesPillsSection(selectedPills: $selectedPills)

                    CatalogButtonsSection(
                        isButtonLoading: $isButtonLoading,
                        customPressCount: $customPressCount
                    )

                    CatalogTextFieldsSection(
                        searchQuery: $searchQuery,
                        textInput: $textInput,
                        passwordInput: $passwordInput,
                        errorInput: $errorInput
                    )

                    CatalogStepperTogglesSection(
                        stepperValue: $stepperValue,
                        toggleNotifications: $toggleNotifications,
                        toggleHaptics: $toggleHaptics
                    )

                    CatalogCardsBentoSection(
                        bentoCardTapped: $bentoCardTapped,
                        isShimmerActive: $isShimmerActive
                    )

                    CatalogProgressSection(progressValue: $progressValue)

                    CatalogListRowsEmptySection(
                        selectedPreset: $selectedEmptyPreset,
                        onEmptyAction: {
                            toastStyle = .info
                            isToastPresented = true
                        }
                    )

                    CatalogOverlaysSection(
                        toastStyle: $toastStyle,
                        toastPosition: $toastPosition,
                        isToastPresented: $isToastPresented,
                        isBottomSheetPresented: $isBottomSheetPresented,
                        isConfirmDialogPresented: $isConfirmDialogPresented,
                        isDangerDialogPresented: $isDangerDialogPresented
                    )

                    CatalogMetricsProgressionSection(
                        masteredCount: $masteredCount,
                        reviewingCount: $reviewingCount,
                        learningCount: $learningCount,
                        selectedRoadmapStep: $selectedRoadmapStep
                    )

                    CatalogInteractiveCardsSection(
                        isCardFlipped: $isCardFlipped,
                        flipAxis: $flipAxis,
                        selectedQuizChoice: $selectedQuizChoice,
                        isQuizSubmitted: $isQuizSubmitted,
                        onSubmitQuiz: submitQuiz,
                        onResetQuiz: resetQuiz
                    )

                    CatalogNavigationSection(
                        selectedTab: $selectedTab,
                        showCenterFAB: $showCenterFAB,
                        fabTapCount: $fabTapCount,
                        onFabTap: {
                            fabTapCount += 1
                            toastStyle = .success
                            isToastPresented = true
                        }
                    )

                    CatalogAudioMotionSection(
                        waveformLevels: $waveformLevels,
                        isWaveformRecording: $isWaveformRecording,
                        isSparkleTriggered: $isSparkleTriggered,
                        isConfettiTriggered: $isConfettiTriggered,
                        isCountdownPresented: $isCountdownPresented
                    )
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.vertical, theme.spacing.lg)
            }
            .background(theme.colors.canvasBackground.ignoresSafeArea())
            .navigationTitle("CraftUIKit Gallery")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .craftSparkle(isTriggered: $isSparkleTriggered, particleCount: 25)
        .craftConfetti(isTriggered: $isConfettiTriggered, particleCount: 35)
        .craftCountdown(
            isPresented: $isCountdownPresented,
            startNumber: 3,
            title: "Speed Challenge Countdown",
            goText: "GO!"
        ) {
            toastStyle = .success
            isToastPresented = true
            isConfettiTriggered = true
        }
        .craftToast(
            isPresented: $isToastPresented,
            message: "Action completed successfully!",
            title: "Craft Toast Notification",
            iconName: toastStyle.defaultIconName,
            style: toastStyle,
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
            primaryButtonTitle: "Confirm",
            primaryButtonVariant: .primary,
            primaryAction: {
                toastStyle = .success
                isToastPresented = true
            },
            cancelButtonTitle: "Cancel"
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
                isToastPresented = true
            },
            cancelButtonTitle: "Cancel"
        )
    }

    private func submitQuiz() {
        guard selectedQuizChoice != nil else { return }
        isQuizSubmitted = true
        if selectedQuizChoice == "B" {
            isConfettiTriggered = true
            toastStyle = .success
            isToastPresented = true
        } else {
            toastStyle = .danger
            isToastPresented = true
        }
    }

    private func resetQuiz() {
        selectedQuizChoice = nil
        isQuizSubmitted = false
    }
}

// MARK: - Section 0: Theme Header

private struct CatalogThemeHeaderView: View {
    @Environment(\.craftTheme) private var theme
    @Binding var selectedThemeType: CatalogThemeType
    @Binding var selectedColorScheme: CatalogColorScheme

    var body: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack {
                    CraftIcon("paintbrush.fill", size: .md, color: theme.colors.brandPrimary)
                    CraftText("Design System Theme & Appearance", style: .headline, color: theme.colors.textPrimary)
                }

                CraftDivider()

                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        CraftText("Theme", style: .label, color: theme.colors.textSecondary)
                        Picker("Theme", selection: $selectedThemeType) {
                            ForEach(CatalogThemeType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        CraftText("Color Scheme", style: .label, color: theme.colors.textSecondary)
                        Picker("Appearance", selection: $selectedColorScheme) {
                            ForEach(CatalogColorScheme.allCases) { scheme in
                                Text(scheme.rawValue).tag(scheme)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
        }
    }
}

// MARK: - Section 1: Typography & Icons

private struct CatalogTypographySection: View {
    @Environment(\.craftTheme) private var theme
    @Binding var iconButtonCounter: Int

    var body: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                CatalogSectionHeader(title: "1. Typography & SF Symbol Tokens", iconName: "textformat")

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("Display Large", style: .displayLarge)
                    CraftText("Title Large", style: .titleLarge)
                    CraftText("Title Medium", style: .titleMedium)
                    CraftText("Headline Text", style: .headline)
                    CraftText("Body Large Typography Scale", style: .bodyLarge)
                    CraftText("Body Medium standard readability paragraph style.", style: .bodyMedium, color: theme.colors.textSecondary)
                    CraftText("Label Style", style: .label, color: theme.colors.textMuted)
                    CraftText("Caption helper text style", style: .caption, color: theme.colors.textMuted)

                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        HStack(spacing: 6) {
                            CraftText("Modifier Demo:", style: .caption, color: theme.colors.textMuted)
                            Text(".craftTypography(.titleMedium)")
                                .font(.system(.caption, design: .monospaced, weight: .semibold))
                                .foregroundStyle(theme.colors.brandSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(theme.colors.surfaceSubtle)
                                .clipShape(RoundedRectangle(cornerRadius: theme.radii.xs))
                        }

                        Text("SwiftUI Text Integration Preview")
                            .craftTypography(.titleMedium)
                            .foregroundStyle(theme.colors.brandPrimary)
                    }
                    .padding(.top, theme.spacing.xs)
                }

                CraftDivider()

                // CraftSymbol Token Library Grid
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

                CraftDivider()

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("CraftIcon Scales", style: .headline)
                    HStack(spacing: theme.spacing.lg) {
                        VStack {
                            CraftIcon("star.fill", size: .sm, color: theme.colors.accent)
                            CraftText("sm (14pt)", style: .caption, color: theme.colors.textMuted)
                        }
                        VStack {
                            CraftIcon("star.fill", size: .md, color: theme.colors.accent)
                            CraftText("md (18pt)", style: .caption, color: theme.colors.textMuted)
                        }
                        VStack {
                            CraftIcon("star.fill", size: .lg, color: theme.colors.accent)
                            CraftText("lg (24pt)", style: .caption, color: theme.colors.textMuted)
                        }
                        VStack {
                            CraftIcon("star.fill", size: .xl, color: theme.colors.accent)
                            CraftText("xl (32pt)", style: .caption, color: theme.colors.textMuted)
                        }
                    }
                }

                CraftDivider()

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

                CraftDivider()

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        CraftText("CraftIconButton Variants & Shapes", style: .headline)
                        Spacer()
                        CraftText("Taps: \(iconButtonCounter)", style: .caption, color: theme.colors.brandPrimary)
                    }

                    HStack(spacing: theme.spacing.sm) {
                        CraftIconButton(symbol: .favoriteFill, size: .md, shape: .circle, variant: .filled, accessibilityLabel: "Favorite") {
                            iconButtonCounter += 1
                        }
                        CraftIconButton(symbol: .bookmarkFill, size: .md, shape: .circle, variant: .subtle, accessibilityLabel: "Bookmark") {
                            iconButtonCounter += 1
                        }
                        CraftIconButton(symbol: .share, size: .md, shape: .circle, variant: .outline, accessibilityLabel: "Share") {
                            iconButtonCounter += 1
                        }
                        CraftIconButton(symbol: .deleteFill, size: .md, shape: .square, variant: .ghost, accessibilityLabel: "Delete") {
                            iconButtonCounter += 1
                        }
                    }
                }
            }
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

// MARK: - Section 2: Badges & Chips

private struct CatalogBadgesPillsSection: View {
    @Environment(\.craftTheme) private var theme
    @Binding var selectedPills: Set<String>

    private let filterChips: [CatalogChipItem] = [
        CatalogChipItem(title: "Vocabulary", iconName: "character.book.closed.fill", count: 14),
        CatalogChipItem(title: "Grammar", iconName: "doc.text.fill", count: 8),
        CatalogChipItem(title: "Listening", iconName: "headphones", count: 22),
        CatalogChipItem(title: "Idioms", iconName: "quote.bubble.fill", count: 5),
        CatalogChipItem(title: "Favorites", iconName: "heart.fill", count: 3)
    ]

    var body: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                CatalogSectionHeader(title: "2. Badges & Chips (WCAG AAA Contrast)", iconName: "tag.fill")

                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    HStack {
                        CraftText("CraftBadge Variants & Tones", style: .headline)
                        Spacer()
                        CraftText("WCAG AAA Safe", style: .caption, color: theme.colors.statusSuccess)
                    }

                    CraftText("Solid warning badge automatically uses dynamic dark ink (#18181B) on amber for >9.5:1 contrast.", style: .caption, color: theme.colors.textMuted)

                    // Solid
                    VStack(alignment: .leading, spacing: 4) {
                        CraftText("Solid Variant", style: .caption, color: theme.colors.textSecondary)
                        HStack(spacing: theme.spacing.xs) {
                            CraftBadge("Primary", symbol: .sparkles, variant: .solid, tone: .primary)
                            CraftBadge("Success", symbol: .check, variant: .solid, tone: .success)
                            CraftBadge("Warning", symbol: .warning, variant: .solid, tone: .warning)
                            CraftBadge("Danger", symbol: .danger, variant: .solid, tone: .danger)
                            CraftBadge("Neutral", symbol: .mastery, variant: .solid, tone: .neutral)
                        }
                    }

                    // Subtle
                    VStack(alignment: .leading, spacing: 4) {
                        CraftText("Subtle Variant (1pt Stroke Highlight)", style: .caption, color: theme.colors.textSecondary)
                        HStack(spacing: theme.spacing.xs) {
                            CraftBadge("Primary", symbol: .sparkles, variant: .subtle, tone: .primary)
                            CraftBadge("Success", symbol: .check, variant: .subtle, tone: .success)
                            CraftBadge("Warning", symbol: .warning, variant: .subtle, tone: .warning)
                            CraftBadge("Danger", symbol: .danger, variant: .subtle, tone: .danger)
                            CraftBadge("Neutral", symbol: .mastery, variant: .subtle, tone: .neutral)
                        }
                    }

                    // Outline
                    VStack(alignment: .leading, spacing: 4) {
                        CraftText("Outline Variant", style: .caption, color: theme.colors.textSecondary)
                        HStack(spacing: theme.spacing.xs) {
                            CraftBadge("Primary", symbol: .sparkles, variant: .outline, tone: .primary)
                            CraftBadge("Success", symbol: .check, variant: .outline, tone: .success)
                            CraftBadge("Warning", symbol: .warning, variant: .outline, tone: .warning)
                            CraftBadge("Danger", symbol: .danger, variant: .outline, tone: .danger)
                            CraftBadge("Neutral", symbol: .mastery, variant: .outline, tone: .neutral)
                        }
                    }

                    // Sizes
                    VStack(alignment: .leading, spacing: 4) {
                        CraftText("Size Comparison", style: .caption, color: theme.colors.textSecondary)
                        HStack(spacing: theme.spacing.sm) {
                            CraftBadge("Small (sm)", symbol: .streak, variant: .subtle, tone: .warning, size: .sm)
                            CraftBadge("Medium (md)", symbol: .streak, variant: .subtle, tone: .warning, size: .md)
                        }
                    }
                }

                CraftDivider()

                // Filter Chips / Pills
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("CraftPill / Filter Chips (Interactive Selection)", style: .headline)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: theme.spacing.xs) {
                            ForEach(filterChips) { item in
                                let isSelected = selectedPills.contains(item.title)
                                CraftPill(
                                    item.title,
                                    iconName: item.iconName,
                                    count: item.count,
                                    isSelected: isSelected
                                ) {
                                    if isSelected {
                                        selectedPills.remove(item.title)
                                    } else {
                                        selectedPills.insert(item.title)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Section 3: Buttons

private struct CatalogButtonsSection: View {
    @Environment(\.craftTheme) private var theme
    @Binding var isButtonLoading: Bool
    @Binding var customPressCount: Int

    var body: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                CatalogSectionHeader(title: "3. Buttons", iconName: "hand.tap.fill")

                HStack {
                    CraftText("Variants & Loading State", style: .headline)
                    Spacer()
                    Toggle("Loading State", isOn: $isButtonLoading)
                        .labelsHidden()
                        .toggleStyle(.craft)
                }

                VStack(spacing: theme.spacing.xs) {
                    CraftButton(
                        "Primary Action",
                        iconName: "arrow.right",
                        iconPosition: .trailing,
                        variant: .primary,
                        size: .md,
                        isLoading: isButtonLoading
                    ) {}
                    .frame(maxWidth: .infinity)

                    CraftButton(
                        "Secondary Action",
                        iconName: "slider.horizontal.3",
                        iconPosition: .leading,
                        variant: .secondary,
                        size: .md,
                        isLoading: isButtonLoading
                    ) {}
                    .frame(maxWidth: .infinity)

                    CraftButton(
                        "Outline Action",
                        iconName: "square.and.arrow.down",
                        iconPosition: .leading,
                        variant: .outline,
                        size: .md,
                        isLoading: isButtonLoading
                    ) {}
                    .frame(maxWidth: .infinity)

                    CraftButton(
                        "Ghost Action",
                        iconName: "sparkles",
                        iconPosition: .leading,
                        variant: .ghost,
                        size: .md,
                        isLoading: isButtonLoading
                    ) {}
                    .frame(maxWidth: .infinity)

                    CraftButton(
                        "Danger Action",
                        iconName: "trash.fill",
                        iconPosition: .leading,
                        variant: .danger,
                        size: .md,
                        isLoading: isButtonLoading
                    ) {}
                    .frame(maxWidth: .infinity)
                }

                CraftDivider()

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("Button Sizes (sm, md, lg) & Disabled", style: .headline)
                    HStack(spacing: theme.spacing.sm) {
                        CraftButton("Small (32pt)", variant: .primary, size: .sm) {}
                        CraftButton("Medium (44pt)", variant: .primary, size: .md) {}
                        CraftButton("Disabled", variant: .secondary, size: .md) {}
                            .disabled(true)
                    }
                    CraftButton("Large Button (54pt)", iconName: "star.fill", variant: .primary, size: .lg) {}
                        .frame(maxWidth: .infinity)
                }

                CraftDivider()

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        CraftText("Interactive Press Effects (.craftPress & .craftPressEffect)", style: .headline)
                        Spacer()
                        if customPressCount > 0 {
                            CraftText("Taps: \(customPressCount)", style: .caption, color: theme.colors.brandPrimary)
                        }
                    }

                    HStack(spacing: theme.spacing.sm) {
                        Button {
                            customPressCount += 1
                        } label: {
                            HStack(spacing: theme.spacing.xs) {
                                CraftIcon("hand.tap.fill", size: .sm, color: theme.colors.brandPrimary)
                                CraftText("ButtonStyle .craftPress", style: .label, color: theme.colors.textPrimary)
                            }
                            .padding(.horizontal, theme.spacing.base)
                            .padding(.vertical, theme.spacing.sm)
                            .background(theme.colors.surfaceSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
                        }
                        .buttonStyle(.craftPress())

                        Text("Modifier .craftPressEffect")
                            .font(theme.typography.label)
                            .foregroundStyle(theme.colors.brandSecondary)
                            .padding(.horizontal, theme.spacing.base)
                            .padding(.vertical, theme.spacing.sm)
                            .background(theme.colors.surfaceSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
                            .craftPressEffect(scale: 0.94)
                            .onTapGesture {
                                customPressCount += 1
                            }
                    }
                }
            }
        }
    }
}

// MARK: - Section 4: TextFields & SearchBar

private struct CatalogTextFieldsSection: View {
    @Environment(\.craftTheme) private var theme
    @Binding var searchQuery: String
    @Binding var textInput: String
    @Binding var passwordInput: String
    @Binding var errorInput: String

    var body: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                CatalogSectionHeader(title: "4. TextFields & SearchBar", iconName: "pencil.and.list.clipboard")

                CraftText("CraftSearchBar", style: .headline)
                CraftSearchBar(
                    text: $searchQuery,
                    placeholder: "Search vocabulary, lessons, tags...",
                    onCancel: { searchQuery = "" }
                )

                CraftDivider()

                CraftTextField(
                    placeholder: "e.g. Vocabulary Craft",
                    text: $textInput,
                    label: "Project Title",
                    helperText: "Enter a descriptive name for your study set",
                    leadingIcon: "folder.fill"
                )

                CraftTextField(
                    placeholder: "Enter account password",
                    text: $passwordInput,
                    label: "Password Input (With Visibility Toggle)",
                    leadingIcon: "lock.fill",
                    isSecure: true
                )

                CraftTextField(
                    placeholder: "Enter user email",
                    text: $errorInput,
                    label: "Email (Error Feedback State)",
                    errorMessage: errorInput.contains("@") ? nil : "Please provide a valid email address.",
                    leadingIcon: "envelope.fill"
                )
            }
        }
    }
}

// MARK: - Section 5: Stepper & Toggles

private struct CatalogStepperTogglesSection: View {
    @Environment(\.craftTheme) private var theme
    @Binding var stepperValue: Int
    @Binding var toggleNotifications: Bool
    @Binding var toggleHaptics: Bool

    var body: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                CatalogSectionHeader(title: "5. Stepper & Toggles", iconName: "switch.2")

                CraftStepper(
                    value: $stepperValue,
                    range: 1...50,
                    step: 1,
                    unit: "words/day",
                    label: "Daily Learning Goal"
                )

                CraftDivider()

                VStack(spacing: theme.spacing.xs) {
                    CraftToggle(
                        isOn: $toggleNotifications,
                        title: "Push Notifications",
                        subtitle: "Receive daily review reminders and streak alerts",
                        iconName: "bell.badge.fill"
                    )

                    CraftDivider()

                    CraftToggle(
                        isOn: $toggleHaptics,
                        title: "Haptic Feedback",
                        subtitle: "Provide tactile responses for card swipes and taps",
                        iconName: "waveform"
                    )
                }
            }
        }
    }
}

// MARK: - Section 6: Cards & Bento Grid

private struct CatalogCardsBentoSection: View {
    @Environment(\.craftTheme) private var theme
    @Binding var bentoCardTapped: String?
    @Binding var isShimmerActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.base) {
            CatalogSectionHeader(title: "6. Cards, Bento Grid & Skeleton Shimmer", iconName: "square.grid.2x2.fill")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.base) {
                CraftCard(style: .flat, isPressable: true, action: { bentoCardTapped = "Flat Card" }) {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        CraftBadge("Flat Style", tone: .primary)
                        CraftText("Standard Flat", style: .headline)
                        CraftText("Subtle surface background", style: .caption, color: theme.colors.textSecondary)
                    }
                }

                CraftCard(style: .elevated, isPressable: true, action: { bentoCardTapped = "Elevated Card" }) {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        CraftBadge("Elevated", tone: .success)
                        CraftText("Elevated Shadow", style: .headline)
                        CraftText("Layered depth surface", style: .caption, color: theme.colors.textSecondary)
                    }
                }

                CraftCard(style: .outlined, isPressable: true, action: { bentoCardTapped = "Outlined Card" }) {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        CraftBadge("Outlined", tone: .warning)
                        CraftText("Border Outlined", style: .headline)
                        CraftText("Explicit outline boundary", style: .caption, color: theme.colors.textSecondary)
                    }
                }

                CraftCard(style: .gradient, isPressable: true, action: { bentoCardTapped = "Gradient Card" }) {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        CraftBadge("Hero Gradient", variant: .solid, tone: .neutral)
                        CraftText("Brand Hero", style: .headline, color: .white)
                        CraftText("Vibrant accent gradient", style: .caption, color: .white.opacity(0.85))
                    }
                }
            }

            if let bentoCardTapped {
                CraftText("Last Pressed: \(bentoCardTapped)", style: .caption, color: theme.colors.brandPrimary)
            }

            CraftCard(style: .elevated) {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        CraftText("Skeleton Card Loading (.craftShimmer)", style: .headline)
                        Spacer()
                        Toggle("Shimmer", isOn: $isShimmerActive)
                            .labelsHidden()
                            .toggleStyle(.craft)
                    }

                    HStack(spacing: theme.spacing.sm) {
                        Circle()
                            .fill(theme.colors.surfaceSubtle)
                            .frame(width: 40, height: 40)

                        VStack(alignment: .leading, spacing: 6) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.colors.surfaceSubtle)
                                .frame(width: 140, height: 14)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.colors.surfaceSubtle)
                                .frame(width: 90, height: 10)
                        }
                    }
                    .padding(.vertical, theme.spacing.xs)
                    .craftShimmer(isActive: isShimmerActive)
                }
            }
        }
    }
}

// MARK: - Section 7: Progress & Rings

private struct CatalogProgressSection: View {
    @Environment(\.craftTheme) private var theme
    @Binding var progressValue: Double

    var body: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                CatalogSectionHeader(title: "7. Progress Bars & Rings", iconName: "chart.bar.fill")

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        CraftText("CraftProgressBar (\(Int(progressValue * 100))%)", style: .headline)
                        Spacer()
                        Button("-10%") { progressValue = max(0, progressValue - 0.1) }
                            .font(theme.typography.caption)
                        Button("+10%") { progressValue = min(1.0, progressValue + 0.1) }
                            .font(theme.typography.caption)
                    }

                    CraftProgressBar(progress: progressValue, height: 10)
                }

                CraftDivider()

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("Stepped Progress (Step 3 of 5)", style: .headline)
                    CraftProgressBar(currentStep: 3, totalSteps: 5, height: 8)
                }

                CraftDivider()

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("CraftProgressRing", style: .headline)

                    HStack(spacing: theme.spacing.xl) {
                        CraftProgressRing(progress: progressValue, lineWidth: 8, size: 76)

                        CraftProgressRing(progress: 0.85, lineWidth: 8, size: 76, tintColor: theme.colors.statusSuccess) {
                            VStack(spacing: 2) {
                                CraftIcon("flame.fill", size: .sm, color: theme.colors.statusWarning)
                                CraftText("85%", style: .caption, color: theme.colors.textPrimary)
                            }
                        }

                        CraftProgressRing(progress: 0.42, lineWidth: 8, size: 76, tintColor: theme.colors.statusInfo) {
                            CraftIcon("bolt.fill", size: .md, color: theme.colors.statusInfo)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Section 8: List Rows & Empty State

private struct CatalogListRowsEmptySection: View {
    @Environment(\.craftTheme) private var theme
    @Binding var selectedPreset: CatalogEmptyStatePreset
    let onEmptyAction: () -> Void

    var body: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                CatalogSectionHeader(title: "8. List Rows & Layered Squircle Empty States", iconName: "list.bullet.rectangle.fill")

                VStack(spacing: 0) {
                    CraftListRow(
                        title: "Mastered Words",
                        subtitle: "142 vocabulary items fully retained",
                        iconName: "checkmark.seal.fill",
                        iconColor: theme.colors.statusSuccess,
                        showChevron: true
                    ) {
                        CraftBadge("Level 4", symbol: .mastery, tone: .success)
                    }

                    CraftDivider()

                    CraftListRow(
                        title: "Spaced Repetition Deck",
                        subtitle: "18 cards scheduled for review today",
                        iconName: "clock.arrow.circlepath",
                        iconColor: theme.colors.brandPrimary,
                        showChevron: true
                    ) {
                        CraftBadge("18 due", symbol: .sparkles, variant: .solid, tone: .primary)
                    }

                    CraftDivider()

                    CraftListRow(
                        title: "Grammar Rules",
                        subtitle: "Conditionals, subjunctive, and tenses",
                        iconName: "book.pages.fill",
                        iconColor: theme.colors.accent,
                        showChevron: true
                    )
                }
                .background(theme.colors.surfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))

                CraftDivider()

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        CraftText("CraftEmptyState (3-Tier Layered Squircle)", style: .headline)
                        Spacer()
                        CraftText("Continuous Radii", style: .caption, color: theme.colors.brandPrimary)
                    }

                    CraftText("Features outer translucent squircle, inner accent pill, hierarchical focal icon, and domain symbol presets.", style: .caption, color: theme.colors.textMuted)

                    Picker("Empty State Preset", selection: $selectedPreset) {
                        ForEach(CatalogEmptyStatePreset.allCases) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, theme.spacing.xs)

                    CraftCard(style: .outlined) {
                        CraftEmptyState(
                            symbol: selectedPreset.symbol,
                            title: selectedPreset.title,
                            message: selectedPreset.message,
                            buttonTitle: selectedPreset.buttonTitle,
                            buttonSymbol: selectedPreset.buttonSymbol,
                            buttonAction: onEmptyAction
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, theme.spacing.xs)
                }
            }
        }
    }
}

// MARK: - Section 9: Overlays

private struct CatalogOverlaysSection: View {
    @Environment(\.craftTheme) private var theme
    @Binding var toastStyle: CraftToastStyle
    @Binding var toastPosition: CraftToastPosition
    @Binding var isToastPresented: Bool
    @Binding var isBottomSheetPresented: Bool
    @Binding var isConfirmDialogPresented: Bool
    @Binding var isDangerDialogPresented: Bool

    var body: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                CatalogSectionHeader(title: "9. Feedback & Overlays", iconName: "bell.and.waves.left.and.right.fill")

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("CraftToast Triggers", style: .headline)

                    HStack(spacing: theme.spacing.xs) {
                        CraftButton("Info Toast", variant: .outline, size: .sm) {
                            toastStyle = .info
                            isToastPresented = true
                        }

                        CraftButton("Success", variant: .outline, size: .sm) {
                            toastStyle = .success
                            isToastPresented = true
                        }

                        CraftButton("Warning", variant: .outline, size: .sm) {
                            toastStyle = .warning
                            isToastPresented = true
                        }

                        CraftButton("Danger", variant: .outline, size: .sm) {
                            toastStyle = .danger
                            isToastPresented = true
                        }
                    }

                    Picker("Toast Placement", selection: $toastPosition) {
                        Text("Top HUD").tag(CraftToastPosition.top)
                        Text("Bottom HUD").tag(CraftToastPosition.bottom)
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, theme.spacing.xs)
                }

                CraftDivider()

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("Modals & Dialogs", style: .headline)

                    HStack(spacing: theme.spacing.sm) {
                        CraftButton(
                            "Bottom Sheet",
                            iconName: "arrow.up.doc.fill",
                            variant: .secondary,
                            size: .md
                        ) {
                            isBottomSheetPresented = true
                        }
                        .frame(maxWidth: .infinity)

                        CraftButton(
                            "Confirm Dialog",
                            iconName: "questionmark.circle.fill",
                            variant: .primary,
                            size: .md
                        ) {
                            isConfirmDialogPresented = true
                        }
                        .frame(maxWidth: .infinity)
                    }

                    CraftButton(
                        "Trigger Danger Dialog",
                        iconName: "trash.fill",
                        variant: .danger,
                        size: .md
                    ) {
                        isDangerDialogPresented = true
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Section 10: Metrics & Progression

private struct CatalogMetricsProgressionSection: View {
    @Environment(\.craftTheme) private var theme
    @Binding var masteredCount: Double
    @Binding var reviewingCount: Double
    @Binding var learningCount: Double
    @Binding var selectedRoadmapStep: Int

    var body: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                CatalogSectionHeader(title: "10. Segmented Distribution Bar & Step Roadmap", iconName: "chart.pie.fill")

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        CraftText("CraftSegmentedBar (Distribution)", style: .headline)
                        Spacer()
                        Button("Randomize") {
                            withAnimation(theme.animations.springSmooth) {
                                masteredCount = Double.random(in: 20...60).rounded()
                                reviewingCount = Double.random(in: 15...40).rounded()
                                learningCount = Double.random(in: 10...30).rounded()
                            }
                        }
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.brandPrimary)
                    }

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

                CraftDivider()

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        CraftText("CraftStepNode (Interactive Roadmap)", style: .headline)
                        Spacer()
                        CraftText("Step \(selectedRoadmapStep) of 4 Selected", style: .caption, color: theme.colors.brandPrimary)
                    }

                    VStack(spacing: 0) {
                        CraftStepNode(
                            title: "Foundations & Phonetics",
                            subtitle: "Alphabet, pronunciation rules, and 200 base words",
                            state: selectedRoadmapStep > 1 ? .completed : (selectedRoadmapStep == 1 ? .active : .upcoming),
                            stepNumber: 1,
                            onTap: { selectedRoadmapStep = 1 }
                        )

                        CraftStepNode(
                            title: "Intermediate Lexicon",
                            subtitle: "Collocations, phrasal verbs, and daily situational dialogues",
                            state: selectedRoadmapStep > 2 ? .completed : (selectedRoadmapStep == 2 ? .active : .upcoming),
                            stepNumber: 2,
                            onTap: { selectedRoadmapStep = 2 }
                        )

                        CraftStepNode(
                            title: "Advanced Idioms & Nuance",
                            subtitle: "Metaphors, formal registers, and rhetoric structures",
                            state: selectedRoadmapStep > 3 ? .completed : (selectedRoadmapStep == 3 ? .active : .locked),
                            stepNumber: 3,
                            onTap: { selectedRoadmapStep = 3 }
                        )

                        CraftStepNode(
                            title: "Fluency Mastery Certification",
                            subtitle: "Comprehensive assessment sprint and final review",
                            state: selectedRoadmapStep == 4 ? .active : .locked,
                            stepNumber: 4,
                            isLast: true,
                            onTap: { selectedRoadmapStep = 4 }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Section 11: 3D Flip Card & Quiz Cards

private struct CatalogInteractiveCardsSection: View {
    @Environment(\.craftTheme) private var theme
    @Binding var isCardFlipped: Bool
    @Binding var flipAxis: Axis
    @Binding var selectedQuizChoice: String?
    @Binding var isQuizSubmitted: Bool
    let onSubmitQuiz: () -> Void
    let onResetQuiz: () -> Void

    var body: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                CatalogSectionHeader(title: "11. 3D Flip Card & Quiz Choice Cards", iconName: "rectangle.portrait.on.rectangle.portrait.angled")

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        CraftText("CraftFlipCard (3D Double-Sided)", style: .headline)
                        Spacer()
                        Picker("Axis", selection: $flipAxis) {
                            Text("Horizontal").tag(Axis.horizontal)
                            Text("Vertical").tag(Axis.vertical)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                    }

                    CraftFlipCard(isFlipped: $isCardFlipped, axis: flipAxis) {
                        CraftCard(style: .outlined) {
                            VStack(spacing: theme.spacing.sm) {
                                HStack {
                                    CraftBadge("Vocabulary Card", symbol: .study, variant: .subtle, tone: .primary)
                                    Spacer()
                                    CraftIcon(.audio, size: .sm, color: theme.colors.brandPrimary)
                                }

                                Spacer()

                                CraftText("Ephemeral", style: .displayLarge, color: theme.colors.textPrimary)
                                CraftText("/ɪˈfem.ər.əl/", style: .label, color: theme.colors.textMuted)

                                Spacer()

                                HStack(spacing: theme.spacing.xs) {
                                    CraftIcon(.flip, size: .sm, color: theme.colors.textSecondary)
                                    CraftText("Tap to reveal definition", style: .caption, color: theme.colors.textSecondary)
                                }
                            }
                            .frame(height: 160)
                            .frame(maxWidth: .infinity)
                        }
                        .onTapGesture {
                            isCardFlipped.toggle()
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

                                CraftText("\"Fame in the digital age can be remarkably ephemeral.\"", style: .caption, color: .white.opacity(0.85))
                                    .italic()
                                    .multilineTextAlignment(.center)

                                Spacer()

                                HStack(spacing: theme.spacing.xs) {
                                    CraftIcon(.flip, size: .sm, color: .white.opacity(0.8))
                                    CraftText("Tap to flip back", style: .caption, color: .white.opacity(0.8))
                                }
                            }
                            .frame(height: 160)
                            .frame(maxWidth: .infinity)
                        }
                        .onTapGesture {
                            isCardFlipped.toggle()
                        }
                    }
                }

                CraftDivider()

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        CraftText("CraftChoiceCard (Quiz with Dual-Tone Indicators)", style: .headline)
                        Spacer()
                        if isQuizSubmitted {
                            Button("Reset", action: onResetQuiz)
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.brandPrimary)
                        }
                    }

                    CraftText("What is the closest synonym for 'Ephemeral'?", style: .bodyMedium, color: theme.colors.textSecondary)
                        .padding(.bottom, theme.spacing.xs)

                    VStack(spacing: theme.spacing.sm) {
                        CraftChoiceCard(
                            prefix: "A",
                            title: "Permanent",
                            subtitle: "Enduring and perpetual across eras",
                            state: choiceState(for: "A")
                        ) {
                            selectChoice("A")
                        }

                        CraftChoiceCard(
                            prefix: "B",
                            title: "Transitory",
                            subtitle: "Fleeting and brief in existence",
                            state: choiceState(for: "B")
                        ) {
                            selectChoice("B")
                        }

                        CraftChoiceCard(
                            prefix: "C",
                            title: "Immutable",
                            subtitle: "Completely rigid and unchangeable",
                            state: choiceState(for: "C")
                        ) {
                            selectChoice("C")
                        }

                        CraftChoiceCard(
                            prefix: "D",
                            title: "Dormant",
                            subtitle: "Temporarily inactive or asleep",
                            state: choiceState(for: "D")
                        ) {
                            selectChoice("D")
                        }
                    }

                    if !isQuizSubmitted {
                        CraftButton(
                            "Submit Answer",
                            iconName: "checkmark.circle.fill",
                            variant: .primary,
                            size: .md,
                            action: onSubmitQuiz
                        )
                        .frame(maxWidth: .infinity)
                        .disabled(selectedQuizChoice == nil)
                        .padding(.top, theme.spacing.xs)
                    }
                }

                CraftDivider()

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("Choice Card State Matrix", style: .headline)

                    HStack(spacing: theme.spacing.xs) {
                        CraftChoiceCard(prefix: "1", title: "Idle", state: .idle) {}
                        CraftChoiceCard(prefix: "2", title: "Selected", state: .selected) {}
                    }

                    HStack(spacing: theme.spacing.xs) {
                        CraftChoiceCard(prefix: "3", title: "Correct", state: .correct) {}
                        CraftChoiceCard(prefix: "4", title: "Wrong", state: .wrong) {}
                    }
                }
            }
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

// MARK: - Section 12: Floating TabBar

private struct CatalogNavigationSection: View {
    @Environment(\.craftTheme) private var theme
    @Binding var selectedTab: CatalogTabItem
    @Binding var showCenterFAB: Bool
    @Binding var fabTapCount: Int
    let onFabTap: () -> Void

    var body: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                CatalogSectionHeader(title: "12. Floating Liquid Glass TabBar", iconName: "dock.rectangle")

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("Active Navigation Canvas", style: .headline)

                    ZStack {
                        RoundedRectangle(cornerRadius: theme.radii.lg)
                            .fill(theme.colors.surfaceSubtle.opacity(0.4))
                            .frame(height: 130)

                        VStack(spacing: theme.spacing.xs) {
                            CraftIcon(selectedTab.symbol, size: .xl, color: theme.colors.brandPrimary)
                            CraftText("Active: \(selectedTab.title) Screen", style: .headline, color: theme.colors.textPrimary)
                            CraftText("Liquid glass capsule with spring sliding indicator", style: .caption, color: theme.colors.textMuted)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        CraftFloatingTabBar(
                            selectedItem: $selectedTab,
                            items: CatalogTabItem.allCases,
                            centerAction: showCenterFAB ? onFabTap : nil,
                            centerSymbol: CraftSymbol.add.rawValue,
                            centerTitle: "Add"
                        )
                        .padding(.bottom, theme.spacing.xs)
                    }
                }

                CraftDivider()

                CraftToggle(
                    isOn: $showCenterFAB,
                    title: "Integrated Center Action",
                    subtitle: "Displays tactile circular action button inside liquid glass bar",
                    iconName: "plus.circle.fill"
                )

                if fabTapCount > 0 {
                    CraftText("Center action button tapped \(fabTapCount) times", style: .caption, color: theme.colors.brandPrimary)
                }
            }
        }
    }
}

// MARK: - Section 13: Audio Visualizer & Motion FX

private struct CatalogAudioMotionSection: View {
    @Environment(\.craftTheme) private var theme
    @Binding var waveformLevels: [CGFloat]
    @Binding var isWaveformRecording: Bool
    @Binding var isSparkleTriggered: Bool
    @Binding var isConfettiTriggered: Bool
    @Binding var isCountdownPresented: Bool

    var body: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                CatalogSectionHeader(title: "13. Audio & Motion FX", iconName: "waveform.badge.mic")

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        CraftText("CraftWaveformView (Audio Visualizer)", style: .headline)
                        Spacer()
                        Toggle("Recording Glow", isOn: $isWaveformRecording)
                            .labelsHidden()
                            .toggleStyle(.craft)
                    }

                    HStack {
                        CraftWaveformView(
                            audioLevels: waveformLevels,
                            barCount: 16,
                            isRecording: isWaveformRecording
                        )

                        Spacer()

                        CraftButton("Randomize", iconName: "dice.fill", variant: .outline, size: .sm) {
                            waveformLevels = (0..<16).map { _ in CGFloat.random(in: 0.05...1.0) }
                        }
                    }
                }

                CraftDivider()

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("Celebration FX (Sparkles & Confetti)", style: .headline)

                    HStack(spacing: theme.spacing.sm) {
                        CraftButton(
                            "Sparkle Burst",
                            iconName: "sparkles",
                            variant: .primary,
                            size: .md
                        ) {
                            isSparkleTriggered = true
                        }
                        .frame(maxWidth: .infinity)

                        CraftButton(
                            "Confetti Cannon",
                            iconName: "party.popper.fill",
                            variant: .secondary,
                            size: .md
                        ) {
                            isConfettiTriggered = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                CraftDivider()

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("Countdown Overlay Modal", style: .headline)

                    CraftButton(
                        "Launch 3-2-1 Countdown",
                        iconName: "timer",
                        variant: .outline,
                        size: .md
                    ) {
                        isCountdownPresented = true
                    }
                    .frame(maxWidth: .infinity)
                }
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

#Preview("CraftCatalogView - Light") {
    CraftCatalogView()
}

#Preview("CraftCatalogView - Dark") {
    CraftCatalogView()
        .preferredColorScheme(.dark)
}
