import SwiftUI

/// A reusable SwiftUI component that visualizes speech evaluation tokens
/// with color-coded chips indicating match accuracy:
/// - `.exactMatch`: Emerald/Green with a checkmark icon.
/// - `.fuzzyMatch`: Amber/Orange with highlighted border.
/// - `.missing`: Subtle muted gray.
public struct SpeechWordHighlightView: View {
    public let tokens: [WordTokenResult]
    public let targetSentence: String
    public let evaluationResult: SpeechEvaluationResult?

    public init(
        tokens: [WordTokenResult],
        targetSentence: String = "",
        evaluationResult: SpeechEvaluationResult? = nil
    ) {
        self.tokens = tokens
        self.targetSentence = targetSentence
        self.evaluationResult = evaluationResult
    }

    public init(evaluation: SpeechEvaluationResult) {
        self.tokens = evaluation.tokens
        self.targetSentence = evaluation.targetSentence
        self.evaluationResult = evaluation
    }

    public var body: some View {
        SpeechFlowLayout(spacing: 8, lineSpacing: 8, alignment: .center) {
            ForEach(tokens) { token in
                tokenChip(for: token)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: tokens)
    }

    @ViewBuilder
    private func tokenChip(for token: WordTokenResult) -> some View {
        HStack(spacing: 4) {
            if let icon = Self.iconName(for: token.status) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Self.foregroundColor(for: token.status))
            }
            Text(token.targetWord)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(Self.foregroundColor(for: token.status))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Self.backgroundColor(for: token.status))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Self.borderColor(for: token.status), lineWidth: 1)
        )
    }

    // MARK: - Color & Icon Palette Mapping

    public static func backgroundColor(for status: WordMatchStatus) -> Color {
        switch status {
        case .exactMatch:
            return Color.green.opacity(0.15)
        case .fuzzyMatch:
            return Color.orange.opacity(0.15)
        case .missing:
            return Color.secondary.opacity(0.1)
        }
    }

    public static func foregroundColor(for status: WordMatchStatus) -> Color {
        switch status {
        case .exactMatch:
            return Color.green
        case .fuzzyMatch:
            return Color.orange
        case .missing:
            return Color.secondary
        }
    }

    public static func borderColor(for status: WordMatchStatus) -> Color {
        switch status {
        case .exactMatch:
            return Color.green.opacity(0.4)
        case .fuzzyMatch:
            return Color.orange.opacity(0.4)
        case .missing:
            return Color.secondary.opacity(0.2)
        }
    }

    public static func iconName(for status: WordMatchStatus) -> String? {
        switch status {
        case .exactMatch:
            return "checkmark"
        case .fuzzyMatch, .missing:
            return nil
        }
    }
}

// MARK: - Flow Layout

/// A flexible wrap / flow layout for token chips that supports centering and custom line spacing.
public struct SpeechFlowLayout: Layout {
    public var spacing: CGFloat
    public var lineSpacing: CGFloat
    public var alignment: HorizontalAlignment

    public init(
        spacing: CGFloat = 8,
        lineSpacing: CGFloat = 8,
        alignment: HorizontalAlignment = .center
    ) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.alignment = alignment
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)

        var totalHeight: CGFloat = 0
        var maxRowWidth: CGFloat = 0

        for (index, row) in rows.enumerated() {
            totalHeight += row.height
            if index < rows.count - 1 {
                totalHeight += lineSpacing
            }
            maxRowWidth = max(maxRowWidth, row.width)
        }

        return CGSize(width: min(maxWidth, maxRowWidth), height: totalHeight)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var currentY = bounds.minY

        for row in rows {
            let startX: CGFloat
            switch alignment {
            case .leading:
                startX = bounds.minX
            case .trailing:
                startX = bounds.maxX - row.width
            default: // .center
                startX = bounds.minX + max(0, (bounds.width - row.width) / 2)
            }

            var currentX = startX
            for item in row.items {
                item.subview.place(
                    at: CGPoint(x: currentX, y: currentY + (row.height - item.size.height) / 2),
                    proposal: ProposedViewSize(item.size)
                )
                currentX += item.size.width + spacing
            }
            currentY += row.height + lineSpacing
        }
    }

    private struct RowItem {
        let subview: LayoutSubview
        let size: CGSize
    }

    private struct Row {
        var items: [RowItem] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let itemSpacing = currentRow.items.isEmpty ? 0 : spacing

            if !currentRow.items.isEmpty && (currentRow.width + itemSpacing + size.width) > maxWidth {
                rows.append(currentRow)
                currentRow = Row()
            }

            let addedSpacing = currentRow.items.isEmpty ? 0 : spacing
            currentRow.items.append(RowItem(subview: subview, size: size))
            currentRow.width += addedSpacing + size.width
            currentRow.height = max(currentRow.height, size.height)
        }

        if !currentRow.items.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }
}
