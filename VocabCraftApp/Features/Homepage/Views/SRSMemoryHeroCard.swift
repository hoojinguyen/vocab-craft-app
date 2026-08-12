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
                Text(AppStrings.Homepage.srsHeader)
                    .font(.caption.smallCaps())
                    .fontWeight(.bold)
                    .foregroundColor(Color.vocabMint)
                    .tracking(0.5)

                (Text("\(totalWords) ") + Text(AppStrings.Common.wordUnit))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(Color.vocabInk)

                Text(AppStrings.Homepage.srsRetentionMessage(Int(retentionPercentage * 100)))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.vocabMuted)
            }

            Spacer()

            // 60pt Conic progress gauge ring
            ZStack {
                Circle()
                    .stroke(Color.vocabHairline, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: CGFloat(min(max(retentionPercentage, 0.0), 1.0)))
                    .stroke(
                        Color.vocabMint,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Text("\(Int(retentionPercentage * 100))%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(Color.vocabMint)
            }
            .frame(width: 60, height: 60)
        }
        .padding(20)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.vocabHairline, lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
        .padding(.horizontal)
    }
}
