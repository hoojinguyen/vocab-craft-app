import SwiftUI

/// A selectable row component representing a word in the Practice Selection sheet.
/// Complies with Apple HIG guidelines: minimum 44x44pt touch targets, native SF Symbols,
/// spring transitions, and haptic feedback.
public struct PracticeSelectionRow: View {
    public let word: VaultWordItem
    public let isSelected: Bool
    public let onToggle: () -> Void
    public let onAudioTap: (() -> Void)?

    public init(
        word: VaultWordItem,
        isSelected: Bool,
        onToggle: @escaping () -> Void,
        onAudioTap: (() -> Void)? = nil
    ) {
        self.word = word
        self.isSelected = isSelected
        self.onToggle = onToggle
        self.onAudioTap = onAudioTap
    }

    public var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .center, spacing: 12) {
                // Word Details
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

                        if let onAudioTap {
                            Button(action: onAudioTap) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color.vocabPeach)
                                    .frame(width: 32, height: 32)
                                    .background(Color.vocabPeach.opacity(0.12))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                        }
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

                        Text(word.definitionVi)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.vocabMuted)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                // Selection Checkbox
                ZStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(isSelected ? Color.vocabHeroAccent : Color.vocabMuted.opacity(0.4))
                        .contentTransition(.symbolEffect(.replace))
                }
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: 56)
            .background(Color.vocabSurfaceCard)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? Color.vocabHeroAccent.opacity(0.5) : Color.vocabHairline,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .shadow(
                color: isSelected ? Color.vocabHeroAccent.opacity(0.08) : Color.black.opacity(0.02),
                radius: 4,
                x: 0,
                y: 2
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .sensoryFeedback(.selection, trigger: isSelected)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isSelected)
    }

    private var cefrBadgeBackground: Color {
        let level = word.cefrLevel.uppercased()
        switch level {
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
