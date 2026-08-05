import SwiftUI

public struct SettingsView: View {
    @Bindable public var viewModel: SettingsViewModel
    @State private var showResetAlert: Bool = false

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
            Section(header: sectionHeader("Học tập & Ôn tập (SRS)")) {
                SettingsRowView(
                    iconName: "target",
                    iconColor: .vocabHeroAccent,
                    title: "Mục tiêu từ/ngày"
                ) {
                    HStack(spacing: 8) {
                        Text("\(viewModel.store.dailyGoalCount) từ")
                            .font(.callout.weight(.bold))
                            .fontDesign(.rounded)
                            .monospacedDigit()
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .foregroundColor(.vocabHeroAccent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.vocabHeroAccent.opacity(0.12))
                            .clipShape(Capsule())

                        Stepper("", value: $viewModel.store.dailyGoalCount, in: 5...50, step: 5)
                            .labelsHidden()
                    }
                }

                SettingsRowView(
                    iconName: "bell.fill",
                    iconColor: .vocabHeroAccent,
                    title: "Nhắc nhở ôn tập"
                ) {
                    Toggle("", isOn: Binding(
                        get: { viewModel.store.isNotificationEnabled },
                        set: { newValue in
                            withAnimation(.smooth) {
                                viewModel.store.isNotificationEnabled = newValue
                            }
                        }
                    ))
                }

                if viewModel.store.isNotificationEnabled {
                    DatePicker(
                        "Giờ nhắc nhở",
                        selection: $viewModel.store.notificationTime,
                        displayedComponents: .hourAndMinute
                    )
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.vocabInk)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Button(role: .destructive, action: {
                    showResetAlert = true
                }) {
                    SettingsRowView(
                        iconName: "arrow.triangle.2.circlepath",
                        iconColor: .vocabCoral,
                        title: "Reset tiến trình SRS"
                    ) {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.vocabMuted)
                    }
                }
            }
            .listRowBackground(Color.vocabSurfaceCard)

            // Audio & TTS Section
            Section(header: sectionHeader("Âm thanh & Phát âm")) {
                SettingsRowView(
                    iconName: "speaker.wave.2.fill",
                    iconColor: .vocabPeach,
                    title: "Giọng đọc tiếng Anh"
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
                        title: "Tốc độ đọc"
                    ) {
                        Text(String(format: "%.2fx", viewModel.store.ttsSpeed))
                            .font(.footnote.weight(.bold))
                            .fontDesign(.rounded)
                            .monospacedDigit()
                            .foregroundColor(.vocabPeach)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.vocabPeach.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Slider(value: $viewModel.store.ttsSpeed, in: 0.5...1.0, step: 0.05)
                        .tint(.vocabPeach)
                }

                Button(action: {
                    viewModel.playAudioPreview()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.isPlayingAudio ? "speaker.wave.3.fill" : "play.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.vocabPeach)
                            .symbolEffect(.bounce, value: viewModel.isPlayingAudio)
                        
                        Text(viewModel.isPlayingAudio ? "Đang phát mẫu âm thanh..." : "Nghe thử phát âm TTS")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.vocabPeach)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .listRowBackground(Color.vocabSurfaceCard)

            // Appearance & Experience Section
            Section(header: sectionHeader("Giao diện & Trải nghiệm")) {
                SettingsRowView(
                    iconName: "paintpalette.fill",
                    iconColor: .vocabLavender,
                    title: "Giao diện App"
                ) {
                    Picker("", selection: $viewModel.store.appTheme) {
                        Text("Tối").tag("dark")
                        Text("Sáng").tag("light")
                        Text("Auto").tag("system")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }

                SettingsRowView(
                    iconName: "hand.tap.fill",
                    iconColor: .vocabLavender,
                    title: "Rung phản hồi (Haptics)"
                ) {
                    Toggle("", isOn: $viewModel.store.isHapticsEnabled)
                }

                SettingsRowView(
                    iconName: "waveform",
                    iconColor: .vocabLavender,
                    title: "Hiệu ứng âm thanh"
                ) {
                    Toggle("", isOn: $viewModel.store.isSoundEffectsEnabled)
                }
            }
            .listRowBackground(Color.vocabSurfaceCard)

            // App Data & About Section
            Section(header: sectionHeader("Ứng dụng & Dữ liệu")) {
                SettingsRowView(
                    iconName: "icloud.fill",
                    iconColor: .vocabMuted,
                    title: "Đồng bộ iCloud"
                ) {
                    Text("Đã đồng bộ")
                        .font(.caption.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundColor(.vocabMint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.vocabMint.opacity(0.12))
                        .clipShape(Capsule())
                }

                Button(action: {
                    viewModel.clearCache()
                }) {
                    SettingsRowView(
                        iconName: "trash.fill",
                        iconColor: .vocabMuted,
                        title: "Dọn dẹp bộ nhớ đệm"
                    ) {
                        Text(viewModel.cacheSizeString)
                            .font(.caption.weight(.semibold))
                            .fontDesign(.rounded)
                            .monospacedDigit()
                            .foregroundColor(.vocabMuted)
                    }
                }

                HStack {
                    Text("Phiên bản ứng dụng")
                        .font(.body)
                        .foregroundColor(.vocabInk)
                    Spacer()
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
            Color.clear.frame(height: 90)
        }
        .sensoryFeedback(.selection, trigger: viewModel.store.dailyGoalCount)
        .sensoryFeedback(.selection, trigger: viewModel.store.ttsVoiceGender)
        .sensoryFeedback(.selection, trigger: viewModel.store.appTheme)
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.store.isNotificationEnabled)
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.store.isHapticsEnabled)
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.store.isSoundEffectsEnabled)
        .alert("Xác nhận Reset Tiến trình", isPresented: $showResetAlert) {
            Button("Hủy", role: .cancel) {}
            Button("Reset", role: .destructive) {
                viewModel.resetSRSProgress()
            }
        } message: {
            Text("Tất cả dữ liệu ôn tập SRS sẽ được đặt lại từ đầu. Hành động này không thể hoàn tác.")
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.bold().smallCaps())
            .foregroundColor(.vocabMuted)
    }
}
