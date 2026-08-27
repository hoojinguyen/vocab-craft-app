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

    @Environment(\.craftTheme) private var theme

    // MARK: - Initializers

    /// Creates a lesson section header view for the given section.
    ///
    /// - Parameter section: The `LessonSection` presentation model.
    public init(section: LessonSection) {
        self.section = section
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

    // MARK: - Body

    public var body: some View {
        if hasHeaderContent {
            ZStack(alignment: .topTrailing) {
                // Trailing Watermark SF Symbol
                if let bannerIcon = section.bannerIcon, !bannerIcon.isEmpty {
                    Image(systemName: bannerIcon)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(theme.colors.brandPrimary.opacity(0.15))
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
                                    .fill(theme.colors.brandPrimary.opacity(0.12))
                            )

                        Spacer()

                        if let progress = section.progressText ?? section.progress, !progress.isEmpty {
                            Text(progress)
                                .font(theme.typography.label)
                                .monospacedDigit()
                                .fontDesign(.rounded)
                                .foregroundStyle(theme.colors.textSecondary)
                        }
                    }

                    // Center Content: Title & Subtitle
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
            .padding(.horizontal, theme.spacing.base)
        }
    }
}

// MARK: - CraftLessonSectionBodyView

/// Organism body view rendering the partitioned node rows and vector snake connectors for a learning path section.
public struct CraftLessonSectionBodyView: View {
    public let section: LessonSection
    public let rowPattern: RowPattern
    public let onNodeTap: (@Sendable (LessonNodeModel) -> Void)?

    @Environment(\.craftTheme) private var theme

    // MARK: - Initializers

    /// Creates a lesson section body view with snake hybrid layout and optional tap handler.
    ///
    /// - Parameters:
    ///   - section: The `LessonSection` presentation model.
    ///   - onNodeTap: Optional closure invoked when any lesson node within the section is tapped.
    public init(
        section: LessonSection,
        onNodeTap: (@Sendable (LessonNodeModel) -> Void)? = nil
    ) {
        self.section = section
        self.rowPattern = section.rowPattern
        self.onNodeTap = onNodeTap
    }

    /// Creates a lesson section body view supporting custom row patterns.
    ///
    /// - Parameters:
    ///   - section: The `LessonSection` presentation model.
    ///   - rowPattern: Layout row pattern (defaults to `.standard`).
    ///   - onNodeTap: Optional closure invoked when any lesson node within the section is tapped.
    public init(
        section: LessonSection,
        rowPattern: RowPattern = .standard,
        onNodeTap: (@Sendable (LessonNodeModel) -> Void)? = nil
    ) {
        self.section = section
        self.rowPattern = rowPattern
        self.onNodeTap = onNodeTap
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
                    onNodeTap: onNodeTap
                )
            }
        }
        .backgroundPreferenceValue(NodeAnchorPreferenceKey.self) { preferences in
            GeometryReader { geometry in
                CraftSnakeConnectorLayer(
                    nodes: section.nodes,
                    preferences: preferences,
                    geometry: geometry
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

    @Environment(\.craftTheme) private var theme

    // MARK: - Initializers

    /// Creates a lesson section view with snake hybrid layout and optional tap handler.
    ///
    /// - Parameters:
    ///   - section: The `LessonSection` presentation model.
    ///   - onNodeTap: Optional closure invoked when any lesson node within the section is tapped.
    public init(
        section: LessonSection,
        onNodeTap: (@Sendable (LessonNodeModel) -> Void)? = nil
    ) {
        self.section = section
        self.rowPattern = section.rowPattern
        self.onNodeTap = onNodeTap
    }

    /// Creates a lesson section view supporting custom row patterns for backward compatibility.
    ///
    /// - Parameters:
    ///   - section: The `LessonSection` presentation model.
    ///   - rowPattern: Layout row pattern (defaults to `.standard`).
    ///   - onNodeTap: Optional closure invoked when any lesson node within the section is tapped.
    public init(
        section: LessonSection,
        rowPattern: RowPattern = .standard,
        onNodeTap: (@Sendable (LessonNodeModel) -> Void)? = nil
    ) {
        self.section = section
        self.rowPattern = rowPattern
        self.onNodeTap = onNodeTap
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: theme.spacing.lg) {
            CraftLessonSectionHeaderView(section: section)

            CraftLessonSectionBodyView(
                section: section,
                rowPattern: rowPattern,
                onNodeTap: onNodeTap
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
