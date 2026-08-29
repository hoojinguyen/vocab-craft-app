import SwiftUI

/// Top Carousel Flashcard component for VocabularyView.
/// Displays flashcards in a horizontal paging TabView with highlighted lemma in example sentences,
/// audio pronunciation triggers, CEFR/POS indicators, and bookmark action.
public struct TopCarouselFlashcardView: View {
    public let words: [VaultWordItem]
    public let onAudioTap: ((VaultWordItem) -> Void)?
    public let onBookmarkTap: ((VaultWordItem) -> Void)?
    public let onWordSelected: ((VaultWordItem) -> Void)?

    @State private var selectedIndex: Int = 0

    public init(
        words: [VaultWordItem],
        onAudioTap: ((VaultWordItem) -> Void)? = nil,
        onBookmarkTap: ((VaultWordItem) -> Void)? = nil,
        onWordSelected: ((VaultWordItem) -> Void)? = nil
    ) {
        self.words = words
        self.onAudioTap = onAudioTap
        self.onBookmarkTap = onBookmarkTap
        self.onWordSelected = onWordSelected
    }

    public var body: some View {
        if words.isEmpty {
            emptyPlaceholderCard
        } else {
            TabView(selection: $selectedIndex) {
                ForEach(Array(words.enumerated()), id: \.element.id) { index, word in
                    flashcardContent(for: word)
                        .tag(index)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                }
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: words.count > 1 ? .automatic : .never))
            #endif
            .frame(height: 220)
        }
    }

    // MARK: - Flashcard Item View
    private func flashcardContent(for word: VaultWordItem) -> some View {
        Button(action: {
            onWordSelected?(word)
        }) {
            VStack(alignment: .leading, spacing: 10) {
                flashcardMetaHeader(for: word)
                flashcardWordTitle(for: word)
                flashcardExampleBox(for: word)
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.vocabSurfaceCard)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.vocabHairline, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func flashcardMetaHeader(for word: VaultWordItem) -> some View {
        HStack(alignment: .center, spacing: 6) {
            if !word.cefrLevel.isEmpty {
                Text(word.cefrLevel.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(cefrBadgeBackground(for: word.cefrLevel))
                    .foregroundColor(Color.vocabInk)
                    .cornerRadius(4)
            }

            if !word.pos.isEmpty {
                Text("(\(word.pos))")
                    .font(.system(size: 11, weight: .medium).italic())
                    .foregroundColor(Color.vocabMuted)
            }

            if word.isMastered {
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("Đã thuộc")
                        .font(.system(size: 10, weight: .bold))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.vocabMint.opacity(0.18))
                .foregroundColor(Color.vocabMint)
                .cornerRadius(4)
            } else if word.correctStreak > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("Chuỗi: \(word.correctStreak)/3")
                        .font(.system(size: 10, weight: .bold))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.vocabPeach.opacity(0.18))
                .foregroundColor(Color.vocabPeach)
                .cornerRadius(4)
            }

            Spacer()

            Button(action: {
                onBookmarkTap?(word)
            }) {
                Image(systemName: word.isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(word.isBookmarked ? Color.vocabPeach : Color.vocabMuted)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .frame(minWidth: 44, minHeight: 44)

            Button(action: {
                onAudioTap?(word)
            }) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.vocabHeroAccent)
                    .frame(width: 34, height: 34)
                    .background(Color.vocabHeroAccent.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .frame(minWidth: 44, minHeight: 44)
        }
    }

    private func flashcardWordTitle(for word: VaultWordItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(word.lemma)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(Color.vocabInk)

                if !word.phonetic.isEmpty {
                    Text(word.phonetic)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.vocabMuted)
                }
            }

            Text(word.definitionVi)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.vocabInk)
                .lineLimit(2)
        }
    }

    @ViewBuilder
    private func flashcardExampleBox(for word: VaultWordItem) -> some View {
        if !word.exampleSentenceEn.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                highlightedExample(sentence: word.exampleSentenceEn, lemma: word.lemma)

                if !word.exampleSentenceVi.isEmpty {
                    Text(word.exampleSentenceVi)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color.vocabMuted)
                        .lineLimit(1)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.vocabSurfaceSoft)
            .cornerRadius(8)
        }
    }

    // MARK: - Example Sentence Highlighting
    @ViewBuilder
    private func highlightedExample(sentence: String, lemma: String) -> some View {
        if let range = sentence.range(of: lemma, options: .caseInsensitive) {
            let prefix = String(sentence[..<range.lowerBound])
            let match = String(sentence[range])
            let suffix = String(sentence[range.upperBound...])

            (
                Text(prefix)
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundColor(Color.vocabInk)
                +
                Text(match)
                    .font(.system(size: 12, weight: .bold, design: .serif))
                    .foregroundColor(Color.vocabHeroAccent)
                +
                Text(suffix)
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundColor(Color.vocabInk)
            )
            .lineLimit(2)
        } else {
            Text(sentence)
                .font(.system(size: 12, weight: .medium, design: .serif))
                .foregroundColor(Color.vocabInk)
                .lineLimit(2)
        }
    }

    // MARK: - Empty Placeholder Card
    private var emptyPlaceholderCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 24))
                .foregroundColor(Color.vocabHeroAccent)

            Text("Kho từ của bạn")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.vocabInk)

            Text("Nạp từ vựng hoặc luyện tập để xem thẻ từ tại đây.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.vocabMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.vocabHairline, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private func cefrBadgeBackground(for level: String) -> Color {
        switch level.uppercased() {
        case "A1", "A2":
            return Color.vocabMint.opacity(0.18)
        case "B1", "B2":
            return Color.vocabPeach.opacity(0.18)
        case "C1", "C2":
            return Color.vocabLavender.opacity(0.18)
        default:
            return Color.vocabSurfaceSoft
        }
    }
}
