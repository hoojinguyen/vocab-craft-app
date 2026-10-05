import CraftUIKit
import SwiftUI

public struct RoleplayModelDownloadCard: View {
    @Environment(\.craftTheme) private var theme
    @Bindable private var modelManager = OnDemandAIModelManager.shared

    let onDismiss: () -> Void

    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    public var body: some View {
        CraftCard(style: .elevated, padding: theme.spacing.md) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text(AppStrings.AIModelDownload.bannerTitle)
                    .font(theme.typography.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.colors.textPrimary)

                Text(AppStrings.AIModelDownload.bannerDesc)
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.textSecondary)

                let kokoroState = modelManager.state(for: .kokoro)
                let whisperState = modelManager.state(for: .whisper)

                let isDownloading = isDownloadingState(kokoroState) || isDownloadingState(whisperState)
                let kokoroProgress = getProgress(kokoroState)
                let whisperProgress = getProgress(whisperState)
                let overallProgress = (kokoroProgress + whisperProgress) / 2.0

                if isDownloading {
                    VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                        CraftProgressBar(progress: overallProgress, height: 6)
                        Text("\(Int(overallProgress * 100))%")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textMuted)
                    }
                    .padding(.vertical, theme.spacing.xs)
                }

                HStack(spacing: theme.spacing.sm) {
                    if !isDownloading {
                        CraftButton(
                            AppStrings.AIModelDownload.btnDownload,
                            variant: .primary,
                            size: .md
                        ) {
                            let kokoroURL = URL(string: "https://huggingface.co/hexgrad/Kokoro-82M/resolve/main/kokoro-v0_19.pth")!
                            let whisperURL = URL(string: "https://huggingface.co/argmaxinc/whisperkit-coreml/resolve/main/openai_whisper-tiny.en/whisperkit.zip")!
                            modelManager.startDownload(for: .kokoro, remoteURL: kokoroURL)
                            modelManager.startDownload(for: .whisper, remoteURL: whisperURL)
                        }
                    }

                    CraftButton(
                        AppStrings.AIModelDownload.btnLater,
                        variant: .ghost,
                        size: .md
                    ) {
                        onDismiss()
                    }
                }
            }
        }
    }

    private func isDownloadingState(_ state: AIModelDownloadState) -> Bool {
        if case .downloading = state { return true }
        return false
    }

    private func getProgress(_ state: AIModelDownloadState) -> Double {
        switch state {
        case .downloading(let progress): return progress
        case .ready: return 1.0
        default: return 0.0
        }
    }
}
