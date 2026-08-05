import SwiftUI

public struct WordAccordionCard: View {
    public let item: WordItem
    public let isExpanded: Bool
    public let onTap: () -> Void
    public let onAudioTap: () -> Void
    public let onDrillTap: () -> Void

    public init(
        item: WordItem,
        isExpanded: Bool,
        onTap: @escaping () -> Void,
        onAudioTap: @escaping () -> Void,
        onDrillTap: @escaping () -> Void
    ) {
        self.item = item
        self.isExpanded = isExpanded
        self.onTap = onTap
        self.onAudioTap = onAudioTap
        self.onDrillTap = onDrillTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row (Tappable)
            Button(action: onTap) {
                HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(item.lemma)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(Color.vocabInk)
                            
                            Text(item.pos)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.vocabMuted)
                        }
                        
                        Text(item.phonetic)
                            .font(.system(size: 13, weight: .medium, design: .serif))
                            .foregroundColor(Color.vocabMuted)
                    }
                    
                    Spacer()
                    
                    // CEFR Badge
                    Text(item.cefrLevel)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(cefrColor(item.cefrLevel).opacity(0.18))
                        .foregroundColor(Color.vocabInk)
                        .cornerRadius(8)
                    
                    // SRS Mastery Stars
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= item.masteryLevel ? "star.fill" : "star")
                                .font(.system(size: 9))
                                .foregroundColor(star <= item.masteryLevel ? Color.vocabMint : Color.vocabMuted.opacity(0.4))
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Collapsed Definition Snippet
            if !isExpanded {
                Text(item.definition)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.vocabMuted)
                    .lineLimit(1)
            }

            // Expanded Detail Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()
                        .overlay(Color.vocabHairline)

                    // Definition
                    Text(item.definition)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.vocabInk)

                    // Example Sentence + TTS Audio Button
                    HStack(alignment: .top, spacing: 10) {
                        Button(action: onAudioTap) {
                            ZStack {
                                Circle()
                                    .fill(Color.vocabHeroAccent.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.vocabHeroAccent)
                            }
                            .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.exampleSentenceEn)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.vocabInk)
                            Text(item.exampleSentenceVi)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Color.vocabMuted)
                        }
                    }

                    // Quick Practice Button
                    Button(action: onDrillTap) {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text("Luyện phản xạ từ này")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(Color.vocabInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.vocabPeach.opacity(0.25))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.vocabHairline, lineWidth: 1.5)
        )
        .shadow(color: Color.vocabHeroTeal.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    private func cefrColor(_ level: String) -> Color {
        switch level {
        case "A1", "A2": return Color.vocabMint
        case "B1", "B2": return Color.vocabPeach
        case "C1", "C2": return Color.vocabLavender
        default: return Color.vocabMint
        }
    }
}
