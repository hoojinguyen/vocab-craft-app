import SwiftUI

public struct SubTopicPreviewSheet: View {
    public let node: SubTopicNode
    public let onStartDrill: () -> Void
    public let onToggleVault: (TopicWord) -> Void
    private let ttsService: TextToSpeechProtocol

    @MainActor
    public init(
        node: SubTopicNode,
        onStartDrill: @escaping () -> Void,
        onToggleVault: @escaping (TopicWord) -> Void,
        ttsService: TextToSpeechProtocol? = nil
    ) {
        self.node = node
        self.onStartDrill = onStartDrill
        self.onToggleVault = onToggleVault
        self.ttsService = ttsService ?? TextToSpeechService()
    }

    public var body: some View {
        VStack(spacing: 16) {
            headerView
            Divider()
                .background(Color.vocabHairline)
            wordListView
            startDrillButton
        }
        .padding(20)
        .background(Color.vocabCanvas)
    }


    private var headerView: some View {
        HStack(spacing: 12) {
            Image(systemName: node.iconName)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.vocabInk)
                .padding(10)
                .background(Color.vocabMint.opacity(0.2))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(node.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.vocabInk)
                Text("\(node.learnedWords)/\(node.totalWords) từ đã thuộc")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.vocabMuted)
            }

            Spacer()
        }
        .padding(.top, 8)
    }

    private var wordListView: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(node.words) { word in
                    wordRow(word)
                }
            }
        }
    }

    private func wordRow(_ word: TopicWord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(word.english)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color.vocabInk)
                    Text(word.phonetic)
                        .font(.system(size: 12))
                        .foregroundColor(Color.vocabMuted)
                }
                Text(word.vietnamese)
                    .font(.system(size: 13))
                    .foregroundColor(Color.vocabInk)
            }

            Spacer()

            if word.isMastered {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color.vocabMint)
            } else {
                Image(systemName: "flame.fill")
                    .foregroundColor(Color.vocabPeach)
            }

            Button(action: { ttsService.speak(text: word.english) }) {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(Color.vocabInk)
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 32, height: 32)
                    .background(Color.vocabInk.opacity(0.06))
                    .clipShape(Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(BentoCardButtonStyle())

            Button(action: { onToggleVault(word) }) {
                Image(systemName: word.isSavedToPersonalVault ? "bookmark.fill" : "bookmark")
                    .foregroundColor(word.isSavedToPersonalVault ? Color.vocabPeach : Color.vocabMuted)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 32, height: 32)
                    .background(word.isSavedToPersonalVault ? Color.vocabPeach.opacity(0.12) : Color.vocabSurfaceSoft)
                    .clipShape(Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(BentoCardButtonStyle())
        }
        .padding(12)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.vocabHairline, lineWidth: 1)
        )
    }

    private var startDrillButton: some View {
        Button(action: onStartDrill) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.system(size: 13, weight: .bold))
                Text("Luyện tập riêng chặng này")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
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
}
