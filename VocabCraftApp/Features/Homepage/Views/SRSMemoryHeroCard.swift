import SwiftUI

public struct SRSMemoryHeroCard: View {
    public let totalWords: Int
    public let retentionPercentage: Double

    public init(totalWords: Int, retentionPercentage: Double) {
        self.totalWords = totalWords
        self.retentionPercentage = retentionPercentage
    }

    public var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TRÍ NHỚ DÀI HẠN (SRS)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.vocabMint)
                    .tracking(0.5)

                Text("\(totalWords) từ")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("\(Int(retentionPercentage * 100))% từ đã đi vào bộ nhớ bền vững")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.vocabMint.opacity(0.9))
            }

            Spacer()

            // 60pt Conic progress gauge ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: CGFloat(min(max(retentionPercentage, 0.0), 1.0)))
                    .stroke(
                        Color.vocabMint,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(retentionPercentage * 100))%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.vocabMint)
            }
            .frame(width: 60, height: 60)
        }
        .padding(20)
        .background(Color.vocabHeroTeal)
        .cornerRadius(24)
        .padding(.horizontal)
    }
}
