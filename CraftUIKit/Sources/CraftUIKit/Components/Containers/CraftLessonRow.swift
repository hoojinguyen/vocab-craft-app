import SwiftUI

// MARK: - RowWidthPreferenceKey

private struct RowWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 360

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        if next > 0 {
            value = next
        }
    }
}

// MARK: - CraftLessonRow Molecule View

/// A molecule view representing a single horizontal row within a serpentine or snake learning path section.
///
/// Lays out `CraftLessonNode` instances horizontally according to either:
/// 1. `SnakeRowLayout` with slot anchor offsets (`.center` at 50%, `.left` at 26%, `.right` at 74%).
/// 2. `offsetRatio` (-1.0 to 1.0) forming organic S-curves.
/// 3. Legacy multi-node arrangements (`.single`, `.pair`, `.triple`).
///
/// Emits `NodeAnchorPreferenceKey` center coordinates for smart Bézier / hairpin connector linking
/// and conforms to `Equatable` to minimize view update overhead.
public struct CraftLessonRow: View, Equatable {
    public let rowLayout: SnakeRowLayout?
    public let node: LessonNodeModel
    public let offsetRatio: CGFloat
    public let onNodeTap: (@Sendable (LessonNodeModel) -> Void)?

    // Backward compatibility properties
    public let nodes: [LessonNodeModel]
    public let arrangement: LessonRowArrangement

    @Environment(\.craftTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var measuredWidth: CGFloat = 360

    // MARK: - Initializers

    /// Creates a snake grid row layout with slot-positioned nodes.
    ///
    /// - Parameters:
    ///   - rowLayout: The `SnakeRowLayout` defining positioned nodes for this row.
    ///   - onNodeTap: Optional closure invoked when a node is tapped.
    public init(
        rowLayout: SnakeRowLayout,
        onNodeTap: (@Sendable (LessonNodeModel) -> Void)? = nil
    ) {
        self.rowLayout = rowLayout
        self.onNodeTap = onNodeTap
        self.nodes = rowLayout.nodes.map(\.node)
        self.node = rowLayout.nodes.first?.node ?? LessonNodeModel(id: "empty", title: "")
        self.offsetRatio = 0.0
        self.arrangement = switch rowLayout.nodes.count {
        case 1: .single
        case 2: .pair
        default: .triple
        }
    }

    /// Creates a single-node serpentine offset row.
    ///
    /// - Parameters:
    ///   - node: The `LessonNodeModel` to display in this row.
    ///   - offsetRatio: Horizontal offset ratio (-1.0 to 1.0, where 0.0 is center, -0.5 is left, +0.5 is right).
    ///   - onNodeTap: Optional closure invoked when the node is tapped.
    public init(
        node: LessonNodeModel,
        offsetRatio: CGFloat = 0.0,
        onNodeTap: (@Sendable (LessonNodeModel) -> Void)? = nil
    ) {
        self.rowLayout = nil
        self.node = node
        self.offsetRatio = offsetRatio
        self.onNodeTap = onNodeTap
        self.nodes = [node]
        self.arrangement = .single
    }

    /// Legacy initializer supporting multi-node row arrangements.
    public init(
        nodes: [LessonNodeModel],
        arrangement: LessonRowArrangement = .single,
        onNodeTap: (@Sendable (LessonNodeModel) -> Void)? = nil
    ) {
        self.rowLayout = nil
        self.node = nodes.first ?? LessonNodeModel(id: "empty", title: "")
        self.offsetRatio = 0.0
        self.onNodeTap = onNodeTap
        self.nodes = nodes
        self.arrangement = arrangement
    }

    // MARK: - Equatable Conformance

    public static func == (lhs: CraftLessonRow, rhs: CraftLessonRow) -> Bool {
        lhs.rowLayout == rhs.rowLayout &&
        lhs.node == rhs.node &&
        abs(lhs.offsetRatio - rhs.offsetRatio) < 0.0001 &&
        lhs.nodes == rhs.nodes &&
        lhs.arrangement == rhs.arrangement
    }

    // MARK: - Body

    public var body: some View {
        if let rowLayout = rowLayout {
            snakeLayout(rowLayout)
        } else if nodes.count > 1 && arrangement != .single {
            legacyLayout
        } else {
            serpentineLayout
        }
    }

    // MARK: - Snake Row Layout

    private func snakeLayout(_ layout: SnakeRowLayout) -> some View {
        ZStack(alignment: .top) {
            ForEach(layout.nodes) { pNode in
                let xOffset = measuredWidth * (pNode.slot.xRatio - 0.50)
                CraftLessonNode(
                    model: pNode.node,
                    onTap: onNodeTap != nil ? { onNodeTap?(pNode.node) } : nil
                )
                .id(pNode.node.id)
                .alignmentGuide(HorizontalAlignment.center) { d in
                    d[HorizontalAlignment.center] - xOffset
                }
                .anchorPreference(key: NodeAnchorPreferenceKey.self, value: .center) { anchor in
                    [pNode.node.id: anchor]
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.spacing.pathRowSpacing * 0.1)
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: RowWidthPreferenceKey.self, value: geo.size.width)
            }
        )
        .onPreferenceChange(RowWidthPreferenceKey.self) { width in
            if width > 0 {
                measuredWidth = width
            }
        }
    }

    // MARK: - Serpentine Layout (1 Node Offset)

    private var serpentineLayout: some View {
        let maxShift = max(0, (measuredWidth - 96) / 2)
        let clampedRatio = min(max(offsetRatio, -1.0), 1.0)
        let xOffset = clampedRatio * (maxShift > 0 ? maxShift : 100)

        return ZStack(alignment: .center) {
            CraftLessonNode(
                model: node,
                onTap: onNodeTap != nil ? { onNodeTap?(node) } : nil
            )
            .id(node.id)
            .alignmentGuide(HorizontalAlignment.center) { d in
                d[HorizontalAlignment.center] - xOffset
            }
            .anchorPreference(key: NodeAnchorPreferenceKey.self, value: .center) { anchor in
                [node.id: anchor]
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: RowWidthPreferenceKey.self, value: geo.size.width)
            }
        )
        .onPreferenceChange(RowWidthPreferenceKey.self) { width in
            if width > 0 {
                measuredWidth = width
            }
        }
    }

    // MARK: - Legacy Multi-Node Layouts

    @ViewBuilder
    private var legacyLayout: some View {
        Group {
            switch arrangement {
            case .single:
                serpentineLayout
            case .pair:
                pairLayout
            case .triple:
                tripleLayout
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var pairLayout: some View {
        HStack {
            Spacer(minLength: dynamicTypeSize.isAccessibilitySize ? theme.spacing.xs : theme.spacing.md)

            if let first = nodes.first {
                nodeView(for: first)
            }

            Spacer(minLength: dynamicTypeSize.isAccessibilitySize ? theme.spacing.sm : theme.spacing.xl)

            if nodes.count > 1 {
                nodeView(for: nodes[1])
            }

            Spacer(minLength: dynamicTypeSize.isAccessibilitySize ? theme.spacing.xs : theme.spacing.md)
        }
    }

    private var tripleLayout: some View {
        HStack(spacing: 0) {
            Spacer(minLength: dynamicTypeSize.isAccessibilitySize ? theme.spacing.xs : theme.spacing.sm)

            ForEach(Array(nodes.prefix(3))) { node in
                nodeView(for: node)
                Spacer(minLength: dynamicTypeSize.isAccessibilitySize ? theme.spacing.xs : theme.spacing.sm)
            }
        }
    }

    private func nodeView(for node: LessonNodeModel) -> some View {
        CraftLessonNode(
            model: node,
            onTap: onNodeTap != nil ? { onNodeTap?(node) } : nil
        )
        .id(node.id)
        .anchorPreference(key: NodeAnchorPreferenceKey.self, value: .center) { anchor in
            [node.id: anchor]
        }
    }
}

// MARK: - Preview

#Preview("CraftLessonRow Serpentine") {
    VStack(spacing: 24) {
        CraftLessonRow(
            node: LessonNodeModel(id: "1", title: "Center", iconName: "star.fill", state: .completed),
            offsetRatio: 0.0
        )

        CraftLessonRow(
            node: LessonNodeModel(id: "2", title: "Left Shift", iconName: "flame.fill", state: .active, progress: 0.7),
            offsetRatio: -0.55
        )

        CraftLessonRow(
            node: LessonNodeModel(id: "3", title: "Right Shift", iconName: "crown.fill", state: .bonus, badgeText: "HOT"),
            offsetRatio: 0.55
        )
    }
    .padding()
}
