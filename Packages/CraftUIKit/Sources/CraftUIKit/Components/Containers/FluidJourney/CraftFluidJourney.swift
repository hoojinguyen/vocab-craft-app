import SwiftUI

// MARK: - CraftFluidJourney Organism

/// An airy, ethereal learning journey path organism view inspired by modern fluid navigation.
///
/// `CraftFluidJourney` coordinates:
/// - A vertical scroll container (`ScrollView`) inside a `ScrollViewReader` with named coordinate space
/// - An ambient ethereal background with soft radial gradients behind content using `CraftColor` tokens
/// - Floating S-curve nodes positioned with `FluidJourneyNodeOffset.offset(for: index)` without connecting lines
/// - Milestone boundary capsules (`CraftMilestonePill`) that emit vertical position via `FluidJourneyMilestonePreferenceKey`
/// - A sticky floating unit header card (`CraftPinnedUnitHeader`) docked at the top that morphs between units
/// - An expandable accordion curriculum drawer (`CraftUnitDrawerSheet`) presented on header tap
/// - Interactive lesson detail sheets (`CraftLessonDetailSheet`) on node tap
/// - Deliberate scroll tracking dispatching `onTabBarPresentationChange`
public struct CraftFluidJourney: View {
    // MARK: - Constants

    /// Named coordinate space used for milestone scroll offset tracking and header docking.
    public static let scrollCoordinateSpaceName = "CraftFluidJourneyScrollCoordinateSpace"

    /// Default vertical threshold (in points) at which a milestone pill triggers unit docking.
    public static let defaultDockThreshold: CGFloat = 140

    /// Scroll anchor positioning a lesson node near the top of the viewport, just below
    /// the floating pinned header overlay.
    public static let nodeTopAnchor = UnitPoint(x: 0.5, y: 0.12)

    // MARK: - Properties

    /// Curriculum sections displayed along the fluid journey path.
    public let sections: [LessonSection]

    /// Optional explicit surface style applied to journey nodes and milestone pills.
    public let surfaceStyle: CraftSurfaceStyle?

    /// Whether background blur rendering is suspended (e.g. when covered by an overlay or sheet).
    public var isSuspended: Bool

    /// Optional deck title shown in the unit curriculum drawer.
    public let deckTitle: String?

    /// Optional deck subtitle shown in the unit curriculum drawer.
    public let deckSubtitle: String?

    /// Callback closure invoked when any lesson node is tapped.
    public let onNodeTap: (@Sendable (LessonNodeModel) -> Void)?

    /// Callback closure invoked when a lesson is started or resumed from the detail modal.
    public let onStartLesson: (@Sendable (LessonNodeModel) -> Void)?

    /// Callback closure invoked when user scrolling changes the floating tab bar presentation state.
    public let onTabBarPresentationChange: (@Sendable (CraftTabBarPresentation) -> Void)?

    /// Optional callback invoked when a lesson is selected directly from the unit drawer sheet.
    public let onSelectLesson: (@Sendable (String, String) -> Void)?

    /// Optional callback invoked when the adjust plan button is tapped in the curriculum drawer.
    public let onAdjustPlan: (@Sendable () -> Void)?

    /// Whether tapping an unlocked node presents `CraftLessonDetailSheet`.
    public let showDetailModal: Bool

    /// Whether to automatically scroll to the active node upon initial appearance.
    public let scrollToActive: Bool

    /// External trigger incremented by parent views to request scrolling to the active lesson node.
    public let externalScrollTrigger: Int

    /// Precomputed mapping of node identifiers to continuous global index along the journey path.
    public let nodeIndexLookup: [String: Int]

    /// Optional custom builder for the lesson detail sheet.
    public let detailSheetBuilder: (@Sendable (LessonNodeModel, @escaping (LessonNodeModel) -> Void, @escaping () -> Void) -> AnyView)?

    /// Optional custom builder for the empty state placeholder.
    public let emptyStateViewBuilder: (() -> AnyView)?

    /// Optional closure providing custom callout text for active nodes.
    public let calloutTextProvider: (@Sendable (LessonNodeModel, Int, Int) -> String)?

    // MARK: - Environment

    @Environment(\.craftTheme) var theme
    @Environment(\.craftSurfaceStyle) var environmentStyle
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    /// Effective surface style resolved from explicit parameter, environment, or theme default.
    public var effectiveSurfaceStyle: CraftSurfaceStyle {
        surfaceStyle ?? (environmentStyle != .flat ? environmentStyle : theme.journeySurfaceStyle)
    }

    // MARK: - State

    @State private var dockedSectionId: String?
    @State private var selectedNodeForDetail: LessonNodeModel?
    @State private var pendingLessonToStart: LessonNodeModel?
    @State private var isDrawerPresented: Bool = false
    @State private var drawerExpandedSectionIds: Set<String> = []
    @State private var hasScrolledToActive: Bool = false
    @State private var tabBarScrollReducer = CraftTabBarScrollPresentationReducer()
    @State private var tracksUserTabBarScroll: Bool = false

    // MARK: - Body

    public var body: some View {
        Group {
            if isEmpty {
                emptyStateView
            } else {
                journeyContentView
            }
        }
        .background(ambientEtherealBackground)
        .sheet(item: $selectedNodeForDetail, onDismiss: {
            if let node = pendingLessonToStart {
                pendingLessonToStart = nil
                onStartLesson?(node)
            }
        }) { node in
            lessonDetailSheet(for: node)
        }
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-open-detail-node") {
                selectedNodeForDetail = sections.first?.nodes.first(where: { $0.state == .active })
            }
        }
    }

    // MARK: - Journey Content View

    private var journeyContentView: some View {
        ScrollViewReader { scrollProxy in
            ZStack(alignment: .top) {
                trackedTabBarScrollView(
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: theme.spacing.xxl) {
                            Color.clear.frame(height: headerClearanceHeight)

                            ForEach(sections) { section in
                                sectionBlock(section: section)
                            }

                            Color.clear.frame(height: smartBottomPadding)
                        }
                    }
                    .coordinateSpace(name: Self.scrollCoordinateSpaceName)
                    .onPreferenceChange(FluidJourneyMilestonePreferenceKey.self) { positions in
                        handleMilestonePreferenceChange(positions)
                    }
                    .onAppear {
                        handleInitialScroll(scrollProxy: scrollProxy)
                    }
                )
                .onChange(of: externalScrollTrigger) { _, newValue in
                    guard newValue > 0, let targetID = activeNodeID else { return }
                    withAnimation(reduceMotion ? nil : .smooth(duration: 0.45)) {
                        scrollProxy.scrollTo(targetID, anchor: Self.nodeTopAnchor)
                    }
                }

                pinnedHeaderOverlay(scrollProxy: scrollProxy)
            }
            .sheet(isPresented: $isDrawerPresented) {
                curriculumDrawerSheet(scrollProxy: scrollProxy)
            }
        }
    }
}

// MARK: - Initializers Extension

public extension CraftFluidJourney {
    /// Creates a multi-section fluid journey learning path.
    ///
    /// - Parameters:
    ///   - sections: Array of `LessonSection` models to display.
    ///   - surfaceStyle: Optional explicit surface style applied to nodes and milestone pills.
    ///   - isSuspended: Whether heavy background Gaussian blurs are suspended when covered (default: `false`).
    ///   - deckTitle: Optional custom deck title for the curriculum drawer and pinned header.
    ///   - deckSubtitle: Optional custom deck subtitle for the curriculum drawer.
    ///   - onNodeTap: Optional closure invoked when a node is tapped.
    ///   - onStartLesson: Optional closure invoked when a lesson starts.
    ///   - onTabBarPresentationChange: Optional closure invoked when scroll alters tab bar presentation.
    ///   - onSelectLesson: Optional closure invoked when a lesson is picked in the curriculum drawer.
    ///   - onAdjustPlan: Optional closure invoked when adjust plan is tapped in the curriculum drawer.
    ///   - showDetailModal: Whether tapping a node presents the detail modal (default: `true`).
    ///   - scrollToActive: Whether to auto-scroll to the active node on appear (default: `true`).
    ///   - externalScrollTrigger: Trigger value incremented to request smooth scroll to active node (default: `0`).
    ///   - detailSheetBuilder: Optional custom builder for the lesson detail sheet.
    ///   - emptyStateViewBuilder: Optional custom builder for the empty state view.
    ///   - calloutTextProvider: Optional custom closure resolving callout bubble text for active nodes.
    init(
        sections: [LessonSection],
        surfaceStyle: CraftSurfaceStyle? = nil,
        isSuspended: Bool = false,
        deckTitle: String? = nil,
        deckSubtitle: String? = nil,
        onNodeTap: (@Sendable (LessonNodeModel) -> Void)? = nil,
        onStartLesson: (@Sendable (LessonNodeModel) -> Void)? = nil,
        onTabBarPresentationChange: (@Sendable (CraftTabBarPresentation) -> Void)? = nil,
        onSelectLesson: (@Sendable (String, String) -> Void)? = nil,
        onAdjustPlan: (@Sendable () -> Void)? = nil,
        showDetailModal: Bool = true,
        scrollToActive: Bool = true,
        externalScrollTrigger: Int = 0,
        detailSheetBuilder: (@Sendable (LessonNodeModel, @escaping (LessonNodeModel) -> Void, @escaping () -> Void) -> AnyView)? = nil,
        emptyStateViewBuilder: (() -> AnyView)? = nil,
        calloutTextProvider: (@Sendable (LessonNodeModel, Int, Int) -> String)? = nil
    ) {
        self.sections = sections
        self.surfaceStyle = surfaceStyle
        self.isSuspended = isSuspended
        self.deckTitle = deckTitle
        self.deckSubtitle = deckSubtitle
        self.onNodeTap = onNodeTap
        self.onStartLesson = onStartLesson
        self.onTabBarPresentationChange = onTabBarPresentationChange
        self.onSelectLesson = onSelectLesson
        self.onAdjustPlan = onAdjustPlan
        self.showDetailModal = showDetailModal
        self.scrollToActive = scrollToActive
        self.externalScrollTrigger = externalScrollTrigger
        self.detailSheetBuilder = detailSheetBuilder
        self.emptyStateViewBuilder = emptyStateViewBuilder
        self.calloutTextProvider = calloutTextProvider

        var lookup: [String: Int] = [:]
        var currentIndex = 0
        for section in sections {
            for node in section.nodes {
                lookup[node.id] = currentIndex
                currentIndex += 1
            }
        }
        self.nodeIndexLookup = lookup
    }

    /// Convenience initializer creating a single-section fluid journey learning path.
    ///
    /// - Parameters:
    ///   - section: The single `LessonSection` to display.
    ///   - surfaceStyle: Optional explicit surface style applied to nodes and milestone pills.
    ///   - isSuspended: Whether heavy background Gaussian blurs are suspended when covered (default: `false`).
    ///   - deckTitle: Optional custom deck title for the curriculum drawer and pinned header.
    ///   - deckSubtitle: Optional custom deck subtitle for the curriculum drawer.
    ///   - onNodeTap: Optional closure invoked when a node is tapped.
    ///   - onStartLesson: Optional closure invoked when a lesson starts.
    ///   - onTabBarPresentationChange: Optional closure invoked when scroll alters tab bar presentation.
    ///   - onSelectLesson: Optional closure invoked when a lesson is picked in the curriculum drawer.
    ///   - onAdjustPlan: Optional closure invoked when adjust plan is tapped in the curriculum drawer.
    ///   - showDetailModal: Whether tapping a node presents the detail modal (default: `true`).
    ///   - scrollToActive: Whether to auto-scroll to the active node on appear (default: `true`).
    ///   - externalScrollTrigger: Trigger value incremented to request smooth scroll to active node (default: `0`).
    ///   - detailSheetBuilder: Optional custom builder for the lesson detail sheet.
    ///   - emptyStateViewBuilder: Optional custom builder for the empty state view.
    ///   - calloutTextProvider: Optional custom closure resolving callout bubble text for active nodes.
    init(
        section: LessonSection,
        surfaceStyle: CraftSurfaceStyle? = nil,
        isSuspended: Bool = false,
        deckTitle: String? = nil,
        deckSubtitle: String? = nil,
        onNodeTap: (@Sendable (LessonNodeModel) -> Void)? = nil,
        onStartLesson: (@Sendable (LessonNodeModel) -> Void)? = nil,
        onTabBarPresentationChange: (@Sendable (CraftTabBarPresentation) -> Void)? = nil,
        onSelectLesson: (@Sendable (String, String) -> Void)? = nil,
        onAdjustPlan: (@Sendable () -> Void)? = nil,
        showDetailModal: Bool = true,
        scrollToActive: Bool = true,
        externalScrollTrigger: Int = 0,
        detailSheetBuilder: (@Sendable (LessonNodeModel, @escaping (LessonNodeModel) -> Void, @escaping () -> Void) -> AnyView)? = nil,
        emptyStateViewBuilder: (() -> AnyView)? = nil,
        calloutTextProvider: (@Sendable (LessonNodeModel, Int, Int) -> String)? = nil
    ) {
        self.init(
            sections: [section],
            surfaceStyle: surfaceStyle,
            isSuspended: isSuspended,
            deckTitle: deckTitle,
            deckSubtitle: deckSubtitle,
            onNodeTap: onNodeTap,
            onStartLesson: onStartLesson,
            onTabBarPresentationChange: onTabBarPresentationChange,
            onSelectLesson: onSelectLesson,
            onAdjustPlan: onAdjustPlan,
            showDetailModal: showDetailModal,
            scrollToActive: scrollToActive,
            externalScrollTrigger: externalScrollTrigger,
            detailSheetBuilder: detailSheetBuilder,
            emptyStateViewBuilder: emptyStateViewBuilder,
            calloutTextProvider: calloutTextProvider
        )
    }
}

// MARK: - Computed Properties & Helpers Extension

public extension CraftFluidJourney {
    /// Whether there are no sections or all sections contain no nodes.
    var isEmpty: Bool {
        sections.isEmpty || sections.allSatisfy { $0.nodes.isEmpty }
    }

    /// Resolves the ID of the first `.active` node across all sections.
    var activeNodeID: String? {
        for section in sections {
            if let activeNode = section.nodes.first(where: { $0.state == .active }) {
                return activeNode.id
            }
        }
        return nil
    }

    /// Resolves the section currently containing an `.active` or `.inProgress` node.
    var activeSection: LessonSection? {
        sections.first { section in
            section.nodes.contains { $0.state == .active || $0.state == .inProgress }
        }
    }

    /// Fallback default section: the active section if available, otherwise the first section.
    var defaultSection: LessonSection? {
        activeSection ?? sections.first
    }

    /// The currently docked section shown in the top pinned header card.
    var currentlyDockedSection: LessonSection? {
        if let dockedSectionId, let matched = sections.first(where: { $0.id == dockedSectionId }) {
            return matched
        }
        return defaultSection
    }

    /// Resolves the horizontal S-curve offset in points for a given node identifier.
    func offset(for nodeId: String) -> CGFloat {
        let index = nodeIndexLookup[nodeId] ?? 0
        return FluidJourneyNodeOffset.offset(for: index)
    }

    /// Evaluates preference key positions against the docking threshold and returns the docked section.
    func resolveDockedSection(
        from preferences: [String: CGFloat],
        threshold: CGFloat = defaultDockThreshold
    ) -> LessonSection? {
        let matchingSection = sections.last { section in
            guard let yPosition = preferences[section.id] else { return false }
            return yPosition <= threshold
        }
        if let matchingSection {
            return matchingSection
        }
        if !preferences.isEmpty {
            return sections.first
        }
        return defaultSection
    }

    /// Resolves the title displayed in the curriculum drawer header.
    var resolvedDeckTitle: String {
        if let deckTitle, !deckTitle.isEmpty {
            return deckTitle
        }
        if let firstTitle = sections.first?.title, !firstTitle.isEmpty {
            return firstTitle
        }
        return CraftLocalized.string("craft.fluid_journey.unit_picker_title")
    }

    /// Resolves the subtitle displayed in the curriculum drawer header.
    var resolvedDeckSubtitle: String {
        if let deckSubtitle, !deckSubtitle.isEmpty {
            return deckSubtitle
        }
        let parts = [sections.first?.level, sections.first?.subtitle]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return parts.joined(separator: " • ")
    }
    /// Resolves the dynamic topic summary subtitle displayed in the pinned header.
    func headerSubtitle(for docked: LessonSection) -> String? {
        if let subtitle = docked.subtitle, !subtitle.isEmpty {
            return subtitle
        }
        return docked.progressText
    }

    /// Generates the section model for the pinned header, dynamically reflecting the docked section.
    func headerSection(for docked: LessonSection) -> LessonSection {
        let resolvedTitle: String = {
            if !docked.title.isEmpty { return docked.title }
            if let deckTitle, !deckTitle.isEmpty { return deckTitle }
            return ""
        }()

        return LessonSection(
            id: docked.id,
            title: resolvedTitle,
            subtitle: headerSubtitle(for: docked),
            level: docked.level ?? sections.first?.level,
            nodes: docked.nodes
        )
    }

    /// Resolves the title displayed by the milestone pill for a given section.
    ///
    /// Milestone pills represent transitions between curriculum decks, displaying the deck title directly.
    func milestoneTitle(for section: LessonSection) -> String {
        section.title
    }

    /// Determines whether an active callout bubble should be displayed for the given node.
    func shouldShowCallout(for node: LessonNodeModel) -> Bool {
        node.state == .active
    }

    /// Resolves the localized callout text for an active node in the fluid journey.
    func calloutText(for node: LessonNodeModel, at index: Int = 0, totalNodes: Int = 1) -> String {
        if let custom = calloutTextProvider?(node, index, totalNodes) {
            return custom
        }

        if node.kind == .checkpoint {
            return CraftLocalized.string("craft.fluid_journey.challenge")
        }

        if node.kind == .treasureChest {
            return CraftLocalized.string("craft.fluid_journey.claim_gift")
        }

        if let progress = node.progress, progress > 0.0 {
            return CraftLocalized.string("craft.fluid_journey.continue")
        }

        if index == 0 {
            return CraftLocalized.string("craft.fluid_journey.start")
        }

        if totalNodes > 2 && index >= totalNodes - 2 {
            return CraftLocalized.string("craft.fluid_journey.almost_there")
        }

        return CraftLocalized.string("craft.fluid_journey.keep_going")
    }
}

// MARK: - Subviews Extension

extension CraftFluidJourney {
    @ViewBuilder
    func sectionBlock(section: LessonSection) -> some View {
        VStack(spacing: theme.spacing.xl) {
            if section.id != sections.first?.id {
                CraftMilestonePill(
                    sectionId: section.id,
                    title: milestoneTitle(for: section),
                    surfaceStyle: surfaceStyle,
                    coordinateSpaceName: Self.scrollCoordinateSpaceName
                )
                .id("milestone-\(section.id)")
            }

            VStack(spacing: theme.spacing.xxl) {
                ForEach(Array(section.nodes.enumerated()), id: \.element.id) { index, node in
                    VStack(spacing: theme.spacing.sm) {
                        if shouldShowCallout(for: node) {
                            ActiveCalloutBubble(
                                text: calloutText(for: node, at: index, totalNodes: section.nodes.count),
                                isSuspended: isSuspended
                            )
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }

                        CraftJourneyNode(
                            node: node,
                            surfaceStyle: surfaceStyle,
                            isSuspended: isSuspended,
                            onTap: node.state == .locked ? nil : {
                                handleNodeTap(node)
                            }
                        )
                    }
                    .offset(x: offset(for: node.id))
                    .id(node.id)
                }
            }
        }
    }

    @ViewBuilder
    func pinnedHeaderOverlay(scrollProxy: ScrollViewProxy) -> some View {
        if let docked = currentlyDockedSection {
            CraftPinnedUnitHeader(
                section: headerSection(for: docked),
                onTap: {
                    // Parent-owned expansion state: survives sheet rebuilds and
                    // guarantees the drawer re-renders on every toggle.
                    if let dockedId = currentlyDockedSection?.id {
                        drawerExpandedSectionIds = [dockedId]
                    }
                    isDrawerPresented = true
                }
            )
            .padding(.horizontal, theme.spacing.base)
            .padding(.top, theme.spacing.xs)
            .id("pinned-unit-header")
        }
    }

    @ViewBuilder
    func curriculumDrawerSheet(scrollProxy: ScrollViewProxy) -> some View {
        CraftUnitDrawerSheet(
            sections: sections,
            deckTitle: resolvedDeckTitle,
            deckSubtitle: resolvedDeckSubtitle,
            activeSectionId: currentlyDockedSection?.id ?? sections.first?.id ?? "",
            expandedSectionIds: $drawerExpandedSectionIds,
            onAdjustPlan: onAdjustPlan,
            onSelectLesson: { sectionId, nodeId in
                handleLessonSelection(sectionId: sectionId, nodeId: nodeId, scrollProxy: scrollProxy)
            },
            onDismiss: {
                isDrawerPresented = false
            }
        )
    }

    @ViewBuilder
    func lessonDetailSheet(for node: LessonNodeModel) -> some View {
        if let builder = detailSheetBuilder {
            builder(
                node,
                { started in
                    pendingLessonToStart = started
                    selectedNodeForDetail = nil
                },
                { selectedNodeForDetail = nil }
            )
        } else {
            CraftLessonDetailSheet(
                node: node,
                surfaceStyle: effectiveSurfaceStyle,
                onStart: { started in
                    pendingLessonToStart = started
                    selectedNodeForDetail = nil
                },
                onDismiss: {
                    selectedNodeForDetail = nil
                }
            )
            .craftSurfaceStyle(effectiveSurfaceStyle)
            .presentationDetents([.fraction(0.70), .large])
        }
    }

    var headerClearanceHeight: CGFloat {
        110
    }

    var smartBottomPadding: CGFloat {
        280
    }

    var ambientEtherealBackground: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            if !isSuspended {
                GeometryReader { proxy in
                    let size = proxy.size
                    let topAuraSize = size.width * 1.3
                    let bottomAuraSize = size.width * 1.1

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    theme.colors.brandPrimary.opacity(0.12),
                                    theme.colors.brandPrimary.opacity(0.04),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: size.width * 0.65
                            )
                        )
                        .frame(width: topAuraSize, height: topAuraSize)
                        .position(x: size.width * 0.85, y: size.height * 0.2)
                        .blur(radius: 40)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    theme.colors.brandSecondary.opacity(0.08),
                                    theme.colors.brandSecondary.opacity(0.02),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: size.width * 0.55
                            )
                        )
                        .frame(width: bottomAuraSize, height: bottomAuraSize)
                        .position(x: size.width * 0.15, y: size.height * 0.65)
                        .blur(radius: 50)
                }
                .ignoresSafeArea()
            }
        }
        .allowsHitTesting(false)
    }

    var emptyStateView: some View {
        Group {
            if let builder = emptyStateViewBuilder {
                builder()
            } else {
                ContentUnavailableView(
                    CraftLocalized.string("craft.learning_path.empty_title"),
                    systemImage: "character.book.closed",
                    description: Text(CraftLocalized.string("craft.learning_path.empty_desc"))
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Actions & Scroll Handling Extension

extension CraftFluidJourney {
    func handleNodeTap(_ node: LessonNodeModel) {
        guard node.state != .locked else { return }

        onNodeTap?(node)
        if showDetailModal {
            selectedNodeForDetail = node
        }
    }

    func handleMilestonePreferenceChange(_ positions: [String: CGFloat]) {
        if let resolved = resolveDockedSection(from: positions), dockedSectionId != resolved.id {
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.28)) {
                dockedSectionId = resolved.id
            }
        }
    }

    func handleLessonSelection(
        sectionId: String,
        nodeId: String,
        scrollProxy: ScrollViewProxy
    ) {
        isDrawerPresented = false
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.28)) {
            dockedSectionId = sectionId
        }
        onSelectLesson?(sectionId, nodeId)

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.45)) {
                scrollProxy.scrollTo(nodeId, anchor: Self.nodeTopAnchor)
            }
        }
    }

    func handleInitialScroll(scrollProxy: ScrollViewProxy) {
        guard scrollToActive, !hasScrolledToActive, let targetID = activeNodeID else { return }
        hasScrolledToActive = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            guard !Task.isCancelled else { return }
            scrollProxy.scrollTo(targetID, anchor: Self.nodeTopAnchor)
        }
    }

    @ViewBuilder
    func trackedTabBarScrollView<Content: View>(_ content: Content) -> some View {
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
    func handleScrollPhaseChange(
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

    func handleTabBarScrollOffset(_ contentOffset: CGFloat) {
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
}
