import SwiftUI

/// Focused mini-session view to review weak vocabulary words needing reinforcement.
/// Presents clear flashcard typography, audio pronunciation, definition reveal, and instant mastery grading.
public struct SmartReviewSessionView: View {
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
            Color.vocabCanvas
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
        }
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.vocabInk)
                    .padding(8)
                    .background(Color.vocabSurfaceSoft)
                    .clipShape(Circle())
            }

            Spacer()

            Text("Ôn Tập Tập Trung")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.vocabInk)

            Spacer()

            if !viewModel.weakWords.isEmpty && !viewModel.isCompleted {
                Text("\(viewModel.currentIndex + 1)/\(viewModel.weakWords.count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.vocabPeach.opacity(0.18))
                    .foregroundColor(Color.vocabPeach)
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
            .fill(Color.vocabHairline)
            .frame(height: 6)
            .overlay(
                GeometryReader { geo in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.vocabPeach, Color(hex: "FA9938")],
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
                        .foregroundColor(Color.vocabInk)
                        .multilineTextAlignment(.center)

                    if !word.phonetic.isEmpty {
                        Text(word.phonetic)
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.vocabMuted)
                    }

                    Button(action: {
                        viewModel.playAudio()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("Phát âm")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(Color.vocabPeach)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.vocabPeach.opacity(0.12))
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
        .background(Color.vocabSurfaceCard)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.vocabHairline, lineWidth: 1.2)
        )
    }

    // MARK: - Revealed Content
    private func revealedContent(word: PersonalWord) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Divider()
                .background(Color.vocabHairline)

            VStack(alignment: .leading, spacing: 4) {
                Text("Nghĩa tiếng Việt")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.vocabMuted)
                    .textCase(.uppercase)

                Text(word.definitionVi)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color.vocabInk)
            }

            if !word.definitionEn.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Định nghĩa tiếng Anh")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.vocabMuted)
                        .textCase(.uppercase)

                    Text(word.definitionEn)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.vocabInk.opacity(0.85))
                }
            }

            if !word.exampleEn.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ví dụ ngữ cảnh")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.vocabMuted)
                        .textCase(.uppercase)

                    Text(word.exampleEn)
                        .font(.system(size: 14, weight: .medium).italic())
                        .foregroundColor(Color.vocabInk)

                    if !word.exampleVi.isEmpty {
                        Text(word.exampleVi)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color.vocabMuted)
                    }
                }
                .padding(12)
                .background(Color.vocabSurfaceSoft)
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
                    Text("Hiện nghĩa & Ví dụ")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.vocabInk)
                .clipShape(Capsule())
                .shadow(color: Color.vocabInk.opacity(0.2), radius: 6, x: 0, y: 3)
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
                        Text("Chưa nhớ")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(Color.vocabCoral)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.vocabCoral.opacity(0.12))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.vocabCoral.opacity(0.3), lineWidth: 1.2)
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
                        Text("Đã nhớ")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        LinearGradient(
                            colors: [Color.vocabMint, Color(hex: "34D399")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: Color.vocabMint.opacity(0.35), radius: 6, x: 0, y: 3)
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
                    .fill(Color.vocabMint.opacity(0.15))
                    .frame(width: 88, height: 88)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Color.vocabMint)
            }

            VStack(spacing: 6) {
                Text("Hoàn Thành Ôn Tập!")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color.vocabInk)

                Text("Bạn đã ôn tập toàn bộ \(viewModel.weakWords.count) từ yếu trong phiên này.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.vocabMuted)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(action: onDismiss) {
                Text("Hoàn tất & Quay lại")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.vocabInk)
                    .clipShape(Capsule())
                    .shadow(color: Color.vocabInk.opacity(0.25), radius: 6, x: 0, y: 3)
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
                .foregroundColor(Color.vocabMint)

            Text("Không có từ yếu nào!")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color.vocabInk)

            Text("Tất cả từ vựng trong kho của bạn đang được ghi nhớ rất tốt.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.vocabMuted)
                .multilineTextAlignment(.center)

            Spacer()

            Button(action: onDismiss) {
                Text("Đóng")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.vocabInk)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.vocabSurfaceSoft)
                    .cornerRadius(12)
            }
        }
    }
}
