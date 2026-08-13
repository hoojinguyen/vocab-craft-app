import SwiftUI

/// Refactored Minimalist Card Section presenting daily suggested words with clean typography, compact height (~145pt), and zero clutter.
public struct SuggestedWordsCardView: View {
    public let words: [SuggestedWord]
    @Binding public var selectedIndex: Int
    public let onBookmarkToggle: (String) -> Void
    public let onSpeakTap: ((SuggestedWord) -> Void)?

    @State private var playingWordId: String?

    public init(
        words: [SuggestedWord],
        selectedIndex: Binding<Int>,
        onBookmarkToggle: @escaping (String) -> Void,
        onSpeakTap: ((SuggestedWord) -> Void)? = nil
    ) {
        self.words = words
        self._selectedIndex = selectedIndex
        self.onBookmarkToggle = onBookmarkToggle
        self.onSpeakTap = onSpeakTap
    }

    public var body: some View {
        VStack(spacing: 8) {
            // Combined Single-line Header: Section Title & Minimalist Page Indicator Dots
            HStack {
                Text(AppStrings.Homepage.suggestedWordsTitle)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.vocabMuted)
                    .tracking(0.5)

                Spacer()

                if !words.isEmpty {
                    HStack(spacing: 5) {
                        ForEach(words.indices, id: \.self) { index in
                            Circle()
                                .fill(index == selectedIndex ? Color.vocabMint : Color.vocabHairline)
                                .frame(width: index == selectedIndex ? 7 : 5, height: index == selectedIndex ? 7 : 5)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedIndex)
                        }
                    }
                }
            }
            .padding(.horizontal)

            if !words.isEmpty {
                // Compact Paging TabView (~145pt height)
                TabView(selection: $selectedIndex) {
                    ForEach(words.indices, id: \.self) { index in
                        suggestedCard(for: words[index])
                            .tag(index)
                    }
                }
                .frame(height: 160)
#if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
#else
                .tabViewStyle(.automatic)
#endif
            }
        }
    }

    @ViewBuilder
    private func suggestedCard(for word: SuggestedWord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            cardHeader(for: word)
            cardTitleRow(for: word)
            cardContent(for: word)
        }
        .padding(14)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.vocabHairline, lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func cardHeader(for word: SuggestedWord) -> some View {
        HStack(alignment: .center) {
            HStack(spacing: 6) {
                Text(word.cefrLevel)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(cefrColor(for: word.cefrLevel))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(cefrColor(for: word.cefrLevel).opacity(0.15))
                    .clipShape(Capsule())

                Text(word.pos)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.vocabMuted)
                    .italic()
            }

            Spacer()

            HStack(spacing: 8) {
                let isPlayingThisWord: Bool = (playingWordId == word.id)
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        playingWordId = word.id
                    }
                    onSpeakTap?(word)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        if playingWordId == word.id {
                            playingWordId = nil
                        }
                    }
                }) {
                    Image(systemName: isPlayingThisWord ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isPlayingThisWord ? Color.vocabMint : Color.vocabInk)
                        .frame(width: 36, height: 36)
                        .background(isPlayingThisWord ? Color.vocabMint.opacity(0.18) : Color.vocabSurfaceSoft)
                        .clipShape(Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(BentoCardButtonStyle())

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        onBookmarkToggle(word.id)
                    }
                }) {
                    Image(systemName: word.isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(word.isBookmarked ? Color.vocabPeach : Color.vocabMuted)
                        .frame(width: 36, height: 36)
                        .background(word.isBookmarked ? Color.vocabPeach.opacity(0.15) : Color.vocabSurfaceSoft)
                        .clipShape(Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(BentoCardButtonStyle())
            }
        }
    }

    @ViewBuilder
    private func cardTitleRow(for word: SuggestedWord) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(word.lemma)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundColor(Color.vocabInk)

            Text(word.ipaUs)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(Color.vocabMuted)
        }
    }

    @ViewBuilder
    private func cardContent(for word: SuggestedWord) -> some View {
        Text(word.definitionVi)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Color.vocabInk)
            .lineLimit(2)

        if !word.example.isEmpty {
            Text("Ex: “\(word.example)”")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color.vocabMuted)
                .italic()
                .lineLimit(2)
        }
    }

    private func cefrColor(for level: String) -> Color {
        switch level.uppercased() {
        case "A1", "A2":
            return Color.vocabMint
        case "B1", "B2":
            return Color.vocabPeach
        case "C1", "C2":
            return Color.vocabLavender
        default:
            return Color.vocabHeroAccent
        }
    }
}
