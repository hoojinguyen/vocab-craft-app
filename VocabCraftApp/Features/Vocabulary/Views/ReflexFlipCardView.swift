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
            // FRONT FACE
            VStack(spacing: 12) {
                Text("MẶT TRƯỚC • THỬ THÁCH NHỚ NGHĨA")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.vocabSurfaceSoft)
                    .foregroundColor(Color.vocabMuted)
                    .cornerRadius(6)

                Text(word.english)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.vocabInk)

                Button(action: onAudioTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "speaker.wave.2.fill")
                        Text(word.phonetic)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.vocabMint.opacity(0.15))
                    .foregroundColor(Color.vocabMint)
                    .cornerRadius(16)
                }

                Text("👇 Chọn đáp án tiếng Việt chính xác bên dưới")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.vocabMuted)
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(Color.vocabSurfaceCard)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.vocabHairline, lineWidth: 1)
            )
            .opacity(isFlipped ? 0 : 1)

            // BACK FACE
            VStack(spacing: 12) {
                Text(isSuccess ? "✓ CHÍNH XÁC! MẶT SAU & VÍ DỤ NGUYÊN CẢNH" : "⚠️ SAI 2 LẦN! MẶT SAU & GIẢI THÍCH")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((isSuccess ? Color.vocabMint : Color.vocabCoral).opacity(0.2))
                    .foregroundColor(isSuccess ? Color.vocabMint : Color.vocabCoral)
                    .cornerRadius(6)

                Text(word.vietnamese)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(isSuccess ? Color.vocabMint : Color.vocabCoral)

                VStack(alignment: .leading, spacing: 4) {
                    Text("💡 Ví dụ ngữ cảnh:")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.vocabMuted)
                    Text("\"The \(word.english) processes data in real time.\"")
                        .font(.system(size: 12, weight: .medium))
                        .italic()
                        .foregroundColor(Color.vocabInk)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.vocabSurfaceSoft)
                .cornerRadius(10)
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(Color.vocabSurfaceCard)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSuccess ? Color.vocabMint : Color.vocabCoral, lineWidth: 1.5)
            )
            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            .opacity(isFlipped ? 1 : 0)
        }
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.55, dampingFraction: 0.8), value: isFlipped)
    }
}
