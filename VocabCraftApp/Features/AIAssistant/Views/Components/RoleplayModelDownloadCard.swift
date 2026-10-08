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
                        Text(AppStrings.AIPack.offlineDownloadAllTitle)
                            .font(theme.typography.label)
                            .fontWeight(.bold)
                            .foregroundStyle(theme.colors.textPrimary)

                        Text(AppStrings.AIPack.offlineDownloadAllDesc)
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

                if case .downloading = modelManager.fullOfflinePackState {
                    VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                        CraftProgressBar(progress: modelManager.fullOfflinePackProgress, height: 4)
                        Text(modelManager.fullOfflinePackProgress, format: .percent.precision(.fractionLength(0)))
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textMuted)
                    }
                } else {
                    CraftButton(
                        AppStrings.AIPack.offlineDownloadAllAction,
                        variant: .primary,
                        size: .sm,
                        isFullWidth: true
                    ) {
                        modelManager.startFullOfflinePackDownload()
                    }
                }
            }
        }
    }
}
