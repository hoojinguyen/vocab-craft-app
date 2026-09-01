import CraftUIKit
import SwiftUI

/// Focused mini-session view to review weak vocabulary words needing reinforcement.
/// Built 100% with CraftUIKit components and theme tokens.
public struct SmartReviewSessionView: View {
    @Environment(\.craftTheme) private var theme
    @State private var viewModel: SmartReviewViewModel
    public let onDismiss: () -> Void

    public init(
        viewModel: SmartReviewViewModel,
        onDismiss: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            VStack(spacing: theme.spacing.base) {
                headerBar

                if viewModel.isCompleted {
                    completionView
                } else if viewModel.weakWords.isEmpty {
                    emptyStateView
                } else if let word = viewModel.currentWord {
                    wordReviewCard(word: word)
                }
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.top, theme.spacing.base)
            .padding(.bottom, theme.spacing.lg)
        }
        .task {
            await viewModel.loadWeakWords()
            let args = ProcessInfo.processInfo.arguments
            if let stateIdx = args.firstIndex(of: "-vocab-state"), stateIdx + 1 < args.count {
                let state = args[stateIdx + 1]
                if state == "smart-review-revealed" {
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    viewModel.revealDefinition()
                } else if state == "smart-review-completed" {
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    while !viewModel.isCompleted && !viewModel.weakWords.isEmpty {
                        await viewModel.markCurrentReviewed(isCorrect: true)
                    }
                }
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            CraftIconButton(
                symbol: .close,
                size: .md,
                variant: .subtle,
                accessibilityLabel: AppStrings.Vault.SmartReview.closeText,
                action: onDismiss
            )

            Spacer()

            Text(AppStrings.Vault.SmartReview.title)
                .font(theme.typography.headline)
                .fontWeight(.bold)
                .foregroundStyle(theme.colors.textPrimary)

            Spacer()

            if !viewModel.weakWords.isEmpty && !viewModel.isCompleted {
                CraftBadge(
                    verbatim: "\(viewModel.currentIndex + 1)/\(viewModel.weakWords.count)",
                    variant: .subtle,
                    tone: .primary,
                    size: .sm,
                    customTint: theme.colors.accent
                )
            } else {
                Color.clear
                    .frame(width: 36, height: 36)
            }
        }
    }

    // MARK: - Word Review Flashcard

    private func wordReviewCard(word: PersonalWord) -> some View {
        VStack(spacing: theme.spacing.base) {
            progressBar
            flashcardBody(word: word)
            Spacer()
            actionControls
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        let progressFraction = Double(viewModel.currentIndex + 1) / Double(max(viewModel.weakWords.count, 1))
        return Capsule()
            .fill(theme.colors.hairline)
            .frame(height: 6)
            .overlay(
                GeometryReader { geo in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [theme.colors.accent, theme.colors.accent.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(progressFraction))
                }
            )
    }

    // MARK: - Flashcard Body

    private func flashcardBody(word: PersonalWord) -> some View {
        CraftCard(
            style: .elevated,
            cornerRadius: theme.radii.xl,
            padding: theme.spacing.lg
        ) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: theme.spacing.base) {
                    VStack(spacing: theme.spacing.xs) {
                        Text(word.lemma)
                            .font(theme.typography.displayLarge)
                            .fontWeight(.bold)
                            .foregroundStyle(theme.colors.textPrimary)
                            .multilineTextAlignment(.center)

                        if !word.phonetic.isEmpty {
                            Text(word.phonetic)
                                .font(theme.typography.phonetic)
                                .foregroundStyle(theme.colors.textSecondary)
                        }

                        CraftButton(
                            AppStrings.Vault.SmartReview.pronounce,
                            iconName: CraftSymbol.audio.rawValue,
                            variant: .secondary,
                            size: .sm,
                            action: {
                                viewModel.playAudio()
                            }
                        )
                        .padding(.top, theme.spacing.xxs)
                    }
                    .padding(.top, theme.spacing.xs)

                    if viewModel.isRevealed {
                        revealedContent(word: word)
                    }
                }
            }
        }
    }

    // MARK: - Revealed Content

    private func revealedContent(word: PersonalWord) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Divider()
                .background(theme.colors.hairline)

            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(AppStrings.Vault.SmartReview.definitionVi)
                    .font(theme.typography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.colors.textSecondary)
                    .textCase(.uppercase)

                Text(word.definitionVi)
                    .font(theme.typography.titleLarge)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.colors.textPrimary)
            }

            if !word.definitionEn.isEmpty {
                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    Text(AppStrings.Vault.SmartReview.definitionEn)
                        .font(theme.typography.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.colors.textSecondary)
                        .textCase(.uppercase)

                    Text(word.definitionEn)
                        .font(theme.typography.bodyMedium)
                        .foregroundStyle(theme.colors.textPrimary.opacity(0.85))
                }
            }

            if !word.exampleEn.isEmpty {
                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    Text(AppStrings.Vault.SmartReview.contextExample)
                        .font(theme.typography.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.colors.textSecondary)
                        .textCase(.uppercase)

                    Text(word.exampleEn)
                        .font(theme.typography.bodyMedium.italic())
                        .foregroundStyle(theme.colors.textPrimary)

                    if !word.exampleVi.isEmpty {
                        Text(word.exampleVi)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }
                .padding(theme.spacing.sm)
                .background(theme.colors.surfaceSubtle)
                .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Action Controls

    @ViewBuilder
    private var actionControls: some View {
        if !viewModel.isRevealed {
            CraftButton(
                AppStrings.Vault.SmartReview.showAnswer,
                iconName: CraftSymbol.eye.rawValue,
                variant: .tactile,
                size: .lg,
                isFullWidth: true,
                action: {
                    withAnimation(theme.animations.springSmooth) {
                        viewModel.revealDefinition()
                    }
                }
            )
        } else {
            HStack(spacing: theme.spacing.md) {
                CraftButton(
                    AppStrings.Vault.SmartReview.notRemembered,
                    iconName: CraftSymbol.wrongCircle.rawValue,
                    variant: .secondary,
                    size: .lg,
                    isFullWidth: true,
                    action: {
                        Task {
                            withAnimation(theme.animations.springSmooth) {
                                _ = Task { await viewModel.markCurrentReviewed(isCorrect: false) }
                            }
                        }
                    }
                )

                CraftButton(
                    AppStrings.Vault.SmartReview.remembered,
                    iconName: CraftSymbol.checkmarkCircle.rawValue,
                    variant: .primary,
                    size: .lg,
                    isFullWidth: true,
                    action: {
                        Task {
                            withAnimation(theme.animations.springSmooth) {
                                _ = Task { await viewModel.markCurrentReviewed(isCorrect: true) }
                            }
                        }
                    }
                )
            }
        }
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: theme.spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(theme.colors.statusSuccess.opacity(0.15))
                    .frame(width: 88, height: 88)

                CraftIcon(
                    .checkmarkCircle,
                    size: .xl,
                    color: theme.colors.statusSuccess
                )
            }

            VStack(spacing: theme.spacing.xs) {
                Text(AppStrings.Vault.SmartReview.completedTitle)
                    .font(theme.typography.titleLarge)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.colors.textPrimary)

                Text(AppStrings.Vault.SmartReview.completedDesc(viewModel.weakWords.count))
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            CraftButton(
                AppStrings.Vault.SmartReview.finishAndReturn,
                variant: .tactile,
                size: .lg,
                isFullWidth: true,
                action: onDismiss
            )
        }
        .padding(.horizontal, theme.spacing.xs)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: theme.spacing.base) {
            Spacer()

            CraftIcon(
                .sparkles,
                size: .xl,
                color: theme.colors.statusSuccess
            )

            Text(AppStrings.Vault.SmartReview.emptyTitle)
                .font(theme.typography.titleLarge)
                .fontWeight(.bold)
                .foregroundStyle(theme.colors.textPrimary)

            Text(AppStrings.Vault.SmartReview.emptyDesc)
                .font(theme.typography.bodyMedium)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            CraftButton(
                AppStrings.Vault.SmartReview.close,
                variant: .secondary,
                size: .md,
                isFullWidth: true,
                action: onDismiss
            )
        }
    }
}
