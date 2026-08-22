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

    public init(
        colors: CraftColorTokens = CraftEmeraldColorTokens(),
        typography: CraftTypographyTokens = CraftDefaultTypographyTokens(),
        spacing: CraftSpacingTokens = CraftDefaultSpacingTokens(),
        radii: CraftRadiusTokens = CraftDefaultRadiusTokens(),
        shadows: CraftShadowTokens = CraftDefaultShadowTokens(),
        gradients: CraftGradientTokens = CraftEmeraldGradientTokens(),
        animations: CraftAnimationTokens = CraftDefaultAnimationTokens()
    ) {
        self.colors = colors
        self.typography = typography
        self.spacing = spacing
        self.radii = radii
        self.shadows = shadows
        self.gradients = gradients
        self.animations = animations
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

    // Interactive States
    @State private var isButtonLoading: Bool = false
    @State private var iconButtonCounter: Int = 0
    @State private var selectedPills: Set<String> = ["Vocabulary", "Grammar"]
    @State private var searchQuery: String = ""
    @State private var textInput: String = "Design System"
    @State private var passwordInput: String = "SecretPass123"
    @State private var errorInput: String = "Invalid Email"
    @State private var toggleNotifications: Bool = true
    @State private var toggleHaptics: Bool = true
    @State private var toggleDarkMode: Bool = false
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Header / Controls Bar
                    headerThemeBar

                    // Section 1: Typography & Icons
                    typographyIconsSection

                    // Section 2: Badges & Tags
                    badgesPillsSection

                    // Section 3: Buttons
                    buttonsSection

                    // Section 4: TextFields & SearchBar
                    textFieldsSection

                    // Section 5: Stepper & Toggles
                    stepperTogglesSection

                    // Section 6: Cards & Bento Grid
                    cardsBentoSection

                    // Section 7: Progress Bars & Rings
                    progressSection

                    // Section 8: List Rows & Empty State
                    listRowsEmptyStateSection

                    // Section 9: Toasts, Sheets & Dialogs
                    overlaysSection
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
        // Overlays Attached to Root
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

    // MARK: - 0. Header / Theme Switcher Bar

    private var headerThemeBar: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack {
                    CraftIcon("paintbrush.fill", size: .md, color: theme.colors.brandPrimary)
                    CraftText("Design System Theme & Appearance", style: .headline, color: theme.colors.textPrimary)
                }

                CraftDivider()

                HStack(spacing: theme.spacing.base) {
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

    // MARK: - 1. Typography & Icons Section

    private var typographyIconsSection: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                sectionHeader(title: "1. Typography & Icons", iconName: "textformat")

                // Typography Styles
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("Display Large", style: .displayLarge)
                    CraftText("Title Large", style: .titleLarge)
                    CraftText("Title Medium", style: .titleMedium)
                    CraftText("Headline Text", style: .headline)
                    CraftText("Body Large Typography Scale", style: .bodyLarge)
                    CraftText("Body Medium standard readability paragraph style.", style: .bodyMedium, color: theme.colors.textSecondary)
                    CraftText("Label Style", style: .label, color: theme.colors.textMuted)
                    CraftText("Caption helper text style", style: .caption, color: theme.colors.textMuted)
                }

                CraftDivider()

                // Icon Scales
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

                // Icon Buttons
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        CraftText("CraftIconButton Variants & Shapes", style: .headline)
                        Spacer()
                        CraftText("Taps: \(iconButtonCounter)", style: .caption, color: theme.colors.brandPrimary)
                    }

                    HStack(spacing: theme.spacing.sm) {
                        CraftIconButton(iconName: "heart.fill", size: .md, shape: .circle, variant: .filled) {
                            iconButtonCounter += 1
                        }
                        CraftIconButton(iconName: "bookmark.fill", size: .md, shape: .circle, variant: .subtle) {
                            iconButtonCounter += 1
                        }
                        CraftIconButton(iconName: "square.and.arrow.up", size: .md, shape: .circle, variant: .outline) {
                            iconButtonCounter += 1
                        }
                        CraftIconButton(iconName: "ellipsis", size: .md, shape: .circle, variant: .ghost) {
                            iconButtonCounter += 1
                        }

                        Spacer()

                        CraftIconButton(iconName: "play.fill", size: .md, shape: .square, variant: .filled) {
                            iconButtonCounter += 1
                        }
                        CraftIconButton(iconName: "pause.fill", size: .md, shape: .square, variant: .subtle) {
                            iconButtonCounter += 1
                        }
                        CraftIconButton(iconName: "slider.horizontal.3", size: .md, shape: .square, variant: .outline) {
                            iconButtonCounter += 1
                        }
                    }
                }

                CraftDivider()

                // Spinners
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("CraftSpinner Scales", style: .headline)
                    HStack(spacing: theme.spacing.lg) {
                        CraftSpinner(size: .sm)
                        CraftSpinner(size: .md)
                        CraftSpinner(size: .lg)
                        CraftSpinner(size: .xl)
                    }
                }
            }
        }
    }

    // MARK: - 2. Badges & Pills Section

    private var badgesPillsSection: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                sectionHeader(title: "2. Badges & Pills", iconName: "tag.fill")

                // Badge Variants & Tones
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("CraftBadge Variants & Tones", style: .headline)

                    // Solid
                    HStack(spacing: theme.spacing.xs) {
                        CraftBadge("Primary", iconName: "sparkles", variant: .solid, tone: .primary)
                        CraftBadge("Success", iconName: "checkmark", variant: .solid, tone: .success)
                        CraftBadge("Warning", iconName: "exclamationmark.triangle", variant: .solid, tone: .warning)
                        CraftBadge("Danger", iconName: "xmark.octagon", variant: .solid, tone: .danger)
                        CraftBadge("Neutral", variant: .solid, tone: .neutral)
                    }

                    // Subtle
                    HStack(spacing: theme.spacing.xs) {
                        CraftBadge("Primary", iconName: "sparkles", variant: .subtle, tone: .primary)
                        CraftBadge("Success", iconName: "checkmark", variant: .subtle, tone: .success)
                        CraftBadge("Warning", iconName: "exclamationmark.triangle", variant: .subtle, tone: .warning)
                        CraftBadge("Danger", iconName: "xmark.octagon", variant: .subtle, tone: .danger)
                        CraftBadge("Neutral", variant: .subtle, tone: .neutral)
                    }

                    // Outline
                    HStack(spacing: theme.spacing.xs) {
                        CraftBadge("Primary", iconName: "sparkles", variant: .outline, tone: .primary)
                        CraftBadge("Success", iconName: "checkmark", variant: .outline, tone: .success)
                        CraftBadge("Warning", iconName: "exclamationmark.triangle", variant: .outline, tone: .warning)
                        CraftBadge("Danger", iconName: "xmark.octagon", variant: .outline, tone: .danger)
                        CraftBadge("Neutral", variant: .outline, tone: .neutral)
                    }
                }

                CraftDivider()

                // Filter Chips / Pills
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("CraftPill / Filter Chips (Interactive Selection)", style: .headline)

                    let chips = [
                        ("Vocabulary", "character.book.closed.fill", 14),
                        ("Grammar", "doc.text.fill", 8),
                        ("Listening", "headphones", 22),
                        ("Idioms", "quote.bubble.fill", 5),
                        ("Favorites", "heart.fill", 3)
                    ]

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: theme.spacing.xs) {
                            ForEach(chips, id: \.0) { title, icon, count in
                                let isSelected = selectedPills.contains(title)
                                CraftPill(
                                    title,
                                    iconName: icon,
                                    count: count,
                                    isSelected: isSelected
                                ) {
                                    if isSelected {
                                        selectedPills.remove(title)
                                    } else {
                                        selectedPills.insert(title)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 3. Buttons Section

    private var buttonsSection: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                sectionHeader(title: "3. Buttons", iconName: "hand.tap.fill")

                HStack {
                    CraftText("Variants & Loading State", style: .headline)
                    Spacer()
                    Toggle("Loading State", isOn: $isButtonLoading)
                        .labelsHidden()
                        .toggleStyle(.craft)
                }

                // All Variants
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

                // Sizes
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("Button Sizes (sm, md, lg)", style: .headline)
                    HStack(spacing: theme.spacing.sm) {
                        CraftButton("Small (32pt)", variant: .primary, size: .sm) {}
                        CraftButton("Medium (44pt)", variant: .primary, size: .md) {}
                    }
                    CraftButton("Large Button (54pt)", iconName: "star.fill", variant: .primary, size: .lg) {}
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - 4. TextFields & SearchBar Section

    private var textFieldsSection: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                sectionHeader(title: "4. TextFields & SearchBar", iconName: "pencil.and.list.clipboard")

                // Search Bar
                CraftText("CraftSearchBar", style: .headline)
                CraftSearchBar(
                    text: $searchQuery,
                    placeholder: "Search vocabulary, lessons, tags...",
                    onCancel: { searchQuery = "" }
                )

                CraftDivider()

                // Standard TextField
                CraftTextField(
                    placeholder: "e.g. Vocabulary Craft",
                    text: $textInput,
                    label: "Project Title",
                    helperText: "Enter a descriptive name for your study set",
                    leadingIcon: "folder.fill"
                )

                // Password / Secure TextField
                CraftTextField(
                    placeholder: "Enter account password",
                    text: $passwordInput,
                    label: "Password Input (With Visibility Toggle)",
                    leadingIcon: "lock.fill",
                    isSecure: true
                )

                // Error State TextField
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

    // MARK: - 5. Stepper & Toggles Section

    private var stepperTogglesSection: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                sectionHeader(title: "5. Stepper & Toggles", iconName: "switch.2")

                // Stepper
                CraftStepper(
                    value: $stepperValue,
                    range: 1...50,
                    step: 1,
                    unit: "words/day",
                    label: "Daily Learning Goal"
                )

                CraftDivider()

                // Toggles
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

    // MARK: - 6. Cards & Bento Grid Section

    private var cardsBentoSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.base) {
            sectionHeader(title: "6. Cards & Bento Grid", iconName: "square.grid.2x2.fill")

            // Bento Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.base) {
                // Card 1: Flat
                CraftCard(style: .flat, isPressable: true, action: { bentoCardTapped = "Flat Card" }) {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        CraftBadge("Flat Style", tone: .primary)
                        CraftText("Standard Flat", style: .headline)
                        CraftText("Subtle surface background", style: .caption, color: theme.colors.textSecondary)
                    }
                }

                // Card 2: Elevated
                CraftCard(style: .elevated, isPressable: true, action: { bentoCardTapped = "Elevated Card" }) {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        CraftBadge("Elevated", tone: .success)
                        CraftText("Elevated Shadow", style: .headline)
                        CraftText("Layered depth surface", style: .caption, color: theme.colors.textSecondary)
                    }
                }

                // Card 3: Outlined
                CraftCard(style: .outlined, isPressable: true, action: { bentoCardTapped = "Outlined Card" }) {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        CraftBadge("Outlined", tone: .warning)
                        CraftText("Border Outlined", style: .headline)
                        CraftText("Explicit outline boundary", style: .caption, color: theme.colors.textSecondary)
                    }
                }

                // Card 4: Gradient
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
        }
    }

    // MARK: - 7. Progress Bars & Rings Section

    private var progressSection: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                sectionHeader(title: "7. Progress Bars & Rings", iconName: "chart.bar.fill")

                // Progress Bar
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

                // Stepped Progress Bar
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("Stepped Progress (Step 3 of 5)", style: .headline)
                    CraftProgressBar(currentStep: 3, totalSteps: 5, height: 8)
                }

                CraftDivider()

                // Progress Rings
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

                CraftDivider()

                // Segmented Metric Bar
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("CraftSegmentedBar", style: .headline)

                    CraftSegmentedBar(
                        items: [
                            CraftSegmentItem(id: "1", label: "Mastered", value: 45, color: theme.colors.statusSuccess),
                            CraftSegmentItem(id: "2", label: "Reviewing", value: 30, color: theme.colors.brandPrimary),
                            CraftSegmentItem(id: "3", label: "Learning", value: 25, color: theme.colors.statusWarning)
                        ],
                        height: 10
                    )
                }

                CraftDivider()

                // Step Roadmap Nodes
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText("CraftStepNode (Roadmap)", style: .headline)

                    VStack(spacing: 0) {
                        CraftStepNode(
                            title: "Foundations",
                            subtitle: "Core vocabulary & phonetics completed",
                            state: .completed,
                            stepNumber: 1
                        )
                        CraftStepNode(
                            title: "Intermediate Grammar",
                            subtitle: "Sentence structure & common idioms",
                            state: .active,
                            stepNumber: 2
                        )
                        CraftStepNode(
                            title: "Advanced Nuances",
                            subtitle: "Subtle connotations & formal registers",
                            state: .upcoming,
                            stepNumber: 3
                        )
                        CraftStepNode(
                            title: "Mastery Certification",
                            subtitle: "Comprehensive assessment",
                            state: .locked,
                            stepNumber: 4,
                            isLast: true
                        )
                    }
                }
            }
        }
    }

    // MARK: - 8. List Rows & Empty State Section

    private var listRowsEmptyStateSection: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                sectionHeader(title: "8. List Rows & Empty State", iconName: "list.bullet.rectangle.fill")

                // List Rows
                VStack(spacing: 0) {
                    CraftListRow(
                        title: "Mastered Words",
                        subtitle: "142 vocabulary items fully retained",
                        iconName: "checkmark.seal.fill",
                        iconColor: theme.colors.statusSuccess,
                        showChevron: true
                    ) {
                        CraftBadge("Level 4", tone: .success)
                    }

                    CraftDivider()

                    CraftListRow(
                        title: "Spaced Repetition Deck",
                        subtitle: "18 cards scheduled for review today",
                        iconName: "clock.arrow.circlepath",
                        iconColor: theme.colors.brandPrimary,
                        showChevron: true
                    ) {
                        CraftBadge("18 due", variant: .solid, tone: .primary)
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

                // Empty State Demo
                CraftText("CraftEmptyState Placeholder", style: .headline)
                CraftCard(style: .outlined) {
                    CraftEmptyState(
                        iconName: "tray.fill",
                        title: "No Completed Quizzes",
                        message: "Take your first daily vocabulary sprint to unlock performance analytics and progress tracking.",
                        buttonTitle: "Start Sprint",
                        buttonIcon: "play.fill"
                    ) {
                        toastStyle = .info
                        isToastPresented = true
                    }
                }
            }
        }
    }

    // MARK: - 9. Overlays Section

    private var overlaysSection: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                sectionHeader(title: "9. Feedback & Overlays", iconName: "bell.and.waves.left.and.right.fill")

                // Toast Trigger Options
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

                // Modal Overlays Triggers
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

    // MARK: - Helpers

    private func sectionHeader(title: String, iconName: String) -> some View {
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
