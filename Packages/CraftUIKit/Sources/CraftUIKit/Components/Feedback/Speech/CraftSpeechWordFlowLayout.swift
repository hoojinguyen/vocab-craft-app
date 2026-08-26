import SwiftUI

// MARK: - CraftSpeechWordFlowLayout

/// A custom wrap/flow layout that arranges views horizontally and wraps them to new lines
/// when horizontal space is exhausted, supporting configurable spacing, line spacing, and alignment.
public struct CraftSpeechWordFlowLayout: Layout {
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
            let itemProposal = maxWidth.isFinite ? ProposedViewSize(width: maxWidth, height: nil) : .unspecified
            let rawSize = subview.sizeThatFits(itemProposal)
            let constrainedWidth = maxWidth.isFinite ? min(rawSize.width, maxWidth) : rawSize.width
            let size = CGSize(width: constrainedWidth, height: rawSize.height)

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
