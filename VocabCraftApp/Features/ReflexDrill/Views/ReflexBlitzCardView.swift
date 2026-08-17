import SwiftUI

public struct ReflexBlitzCardView: View {
    public let word: ReflexBlitzWordItem
    public let showHint: Bool
    public let isCorrect: Bool
    public let isTimeout: Bool

    public init(
        word: ReflexBlitzWordItem,
        showHint: Bool,
        isCorrect: Bool,
        isTimeout: Bool
    ) {
        self.word = word
        self.showHint = showHint
        self.isCorrect = isCorrect
        self.isTimeout = isTimeout
    }

    public var body: some View {
        VStack(spacing: 20) {
            // English Cloze Sentence
            Text(isTimeout ? word.exampleSentenceEn : word.clozeSentenceEn)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(isTimeout ? .vocabCoral : (isCorrect ? .vocabMint : .vocabInk))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 8)
                .animation(.easeInOut(duration: 0.2), value: isTimeout)
                .animation(.easeInOut(duration: 0.2), value: isCorrect)
                .accessibilityLabel(
                    isTimeout
                        ? "Câu hoàn chỉnh: \(word.exampleSentenceEn)"
                        : "Câu điền từ: \(word.clozeSentenceEn)"
                )

            // Vietnamese Subtitle
            Text(word.definitionVi)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.vocabMuted)
                .multilineTextAlignment(.center)
                .accessibilityLabel("Nghĩa tiếng Việt: \(word.definitionVi)")

            // Progressive Scaffolding Pill
            if showHint && !isCorrect && !isTimeout {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption2)
                    Text("Gợi ý: \(word.initialLetterHint)")
                        .font(.caption.bold())
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.vocabPeach.opacity(0.15))
                .foregroundColor(.vocabPeach)
                .clipShape(Capsule())
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Gợi ý: \(word.initialLetterHint)")
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, minHeight: 220)
        .background(Color.vocabSurfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    isCorrect ? Color.vocabMint : (isTimeout ? Color.vocabCoral : Color.vocabHairline),
                    lineWidth: isCorrect || isTimeout ? 2.5 : 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
        .padding(.horizontal)
    }
}
