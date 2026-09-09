import CraftUIKit
import SwiftUI

public struct SettingsView: View {
    @Environment(\.craftTheme) private var theme
    @Bindable public var viewModel: SettingsViewModel
    @State private var showResetAlert: Bool = false
    @State private var showCatalogSheet: Bool = ProcessInfo.processInfo.arguments.contains("-open-catalog")
    @State private var showProfileSheet: Bool = false

    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // 1. Hero Profile Card
                    HeroProfileCard(userLevel: viewModel.store.assessedCefrLevel) {
                        showProfileSheet = true
                    }

                    // 2. Learning & Goals Section
                    learningSection

                    // 3. Audio & Speech Section
                    audioSection

                    // 4. Appearance & Feedback Section
                    appearanceSection

                    // 5. Data & Storage Section
                    dataSection

                    // 6. About & System Section
                    aboutSection
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.top, theme.spacing.sm)
                .padding(.bottom, theme.spacing.xxl + 40)
            }
            .background(theme.colors.canvasBackground.ignoresSafeArea())
            .navigationTitle(AppStrings.Settings.title)
            .onAppear {
                if ProcessInfo.processInfo.arguments.contains("-scroll-developer") {
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(300))
                        withAnimation(.easeInOut(duration: 0.4)) {
                            proxy.scrollTo("developer_section", anchor: .bottom)
                        }
                    }
                }
            }
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $showCatalogSheet) {
            CraftCatalogView()
        }
        #else
        .sheet(isPresented: $showCatalogSheet) {
            CraftCatalogView()
                .frame(minWidth: 700, minHeight: 600)
        }
        #endif
        .sheet(isPresented: $showProfileSheet) {
            ProfileStatsSheet()
        }
        .sensoryFeedback(.selection, trigger: viewModel.store.dailyGoalCount) { _, _ in viewModel.store.isHapticsEnabled }
        .sensoryFeedback(.selection, trigger: viewModel.store.themePreset) { _, _ in viewModel.store.isHapticsEnabled }
        .sensoryFeedback(.selection, trigger: viewModel.store.ttsVoiceGender) { _, _ in viewModel.store.isHapticsEnabled }
        .sensoryFeedback(.selection, trigger: viewModel.store.appTheme) { _, _ in viewModel.store.isHapticsEnabled }
        .sensoryFeedback(.selection, trigger: viewModel.store.appLanguage) { _, _ in viewModel.store.isHapticsEnabled }
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.store.isNotificationEnabled) { _, _ in viewModel.store.isHapticsEnabled }
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.store.isHapticsEnabled) { _, _ in viewModel.store.isHapticsEnabled }
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.store.isSoundEffectsEnabled) { _, _ in viewModel.store.isHapticsEnabled }
        .alert(AppStrings.Settings.resetConfirmTitle, isPresented: $showResetAlert) {
            Button(AppStrings.Common.cancel, role: .cancel) {}
            Button(AppStrings.Common.reset, role: .destructive) {
                Task {
                    await viewModel.resetSRSProgress()
                }
            }
        } message: {
            Text(AppStrings.Settings.resetConfirmMessage)
        }
    }

    // MARK: - Section Views

    private var learningSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            sectionHeader(AppStrings.Settings.sectionLearning)
            SettingsLearningCard(store: viewModel.store)
        }
    }

    private var audioSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            sectionHeader(AppStrings.Settings.sectionAudio)
            SettingsAudioCard(
                store: viewModel.store,
                isPlayingAudio: viewModel.isPlayingAudio,
                onPlayPreview: {
                    viewModel.playAudioPreview()
                }
            )
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            sectionHeader(AppStrings.Settings.sectionAppearance)
            SettingsAppearanceCard(store: viewModel.store)
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            sectionHeader(AppStrings.Settings.sectionDataStorage)
            SettingsDataStorageCard(
                cacheSizeString: viewModel.cacheSizeString,
                onClearCache: {
                    viewModel.clearCache()
                },
                onShowResetAlert: {
                    showResetAlert = true
                }
            )
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            sectionHeader(AppStrings.Settings.sectionAbout)
            SettingsAboutCard(
                store: viewModel.store,
                onOpenCatalog: {
                    showCatalogSheet = true
                }
            )
            .id("developer_section")
        }
    }

    private func sectionHeader(_ title: LocalizedStringKey) -> some View {
        CraftText(title, style: .caption, color: theme.colors.textSecondary)
            .fontWeight(.bold)
            .padding(.horizontal, theme.spacing.xs)
    }
}

// MARK: - Subview Components

private struct SettingsLearningCard: View {
    @Environment(\.craftTheme) private var theme
    @Bindable var store: UserSettingsStore

    var body: some View {
        CraftCard(style: .outlined, padding: 0) {
            VStack(spacing: 0) {
                CraftListRow(
                    title: AppStrings.Settings.dailyGoal
                ) {
                    CraftStepper(
                        value: $store.dailyGoalCount,
                        range: 5...100,
                        step: 5,
                        unit: AppStrings.Common.wordUnit
                    )
                }

                CraftDivider()

                CraftListRow(
                    title: AppStrings.Settings.reminders
                ) {
                    CraftSwitch(
                        isOn: Binding(
                            get: { store.isNotificationEnabled },
                            set: { newValue in
                                withAnimation(theme.animations.springSnappy) {
                                    store.isNotificationEnabled = newValue
                                }
                            }
                        ),
                        activeTint: theme.colors.brandPrimary
                    )
                }

                if store.isNotificationEnabled {
                    CraftDivider()

                    CraftListRow(
                        title: AppStrings.Settings.reminderTime
                    ) {
                        DatePicker(
                            "",
                            selection: $store.notificationTime,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .tint(theme.colors.brandPrimary)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                CraftDivider()

                CraftListRow(
                    title: AppStrings.Settings.targetLevel
                ) {
                    CraftBadge(
                        store.assessedCefrLevel,
                        symbol: .star,
                        variant: .subtle,
                        tone: .primary,
                        size: .sm
                    )
                }
            }
        }
    }
}

private struct SettingsAudioCard: View {
    @Environment(\.craftTheme) private var theme
    @Bindable var store: UserSettingsStore
    let isPlayingAudio: Bool
    let onPlayPreview: () -> Void

    var body: some View {
        CraftCard(style: .outlined, padding: 0) {
            VStack(spacing: 0) {
                CraftListRow(
                    title: AppStrings.Settings.audioAccent
                ) {
                    CraftSegmentedControl(
                        selection: $store.ttsVoiceGender,
                        options: [
                            CraftSegmentOption("US", title: AppStrings.Settings.accentUSText),
                            CraftSegmentOption("UK", title: AppStrings.Settings.accentUKText)
                        ],
                        style: .flat
                    )
                    .frame(width: 170)
                }

                CraftDivider()

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        CraftText(
                            AppStrings.Settings.speechSpeed,
                            style: .headline,
                            color: theme.colors.textPrimary
                        )

                        Spacer()

                        CraftBadge(
                            String(format: "%.2fx", store.ttsSpeed),
                            variant: .subtle,
                            tone: .warning,
                            size: .sm
                        )
                    }
                    .padding(.horizontal, theme.spacing.base)
                    .padding(.top, theme.spacing.sm)

                    HStack(spacing: theme.spacing.sm) {
                        Image(systemName: "tortoise")
                            .foregroundStyle(theme.colors.textMuted)
                            .accessibilityHidden(true)

                        Slider(value: $store.ttsSpeed, in: 0.5...1.5, step: 0.05)
                            .tint(theme.colors.brandPrimary)

                        Image(systemName: "hare.fill")
                            .foregroundStyle(theme.colors.textMuted)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, theme.spacing.base)
                    .padding(.bottom, theme.spacing.sm)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text(AppStrings.Settings.speechSpeed))
                .accessibilityValue(Text(String(format: "%.2fx", store.ttsSpeed)))

                CraftDivider()

                CraftListRow(
                    title: isPlayingAudio ? AppStrings.Settings.playingPreview : AppStrings.Settings.testTTS,
                    iconName: isPlayingAudio ? "speaker.wave.3.fill" : "play.circle.fill",
                    iconColor: theme.colors.brandPrimary,
                    iconBackgroundColor: theme.colors.surfaceSubtle,
                    showChevron: !isPlayingAudio,
                    action: onPlayPreview
                ) {
                    if isPlayingAudio {
                        CraftWaveformView(
                            audioLevels: [0.3, 0.8, 0.6, 0.9],
                            barCount: 4,
                            spacing: 3,
                            minHeight: 6,
                            maxHeight: 20,
                            barWidth: 3,
                            isRecording: true,
                            activeColor: theme.colors.brandPrimary
                        )
                        .padding(.trailing, theme.spacing.xs)
                    } else {
                        EmptyView()
                    }
                }
            }
        }
    }
}

private struct SettingsAppearanceCard: View {
    @Environment(\.craftTheme) private var theme
    @Bindable var store: UserSettingsStore

    var body: some View {
        CraftCard(style: .outlined, padding: 0) {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    CraftText(
                        AppStrings.Settings.appearanceMode,
                        style: .headline,
                        color: theme.colors.textPrimary
                    )

                    CraftSegmentedControl(
                        selection: $store.appTheme,
                        options: [
                            CraftSegmentOption("dark", title: AppStrings.Settings.themeDarkText),
                            CraftSegmentOption("light", title: AppStrings.Settings.themeLightText),
                            CraftSegmentOption("system", title: AppStrings.Settings.themeSystemText)
                        ],
                        style: .flat
                    )
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.vertical, theme.spacing.sm)

                CraftDivider()

                CraftListRow(
                    title: AppStrings.Settings.themePreset,
                    subtitle: LocalizedStringKey(store.themePreset.displayName)
                ) {
                    Picker("", selection: $store.themePreset) {
                        ForEach(CraftThemePreset.allCases) { preset in
                            Text(preset.displayName).tag(preset)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(theme.colors.brandPrimary)
                }

                CraftDivider()

                CraftListRow(
                    title: AppStrings.Settings.haptics
                ) {
                    CraftSwitch(isOn: $store.isHapticsEnabled, activeTint: theme.colors.brandPrimary)
                }

                CraftDivider()

                CraftListRow(
                    title: AppStrings.Settings.soundEffects
                ) {
                    CraftSwitch(isOn: $store.isSoundEffectsEnabled, activeTint: theme.colors.brandPrimary)
                }
            }
        }
    }
}

private struct SettingsDataStorageCard: View {
    @Environment(\.craftTheme) private var theme
    let cacheSizeString: String
    let onClearCache: () -> Void
    let onShowResetAlert: () -> Void

    var body: some View {
        CraftCard(style: .outlined, padding: 0) {
            VStack(spacing: 0) {
                CraftListRow(
                    title: AppStrings.Settings.icloudSync
                ) {
                    CraftBadge(
                        AppStrings.Settings.synced,
                        symbol: .check,
                        variant: .subtle,
                        tone: .success,
                        size: .sm
                    )
                }

                CraftDivider()

                CraftListRow(
                    title: AppStrings.Settings.clearCache,
                    action: onClearCache
                ) {
                    CraftText(
                        cacheSizeString,
                        style: .label,
                        color: theme.colors.textMuted
                    )
                }

                CraftDivider()

                CraftListRow(
                    title: AppStrings.Settings.resetSRS,
                    subtitle: AppStrings.Settings.resetSRSSubtitle,
                    titleColor: theme.colors.statusDanger,
                    chevronColor: theme.colors.statusDanger.opacity(0.6),
                    showChevron: true,
                    action: onShowResetAlert
                )
            }
        }
    }
}

private struct SettingsAboutCard: View {
    @Environment(\.craftTheme) private var theme
    @Bindable var store: UserSettingsStore
    let onOpenCatalog: () -> Void

    var body: some View {
        CraftCard(style: .outlined, padding: 0) {
            VStack(spacing: 0) {
                CraftListRow(
                    title: AppStrings.Settings.appLanguage
                ) {
                    Picker("", selection: $store.appLanguage) {
                        Text(AppStrings.Settings.langSystem).tag("system")
                        Text(AppStrings.Settings.langVietnamese).tag("vi")
                        Text(AppStrings.Settings.langEnglish).tag("en")
                    }
                    .pickerStyle(.menu)
                    .tint(theme.colors.brandPrimary)
                }

                CraftDivider()

                CraftListRow(
                    title: AppStrings.Settings.craftCatalog,
                    subtitle: AppStrings.Settings.craftCatalogSubtitle,
                    showChevron: true,
                    action: onOpenCatalog
                )

                CraftDivider()

                CraftListRow(
                    title: AppStrings.Settings.appVersion
                ) {
                    CraftText(
                        appVersionString,
                        style: .label,
                        color: theme.colors.textMuted
                    )
                }
            }
        }
    }

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (Build \(build))"
    }
}
