import CraftUIKit
import SwiftUI

/// Modal sheet for selecting active AI Pack and configuring cloud API keys.
@MainActor
public struct AIConfigSheet: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appContainer) private var appContainer
    @Bindable public var store: UserSettingsStore
    @Bindable private var modelManager = OnDemandAIModelManager.shared
    public let onDismiss: () -> Void

    @State private var geminiApiKey: String
    @State private var groqApiKey: String

    @State private var isGeminiSecure: Bool = true
    @State private var isGroqSecure: Bool = true

    @State private var selectionError: AIPackError?
    @State private var showSelectionErrorAlert: Bool = false

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
                    // Section 1: AI Packs
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        Text(AppStrings.AIPack.sectionTitle)
                            .font(theme.typography.titleMedium)
                            .fontWeight(.bold)
                            .foregroundStyle(theme.colors.textPrimary)

                        ForEach(appContainer.aiPackRegistry.packCatalog) { entry in
                            packSelectionCard(entry)
                        }
                    }

                    // Section 2: Cloud API Keys (for GeminiCloudPack)
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        Text(AppStrings.AIPack.keysSection)
                            .font(theme.typography.titleMedium)
                            .fontWeight(.bold)
                            .foregroundStyle(theme.colors.textPrimary)

                        Text(AppStrings.AIAssistant.apiKeyBannerDesc)
                            .font(theme.typography.bodyMedium)
                            .foregroundStyle(theme.colors.textSecondary)

                        // Gemini Input Card
                        CraftCard(style: .outlined, cornerRadius: theme.radii.lg, padding: theme.spacing.md) {
                            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                                HStack {
                                    Text(AppStrings.Settings.aiGeminiKeyTitle)
                                        .font(theme.typography.label)
                                        .fontWeight(.bold)
                                        .foregroundStyle(theme.colors.textPrimary)

                                    Spacer()

                                    if store.isGeminiApiKeyConfigured {
                                        CraftBadge(
                                            AppStrings.AIPack.statusReady,
                                            symbol: .check,
                                            variant: .subtle,
                                            tone: .success,
                                            size: .sm
                                        )
                                    } else {
                                        CraftBadge(
                                            AppStrings.AIPack.statusNeedsKey,
                                            symbol: .sparkles,
                                            variant: .subtle,
                                            tone: .warning,
                                            size: .sm
                                        )
                                    }
                                }

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
                                HStack {
                                    Text(AppStrings.Settings.aiGroqKeyTitle)
                                        .font(theme.typography.label)
                                        .fontWeight(.bold)
                                        .foregroundStyle(theme.colors.textPrimary)

                                    Spacer()

                                    if store.isGroqApiKeyConfigured {
                                        CraftBadge(
                                            AppStrings.AIPack.statusReady,
                                            symbol: .check,
                                            variant: .subtle,
                                            tone: .success,
                                            size: .sm
                                        )
                                    }
                                }

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
                    }

                    // Section 3: Offline On-Device Models
                    offlineModelsSection

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
            .navigationTitle(AppStrings.AIPack.selectPackTitle)
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
            .alert(
                AppStrings.AIPack.alertTitle,
                isPresented: $showSelectionErrorAlert
            ) {
                Button(AppStrings.Common.confirm, role: .cancel) {}
            } message: {
                if let error = selectionError {
                    Text(LocalizedStringKey(error.localizedKey))
                }
            }
            .onAppear {
                modelManager.refreshStatus()
                appContainer.aiPackRegistry.revalidateActivePack()
            }
        }
    }

    private func packSelectionCard(_ entry: AIPackEntry) -> some View {
        let (statusKey, tone): (LocalizedStringKey, CraftBadgeTone) = statusBadgeInfo(for: entry.status)

        return Button {
            selectPack(entry)
        } label: {
            CraftCard(
                style: entry.isActive ? .elevated : .outlined,
                padding: theme.spacing.md
            ) {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack(spacing: theme.spacing.xs) {
                        CraftIcon(
                            entry.isActive ? .check : .sparkles,
                            size: .sm,
                            color: entry.isActive ? theme.colors.brandPrimary : theme.colors.textMuted
                        )

                        Text(verbatim: entry.displayName)
                            .font(theme.typography.label)
                            .fontWeight(.bold)
                            .foregroundStyle(theme.colors.textPrimary)

                        Spacer()

                        CraftBadge(
                            statusKey,
                            variant: .subtle,
                            tone: tone,
                            size: .sm
                        )
                    }

                    Text(localizedPackDescription(for: entry.identifier))
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                        .lineLimit(2)

                    if entry.isActive {
                        CraftBadge(
                            AppStrings.AIPack.activeBadge,
                            symbol: .check,
                            variant: .solid,
                            tone: .primary,
                            size: .sm
                        )
                        .padding(.top, theme.spacing.xxs)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.lg)
                    .strokeBorder(
                        entry.isActive ? theme.colors.brandPrimary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func statusBadgeInfo(for status: AIPackStatus) -> (LocalizedStringKey, CraftBadgeTone) {
        switch status {
        case .ready:
            return (AppStrings.AIPack.statusReady, .success)
        case .needsApiKey:
            return (AppStrings.AIPack.statusNeedsKey, .warning)
        case .needsDownload, .partiallyReady:
            return (AppStrings.AIPack.statusNeedsDownload, .primary)
        case .unavailable:
            return (AppStrings.AIPack.statusUnavailable, .neutral)
        }
    }

    private func localizedPackDescription(for identifier: AIPackIdentifier) -> LocalizedStringKey {
        switch identifier {
        case .appleDefault:
            return AppStrings.AIPack.appleDefaultDesc
        case .offlineAI:
            return AppStrings.AIPack.offlineDesc
        case .geminiCloud:
            return AppStrings.AIPack.geminiCloudDesc
        default:
            return LocalizedStringKey(stringLiteral: "")
        }
    }

    private func selectPack(_ entry: AIPackEntry) {
        do {
            try appContainer.aiPackRegistry.selectPack(entry.identifier)
            CraftHaptics.shared.success()
        } catch {
            selectionError = error
            showSelectionErrorAlert = true
            CraftHaptics.shared.warning()
        }
    }
}

// MARK: - Offline Models & Actions

extension AIConfigSheet {
    var offlineModelsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text(AppStrings.AIPack.modelsSection)
                .font(theme.typography.titleMedium)
                .fontWeight(.bold)
                .foregroundStyle(theme.colors.textPrimary)

            Text(AppStrings.AIPack.offlineDownloadAllDesc)
                .font(theme.typography.bodyMedium)
                .foregroundStyle(theme.colors.textSecondary)

            // Unified Full Pack Card
            CraftCard(
                style: .elevated,
                cornerRadius: theme.radii.lg,
                padding: theme.spacing.md
            ) {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    HStack {
                        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                            Text(AppStrings.AIPack.offlineDownloadAllTitle)
                                .font(theme.typography.label)
                                .fontWeight(.bold)
                                .foregroundStyle(theme.colors.textPrimary)

                            if modelManager.isFullOfflinePackReady() {
                                Text(AppStrings.AIPack.statusReady)
                                    .font(theme.typography.caption)
                                    .foregroundStyle(theme.colors.statusSuccess)
                            } else if case .error(let msg) = modelManager.fullOfflinePackState {
                                let trimmed = msg.trimmingCharacters(in: .whitespacesAndNewlines)
                                let displayError = (!trimmed.isEmpty && trimmed != AppStrings.AIPack.statusDownloadFailedText)
                                    ? "\(AppStrings.AIPack.statusDownloadFailedText): \(trimmed)"
                                    : AppStrings.AIPack.statusDownloadFailedText
                                Text(displayError)
                                    .font(theme.typography.caption)
                                    .foregroundStyle(theme.colors.statusDanger)
                                    .lineLimit(2)
                            } else {
                                Text(AppStrings.AIPack.statusNeedsDownload)
                                    .font(theme.typography.caption)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }
                        }

                        Spacer()

                        if modelManager.isFullOfflinePackReady() {
                            CraftBadge(
                                AppStrings.AIPack.statusReady,
                                symbol: .check,
                                variant: .subtle,
                                tone: .success,
                                size: .sm
                            )
                        } else if case .downloading = modelManager.fullOfflinePackState {
                            CraftBadge(
                                AppStrings.AIModelDownload.statusDownloading,
                                symbol: .sparkles,
                                variant: .subtle,
                                tone: .primary,
                                size: .sm
                            )
                        } else if case .error = modelManager.fullOfflinePackState {
                            CraftBadge(
                                AppStrings.AIPack.statusDownloadFailed,
                                symbol: .alert,
                                variant: .subtle,
                                tone: .danger,
                                size: .sm
                            )
                        }
                    }

                    if case .downloading = modelManager.fullOfflinePackState {
                        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                            CraftProgressBar(progress: modelManager.fullOfflinePackProgress, height: 6)
                            HStack {
                                Text(AppStrings.AIModelDownload.statusDownloading)
                                    .font(theme.typography.caption)
                                    .foregroundStyle(theme.colors.textSecondary)
                                Spacer()
                                Text(modelManager.fullOfflinePackProgress, format: .percent.precision(.fractionLength(0)))
                                    .font(theme.typography.caption)
                                    .foregroundStyle(theme.colors.textMuted)
                            }
                        }
                    } else if modelManager.isFullOfflinePackReady() {
                        CraftButton(
                            AppStrings.Settings.modelsFreeSpace,
                            variant: .outline,
                            size: .sm,
                            isFullWidth: true
                        ) {
                            modelManager.deleteFullOfflinePack()
                            appContainer.aiPackRegistry.revalidateActivePack()
                        }
                    } else if case .error = modelManager.fullOfflinePackState {
                        CraftButton(
                            AppStrings.AIPack.retryAction,
                            variant: .outline,
                            size: .md,
                            isFullWidth: true
                        ) {
                            modelManager.startFullOfflinePackDownload()
                        }
                        .tint(theme.colors.statusDanger)
                    } else {
                        let remainingMB = modelManager.remainingOfflinePackSizeMB
                        let actionTitle: LocalizedStringKey = (remainingMB < 975 && remainingMB > 0)
                            ? AppStrings.AIPack.downloadRemainingAction(remainingMB)
                            : AppStrings.AIPack.offlineDownloadAllAction

                        CraftButton(
                            actionTitle,
                            variant: .primary,
                            size: .md,
                            isFullWidth: true
                        ) {
                            modelManager.startFullOfflinePackDownload()
                        }
                    }
                }
            }

            // Breakdown indicators for Kokoro, Whisper, and Llama
            CraftCard(style: .outlined, padding: theme.spacing.none) {
                VStack(spacing: theme.spacing.none) {
                    modelRow(type: .kokoro)
                    CraftDivider()
                    modelRow(type: .whisper)
                    CraftDivider()
                    modelRow(type: .llama)
                }
            }
        }
        .onAppear {
            modelManager.refreshStatus()
        }
    }

    @ViewBuilder
    private func modelRow(type: AIModelType) -> some View {
        let isReady = modelManager.isModelReady(type)
        let state = modelManager.state(for: type)

        CraftListRow(
            title: modelTitle(for: type),
            subtitle: LocalizedStringKey(modelSubtitle(for: type, state: state))
        ) {
            if isReady {
                CraftButton(
                    AppStrings.Settings.modelsFreeSpace,
                    variant: .ghost,
                    size: .sm
                ) {
                    try? modelManager.deleteModel(type)
                    appContainer.aiPackRegistry.revalidateActivePack()
                }
                .tint(theme.colors.statusDanger)
            } else if case .downloading(let progress) = state {
                HStack(spacing: theme.spacing.xs) {
                    CraftProgressBar(progress: progress, height: 4)
                        .frame(width: theme.spacing.xxl)
                    Text(progress, format: .percent.precision(.fractionLength(0)))
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textMuted)
                }
            } else if case .error = state {
                CraftButton(
                    AppStrings.Common.retry,
                    variant: .outline,
                    size: .sm
                ) {
                    modelManager.startDownload(for: type)
                }
                .tint(theme.colors.statusDanger)
            } else {
                CraftButton(
                    AppStrings.AIModelDownload.actionDownload,
                    variant: .secondary,
                    size: .sm
                ) {
                    modelManager.startDownload(for: type)
                }
            }
        }
    }

    private func modelTitle(for type: AIModelType) -> LocalizedStringKey {
        switch type {
        case .kokoro:
            return AppStrings.AIPack.kokoroTitle
        case .whisper:
            return LocalizedStringKey(type.displayName)
        case .llama:
            return AppStrings.AIPack.llamaTitle
        }
    }

    private func modelSubtitle(for type: AIModelType, state: AIModelDownloadState) -> String {
        switch state {
        case .ready: return AppStrings.AIModelDownload.statusReady(type.estimatedSizeMB)
        case .downloading: return AppStrings.AIModelDownload.statusDownloadingText
        case .error(let message):
            let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && trimmed != AppStrings.AIModelDownload.statusErrorText {
                return "\(AppStrings.AIModelDownload.statusErrorText) (\(trimmed))"
            }
            return AppStrings.AIModelDownload.statusErrorText
        default: return AppStrings.AIModelDownload.statusSize(type.estimatedSizeMB)
        }
    }

    public func save(_ key: String? = nil) {
        let keyToSave = key ?? geminiApiKey
        store.geminiApiKey = keyToSave.trimmingCharacters(in: .whitespacesAndNewlines)
        store.groqApiKey = groqApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        appContainer.aiPackRegistry.revalidateActivePack()
    }
}

private extension CraftSymbol {
    static var alert: CraftSymbol { .danger }
}
