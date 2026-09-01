import CraftUIKit
import SwiftUI

/// Focused mini-session view to review weak vocabulary words needing reinforcement.
/// Presents clear flashcard typography, audio pronunciation, definition reveal, and instant mastery grading.
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

            VStack(spacing: 16) {
                headerBar

                if viewModel.isCompleted {
                    completionView
                } else if viewModel.weakWords.isEmpty {
                    emptyStateView
                } else if let word = viewModel.currentWord {
                    wordReviewCard(word: word)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
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
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
                    .padding(8)
                    .background(theme.colors.surfaceSubtle)
                    .clipShape(Circle())
            }

            Spacer()

            Text(AppStrings.Vault.SmartReview.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(theme.colors.textPrimary)

            Spacer()

            if !viewModel.weakWords.isEmpty && !viewModel.isCompleted {
                Text("\(viewModel.currentIndex + 1)/\(viewModel.weakWords.count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(theme.colors.accent.opacity(0.18))
                    .foregroundColor(theme.colors.accent)
                    .cornerRadius(8)
            } else {
                Color.clear
                    .frame(width: 32, height: 32)
            }
        }
    }

    // MARK: - Word Review Flashcard
    private func wordReviewCard(word: PersonalWord) -> some View {
        VStack(spacing: 20) {
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
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text(word.lemma)
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)

                    if !word.phonetic.isEmpty {
                        Text(word.phonetic)
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(theme.colors.textSecondary)
                    }

                    Button(action: {
                        viewModel.playAudio()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text(AppStrings.Vault.SmartReview.pronounce)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(theme.colors.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(theme.colors.accent.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 10)

                if viewModel.isRevealed {
                    revealedContent(word: word)
                }
            }
            .padding(20)
        }
        .background(theme.colors.surfaceCard)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.colors.hairline, lineWidth: 1.2)
        )
    }

    // MARK: - Revealed Content
    private func revealedContent(word: PersonalWord) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Divider()
                .background(theme.colors.hairline)

            VStack(alignment: .leading, spacing: 4) {
                Text(AppStrings.Vault.SmartReview.definitionVi)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.colors.textSecondary)
                    .textCase(.uppercase)

                Text(word.definitionVi)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
            }

            if !word.definitionEn.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppStrings.Vault.SmartReview.definitionEn)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(theme.colors.textSecondary)
                        .textCase(.uppercase)

                    Text(word.definitionEn)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.colors.textPrimary.opacity(0.85))
                }
            }

            if !word.exampleEn.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppStrings.Vault.SmartReview.contextExample)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(theme.colors.textSecondary)
                        .textCase(.uppercase)

                    Text(word.exampleEn)
                        .font(.system(size: 14, weight: .medium).italic())
                        .foregroundColor(theme.colors.textPrimary)

                    if !word.exampleVi.isEmpty {
                        Text(word.exampleVi)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
                .padding(12)
                .background(theme.colors.surfaceSubtle)
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Action Controls
    @ViewBuilder
    private var actionControls: some View {
        if !viewModel.isRevealed {
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    viewModel.revealDefinition()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text(AppStrings.Vault.SmartReview.showAnswer)
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(theme.colors.textPrimary)
                .clipShape(Capsule())
                .shadow(color: theme.colors.textPrimary.opacity(0.2), radius: 6, x: 0, y: 3)
                .contentShape(Rectangle())
            }
            .buttonStyle(BentoCardButtonStyle())
        } else {
            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            _ = Task { await viewModel.markCurrentReviewed(isCorrect: false) }
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text(AppStrings.Vault.SmartReview.notRemembered)
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(theme.colors.statusDanger)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(theme.colors.statusDanger.opacity(0.12))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(theme.colors.statusDanger.opacity(0.3), lineWidth: 1.2)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(BentoCardButtonStyle())

                Button(action: {
                    Task {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            _ = Task { await viewModel.markCurrentReviewed(isCorrect: true) }
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text(AppStrings.Vault.SmartReview.remembered)
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        LinearGradient(
                            colors: [theme.colors.statusSuccess, theme.colors.statusSuccess.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: theme.colors.statusSuccess.opacity(0.35), radius: 6, x: 0, y: 3)
                    .contentShape(Rectangle())
                }
                .buttonStyle(BentoCardButtonStyle())
            }
        }
    }

    // MARK: - Completion View
    private var completionView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(theme.colors.statusSuccess.opacity(0.15))
                    .frame(width: 88, height: 88)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(theme.colors.statusSuccess)
            }

            VStack(spacing: 6) {
                Text(AppStrings.Vault.SmartReview.completedTitle)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)

                Text(AppStrings.Vault.SmartReview.completedDesc(viewModel.weakWords.count))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(action: onDismiss) {
                Text(AppStrings.Vault.SmartReview.finishAndReturn)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(theme.colors.textPrimary)
                    .clipShape(Capsule())
                    .shadow(color: theme.colors.textPrimary.opacity(0.25), radius: 6, x: 0, y: 3)
                    .contentShape(Rectangle())
            }
            .buttonStyle(BentoCardButtonStyle())
        }
        .padding(.horizontal, 10)
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundColor(theme.colors.statusSuccess)

            Text(AppStrings.Vault.SmartReview.emptyTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(theme.colors.textPrimary)

            Text(AppStrings.Vault.SmartReview.emptyDesc)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button(action: onDismiss) {
                Text(AppStrings.Vault.SmartReview.close)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(theme.colors.surfaceSubtle)
                    .cornerRadius(12)
            }
        }
    }
}
