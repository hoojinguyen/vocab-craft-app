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

// MARK: - CraftLessonSectionHeaderView

/// Organism header view representing the Unit Portal Gateway Card for a learning path section.
public struct CraftLessonSectionHeaderView: View {
    public let section: LessonSection
    public var isPinned: Bool
    public var dockThreshold: CGFloat
    public var onDockChange: ((Bool) -> Void)?

    @Environment(\.craftTheme) private var theme
    @State private var isDocked: Bool = false

    // MARK: - Initializers

    /// Creates a lesson section header view for the given section.
    ///
    /// - Parameters:
    ///   - section: The `LessonSection` presentation model.
    ///   - isPinned: Whether this header is explicitly marked as pinned.
    ///   - dockThreshold: The vertical offset threshold to consider the header docked.
    ///   - onDockChange: Optional closure invoked when the header dock status changes.
    public init(
        section: LessonSection,
        isPinned: Bool = false,
        dockThreshold: CGFloat = 0,
        onDockChange: ((Bool) -> Void)? = nil
    ) {
        self.section = section
        self.isPinned = isPinned
        self.dockThreshold = dockThreshold
        self.onDockChange = onDockChange
    }

    // MARK: - Header Visibility

    /// Returns `true` if the section contains any non-empty header content.
    public var hasHeaderContent: Bool {
        !section.title.isEmpty ||
        section.subtitle != nil ||
        section.level != nil ||
        section.progressText != nil ||
        section.progress != nil ||
        section.progressValue != nil ||
        section.bannerIcon != nil
    }

    private var isHighlighted: Bool {
        isPinned || isDocked
    }

    // MARK: - Body

    public var body: some View {
        if hasHeaderContent {
            ZStack(alignment: .topTrailing) {
                // Trailing Watermark SF Symbol
                if let bannerIcon = section.bannerIcon, !bannerIcon.isEmpty {
                    Image(systemName: bannerIcon)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(theme.colors.brandPrimary.opacity(isHighlighted ? 0.22 : 0.15))
                        .padding(.top, theme.spacing.base)
                        .padding(.trailing, theme.spacing.base)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    // Top Row: Level Badge & Progress Pill
                    HStack(alignment: .center) {
                        Text(section.level ?? CraftLocalized.string("craft.learning_path.default_unit_label"))
                            .font(.caption.smallCaps().bold())
                            .foregroundStyle(theme.colors.brandPrimary)
                            .padding(.horizontal, theme.spacing.xs * 1.5)
                            .padding(.vertical, theme.spacing.xs / 2)
                            .background(
                                Capsule()
                                    .fill(theme.colors.brandPrimary.opacity(isHighlighted ? 0.18 : 0.12))
                            )

                        Spacer()

                        if let progress = section.progressText ?? section.progress, !progress.isEmpty {
                            Text(progress)
                                .font(theme.typography.label)
                                .monospacedDigit()
                                .fontDesign(.rounded)
                                .foregroundStyle(isHighlighted ? theme.colors.brandPrimary : theme.colors.textSecondary)
                        }
                    }

                    // Center Content: Title & Subtitle
                    VStack(alignment: .leading, spacing: theme.spacing.xs / 2) {
                        if !section.title.isEmpty {
                            Text(section.title)
                                .font(theme.typography.titleMedium.bold())
                                .foregroundStyle(theme.colors.textPrimary)
                        }

                        if let subtitle = section.subtitle,
                           !subtitle.isEmpty,
                           subtitle != section.level,
                           subtitle != section.title {
                            Text(subtitle)
                                .font(theme.typography.bodyMedium)
                                .foregroundStyle(theme.colors.textSecondary)
                        }
                    }

                    // Bottom Row: Mini Progress Bar
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
                        theme.colors.brandPrimary.opacity(isHighlighted ? 0.14 : 0.06),
                        isHighlighted ? theme.colors.surfaceElevated : theme.colors.surfaceCard
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.xl))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.xl)
                    .strokeBorder(
                        isHighlighted ? theme.colors.brandPrimary.opacity(0.35) : theme.colors.hairline,
                        lineWidth: isHighlighted ? 1.5 : 1
                    )
            )
            .craftShadow(isHighlighted ? theme.shadows.md : theme.shadows.sm)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel(Text(section.title))
            .accessibilityValue(Text((section.progressText ?? section.progress) ?? ""))
            .padding(.horizontal, theme.spacing.base)
            .id(section.id)
            .background(
                GeometryReader { geo in
                    let maxY = geo.frame(in: .named(CraftLearningPath.scrollCoordinateSpaceName)).maxY
                    Color.clear
                        .onChange(of: maxY) { _, newValue in
                            let docked = newValue <= dockThreshold
                            if isDocked != docked {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    isDocked = docked
                                }
                                onDockChange?(docked)
                            }
                        }
                        .onAppear {
                            let docked = maxY <= dockThreshold
                            if isDocked != docked {
                                isDocked = docked
                                onDockChange?(docked)
                            }
                        }
                }
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isHighlighted)
        }
    }
}

// MARK: - CraftLessonSectionBodyView

/// Organism body view rendering the partitioned node rows and vector snake connectors for a learning path section.
public struct CraftLessonSectionBodyView: View {
    public let section: LessonSection
    public let rowPattern: RowPattern
    public let onNodeTap: (@Sendable (LessonNodeModel) -> Void)?
    public let onNodeImpression: (@Sendable (LessonNodeModel) -> Void)?
    public let impressionThreshold: TimeInterval
    
    public let connectorDotDiameter: CGFloat?
    public let connectorDotSpacing: CGFloat?
    public let connectorTurnRadius: CGFloat?
    public let connectorEdgeInset: CGFloat?

    @Environment(\.craftTheme) private var theme

    // MARK: - Initializers

    /// Creates a lesson section body view with snake hybrid layout and optional tap handler.
    ///
    /// - Parameters:
    ///   - section: The `LessonSection` presentation model.
    ///   - onNodeTap: Optional closure invoked when any lesson node within the section is tapped.
    ///   - connectorDotDiameter: Optional diameter for connector dots.
    ///   - connectorDotSpacing: Optional spacing between connector dots.
    ///   - connectorTurnRadius: Optional turn corner radius for connector curves.
    ///   - connectorEdgeInset: Optional edge inset margin for connector turns.
    ///   - onNodeImpression: Optional closure invoked when a node impression is recorded.
    ///   - impressionThreshold: Duration in seconds a node must be visible before impression triggers.
    public init(
        section: LessonSection,
        onNodeTap: (@Sendable (LessonNodeModel) -> Void)? = nil,
        connectorDotDiameter: CGFloat? = nil,
        connectorDotSpacing: CGFloat? = nil,
        connectorTurnRadius: CGFloat? = nil,
        connectorEdgeInset: CGFloat? = nil,
        onNodeImpression: (@Sendable (LessonNodeModel) -> Void)? = nil,
        impressionThreshold: TimeInterval = 0.5
    ) {
        self.section = section
        self.rowPattern = section.rowPattern
        self.onNodeTap = onNodeTap
        self.onNodeImpression = onNodeImpression
        self.impressionThreshold = impressionThreshold
        
        self.connectorDotDiameter = connectorDotDiameter
        self.connectorDotSpacing = connectorDotSpacing
        self.connectorTurnRadius = connectorTurnRadius
        self.connectorEdgeInset = connectorEdgeInset
    }

    /// Creates a lesson section body view supporting custom row patterns.
    ///
    /// - Parameters:
    ///   - section: The `LessonSection` presentation model.
    ///   - rowPattern: Layout row pattern (defaults to `.standard`).
    ///   - onNodeTap: Optional closure invoked when any lesson node within the section is tapped.
    ///   - connectorDotDiameter: Optional diameter for connector dots.
    ///   - connectorDotSpacing: Optional spacing between connector dots.
    ///   - connectorTurnRadius: Optional turn corner radius for connector curves.
    ///   - connectorEdgeInset: Optional edge inset margin for connector turns.
    ///   - onNodeImpression: Optional closure invoked when a node impression is recorded.
    ///   - impressionThreshold: Duration in seconds a node must be visible before impression triggers.
    public init(
        section: LessonSection,
        rowPattern: RowPattern = .standard,
        onNodeTap: (@Sendable (LessonNodeModel) -> Void)? = nil,
        connectorDotDiameter: CGFloat? = nil,
        connectorDotSpacing: CGFloat? = nil,
        connectorTurnRadius: CGFloat? = nil,
        connectorEdgeInset: CGFloat? = nil,
        onNodeImpression: (@Sendable (LessonNodeModel) -> Void)? = nil,
        impressionThreshold: TimeInterval = 0.5
    ) {
        self.section = section
        self.rowPattern = rowPattern
        self.onNodeTap = onNodeTap
        self.onNodeImpression = onNodeImpression
        self.impressionThreshold = impressionThreshold
        
        self.connectorDotDiameter = connectorDotDiameter
        self.connectorDotSpacing = connectorDotSpacing
        self.connectorTurnRadius = connectorTurnRadius
        self.connectorEdgeInset = connectorEdgeInset
    }

    // MARK: - Computed Properties

    private var rowLayouts: [SnakeRowLayout] {
        rowPattern.layoutRows(nodes: section.nodes)
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: theme.spacing.pathRowSpacing) {
            ForEach(rowLayouts) { rowLayout in
                CraftLessonRow(
                    rowLayout: rowLayout,
                    onNodeTap: onNodeTap,
                    onNodeImpression: onNodeImpression,
                    impressionThreshold: impressionThreshold
                )
            }
        }
        .backgroundPreferenceValue(NodeAnchorPreferenceKey.self) { preferences in
            GeometryReader { geometry in
                CraftSnakeConnectorLayer(
                    nodes: section.nodes,
                    preferences: preferences,
                    geometry: geometry,
                    turnRadius: connectorTurnRadius,
                    edgeInset: connectorEdgeInset,
                    dotDiameter: connectorDotDiameter,
                    dotSpacing: connectorDotSpacing
                )
            }
            .allowsHitTesting(false)
        }
        .padding(.horizontal, theme.spacing.base)
    }
}

// MARK: - CraftLessonSectionView

/// An organism container view representing an entire learning path section / unit portal.
///
/// Composes `CraftLessonSectionHeaderView` and `CraftLessonSectionBodyView`.
public struct CraftLessonSectionView: View {
    public let section: LessonSection
    public let rowPattern: RowPattern
    public let onNodeTap: (@Sendable (LessonNodeModel) -> Void)?
    public let onNodeImpression: (@Sendable (LessonNodeModel) -> Void)?
    public let impressionThreshold: TimeInterval
    public var dockThreshold: CGFloat
    public var onDockChange: ((Bool) -> Void)?

    @Environment(\.craftTheme) private var theme

    // MARK: - Initializers

    /// Creates a lesson section view with snake hybrid layout and optional tap handler.
    ///
    /// - Parameters:
    ///   - section: The `LessonSection` presentation model.
    ///   - onNodeTap: Optional closure invoked when any lesson node within the section is tapped.
    ///   - onNodeImpression: Optional closure invoked when a node impression is recorded.
    ///   - impressionThreshold: Duration in seconds a node must be visible before impression triggers.
    ///   - dockThreshold: The vertical offset threshold to consider the header docked.
    ///   - onDockChange: Optional closure invoked when the header dock status changes.
    public init(
        section: LessonSection,
        onNodeTap: (@Sendable (LessonNodeModel) -> Void)? = nil,
        onNodeImpression: (@Sendable (LessonNodeModel) -> Void)? = nil,
        impressionThreshold: TimeInterval = 0.5,
        dockThreshold: CGFloat = 0,
        onDockChange: ((Bool) -> Void)? = nil
    ) {
        self.section = section
        self.rowPattern = section.rowPattern
        self.onNodeTap = onNodeTap
        self.onNodeImpression = onNodeImpression
        self.impressionThreshold = impressionThreshold
        self.dockThreshold = dockThreshold
        self.onDockChange = onDockChange
    }

    /// Creates a lesson section view supporting custom row patterns for backward compatibility.
    ///
    /// - Parameters:
    ///   - section: The `LessonSection` presentation model.
    ///   - rowPattern: Layout row pattern (defaults to `.standard`).
    ///   - onNodeTap: Optional closure invoked when any lesson node within the section is tapped.
    ///   - onNodeImpression: Optional closure invoked when a node impression is recorded.
    ///   - impressionThreshold: Duration in seconds a node must be visible before impression triggers.
    ///   - dockThreshold: The vertical offset threshold to consider the header docked.
    ///   - onDockChange: Optional closure invoked when the header dock status changes.
    public init(
        section: LessonSection,
        rowPattern: RowPattern = .standard,
        onNodeTap: (@Sendable (LessonNodeModel) -> Void)? = nil,
        onNodeImpression: (@Sendable (LessonNodeModel) -> Void)? = nil,
        impressionThreshold: TimeInterval = 0.5,
        dockThreshold: CGFloat = 0,
        onDockChange: ((Bool) -> Void)? = nil
    ) {
        self.section = section
        self.rowPattern = rowPattern
        self.onNodeTap = onNodeTap
        self.onNodeImpression = onNodeImpression
        self.impressionThreshold = impressionThreshold
        self.dockThreshold = dockThreshold
        self.onDockChange = onDockChange
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: theme.spacing.lg) {
            CraftLessonSectionHeaderView(
                section: section,
                dockThreshold: dockThreshold,
                onDockChange: onDockChange
            )

            CraftLessonSectionBodyView(
                section: section,
                rowPattern: rowPattern,
                onNodeTap: onNodeTap,
                onNodeImpression: onNodeImpression,
                impressionThreshold: impressionThreshold
            )
        }
    }
}

// MARK: - Preview

#Preview("CraftLessonSectionView Portal") {
    ScrollView {
        CraftLessonSectionView(
            section: LessonSection(
                id: "sec_1",
                title: "Unit 1: Essential Vocabulary",
                subtitle: "Master common daily greetings and phrases",
                level: "LEVEL 1",
                progressText: "3/7 HOÀN THÀNH",
                progressValue: 0.43,
                bannerIcon: "sparkles",
                nodes: [
                    LessonNodeModel(id: "n1", title: "Greetings", subtitle: "10 words • 2 min", iconName: "hand.wave.fill", state: .completed, xpReward: 20, stars: 3),
                    LessonNodeModel(id: "n2", title: "Introductions", subtitle: "12 words • 3 min", iconName: "person.fill", state: .completed, xpReward: 25, stars: 3),
                    LessonNodeModel(id: "n3", title: "Numbers", subtitle: "15 words • 4 min", iconName: "number", state: .completed, xpReward: 20, stars: 3),
                    LessonNodeModel(id: "n4", title: "Colors", subtitle: "8 words • 2 min", iconName: "paintpalette.fill", state: .active, progress: 0.65, xpReward: 30, badgeCount: 2),
                    LessonNodeModel(id: "n5", title: "Food & Drinks", subtitle: "14 words • 4 min", iconName: "fork.knife", state: .upcoming, xpReward: 25),
                    LessonNodeModel(id: "n6", title: "Time", subtitle: "12 words • 3 min", iconName: "clock.fill", state: .locked, xpReward: 30),
                    LessonNodeModel(id: "n7", title: "Mastery Challenge", subtitle: "Boss Exam", iconName: "crown.fill", state: .bonus, kind: .checkpoint, xpReward: 80, badgeText: "HOT")
                ],
                rowPattern: .standard
            )
        )
        .padding(.vertical)
    }
}

