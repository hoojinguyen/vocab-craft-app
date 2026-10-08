import CraftUIKit
import SwiftUI

/// Modal sheet allowing users to select and preview roleplay voice profiles.
@MainActor
public struct RoleplayVoicePickerSheet: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @Bindable public var store: UserSettingsStore
    public let ttsService: any TextToSpeechProtocol

    @State private var previewingProfileId: String?
    @State private var previewTask: Task<Void, Never>?
    @State private var showDownloadPromptAlert: Bool = false

    public init(
        store: UserSettingsStore,
        ttsService: any TextToSpeechProtocol
    ) {
        self.store = store
        self.ttsService = ttsService
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    autoSection
                    cloudNeuralSection
                    onDeviceNeuralSection
                    deviceEnhancedSection
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.top, theme.spacing.base)
                .padding(.bottom, theme.spacing.xxl)
            }
            .background(theme.colors.canvasBackground.ignoresSafeArea())
            .navigationTitle(AppStrings.AIAssistant.selectVoiceTitle)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CraftIconButton(
                        symbol: .close,
                        size: .sm,
                        variant: .ghost,
                        accessibilityLabelKey: AppStrings.Common.close
                    ) {
                        dismiss()
                    }
                }
            }
            .alert(
                AppStrings.Settings.voicePreviewNeedsDownload,
                isPresented: $showDownloadPromptAlert
            ) {
                Button(AppStrings.Settings.voicePreviewDownloadAction) {
                    OnDemandAIModelManager.shared.startDownload(for: .kokoro)
                }
                Button(AppStrings.Common.cancel, role: .cancel) {}
            }
            .onDisappear {
                stopPlayback()
            }
        }
    }

    // MARK: - Sections

    private var autoSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            sectionHeader(AppStrings.Settings.voiceAutoPersona)

            CraftCard(style: .outlined, padding: 0) {
                profileRow(RoleplayVoiceProfileCatalog.defaultProfile, isAuto: true)
            }
        }
    }

    private var cloudNeuralSection: some View {
        let profiles = RoleplayVoiceProfileCatalog.allProfiles.filter { $0.engine == .geminiNeural }

        return VStack(alignment: .leading, spacing: theme.spacing.xs) {
            sectionHeader(AppStrings.Settings.voiceQualityGemini)

            CraftCard(style: .outlined, padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
                        if index > 0 {
                            CraftDivider()
                        }
                        profileRow(profile, isAuto: false)
                    }
                }
            }
        }
    }

    private var onDeviceNeuralSection: some View {
        let profiles = RoleplayVoiceProfileCatalog.allProfiles.filter { $0.engine == .kokoroNeural }

        if profiles.isEmpty { return AnyView(EmptyView()) }

        return AnyView(VStack(alignment: .leading, spacing: theme.spacing.xs) {
            sectionHeader(AppStrings.Settings.voiceQualityKokoro)

            CraftCard(style: .outlined, padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
                        if index > 0 {
                            CraftDivider()
                        }
                        profileRow(profile, isAuto: false)
                    }
                }
            }
        })
    }

    private var deviceEnhancedSection: some View {
        let profiles = RoleplayVoiceProfileCatalog.allProfiles.filter {
            $0.engine == .appleEnhanced && $0.id != RoleplayVoiceProfileCatalog.defaultProfile.id
        }

        return VStack(alignment: .leading, spacing: theme.spacing.xs) {
            sectionHeader(AppStrings.Settings.voiceQualityApple)

            CraftCard(style: .outlined, padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
                        if index > 0 {
                            CraftDivider()
                        }
                        profileRow(profile, isAuto: false)
                    }
                }
            }
        }
    }

    // MARK: - Row Component

    private func profileRow(_ profile: RoleplayVoiceProfile, isAuto: Bool) -> some View {
        let isSelected = store.roleplayVoiceId == profile.id
        let isPreviewing = previewingProfileId == profile.id

        return HStack(spacing: theme.spacing.sm) {
            Button {
                selectProfile(profile)
            } label: {
                HStack(spacing: theme.spacing.sm) {
                    VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                        HStack(spacing: theme.spacing.xs) {
                            if isAuto || profile.displayNameKey.hasPrefix("app.") {
                                Text(AppStrings.Settings.voiceAutoPersona)
                                    .font(theme.typography.headline)
                                    .foregroundStyle(theme.colors.textPrimary)
                            } else {
                                Text(verbatim: profile.displayNameKey)
                                    .font(theme.typography.headline)
                                    .foregroundStyle(theme.colors.textPrimary)
                            }

                            if isSelected {
                                CraftIcon(.check, size: .sm, color: theme.colors.brandPrimary)
                            }
                        }

                        Text(verbatim: "\(profile.gender.rawValue.capitalized) · \(profile.locale)")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                        if profile.engine == .geminiNeural {
                            Text(AppStrings.Settings.voiceQualityGemini)
                                .font(theme.typography.caption)
                                .foregroundStyle(theme.colors.textMuted)
                        } else if profile.engine == .kokoroNeural {
                            Text(AppStrings.Settings.voiceQualityKokoro)
                                .font(theme.typography.caption)
                                .foregroundStyle(theme.colors.textMuted)
                        } else {
                            Text(AppStrings.Settings.voiceQualityApple)
                                .font(theme.typography.caption)
                                .foregroundStyle(theme.colors.textMuted)
                        }
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            CraftIconButton(
                symbol: isPreviewing ? .pause : .play,
                size: .sm,
                variant: isPreviewing ? .filled : .subtle,
                accessibilityLabelKey: isPreviewing
                    ? AppStrings.Settings.voicePreviewing
                    : AppStrings.Settings.voicePreviewButton
            ) {
                handlePreview(for: profile)
            }
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.vertical, theme.spacing.sm)
    }

    private func sectionHeader(_ title: LocalizedStringKey) -> some View {
        CraftText(title, style: .caption, color: theme.colors.textSecondary)
            .fontWeight(.bold)
            .padding(.horizontal, theme.spacing.xs)
    }

    // MARK: - Actions

    private func selectProfile(_ profile: RoleplayVoiceProfile) {
        store.roleplayVoiceId = profile.id
        stopPlayback()
        dismiss()
    }

    private func handlePreview(for profile: RoleplayVoiceProfile) {
        if profile.engine == .kokoroNeural && !OnDemandAIModelManager.shared.isModelReady(.kokoro) {
            showDownloadPromptAlert = true
            return
        }

        if previewingProfileId == profile.id {
            stopPlayback()
        } else {
            previewTask?.cancel()
            previewingProfileId = profile.id
            previewTask = Task {
                await ttsService.previewVoice(
                    profile: profile,
                    rate: store.roleplaySpeechRate,
                    pitch: store.roleplaySpeechPitch
                )
                if !Task.isCancelled && previewingProfileId == profile.id {
                    previewingProfileId = nil
                }
            }
        }
    }

    private func stopPlayback() {
        previewTask?.cancel()
        previewTask = nil
        ttsService.stop()
        previewingProfileId = nil
    }
}
