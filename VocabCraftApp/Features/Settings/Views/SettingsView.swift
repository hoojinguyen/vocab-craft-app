import SwiftUI

public struct SettingsView: View {
    @Bindable public var viewModel: SettingsViewModel
    @State private var showResetAlert: Bool = false
    @State private var showGoalInputAlert: Bool = false
    @State private var goalInputText: String = ""

    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        List {
            // Profile Header
            Section {
                ProfileHeaderCard()
            }
            .listRowBackground(Color.vocabSurfaceCard)

            // Learning & SRS Section
            Section(header: sectionHeader(AppStrings.Settings.sectionLearningSRS)) {
                SettingsRowView(
                    iconName: "target",
                    iconColor: .vocabHeroAccent,
                    title: AppStrings.Settings.dailyGoal
                ) {
                    HStack(spacing: 0) {
                        Button(action: {
                            if viewModel.store.dailyGoalCount > 5 {
                                viewModel.store.dailyGoalCount -= 5
                            }
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.vocabHeroAccent)
                                .frame(width: 32, height: 30)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.borderless)

                        Divider()
                            .frame(height: 14)
                            .opacity(0.35)

                        Button(action: {
                            goalInputText = "\(viewModel.store.dailyGoalCount)"
                            showGoalInputAlert = true
                        }) {
                            (Text("\(viewModel.store.dailyGoalCount) ") + Text(AppStrings.Common.wordUnit))
                                .font(.caption.weight(.bold))
                                .fontDesign(.rounded)
                                .monospacedDigit()
                                .foregroundColor(.vocabHeroAccent)
                                .frame(minWidth: 50)
                                .frame(height: 30)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.borderless)

                        Divider()
                            .frame(height: 14)
                            .opacity(0.35)

                        Button(action: {
                            if viewModel.store.dailyGoalCount < 100 {
                                viewModel.store.dailyGoalCount += 5
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.vocabHeroAccent)
                                .frame(width: 32, height: 30)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.borderless)
                    }
                    .background(Color.vocabHeroAccent.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.vocabHeroAccent.opacity(0.25), lineWidth: 0.8))
                }

                SettingsRowView(
                    iconName: "bell.fill",
                    iconColor: .vocabHeroAccent,
                    title: AppStrings.Settings.reminderNotification
                ) {
                    Toggle("", isOn: Binding(
                        get: { viewModel.store.isNotificationEnabled },
                        set: { newValue in
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                viewModel.store.isNotificationEnabled = newValue
                            }
                        }
                    ))
                }

                if viewModel.store.isNotificationEnabled {
                    SettingsRowView(
                        iconName: "clock.fill",
                        iconColor: .vocabHeroAccent,
                        title: AppStrings.Settings.reminderTime
                    ) {
                        DatePicker(
                            "",
                            selection: $viewModel.store.notificationTime,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .tint(.vocabHeroAccent)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Button(role: .destructive, action: {
                    showResetAlert = true
                }) {
                    SettingsRowView(
                        iconName: "arrow.triangle.2.circlepath",
                        iconColor: .vocabCoral,
                        title: AppStrings.Settings.resetSRS,
                        subtitle: AppStrings.Settings.resetSRSSubtitle
                    ) {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.vocabCoral.opacity(0.7))
                    }
                }
            }
            .listRowBackground(Color.vocabSurfaceCard)

            // Audio & TTS Section
            Section(header: sectionHeader(AppStrings.Settings.sectionAudioTTS)) {
                SettingsRowView(
                    iconName: "speaker.wave.2.fill",
                    iconColor: .vocabPeach,
                    title: AppStrings.Settings.englishVoice
                ) {
                    Picker("", selection: $viewModel.store.ttsVoiceGender) {
                        Text("US (Mỹ)").tag("US")
                        Text("UK (Anh)").tag("UK")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }

                VStack(alignment: .leading, spacing: 8) {
                    SettingsRowView(
                        iconName: "speedometer",
                        iconColor: .vocabPeach,
                        title: AppStrings.Settings.speechSpeed
                    ) {
                        Text(String(format: "%.2fx", viewModel.store.ttsSpeed))
                            .font(.caption.weight(.bold))
                            .fontDesign(.rounded)
                            .monospacedDigit()
                            .foregroundColor(.vocabPeach)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.vocabPeach.opacity(0.14))
                                    .overlay(Capsule().stroke(Color.vocabPeach.opacity(0.25), lineWidth: 0.8))
                            )
                    }

                    Slider(value: $viewModel.store.ttsSpeed, in: 0.5...1.5, step: 0.05)
                        .tint(.vocabPeach)
                        .padding(.horizontal, 2)
                }
                .padding(.vertical, 2)

                Button(action: {
                    viewModel.playAudioPreview()
                }) {
                    SettingsRowView(
                        iconName: viewModel.isPlayingAudio ? "speaker.wave.3.fill" : "play.circle.fill",
                        iconColor: .vocabPeach,
                        title: viewModel.isPlayingAudio ? AppStrings.Settings.playingAudio : AppStrings.Settings.testTTS
                    ) {
                        HStack(spacing: 6) {
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
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.vocabMuted)
                        }
                    }
                }
            }
            .listRowBackground(Color.vocabSurfaceCard)

            // Appearance & Experience Section
            Section(header: sectionHeader(AppStrings.Settings.sectionAppearance)) {
                SettingsRowView(
                    iconName: "paintpalette.fill",
                    iconColor: .vocabLavender,
                    title: AppStrings.Settings.appTheme
                ) {
                    Picker("", selection: $viewModel.store.appTheme) {
                        Text(AppStrings.Settings.themeDark).tag("dark")
                        Text(AppStrings.Settings.themeLight).tag("light")
                        Text(AppStrings.Settings.themeSystem).tag("system")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 170)
                }

                SettingsRowView(
                    iconName: "hand.tap.fill",
                    iconColor: .vocabLavender,
                    title: AppStrings.Settings.haptics
                ) {
                    Toggle("", isOn: $viewModel.store.isHapticsEnabled)
                }

                SettingsRowView(
                    iconName: "waveform",
                    iconColor: .vocabLavender,
                    title: AppStrings.Settings.soundEffects
                ) {
                    Toggle("", isOn: $viewModel.store.isSoundEffectsEnabled)
                }
            }
            .listRowBackground(Color.vocabSurfaceCard)

            // Language & Region Section
            Section(header: sectionHeader(AppStrings.Settings.sectionLanguage)) {
                SettingsRowView(
                    iconName: "globe",
                    iconColor: .vocabHeroTeal,
                    title: AppStrings.Settings.appLanguage
                ) {
                    Picker("", selection: $viewModel.store.appLanguage) {
                        Text(AppStrings.Settings.langSystem).tag("system")
                        Text(AppStrings.Settings.langVietnamese).tag("vi")
                        Text(AppStrings.Settings.langEnglish).tag("en")
                    }
                    .pickerStyle(.menu)
                    .tint(.vocabHeroTeal)
                }
            }
            .listRowBackground(Color.vocabSurfaceCard)

            // App Data & About Section
            Section(header: sectionHeader(AppStrings.Settings.sectionAppData)) {
                SettingsRowView(
                    iconName: "icloud.fill",
                    iconColor: .vocabMuted,
                    title: AppStrings.Settings.icloudSync
                ) {
                    Text(AppStrings.Settings.synced)
                        .font(.caption2.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundColor(.vocabMint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.vocabMint.opacity(0.14))
                                .overlay(Capsule().stroke(Color.vocabMint.opacity(0.25), lineWidth: 0.8))
                        )
                }

                Button(action: {
                    viewModel.clearCache()
                }) {
                    SettingsRowView(
                        iconName: "trash.fill",
                        iconColor: .vocabMuted,
                        title: AppStrings.Settings.clearCache
                    ) {
                        Text(viewModel.cacheSizeString)
                            .font(.caption.weight(.semibold))
                            .fontDesign(.rounded)
                            .monospacedDigit()
                            .foregroundColor(.vocabMuted)
                    }
                }

                SettingsRowView(
                    iconName: "info.circle.fill",
                    iconColor: .vocabMuted,
                    title: AppStrings.Settings.appVersion
                ) {
                    Text("v1.2.0 (Build 42)")
                        .font(.footnote.weight(.medium))
                        .fontDesign(.rounded)
                        .foregroundColor(.vocabMuted)
                }
            }
            .listRowBackground(Color.vocabSurfaceCard)
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.sidebar)
        #endif
        .scrollContentBackground(.hidden)
        .background(Color.vocabCanvas)
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
                viewModel.resetSRSProgress()
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
