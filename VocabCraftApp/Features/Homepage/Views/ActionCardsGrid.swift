import SwiftUI

public struct BentoCardButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

public struct ActionCardsGrid: View {
    public let dueCardsCount: Int
    public var onReflexTap: () -> Void
    public var onQueueTap: () -> Void

    public init(
        dueCardsCount: Int,
        onReflexTap: @escaping () -> Void,
        onQueueTap: @escaping () -> Void
    ) {
        self.dueCardsCount = dueCardsCount
        self.onReflexTap = onReflexTap
        self.onQueueTap = onQueueTap
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Quick Reflex Drill Card
            Button(action: onReflexTap) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text("THỬ THÁCH")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.vocabPeach.opacity(0.20))
                        .foregroundColor(Color.vocabInk)
                        .cornerRadius(10)

                        Spacer()

                        Image(systemName: "timer")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.vocabHeroTeal)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Luyện Phản Xạ")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.vocabInk)
                        Text("Rèn phản xạ tốc độ")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.vocabMuted)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.vocabSurfaceCard)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.vocabHairline, lineWidth: 1.5)
                )
                .shadow(color: Color.vocabHeroTeal.opacity(0.04), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(BentoCardButtonStyle())

            // SRS Queue Card
            Button(action: onQueueTap) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.stack.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text("\(dueCardsCount) THẺ BÀI")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.vocabLavender.opacity(0.20))
                        .foregroundColor(Color.vocabInk)
                        .cornerRadius(10)

                        Spacer()

                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.vocabHeroTeal)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hàng Đợi SRS")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.vocabInk)
                        Text("Cần hoàn thành hôm nay")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.vocabMuted)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.vocabSurfaceCard)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.vocabHairline, lineWidth: 1.5)
                )
                .shadow(color: Color.vocabHeroTeal.opacity(0.04), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(BentoCardButtonStyle())
        }
        .padding(.horizontal)
    }
}
