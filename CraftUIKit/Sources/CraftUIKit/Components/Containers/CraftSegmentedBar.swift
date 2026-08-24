import SwiftUI

// MARK: - CraftSegmentItem Model

/// Represents an individual segment item within a `CraftSegmentedBar`.
public struct CraftSegmentItem: Identifiable, @unchecked Sendable, Equatable, Hashable {
    public let id: String
    private let labelKey: LocalizedStringKey?
    private let rawLabel: String?
    public let value: Double
    public let color: Color

    public var label: String {
        rawLabel ?? ""
    }

    public var localizedLabel: LocalizedStringKey? {
        labelKey
    }

    public init(
        id: String? = nil,
        label: String,
        value: Double,
        color: Color
    ) {
        self.id = id ?? label
        self.labelKey = nil
        self.rawLabel = label
        self.value = value
        self.color = color
    }

    public init(
        id: String? = nil,
        label: LocalizedStringKey,
        value: Double,
        color: Color
    ) {
        self.id = id ?? String(describing: label)
        self.labelKey = label
        self.rawLabel = nil
        self.value = value
        self.color = color
    }

    public static func == (lhs: CraftSegmentItem, rhs: CraftSegmentItem) -> Bool {
        lhs.id == rhs.id && lhs.rawLabel == rhs.rawLabel && lhs.value == rhs.value && lhs.color == rhs.color
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(rawLabel)
        hasher.combine(value)
        hasher.combine(color)
    }
}

// MARK: - CraftSegmentedBar Component

/// A proportional multi-color segmented progress bar with animated widths,
/// safe zero-division fallbacks, optional legend chips with formatted percentages, and accessible VoiceOver descriptions.
public struct CraftSegmentedBar: View {
    @Environment(\.craftTheme) private var theme

    public let items: [CraftSegmentItem]
    public let height: CGFloat
    public let cornerRadius: CGFloat
    public let showLegend: Bool
    public let showPercentages: Bool
    public let animated: Bool

    /// Total sum of all non-negative item values.
    public var totalValue: Double {
        items.reduce(0.0) { $0 + max($1.value, 0.0) }
    }

    /// Computes the ratio [0.0, 1.0] of a segment item relative to the total value.
    public func ratio(for item: CraftSegmentItem) -> Double {
        guard totalValue > 0 else { return 0.0 }
        let clampedValue = max(item.value, 0.0)
        return clampedValue / totalValue
    }

    /// Computes the percentage [0.0, 100.0] of a segment item relative to the total value.
    public func percentage(for item: CraftSegmentItem) -> Double {
        ratio(for: item) * 100.0
    }

    public init(
        items: [CraftSegmentItem],
        height: CGFloat = 8,
        cornerRadius: CGFloat = 4,
        showLegend: Bool = true,
        showPercentages: Bool = true,
        animated: Bool = true
    ) {
        self.items = items
        self.height = height
        self.cornerRadius = cornerRadius
        self.showLegend = showLegend
        self.showPercentages = showPercentages
        self.animated = animated
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            // Segmented Progress Bar Track & Segments
            GeometryReader { geometry in
                let totalWidth = geometry.size.width
                ZStack(alignment: .leading) {
                    // Track Background
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(theme.colors.surfaceSubtle)
                        .frame(width: totalWidth, height: height)

                    // Segments
                    if totalValue > 0 {
                        HStack(spacing: 0) {
                            ForEach(items) { item in
                                let segmentRatio = ratio(for: item)
                                if segmentRatio > 0 {
                                    Rectangle()
                                        .fill(item.color)
                                        .frame(width: totalWidth * CGFloat(segmentRatio), height: height)
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        .animation(animated ? theme.animations.springSmooth : nil, value: items.map(\.value))
                    }
                }
            }
            .frame(height: height)

            // Optional Legend Chips
            if showLegend && !items.isEmpty {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 120, maximum: 240), spacing: theme.spacing.xs)],
                    alignment: .leading,
                    spacing: theme.spacing.xs
                ) {
                    ForEach(items) { item in
                        legendChip(for: item)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Segmented metric bar")
        .accessibilityValue(accessibilitySummary)
    }

    @ViewBuilder
    private func legendChip(for item: CraftSegmentItem) -> some View {
        HStack(spacing: theme.spacing.xs) {
            Circle()
                .fill(item.color)
                .frame(width: 8, height: 8)

            if let labelKey = item.localizedLabel {
                Text(labelKey)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            } else {
                Text(item.label)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }

            if showPercentages {
                Text("\(Int(round(percentage(for: item))))%")
                    .font(theme.typography.caption)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, theme.spacing.xs)
        .background(theme.colors.surfaceSubtle)
        .clipShape(Capsule())
    }

    private var accessibilitySummary: String {
        if items.isEmpty || totalValue == 0 {
            return "Empty"
        }
        return items.map { item in
            let pct = Int(round(percentage(for: item)))
            let labelText = item.label.isEmpty ? "Segment" : item.label
            return "\(labelText): \(pct)%"
        }.joined(separator: ", ")
    }
}

#Preview("CraftSegmentedBar") {
    VStack(spacing: 24) {
        CraftSegmentedBar(
            items: [
                CraftSegmentItem(label: "Correct", value: 10, color: .green),
                CraftSegmentItem(label: "Wrong", value: 5, color: .red)
            ]
        )
        
        CraftSegmentedBar(
            items: [
                CraftSegmentItem(label: "A", value: 30, color: .blue),
                CraftSegmentItem(label: "B", value: 30, color: .purple),
                CraftSegmentItem(label: "C", value: 40, color: .orange)
            ]
        )
    }
    .padding()
}

