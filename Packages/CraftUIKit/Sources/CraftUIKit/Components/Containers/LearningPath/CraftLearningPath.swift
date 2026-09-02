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
    /// Coordinate space identifier used for header docking and scroll position calculations.
    public static let scrollCoordinateSpaceName = "CraftLearningPathScrollView"

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
    public let topHeaderBuilder: (() -> AnyView)?
    public let detailSheetBuilder: (@Sendable (LessonNodeModel, @escaping (LessonNodeModel) -> Void, @escaping () -> Void) -> AnyView)?
    public let backgroundViewBuilder: (() -> AnyView)?
    public let emptyStateViewBuilder: (() -> AnyView)?
    public let stickyHUDBuilder: (@Sendable (LessonSection) -> AnyView)?

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
    public let onNodeImpression: (@Sendable (LessonNodeModel) -> Void)?
    public let onTabBarPresentationChange: (@Sendable (CraftTabBarPresentation) -> Void)?
    public let nodeImpressionThreshold: TimeInterval
    public let externalScrollTrigger: Int

    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var celebrationTriggered: Bool = false
    @State private var selectedNodeForDetail: LessonNodeModel?
    @State private var hasScrolledToActive: Bool = false
    @State private var dockedSectionIDs: Set<String> = []
    @State private var dockedSection: LessonSection?
    @State private var dockDebounceTask: Task<Void, Never>?
    @State private var tabBarScrollReducer = CraftTabBarScrollPresentationReducer()
    @State private var tracksUserTabBarScroll = false

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
    ///   - pinSectionHeaders: Whether to pin section headers at the top when scrolling (default: `false`).
    ///   - onNodeImpression: Optional closure invoked when a node impression is recorded.
    ///   - nodeImpressionThreshold: Duration in seconds a node must be visible before impression triggers (default: `0.5`).
    ///   - stickyHUDBuilder: Optional custom builder for the floating sticky HUD.
    public init(
        section: LessonSection,
        winding: SerpentineWinding = .standard,
        rowPattern: RowPattern = .standard,
        onNodeTap: (@Sendable (LessonNodeModel) -> Void)? = nil,
        onStartLesson: (@Sendable (LessonNodeModel) -> Void)? = nil,
        showDetailModal: Bool = true,
        scrollToActive: Bool = true,
        showCelebration: Bool = true,
        pinSectionHeaders: Bool = false,
        topHeaderBuilder: (() -> AnyView)? = nil,
        onNodeImpression: (@Sendable (LessonNodeModel) -> Void)? = nil,
        nodeImpressionThreshold: TimeInterval = 0.5,
        stickyHUDBuilder: (@Sendable (LessonSection) -> AnyView)? = nil
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
            pinSectionHeaders: pinSectionHeaders,
            topHeaderBuilder: topHeaderBuilder,
            stickyHUDBuilder: stickyHUDBuilder,
            onNodeImpression: onNodeImpression,
            nodeImpressionThreshold: nodeImpressionThreshold
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
    ///   - pinSectionHeaders: Whether to pin section headers at the top when scrolling (default: `false`).
    ///   - scrollAnimation: Animation used for automatic scrolling.
    ///   - scrollAnchor: Anchor point used for auto-scrolling to active node.
    ///   - topHeaderBuilder: Optional builder for a top header view scrolling along with the learning path.
    ///   - detailSheetBuilder: Optional custom modal sheet builder.
    ///   - backgroundViewBuilder: Optional custom background view builder.
    ///   - emptyStateViewBuilder: Optional custom empty state view builder.
    ///   - stickyHUDBuilder: Optional custom builder for the floating sticky HUD.
    ///   - connectorDotDiameter: Optional connector dot diameter.
    ///   - connectorDotSpacing: Optional connector dot spacing.
    ///   - connectorTurnRadius: Optional connector turn corner radius.
    ///   - connectorEdgeInset: Optional connector edge inset margin.
    ///   - onSectionAppear: Optional closure invoked when a section appears.
    ///   - onAutoScrolled: Optional closure invoked when auto-scroll completes.
    ///   - onNodeImpression: Optional closure invoked when a node impression is recorded.
    ///   - onTabBarPresentationChange: Optional closure invoked when a deliberate user scroll changes the tab bar presentation.
    ///   - nodeImpressionThreshold: Duration in seconds a node must be visible before impression triggers (default: `0.5`).
    public init(
        sections: [LessonSection],
        winding: SerpentineWinding = .standard,
        rowPattern: RowPattern = .standard,
        onNodeTap: (@Sendable (LessonNodeModel) -> Void)? = nil,
        onStartLesson: (@Sendable (LessonNodeModel) -> Void)? = nil,
        showDetailModal: Bool = true,
        scrollToActive: Bool = true,
        showCelebration: Bool = true,
        pinSectionHeaders: Bool = false,
        scrollAnimation: Animation = .spring(response: 0.5, dampingFraction: 0.8),
        scrollAnchor: UnitPoint = .center,
        topHeaderBuilder: (() -> AnyView)? = nil,
        detailSheetBuilder: (@Sendable (LessonNodeModel, @escaping (LessonNodeModel) -> Void, @escaping () -> Void) -> AnyView)? = nil,
        backgroundViewBuilder: (() -> AnyView)? = nil,
        emptyStateViewBuilder: (() -> AnyView)? = nil,
        stickyHUDBuilder: (@Sendable (LessonSection) -> AnyView)? = nil,
        connectorDotDiameter: CGFloat? = nil,
        connectorDotSpacing: CGFloat? = nil,
        connectorTurnRadius: CGFloat? = nil,
        connectorEdgeInset: CGFloat? = nil,
        onSectionAppear: (@Sendable (LessonSection) -> Void)? = nil,
        onAutoScrolled: (@Sendable (String) -> Void)? = nil,
        onNodeImpression: (@Sendable (LessonNodeModel) -> Void)? = nil,
        onTabBarPresentationChange: (@Sendable (CraftTabBarPresentation) -> Void)? = nil,
        nodeImpressionThreshold: TimeInterval = 0.5,
        externalScrollTrigger: Int = 0
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

        self.topHeaderBuilder = topHeaderBuilder
        self.detailSheetBuilder = detailSheetBuilder
        self.backgroundViewBuilder = backgroundViewBuilder
        self.emptyStateViewBuilder = emptyStateViewBuilder
        self.stickyHUDBuilder = stickyHUDBuilder
        self.scrollAnimation = scrollAnimation
        self.scrollAnchor = scrollAnchor
        self.connectorDotDiameter = connectorDotDiameter
        self.connectorDotSpacing = connectorDotSpacing
        self.connectorTurnRadius = connectorTurnRadius
        self.connectorEdgeInset = connectorEdgeInset
        self.onSectionAppear = onSectionAppear
        self.onAutoScrolled = onAutoScrolled
        self.onNodeImpression = onNodeImpression
        self.onTabBarPresentationChange = onTabBarPresentationChange
        self.nodeImpressionThreshold = nodeImpressionThreshold
        self.externalScrollTrigger = externalScrollTrigger
    }

    /// Creates a multi-section learning path with a custom ViewBuilder for the floating sticky HUD.
    public init<HUDContent: View>(
        sections: [LessonSection],
        winding: SerpentineWinding = .standard,
        rowPattern: RowPattern = .standard,
        onNodeTap: (@Sendable (LessonNodeModel) -> Void)? = nil,
        onStartLesson: (@Sendable (LessonNodeModel) -> Void)? = nil,
        showDetailModal: Bool = true,
        scrollToActive: Bool = true,
        showCelebration: Bool = true,
        pinSectionHeaders: Bool = false,
        scrollAnimation: Animation = .spring(response: 0.5, dampingFraction: 0.8),
        scrollAnchor: UnitPoint = .center,
        topHeaderBuilder: (() -> AnyView)? = nil,
        detailSheetBuilder: (@Sendable (LessonNodeModel, @escaping (LessonNodeModel) -> Void, @escaping () -> Void) -> AnyView)? = nil,
        backgroundViewBuilder: (() -> AnyView)? = nil,
        emptyStateViewBuilder: (() -> AnyView)? = nil,
        connectorDotDiameter: CGFloat? = nil,
        connectorDotSpacing: CGFloat? = nil,
        connectorTurnRadius: CGFloat? = nil,
        connectorEdgeInset: CGFloat? = nil,
        onSectionAppear: (@Sendable (LessonSection) -> Void)? = nil,
        onAutoScrolled: (@Sendable (String) -> Void)? = nil,
        onNodeImpression: (@Sendable (LessonNodeModel) -> Void)? = nil,
        nodeImpressionThreshold: TimeInterval = 0.5,
        @ViewBuilder stickyHUD: @escaping @Sendable (LessonSection) -> HUDContent
    ) {
        self.init(
            sections: sections,
            winding: winding,
            rowPattern: rowPattern,
            onNodeTap: onNodeTap,
            onStartLesson: onStartLesson,
            showDetailModal: showDetailModal,
            scrollToActive: scrollToActive,
            showCelebration: showCelebration,
            pinSectionHeaders: pinSectionHeaders,
            scrollAnimation: scrollAnimation,
            scrollAnchor: scrollAnchor,
            topHeaderBuilder: topHeaderBuilder,
            detailSheetBuilder: detailSheetBuilder,
            backgroundViewBuilder: backgroundViewBuilder,
            emptyStateViewBuilder: emptyStateViewBuilder,
            stickyHUDBuilder: { section in AnyView(stickyHUD(section)) },
            connectorDotDiameter: connectorDotDiameter,
            connectorDotSpacing: connectorDotSpacing,
            connectorTurnRadius: connectorTurnRadius,
            connectorEdgeInset: connectorEdgeInset,
            onSectionAppear: onSectionAppear,
            onAutoScrolled: onAutoScrolled,
            onNodeImpression: onNodeImpression,
            nodeImpressionThreshold: nodeImpressionThreshold
        )
    }

    /// Creates a single-section learning path with a custom ViewBuilder for the floating sticky HUD.
    public init<HUDContent: View>(
        section: LessonSection,
        winding: SerpentineWinding = .standard,
        rowPattern: RowPattern = .standard,
        onNodeTap: (@Sendable (LessonNodeModel) -> Void)? = nil,
        onStartLesson: (@Sendable (LessonNodeModel) -> Void)? = nil,
        showDetailModal: Bool = true,
        scrollToActive: Bool = true,
        showCelebration: Bool = true,
        pinSectionHeaders: Bool = false,
        onNodeImpression: (@Sendable (LessonNodeModel) -> Void)? = nil,
        nodeImpressionThreshold: TimeInterval = 0.5,
        @ViewBuilder stickyHUD: @escaping @Sendable (LessonSection) -> HUDContent
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
            pinSectionHeaders: pinSectionHeaders,
            onNodeImpression: onNodeImpression,
            nodeImpressionThreshold: nodeImpressionThreshold,
            stickyHUD: stickyHUD
        )
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
        pinSectionHeaders: Bool = false,
        onNodeImpression: (@Sendable (LessonNodeModel) -> Void)? = nil,
        nodeImpressionThreshold: TimeInterval = 0.5,
        stickyHUDBuilder: (@Sendable (LessonSection) -> AnyView)? = nil
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
            pinSectionHeaders: pinSectionHeaders,
            stickyHUDBuilder: stickyHUDBuilder,
            onNodeImpression: onNodeImpression,
            nodeImpressionThreshold: nodeImpressionThreshold
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
        pinSectionHeaders: Bool = false,
        onNodeImpression: (@Sendable (LessonNodeModel) -> Void)? = nil,
        nodeImpressionThreshold: TimeInterval = 0.5,
        stickyHUDBuilder: (@Sendable (LessonSection) -> AnyView)? = nil
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
            pinSectionHeaders: pinSectionHeaders,
            stickyHUDBuilder: stickyHUDBuilder,
            onNodeImpression: onNodeImpression,
            nodeImpressionThreshold: nodeImpressionThreshold
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
        // TabBar: bar 52 + vertical 10 + bottom 8 + safeArea 34 + FAB protrusion 20 ≈ 124 total visible.
        // Add row spacing + breathing room so last Unit card + treasure row is fully readable above glass bar.
        // Previous 200/220 left truncated peek; P0 bumped to 260/280; P1 adds treasure chest row (+~80pt) → 320/340.
        pinSectionHeaders ? 340 : 320
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
            }
        }
    }

    // MARK: - Scrollable Path View

    private var scrollableView: some View {
        let isReducedMotion = reduceMotion
        return ScrollViewReader { proxy in
            trackedTabBarScrollView(
                ScrollView {
                if let topHeader = topHeaderBuilder {
                    topHeader()
                }

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
                                    connectorEdgeInset: connectorEdgeInset,
                                    onNodeImpression: onNodeImpression,
                                    impressionThreshold: nodeImpressionThreshold
                                )
                                .scrollTransition(.animated) { content, phase in
                                    content
                                        .opacity(isReducedMotion ? 1.0 : (1.0 - abs(phase.value) * 0.15))
                                }
                                .onAppear { onSectionAppear?(section) }
                            } header: {
                                if CraftLessonSectionHeaderView(section: section).hasHeaderContent {
                                    CraftLessonSectionHeaderView(
                                        section: section,
                                        onDockChange: { isDocked in
                                            handleDockChange(section: section, isDocked: isDocked)
                                        }
                                    )
                                    .id(section.id)
                                    .accessibilityAddTraits(.isHeader)
                                    .padding(.vertical, theme.spacing.xs)
                                    .background(theme.colors.canvasBackground)
                                }
                            }
                        }
                        Color.clear.frame(height: 120)
                    }
                    .padding(.top, topHeaderBuilder != nil ? theme.spacing.sm : theme.spacing.xl)
                } else {
                    LazyVStack(spacing: theme.spacing.xxl, pinnedViews: []) {
                        ForEach(sections) { section in
                            VStack(spacing: theme.spacing.xxl) {
                                CraftLessonSectionHeaderView(
                                    section: section,
                                    onDockChange: { isDocked in
                                        handleDockChange(section: section, isDocked: isDocked)
                                    }
                                )
                                .id(section.id)

                                CraftLessonSectionBodyView(
                                    section: section,
                                    rowPattern: rowPattern != .standard ? rowPattern : section.rowPattern,
                                    onNodeTap: { node in
                                        handleNodeTap(node)
                                    },
                                    connectorDotDiameter: connectorDotDiameter,
                                    connectorDotSpacing: connectorDotSpacing,
                                    connectorTurnRadius: connectorTurnRadius,
                                    connectorEdgeInset: connectorEdgeInset,
                                    onNodeImpression: onNodeImpression,
                                    impressionThreshold: nodeImpressionThreshold
                                )
                            }
                            .scrollTransition(.animated) { content, phase in
                                content
                                    .opacity(isReducedMotion ? 1.0 : (1.0 - abs(phase.value) * 0.15))
                            }
                            .onAppear { onSectionAppear?(section) }
                        }
                        Color.clear.frame(height: 120)
                    }
                    .padding(.top, topHeaderBuilder != nil ? theme.spacing.sm : theme.spacing.xl)
                }
            }
            .coordinateSpace(name: Self.scrollCoordinateSpaceName)
            .contentMargins(.bottom, theme.spacing.base, for: .scrollContent)
            .contentMargins(.top, theme.spacing.sm, for: .scrollContent)
            .overlay(alignment: .top) {
                stickyHUDOverlay(proxy: proxy)
            }
            .onAppear {
                if scrollToActive, !hasScrolledToActive, let targetID = activeNodeID {
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(300))
                        guard !Task.isCancelled else { return }
                        performScroll(proxy, to: targetID, reducedMotion: isReducedMotion)
                        hasScrolledToActive = true
                    }
                }
            }
            .onChange(of: activeNodeID) { _, newID in
                guard scrollToActive, let id = newID else { return }
                performScroll(proxy, to: id, reducedMotion: isReducedMotion)
            }
            .onChange(of: sections) { _, newSections in
                dockDebounceTask?.cancel()
                dockedSection = newSections.last(where: { dockedSectionIDs.contains($0.id) })
                guard scrollToActive, !hasScrolledToActive, let id = activeNodeID else { return }
                performScroll(proxy, to: id, reducedMotion: isReducedMotion)
                hasScrolledToActive = true
            }
            .onChange(of: externalScrollTrigger) { _, _ in
                guard scrollToActive, let id = activeNodeID else { return }
                performScroll(proxy, to: id, reducedMotion: isReducedMotion)
            }
            )
        }
    }

    @ViewBuilder
    private func trackedTabBarScrollView<Content: View>(_ content: Content) -> some View {
        if #available(iOS 18, macOS 15, *) {
            content
                .onScrollPhaseChange { _, newPhase, context in
                    handleScrollPhaseChange(newPhase, context: context)
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top
                } action: { _, contentOffset in
                    handleTabBarScrollOffset(contentOffset)
                }
        } else {
            content
        }
    }

    @available(iOS 18, macOS 15, *)
    private func handleScrollPhaseChange(
        _ phase: ScrollPhase,
        context: ScrollPhaseChangeContext
    ) {
        let contentOffset = context.geometry.contentOffset.y + context.geometry.contentInsets.top

        switch phase {
        case .tracking:
            tracksUserTabBarScroll = true
            tabBarScrollReducer.reset(at: contentOffset)
        case .interacting, .decelerating:
            tracksUserTabBarScroll = true
        case .idle, .animating:
            tracksUserTabBarScroll = false
            tabBarScrollReducer.reset(at: contentOffset)
        }
    }

    private func handleTabBarScrollOffset(_ contentOffset: CGFloat) {
        guard tracksUserTabBarScroll,
              let presentation = tabBarScrollReducer.receive(
                  contentOffset: contentOffset,
                  threshold: theme.spacing.lg
              )
        else {
            return
        }

        onTabBarPresentationChange?(presentation)
    }

    // MARK: - Sticky HUD Overlay

    @ViewBuilder
    private func stickyHUDOverlay(proxy: ScrollViewProxy) -> some View {
        if let section = dockedSection {
            Group {
                if let builder = stickyHUDBuilder {
                    builder(section)
                } else {
                    defaultStickyHUD(for: section, proxy: proxy)
                }
            }
            .padding(.top, theme.spacing.xs)
            .transition(
                .asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                )
            )
            .zIndex(100)
        }
    }

    @ViewBuilder
    private func defaultStickyHUD(for section: LessonSection, proxy: ScrollViewProxy) -> some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                proxy.scrollTo(section.id, anchor: .top)
            }
        } label: {
            HStack(spacing: theme.spacing.sm) {
                if let bannerIcon = section.bannerIcon, !bannerIcon.isEmpty {
                    Image(systemName: bannerIcon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(theme.colors.brandPrimary)
                }

                Text(section.level ?? CraftLocalized.string("craft.learning_path.default_unit_label"))
                    .font(.caption2.smallCaps().bold())
                    .foregroundStyle(theme.colors.brandPrimary)
                    .padding(.horizontal, theme.spacing.xs * 1.2)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(theme.colors.brandPrimary.opacity(0.12))
                    )

                if !section.title.isEmpty {
                    Text(section.title)
                        .font(theme.typography.label)
                        .foregroundStyle(theme.colors.textPrimary)
                        .lineLimit(1)
                }

                Spacer()

                if let progress = section.progressText ?? section.progress, !progress.isEmpty {
                    Text(progress)
                        .font(theme.typography.caption.bold())
                        .monospacedDigit()
                        .fontDesign(.rounded)
                        .foregroundStyle(theme.colors.brandPrimary)
                        .padding(.horizontal, theme.spacing.xs * 1.5)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(theme.colors.brandPrimary.opacity(0.08))
                        )
                } else if let progressValue = section.progressValue {
                    CraftProgressBar(
                        progress: progressValue,
                        height: 4,
                        tintColor: theme.colors.brandPrimary,
                        trackColor: theme.colors.surfaceSubtle,
                        cornerRadius: 2,
                        animated: true
                    )
                    .frame(width: 48)
                }
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.vertical, theme.spacing.sm)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
            .background(
                Capsule()
                    .fill(theme.colors.surfaceElevated.opacity(0.85))
            )
            .overlay(
                Capsule()
                    .strokeBorder(theme.depths.topHighlight, lineWidth: 1)
            )
            .craftShadow(theme.shadows.md)
            .padding(.horizontal, theme.spacing.base)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: dockedSection?.id)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel(Text(section.title))
        .accessibilityValue(Text((section.progressText ?? section.progress) ?? ""))
        .accessibilityHint(CraftLocalized.string("craft.learning_path.tap_to_scroll_unit_hint"))
    }

    private func handleDockChange(section: LessonSection, isDocked: Bool) {
        if isDocked {
            dockedSectionIDs.insert(section.id)
        } else {
            dockedSectionIDs.remove(section.id)
        }
        dockDebounceTask?.cancel()
        dockDebounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 16_000_000)
            guard !Task.isCancelled else { return }
            let activeDocked = sections.last(where: { dockedSectionIDs.contains($0.id) })
            guard dockedSection?.id != activeDocked?.id else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                dockedSection = activeDocked
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
        if let firstSection = sections.first, firstSection.nodes.prefix(3).contains(where: { $0.id == id }) {
            withAnimation(reducedMotion ? .default : scrollAnimation) {
                proxy.scrollTo(firstSection.id, anchor: .top)
                onAutoScrolled?(id)
            }
            return
        }

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

#if canImport(PreviewsMacros)
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
#endif
