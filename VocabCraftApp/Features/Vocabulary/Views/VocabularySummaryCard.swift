import SwiftUI

public struct VocabularySummaryCard: View {
    public let totalWords: Int
    public let srsRetentionPercentage: Double
    public let dueCount: Int

    public init(totalWords: Int, srsRetentionPercentage: Double, dueCount: Int) {
        self.totalWords = totalWords
        self.srsRetentionPercentage = srsRetentionPercentage
        self.dueCount = dueCount
    }

    public var body: some View {
        HStack(spacing: 0) {
            metricItem(title: "\(totalWords)", label: "Tổng số từ", color: .vocabInk)
            
            Divider()
                .frame(height: 32)
                .overlay(Color.vocabHairline)
            
            metricItem(title: "\(Int(srsRetentionPercentage * 100))%", label: "Trí nhớ SRS", color: .vocabMint)
            
            Divider()
                .frame(height: 32)
                .overlay(Color.vocabHairline)
            
            metricItem(title: "\(dueCount)", label: "Cần ôn", color: .vocabCoral)
        }
        .padding(.vertical, 14)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.vocabHairline, lineWidth: 1.5)
        )
        .shadow(color: Color.vocabHeroTeal.opacity(0.05), radius: 6, x: 0, y: 3)
        .padding(.horizontal)
    }

    private func metricItem(title: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.vocabMuted)
        }
        .frame(maxWidth: .infinity)
    }
}
