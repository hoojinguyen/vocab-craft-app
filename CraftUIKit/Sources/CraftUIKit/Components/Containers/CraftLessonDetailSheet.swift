import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - CraftLessonDetailSheet Component

/// An interactive modal sheet presenting detailed lesson metadata, XP rewards, estimated completion time,
/// learning objectives, and a context-sensitive primary call-to-action button.
public struct CraftLessonDetailSheet: View {
    public let node: LessonNodeModel
    public let onStart: (@Sendable (LessonNodeModel) -> Void)?
    public let onDismiss: (@Sendable () -> Void)?

    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var baseScale: CGFloat = 1.0

    // MARK: - Initializer

    public init(
        node: LessonNodeModel,
        onStart: (@Sendable (LessonNodeModel) -> Void)? = nil,
        onDismiss: (@Sendable () -> Void)? = nil
    ) {
        self.node = node
        self.onStart = onStart
        self.onDismiss = onDismiss
    }

    // MARK: - Computed Properties

    /// Context-sensitive CTA title matching the node's progress and progression state.
    public var ctaTitle: String {
        switch node.state {
        case .active, .upcoming:
            return "BẮT ĐẦU HỌC"
        case .inProgress:
            let percentage = Int(((node.progress ?? 0) * 100).rounded())
            return "TIẾP TỤC HỌC (\(percentage)%)"
        case .completed:
            return "ÔN TẬP LẠI (+5 XP)"
        case .bonus:
            return "CHINH PHỤC THỬ THÁCH"
        case .locked:
            return "BÀI HỌC ĐANG KHÓA"
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
        "⏱ \(node.estimatedMinutes ?? 5) phút"
    }

    /// Formatted vocabulary / objective count string.
    public var formattedVocabularyCount: String {
        node.subtitle ?? "15 từ vựng mới"
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

    private var statusBadgeIcon: String {
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

    // MARK: - Sizing

    private var tactileDiameter: CGFloat {
        60 * baseScale
    }

    private var iconSize: CGFloat {
        26 * baseScale
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            // Drag Indicator Handle
            Capsule()
                .fill(theme.colors.borderDefault)
                .frame(width: 36, height: 4)
                .padding(.top, theme.spacing.sm)
                .padding(.bottom, theme.spacing.xs)
                .accessibilityHidden(true)

            // Header Bar with Dismiss Button
            HStack {
                Spacer()
                Button {
                    triggerDismissFeedback()
                    onDismiss?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(theme.colors.textMuted)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Đóng")
                .accessibilityHint("Nhấn đúp để đóng thông tin bài học")
            }
            .padding(.horizontal, theme.spacing.base)

            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Header Section: Tactile 3D Icon, Title, Status Badge
                    headerSection

                    // Metrics Chips Row
                    metricsRow

                    // Description / Learning Objectives Card
                    objectivesCard
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.bottom, theme.spacing.base)
            }

            // Primary Action Button
            actionButton
                .padding(.horizontal, theme.spacing.base)
                .padding(.top, theme.spacing.xs)
                .padding(.bottom, theme.spacing.lg)
        }
        .background(theme.colors.surfaceCard)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: theme.radii.xl,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: theme.radii.xl
            )
        )
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: theme.spacing.sm) {
            tactile3DNodeIcon

            Text(node.title)
                .font(theme.typography.titleLarge.bold())
                .foregroundStyle(theme.colors.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

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

    // MARK: - 3D Tactile Node Icon (60pt diameter)

    private var tactile3DNodeIcon: some View {
        ZStack {
            // Bottom 3D Bevel/Rim
            bottomRimShape
                .offset(y: node.state == .locked ? 0 : 5)

            // Top Face
            topFaceShape
        }
        .frame(width: tactileDiameter, height: tactileDiameter + (node.state == .locked ? 0 : 5))
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var bottomRimShape: some View {
        switch node.kind {
        case .checkpoint:
            HexagonShape()
                .fill(rimColor)
                .frame(width: tactileDiameter, height: tactileDiameter)
        case .standard, .treasureChest:
            Circle()
                .fill(rimColor)
                .frame(width: tactileDiameter, height: tactileDiameter)
        }
    }

    private var topFaceShape: some View {
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
    private var faceBackground: some View {
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
                        .strokeBorder(theme.colors.borderDefault, lineWidth: 1.5)
                }
            }
        case .standard:
            ZStack {
                switch node.state {
                case .completed:
                    Circle().fill(theme.colors.statusSuccess)
                case .active:
                    Circle().fill(theme.gradients.brandHero)
                case .inProgress:
                    Circle().fill(theme.colors.surfaceElevated)
                case .upcoming, .locked:
                    Circle().fill(theme.colors.surfaceSubtle)
                case .bonus:
                    Circle().fill(theme.gradients.accentShine)
                }

                if node.state == .upcoming || node.state == .locked {
                    Circle()
                        .strokeBorder(theme.colors.borderDefault, lineWidth: 1.5)
                }
            }
        case .treasureChest:
            Circle()
                .fill(theme.gradients.accentShine)
        }
    }

    @ViewBuilder
    private var faceHighlight: some View {
        switch node.kind {
        case .checkpoint:
            HexagonShape()
                .strokeBorder(
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
            Circle()
                .strokeBorder(
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

    private var rimColor: Color {
        switch node.kind {
        case .treasureChest:
            return Color(hex: 0xD97706)
        case .standard, .checkpoint:
            switch node.state {
            case .completed:
                return Color(hex: 0x059669)
            case .active:
                return Color(hex: 0xC2410C)
            case .inProgress, .upcoming:
                return theme.colors.borderDefault
            case .locked:
                return theme.colors.surfaceSubtle
            case .bonus:
                return Color(hex: 0xD97706)
            }
        }
    }

    private var effectiveIconName: String {
        if node.kind == .treasureChest {
            return (node.iconName == "book.fill" || node.iconName.isEmpty) ? "gift.fill" : node.iconName
        }

        switch node.state {
        case .completed:
            return "checkmark"
        case .locked:
            return "lock.fill"
        case .bonus:
            return node.iconName.isEmpty ? "star.fill" : node.iconName
        case .active, .inProgress, .upcoming:
            if node.kind == .checkpoint && (node.iconName == "book.fill" || node.iconName.isEmpty) {
                return "crown.fill"
            }
            return node.iconName.isEmpty ? "book.fill" : node.iconName
        }
    }

    private var effectiveIconColor: Color {
        switch node.state {
        case .completed, .active, .bonus:
            return .white
        case .inProgress:
            return theme.colors.brandPrimary
        case .upcoming, .locked:
            return theme.colors.textMuted
        }
    }

    // MARK: - Metrics Row

    private var metricsRow: some View {
        HStack(spacing: theme.spacing.sm) {
            // XP Reward Chip
            metricChip(
                icon: "sparkles",
                title: formattedXPReward,
                tintColor: theme.colors.accent,
                backgroundColor: theme.colors.accent.opacity(0.12)
            )

            // Duration Chip
            metricChip(
                icon: "clock.fill",
                title: "\(node.estimatedMinutes ?? 5) phút",
                tintColor: theme.colors.brandPrimary,
                backgroundColor: theme.colors.brandPrimary.opacity(0.12)
            )

            // Target / Word Count Chip
            metricChip(
                icon: "character.book.closed.fill",
                title: formattedVocabularyCount,
                tintColor: theme.colors.textSecondary,
                backgroundColor: theme.colors.surfaceSubtle
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func metricChip(
        icon: String,
        title: String,
        tintColor: Color,
        backgroundColor: Color
    ) -> some View {
        HStack(spacing: 5) {
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
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.md)
                .strokeBorder(theme.colors.borderDefault.opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - Objectives Card

    private var objectivesCard: some View {
        CraftCard(style: .outlined) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(theme.colors.brandPrimary)

                    Text("Mục tiêu bài học")
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.colors.textPrimary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    objectiveRow(icon: "checkmark.circle.fill", text: "Nắm vững phát âm chuẩn và ý nghĩa từ vựng trọng tâm")
                    objectiveRow(icon: "checkmark.circle.fill", text: "Thực hành phản xạ câu qua bài tập tương tác Spaced Repetition")
                    objectiveRow(icon: "checkmark.circle.fill", text: "Tích lũy \(formattedXPReward) và duy trì chuỗi Streak học tập")
                }
            }
        }
    }

    private func objectiveRow(icon: String, text: String) -> some View {
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

    // MARK: - Action Button

    private var actionButton: some View {
        CraftButton(
            ctaTitle,
            variant: ctaVariant,
            size: .lg,
            isFullWidth: true
        ) {
            triggerTapFeedback()
            if !isCtaDisabled {
                onStart?(node)
            }
        }
        .disabled(isCtaDisabled)
        .accessibilityLabel(ctaTitle)
        .accessibilityHint(isCtaDisabled ? "Bài học đang bị khóa" : "Nhấn đúp để bắt đầu học")
    }

    // MARK: - Haptic Feedback

    private func triggerTapFeedback() {
        #if os(iOS)
        if isCtaDisabled {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
        } else {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        }
        #endif
    }

    private func triggerDismissFeedback() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
}

// MARK: - Preview

#Preview("CraftLessonDetailSheet - Active") {
    CraftLessonDetailSheet(
        node: LessonNodeModel(
            id: "preview_active",
            title: "Daily Food & Drinks",
            subtitle: "15 từ mới • 4 phút",
            iconName: "cup.and.saucer.fill",
            state: .active,
            progress: 0.45,
            xpReward: 30,
            estimatedMinutes: 4
        )
    )
}

#Preview("CraftLessonDetailSheet - Checkpoint") {
    CraftLessonDetailSheet(
        node: LessonNodeModel(
            id: "preview_cp",
            title: "Mastery Checkpoint",
            subtitle: "25 câu hỏi tổng hợp",
            iconName: "crown.fill",
            state: .inProgress,
            kind: .checkpoint,
            progress: 0.75,
            xpReward: 80,
            estimatedMinutes: 8
        )
    )
}

#Preview("CraftLessonDetailSheet - Locked") {
    CraftLessonDetailSheet(
        node: LessonNodeModel(
            id: "preview_locked",
            title: "Advanced Travel Phrases",
            subtitle: "20 từ vựng nâng cao",
            iconName: "airplane",
            state: .locked,
            xpReward: 50,
            estimatedMinutes: 6
        )
    )
}
