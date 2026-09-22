import CraftUIKit
import SwiftUI

/// Modal sheet for viewing, updating, and clearing the Gemini API key.
public struct AIConfigSheet: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Bindable public var store: UserSettingsStore
    public let onDismiss: () -> Void

    @State private var apiKey: String
    @State private var isSecure: Bool = true

    public init(store: UserSettingsStore, onDismiss: @escaping () -> Void = {}) {
        self.store = store
        self.onDismiss = onDismiss
        self._apiKey = State(initialValue: store.geminiApiKey)
    }

    private var isApiKeyConfigured: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Status Badge & Description
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        HStack {
                            if isApiKeyConfigured {
                                CraftBadge(
                                    AppStrings.Settings.aiGeminiStatusConnected,
                                    symbol: .check,
                                    variant: .subtle,
                                    tone: .success,
                                    size: .md
                                )
                            } else {
                                CraftBadge(
                                    AppStrings.Settings.aiGeminiStatusMock,
                                    symbol: .sparkles,
                                    variant: .subtle,
                                    tone: .neutral,
                                    size: .md
                                )
                            }
                            Spacer()
                        }

                        Text(AppStrings.AIAssistant.apiKeyBannerDesc)
                            .font(theme.typography.bodyMedium)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                    .padding(.horizontal, theme.spacing.xs)

                    // Input Card
                    CraftCard(style: .outlined, cornerRadius: theme.radii.lg, padding: theme.spacing.md) {
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Text(AppStrings.Settings.aiGeminiKeyTitle)
                                .font(theme.typography.label)
                                .fontWeight(.bold)
                                .foregroundStyle(theme.colors.textPrimary)

                            HStack(spacing: theme.spacing.xs) {
                                Group {
                                    if isSecure {
                                        SecureField(
                                            AppStrings.Settings.aiGeminiKeyPlaceholderText,
                                            text: $apiKey
                                        )
                                    } else {
                                        TextField(
                                            AppStrings.Settings.aiGeminiKeyPlaceholderText,
                                            text: $apiKey
                                        )
                                    }
                                }
                                .font(theme.typography.bodyMedium)
                                .foregroundStyle(theme.colors.textPrimary)
                                .tint(theme.colors.brandPrimary)
                                .autocorrectionDisabled()
                                #if os(iOS)
                                .textInputAutocapitalization(.never)
                                #endif

                                if !apiKey.isEmpty {
                                    CraftIconButton(
                                        symbol: .clear,
                                        size: .sm,
                                        variant: .ghost,
                                        accessibilityLabelKey: AppStrings.Settings.aiClearKey
                                    ) {
                                        apiKey = ""
                                    }
                                }

                                CraftIconButton(
                                    symbol: isSecure ? .eye : .eyeSlash,
                                    size: .sm,
                                    variant: .ghost,
                                    accessibilityLabelKey: isSecure ? AppStrings.Settings.aiShowKey : AppStrings.Settings.aiHideKey
                                ) {
                                    isSecure.toggle()
                                }
                            }
                            .padding(.horizontal, theme.spacing.sm)
                            .padding(.vertical, theme.spacing.xs)
                            .background(theme.colors.surfaceSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))

                            Text(AppStrings.Settings.aiGeminiHelpText)
                                .font(theme.typography.caption)
                                .foregroundStyle(theme.colors.textSecondary)
                        }
                    }

                    // Save Button
                    CraftButton(
                        AppStrings.Common.save,
                        variant: .primary,
                        size: .lg,
                        isFullWidth: true
                    ) {
                        save()
                        onDismiss()
                        dismiss()
                    }
                    .padding(.top, theme.spacing.xs)

                    Spacer(minLength: theme.spacing.xl)
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.top, theme.spacing.base)
            }
            .background(theme.colors.canvasBackground.ignoresSafeArea())
            .navigationTitle(AppStrings.AIAssistant.apiKeySheetTitle)
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
                        onDismiss()
                        dismiss()
                    }
                }
            }
        }
    }

    public func save(_ key: String? = nil) {
        let keyToSave = key ?? apiKey
        store.geminiApiKey = keyToSave.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
