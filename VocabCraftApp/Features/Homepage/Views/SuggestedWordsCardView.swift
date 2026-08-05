import SwiftUI

/// Premium Bento-style card section presenting daily recommended vocabulary words with swipeable paging gestures.
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
        VStack(spacing: 12) {
            // Section Header & Navigation Hint
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.vocabPeach)
                    Text("GỢI Ý TỪ MỚI HÔM NAY")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.vocabMuted)
                        .tracking(0.5)
                }

                Spacer()

                // Swipe affordance label
                HStack(spacing: 4) {
                    Image(systemName: "hand.draw")
                        .font(.system(size: 12))
                    Text("Vuốt để đổi từ")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(Color.vocabMuted.opacity(0.8))
            }
            .padding(.horizontal)

            if !words.isEmpty {
                // Horizontal Paging TabView for Swipe Gesture
                TabView(selection: $selectedIndex) {
                    ForEach(words.indices, id: \.self) { index in
                        suggestedCard(for: words[index])
                            .tag(index)
                    }
                }
                .frame(height: 245)
#if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
#else
                .tabViewStyle(.automatic)
#endif

                // Custom Modern Page Indicator Dots
                HStack(spacing: 6) {
                    ForEach(words.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == selectedIndex ? Color.vocabHeroAccent : Color.vocabHairline)
                            .frame(width: index == selectedIndex ? 20 : 6, height: 6)
                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: selectedIndex)
                    }
                }
                .padding(.top, 2)
            }
        }
    }

    @ViewBuilder
    private func suggestedCard(for word: SuggestedWord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top Row: CEFR Badge, Topic Tag & Actions (Sound, Bookmark)
            HStack(alignment: .center) {
                // CEFR Level Tag
                Text(word.cefrLevel)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(cefrColor(for: word.cefrLevel))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(cefrColor(for: word.cefrLevel).opacity(0.15))
                    .clipShape(Capsule())

                // Part of Speech tag
                Text(word.pos)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.vocabMuted)
                    .italic()

                Spacer()

                // Audio Speaker Button (44x44pt touch target)
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
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isPlayingAudio ? Color.vocabMint : Color.vocabInk)
                        .frame(width: 36, height: 36)
                        .background(Color.vocabSurfaceSoft)
                        .clipShape(Circle())
                        .scaleEffect(isPlayingAudio ? 1.15 : 1.0)
                }
                .buttonStyle(.plain)

                // Bookmark Button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        onBookmarkToggle(word.id)
                    }
                }) {
                    Image(systemName: word.isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(word.isBookmarked ? Color.vocabPeach : Color.vocabMuted)
                        .frame(width: 36, height: 36)
                        .background(word.isBookmarked ? Color.vocabPeach.opacity(0.12) : Color.vocabSurfaceSoft)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            // Word Lemma & Phonetics
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(word.lemma)
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundColor(Color.vocabInk)

                    Text(word.ipaUs)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color.vocabMuted)
                }
            }

            // Definition Section
            VStack(alignment: .leading, spacing: 4) {
                Text(word.definitionVi)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.vocabInk)
                    .lineLimit(2)

                Text(word.definitionEn)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color.vocabMuted)
                    .lineLimit(2)
            }

            // Example Sentence Box
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.vocabHeroAccent)
                    .frame(width: 3)
                    .cornerRadius(1.5)

                Text("“\(word.example)”")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.vocabInk.opacity(0.85))
                    .italic()
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .padding(10)
            .background(Color.vocabSurfaceSoft.opacity(0.6))
            .cornerRadius(10)
        }
        .padding(16)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.vocabHairline, lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
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
