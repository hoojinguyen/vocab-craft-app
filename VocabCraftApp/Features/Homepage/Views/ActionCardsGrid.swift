import SwiftUI

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
                            Text("QUICK DRILL")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.12))
                        .foregroundColor(Color.vocabInk)
                        .cornerRadius(10)

                        Spacer()

                        Image(systemName: "timer")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.vocabInk)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Luyện Phản Xạ")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.vocabInk)
                        Text("Thử thách tốc độ")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.vocabInk.opacity(0.7))
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.vocabPeach)
                .cornerRadius(24)
            }

            // SRS Queue Card
            Button(action: onQueueTap) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10, weight: .bold))
                            Text("SRS QUEUE")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.12))
                        .foregroundColor(Color.vocabInk)
                        .cornerRadius(10)

                        Spacer()

                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.vocabInk)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(dueCardsCount) Thẻ Bài")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.vocabInk)
                        Text("Cần ôn tập hôm nay")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.vocabInk.opacity(0.7))
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.vocabLavender)
                .cornerRadius(24)
            }
        }
        .padding(.horizontal)
    }
}
