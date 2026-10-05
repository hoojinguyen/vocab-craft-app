import CraftUIKit
import SwiftUI

/// Modal sheet for viewing, updating, and clearing the Gemini and Groq API keys.
@MainActor
public struct AIConfigSheet: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Bindable public var store: UserSettingsStore
    public let onDismiss: () -> Void

    @State private var geminiApiKey: String
    @State private var groqApiKey: String

    @State private var isGeminiSecure: Bool = true
    @State private var isGroqSecure: Bool = true

    public init(store: UserSettingsStore, onDismiss: @escaping () -> Void = {}) {
        self.store = store
        self.onDismiss = onDismiss
        self._geminiApiKey = State(initialValue: store.geminiApiKey)
        self._groqApiKey = State(initialValue: store.groqApiKey)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Status Badge & Description
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        HStack {
                            if store.isGeminiApiKeyConfigured {
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

                            if store.isGroqApiKeyConfigured {
                                CraftBadge(
                                    AppStrings.Settings.aiGroqStatusActive,
                                    symbol: .check,
                                    variant: .subtle,
                                    tone: .success,
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

                    // Gemini Input Card
                    CraftCard(style: .outlined, cornerRadius: theme.radii.lg, padding: theme.spacing.md) {
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Text(AppStrings.Settings.aiGeminiKeyTitle)
                                .font(theme.typography.label)
                                .fontWeight(.bold)
                                .foregroundStyle(theme.colors.textPrimary)

                            HStack(spacing: theme.spacing.xs) {
                                Group {
                                    if isGeminiSecure {
                                        SecureField(
                                            AppStrings.Settings.aiGeminiKeyPlaceholder,
                                            text: $geminiApiKey
                                        )
                                    } else {
                                        TextField(
                                            AppStrings.Settings.aiGeminiKeyPlaceholder,
                                            text: $geminiApiKey
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

                                if !geminiApiKey.isEmpty {
                                    CraftIconButton(
                                        symbol: .clear,
                                        size: .sm,
                                        variant: .ghost,
                                        accessibilityLabelKey: AppStrings.Settings.aiClearKey
                                    ) {
                                        geminiApiKey = ""
                                    }
                                }

                                CraftIconButton(
                                    symbol: isGeminiSecure ? .eye : .eyeSlash,
                                    size: .sm,
                                    variant: .ghost,
                                    accessibilityLabelKey: isGeminiSecure ? AppStrings.Settings.aiShowKey : AppStrings.Settings.aiHideKey
                                ) {
                                    isGeminiSecure.toggle()
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

                    // Groq Input Card
                    CraftCard(style: .outlined, cornerRadius: theme.radii.lg, padding: theme.spacing.md) {
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Text(AppStrings.Settings.aiGroqKeyTitle)
                                .font(theme.typography.label)
                                .fontWeight(.bold)
                                .foregroundStyle(theme.colors.textPrimary)

                            HStack(spacing: theme.spacing.xs) {
                                Group {
                                    if isGroqSecure {
                                        SecureField(
                                            AppStrings.Settings.aiGroqKeyPlaceholder,
                                            text: $groqApiKey
                                        )
                                    } else {
                                        TextField(
                                            AppStrings.Settings.aiGroqKeyPlaceholder,
                                            text: $groqApiKey
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

                                if !groqApiKey.isEmpty {
                                    CraftIconButton(
                                        symbol: .clear,
                                        size: .sm,
                                        variant: .ghost,
                                        accessibilityLabelKey: AppStrings.Settings.aiClearKey
                                    ) {
                                        groqApiKey = ""
                                    }
                                }

                                CraftIconButton(
                                    symbol: isGroqSecure ? .eye : .eyeSlash,
                                    size: .sm,
                                    variant: .ghost,
                                    accessibilityLabelKey: isGroqSecure ? AppStrings.Settings.aiShowKey : AppStrings.Settings.aiHideKey
                                ) {
                                    isGroqSecure.toggle()
                                }
                            }
                            .padding(.horizontal, theme.spacing.sm)
                            .padding(.vertical, theme.spacing.xs)
                            .background(theme.colors.surfaceSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))

                            Text(AppStrings.Settings.aiGroqHelpText)
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
        let keyToSave = key ?? geminiApiKey
        store.geminiApiKey = keyToSave.trimmingCharacters(in: .whitespacesAndNewlines)
        store.groqApiKey = groqApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
