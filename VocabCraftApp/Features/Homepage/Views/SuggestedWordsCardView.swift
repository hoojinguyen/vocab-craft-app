import SwiftUI

/// Refactored Minimalist Card Section presenting daily suggested words with clean typography, compact height (~145pt), and zero clutter.
public struct SuggestedWordsCardView: View {
    public let words: [SuggestedWord]
    @Binding public var selectedIndex: Int
    public let onBookmarkToggle: (String) -> Void
    public let onSpeakTap: ((SuggestedWord) -> Void)?

    @State private var isPlayingAudio: Bool = false

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
                Text("GỢI Ý TỪ MỚI")
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
                .frame(height: 145)
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
            // Top Row: CEFR Badge, POS tag & Action Buttons
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
                    // Audio Speaker Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPlayingAudio = true
                        }
                        onSpeakTap?(word)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            isPlayingAudio = false
                        }
                    }) {
                        Image(systemName: isPlayingAudio ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(isPlayingAudio ? Color.vocabMint : Color.vocabInk)
                            .frame(width: 32, height: 32)
                            .background(Color.vocabSurfaceSoft)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    // Bookmark Button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            onBookmarkToggle(word.id)
                        }
                    }) {
                        Image(systemName: word.isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(word.isBookmarked ? Color.vocabPeach : Color.vocabMuted)
                            .frame(width: 32, height: 32)
                            .background(word.isBookmarked ? Color.vocabPeach.opacity(0.12) : Color.vocabSurfaceSoft)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }

            // Word Lemma & Phonetics
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(word.lemma)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(Color.vocabInk)

                Text(word.ipaUs)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color.vocabMuted)
            }

            // Vietnamese Definition Only
            Text(word.definitionVi)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.vocabInk)
                .lineLimit(2)

            // Simple Unboxed Example Sentence
            if !word.example.isEmpty {
                Text("Ex: “\(word.example)”")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color.vocabMuted)
                    .italic()
                    .lineLimit(2)
            }
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
