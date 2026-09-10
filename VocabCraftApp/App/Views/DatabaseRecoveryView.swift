import CraftUIKit
import SwiftUI

public struct DatabaseRecoveryView: View {
    @Environment(\.craftTheme) private var theme
    @State private var isShowingResetConfirmation = false

    public let error: DatabaseStoreError
    public let onRetry: () -> Void
    public let onConfirmReset: () -> Void

    public init(
        error: DatabaseStoreError,
        onRetry: @escaping () -> Void,
        onConfirmReset: @escaping () -> Void
    ) {
        self.error = error
        self.onRetry = onRetry
        self.onConfirmReset = onConfirmReset
    }

    private var backupURL: URL? {
        if case .storeInitializationFailed(_, let url) = error {
            return url
        }
        return nil
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            VStack(spacing: theme.spacing.xl) {
                Spacer()

                CraftCard(style: .elevated, padding: theme.spacing.lg) {
                    VStack(spacing: theme.spacing.md) {
                        CraftIcon(
                            .warning,
                            size: .xl,
                            color: theme.colors.statusDanger
                        )

                        Text("app.recovery.title")
                            .font(theme.typography.titleLarge)
                            .foregroundStyle(theme.colors.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("app.recovery.message")
                            .font(theme.typography.bodyMedium)
                            .foregroundStyle(theme.colors.textSecondary)
                            .multilineTextAlignment(.center)

                        if let backupURL {
                            Text(String(format: String(localized: "app.recovery.backup_location"), backupURL.path))
                                .font(theme.typography.caption)
                                .foregroundStyle(theme.colors.textMuted)
                                .multilineTextAlignment(.center)
                                .padding(theme.spacing.xs)
                                .background(theme.colors.surfaceSubtle)
                                .clipShape(RoundedRectangle(cornerRadius: theme.radii.sm))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                VStack(spacing: theme.spacing.sm) {
                    CraftButton(
                        LocalizedStringKey("app.recovery.retry_button"),
                        iconName: CraftSymbol.refresh.systemName,
                        iconPosition: .leading,
                        variant: .primary,
                        size: .lg,
                        isFullWidth: true,
                        action: onRetry
                    )

                    CraftButton(
                        LocalizedStringKey("app.recovery.reset_button"),
                        iconName: CraftSymbol.delete.systemName,
                        iconPosition: .leading,
                        variant: .danger,
                        size: .lg,
                        isFullWidth: true,
                        action: {
                            isShowingResetConfirmation = true
                        }
                    )
                }

                Spacer()
            }
            .padding(.horizontal, theme.spacing.lg)
        }
        .confirmationDialog(
            Text("app.recovery.reset_confirm_title"),
            isPresented: $isShowingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button(role: .destructive) {
                onConfirmReset()
            } label: {
                Text("app.recovery.reset_button")
            }
            Button(role: .cancel) {
            } label: {
                Text("app.recovery.cancel_button")
            }
        } message: {
            Text("app.recovery.reset_confirm_message")
        }
    }
}

#if canImport(PreviewsMacros)
#Preview("DatabaseRecoveryView") {
    DatabaseRecoveryView(
        error: .storeInitializationFailed(
            description: "Corrupted store",
            backupURL: URL(fileURLWithPath: "/tmp/backup.sqlite")
        ),
        onRetry: {},
        onConfirmReset: {}
    )
    .craftTheme(CraftThemeManager.shared.currentPreset.theme)
}
#endif
