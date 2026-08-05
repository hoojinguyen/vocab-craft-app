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
            VStack(alignment: .leading, spacing: 6) {
                Text("TRÍ NHỚ DÀI HẠN (SRS)")
                    .font(.caption.smallCaps())
                    .fontWeight(.bold)
                    .foregroundColor(Color.white.opacity(0.8))
                    .tracking(0.5)

                Text("\(totalWords) từ")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)

                Text("\(Int(retentionPercentage * 100))% từ đã đi vào bộ nhớ bền vững")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.8))
            }

            Spacer()

            // 60pt Conic progress gauge ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: CGFloat(min(max(retentionPercentage, 0.0), 1.0)))
                    .stroke(
                        Color.white,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(retentionPercentage * 100))%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(Color.white)
            }
            .frame(width: 60, height: 60)
        }
        .padding(20)
        .background(Color.vocabHeroTeal)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}
