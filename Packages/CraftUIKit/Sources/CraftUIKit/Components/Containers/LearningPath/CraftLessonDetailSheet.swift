import SwiftUI

// MARK: - CraftLessonDetailSheet Component

/// An interactive modal sheet presenting detailed lesson metadata, XP rewards, estimated completion time,
/// learning objectives, and a context-sensitive primary call-to-action button.
public struct CraftLessonDetailSheet: View {
    public let node: LessonNodeModel
    public let surfaceStyle: CraftSurfaceStyle?
    public let onStart: (@Sendable (LessonNodeModel) -> Void)?
    public let onDismiss: (@Sendable () -> Void)?

    @Environment(\.craftTheme) private var theme
    @Environment(\.craftSurfaceStyle) private var environmentStyle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var isHeaderFocused: Bool
    @ScaledMetric(relativeTo: .body) private var baseScale: CGFloat = 1.0

    // MARK: - Initializer

    public init(
        node: LessonNodeModel,
        surfaceStyle: CraftSurfaceStyle? = nil,
        onStart: (@Sendable (LessonNodeModel) -> Void)? = nil,
        onDismiss: (@Sendable () -> Void)? = nil
    ) {
        self.node = node
        self.surfaceStyle = surfaceStyle
        self.onStart = onStart
        self.onDismiss = onDismiss
    }

    /// Effective surface style resolved from explicit parameter, environment, or theme default.
    public var effectiveSurfaceStyle: CraftSurfaceStyle {
        surfaceStyle ?? (environmentStyle != .flat ? environmentStyle : theme.journeySurfaceStyle)
    }

    // MARK: - Computed Properties

    /// Context-sensitive CTA title matching the node's progress and progression state.
    public var ctaTitle: String {
        switch node.state {
        case .active, .upcoming:
            return CraftLocalized.string("craft.learning_path.start_lesson")
        case .inProgress:
            let percentage = Int(((node.progress ?? 0) * 100).rounded())
            return CraftLocalized.format("craft.learning_path.continue_lesson_format", percentage)
        case .completed:
            return CraftLocalized.format("craft.learning_path.review_lesson_format", node.xpReward ?? 20)
        case .bonus:
            return CraftLocalized.string("craft.learning_path.challenge_lesson")
        case .locked:
            return CraftLocalized.string("craft.learning_path.locked_lesson")
        }
    }

    /// Context-sensitive button variant based on the node progression state.
    public var ctaVariant: CraftButtonVariant {
        switch node.state {
        case .active, .inProgress, .upcoming, .bonus:
            return .primary
        case .completed, .locked:
            return .secondary
        }
    }

    /// Whether the CTA button is disabled (e.g. for locked lessons).
    public var isCtaDisabled: Bool {
        node.state == .locked
    }

    /// Formatted XP reward string.
    public var formattedXPReward: String {
        "+\(node.xpReward ?? 20) XP"
    }

    /// Formatted estimated duration string.
    public var formattedDuration: String {
        CraftLocalized.format("craft.common.unit.minutes_format", node.estimatedMinutes ?? 5)
    }

    /// Formatted vocabulary / objective count string.
    public var formattedVocabularyCount: String {
        node.subtitle ?? CraftLocalized.format("craft.common.unit.words_format", 15)
    }

    /// Accessibility label for the XP reward metric chip.
    public var accessibilityXPLabel: String {
        CraftLocalized.format("craft.learning_path.reward_format_a11y", node.xpReward ?? 20)
    }

    /// Accessibility label for the duration metric chip.
    public var accessibilityDurationLabel: String {
        CraftLocalized.format("craft.learning_path.duration_format_a11y", formattedDuration)
    }

    /// Accessibility label for the vocabulary / objectives metric chip.
    public var accessibilityVocabularyLabel: String {
        formattedVocabularyCount
    }

    /// Capitalized status text for badge presentation.
    public var statusBadgeTitle: String {
        node.state.rawValue.capitalized
    }

    /// Badge tone corresponding to the node progression state.
    public var statusBadgeTone: CraftBadgeTone {
        switch node.state {
        case .completed:
            return .success
        case .active, .inProgress:
            return .primary
        case .bonus:
            return .warning
        case .upcoming, .locked:
            return .neutral
        }
    }

    // MARK: - Sizing Constants

    private var tactileDiameter: CGFloat {
        54 * baseScale
    }

    private var iconSize: CGFloat {
        24 * baseScale
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacing.base) {
                    // Header Section: Tactile 3D Icon, Title, Stars (if completed), Status Badge
                    headerSection

                    // Metrics Chips Row
                    metricsRow

                    // Description / Learning Objectives Card
                    objectivesCard
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.top, theme.spacing.lg)
                .padding(.bottom, theme.spacing.sm)
            }

            // Primary Action Button
            actionButton
                .padding(.horizontal, theme.spacing.base)
                .padding(.top, theme.spacing.xs)
                .padding(.bottom, theme.spacing.lg)
        }
        .background(theme.colors.canvasBackground)
        .presentationBackground(theme.colors.canvasBackground)
        .presentationDragIndicator(.visible)
        .accessibilityAction(.escape) {
            triggerDismissFeedback()
            onDismiss?()
        }
        .task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            isHeaderFocused = true
        }
    }
}

// MARK: - Header & Badge Extensions

private extension CraftLessonDetailSheet {
    var headerSection: some View {
        VStack(spacing: theme.spacing.xs) {
            tactile3DNodeIcon
                .padding(.bottom, theme.spacing.xs)

            Text(node.title)
                .font(theme.typography.titleLarge.bold())
                .foregroundStyle(theme.colors.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($isHeaderFocused)

            if node.state == .completed, let starCount = node.stars, starCount > 0 {
                starRatingView(count: starCount)
            }

            CraftBadge(
                statusBadgeTitle,
                iconName: statusBadgeIcon,
                variant: .subtle,
                tone: statusBadgeTone,
                size: .md
            )
        }
        .frame(maxWidth: .infinity)
    }

    func starRatingView(count: Int) -> some View {
        let clampedStars = min(max(count, 0), 3)
        return HStack(spacing: 4) {
            ForEach(0..<clampedStars, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(theme.gradients.accentShine)
                    .shadow(color: theme.colors.accent.opacity(0.5), radius: 0, x: 0, y: 1.2)
            }
        }
        .accessibilityHidden(true)
    }

    var statusBadgeIcon: String {
        switch node.state {
        case .completed:
            return "checkmark.circle.fill"
        case .active:
            return "flame.fill"
        case .inProgress:
            return "bolt.fill"
        case .bonus:
            return "star.fill"
        case .locked:
            return "lock.fill"
        case .upcoming:
            return "character.book.closed.fill"
        }
    }
}

// MARK: - 3D Tactile Node Icon Extensions

private extension CraftLessonDetailSheet {
    var tactile3DNodeIcon: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                // Bottom 3D Bevel/Rim
                bottomRimShape
                    .offset(y: node.state == .locked ? 0 : 4)

                // Top Face
                topFaceShape
            }

            if node.state == .completed {
                ZStack {
                    Circle()
                        .fill(theme.colors.surfaceCard)
                        .frame(width: 26, height: 26)
                    Circle()
                        .fill(theme.colors.statusSuccess)
                        .frame(width: 22, height: 22)
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white)
                }
                .offset(x: 4, y: 4)
            }
        }
        .frame(width: tactileDiameter, height: tactileDiameter + (node.state == .locked ? 0 : 4))
        .accessibilityHidden(true)
    }

    @ViewBuilder
    var bottomRimShape: some View {
        switch node.kind {
        case .checkpoint:
            HexagonShape()
                .fill(rimColor)
                .frame(width: tactileDiameter, height: tactileDiameter)
        case .standard, .treasureChest:
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(rimColor)
                .frame(width: tactileDiameter, height: tactileDiameter)
        }
    }

    var topFaceShape: some View {
        ZStack {
            faceBackground

            // Highlight overlay
            faceHighlight

            // Center SF Symbol
            Image(systemName: effectiveIconName)
                .font(.system(size: iconSize, weight: .bold))
                .foregroundStyle(effectiveIconColor)
        }
        .frame(width: tactileDiameter, height: tactileDiameter)
        .opacity(node.state == .locked ? 0.6 : 1.0)
    }

    @ViewBuilder
    var faceBackground: some View {
        switch node.kind {
        case .checkpoint:
            ZStack {
                switch node.state {
                case .completed:
                    HexagonShape().fill(theme.colors.statusSuccess)
                case .active:
                    HexagonShape().fill(theme.gradients.brandHero)
                case .inProgress:
                    HexagonShape().fill(theme.colors.surfaceElevated)
                case .upcoming, .locked:
                    HexagonShape().fill(theme.colors.surfaceSubtle)
                case .bonus:
                    HexagonShape().fill(theme.gradients.accentShine)
                }

                if node.state == .upcoming || node.state == .locked {
                    HexagonShape()
                        .stroke(theme.colors.borderDefault, lineWidth: 1.5)
                }
            }
        case .standard:
            let squircle = RoundedRectangle(cornerRadius: 22, style: .continuous)
            ZStack {
                switch node.state {
                case .completed:
                    squircle.fill(theme.colors.brandPrimary.opacity(0.14))
                case .active:
                    squircle.fill(theme.gradients.brandHero)
                case .inProgress:
                    squircle.fill(theme.colors.surfaceElevated)
                case .upcoming, .locked:
                    squircle.fill(theme.colors.surfaceSubtle)
                case .bonus:
                    squircle.fill(theme.gradients.accentShine)
                }

                if node.state == .upcoming || node.state == .locked {
                    squircle
                        .stroke(theme.colors.borderDefault, lineWidth: 1.5)
                }
            }
        case .treasureChest:
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(theme.gradients.accentShine)
        }
    }

    @ViewBuilder
    var faceHighlight: some View {
        switch node.kind {
        case .checkpoint:
            HexagonShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
        case .standard, .treasureChest:
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
        }
    }

    var rimColor: Color {
        switch node.kind {
        case .treasureChest:
            return theme.colors.accent.opacity(0.85)
        case .standard, .checkpoint:
            switch node.state {
            case .completed:
                return theme.colors.brandPrimary.opacity(0.3)
            case .active:
                return theme.colors.brandPrimary.opacity(0.85)
            case .inProgress, .upcoming:
                return theme.colors.borderDefault
            case .locked:
                return theme.colors.surfaceSubtle
            case .bonus:
                return theme.colors.accent.opacity(0.85)
            }
        }
    }

    var effectiveIconName: String {
        if node.kind == .treasureChest {
            return (node.iconName == "book.fill" || node.iconName.isEmpty) ? "gift.fill" : node.iconName
        }

        if node.kind == .checkpoint && (node.iconName == "book.fill" || node.iconName.isEmpty) {
            return "crown.fill"
        }

        if !node.iconName.isEmpty {
            return CraftJourneyNode.resolveIconName(for: node.iconName)
        }

        switch node.state {
        case .completed:
            return "checkmark"
        case .locked:
            return "lock.fill"
        case .bonus:
            return "star.fill"
        case .active, .inProgress, .upcoming:
            return "book.fill"
        }
    }

    var effectiveIconColor: Color {
        switch node.state {
        case .completed:
            return theme.colors.brandPrimary
        case .active, .bonus:
            return .white
        case .inProgress:
            return .white
        case .upcoming, .locked:
            return theme.colors.textMuted
        }
    }
}

// MARK: - Metrics, Objectives & Action Extensions

private extension CraftLessonDetailSheet {
    var metricsRow: some View {
        HStack(spacing: theme.spacing.sm) {
            // XP Reward Chip
            metricChip(
                icon: "sparkles",
                title: formattedXPReward,
                accessibilityLabel: accessibilityXPLabel,
                tintColor: theme.colors.accent,
                backgroundColor: theme.colors.accent.opacity(0.12)
            )

            // Duration Chip
            metricChip(
                icon: "clock.fill",
                title: formattedDuration,
                accessibilityLabel: accessibilityDurationLabel,
                tintColor: theme.colors.brandPrimary,
                backgroundColor: theme.colors.brandPrimary.opacity(0.12)
            )

            // Target / Word Count Chip
            metricChip(
                icon: "character.book.closed.fill",
                title: formattedVocabularyCount,
                accessibilityLabel: accessibilityVocabularyLabel,
                tintColor: theme.colors.textSecondary,
                backgroundColor: theme.colors.surfaceSubtle
            )
        }
        .frame(maxWidth: .infinity)
    }

    func metricChip(
        icon: String,
        title: String,
        accessibilityLabel: String? = nil,
        tintColor: Color,
        backgroundColor: Color
    ) -> some View {
        let isTactile = (effectiveSurfaceStyle == .tactile3D)
        let chipCornerRadius = theme.radii.md
        let bottomRimDepth: CGFloat = isTactile ? 2.5 : 0

        let chipContent = HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tintColor)

            Text(title)
                .font(theme.typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(theme.colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(
            isTactile ? theme.colors.surfaceCard : backgroundColor
        )
        .clipShape(RoundedRectangle(cornerRadius: chipCornerRadius, style: .continuous))
        .overlay {
            if isTactile {
                RoundedRectangle(cornerRadius: chipCornerRadius, style: .continuous)
                    .stroke(theme.depths.topHighlight, lineWidth: 1)
            } else {
                RoundedRectangle(cornerRadius: chipCornerRadius, style: .continuous)
                    .stroke(theme.colors.borderDefault.opacity(0.5), lineWidth: 1)
            }
        }

        return Group {
            if isTactile {
                ZStack {
                    RoundedRectangle(cornerRadius: chipCornerRadius, style: .continuous)
                        .fill(theme.colors.surfaceElevated)
                        .offset(y: bottomRimDepth)
                    chipContent
                }
                .padding(.bottom, bottomRimDepth)
            } else {
                chipContent
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel ?? title)
    }

    var resolvedObjectives: [String]? {
        if let customObjectives = node.objectives, !customObjectives.isEmpty {
            return customObjectives
        }
        if let objectiveKeys = node.objectiveKeys, !objectiveKeys.isEmpty {
            return objectiveKeys.map { CraftLocalized.string($0) }
        }
        return nil
    }

    var objectivesCard: some View {
        CraftCard(style: effectiveSurfaceStyle == .tactile3D ? .tactile3D : .outlined) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(theme.colors.brandPrimary)

                    Text(CraftLocalized.string("craft.learning_path.objectives_header"))
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.colors.textPrimary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    if let objectives = resolvedObjectives {
                        ForEach(objectives, id: \.self) { objective in
                            objectiveRow(icon: "checkmark.circle.fill", text: objective)
                        }
                    } else {
                        objectiveRow(icon: "checkmark.circle.fill", text: CraftLocalized.string("craft.learning_path.default_objective_1"))
                        objectiveRow(icon: "checkmark.circle.fill", text: CraftLocalized.string("craft.learning_path.default_objective_2"))
                        objectiveRow(icon: "checkmark.circle.fill", text: CraftLocalized.format("craft.learning_path.default_objective_3_format", formattedXPReward))
                    }
                }
            }
        }
    }

    func objectiveRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.colors.statusSuccess)
                .padding(.top, 2)

            Text(text)
                .font(theme.typography.bodyMedium)
                .foregroundStyle(theme.colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var actionButton: some View {
        CraftButton(
            ctaTitle,
            variant: (effectiveSurfaceStyle == .tactile3D && ctaVariant == .primary) ? .tactile : ctaVariant,
            size: .lg,
            isFullWidth: true,
            style: effectiveSurfaceStyle
        ) {
            triggerTapFeedback()
            if !isCtaDisabled {
                onStart?(node)
            }
        }
        .disabled(isCtaDisabled)
        .accessibilityLabel(ctaTitle)
        .accessibilityHint(
            isCtaDisabled
                ? CraftLocalized.string("craft.learning_path.unlock_requirement_hint")
                : CraftLocalized.string("craft.learning_path.tap_to_start_hint")
        )
    }

    func triggerTapFeedback() {
        #if os(iOS)
        if isCtaDisabled {
            CraftHaptics.shared.warning()
        } else {
            CraftHaptics.shared.medium()
        }
        #endif
    }

    func triggerDismissFeedback() {
        #if os(iOS)
        CraftHaptics.shared.light()
        #endif
    }
}
