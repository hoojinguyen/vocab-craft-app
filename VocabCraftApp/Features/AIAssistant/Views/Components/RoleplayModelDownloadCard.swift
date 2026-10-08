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
        CraftCard(style: .elevated, padding: theme.spacing.sm) {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(AppStrings.AIModelDownload.bannerTitle)
                            .font(theme.typography.label)
                            .fontWeight(.bold)
                            .foregroundStyle(theme.colors.textPrimary)

                        Text(AppStrings.AIModelDownload.bannerDesc)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: theme.spacing.xs)

                    CraftIconButton(
                        symbol: .close,
                        size: .sm,
                        variant: .ghost,
                        accessibilityLabelKey: AppStrings.Common.close
                    ) {
                        onDismiss()
                    }
                }

                let kokoroState = modelManager.state(for: .kokoro)
                let whisperState = modelManager.state(for: .whisper)

                let isDownloading = isDownloadingState(kokoroState) || isDownloadingState(whisperState)
                let kokoroProgress = getProgress(kokoroState)
                let whisperProgress = getProgress(whisperState)
                let overallProgress = (kokoroProgress + whisperProgress) / 2.0

                if isDownloading {
                    VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                        CraftProgressBar(progress: overallProgress, height: 4)
                        Text(overallProgress, format: .percent.precision(.fractionLength(0)))
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textMuted)
                    }
                } else {
                    CraftButton(
                        AppStrings.AIModelDownload.btnDownload,
                        variant: .primary,
                        size: .sm,
                        isFullWidth: true
                    ) {
                        let kokoroURL = URL(string: "https://huggingface.co/hexgrad/Kokoro-82M/resolve/main/kokoro-v0_19.pth")!
                        let whisperURL = URL(string: "https://huggingface.co/argmaxinc/whisperkit-coreml/resolve/main/openai_whisper-tiny.en/whisperkit.zip")!
                        modelManager.startDownload(for: .kokoro, remoteURL: kokoroURL)
                        modelManager.startDownload(for: .whisper, remoteURL: whisperURL)
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
