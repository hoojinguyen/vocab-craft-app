import SwiftUI

/// Elegant accordion word card component for displaying a `VaultWordItem` in the Vocabulary Hub.
/// Follows Apple HIG standards: 44x44pt touch targets, clean typography, CEFR badge,
/// audio pronunciation trigger, bookmark toggle, and expandable contextual sentences.
public struct VaultWordCardView: View {
    public let word: VaultWordItem
    public let isExpanded: Bool
    public let onTap: () -> Void
    public let onAudioTap: () -> Void
    public let onBookmarkTap: () -> Void

    public init(
        word: VaultWordItem,
        isExpanded: Bool,
        onTap: @escaping () -> Void,
        onAudioTap: @escaping () -> Void,
        onBookmarkTap: @escaping () -> Void
    ) {
        self.word = word
        self.isExpanded = isExpanded
        self.onTap = onTap
        self.onAudioTap = onAudioTap
        self.onBookmarkTap = onBookmarkTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main Collapsed / Header Row
            Button(action: onTap) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 8) {
                            Text(word.lemma)
                                .font(.system(size: 17, weight: .bold, design: .serif))
                                .foregroundColor(Color.vocabInk)

                            if !word.phonetic.isEmpty {
                                Text(word.phonetic)
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color.vocabMuted)
                            }

                            Button(action: onAudioTap) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color.vocabHeroAccent)
                                    .padding(5)
                                    .background(Color.vocabHeroAccent.opacity(0.12))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                        }

                        HStack(spacing: 6) {
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

                            Text(word.definitionVi)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.vocabMuted)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Right Accessories: Mastery/Streak status + Bookmark + Expand Chevron
                    HStack(spacing: 8) {
                        if word.isMastered {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.vocabMint)
                                .accessibilityLabel("Đã thuộc")
                        } else if word.correctStreak > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 11, weight: .bold))
                                Text("\(word.correctStreak)/3")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(Color.vocabPeach)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.vocabPeach.opacity(0.15))
                            .clipShape(Capsule())
                        }

                        Button(action: onBookmarkTap) {
                            Image(systemName: word.isBookmarked ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(word.isBookmarked ? Color.vocabPeach : Color.vocabMuted)
                                .frame(width: 36, height: 36)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(minWidth: 44, minHeight: 44)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.vocabMuted)
                            .frame(width: 20, height: 44)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded Context Section
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .background(Color.vocabHairline)

                    // Definition
                    Text(word.definitionVi)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.vocabInk)

                    // Example Sentence
                    if !word.exampleSentenceEn.isEmpty {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "quote.opening")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.vocabMuted)

                                highlightedExample(sentence: word.exampleSentenceEn, lemma: word.lemma)
                            }

                            if !word.exampleSentenceVi.isEmpty {
                                Text(word.exampleSentenceVi)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color.vocabMuted)
                                    .padding(.leading, 16)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.vocabSurfaceSoft)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.vocabSurfaceCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    word.isMastered ? Color.vocabMint.opacity(0.35) : Color.vocabHairline,
                    lineWidth: 1
                )
        )
        .shadow(
            color: Color.black.opacity(0.02),
            radius: 4,
            x: 0,
            y: 2
        )
    }

    @ViewBuilder
    private func highlightedExample(sentence: String, lemma: String) -> some View {
        if let range = sentence.range(of: lemma, options: .caseInsensitive) {
            let prefix = String(sentence[..<range.lowerBound])
            let match = String(sentence[range])
            let suffix = String(sentence[range.upperBound...])

            (
                Text(prefix)
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundColor(Color.vocabInk)
                +
                Text(match)
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundColor(Color.vocabHeroAccent)
                +
                Text(suffix)
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundColor(Color.vocabInk)
            )
        } else {
            Text(sentence)
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundColor(Color.vocabInk)
        }
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
