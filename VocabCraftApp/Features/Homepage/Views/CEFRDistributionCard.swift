import SwiftUI
import CraftUIKit

public struct CEFRDistributionCard: View {
    @Environment(\.craftTheme) private var theme

    public let a1a2Count: Int
    public let b1b2Count: Int
    public let c1c2Count: Int
    public var onDetailTap: (() -> Void)?

    public init(
        a1a2Count: Int = 450,
        b1b2Count: Int = 620,
        c1c2Count: Int = 350,
        onDetailTap: (() -> Void)? = nil
    ) {
        self.a1a2Count = a1a2Count
        self.b1b2Count = b1b2Count
        self.c1c2Count = c1c2Count
        self.onDetailTap = onDetailTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with Detail link
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(AppStrings.Homepage.cefrTitle)
                        .font(.caption.smallCaps())
                        .fontWeight(.bold)
                        .foregroundColor(Color.vocabMuted)
                        .tracking(0.5)

                    Text("CEFR")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.vocabInk)
                }

                Spacer()

                if let onDetailTap = onDetailTap {
                    Button(action: onDetailTap) {
                        HStack(spacing: 2) {
                            Text(AppStrings.Common.viewDetails)
                                .font(.system(size: 12, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(Color.vocabCoral)
                        .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.vocabMuted)
                }
            }

            // Segmented Progress Bar & Legend
            CraftSegmentedBar(
                items: [
                    CraftSegmentItem(id: "a1a2", label: "A1-A2", value: Double(a1a2Count), color: theme.colors.statusSuccess),
                    CraftSegmentItem(id: "b1b2", label: "B1-B2", value: Double(b1b2Count), color: theme.colors.statusWarning),
                    CraftSegmentItem(id: "c1c2", label: "C1-C2", value: Double(c1c2Count), color: theme.colors.brandPrimary)
                ],
                showLegend: true,
                showPercentages: true
            )
        }
        .padding(18)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.vocabHairline, lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
        .padding(.horizontal)
    }
}
