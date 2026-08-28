import CraftUIKit
import SwiftUI

public struct SettingsView: View {
    @Environment(\.craftTheme) private var theme
    @Bindable public var viewModel: SettingsViewModel
    @State private var showResetAlert: Bool = false
    @State private var showGoalInputAlert: Bool = false
    @State private var goalInputText: String = ""
    @State private var showCatalogSheet: Bool = ProcessInfo.processInfo.arguments.contains("-open-catalog")

    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // 1. Hero Profile & Pro Card
                    HeroProfileCard()

                    // 2. 7-Day Streak Tracker Card
                    CraftStreakCard(data: streakData, cardStyle: .outlined)

                    // 3. Learning & SRS Section
                    learningSection

                    // 4. Audio & TTS Section
                    audioSection

                    // 5. Appearance & Experience Section
                    appearanceSection

                    // 6. Developer Tools Section
                    developerSection

                    // 7. About & App Info Section
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
        .sensoryFeedback(.selection, trigger: viewModel.store.dailyGoalCount) { _, _ in viewModel.store.isHapticsEnabled }
        .sensoryFeedback(.selection, trigger: viewModel.store.themePreset) { _, _ in viewModel.store.isHapticsEnabled }
        .sensoryFeedback(.selection, trigger: viewModel.store.ttsVoiceGender) { _, _ in viewModel.store.isHapticsEnabled }
        .sensoryFeedback(.selection, trigger: viewModel.store.appTheme) { _, _ in viewModel.store.isHapticsEnabled }
        .sensoryFeedback(.selection, trigger: viewModel.store.appLanguage) { _, _ in viewModel.store.isHapticsEnabled }
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.store.isNotificationEnabled) { _, _ in viewModel.store.isHapticsEnabled }
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.store.isHapticsEnabled) { _, _ in viewModel.store.isHapticsEnabled }
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.store.isSoundEffectsEnabled) { _, _ in viewModel.store.isHapticsEnabled }
        .alert(AppStrings.Settings.dailyGoal, isPresented: $showGoalInputAlert) {
            TextField("5 - 100", text: $goalInputText)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
            Button(AppStrings.Common.cancel, role: .cancel) {}
            Button(AppStrings.Common.save) {
                if let val = Int(goalInputText), val >= 5, val <= 100 {
                    viewModel.store.dailyGoalCount = val
                }
            }
        } message: {
            Text(AppStrings.Settings.dailyGoal)
        }
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
            SettingsLearningCard(
                store: viewModel.store,
                onShowGoalInput: {
                    goalInputText = "\(viewModel.store.dailyGoalCount)"
                    showGoalInputAlert = true
                },
                onShowResetAlert: {
                    showResetAlert = true
                }
            )
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

    private var developerSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            sectionHeader(AppStrings.Settings.sectionDevTools)
            SettingsDeveloperCard(
                store: viewModel.store,
                onOpenCatalog: {
                    showCatalogSheet = true
                }
            )
            .id("developer_section")
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            sectionHeader(AppStrings.Settings.sectionAbout)
            SettingsAboutCard(
                cacheSizeString: viewModel.cacheSizeString,
                onClearCache: {
                    viewModel.clearCache()
                }
            )
        }
    }

    private func sectionHeader(_ title: LocalizedStringKey) -> some View {
        CraftText(title, style: .caption, color: theme.colors.textSecondary)
            .fontWeight(.bold)
            .padding(.horizontal, theme.spacing.xs)
    }

    private var streakData: CraftStreakData {
        let mockDays: [CraftStreakDay] = [
            .init(id: "1", weekdaySymbol: "T2", status: .completed),
            .init(id: "2", weekdaySymbol: "T3", status: .completed),
            .init(id: "3", weekdaySymbol: "T4", status: .completed),
            .init(id: "4", weekdaySymbol: "T5", status: .pending, isToday: true),
            .init(id: "5", weekdaySymbol: "T6", status: .upcoming),
            .init(id: "6", weekdaySymbol: "T7", status: .upcoming),
            .init(id: "7", weekdaySymbol: "CN", status: .upcoming)
        ]
        return CraftStreakData(
            currentStreak: 14,
            bestStreak: 30,
            freezeTokens: 2,
            maxFreezeTokens: 3,
            nextMilestoneDays: 21,
            isCompletedToday: false,
            weekDays: mockDays
        )
    }
}

// MARK: - Subview Components

private struct SettingsLearningCard: View {
    @Environment(\.craftTheme) private var theme
    @Bindable var store: UserSettingsStore
    let onShowGoalInput: () -> Void
    let onShowResetAlert: () -> Void

    var body: some View {
        CraftCard(style: .outlined, padding: 0) {
            VStack(spacing: 0) {
                CraftListRow(
                    title: AppStrings.Settings.targetLevel,
                    iconName: "graduationcap.fill",
                    iconColor: theme.colors.brandPrimary,
                    iconBackgroundColor: theme.colors.surfaceSubtle
                ) {
                    CraftBadge("B2 Intermediate", symbol: .star, variant: .subtle, tone: .primary, size: .sm)
                }

                CraftDivider()

                CraftListRow(
                    title: AppStrings.Settings.appLanguage,
                    iconName: "globe",
                    iconColor: theme.colors.brandPrimary,
                    iconBackgroundColor: theme.colors.surfaceSubtle
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
                    title: AppStrings.Settings.dailyGoal,
                    iconName: "target",
                    iconColor: theme.colors.brandPrimary,
                    iconBackgroundColor: theme.colors.surfaceSubtle
                ) {
                    CraftStepper(
                        value: $store.dailyGoalCount,
                        range: 5...100,
                        step: 5,
                        unit: AppStrings.Common.wordUnit
                    )
                    .onTapGesture(count: 2) {
                        onShowGoalInput()
                    }
                }

                CraftDivider()

                CraftListRow(
                    title: AppStrings.Settings.reminders,
                    iconName: "bell.fill",
                    iconColor: theme.colors.brandPrimary,
                    iconBackgroundColor: theme.colors.surfaceSubtle
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
                        title: AppStrings.Settings.reminderTime,
                        iconName: "clock.fill",
                        iconColor: theme.colors.brandPrimary,
                        iconBackgroundColor: theme.colors.surfaceSubtle
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
                    title: AppStrings.Settings.resetSRS,
                    subtitle: AppStrings.Settings.resetSRSSubtitle,
                    iconName: "arrow.triangle.2.circlepath",
                    iconColor: theme.colors.statusDanger,
                    iconBackgroundColor: theme.colors.statusDanger.opacity(0.12),
                    showChevron: true,
                    action: onShowResetAlert
                ) {
                    EmptyView()
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
                    title: AppStrings.Settings.audioAccent,
                    iconName: "speaker.wave.2.fill",
                    iconColor: theme.colors.brandPrimary,
                    iconBackgroundColor: theme.colors.surfaceSubtle
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
                    CraftListRow(
                        title: AppStrings.Settings.speechSpeed,
                        iconName: "speedometer",
                        iconColor: theme.colors.brandPrimary,
                        iconBackgroundColor: theme.colors.surfaceSubtle
                    ) {
                        CraftBadge(
                            String(format: "%.2fx", store.ttsSpeed),
                            variant: .subtle,
                            tone: .warning,
                            size: .sm
                        )
                    }

                    Slider(value: $store.ttsSpeed, in: 0.5...1.5, step: 0.05)
                        .tint(theme.colors.brandPrimary)
                        .padding(.horizontal, theme.spacing.base)
                        .padding(.bottom, theme.spacing.xs)
                }

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
                CraftListRow(
                    title: AppStrings.Settings.appearanceMode,
                    iconName: "paintpalette.fill",
                    iconColor: theme.colors.brandPrimary,
                    iconBackgroundColor: theme.colors.surfaceSubtle
                ) {
                    CraftSegmentedControl(
                        selection: $store.appTheme,
                        options: [
                            CraftSegmentOption("dark", title: AppStrings.Settings.themeDarkText),
                            CraftSegmentOption("light", title: AppStrings.Settings.themeLightText),
                            CraftSegmentOption("system", title: AppStrings.Settings.themeSystemText)
                        ],
                        style: .flat
                    )
                    .frame(width: 200)
                }

                CraftDivider()

                CraftListRow(
                    title: AppStrings.Settings.haptics,
                    iconName: "hand.tap.fill",
                    iconColor: theme.colors.brandPrimary,
                    iconBackgroundColor: theme.colors.surfaceSubtle
                ) {
                    CraftSwitch(isOn: $store.isHapticsEnabled, activeTint: theme.colors.brandPrimary)
                }

                CraftDivider()

                CraftListRow(
                    title: AppStrings.Settings.soundEffects,
                    iconName: "waveform",
                    iconColor: theme.colors.brandPrimary,
                    iconBackgroundColor: theme.colors.surfaceSubtle
                ) {
                    CraftSwitch(isOn: $store.isSoundEffectsEnabled, activeTint: theme.colors.brandPrimary)
                }
            }
        }
    }
}

private struct SettingsDeveloperCard: View {
    @Environment(\.craftTheme) private var theme
    @Bindable var store: UserSettingsStore
    let onOpenCatalog: () -> Void

    var body: some View {
        CraftCard(style: .outlined, padding: 0) {
            VStack(spacing: 0) {
                CraftListRow(
                    title: AppStrings.Settings.themePreset,
                    subtitle: LocalizedStringKey(store.themePreset.displayName),
                    iconName: "wand.and.stars",
                    iconColor: theme.colors.brandPrimary,
                    iconBackgroundColor: theme.colors.surfaceSubtle
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
                    title: AppStrings.Settings.craftCatalog,
                    subtitle: AppStrings.Settings.craftCatalogSubtitle,
                    iconName: "square.grid.2x2.fill",
                    iconColor: theme.colors.brandPrimary,
                    iconBackgroundColor: theme.colors.surfaceSubtle,
                    showChevron: true,
                    action: onOpenCatalog
                ) {
                    EmptyView()
                }
            }
        }
    }
}

private struct SettingsAboutCard: View {
    @Environment(\.craftTheme) private var theme
    let cacheSizeString: String
    let onClearCache: () -> Void

    var body: some View {
        CraftCard(style: .outlined, padding: 0) {
            VStack(spacing: 0) {
                CraftListRow(
                    title: AppStrings.Settings.icloudSync,
                    iconName: "icloud.fill",
                    iconColor: theme.colors.textMuted,
                    iconBackgroundColor: theme.colors.surfaceSubtle
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
                    iconName: "trash.fill",
                    iconColor: theme.colors.textMuted,
                    iconBackgroundColor: theme.colors.surfaceSubtle,
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
                    title: AppStrings.Settings.appVersion,
                    iconName: "info.circle.fill",
                    iconColor: theme.colors.textMuted,
                    iconBackgroundColor: theme.colors.surfaceSubtle
                ) {
                    CraftText(
                        "v1.2.0 (Build 42)",
                        style: .label,
                        color: theme.colors.textMuted
                    )
                }
            }
        }
    }
}
