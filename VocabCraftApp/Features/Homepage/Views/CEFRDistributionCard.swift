import SwiftUI

public struct CEFRDistributionCard: View {
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

    private var totalCount: Int {
        max(a1a2Count + b1b2Count + c1c2Count, 1)
    }

    private var a1a2Ratio: CGFloat {
        CGFloat(a1a2Count) / CGFloat(totalCount)
    }

    private var b1b2Ratio: CGFloat {
        CGFloat(b1b2Count) / CGFloat(totalCount)
    }

    private var c1c2Ratio: CGFloat {
        CGFloat(c1c2Count) / CGFloat(totalCount)
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

            // Tri-color Segmented Progress Bar
            GeometryReader { geometry in
                let width = geometry.size.width
                HStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.vocabMint)
                        .frame(width: max(width * a1a2Ratio - 2, 4))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.vocabPeach)
                        .frame(width: max(width * b1b2Ratio - 2, 4))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.vocabLavender)
                        .frame(width: max(width * c1c2Ratio - 2, 4))
                }
            }
            .frame(height: 8)
            .clipShape(Capsule())

            // Legend / breakdown
            HStack(spacing: 12) {
                CEFRLegendItem(
                    title: "A1-A2",
                    count: a1a2Count,
                    color: Color.vocabMint
                )

                Spacer()

                CEFRLegendItem(
                    title: "B1-B2",
                    count: b1b2Count,
                    color: Color.vocabPeach
                )

                Spacer()

                CEFRLegendItem(
                    title: "C1-C2",
                    count: c1c2Count,
                    color: Color.vocabLavender
                )
            }
            .font(.system(size: 12))
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

private struct CEFRLegendItem: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.vocabMuted)

            Text("\(count) từ")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(Color.vocabInk)
        }
        .lineLimit(1)
    }
}
