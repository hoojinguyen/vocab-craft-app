import SwiftUI

public struct ReflexFlipCardView: View {
    public let word: TopicWord
    public let isFlipped: Bool
    public let isSuccess: Bool
    public let onAudioTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    public init(
        word: TopicWord,
        isFlipped: Bool,
        isSuccess: Bool,
        onAudioTap: @escaping () -> Void
    ) {
        self.word = word
        self.isFlipped = isFlipped
        self.isSuccess = isSuccess
        self.onAudioTap = onAudioTap
    }

    public var body: some View {
        ZStack {
            // FRONT FACE (MINIMAL: Word -> IPA -> Circle Audio Icon)
            VStack(spacing: 8) {
                Text(word.english)
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundColor(Color.vocabInk)

                Text(word.phonetic)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.vocabMuted)

                Button(action: onAudioTap) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.vocabInk)
                        .frame(width: 42, height: 42)
                        .background(Color.vocabInk.opacity(0.08))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.vocabHairline, lineWidth: 1))
                }
                .padding(.top, 6)
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 220)
            .background(Color.vocabSurfaceCard)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.vocabHairline, lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.04), radius: 8, x: 0, y: 4)
            .opacity(isFlipped ? 0 : 1)

            // BACK FACE (DETAILED: Word -> IPA -> Audio -> [partOfSpeech] Meaning -> Example)
            VStack(spacing: 10) {
                Text(word.english)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(Color.vocabInk)

                Text(word.phonetic)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.vocabMuted)

                Button(action: onAudioTap) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isSuccess ? Color.vocabMint : Color.vocabCoral)
                        .frame(width: 32, height: 32)
                        .background((isSuccess ? Color.vocabMint : Color.vocabCoral).opacity(0.12))
                        .clipShape(Circle())
                }

                Text("[\(word.partOfSpeech)] \(word.vietnamese)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSuccess ? Color.vocabMint : Color.vocabCoral)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    (Text(AppStrings.Vocabulary.example) + Text(":"))
                        .font(.caption.smallCaps())
                        .fontWeight(.bold)
                        .foregroundColor(Color.vocabMuted)

                    formattedExampleText
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .italic()
                        .foregroundColor(Color.vocabInk)
                }
                .padding(.top, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 220)
            .background(Color.vocabSurfaceCard)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke((isSuccess ? Color.vocabMint : Color.vocabCoral).opacity(0.6), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.04), radius: 8, x: 0, y: 4)
            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            .opacity(isFlipped ? 1 : 0)
        }
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.55, dampingFraction: 0.8), value: isFlipped)
    }

    private var formattedExampleText: Text {
        let sentence = word.example
        let target = word.english
        if let range = sentence.range(of: target, options: .caseInsensitive) {
            let prefix = String(sentence[..<range.lowerBound])
            let match = String(sentence[range])
            let suffix = String(sentence[range.upperBound...])

            return Text("\"")
                + Text(prefix)
                + Text(match)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.vocabPeach)
                + Text(suffix)
                + Text("\"")
        } else {
            return Text("\"\(sentence)\"")
        }
    }
}

