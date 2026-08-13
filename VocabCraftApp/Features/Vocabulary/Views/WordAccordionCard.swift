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
                                .font(.system(size: 19, weight: .bold, design: .serif))
                                .foregroundColor(Color.vocabInk)

                            Text(item.pos)
                                .font(.system(size: 11, weight: .semibold, design: .serif))
                                .italic()
                                .foregroundColor(Color.vocabMuted)
                        }

                        Text(item.phonetic)
                            .font(.system(size: 13, weight: .medium, design: .serif))
                            .foregroundColor(Color.vocabMuted)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 5) {
                        // CEFR Badge
                        Text(item.cefrLevel)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(cefrColor(item.cefrLevel).opacity(0.18))
                            .foregroundColor(cefrColor(item.cefrLevel))
                            .cornerRadius(8)

                        // SRS Mastery Meter (Clean 5-segment bar)
                        HStack(spacing: 3) {
                            ForEach(1...5, id: \.self) { level in
                                Capsule()
                                    .fill(level <= item.masteryLevel ? Color.vocabMint : Color.vocabMuted.opacity(0.25))
                                    .frame(width: 7, height: 4)
                            }
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
                VStack(alignment: .leading, spacing: 12) {
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
                                    .fill(Color.vocabHeroAccent.opacity(0.14))
                                    .frame(width: 38, height: 38)
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.vocabHeroAccent)
                            }
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(BentoCardButtonStyle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.exampleSentenceEn)
                                .font(.system(size: 13, weight: .medium, design: .serif))
                                .foregroundColor(Color.vocabInk)
                            Text(item.exampleSentenceVi)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Color.vocabMuted)
                        }
                    }

                    // Quick Practice Button (Primary CTA Upgrade)
                    Button(action: onDrillTap) {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text(AppStrings.Homepage.practiceNow)
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            LinearGradient(
                                colors: [Color.vocabPeach, Color(hex: "FA9938")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.vocabPeach.opacity(0.35), radius: 6, x: 0, y: 3)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(BentoCardButtonStyle())
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isExpanded ? Color.vocabHeroAccent.opacity(0.3) : Color.vocabHairline, lineWidth: isExpanded ? 1.8 : 1.5)
        )
        .shadow(
            color: isExpanded ? Color.black.opacity(0.08) : Color.vocabHeroTeal.opacity(0.04),
            radius: isExpanded ? 12 : 6,
            x: 0,
            y: isExpanded ? 5 : 3
        )
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
