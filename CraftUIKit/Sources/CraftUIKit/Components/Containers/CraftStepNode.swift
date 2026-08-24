import SwiftUI

// MARK: - Step State Enum

/// Visual and functional state of a milestone step in a roadmap or workflow.
public enum CraftStepState: String, Sendable, Equatable, Hashable, CaseIterable {
    case completed
    case active
    case locked
    case upcoming

    /// Accessible VoiceOver description for the step state.
    public var accessibilityDescription: String {
        switch self {
        case .completed: return "Completed"
        case .active: return "Active"
        case .locked: return "Locked"
        case .upcoming: return "Upcoming"
        }
    }
}

// MARK: - Dashed Line Shape

private struct VerticalDashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

// MARK: - CraftStepNode Component

/// A roadmap milestone node displaying circle badges (checkmark for completed, glow ring for active, padlock for locked,
/// number badge for upcoming), connector stroke lines (solid for completed/active, dashed for locked/upcoming),
/// title and optional subtitle, with minimum 44pt touch target HIG compliance.
public struct CraftStepNode: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var indicatorDimension: CGFloat = 36
    @State private var isPulsing = false

    private let titleKey: LocalizedStringKey?
    private let rawTitle: String?
    private let subtitleKey: LocalizedStringKey?
    private let rawSubtitle: String?

    public var title: String { rawTitle ?? "" }
    public var subtitle: String? { rawSubtitle }
    public let state: CraftStepState
    public let stepNumber: Int?
    public let isLast: Bool
    public let onTap: (() -> Void)?

    public init(
        title: String,
        subtitle: String? = nil,
        state: CraftStepState,
        stepNumber: Int? = nil,
        isLast: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.subtitleKey = nil
        self.rawSubtitle = subtitle
        self.state = state
        self.stepNumber = stepNumber
        self.isLast = isLast
        self.onTap = onTap
    }

    public init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        state: CraftStepState,
        stepNumber: Int? = nil,
        isLast: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.titleKey = title
        self.rawTitle = nil
        self.subtitleKey = subtitle
        self.rawSubtitle = nil
        self.state = state
        self.stepNumber = stepNumber
        self.isLast = isLast
        self.onTap = onTap
    }

    public var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) {
                    contentLayout
                }
                .buttonStyle(.craftPress(scale: 0.98))
            } else {
                contentLayout
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(onTap != nil ? "Double tap to select this step" : "")
    }

    // MARK: - Content Layout

    private var contentLayout: some View {
        HStack(alignment: .top, spacing: theme.spacing.md) {
            // Indicator Column (Badge + Connector)
            VStack(spacing: 0) {
                badgeView
                    .frame(width: indicatorDimension, height: indicatorDimension)

                if !isLast {
                    connectorView
                        .frame(width: 2)
                        .frame(minHeight: 24)
                }
            }
            .frame(width: indicatorDimension)

            // Text Information Column
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                if let titleKey {
                    Text(titleKey)
                        .font(theme.typography.headline)
                        .foregroundStyle(titleColor)
                        .frame(minHeight: max(36, indicatorDimension), alignment: .leading)
                } else if let rawTitle {
                    Text(rawTitle)
                        .font(theme.typography.headline)
                        .foregroundStyle(titleColor)
                        .frame(minHeight: max(36, indicatorDimension), alignment: .leading)
                }

                if let subtitleKey {
                    Text(subtitleKey)
                        .font(theme.typography.bodyMedium)
                        .foregroundStyle(subtitleColor)
                        .padding(.bottom, isLast ? 0 : theme.spacing.sm)
                } else if let rawSubtitle {
                    Text(rawSubtitle)
                        .font(theme.typography.bodyMedium)
                        .foregroundStyle(subtitleColor)
                        .padding(.bottom, isLast ? 0 : theme.spacing.sm)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    // MARK: - Badge View

    @ViewBuilder
    private var badgeView: some View {
        ZStack {
            switch state {
            case .completed:
                ZStack {
                    // 3D Pedestal Bottom Rim
                    Circle()
                        .fill(Color(hex: 0x059669))
                        .frame(width: 28, height: 28)
                        .offset(y: theme.depths.depthSm)

                    // Top Face
                    Circle()
                        .fill(theme.colors.statusSuccess)
                        .frame(width: 28, height: 28)

                    // Top Highlight Stroke
                    Circle()
                        .strokeBorder(theme.depths.topHighlight, lineWidth: 1.0)
                        .frame(width: 28, height: 28)

                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 28, height: 28 + theme.depths.depthSm)

            case .active:
                // Glowing outer breathing ring
                Circle()
                    .stroke(theme.colors.brandPrimary.opacity(isPulsing ? 0.45 : 0.2), lineWidth: isPulsing ? 4.5 : 3.0)
                    .frame(width: indicatorDimension, height: indicatorDimension)
                    .scaleEffect(isPulsing && !reduceMotion ? 1.05 : 1.0)
                    .onAppear {
                        guard !reduceMotion else { return }
                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            isPulsing = true
                        }
                    }
                    .onDisappear {
                        isPulsing = false
                    }

                // 3D Pedestal Inner Badge
                ZStack {
                    // Bottom Rim
                    Circle()
                        .fill(Color(hex: 0xC2410C))
                        .frame(width: 26, height: 26)
                        .offset(y: theme.depths.depthSm)

                    // Top Face
                    Circle()
                        .fill(theme.colors.brandPrimary)
                        .frame(width: 26, height: 26)

                    // Top Highlight Stroke
                    Circle()
                        .strokeBorder(theme.depths.topHighlight, lineWidth: 1.0)
                        .frame(width: 26, height: 26)

                    if let stepNumber {
                        Text("\(stepNumber)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    } else {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                    }
                }
                .frame(width: 26, height: 26 + theme.depths.depthSm)

            case .locked:
                Circle()
                    .fill(theme.colors.surfaceSubtle)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .strokeBorder(theme.colors.borderDefault, lineWidth: 1.5)
                    )
                    .overlay {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(theme.colors.textMuted)
                    }

            case .upcoming:
                ZStack {
                    // Bottom Rim subtle depth
                    Circle()
                        .fill(theme.colors.borderDefault)
                        .frame(width: 28, height: 28)
                        .offset(y: 1.5)

                    // Top Face
                    Circle()
                        .fill(theme.colors.surfaceSubtle)
                        .frame(width: 28, height: 28)

                    // Border
                    Circle()
                        .strokeBorder(theme.colors.borderDefault, lineWidth: 1.5)
                        .frame(width: 28, height: 28)

                    if let stepNumber {
                        Text("\(stepNumber)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.colors.textSecondary)
                    } else {
                        Circle()
                            .fill(theme.colors.textMuted)
                            .frame(width: 8, height: 8)
                    }
                }
                .frame(width: 28, height: 29.5)
            }
        }
    }

    // MARK: - Connector View

    @ViewBuilder
    private var connectorView: some View {
        switch state {
        case .completed, .active:
            Rectangle()
                .fill(state == .completed ? theme.colors.statusSuccess : theme.colors.brandPrimary)
        case .locked, .upcoming:
            VerticalDashedLine()
                .stroke(theme.colors.borderDefault, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
        }
    }

    // MARK: - Colors & Accessibility

    private var titleColor: Color {
        switch state {
        case .completed, .active, .upcoming:
            return theme.colors.textPrimary
        case .locked:
            return theme.colors.textMuted
        }
    }

    private var subtitleColor: Color {
        switch state {
        case .completed, .active, .upcoming:
            return theme.colors.textSecondary
        case .locked:
            return theme.colors.textMuted.opacity(0.8)
        }
    }

    private var accessibilityLabelText: String {
        var label = title.isEmpty ? "Step" : title
        if let stepNumber {
            label = "Step \(stepNumber): \(label)"
        }
        label += ", \(state.accessibilityDescription)"
        if let subtitle {
            label += ", \(subtitle)"
        }
        return label
    }
}

#Preview("CraftStepNode") {
    VStack(spacing: 0) {
        CraftStepNode(
            title: "Completed Step",
            subtitle: "This is done",
            state: .completed,
            stepNumber: 1
        )
        CraftStepNode(
            title: "Active Step",
            subtitle: "Currently working on this",
            state: .active,
            stepNumber: 2
        )
        CraftStepNode(
            title: "Upcoming Step",
            state: .upcoming,
            stepNumber: 3
        )
        CraftStepNode(
            title: "Locked Step",
            state: .locked,
            stepNumber: 4,
            isLast: true
        )
    }
    .padding()
}

