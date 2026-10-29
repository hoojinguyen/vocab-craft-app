import CraftUIKit
import SwiftUI

/// Modal sheet allowing users to select and preview app voice profiles.
@MainActor
public struct VoicePickerSheet: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @Bindable public var store: UserSettingsStore
    public let ttsService: any TextToSpeechProtocol

    @State private var previewingProfileId: String?
    @State private var previewTask: Task<Void, Never>?

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
                    deviceEnhancedSection
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.top, theme.spacing.base)
                .padding(.bottom, theme.spacing.xxl)
            }
            .background(theme.colors.canvasBackground.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey("app.settings.voice.picker.title"))
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
            .onDisappear {
                stopPlayback()
            }
        }
    }

    // MARK: - Sections

    private var autoSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            sectionHeader(AppStrings.Settings.voiceAutoPersona)

            CraftCard(style: .outlined, padding: theme.spacing.none) {
                profileRow(VoiceProfileCatalog.defaultProfile)
            }
        }
    }

    private var deviceEnhancedSection: some View {
        let profiles = VoiceProfileCatalog.profiles.filter {
            $0.engine == .appleEnhanced && $0.id != VoiceProfileCatalog.defaultProfile.id
        }

        return VStack(alignment: .leading, spacing: theme.spacing.xs) {
            sectionHeader(AppStrings.Settings.voiceQualityApple)

            CraftCard(style: .outlined, padding: theme.spacing.none) {
                VStack(spacing: theme.spacing.none) {
                    ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
                        if index > 0 {
                            CraftDivider()
                        }
                        profileRow(profile)
                    }
                }
            }
        }
    }

    // MARK: - Row Component

    private func profileRow(_ profile: VoiceProfile) -> some View {
        let isSelected = VoiceProfileCatalog.resolve(id: store.voiceProfileId).id == profile.id
        let isPreviewing = previewingProfileId == profile.id

        return CraftListRow(
            title: LocalizedStringKey(profile.displayNameKey),
            subtitle: LocalizedStringKey(profile.qualityDescriptionKey),
            iconName: isSelected ? "checkmark.circle.fill" : "speaker.wave.2",
            iconColor: theme.colors.brandPrimary,
            action: { selectProfile(profile) }
        ) {
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
    }

    private func sectionHeader(_ title: LocalizedStringKey) -> some View {
        CraftText(title, style: .caption, color: theme.colors.textSecondary)
            .fontWeight(.bold)
            .padding(.horizontal, theme.spacing.xs)
    }

    // MARK: - Actions

    private func selectProfile(_ profile: VoiceProfile) {
        store.voiceProfileId = profile.id
        stopPlayback()
        dismiss()
    }

    private func handlePreview(for profile: VoiceProfile) {
        if previewingProfileId == profile.id {
            stopPlayback()
        } else {
            previewTask?.cancel()
            previewingProfileId = profile.id
            previewTask = Task {
                await ttsService.previewVoice(
                    profile: profile,
                    rate: store.speechRate,
                    pitch: store.speechPitch
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
