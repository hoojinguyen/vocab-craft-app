import SwiftUI

public struct ReflexBlitzHeaderView: View {
    public let currentIndex: Int
    public let totalCount: Int
    public let comboStreak: Int
    public let onClose: () -> Void
    public let onSkip: () -> Void

    public init(
        currentIndex: Int,
        totalCount: Int,
        comboStreak: Int,
        onClose: @escaping () -> Void,
        onSkip: @escaping () -> Void
    ) {
        self.currentIndex = currentIndex
        self.totalCount = totalCount
        self.comboStreak = comboStreak
        self.onClose = onClose
        self.onSkip = onSkip
    }

    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.vocabInk)
                        .frame(width: 36, height: 36)
                        .background(Color.vocabMuted.opacity(0.12))
                        .clipShape(Circle())
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(BentoCardButtonStyle())
                .accessibilityLabel("Đóng luyện tập")

                Spacer()

                if comboStreak >= 2 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                        Text("x\(comboStreak) COMBO")
                            .fontWeight(.heavy)
                    }
                    .font(.caption.smallCaps())
                    .foregroundColor(.vocabPeach)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.vocabPeach.opacity(0.15))
                    .clipShape(Capsule())
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityLabel("Chuỗi combo \(comboStreak)")
                }

                Spacer()

                Button(action: onSkip) {
                    Text("Bỏ qua")
                        .font(.subheadline.bold())
                        .foregroundColor(.vocabMuted)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.vocabMuted.opacity(0.08))
                        .clipShape(Capsule())
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(BentoCardButtonStyle())
                .accessibilityLabel("Bỏ qua từ hiện tại")
            }

            // Animated Capsule Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.vocabHairline)
                        .frame(height: 6)

                    Capsule()
                        .fill(Color.vocabHeroAccent)
                        .frame(
                            width: max(0, min(geo.size.width, geo.size.width * CGFloat(currentIndex + 1) / CGFloat(max(1, totalCount)))),
                            height: 6
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
                }
            }
            .frame(height: 6)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Tiến độ luyện tập")
            .accessibilityValue("Từ \(currentIndex + 1) trên \(totalCount)")
        }
        .padding(.horizontal)
    }
}
