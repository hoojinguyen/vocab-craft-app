import SwiftUI

/// Step 1 of the Stage Learning Flow: Explore & listen to stage words, phonetic, definition, bilingual examples, and bookmark words before the quiz challenge.
public struct StagePreviewSheet: View {
    public let stage: SubTopicStage
    public let onStartChallenge: () -> Void
    public var onToggleBookmark: ((TopicWord) -> Void)?
    public var onClose: (() -> Void)?

    @State private var bookmarkedWordIds: Set<String> = []
    private let ttsService: TextToSpeechProtocol

    public init(
        stage: SubTopicStage,
        onStartChallenge: @escaping () -> Void,
        onToggleBookmark: ((TopicWord) -> Void)? = nil,
        onClose: (() -> Void)? = nil,
        ttsService: TextToSpeechProtocol? = nil
    ) {
        self.stage = stage
        self.onStartChallenge = onStartChallenge
        self.onToggleBookmark = onToggleBookmark
        self.onClose = onClose
        self.ttsService = ttsService ?? TextToSpeechService()

        let initialBookmarks = Set(stage.words.filter(\.isSavedToPersonalVault).map(\.id))
        _bookmarkedWordIds = State(initialValue: initialBookmarks)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()
                .background(Color.vocabHairline)

            // Words List
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(stage.words) { word in
                        wordPreviewCard(for: word)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100) // Spacing for floating bottom bar
            }

            // Fixed Bottom CTA
            bottomCtaBar
        }
        .background(Color.vocabCanvas.ignoresSafeArea())
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.vocabPeach.opacity(0.2), Color(hex: "FA9938").opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: stage.iconName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.vocabPeach)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(stage.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.vocabInk)
                    .lineLimit(1)

                Text("\(stage.words.count) từ vựng cốt lõi")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.vocabMuted)
            }

            Spacer()

            if let onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.vocabMuted)
                        .padding(8)
                        .background(Color.vocabSurfaceSoft)
                        .clipShape(Circle())
                }
            }
        }
    }

    // MARK: - Word Preview Card
    private func wordPreviewCard(for word: TopicWord) -> some View {
        let isBookmarked = bookmarkedWordIds.contains(word.id) || word.isSavedToPersonalVault

        return VStack(alignment: .leading, spacing: 10) {
            // Word Header (English + POS + Phonetic + Actions)
            HStack(alignment: .center, spacing: 8) {
                Text(word.english)
                    .font(.system(size: 19, weight: .bold, design: .serif))
                    .foregroundColor(Color.vocabInk)

                if !word.partOfSpeech.isEmpty {
                    Text(word.partOfSpeech.lowercased())
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.vocabMint.opacity(0.15))
                        .foregroundColor(Color.vocabInk)
                        .cornerRadius(6)
                }

                Spacer()

                // TTS Audio Speaker Button
                Button(action: {
                    ttsService.speak(text: word.english)
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.vocabInk)
                        .frame(width: 32, height: 32)
                        .background(Color.vocabSurfaceSoft)
                        .clipShape(Circle())
                }
                .buttonStyle(BentoCardButtonStyle())
                .accessibilityLabel("Nghe phát âm \(word.english)")

                // Bookmark Button
                Button(action: {
                    if bookmarkedWordIds.contains(word.id) {
                        bookmarkedWordIds.remove(word.id)
                    } else {
                        bookmarkedWordIds.insert(word.id)
                    }
                    onToggleBookmark?(word)
                }) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isBookmarked ? Color.vocabPeach : Color.vocabMuted)
                        .frame(width: 32, height: 32)
                        .background(isBookmarked ? Color.vocabPeach.opacity(0.12) : Color.vocabSurfaceSoft)
                        .clipShape(Circle())
                }
                .buttonStyle(BentoCardButtonStyle())
                .accessibilityLabel(isBookmarked ? "Bỏ lưu từ" : "Lưu vào kho cá nhân")
            }

            // Phonetic
            if !word.phonetic.isEmpty {
                Text(word.phonetic)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color.vocabMuted)
            }

            // Vietnamese Definition
            Text(word.vietnamese)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.vocabInk)

            // Example Sentence (Bilingual)
            if !word.example.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 6) {
                        Text("“")
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .foregroundColor(Color.vocabPeach)

                        Text(word.example)
                            .font(.system(size: 13, weight: .medium))
                            .italic()
                            .foregroundColor(Color.vocabInk.opacity(0.85))
                    }

                    if !word.exampleVi.isEmpty {
                        Text(word.exampleVi)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color.vocabMuted)
                            .padding(.leading, 12)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.vocabCanvas)
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.vocabHairline, lineWidth: 1)
        )
    }

    // MARK: - Bottom CTA Bar
    private var bottomCtaBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.vocabHairline)

            Button(action: onStartChallenge) {
                HStack(spacing: 8) {
                    Text("Bắt đầu Thử thách Chặng (\(stage.words.count) câu)")
                        .font(.system(size: 15, weight: .bold))

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [Color.vocabPeach, Color(hex: "FA9938")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.vocabPeach.opacity(0.35), radius: 8, x: 0, y: 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(BentoCardButtonStyle())
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .background(Color.vocabSurfaceCard.ignoresSafeArea(edges: .bottom))
    }
}
