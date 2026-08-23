import SwiftUI

// MARK: - NodeAnchorPreferenceKey

/// PreferenceKey collecting center anchor coordinates for lesson nodes within a section.
public struct NodeAnchorPreferenceKey: PreferenceKey {
    public typealias Value = [String: Anchor<CGPoint>]

    public static var defaultValue: [String: Anchor<CGPoint>] = [:]

    public static func reduce(value: inout [String: Anchor<CGPoint>], nextValue: () -> [String: Anchor<CGPoint>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - CraftLessonSectionView

/// An organism container view representing an entire learning path section / unit.
///
/// Encapsulates:
/// 1. Section Header Card with level tag, title, subtitle, and progress metrics.
/// 2. Rows of lesson nodes laid out according to the configured `RowPattern`.
/// 3. Bézier curve connectors drawn between sequential nodes using scoped `NodeAnchorPreferenceKey`
///    anchors resolved within the section boundary.
public struct CraftLessonSectionView: View {
    public let section: LessonSection
    public let rowPattern: RowPattern
    public let onNodeTap: ((LessonNodeModel) -> Void)?

    @Environment(\.craftTheme) private var theme

    // MARK: - Initializer

    public init(
        section: LessonSection,
        rowPattern: RowPattern = .standard,
        onNodeTap: ((LessonNodeModel) -> Void)? = nil
    ) {
        self.section = section
        self.rowPattern = rowPattern
        self.onNodeTap = onNodeTap
    }

    // MARK: - Body

    public var body: some View {
        let rows = rowPattern.split(nodes: section.nodes)

        VStack(spacing: theme.spacing.lg) {
            if hasHeaderContent {
                sectionHeaderView
            }

            VStack(spacing: theme.spacing.lg) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    CraftLessonRow(
                        nodes: row.nodes,
                        arrangement: row.arrangement,
                        onNodeTap: onNodeTap
                    )
                }
            }
            .overlayPreferenceValue(NodeAnchorPreferenceKey.self) { preferences in
                GeometryReader { geometry in
                    connectorLayer(preferences: preferences, geometry: geometry)
                }
                .allowsHitTesting(false)
            }
        }
        .padding(.horizontal, theme.spacing.base)
    }

    // MARK: - Header Visibility

    private var hasHeaderContent: Bool {
        !section.title.isEmpty || section.subtitle != nil || section.level != nil || section.progress != nil
    }

    // MARK: - Section Header View

    private var sectionHeaderView: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack(alignment: .center) {
                if let level = section.level, !level.isEmpty {
                    Text(level)
                        .font(.caption.smallCaps())
                        .fontWeight(.bold)
                        .foregroundStyle(theme.colors.brandPrimary)
                        .padding(.horizontal, theme.spacing.xs * 1.5)
                        .padding(.vertical, theme.spacing.xs / 2)
                        .background(
                            Capsule()
                                .fill(theme.colors.brandPrimary.opacity(0.12))
                        )
                }

                Spacer()

                if let progress = section.progress, !progress.isEmpty {
                    Text(progress)
                        .font(theme.typography.label)
                        .monospacedDigit()
                        .fontDesign(.rounded)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }

            if !section.title.isEmpty {
                Text(section.title)
                    .font(theme.typography.titleMedium)
                    .foregroundStyle(theme.colors.textPrimary)
            }

            if let subtitle = section.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.textSecondary)
            }
        }
        .padding(theme.spacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.lg)
                .strokeBorder(theme.colors.borderDefault.opacity(0.5), lineWidth: 1)
        )
        .craftShadow(theme.shadows.sm)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Connector Layer

    @ViewBuilder
    private func connectorLayer(preferences: NodeAnchorPreferenceKey.Value, geometry: GeometryProxy) -> some View {
        if section.nodes.count > 1 {
            ForEach(0..<(section.nodes.count - 1), id: \.self) { index in
                let fromNode = section.nodes[index]
                let toNode = section.nodes[index + 1]

                if let fromAnchor = preferences[fromNode.id],
                   let toAnchor = preferences[toNode.id] {
                    let fromPoint = geometry[fromAnchor]
                    let toPoint = geometry[toAnchor]

                    if fromNode.state == .active && (toNode.state == .upcoming || toNode.state == .locked) {
                        BreathingConnectorView(from: fromPoint, to: toPoint)
                    } else {
                        CraftStyledConnector(from: fromPoint, to: toPoint, style: section.connectorStyle)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("CraftLessonSectionView") {
    ScrollView {
        CraftLessonSectionView(
            section: LessonSection(
                id: "sec_1",
                title: "Unit 1: Essential Vocabulary",
                subtitle: "Master common daily greetings and phrases",
                level: "LEVEL 1",
                progress: "3/7",
                nodes: [
                    LessonNodeModel(id: "n1", title: "Greetings", iconName: "hand.wave.fill", state: .completed),
                    LessonNodeModel(id: "n2", title: "Introductions", iconName: "person.fill", state: .completed),
                    LessonNodeModel(id: "n3", title: "Numbers", iconName: "number", state: .completed),
                    LessonNodeModel(id: "n4", title: "Colors", iconName: "paintpalette.fill", state: .active, progress: 0.65, badgeCount: 2),
                    LessonNodeModel(id: "n5", title: "Food & Drinks", iconName: "fork.knife", state: .upcoming),
                    LessonNodeModel(id: "n6", title: "Time", iconName: "clock.fill", state: .locked),
                    LessonNodeModel(id: "n7", title: "Mastery Challenge", iconName: "crown.fill", state: .bonus, badgeText: "HOT")
                ],
                connectorStyle: .dashed
            ),
            rowPattern: .standard
        )
        .padding(.vertical)
    }
}
