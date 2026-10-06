import CraftUIKit
import Foundation
import SwiftUI

public struct RoleplayRoomView: View {
    @State private var viewModel: RoleplayRoomViewModel
    private let onDismiss: () -> Void
    @Environment(\.craftTheme) private var theme
    @Environment(\.appContainer) private var appContainer
    @State private var showDiscardAlert = false
    @State private var showVoicePicker = false
    @State private var selectedWordTooltip: String?
    @State private var hideDownloadBanner = false
    private var modelManager = OnDemandAIModelManager.shared

    public init(viewModel: RoleplayRoomViewModel, onDismiss: @escaping () -> Void) {
        self._viewModel = State(initialValue: viewModel)
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Header Bar
                headerBar

                // Target Words Strip
                InteractiveTargetWordsStrip(
                    targetWords: viewModel.scenario.targetWordIds,
                    masteredWords: viewModel.masteredWords
                ) { word in
                    withAnimation(theme.animations.springSnappy) {
                        if selectedWordTooltip == word {
                            selectedWordTooltip = nil
                        } else {
                            selectedWordTooltip = word
                        }
                    }
                }

                if let selectedWord = selectedWordTooltip {
                    wordTooltipBanner(selectedWord)
                }

                if !hideDownloadBanner,
                   !modelManager.isModelReady(.kokoro) || !modelManager.isModelReady(.whisper) {
                    RoleplayModelDownloadCard {
                        hideDownloadBanner = true
                    }
                    .padding(.horizontal, theme.spacing.base)
                }

                // Dialogue Stream
                dialogueStream

                // Suggested Response Chips Bar
                suggestedChipsBar

                // Bottom Control Bar
                bottomInputBar
            }
        }
        .alert(
            AppStrings.AIAssistant.discardConfirmTitle,
            isPresented: $showDiscardAlert
        ) {
            Button(AppStrings.Common.cancel, role: .cancel) {}
            Button(AppStrings.Common.confirm, role: .destructive) { onDismiss() }
        } message: {
            Text(AppStrings.AIAssistant.discardConfirmMessage)
        }
        #if os(iOS)
        .fullScreenCover(item: $viewModel.sessionSummary) { summary in
            RoleplaySummaryView(summary: summary) {
                onDismiss()
            }
        }
        #else
        .sheet(item: $viewModel.sessionSummary) { summary in
            RoleplaySummaryView(summary: summary) {
                onDismiss()
            }
        }
        #endif
        .sheet(isPresented: $showVoicePicker) {
            RoleplayVoicePickerSheet(
                store: appContainer.userSettingsStore,
                ttsService: appContainer.ttsService
            )
        }
    }

    private var headerBar: some View {
        HStack {
            CraftIconButton(
                symbol: .close,
                size: .md,
                variant: .subtle,
                accessibilityLabelKey: AppStrings.Common.close
            ) {
                showDiscardAlert = true
            }

            Spacer()

            VStack(spacing: theme.spacing.xxs) {
                Text(viewModel.scenario.characterName)
                    .font(theme.typography.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.colors.textPrimary)
                Text(viewModel.scenario.characterRole)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
            }

            Spacer()

            HStack(spacing: theme.spacing.xs) {
                CraftIconButton(
                    symbol: .audio,
                    size: .md,
                    variant: .subtle,
                    accessibilityLabelKey: AppStrings.AIAssistant.selectVoiceTitle
                ) {
                    showVoicePicker = true
                }

                CraftButton(
                    AppStrings.AIAssistant.actionFinishSession,
                    variant: .secondary,
                    size: .sm
                ) {
                    Task { await viewModel.finishSession() }
                }
            }
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.vertical, theme.spacing.sm)
    }

    private func wordTooltipBanner(_ word: String) -> some View {
        HStack(spacing: theme.spacing.xs) {
            CraftIcon(.info, size: .sm, color: theme.colors.brandPrimary)

            Text(word)
                .font(theme.typography.bodyMedium)
                .fontWeight(.semibold)
                .foregroundStyle(theme.colors.textPrimary)

            Spacer()

            CraftIconButton(
                symbol: .audio,
                size: .sm,
                variant: .subtle,
                accessibilityLabelKey: AppStrings.AIAssistant.audioPlayButton
            ) {
                viewModel.playSpeech(for: word)
            }

            CraftIconButton(
                symbol: .close,
                size: .sm,
                variant: .ghost,
                accessibilityLabelKey: AppStrings.Common.close
            ) {
                withAnimation(theme.animations.springSnappy) {
                    selectedWordTooltip = nil
                }
            }
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.vertical, theme.spacing.xs)
        .background(theme.colors.surfaceSubtle)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var dialogueStream: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: theme.spacing.md) {
                    ForEach(viewModel.messages) { message in
                        messageRow(message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.vertical, theme.spacing.md)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let lastId = viewModel.messages.last?.id {
                    withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                }
            }
        }
    }

    private func messageRow(_ message: DisplayChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: theme.spacing.xs) {
            if message.isUser { Spacer() }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: theme.spacing.xs) {
                Text(message.text)
                    .font(theme.typography.bodyLarge)
                    .foregroundStyle(message.isUser ? theme.colors.textInverse : theme.colors.textPrimary)
                    .padding(theme.spacing.md)
                    .background(message.isUser ? theme.colors.brandPrimary : theme.colors.surfaceCard)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg))

                if let refinement = message.refinementSuggestion {
                    VStack(alignment: message.isUser ? .trailing : .leading, spacing: theme.spacing.xs) {
                        Button {
                            withAnimation(theme.animations.springSnappy) {
                                viewModel.toggleRefinement(for: message.id)
                            }
                        } label: {
                            HStack(spacing: theme.spacing.xxs) {
                                CraftIcon(.sparkles, size: .sm, color: theme.colors.brandPrimary)
                                Text(AppStrings.AIAssistant.refineSuggestionButton)
                                    .font(theme.typography.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(theme.colors.brandPrimary)
                                CraftIcon(
                                    message.isRefinementExpanded ? .chevronUp : .chevronDown,
                                    size: .sm,
                                    color: theme.colors.brandPrimary
                                )
                            }
                            .padding(.vertical, theme.spacing.xxs)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if message.isRefinementExpanded {
                            refinementPreviewCard(refinement)
                        }
                    }
                }
            }

            if !message.isUser {
                CraftIconButton(
                    symbol: .audio,
                    size: .sm,
                    variant: .subtle,
                    accessibilityLabelKey: AppStrings.AIAssistant.audioPlayButton
                ) {
                    viewModel.playSpeech(for: message.text)
                }
            }

            if !message.isUser { Spacer() }
        }
    }

    private func refinementPreviewCard(_ refinement: String) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack(spacing: theme.spacing.xs) {
                Text(AppStrings.AIAssistant.chatRefinePrefix)
                    .font(theme.typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.colors.textSecondary)

                Spacer()

                CraftIconButton(
                    symbol: .audio,
                    size: .sm,
                    variant: .subtle,
                    accessibilityLabelKey: AppStrings.AIAssistant.audioPlayButton
                ) {
                    viewModel.playSpeech(for: refinement)
                }
            }

            Text(refinement)
                .font(theme.typography.bodyMedium)
                .foregroundStyle(theme.colors.textPrimary)
        }
        .padding(theme.spacing.sm)
        .background(theme.colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.md)
                .stroke(theme.colors.borderDefault, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var suggestedChipsBar: some View {
        if viewModel.isSuggestionsVisible && !viewModel.suggestedResponses.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.xs) {
                    ForEach(viewModel.suggestedResponses, id: \.self) { suggestion in
                        Button {
                            withAnimation(theme.animations.springSnappy) {
                                viewModel.selectSuggestion(suggestion)
                            }
                        } label: {
                            HStack(spacing: theme.spacing.xxs) {
                                CraftIcon(.sparkles, size: .sm, color: theme.colors.brandPrimary)
                                Text(suggestion)
                                    .font(theme.typography.bodyMedium)
                                    .foregroundStyle(theme.colors.textPrimary)
                            }
                            .padding(.horizontal, theme.spacing.sm)
                            .padding(.vertical, theme.spacing.xs)
                            .background(theme.colors.surfaceCard)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(theme.colors.borderDefault, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.vertical, theme.spacing.xxs)
            }
            .background(theme.colors.canvasBackground)
        }
    }

    private var bottomInputBar: some View {
        HStack(spacing: theme.spacing.sm) {
            TextField(AppStrings.AIAssistant.inputPlaceholder, text: $viewModel.inputText)
                .textFieldStyle(.plain)
                .padding(theme.spacing.sm)
                .background(theme.colors.surfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
                .onSubmit {
                    Task { await viewModel.sendMessage(viewModel.inputText) }
                }

            CraftIconButton(
                symbol: .check,
                size: .md,
                variant: .filled,
                isLoading: viewModel.isSending,
                accessibilityLabelKey: AppStrings.Common.confirm
            ) {
                Task { await viewModel.sendMessage(viewModel.inputText) }
            }
            .disabled(viewModel.isSending || viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.vertical, theme.spacing.sm)
        .background(theme.colors.canvasBackground)
    }
}
