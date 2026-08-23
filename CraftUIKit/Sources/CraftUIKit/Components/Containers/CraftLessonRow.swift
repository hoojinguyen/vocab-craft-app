import SwiftUI

// MARK: - CraftLessonRow Molecule View

/// A molecule view representing a single horizontal row within a learning path section.
///
/// Lays out 1 to 3 `CraftLessonNode` items according to the provided `LessonRowArrangement`:
/// - `.single`: 1 node centered on the horizontal axis
/// - `.pair`: 2 nodes offset symmetrically from the center
/// - `.triple`: 3 nodes distributed evenly across the row
///
/// Supports dynamic spacing adaptation for `dynamicTypeSize.isAccessibilitySize` and conforms
/// to `Equatable` to minimize view update overhead.
public struct CraftLessonRow: View, Equatable {
    public let nodes: [LessonNodeModel]
    public let arrangement: LessonRowArrangement
    public let onNodeTap: ((LessonNodeModel) -> Void)?

    @Environment(\.craftTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // MARK: - Initializer

    public init(
        nodes: [LessonNodeModel],
        arrangement: LessonRowArrangement,
        onNodeTap: ((LessonNodeModel) -> Void)? = nil
    ) {
        self.nodes = nodes
        self.arrangement = arrangement
        self.onNodeTap = onNodeTap
    }

    // MARK: - Equatable Conformance

    public static func == (lhs: CraftLessonRow, rhs: CraftLessonRow) -> Bool {
        lhs.nodes == rhs.nodes && lhs.arrangement == rhs.arrangement
    }

    // MARK: - Body

    public var body: some View {
        Group {
            switch arrangement {
            case .single:
                singleLayout
            case .pair:
                pairLayout
            case .triple:
                tripleLayout
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Single Layout (1 node centered)

    private var singleLayout: some View {
        HStack {
            Spacer()
            if let node = nodes.first {
                nodeView(for: node)
            }
            Spacer()
        }
    }

    // MARK: - Pair Layout (2 nodes offset ~35-40% from center)

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

    // MARK: - Triple Layout (3 nodes evenly spaced)

    private var tripleLayout: some View {
        HStack(spacing: 0) {
            Spacer(minLength: dynamicTypeSize.isAccessibilitySize ? theme.spacing.xs : theme.spacing.sm)

            ForEach(Array(nodes.prefix(3))) { node in
                nodeView(for: node)
                Spacer(minLength: dynamicTypeSize.isAccessibilitySize ? theme.spacing.xs : theme.spacing.sm)
            }
        }
    }

    // MARK: - Node View Builder

    private func nodeView(for node: LessonNodeModel) -> some View {
        CraftLessonNode(
            model: node,
            onTap: onNodeTap != nil ? { onNodeTap?(node) } : nil
        )
        .anchorPreference(key: NodeAnchorPreferenceKey.self, value: .center) { anchor in
            [node.id: anchor]
        }
    }
}

// MARK: - Preview

#Preview("CraftLessonRow Layouts") {
    VStack(spacing: 24) {
        CraftLessonRow(
            nodes: [
                LessonNodeModel(id: "1", title: "Single Node", iconName: "book.fill", state: .completed)
            ],
            arrangement: .single
        )

        CraftLessonRow(
            nodes: [
                LessonNodeModel(id: "2", title: "Pair 1", iconName: "star.fill", state: .active, progress: 0.7),
                LessonNodeModel(id: "3", title: "Pair 2", iconName: "flame.fill", state: .inProgress, progress: 0.3)
            ],
            arrangement: .pair
        )

        CraftLessonRow(
            nodes: [
                LessonNodeModel(id: "4", title: "Triple 1", iconName: "pencil", state: .upcoming),
                LessonNodeModel(id: "5", title: "Triple 2", iconName: "lock", state: .locked),
                LessonNodeModel(id: "6", title: "Triple 3", iconName: "crown.fill", state: .bonus, badgeText: "HOT")
            ],
            arrangement: .triple
        )
    }
    .padding()
}
