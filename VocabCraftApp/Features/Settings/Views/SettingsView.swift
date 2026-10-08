// swiftlint:disable file_length
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

                    // 4. AI Configuration Section
                    aiSection

                    // 4.1 On-Device Models
                    onDeviceModelsSection

                    // 5. Appearance & Feedback Section
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
        .sensoryFeedback(.selection, trigger: viewModel.store.roleplayVoiceId) { _, _ in viewModel.store.isHapticsEnabled }
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
                ttsService: viewModel.ttsService,
                isPlayingPreview: viewModel.isPlayingRoleplayAudio,
                onPlayPreview: {
                    viewModel.playRoleplayVoicePreview()
                }
            )
        }
    }

    private var aiSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            sectionHeader(AppStrings.Settings.sectionAI)
            SettingsAICard(store: viewModel.store)
        }
    }

    private var onDeviceModelsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            sectionHeader(AppStrings.Settings.modelsTitle)
            SettingsOnDeviceModelsCard()
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

@MainActor
private struct SettingsAudioCard: View {
    @Environment(\.craftTheme) private var theme
    @Bindable var store: UserSettingsStore
    let ttsService: any TextToSpeechProtocol
    let isPlayingPreview: Bool
    let onPlayPreview: () -> Void

    @State private var showVoicePicker: Bool = false

    private var currentProfile: RoleplayVoiceProfile {
        RoleplayVoiceProfileCatalog.profile(for: store.roleplayVoiceId)
            ?? RoleplayVoiceProfileCatalog.defaultProfile
    }

    var body: some View {
        CraftCard(style: .outlined, padding: 0) {
            VStack(spacing: 0) {
                // 1. Active Voice Selector Row
                CraftListRow(
                    title: AppStrings.Settings.voiceCurrentProfile,
                    subtitle: store.roleplayVoiceId == RoleplayVoiceProfileCatalog.defaultProfile.id ? nil :
                                (currentProfile.engine == .geminiNeural ? AppStrings.Settings.voiceQualityGemini :
                                currentProfile.engine == .kokoroNeural ? AppStrings.Settings.voiceQualityKokoro :
                                AppStrings.Settings.voiceQualityApple),
                    showChevron: true,
                    action: {
                        showVoicePicker = true
                    }
                ) {
                    if store.roleplayVoiceId == RoleplayVoiceProfileCatalog.defaultProfile.id {
                        CraftText(
                            AppStrings.Settings.voiceAutoPersona,
                            style: .bodyMedium,
                            color: theme.colors.textSecondary
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    } else {
                        Text(verbatim: currentProfile.displayNameKey)
                            .font(theme.typography.bodyMedium)
                            .foregroundStyle(theme.colors.textSecondary)
                            .lineLimit(1)
                    }
                }

                CraftDivider()

                // 3. Speech Rate Slider
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        CraftText(
                            AppStrings.Settings.voiceSpeed,
                            style: .headline,
                            color: theme.colors.textPrimary
                        )

                        Spacer()

                        CraftBadge(
                            String(format: "%.2fx", store.roleplaySpeechRate),
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

                        Slider(value: $store.roleplaySpeechRate, in: 0.75...1.25, step: 0.05)
                            .tint(theme.colors.brandPrimary)

                        Image(systemName: "hare.fill")
                            .foregroundStyle(theme.colors.textMuted)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, theme.spacing.base)
                    .padding(.bottom, theme.spacing.sm)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text(AppStrings.Settings.voiceSpeed))
                .accessibilityValue(Text(String(format: "%.2fx", store.roleplaySpeechRate)))

                CraftDivider()

                // 4. Speech Pitch Slider
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        CraftText(
                            AppStrings.Settings.voicePitch,
                            style: .headline,
                            color: theme.colors.textPrimary
                        )

                        Spacer()

                        CraftBadge(
                            String(format: "%.2fx", store.roleplaySpeechPitch),
                            variant: .subtle,
                            tone: .primary,
                            size: .sm
                        )
                    }
                    .padding(.horizontal, theme.spacing.base)
                    .padding(.top, theme.spacing.sm)

                    HStack(spacing: theme.spacing.sm) {
                        CraftIcon(.waveform, size: .sm, color: theme.colors.textMuted)
                            .accessibilityHidden(true)

                        Slider(value: $store.roleplaySpeechPitch, in: 0.85...1.15, step: 0.05)
                            .tint(theme.colors.brandPrimary)

                        CraftIcon(.sparkles, size: .sm, color: theme.colors.textMuted)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, theme.spacing.base)
                    .padding(.bottom, theme.spacing.sm)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text(AppStrings.Settings.voicePitch))
                .accessibilityValue(Text(String(format: "%.2fx", store.roleplaySpeechPitch)))

                CraftDivider()

                // 5. Play Preview Button Row
                CraftListRow(
                    title: isPlayingPreview ? AppStrings.Settings.voicePreviewing : AppStrings.Settings.voicePreviewButton,
                    iconName: isPlayingPreview ? "speaker.wave.3.fill" : "play.circle.fill",
                    iconColor: theme.colors.brandPrimary,
                    iconBackgroundColor: theme.colors.surfaceSubtle,
                    showChevron: !isPlayingPreview,
                    action: onPlayPreview
                ) {
                    if isPlayingPreview {
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
        .sheet(isPresented: $showVoicePicker) {
            RoleplayVoicePickerSheet(store: store, ttsService: ttsService)
        }
    }
}

@MainActor
public struct SettingsAICard: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.appContainer) private var appContainer
    @Bindable public var store: UserSettingsStore

    @State private var showConfigSheet: Bool = false
    @State private var isGeminiSecure: Bool = true
    @State private var isGroqSecure: Bool = true

    @FocusState private var isGeminiFieldFocused: Bool
    @FocusState private var isGroqFieldFocused: Bool

    public init(store: UserSettingsStore) {
        self.store = store
    }

    public var body: some View {
        CraftCard(style: .outlined, padding: 0) {
            VStack(spacing: 0) {
                // Active AI Pack
                Button {
                    showConfigSheet = true
                } label: {
                    let activePack = appContainer.aiPackRegistry.activePack
                    let displayName = activePack?.displayName ?? appContainer.aiPackRegistry.activePackId.rawValue
                    let (statusKey, tone): (LocalizedStringKey, CraftBadgeTone) = {
                        guard let status = activePack?.status else {
                            return (AppStrings.AIPack.statusReady, .neutral)
                        }
                        return statusBadgeInfo(for: status)
                    }()

                    CraftListRow(
                        title: AppStrings.AIPack.activePackTitle,
                        subtitle: LocalizedStringKey(stringLiteral: displayName)
                    ) {
                        HStack(spacing: theme.spacing.xs) {
                            CraftBadge(
                                statusKey,
                                variant: .subtle,
                                tone: tone,
                                size: .sm
                            )

                            CraftIcon(
                                .chevronRight,
                                size: .sm,
                                color: theme.colors.textMuted
                            )
                        }
                    }
                }
                .buttonStyle(.plain)

                CraftDivider()

                // Gemini Key
                CraftListRow(
                    title: AppStrings.Settings.aiGeminiKeyTitle
                ) {
                    CraftBadge(
                        store.isGeminiApiKeyConfigured
                            ? AppStrings.AIPack.statusReady
                            : AppStrings.AIPack.statusNeedsKey,
                        symbol: store.isGeminiApiKeyConfigured ? .check : .sparkles,
                        variant: .subtle,
                        tone: store.isGeminiApiKeyConfigured ? .success : .warning,
                        size: .sm
                    )
                }

                CraftDivider()

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack(spacing: theme.spacing.xs) {
                        Group {
                            if isGeminiSecure {
                                SecureField(
                                    AppStrings.Settings.aiGeminiKeyPlaceholder,
                                    text: $store.geminiApiKey
                                )
                            } else {
                                TextField(
                                    AppStrings.Settings.aiGeminiKeyPlaceholder,
                                    text: $store.geminiApiKey
                                )
                            }
                        }
                        .focused($isGeminiFieldFocused)
                        .onSubmit {
                            store.geminiApiKey = store.geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        .font(theme.typography.bodyMedium)
                        .foregroundStyle(theme.colors.textPrimary)
                        .tint(theme.colors.brandPrimary)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif

                        if !store.geminiApiKey.isEmpty {
                            CraftIconButton(
                                symbol: .clear,
                                size: .sm,
                                variant: .ghost,
                                accessibilityLabelKey: AppStrings.Settings.aiClearKey
                            ) {
                                store.geminiApiKey = ""
                            }
                        }

                        CraftIconButton(
                            symbol: isGeminiSecure ? .eye : .eyeSlash,
                            size: .sm,
                            variant: .ghost,
                            accessibilityLabelKey: isGeminiSecure ? AppStrings.Settings.aiShowKey : AppStrings.Settings.aiHideKey
                        ) {
                            isGeminiSecure.toggle()
                        }
                    }
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.vertical, theme.spacing.xs)
                    .background(theme.colors.surfaceSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
                    .onChange(of: isGeminiFieldFocused) { _, isFocused in
                        if !isFocused {
                            store.geminiApiKey = store.geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    }

                    Text(AppStrings.Settings.aiGeminiHelpText)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }
                .padding(theme.spacing.md)

                CraftDivider()

                // Groq Key
                CraftListRow(
                    title: AppStrings.Settings.aiGroqKeyTitle
                ) {
                    CraftBadge(
                        store.isGroqApiKeyConfigured
                            ? AppStrings.Settings.aiGroqStatusActive
                            : AppStrings.AIPack.statusNeedsKey,
                        symbol: store.isGroqApiKeyConfigured ? .check : .sparkles,
                        variant: .subtle,
                        tone: store.isGroqApiKeyConfigured ? .success : .neutral,
                        size: .sm
                    )
                }

                CraftDivider()

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack(spacing: theme.spacing.xs) {
                        Group {
                            if isGroqSecure {
                                SecureField(
                                    AppStrings.Settings.aiGroqKeyPlaceholder,
                                    text: $store.groqApiKey
                                )
                            } else {
                                TextField(
                                    AppStrings.Settings.aiGroqKeyPlaceholder,
                                    text: $store.groqApiKey
                                )
                            }
                        }
                        .focused($isGroqFieldFocused)
                        .onSubmit {
                            store.groqApiKey = store.groqApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        .font(theme.typography.bodyMedium)
                        .foregroundStyle(theme.colors.textPrimary)
                        .tint(theme.colors.brandPrimary)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif

                        if !store.groqApiKey.isEmpty {
                            CraftIconButton(
                                symbol: .clear,
                                size: .sm,
                                variant: .ghost,
                                accessibilityLabelKey: AppStrings.Settings.aiClearKey
                            ) {
                                store.groqApiKey = ""
                            }
                        }

                        CraftIconButton(
                            symbol: isGroqSecure ? .eye : .eyeSlash,
                            size: .sm,
                            variant: .ghost,
                            accessibilityLabelKey: isGroqSecure ? AppStrings.Settings.aiShowKey : AppStrings.Settings.aiHideKey
                        ) {
                            isGroqSecure.toggle()
                        }
                    }
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.vertical, theme.spacing.xs)
                    .background(theme.colors.surfaceSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
                    .onChange(of: isGroqFieldFocused) { _, isFocused in
                        if !isFocused {
                            store.groqApiKey = store.groqApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    }

                    Text(AppStrings.Settings.aiGroqHelpText)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }
                .padding(theme.spacing.md)
            }
        }
        .sheet(isPresented: $showConfigSheet) {
            AIConfigSheet(store: store)
        }
    }

    private func statusBadgeInfo(for status: AIPackStatus) -> (LocalizedStringKey, CraftBadgeTone) {
        switch status {
        case .ready:
            return (AppStrings.AIPack.statusReady, .success)
        case .needsApiKey:
            return (AppStrings.AIPack.statusNeedsKey, .warning)
        case .needsDownload, .partiallyReady:
            return (AppStrings.AIPack.statusNeedsDownload, .primary)
        case .unavailable:
            return (AppStrings.AIPack.statusUnavailable, .neutral)
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

private struct SettingsOnDeviceModelsCard: View {
    @Environment(\.craftTheme) private var theme
    @Bindable private var modelManager = OnDemandAIModelManager.shared

    var body: some View {
        CraftCard(style: .outlined, padding: theme.spacing.none) {
            VStack(spacing: theme.spacing.none) {
                modelRow(type: .kokoro)
                CraftDivider()
                modelRow(type: .whisper)
            }
        }
        .onAppear {
            modelManager.refreshStatus()
        }
    }

    @ViewBuilder
    private func modelRow(type: AIModelType) -> some View {
        let isReady = modelManager.isModelReady(type)
        let state = modelManager.state(for: type)

        CraftListRow(
            title: LocalizedStringKey(type.displayName),
            subtitle: LocalizedStringKey(subtitle(for: type, state: state))
        ) {
            if isReady {
                CraftButton(
                    AppStrings.Settings.modelsFreeSpace,
                    variant: .ghost,
                    size: .sm
                ) {
                    try? modelManager.deleteModel(type)
                }
                .tint(theme.colors.statusDanger)
            } else if case .downloading(let progress) = state {
                HStack(spacing: theme.spacing.xs) {
                    CraftProgressBar(progress: progress, height: 4)
                        .frame(width: theme.spacing.xxl)
                    Text(progress, format: .percent.precision(.fractionLength(0)))
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textMuted)
                }
            } else {
                CraftButton(
                    AppStrings.AIModelDownload.btnDownload,
                    variant: .secondary,
                    size: .sm
                ) {
                    let remoteURL = type == .kokoro
                        ? URL(string: "https://huggingface.co/hexgrad/Kokoro-82M/resolve/main/kokoro-v0_19.pth")!
                        : URL(string: "https://huggingface.co/argmaxinc/whisperkit-coreml/resolve/main/openai_whisper-tiny.en/whisperkit.zip")!
                    modelManager.startDownload(for: type, remoteURL: remoteURL)
                }
            }
        }
    }

    private func subtitle(for type: AIModelType, state: AIModelDownloadState) -> String {
        switch state {
        case .ready: return AppStrings.AIModelDownload.statusReady(type.estimatedSizeMB)
        case .downloading: return AppStrings.AIModelDownload.statusDownloadingText
        default: return AppStrings.AIModelDownload.statusSize(type.estimatedSizeMB)
        }
    }
}
