import SwiftUI

public struct ReflexBlitzHeaderView: View {
    public let currentIndex: Int
    public let totalCount: Int
    public let comboStreak: Int
    public let onClose: () -> Void
    public let onSkip: () -> Void
    public var showSkipInHeader: Bool

    public init(
        currentIndex: Int,
        totalCount: Int,
        comboStreak: Int,
        onClose: @escaping () -> Void,
        onSkip: @escaping () -> Void = {},
        showSkipInHeader: Bool = false
    ) {
        self.currentIndex = currentIndex
        self.totalCount = totalCount
        self.comboStreak = comboStreak
        self.onClose = onClose
        self.onSkip = onSkip
        self.showSkipInHeader = showSkipInHeader
    }

    public var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                // Close button (Leading)
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

                // Center: Step counter & Active Combo Badge
                HStack(spacing: 8) {
                    Text("\(currentIndex + 1)/\(totalCount)")
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundColor(.vocabMuted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.vocabMuted.opacity(0.08))
                        .clipShape(Capsule())

                    if comboStreak >= 2 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .symbolEffect(.bounce, value: comboStreak)
                            Text("x\(comboStreak)")
                                .fontWeight(.heavy)
                        }
                        .font(.caption.bold())
                        .foregroundColor(.vocabPeach)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.vocabPeach.opacity(0.15))
                        .clipShape(Capsule())
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityLabel("Chuỗi combo \(comboStreak)")
                    }
                }

                Spacer()

                // Trailing: Optional Skip button or balanced spacer
                if showSkipInHeader {
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
                } else {
                    // Invisible 44x44 placeholder to keep center content perfectly balanced
                    Color.clear
                        .frame(width: 44, height: 44)
                        .accessibilityHidden(true)
                }
            }

            // Animated Capsule Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.vocabHairline.opacity(0.4))
                        .frame(height: 5)

                    Capsule()
                        .fill(Color.vocabHeroAccent)
                        .frame(
                            width: max(0, min(geo.size.width, geo.size.width * CGFloat(currentIndex + 1) / CGFloat(max(1, totalCount)))),
                            height: 5
                        )
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentIndex)
                }
            }
            .frame(height: 5)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Tiến độ luyện tập")
            .accessibilityValue("Từ \(currentIndex + 1) trên \(totalCount)")
        }
        .padding(.horizontal)
    }
}

