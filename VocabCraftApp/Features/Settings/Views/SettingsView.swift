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
            List {
            // Profile Header
            Section {
                ProfileHeaderCard()
            }
            .listRowBackground(theme.colors.surfaceCard)

            // Learning & SRS Section
            Section(header: sectionHeader(AppStrings.Settings.sectionLearningSRS)) {
                CraftListRow(
                    title: String(localized: "settings.dailyGoal", defaultValue: "Daily Goal", bundle: .module),
                    iconName: "target",
                    iconColor: .vocabHeroAccent,
                    iconBackgroundColor: Color.vocabHeroAccent.opacity(0.15)
                ) {
                    CraftStepper(
                        value: $viewModel.store.dailyGoalCount,
                        range: 5...100,
                        step: 5,
                        unit: String(localized: "common.wordUnit", defaultValue: "words", bundle: .module)
                    )
                    .onTapGesture(count: 2) {
                        goalInputText = "\(viewModel.store.dailyGoalCount)"
                        showGoalInputAlert = true
                    }
                }
                .listRowInsets(EdgeInsets())

                CraftListRow(
                    title: String(localized: "settings.reminderNotification", defaultValue: "Review Reminders", bundle: .module),
                    iconName: "bell.fill",
                    iconColor: .vocabHeroAccent,
                    iconBackgroundColor: Color.vocabHeroAccent.opacity(0.15)
                ) {
                    Toggle("", isOn: Binding(
                        get: { viewModel.store.isNotificationEnabled },
                        set: { newValue in
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                viewModel.store.isNotificationEnabled = newValue
                            }
                        }
                    ))
                    .labelsHidden()
                    .toggleStyle(.craft)
                }
                .listRowInsets(EdgeInsets())

                if viewModel.store.isNotificationEnabled {
                    CraftListRow(
                        title: String(localized: "settings.reminderTime", defaultValue: "Reminder Time", bundle: .module),
                        iconName: "clock.fill",
                        iconColor: .vocabHeroAccent,
                        iconBackgroundColor: Color.vocabHeroAccent.opacity(0.15)
                    ) {
                        DatePicker(
                            "",
                            selection: $viewModel.store.notificationTime,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .tint(.vocabHeroAccent)
                    }
                    .listRowInsets(EdgeInsets())
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                CraftListRow(
                    title: String(localized: "settings.resetSRS", defaultValue: "Reset SRS Progress", bundle: .module),
                    subtitle: String(localized: "settings.resetSRSSubtitle", defaultValue: "Reset all studied words", bundle: .module),
                    iconName: "arrow.triangle.2.circlepath",
                    iconColor: .vocabCoral,
                    iconBackgroundColor: Color.vocabCoral.opacity(0.15),
                    showChevron: true,
                    action: {
                        showResetAlert = true
                    }
                ) {
                    EmptyView()
                }
                .listRowInsets(EdgeInsets())
            }
            .listRowBackground(theme.colors.surfaceCard)

            // Audio & TTS Section
            Section(header: sectionHeader(AppStrings.Settings.sectionAudioTTS)) {
                CraftListRow(
                    title: String(localized: "settings.englishVoice", defaultValue: "English TTS Accent", bundle: .module),
                    iconName: "speaker.wave.2.fill",
                    iconColor: .vocabPeach,
                    iconBackgroundColor: Color.vocabPeach.opacity(0.15)
                ) {
                    Picker("", selection: $viewModel.store.ttsVoiceGender) {
                        Text(AppStrings.Settings.voiceUS).tag("US")
                        Text(AppStrings.Settings.voiceUK).tag("UK")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
                .listRowInsets(EdgeInsets())

                VStack(alignment: .leading, spacing: 8) {
                    CraftListRow(
                        title: String(localized: "settings.speechSpeed", defaultValue: "Speech Speed", bundle: .module),
                        iconName: "speedometer",
                        iconColor: .vocabPeach,
                        iconBackgroundColor: Color.vocabPeach.opacity(0.15)
                    ) {
                        CraftBadge(
                            String(format: "%.2fx", viewModel.store.ttsSpeed),
                            variant: .subtle,
                            tone: .warning,
                            size: .sm
                        )
                    }

                    Slider(value: $viewModel.store.ttsSpeed, in: 0.5...1.5, step: 0.05)
                        .tint(.vocabPeach)
                        .padding(.horizontal, theme.spacing.base)
                }
                .padding(.vertical, 2)
                .listRowInsets(EdgeInsets())

                CraftListRow(
                    title: viewModel.isPlayingAudio
                        ? String(localized: "settings.playingAudio", defaultValue: "Playing preview...", bundle: .module)
                        : String(localized: "settings.testTTS", defaultValue: "Test Speech Pronunciation", bundle: .module),
                    iconName: viewModel.isPlayingAudio ? "speaker.wave.3.fill" : "play.circle.fill",
                    iconColor: .vocabPeach,
                    iconBackgroundColor: Color.vocabPeach.opacity(0.15),
                    showChevron: !viewModel.isPlayingAudio,
                    action: {
                        viewModel.playAudioPreview()
                    }
                ) {
                    if viewModel.isPlayingAudio {
                        HStack(spacing: 2) {
                            ForEach(0..<4) { i in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.vocabPeach)
                                    .frame(width: 2.5, height: CGFloat([10, 18, 14, 8][i]))
                            }
                        }
                        .padding(.trailing, 2)
                    }
                }
                .listRowInsets(EdgeInsets())
            }
            .listRowBackground(theme.colors.surfaceCard)

            // Appearance & Experience Section
            Section(header: sectionHeader(AppStrings.Settings.sectionAppearance)) {
                CraftListRow(
                    title: String(localized: "settings.appTheme", defaultValue: "App Theme", bundle: .module),
                    iconName: "paintpalette.fill",
                    iconColor: .vocabLavender,
                    iconBackgroundColor: Color.vocabLavender.opacity(0.15)
                ) {
                    Picker("", selection: $viewModel.store.appTheme) {
                        Text(AppStrings.Settings.themeDark).tag("dark")
                        Text(AppStrings.Settings.themeLight).tag("light")
                        Text(AppStrings.Settings.themeSystem).tag("system")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 170)
                }
                .listRowInsets(EdgeInsets())

                CraftListRow(
                    title: String(localized: "settings.haptics", defaultValue: "Haptic Feedback", bundle: .module),
                    iconName: "hand.tap.fill",
                    iconColor: .vocabLavender,
                    iconBackgroundColor: Color.vocabLavender.opacity(0.15)
                ) {
                    Toggle("", isOn: $viewModel.store.isHapticsEnabled)
                        .labelsHidden()
                        .toggleStyle(.craft)
                }
                .listRowInsets(EdgeInsets())

                CraftListRow(
                    title: String(localized: "settings.soundEffects", defaultValue: "Sound Effects", bundle: .module),
                    iconName: "waveform",
                    iconColor: .vocabLavender,
                    iconBackgroundColor: Color.vocabLavender.opacity(0.15)
                ) {
                    Toggle("", isOn: $viewModel.store.isSoundEffectsEnabled)
                        .labelsHidden()
                        .toggleStyle(.craft)
                }
                .listRowInsets(EdgeInsets())
            }
            .listRowBackground(theme.colors.surfaceCard)

            // Language & Region Section
            Section(header: sectionHeader(AppStrings.Settings.sectionLanguage)) {
                CraftListRow(
                    title: String(localized: "settings.appLanguage", defaultValue: "App Language", bundle: .module),
                    iconName: "globe",
                    iconColor: .vocabHeroTeal,
                    iconBackgroundColor: Color.vocabHeroTeal.opacity(0.15)
                ) {
                    Picker("", selection: $viewModel.store.appLanguage) {
                        Text(AppStrings.Settings.langSystem).tag("system")
                        Text(AppStrings.Settings.langVietnamese).tag("vi")
                        Text(AppStrings.Settings.langEnglish).tag("en")
                    }
                    .pickerStyle(.menu)
                    .tint(.vocabHeroTeal)
                }
                .listRowInsets(EdgeInsets())
            }
            .listRowBackground(theme.colors.surfaceCard)

            // App Data & About Section
            Section(header: sectionHeader(AppStrings.Settings.sectionAppData)) {
                CraftListRow(
                    title: String(localized: "settings.icloudSync", defaultValue: "iCloud Sync", bundle: .module),
                    iconName: "icloud.fill",
                    iconColor: .vocabMuted,
                    iconBackgroundColor: Color.vocabMuted.opacity(0.15)
                ) {
                    CraftBadge(
                        String(localized: "settings.synced", defaultValue: "Synced", bundle: .module),
                        iconName: "checkmark",
                        variant: .subtle,
                        tone: .success,
                        size: .sm
                    )
                }
                .listRowInsets(EdgeInsets())

                CraftListRow(
                    title: String(localized: "settings.clearCache", defaultValue: "Clear Cache", bundle: .module),
                    iconName: "trash.fill",
                    iconColor: .vocabMuted,
                    iconBackgroundColor: Color.vocabMuted.opacity(0.15),
                    action: {
                        viewModel.clearCache()
                    }
                ) {
                    CraftText(
                        viewModel.cacheSizeString,
                        style: .label,
                        color: theme.colors.textMuted
                    )
                }
                .listRowInsets(EdgeInsets())

                CraftListRow(
                    title: String(localized: "settings.appVersion", defaultValue: "App Version", bundle: .module),
                    iconName: "info.circle.fill",
                    iconColor: .vocabMuted,
                    iconBackgroundColor: Color.vocabMuted.opacity(0.15)
                ) {
                    CraftText(
                        "v1.2.0 (Build 42)",
                        style: .label,
                        color: theme.colors.textMuted
                    )
                }
                .listRowInsets(EdgeInsets())
            }
            .listRowBackground(theme.colors.surfaceCard)

            // Developer & Design System Section
            Section(header: sectionHeader(AppStrings.Settings.sectionDeveloper)) {
                CraftListRow(
                    title: String(localized: "settings.craftCatalog", defaultValue: "CraftUIKit Catalog", bundle: .module),
                    subtitle: String(localized: "settings.craftCatalogSubtitle", defaultValue: "Interactive component gallery & tokens", bundle: .module),
                    iconName: "paintpalette.fill",
                    iconColor: .vocabHeroTeal,
                    iconBackgroundColor: Color.vocabHeroTeal.opacity(0.15),
                    showChevron: true,
                    action: {
                        showCatalogSheet = true
                    }
                ) {
                    EmptyView()
                }
                .listRowInsets(EdgeInsets())
            }
            .id("developer_section")
            .listRowBackground(theme.colors.surfaceCard)
        }
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
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.sidebar)
        #endif
        .scrollContentBackground(.hidden)
        .background(theme.colors.canvasBackground)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 115)
        }
        .sensoryFeedback(.selection, trigger: viewModel.store.dailyGoalCount) { _, _ in viewModel.store.isHapticsEnabled }
        .sensoryFeedback(.selection, trigger: viewModel.store.ttsVoiceGender) { _, _ in viewModel.store.isHapticsEnabled }
        .sensoryFeedback(.selection, trigger: viewModel.store.appTheme) { _, _ in viewModel.store.isHapticsEnabled }
        .sensoryFeedback(.selection, trigger: viewModel.store.appLanguage) { _, _ in viewModel.store.isHapticsEnabled }
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.store.isNotificationEnabled) { _, _ in viewModel.store.isHapticsEnabled }
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.store.isHapticsEnabled) { _, _ in viewModel.store.isHapticsEnabled }
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.store.isSoundEffectsEnabled) { _, _ in viewModel.store.isHapticsEnabled }
        .alert(AppStrings.Settings.inputGoalTitle, isPresented: $showGoalInputAlert) {
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
            Text(AppStrings.Settings.inputGoalMessage)
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

    private func sectionHeader(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.caption.bold().smallCaps())
            .foregroundColor(.vocabMuted)
    }
}
