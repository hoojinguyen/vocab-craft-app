import SwiftUI

// MARK: - CraftUnitDrawerSheet Component

/// An expandable accordion curriculum drawer presenting units and their contained sub-lessons.
///
/// `CraftUnitDrawerSheet` features:
/// - A top bar containing a circular close button, deck title and subtitle, and an adjust-plan pill button.
/// - An accordion list of sections where the active unit is expanded by default with its sub-lessons list.
/// - Tapping a unit toggles expansion with a spring animation (`.spring(response: 0.35, dampingFraction: 0.8)`),
///   respecting `@Environment(\.accessibilityReduceMotion)`.
/// - Tapping any sub-lesson executes `onSelectLesson(sectionId, nodeId)` and closes the sheet.
/// - Full VoiceOver accessibility support and 100% token-based styling via `CraftUIKit`.
public struct CraftUnitDrawerSheet: View, Equatable {
    // MARK: - Properties

    /// The list of curriculum lesson sections displayed in the drawer.
    public let sections: [LessonSection]

    /// Title of the currently selected deck.
    public let deckTitle: String

    /// Subtitle of the currently selected deck (e.g. CEFR level and focus).
    public let deckSubtitle: String

    /// Identifier of the currently active section.
    public let activeSectionId: String

    /// Optional callback invoked when the adjust plan button is tapped.
    public let onAdjustPlan: (@Sendable () -> Void)?

    /// Callback invoked when a sub-lesson item is selected, passing section ID and node ID.
    public let onSelectLesson: @Sendable (String, String) -> Void

    /// Callback invoked when the sheet is dismissed.
    public let onDismiss: @Sendable () -> Void

    // MARK: - Environment

    @Environment(\.craftTheme) var theme
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.locale) var locale

    // MARK: - State

    @State private var internalExpandedSectionIds: Set<String>
    private let customExpandedSectionIds: Binding<Set<String>>?

    var currentExpandedSectionIds: Set<String> {
        get {
            customExpandedSectionIds?.wrappedValue ?? internalExpandedSectionIds
        }
        nonmutating set {
            customExpandedSectionIds?.wrappedValue = newValue
            internalExpandedSectionIds = newValue
        }
    }

    // MARK: - Initializers

    /// Creates an accordion curriculum drawer sheet.
    ///
    /// - Parameters:
    ///   - sections: The curriculum sections.
    ///   - deckTitle: Main deck title.
    ///   - deckSubtitle: Deck subtitle.
    ///   - activeSectionId: The active section identifier (expanded by default).
    ///   - expandedSectionIds: Optional external binding controlling expanded section IDs.
    ///   - onAdjustPlan: Optional closure invoked on adjust plan tap.
    ///   - onSelectLesson: Closure invoked when a lesson is tapped.
    ///   - onDismiss: Closure invoked when sheet is dismissed.
    public init(
        sections: [LessonSection],
        deckTitle: String,
        deckSubtitle: String,
        activeSectionId: String,
        expandedSectionIds: Binding<Set<String>>? = nil,
        onAdjustPlan: (@Sendable () -> Void)? = nil,
        onSelectLesson: @escaping @Sendable (String, String) -> Void,
        onDismiss: @escaping @Sendable () -> Void
    ) {
        self.sections = sections
        self.deckTitle = deckTitle
        self.deckSubtitle = deckSubtitle
        self.activeSectionId = activeSectionId
        self.customExpandedSectionIds = expandedSectionIds
        self.onAdjustPlan = onAdjustPlan
        self.onSelectLesson = onSelectLesson
        self.onDismiss = onDismiss
        self._internalExpandedSectionIds = State(initialValue: [activeSectionId])
    }

    /// Convenience initializer supporting omission of `onAdjustPlan` and `expandedSectionIds`.
    public init(
        sections: [LessonSection],
        deckTitle: String,
        deckSubtitle: String,
        activeSectionId: String,
        onSelectLesson: @escaping @Sendable (String, String) -> Void,
        onDismiss: @escaping @Sendable () -> Void
    ) {
        self.init(
            sections: sections,
            deckTitle: deckTitle,
            deckSubtitle: deckSubtitle,
            activeSectionId: activeSectionId,
            expandedSectionIds: nil,
            onAdjustPlan: nil,
            onSelectLesson: onSelectLesson,
            onDismiss: onDismiss
        )
    }

    // MARK: - Equatable Conformance

    public static func == (lhs: CraftUnitDrawerSheet, rhs: CraftUnitDrawerSheet) -> Bool {
        lhs.sections == rhs.sections &&
        lhs.deckTitle == rhs.deckTitle &&
        lhs.deckSubtitle == rhs.deckSubtitle &&
        lhs.activeSectionId == rhs.activeSectionId &&
        lhs.currentExpandedSectionIds == rhs.currentExpandedSectionIds
    }

    // MARK: - Public Actions & Queries

    /// Checks whether the section with the given identifier is currently expanded.
    public func isSectionExpanded(_ sectionId: String) -> Bool {
        currentExpandedSectionIds.contains(sectionId)
    }

    /// Synchronizes the active section into expanded sections if not already present.
    public func synchronizeActiveSection() {
        guard !activeSectionId.isEmpty else { return }
        var updated = currentExpandedSectionIds
        if !updated.contains(activeSectionId) {
            updated.insert(activeSectionId)
            currentExpandedSectionIds = updated
        }
    }

    /// Selects a lesson and immediately dismisses the drawer sheet.
    public func selectLesson(sectionId: String, nodeId: String) {
        onSelectLesson(sectionId, nodeId)
        onDismiss()
    }

    /// Toggles the expanded state of a section with spring animation.
    public func toggleSection(_ sectionId: String) {
        let action = {
            var updated = currentExpandedSectionIds
            if updated.contains(sectionId) {
                updated.remove(sectionId)
            } else {
                updated.insert(sectionId)
            }
            currentExpandedSectionIds = updated
        }

        if reduceMotion {
            action()
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                action()
            }
        }
    }

    /// Merges CEFR level and deck summary into a single meta subtitle (e.g. "A2 - B1 • 3 lessons • 13 words").
    func sectionMetaSubtitle(for section: LessonSection) -> String? {
        let parts = [section.level, section.subtitle]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }

    /// Whether every node in the section is completed.
    func isSectionCompleted(_ section: LessonSection) -> Bool {
        !section.nodes.isEmpty && section.nodes.allSatisfy { $0.state == .completed }
    }

    /// Localized trailing status for lesson rows, reusing the existing fluid journey keys.
    func lessonStatusText(for node: LessonNodeModel) -> String? {
        switch node.state {
        case .completed:
            return CraftLocalized.string("craft.fluid_journey.completed_status", locale: locale)
        case .active, .inProgress:
            return CraftLocalized.string("craft.fluid_journey.current_status", locale: locale)
        case .bonus, .locked, .upcoming:
            return nil
        }
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            dragIndicator
            topNavigationBar
                .padding(.horizontal, theme.spacing.base)
                .padding(.top, theme.spacing.sm)
                .padding(.bottom, theme.spacing.md)

            Divider()
                .overlay(theme.colors.hairline)

            sectionsScrollView
        }
        .background(theme.colors.canvasBackground)
        .presentationBackground(theme.colors.surfaceCard)
        .presentationCornerRadius(theme.radii.xl)
        .presentationDragIndicator(.hidden)
        .onAppear {
            synchronizeActiveSection()
        }
        .onChange(of: activeSectionId) { _, _ in
            synchronizeActiveSection()
        }
        .accessibilityAction(.escape) {
            onDismiss()
        }
    }
}

// MARK: - Top Navigation Subviews

private extension CraftUnitDrawerSheet {
    var dragIndicator: some View {
        Capsule()
            .fill(theme.colors.borderDefault)
            .frame(width: 36, height: 4)
            .padding(.top, theme.spacing.sm)
            .padding(.bottom, theme.spacing.xxs)
            .accessibilityHidden(true)
    }

    var topNavigationBar: some View {
        HStack(spacing: theme.spacing.md) {
            closeButton
            deckInfoBlock
            Spacer(minLength: theme.spacing.xs)
            if onAdjustPlan != nil {
                adjustPlanButton
            }
        }
    }

    var closeButton: some View {
        Button {
            onDismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(theme.colors.textSecondary)
                .frame(width: 36, height: 36)
                .background(theme.colors.surfaceSubtle)
                .clipShape(Circle())
                .overlay(
                    Circle().strokeBorder(theme.colors.hairline, lineWidth: 1)
                )
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.craftPress(scale: 0.95))
        .accessibilityLabel(CraftLocalized.string("craft.common.action.close", locale: locale))
    }

    var deckInfoBlock: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            Text(CraftLocalized.string("craft.fluid_journey.drawer_title", locale: locale))
                .font(theme.typography.headline.weight(.bold))
                .foregroundStyle(theme.colors.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)

            Text(CraftLocalized.string("craft.fluid_journey.drawer_subtitle", locale: locale))
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textSecondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    var adjustPlanButton: some View {
        Button {
            onAdjustPlan?()
        } label: {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 11, weight: .semibold))
                Text(CraftLocalized.string("craft.fluid_journey.adjust_plan", locale: locale))
                    .font(theme.typography.label.weight(.semibold))
            }
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, theme.spacing.xs)
            .background(theme.colors.surfaceSubtle)
            .foregroundStyle(theme.colors.textPrimary)
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(theme.colors.hairline, lineWidth: 1)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.craftPress(scale: 0.96))
        .accessibilityLabel(CraftLocalized.string("craft.fluid_journey.adjust_plan", locale: locale))
    }
}

// MARK: - Sections Accordion Subviews

private extension CraftUnitDrawerSheet {
    var sectionsScrollView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: theme.spacing.md) {
                ForEach(sections) { section in
                    sectionAccordionCard(for: section)
                }
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.vertical, theme.spacing.md)
        }
    }

    func sectionAccordionCard(for section: LessonSection) -> some View {
        let isExpanded = currentExpandedSectionIds.contains(section.id)
        let isActive = section.id == activeSectionId
        let cardShape = RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous)

        return VStack(spacing: 0) {
            Button {
                toggleSection(section.id)
            } label: {
                sectionHeaderRow(for: section, isExpanded: isExpanded, isActive: isActive)
            }
            .buttonStyle(.craftPress(scale: 0.99))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(sectionAccessibilityLabel(for: section, isExpanded: isExpanded))
            .accessibilityValue(isExpanded ? CraftLocalized.string("craft.common.state.expanded", locale: locale) : CraftLocalized.string("craft.common.state.collapsed", locale: locale))
            .accessibilityHint(isExpanded ? CraftLocalized.string("craft.fluid_journey.collapse_unit_hint", locale: locale) : CraftLocalized.string("craft.fluid_journey.expand_unit_hint", locale: locale))

            if isExpanded && !section.nodes.isEmpty {
                Divider()
                    .overlay(theme.colors.hairline)
                    .padding(.horizontal, theme.spacing.base)

                VStack(spacing: theme.spacing.xxs) {
                    ForEach(section.nodes) { node in
                        lessonRow(for: node, in: section)
                    }
                }
                .padding(.horizontal, theme.spacing.sm)
                .padding(.vertical, theme.spacing.xs)
            }
        }
        .background(theme.colors.surfaceCard)
        .overlay(
            cardShape.strokeBorder(
                isActive ? theme.colors.brandPrimary.opacity(0.35) : theme.colors.hairline,
                lineWidth: 1
            )
        )
        .clipShape(cardShape)
        .craftShadow(theme.shadows.sm)
    }

    func sectionHeaderRow(
        for section: LessonSection,
        isExpanded: Bool,
        isActive: Bool
    ) -> some View {
        HStack(spacing: theme.spacing.md) {
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(section.title)
                    .font(theme.typography.headline.weight(.bold))
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if let meta = sectionMetaSubtitle(for: section) {
                    Text(meta)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            Spacer(minLength: theme.spacing.xs)

            if isSectionCompleted(section) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(theme.colors.statusSuccess)
                    .accessibilityHidden(true)
            }

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.colors.textSecondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .accessibilityHidden(true)
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.vertical, theme.spacing.md)
        .contentShape(Rectangle())
    }
}

// MARK: - Lesson Item Subviews & Helpers

private extension CraftUnitDrawerSheet {
    func lessonRow(for node: LessonNodeModel, in section: LessonSection) -> some View {
        Button {
            selectLesson(sectionId: section.id, nodeId: node.id)
        } label: {
            HStack(spacing: theme.spacing.sm) {
                lessonNodeStatusIcon(for: node.state)

                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    Text(node.title)
                        .font(theme.typography.bodyMedium.weight(node.state == .active ? .bold : .medium))
                        .foregroundStyle(node.state == .locked ? theme.colors.textMuted : theme.colors.textPrimary)
                        .lineLimit(1)
                }

                Spacer(minLength: theme.spacing.xs)
            }
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, theme.spacing.sm)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: theme.radii.sm, style: .continuous)
                    .fill(node.state == .active ? theme.colors.brandPrimary.opacity(0.08) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.craftPress(scale: 0.98))
        .disabled(node.state == .locked)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(lessonAccessibilityLabel(for: node))
        .accessibilityHint(CraftLocalized.string("craft.fluid_journey.select_unit_hint", locale: locale))
    }

    func lessonNodeStatusIcon(for state: LessonNodeState) -> some View {
        Group {
            switch state {
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.colors.statusSuccess)
            case .active, .inProgress:
                Image(systemName: "record.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.colors.brandPrimary)
            case .bonus:
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.colors.statusWarning)
            case .locked:
                Image(systemName: "lock.circle")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(theme.colors.textMuted)
            case .upcoming:
                Image(systemName: "circle")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(theme.colors.textMuted)
            }
        }
        .frame(width: 24, height: 24)
    }

    func sectionAccessibilityLabel(for section: LessonSection, isExpanded: Bool) -> String {
        var components: [String] = [section.title]
        if let meta = sectionMetaSubtitle(for: section) {
            components.append(meta)
        }
        if section.id == activeSectionId {
            components.append(CraftLocalized.string("craft.fluid_journey.current_status", locale: locale))
        }
        return components.joined(separator: ", ")
    }

    func lessonAccessibilityLabel(for node: LessonNodeModel) -> String {
        var components: [String] = [node.title]
        if let status = lessonStatusText(for: node) {
            components.append(status)
        }
        return components.joined(separator: ", ")
    }
}

// MARK: - Preview

#Preview("CraftUnitDrawerSheet") {
    let sections = [
        LessonSection(
            id: "sec-1",
            title: "Everyday Conversations",
            subtitle: "Habits & Moods",
            level: "A2",
            nodes: [
                LessonNodeModel(id: "n-1", title: "Morning Routines", subtitle: "10 words • 3 min", state: .completed, xpReward: 20),
                LessonNodeModel(id: "n-2", title: "Describing Feelings", subtitle: "12 words • 5 min", state: .active, xpReward: 25),
                LessonNodeModel(id: "n-3", title: "Weekend Plans", subtitle: "8 words • 4 min", state: .upcoming, xpReward: 15)
            ]
        ),
        LessonSection(
            id: "sec-2",
            title: "Professional Work",
            subtitle: "Meetings & Emails",
            level: "B1",
            nodes: [
                LessonNodeModel(id: "n-4", title: "Email Openers", subtitle: "15 words • 5 min", state: .upcoming, xpReward: 30)
            ]
        )
    ]

    CraftUnitDrawerSheet(
        sections: sections,
        deckTitle: "Everyday English",
        deckSubtitle: "A2 • Career Growth",
        activeSectionId: "sec-1",
        onSelectLesson: { _, _ in },
        onDismiss: {}
    )
}
