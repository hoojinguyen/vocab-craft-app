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
            Section(header: Text("Học tập & Ôn tập (SRS)").font(.footnote.weight(.semibold))) {
                SettingsRowView(
                    iconName: "target",
                    iconColor: .vocabHeroAccent,
                    title: "Mục tiêu từ/ngày"
                ) {
                    Stepper("\(viewModel.store.dailyGoalCount) từ", value: $viewModel.store.dailyGoalCount, in: 5...50, step: 5)
                        .font(.callout.weight(.medium))
                }

                SettingsRowView(
                    iconName: "bell.fill",
                    iconColor: .vocabHeroAccent,
                    title: "Nhắc nhở ôn tập"
                ) {
                    Toggle("", isOn: $viewModel.store.isNotificationEnabled)
                }

                if viewModel.store.isNotificationEnabled {
                    DatePicker(
                        "Giờ nhắc nhở",
                        selection: $viewModel.store.notificationTime,
                        displayedComponents: .hourAndMinute
                    )
                    .font(.subheadline)
                    .foregroundColor(.vocabInk)
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
                            .font(.caption)
                            .foregroundColor(.vocabMuted)
                    }
                }
            }
            .listRowBackground(Color.vocabSurfaceCard)

            // Audio & TTS Section
            Section(header: Text("Âm thanh & Phát âm").font(.footnote.weight(.semibold))) {
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
                            .font(.footnote.bold())
                            .foregroundColor(.vocabPeach)
                    }

                    Slider(value: $viewModel.store.ttsSpeed, in: 0.5...1.0, step: 0.05)
                        .tint(.vocabPeach)
                }

                Button(action: {
                    viewModel.playAudioPreview()
                }) {
                    HStack {
                        Image(systemName: viewModel.isPlayingAudio ? "speaker.wave.3.fill" : "play.circle.fill")
                            .foregroundColor(.vocabPeach)
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
            Section(header: Text("Giao diện & Trải nghiệm").font(.footnote.weight(.semibold))) {
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
            Section(header: Text("Ứng dụng & Dữ liệu").font(.footnote.weight(.semibold))) {
                SettingsRowView(
                    iconName: "icloud.fill",
                    iconColor: .vocabMuted,
                    title: "Đồng bộ iCloud"
                ) {
                    Text("Đã đồng bộ")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.vocabMint)
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
                            .foregroundColor(.vocabMuted)
                    }
                }

                HStack {
                    Text("Phiên bản ứng dụng")
                        .font(.body)
                        .foregroundColor(.vocabInk)
                    Spacer()
                    Text("v1.2.0 (Build 42)")
                        .font(.footnote)
                        .foregroundColor(.vocabMuted)
                }
            }
            .listRowBackground(Color.vocabSurfaceCard)

            // Bottom Spacing for LiquidGlassTabBar
            Section {
                Spacer()
                    .frame(height: 90)
                    .listRowBackground(Color.clear)
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.sidebar)
        #endif
        .scrollContentBackground(.hidden)
        .background(Color.vocabCanvas)
        .alert("Xác nhận Reset Tiến trình", isPresented: $showResetAlert) {
            Button("Hủy", role: .cancel) {}
            Button("Reset", role: .destructive) {}
        } message: {
            Text("Tất cả dữ liệu ôn tập SRS sẽ được đặt lại từ đầu. Hành động này không thể hoàn tác.")
        }
    }
}
