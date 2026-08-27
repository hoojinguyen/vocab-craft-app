import SwiftUI

// MARK: - CraftLearningPath Component

/// A top-level organism container view rendering a complete gamified learning journey path.
///
/// Encapsulates:
/// 1. Auto-scrolling via `ScrollViewReader` to the `.active` node ID on initial render with smooth spring animation after layout stabilization (300ms delay).
/// 2. Modular `LazyVStack` rendering of multiple `CraftLessonSectionView` units with continuous Serpentine winding layout.
/// 3. Interactive `CraftLessonDetailSheet` modal sheet presentation on unlocked node tap.
/// 4. Atmospheric brand gradient background wash.
/// 5. Empty state placeholder using `ContentUnavailableView` when sections or nodes are empty.
/// 6. Smooth scroll-driven parallax and scale transition effects on sections.
/// 7. Optional celebratory confetti/sparkle overlay triggers on milestone and reward completion.
public struct CraftLearningPath: View {
    public let sections: [LessonSection]
    public let winding: SerpentineWinding
    public let rowPattern: RowPattern
    public let onNodeTap: (@Sendable (LessonNodeModel) -> Void)?
    public let onStartLesson: (@Sendable (LessonNodeModel) -> Void)?
    public let showDetailModal: Bool
    public let scrollToActive: Bool
    public let showCelebration: Bool
    public let pinSectionHeaders: Bool

    // Customization hooks
    public let detailSheetBuilder: (@Sendable (LessonNodeModel, @escaping (LessonNodeModel) -> Void, @escaping () -> Void) -> AnyView)?
    public let backgroundViewBuilder: (() -> AnyView)?
    public let emptyStateViewBuilder: (() -> AnyView)?

    // Scroll configuration
    public let scrollAnimation: Animation
    public let scrollAnchor: UnitPoint

    // Connector configuration
    public let connectorDotDiameter: CGFloat?
    public let connectorDotSpacing: CGFloat?
    public let connectorTurnRadius: CGFloat?
    public let connectorEdgeInset: CGFloat?

    // Telemetry hooks
    public let onSectionAppear: (@Sendable (LessonSection) -> Void)?
    public let onAutoScrolled: (@Sendable (String) -> Void)?

    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var celebrationTriggered: Bool = false
    @State private var selectedNodeForDetail: LessonNodeModel?
    @State private var hasScrolledToActive: Bool = false

    // MARK: - Initializers

    /// Creates a single-section learning path with serpentine winding layout and snake row pattern.
    ///
    /// - Parameters:
    ///   - section: The `LessonSection` to display.
    ///   - winding: The continuous serpentine winding layout algorithm (default: `.standard`).
    ///   - rowPattern: The snake row pattern used to partition nodes (default: `.standard`).
    ///   - onNodeTap: Optional closure invoked when any lesson node is tapped.
    ///   - onStartLesson: Optional closure invoked when the user starts or resumes a lesson from the detail sheet modal.
    ///   - showDetailModal: Whether tapping an unlocked node presents the `CraftLessonDetailSheet` modal (default: `true`).
    ///   - scrollToActive: Whether to automatically scroll to the active node upon appear (default: `true`).
    ///   - showCelebration: Whether to display celebratory confetti when completed/bonus/treasure nodes are tapped (default: `true`).
    ///   - pinSectionHeaders: Whether to pin section headers at the top when scrolling (default: `true`).
    public init(
        section: LessonSection,
        winding: SerpentineWinding = .standard,
        rowPattern: RowPattern = .standard,
        onNodeTap: (@Sendable (LessonNodeModel) -> Void)? = nil,
        onStartLesson: (@Sendable (LessonNodeModel) -> Void)? = nil,
        showDetailModal: Bool = true,
        scrollToActive: Bool = true,
        showCelebration: Bool = true,
        pinSectionHeaders: Bool = true
    ) {
        self.init(
            sections: [section],
            winding: winding,
            rowPattern: rowPattern,
            onNodeTap: onNodeTap,
            onStartLesson: onStartLesson,
            showDetailModal: showDetailModal,
            scrollToActive: scrollToActive,
            showCelebration: showCelebration,
            pinSectionHeaders: pinSectionHeaders
        )
    }

    /// Creates a multi-section learning path with serpentine winding layout and snake row pattern.
    ///
    /// - Parameters:
    ///   - sections: Array of `LessonSection` models to display in order.
    ///   - winding: The continuous serpentine winding layout algorithm (default: `.standard`).
    ///   - rowPattern: The snake row pattern used to partition nodes (default: `.standard`).
    ///   - onNodeTap: Optional closure invoked when any lesson node is tapped.
    ///   - onStartLesson: Optional closure invoked when the user starts or resumes a lesson from the detail sheet modal.
    ///   - showDetailModal: Whether tapping an unlocked node presents the `CraftLessonDetailSheet` modal (default: `true`).
    ///   - scrollToActive: Whether to automatically scroll to the active node upon appear (default: `true`).
    ///   - showCelebration: Whether to display celebratory confetti when completed/bonus/treasure nodes are tapped (default: `true`).
    ///   - pinSectionHeaders: Whether to pin section headers at the top when scrolling (default: `true`).
    public init(
        sections: [LessonSection],
        winding: SerpentineWinding = .standard,
        rowPattern: RowPattern = .standard,
        onNodeTap: (@Sendable (LessonNodeModel) -> Void)? = nil,
        onStartLesson: (@Sendable (LessonNodeModel) -> Void)? = nil,
        showDetailModal: Bool = true,
        scrollToActive: Bool = true,
        showCelebration: Bool = true,
        pinSectionHeaders: Bool = true,
        scrollAnimation: Animation = .spring(response: 0.5, dampingFraction: 0.8),
        scrollAnchor: UnitPoint = .center,
        detailSheetBuilder: (@Sendable (LessonNodeModel, @escaping (LessonNodeModel) -> Void, @escaping () -> Void) -> AnyView)? = nil,
        backgroundViewBuilder: (() -> AnyView)? = nil,
        emptyStateViewBuilder: (() -> AnyView)? = nil,
        connectorDotDiameter: CGFloat? = nil,
        connectorDotSpacing: CGFloat? = nil,
        connectorTurnRadius: CGFloat? = nil,
        connectorEdgeInset: CGFloat? = nil,
        onSectionAppear: (@Sendable (LessonSection) -> Void)? = nil,
        onAutoScrolled: (@Sendable (String) -> Void)? = nil
    ) {
        self.sections = sections
        self.winding = winding
        self.rowPattern = rowPattern
        self.onNodeTap = onNodeTap
        self.onStartLesson = onStartLesson
        self.showDetailModal = showDetailModal
        self.scrollToActive = scrollToActive
        self.showCelebration = showCelebration
        self.pinSectionHeaders = pinSectionHeaders

        self.detailSheetBuilder = detailSheetBuilder
        self.backgroundViewBuilder = backgroundViewBuilder
        self.emptyStateViewBuilder = emptyStateViewBuilder
        self.scrollAnimation = scrollAnimation
        self.scrollAnchor = scrollAnchor
        self.connectorDotDiameter = connectorDotDiameter
        self.connectorDotSpacing = connectorDotSpacing
        self.connectorTurnRadius = connectorTurnRadius
        self.connectorEdgeInset = connectorEdgeInset
        self.onSectionAppear = onSectionAppear
        self.onAutoScrolled = onAutoScrolled
    }

    /// Creates a single-section learning path supporting custom row patterns for backward compatibility.
    public init(
        section: LessonSection,
        rowPattern: RowPattern,
        onNodeTap: (@Sendable (LessonNodeModel) -> Void)? = nil,
        onStartLesson: (@Sendable (LessonNodeModel) -> Void)? = nil,
        showDetailModal: Bool = true,
        scrollToActive: Bool = true,
        showCelebration: Bool = true,
        pinSectionHeaders: Bool = true
    ) {
        self.init(
            sections: [section],
            winding: .standard,
            rowPattern: rowPattern,
            onNodeTap: onNodeTap,
            onStartLesson: onStartLesson,
            showDetailModal: showDetailModal,
            scrollToActive: scrollToActive,
            showCelebration: showCelebration,
            pinSectionHeaders: pinSectionHeaders
        )
    }

    /// Creates a multi-section learning path supporting custom row patterns for backward compatibility.
    public init(
        sections: [LessonSection],
        rowPattern: RowPattern,
        onNodeTap: (@Sendable (LessonNodeModel) -> Void)? = nil,
        onStartLesson: (@Sendable (LessonNodeModel) -> Void)? = nil,
        showDetailModal: Bool = true,
        scrollToActive: Bool = true,
        showCelebration: Bool = true,
        pinSectionHeaders: Bool = true
    ) {
        self.init(
            sections: sections,
            winding: .standard,
            rowPattern: rowPattern,
            onNodeTap: onNodeTap,
            onStartLesson: onStartLesson,
            showDetailModal: showDetailModal,
            scrollToActive: scrollToActive,
            showCelebration: showCelebration,
            pinSectionHeaders: pinSectionHeaders
        )
    }

    // MARK: - Computed Properties

    /// Returns `true` if there are no sections or all sections contain no nodes.
    public var isEmpty: Bool {
        sections.isEmpty || sections.allSatisfy { $0.nodes.isEmpty }
    }

    /// Resolves the ID of the first `.active` node across all sections.
    public var activeNodeID: String? {
        for section in sections {
            if let activeNode = section.nodes.first(where: { $0.state == .active }) {
                return activeNode.id
            }
        }
        return nil
    }

    private var smartBottomPadding: CGFloat {
        pinSectionHeaders ? 420 : 130
    }

    // MARK: - Body

    public var body: some View {
        Group {
            if isEmpty {
                emptyStateView
            } else {
                scrollableView
            }
        }
        .background(effectiveBackground)
        .craftConfetti(isTriggered: $celebrationTriggered)
        .sheet(item: $selectedNodeForDetail) { node in
            if let builder = detailSheetBuilder {
                builder(
                    node,
                    { started in handleStartLesson(started) },
                    { selectedNodeForDetail = nil }
                )
            } else {
                CraftLessonDetailSheet(
                    node: node,
                    onStart: handleStartLesson,
                    onDismiss: {
                        selectedNodeForDetail = nil
                    }
                )
                .presentationDetents([.fraction(0.70), .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Scrollable Path View

    private var scrollableView: some View {
        let isReducedMotion = reduceMotion
        return ScrollViewReader { proxy in
            ScrollView {
                if pinSectionHeaders {
                    LazyVStack(spacing: theme.spacing.xxl, pinnedViews: [.sectionHeaders]) {
                        ForEach(sections) { section in
                            Section {
                                CraftLessonSectionBodyView(
                                    section: section,
                                    rowPattern: rowPattern != .standard ? rowPattern : section.rowPattern,
                                    onNodeTap: { node in
                                        handleNodeTap(node)
                                    },
                                    connectorDotDiameter: connectorDotDiameter,
                                    connectorDotSpacing: connectorDotSpacing,
                                    connectorTurnRadius: connectorTurnRadius,
                                    connectorEdgeInset: connectorEdgeInset
                                )
                                .scrollTransition(.animated) { content, phase in
                                    content
                                        .opacity(isReducedMotion ? 1.0 : (1.0 - abs(phase.value) * 0.25))
                                        .scaleEffect(isReducedMotion ? 1.0 : (1.0 - abs(phase.value) * 0.04))
                                }
                                .onAppear { onSectionAppear?(section) }
                            } header: {
                                if CraftLessonSectionHeaderView(section: section).hasHeaderContent {
                                    CraftLessonSectionHeaderView(section: section)
                                        .accessibilityAddTraits(.isHeader)
                                        .padding(.vertical, theme.spacing.xs)
                                        .background(theme.colors.canvasBackground)
                                }
                            }
                        }
                    }
                    .padding(.top, theme.spacing.xl)
                } else {
                    LazyVStack(spacing: theme.spacing.xxl, pinnedViews: []) {
                        ForEach(sections) { section in
                            VStack(spacing: theme.spacing.lg) {
                                CraftLessonSectionHeaderView(section: section)

                                CraftLessonSectionBodyView(
                                    section: section,
                                    rowPattern: rowPattern != .standard ? rowPattern : section.rowPattern,
                                    onNodeTap: { node in
                                        handleNodeTap(node)
                                    },
                                    connectorDotDiameter: connectorDotDiameter,
                                    connectorDotSpacing: connectorDotSpacing,
                                    connectorTurnRadius: connectorTurnRadius,
                                    connectorEdgeInset: connectorEdgeInset
                                )
                            }
                            .scrollTransition(.animated) { content, phase in
                                content
                                    .opacity(isReducedMotion ? 1.0 : (1.0 - abs(phase.value) * 0.25))
                                    .scaleEffect(isReducedMotion ? 1.0 : (1.0 - abs(phase.value) * 0.04))
                            }
                            .onAppear { onSectionAppear?(section) }
                        }
                    }
                    .padding(.top, theme.spacing.xl)
                }
            }
            .coordinateSpace(name: "CraftLearningPathScrollView")
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: smartBottomPadding)
            }
            .onAppear {
                if scrollToActive, let targetID = activeNodeID {
                    performScroll(proxy, to: targetID, reducedMotion: isReducedMotion)
                    hasScrolledToActive = true
                }
            }
            .onChange(of: activeNodeID) { _, newID in
                guard scrollToActive, let id = newID else { return }
                performScroll(proxy, to: id, reducedMotion: isReducedMotion)
            }
            .onChange(of: sections) { _, _ in
                guard scrollToActive, !hasScrolledToActive, let id = activeNodeID else { return }
                performScroll(proxy, to: id, reducedMotion: isReducedMotion)
                hasScrolledToActive = true
            }
        }
    }

    // MARK: - Empty State View

    private var defaultEmptyStateView: some View {
        ContentUnavailableView(
            CraftLocalized.string("craft.learning_path.empty_title"),
            systemImage: "character.book.closed",
            description: Text(CraftLocalized.string("craft.learning_path.empty_desc"))
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        Group {
            if let builder = emptyStateViewBuilder {
                builder()
            } else {
                defaultEmptyStateView
            }
        }
    }

    // MARK: - Atmospheric Background Wash

    private var backgroundWash: some View {
        LinearGradient(
            colors: [
                theme.colors.canvasBackground,
                theme.colors.brandPrimary.opacity(0.03)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Background

    private var effectiveBackground: some View {
        Group {
            if let builder = backgroundViewBuilder {
                builder()
            } else {
                backgroundWash
            }
        }
    }

    // MARK: - Scrolling Helper

    private func performScroll(_ proxy: ScrollViewProxy, to id: String, reducedMotion: Bool) {
        withAnimation(reducedMotion ? .default : scrollAnimation) {
            proxy.scrollTo(id, anchor: scrollAnchor)
            onAutoScrolled?(id)
        }
    }

    // MARK: - Tap & Sheet Handling

    private func handleNodeTap(_ node: LessonNodeModel) {
        if showCelebration && (node.state == .completed || node.state == .bonus || node.kind == .treasureChest) {
            celebrationTriggered = true
        }
        if showDetailModal && node.state != .locked {
            selectedNodeForDetail = node
        }
        onNodeTap?(node)
    }

    private func handleStartLesson(_ node: LessonNodeModel) {
        selectedNodeForDetail = nil
        onStartLesson?(node)
    }
}

// MARK: - Previews

#Preview("CraftLearningPath") {
    let section1 = LessonSection(
        id: "unit_1",
        title: "Unit 1: Foundations",
        subtitle: "Essential daily greetings and basic phrases",
        level: "LEVEL 1",
        progressText: "3/6",
        progressValue: 0.5,
        bannerIcon: "sparkles",
        nodes: [
            LessonNodeModel(id: "u1_n1", title: "Greetings", subtitle: "10 words • 2 min", iconName: "hand.wave.fill", state: .completed, xpReward: 20, stars: 3),
            LessonNodeModel(id: "u1_n2", title: "Introductions", subtitle: "12 words • 3 min", iconName: "person.fill", state: .completed, xpReward: 25, stars: 3),
            LessonNodeModel(id: "u1_n3", title: "Numbers", subtitle: "15 words • 4 min", iconName: "number", state: .completed, xpReward: 20, stars: 3),
            LessonNodeModel(id: "u1_n4", title: "Common Verbs", subtitle: "20 words • 5 min", iconName: "flame.fill", state: .active, progress: 0.6, xpReward: 30, estimatedMinutes: 5, badgeCount: 2),
            LessonNodeModel(id: "u1_n5", title: "Food & Drinks", subtitle: "15 words • 4 min", iconName: "fork.knife", state: .upcoming, xpReward: 25, estimatedMinutes: 4),
            LessonNodeModel(id: "u1_n6", title: "Mastery Quest", subtitle: "Boss Exam • 8 min", iconName: "crown.fill", state: .bonus, kind: .checkpoint, xpReward: 80, estimatedMinutes: 8, badgeText: "HOT")
        ],
        rowPattern: .standard
    )

    let section2 = LessonSection(
        id: "unit_2",
        title: "Unit 2: Travel & Places",
        subtitle: "Navigate conversations at airports, stations, and hotels",
        level: "LEVEL 2",
        progressText: "0/5",
        progressValue: 0.0,
        bannerIcon: "airplane",
        nodes: [
            LessonNodeModel(id: "u2_n1", title: "Airport", subtitle: "15 words • 4 min", iconName: "airplane", state: .locked, xpReward: 30),
            LessonNodeModel(id: "u2_n2", title: "Hotel Check-In", subtitle: "12 words • 3 min", iconName: "bed.double.fill", state: .locked, xpReward: 30),
            LessonNodeModel(id: "u2_n3", title: "Directions", subtitle: "18 words • 5 min", iconName: "map.fill", state: .locked, xpReward: 30),
            LessonNodeModel(id: "u2_n4", title: "Transit", subtitle: "10 words • 3 min", iconName: "tram.fill", state: .locked, xpReward: 30),
            LessonNodeModel(id: "u2_n5", title: "Milestone Reward", subtitle: "Special Gift", iconName: "gift.fill", state: .locked, kind: .treasureChest, xpReward: 150)
        ],
        rowPattern: .wave
    )

    CraftLearningPath(
        sections: [section1, section2],
        onNodeTap: { node in
            print("Selected lesson: \(node.title)")
        },
        onStartLesson: { node in
            print("Starting lesson: \(node.title)")
        }
    )
}

