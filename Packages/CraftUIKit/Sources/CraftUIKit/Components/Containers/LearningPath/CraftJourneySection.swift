import SwiftUI

// MARK: - CraftJourneyRow PreferenceKey

private struct JourneyRowWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 360

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        if next > 0 {
            value = next
        }
    }
}

// MARK: - CraftJourneyRow

/// Molecule view rendering a single row of journey nodes with responsive slot positioning.
public struct CraftJourneyRow<NodePayload: Sendable>: View {
    public let layout: JourneyRowLayout<NodePayload>
    public let onNodeTap: (@Sendable (CraftPathNodeModel<NodePayload>) -> Void)?

    @Environment(\.craftTheme) private var theme
    @State private var measuredWidth: CGFloat = 360

    public init(
        layout: JourneyRowLayout<NodePayload>,
        onNodeTap: (@Sendable (CraftPathNodeModel<NodePayload>) -> Void)? = nil
    ) {
        self.layout = layout
        self.onNodeTap = onNodeTap
    }

    public var body: some View {
        ZStack(alignment: .top) {
            ForEach(layout.nodes) { pNode in
                let xOffset = measuredWidth * (pNode.slot.xRatio - 0.50)
                CraftPathNode(
                    model: pNode.node,
                    onTap: onNodeTap
                )
                .id(pNode.node.id)
                .alignmentGuide(HorizontalAlignment.center) { d in
                    d[HorizontalAlignment.center] - xOffset
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.spacing.pathRowSpacing * 0.1)
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: JourneyRowWidthPreferenceKey.self, value: geo.size.width)
            }
        )
        .onPreferenceChange(JourneyRowWidthPreferenceKey.self) { width in
            if width > 0 && abs(width - measuredWidth) > 0.5 {
                measuredWidth = width
            }
        }
    }
}

// MARK: - CraftJourneyConnectorLayer

/// Canvas rendering vector connectors dynamically linking journey path nodes.
public struct CraftJourneyConnectorLayer<NodePayload: Sendable>: View {
    public let nodes: [CraftPathNodeModel<NodePayload>]
    public let preferences: [String: Anchor<CGPoint>]
    public let geometry: GeometryProxy

    @Environment(\.craftTheme) private var theme

    public init(
        nodes: [CraftPathNodeModel<NodePayload>],
        preferences: [String: Anchor<CGPoint>],
        geometry: GeometryProxy
    ) {
        self.nodes = nodes
        self.preferences = preferences
        self.geometry = geometry
    }

    public var body: some View {
        ZStack {
            if nodes.count >= 2 {
                ForEach(0..<(nodes.count - 1), id: \.self) { index in
                    let fromNode = nodes[index]
                    let toNode = nodes[index + 1]

                    if let fromAnchor = preferences[fromNode.id],
                       let toAnchor = preferences[toNode.id] {
                        let fromPoint = geometry[fromAnchor]
                        let toPoint = geometry[toAnchor]
                        let connectorStyle = SmartConnectorStyle.infer(from: fromNode.state, to: toNode.state)

                        CraftSmartConnector(
                            from: fromPoint,
                            to: toPoint,
                            style: connectorStyle
                        )
                    }
                }
            }
        }
    }
}

// MARK: - CraftJourneySectionView

/// An organism container view representing a complete journey path section or unit portal.
///
/// Encapsulates:
/// 1. Section Header Portal with level capsule, section title, subtitle, progress metrics,
///    mini progress bar, and trailing watermark icon.
/// 2. Responsive snake multi-node grid rows partitioned via `section.rowPattern.layoutJourneyRows(nodes:)`.
/// 3. Vector snake connectors dynamically linking adjacent nodes with state-based connector styling.
public struct CraftJourneySectionView<NodePayload: Sendable>: View {
    public let section: CraftJourneySection<NodePayload>
    public let rowPattern: RowPattern
    public let onNodeTap: (@Sendable (CraftPathNodeModel<NodePayload>) -> Void)?

    @Environment(\.craftTheme) private var theme

    // MARK: - Initializers

    public init(
        section: CraftJourneySection<NodePayload>,
        onNodeTap: (@Sendable (CraftPathNodeModel<NodePayload>) -> Void)? = nil
    ) {
        self.section = section
        self.rowPattern = section.rowPattern
        self.onNodeTap = onNodeTap
    }

    public init(
        section: CraftJourneySection<NodePayload>,
        rowPattern: RowPattern,
        onNodeTap: (@Sendable (CraftPathNodeModel<NodePayload>) -> Void)? = nil
    ) {
        self.section = section
        self.rowPattern = rowPattern
        self.onNodeTap = onNodeTap
    }

    // MARK: - Computed Properties

    private var rowLayouts: [JourneyRowLayout<NodePayload>] {
        rowPattern.layoutJourneyRows(nodes: section.nodes)
    }

    private var hasHeaderContent: Bool {
        !section.title.isEmpty ||
        section.subtitle != nil ||
        section.levelText != nil ||
        section.progressText != nil ||
        section.progressValue != nil ||
        section.bannerIcon != nil
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: theme.spacing.lg) {
            if hasHeaderContent {
                sectionHeaderView
            }

            VStack(spacing: theme.spacing.pathRowSpacing) {
                ForEach(rowLayouts) { rowLayout in
                    CraftJourneyRow(
                        layout: rowLayout,
                        onNodeTap: onNodeTap
                    )
                }
            }
            .backgroundPreferenceValue(NodeAnchorPreferenceKey.self) { preferences in
                GeometryReader { geometry in
                    CraftJourneyConnectorLayer(
                        nodes: section.nodes,
                        preferences: preferences,
                        geometry: geometry
                    )
                }
                .allowsHitTesting(false)
            }
        }
        .padding(.horizontal, theme.spacing.base)
    }

    // MARK: - Section Header Portal View

    private var sectionHeaderView: some View {
        ZStack(alignment: .topTrailing) {
            // Trailing Watermark Icon
            if let bannerIcon = section.bannerIcon, !bannerIcon.name.isEmpty {
                if bannerIcon.isSystem {
                    Image(systemName: bannerIcon.name)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(theme.colors.brandPrimary.opacity(0.15))
                        .padding(.top, theme.spacing.base)
                        .padding(.trailing, theme.spacing.base)
                        .accessibilityHidden(true)
                } else {
                    Image(bannerIcon.name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .opacity(0.15)
                        .padding(.top, theme.spacing.base)
                        .padding(.trailing, theme.spacing.base)
                        .accessibilityHidden(true)
                }
            }

            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                // Top Row: Level Badge & Progress
                HStack(alignment: .center) {
                    if let level = section.levelText, !level.isEmpty {
                        Text(level)
                            .font(.caption.smallCaps().bold())
                            .foregroundStyle(theme.colors.brandPrimary)
                            .padding(.horizontal, theme.spacing.xs * 1.5)
                            .padding(.vertical, theme.spacing.xs / 2)
                            .background(
                                Capsule()
                                    .fill(theme.colors.brandPrimary.opacity(0.12))
                            )
                    }

                    Spacer()

                    if let progress = section.progressText, !progress.isEmpty {
                        Text(progress)
                            .font(theme.typography.label)
                            .monospacedDigit()
                            .fontDesign(.rounded)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }

                // Title & Subtitle
                VStack(alignment: .leading, spacing: theme.spacing.xs / 2) {
                    if !section.title.isEmpty {
                        Text(section.title)
                            .font(theme.typography.titleMedium.bold())
                            .foregroundStyle(theme.colors.textPrimary)
                    }

                    if let subtitle = section.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(theme.typography.bodyMedium)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }

                // Mini Progress Bar
                if let progressValue = section.progressValue {
                    CraftProgressBar(
                        progress: progressValue,
                        height: 4,
                        tintColor: theme.colors.brandPrimary,
                        trackColor: theme.colors.surfaceSubtle,
                        cornerRadius: 2,
                        animated: true
                    )
                    .padding(.top, theme.spacing.xs / 2)
                }
            }
            .padding(theme.spacing.base)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    theme.colors.brandPrimary.opacity(0.06),
                    theme.colors.surfaceCard
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.xl))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.xl)
                .strokeBorder(theme.colors.hairline, lineWidth: 1)
        )
        .craftShadow(theme.shadows.sm)
        .accessibilityElement(children: .combine)
    }
}
