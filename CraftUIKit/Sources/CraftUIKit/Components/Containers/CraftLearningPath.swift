import SwiftUI

// MARK: - CraftLearningPath Component

/// A top-level organism container view rendering a complete gamified learning journey path.
///
/// Encapsulates:
/// 1. Auto-scrolling via `ScrollViewReader` to the `.active` node ID on initial render with smooth spring animation.
/// 2. Modular `LazyVStack` rendering of multiple `CraftLessonSectionView` units.
/// 3. Atmospheric brand gradient background wash.
/// 4. Empty state placeholder using `ContentUnavailableView` when sections or nodes are empty.
/// 5. Smooth scroll-driven parallax and scale transition effects on sections.
/// 6. Optional celebratory confetti/sparkle overlay triggers on milestone completion.
public struct CraftLearningPath: View {
    public let sections: [LessonSection]
    public let rowPattern: RowPattern
    public let onNodeTap: ((LessonNodeModel) -> Void)?
    public let scrollToActive: Bool
    public let showCelebration: Bool

    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var celebrationTriggered: Bool = false

    // MARK: - Initializers

    /// Creates a single-section learning path.
    ///
    /// - Parameters:
    ///   - section: The `LessonSection` to display.
    ///   - rowPattern: The pattern used to split nodes into rows (default: `.standard`).
    ///   - onNodeTap: Optional closure invoked when any lesson node is tapped.
    ///   - scrollToActive: Whether to automatically scroll to the active node upon appear (default: `true`).
    ///   - showCelebration: Whether to display celebratory confetti when completed/bonus nodes are tapped (default: `true`).
    public init(
        section: LessonSection,
        rowPattern: RowPattern = .standard,
        onNodeTap: ((LessonNodeModel) -> Void)? = nil,
        scrollToActive: Bool = true,
        showCelebration: Bool = true
    ) {
        self.init(
            sections: [section],
            rowPattern: rowPattern,
            onNodeTap: onNodeTap,
            scrollToActive: scrollToActive,
            showCelebration: showCelebration
        )
    }

    /// Creates a multi-section learning path.
    ///
    /// - Parameters:
    ///   - sections: Array of `LessonSection` models to display in order.
    ///   - rowPattern: The pattern used to split nodes into rows (default: `.standard`).
    ///   - onNodeTap: Optional closure invoked when any lesson node is tapped.
    ///   - scrollToActive: Whether to automatically scroll to the active node upon appear (default: `true`).
    ///   - showCelebration: Whether to display celebratory confetti when completed/bonus nodes are tapped (default: `true`).
    public init(
        sections: [LessonSection],
        rowPattern: RowPattern = .standard,
        onNodeTap: ((LessonNodeModel) -> Void)? = nil,
        scrollToActive: Bool = true,
        showCelebration: Bool = true
    ) {
        self.sections = sections
        self.rowPattern = rowPattern
        self.onNodeTap = onNodeTap
        self.scrollToActive = scrollToActive
        self.showCelebration = showCelebration
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

    // MARK: - Body

    public var body: some View {
        Group {
            if isEmpty {
                emptyStateView
            } else {
                scrollableView
            }
        }
        .background(backgroundWash)
        .craftConfetti(isTriggered: $celebrationTriggered)
    }

    // MARK: - Scrollable Path View

    private var scrollableView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: theme.spacing.xxl) {
                    ForEach(sections) { section in
                        CraftLessonSectionView(
                            section: section,
                            rowPattern: rowPattern,
                            onNodeTap: { node in
                                handleNodeTap(node)
                            }
                        )
                        .scrollTransition(.animated) { content, phase in
                            content
                                .opacity(reduceMotion ? 1.0 : (1.0 - abs(phase.value) * 0.25))
                                .scaleEffect(reduceMotion ? 1.0 : (1.0 - abs(phase.value) * 0.04))
                        }
                    }
                }
                .padding(.vertical, theme.spacing.xl)
            }
            .task {
                guard scrollToActive, let targetID = activeNodeID else { return }
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(reduceMotion ? .default : .spring(response: 0.5, dampingFraction: 0.8)) {
                    proxy.scrollTo(targetID, anchor: .center)
                }
            }
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Lessons Available",
            systemImage: "character.book.closed",
            description: Text("There are no lesson sections available in this learning path.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    // MARK: - Tap Handling

    private func handleNodeTap(_ node: LessonNodeModel) {
        if showCelebration && (node.state == .completed || node.state == .bonus) {
            celebrationTriggered = true
        }
        onNodeTap?(node)
    }
}

// MARK: - Previews

#Preview("CraftLearningPath") {
    let section1 = LessonSection(
        id: "unit_1",
        title: "Unit 1: Foundations",
        subtitle: "Essential daily greetings and basic phrases",
        level: "LEVEL 1",
        progress: "3/6",
        nodes: [
            LessonNodeModel(id: "u1_n1", title: "Greetings", iconName: "hand.wave.fill", state: .completed),
            LessonNodeModel(id: "u1_n2", title: "Introductions", iconName: "person.fill", state: .completed),
            LessonNodeModel(id: "u1_n3", title: "Numbers", iconName: "number", state: .completed),
            LessonNodeModel(id: "u1_n4", title: "Common Verbs", iconName: "flame.fill", state: .active, progress: 0.6, badgeCount: 2),
            LessonNodeModel(id: "u1_n5", title: "Food & Drinks", iconName: "fork.knife", state: .upcoming),
            LessonNodeModel(id: "u1_n6", title: "Mastery Quest", iconName: "crown.fill", state: .bonus, badgeText: "HOT")
        ],
        connectorStyle: .dashed
    )

    let section2 = LessonSection(
        id: "unit_2",
        title: "Unit 2: Travel & Places",
        subtitle: "Navigate conversations at airports, stations, and hotels",
        level: "LEVEL 2",
        progress: "0/5",
        nodes: [
            LessonNodeModel(id: "u2_n1", title: "Airport", iconName: "airplane", state: .locked),
            LessonNodeModel(id: "u2_n2", title: "Hotel Check-In", iconName: "bed.double.fill", state: .locked),
            LessonNodeModel(id: "u2_n3", title: "Directions", iconName: "map.fill", state: .locked),
            LessonNodeModel(id: "u2_n4", title: "Transit", iconName: "tram.fill", state: .locked),
            LessonNodeModel(id: "u2_n5", title: "Challenge", iconName: "star.fill", state: .locked)
        ],
        connectorStyle: .solid
    )

    CraftLearningPath(
        sections: [section1, section2],
        rowPattern: .standard,
        onNodeTap: { node in
            print("Selected lesson: \(node.title)")
        }
    )
}
