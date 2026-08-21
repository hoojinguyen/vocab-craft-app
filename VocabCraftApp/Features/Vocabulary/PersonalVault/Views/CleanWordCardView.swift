import SwiftUI

/// Elegant accordion word card view for the Personal Vault.
/// Features Serif typography, audio playback, CEFR badge, 5-bar mastery indicator, and rich expanded definitions.
/// ZERO per-word micro-drill buttons (following anti-AI slop Apple HIG guidelines).
public struct CleanWordCardView: View {
    public let word: PersonalWord
    public let isExpanded: Bool
    public let onTap: () -> Void
    public let onAudioTap: () -> Void
    public let onBookmarkTap: () -> Void

    public init(
        word: PersonalWord,
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
            // Header / Collapsed Row
            Button(action: onTap) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(word.lemma)
                                .font(.system(size: 17, weight: .bold, design: .serif))
                                .foregroundColor(Color.vocabInk)

                            if !word.phonetic.isEmpty {
                                Text(word.phonetic)
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color.vocabMuted)
                            }

                            Button(action: {
                                onAudioTap()
                            }) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color.vocabPeach)
                                    .padding(4)
                                    .background(Color.vocabPeach.opacity(0.12))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        HStack(spacing: 6) {
                            if !word.cefrLevel.isEmpty {
                                Text(word.cefrLevel)
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(cefrBadgeBackground)
                                    .foregroundColor(Color.vocabInk)
                                    .cornerRadius(4)
                            }

                            if !word.pos.isEmpty {
                                Text("(\(word.pos))")
                                    .font(.system(size: 11, weight: .medium).italic())
                                    .foregroundColor(Color.vocabMuted)
                            }

                            if word.needsReview {
                                Text("Cần ôn")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.vocabPeach.opacity(0.2))
                                    .foregroundColor(Color.vocabPeach)
                                    .cornerRadius(4)
                            }
                        }
                    }

                    Spacer()

                    // Right Side: 5-Bar Mastery & Bookmark & Expand Chevron
                    HStack(spacing: 10) {
                        masteryBars(level: word.masteryLevel)

                        Button(action: onBookmarkTap) {
                            Image(systemName: word.isBookmarked ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(word.isBookmarked ? Color.vocabPeach : Color.vocabMuted)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.vocabMuted)
                    }
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()
                        .background(Color.vocabHairline)

                    // Bilingual Definitions
                    VStack(alignment: .leading, spacing: 4) {
                        Text(word.definitionVi)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.vocabInk)

                        if !word.definitionEn.isEmpty {
                            Text(word.definitionEn)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color.vocabMuted)
                        }
                    }

                    // Contextual Examples
                    if !word.exampleEn.isEmpty {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "quote.opening")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.vocabMuted)

                                Text(word.exampleEn)
                                    .font(.system(size: 13, weight: .medium).italic())
                                    .foregroundColor(Color.vocabInk)
                            }

                            if !word.exampleVi.isEmpty {
                                Text(word.exampleVi)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color.vocabMuted)
                                    .padding(.leading, 16)
                            }
                        }
                        .padding(10)
                        .background(Color.vocabSurfaceSoft)
                        .cornerRadius(8)
                    }

                    // Stage / Deck Source
                    if let deck = word.sourceDeckTitle ?? word.sourceStageTitle {
                        HStack(spacing: 4) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Color.vocabMuted)

                            Text(deck)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color.vocabMuted)
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.vocabSurfaceCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    word.needsReview ? Color.vocabPeach.opacity(0.35) : Color.vocabHairline,
                    lineWidth: word.needsReview ? 1.2 : 1
                )
        )
        .shadow(
            color: word.needsReview ? Color.vocabPeach.opacity(0.06) : Color.black.opacity(0.02),
            radius: 4,
            x: 0,
            y: 2
        )
    }

    // MARK: - 5-Bar Mastery Indicator
    private func masteryBars(level: Int) -> some View {
        HStack(spacing: 2.5) {
            ForEach(1...5, id: \.self) { barIndex in
                Capsule()
                    .fill(barIndex <= level ? Color.vocabMint : Color.vocabHairline)
                    .frame(width: 4, height: 14)
            }
        }
    }

    private var cefrBadgeBackground: Color {
        switch word.cefrLevel.uppercased() {
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
