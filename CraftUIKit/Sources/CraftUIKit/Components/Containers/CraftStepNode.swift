import SwiftUI
#if os(iOS)
import UIKit
#endif

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

    public let title: String
    public let subtitle: String?
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
        self.title = title
        self.subtitle = subtitle
        self.state = state
        self.stepNumber = stepNumber
        self.isLast = isLast
        self.onTap = onTap
    }

    public var body: some View {
        Group {
            if let onTap {
                Button(action: {
                    #if os(iOS)
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.prepare()
                    generator.impactOccurred()
                    #endif
                    onTap()
                }) {
                    contentLayout
                }
                .buttonStyle(.plain)
                .craftPressEffect(scale: 0.98)
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
                    .frame(width: 36, height: 36)

                if !isLast {
                    connectorView
                        .frame(width: 2)
                        .frame(minHeight: 24)
                }
            }
            .frame(width: 36)

            // Text Information Column
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(title)
                    .font(theme.typography.headline)
                    .foregroundColor(titleColor)
                    .frame(minHeight: 36, alignment: .leading)

                if let subtitle {
                    Text(subtitle)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(subtitleColor)
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
                Circle()
                    .fill(theme.colors.statusSuccess)
                    .frame(width: 28, height: 28)
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

            case .active:
                // Glowing outer ring
                Circle()
                    .stroke(theme.colors.brandPrimary.opacity(0.3), lineWidth: 4)
                    .frame(width: 36, height: 36)

                // Inner filled badge
                Circle()
                    .fill(theme.colors.brandPrimary)
                    .frame(width: 26, height: 26)

                if let stepNumber {
                    Text("\(stepNumber)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                }

            case .locked:
                Circle()
                    .fill(theme.colors.surfaceSubtle)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .strokeBorder(theme.colors.borderDefault, lineWidth: 1.5)
                    )
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.colors.textMuted)

            case .upcoming:
                Circle()
                    .fill(theme.colors.surfaceSubtle)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .strokeBorder(theme.colors.borderDefault, lineWidth: 1.5)
                    )
                if let stepNumber {
                    Text("\(stepNumber)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.colors.textSecondary)
                } else {
                    Circle()
                        .fill(theme.colors.textMuted)
                        .frame(width: 8, height: 8)
                }
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
        var label = title
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
