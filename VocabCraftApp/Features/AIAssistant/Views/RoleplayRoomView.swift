import CraftUIKit
import SwiftUI

public struct RoleplayRoomView: View {
    @State private var viewModel: RoleplayRoomViewModel
    private let onDismiss: () -> Void
    @Environment(\.craftTheme) private var theme
    @State private var showDiscardAlert = false

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
                targetWordsStrip

                // Dialogue Stream
                dialogueStream

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

            CraftButton(
                AppStrings.AIAssistant.actionFinishSession,
                variant: .secondary,
                size: .sm
            ) {
                Task { await viewModel.finishSession() }
            }
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.vertical, theme.spacing.sm)
    }

    private var targetWordsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.xs) {
                Text(AppStrings.AIAssistant.targetWordsTitle)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
                    .padding(.trailing, theme.spacing.xs)

                ForEach(viewModel.scenario.targetWordIds, id: \.self) { word in
                    let isMastered = viewModel.masteredWords.contains(word)
                    CraftBadge(
                        LocalizedStringKey(word),
                        iconName: isMastered ? "checkmark.circle.fill" : nil,
                        variant: isMastered ? .solid : .subtle,
                        tone: isMastered ? .success : .neutral,
                        size: .sm
                    )
                }
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.vertical, theme.spacing.xs)
        }
        .background(theme.colors.surfaceCard)
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
        HStack {
            if message.isUser { Spacer() }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: theme.spacing.xs) {
                Text(message.text)
                    .font(theme.typography.bodyLarge)
                    .foregroundStyle(message.isUser ? theme.colors.textInverse : theme.colors.textPrimary)
                    .padding(theme.spacing.md)
                    .background(message.isUser ? theme.colors.brandPrimary : theme.colors.surfaceCard)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg))

                if let refinement = message.refinementSuggestion {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Button {
                            viewModel.toggleRefinement(for: message.id)
                        } label: {
                            Text(AppStrings.AIAssistant.refineSuggestionButton)
                                .font(theme.typography.caption)
                                .foregroundStyle(theme.colors.brandPrimary)
                        }

                        if message.isRefinementExpanded {
                            Text(refinement)
                                .font(theme.typography.caption)
                                .italic()
                                .foregroundStyle(theme.colors.textSecondary)
                                .padding(theme.spacing.xs)
                                .background(theme.colors.brandPrimary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: theme.radii.sm))
                        }
                    }
                }
            }

            if !message.isUser { Spacer() }
        }
    }

    private var bottomInputBar: some View {
        HStack(spacing: theme.spacing.sm) {
            TextField(AppStrings.Common.search, text: $viewModel.inputText)
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
