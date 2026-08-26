import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - CraftFeedbackStatus

/// Semantic status for assessment feedback sheets.
public enum CraftFeedbackStatus: String, Sendable, CaseIterable {
    case success
    case error
    case warning
    case info

    /// SF Symbol icon representation for the feedback state.
    public var iconName: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

// MARK: - CraftFeedbackSheet Component

/// A modal feedback bottom sheet presented after an answer or assessment submission,
/// featuring semantic status coloring, tactile action buttons, dynamic surface styles,
/// and optional custom auxiliary content.
public struct CraftFeedbackSheet<ExtraContent: View>: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.craftSurfaceStyle) private var environmentSurfaceStyle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let status: CraftFeedbackStatus
    public let title: String?
    public let message: String?
    public let actionTitle: String?
    public let secondaryActionTitle: String?
    public let surfaceStyle: CraftSurfaceStyle?
    public let onSecondaryAction: (() -> Void)?
    public let onContinue: () -> Void
    public let extraContent: ExtraContent

    // MARK: - Initializers

    public init(
        status: CraftFeedbackStatus,
        title: String? = nil,
        message: String? = nil,
        actionTitle: String? = nil,
        secondaryActionTitle: String? = nil,
        surfaceStyle: CraftSurfaceStyle? = nil,
        onSecondaryAction: (() -> Void)? = nil,
        onContinue: @escaping () -> Void,
        @ViewBuilder extraContent: () -> ExtraContent
    ) {
        self.status = status
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.secondaryActionTitle = secondaryActionTitle
        self.surfaceStyle = surfaceStyle
        self.onSecondaryAction = onSecondaryAction
        self.onContinue = onContinue
        self.extraContent = extraContent()
    }

    // MARK: - Computed Properties

    /// Resolved title falling back to localized status title when none is explicitly provided.
    public var resolvedTitle: String {
        if let title, !title.isEmpty {
            return title
        }
        switch status {
        case .success:
            return CraftLocalized.string("craft.feedback.success_title")
        case .error:
            return CraftLocalized.string("craft.feedback.error_title")
        case .warning:
            return CraftLocalized.string("craft.feedback.warning_title")
        case .info:
            return CraftLocalized.string("craft.feedback.info_title")
        }
    }

    /// Resolved action title falling back to localized continue action key.
    public var resolvedActionTitle: String {
        if let actionTitle, !actionTitle.isEmpty {
            return actionTitle
        }
        return CraftLocalized.string("craft.feedback.continue_action")
    }

    private var resolvedSurfaceStyle: CraftSurfaceStyle {
        surfaceStyle ?? environmentSurfaceStyle
    }

    private var statusColor: Color {
        switch status {
        case .success:
            return theme.colors.statusSuccess
        case .error:
            return theme.colors.statusDanger
        case .warning:
            return theme.colors.statusWarning
        case .info:
            return theme.colors.statusInfo
        }
    }

    // MARK: - Body

    public var body: some View {
        let sheetShape = UnevenRoundedRectangle(
            topLeadingRadius: theme.radii.xl,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: theme.radii.xl
        )

        VStack(alignment: .leading, spacing: theme.spacing.base) {
            // Drag indicator handle
            Capsule()
                .fill(theme.colors.borderDefault.opacity(0.6))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, theme.spacing.xs)
                .accessibilityHidden(true)

            // Header row: Status Icon + Title + Secondary Action Button
            headerRow

            // Message row (if provided)
            if let message, !message.isEmpty {
                CraftText(
                    message,
                    style: .bodyLarge,
                    color: theme.colors.textPrimary,
                    textAlignment: .leading
                )
                .fixedSize(horizontal: false, vertical: true)
            }

            // Optional extra content
            if !(ExtraContent.self == EmptyView.self) {
                extraContent
            }

            // Primary tactile progression button
            CraftButton(
                resolvedActionTitle,
                variant: .tactile,
                size: .lg,
                isFullWidth: true,
                customTint: statusColor,
                action: onContinue
            )
            .padding(.top, theme.spacing.xs)
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.bottom, theme.spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(surfaceBackground(shape: sheetShape))
        .clipShape(sheetShape)
        .overlay(surfaceBorder(shape: sheetShape))
        .modifier(FeedbackSheetShadowModifier(style: resolvedSurfaceStyle, theme: theme))
        .accessibilityElement(children: .contain)
        .task {
            triggerFeedbackHaptics()
        }
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack(alignment: .center, spacing: theme.spacing.sm) {
            CraftIcon(status.iconName, size: .lg, color: statusColor)

            CraftText(
                resolvedTitle,
                style: .titleMedium,
                color: statusColor
            )

            Spacer(minLength: theme.spacing.xs)

            if let secondaryActionTitle, let onSecondaryAction {
                CraftButton(
                    secondaryActionTitle,
                    variant: .ghost,
                    size: .sm,
                    customTint: statusColor,
                    action: onSecondaryAction
                )
            }
        }
    }

    // MARK: - Surface Background & Border

    @ViewBuilder
    private func surfaceBackground(shape: UnevenRoundedRectangle) -> some View {
        switch resolvedSurfaceStyle {
        case .glass:
            ZStack {
                shape.fill(.ultraThinMaterial)
                shape.fill(theme.colors.surfaceCard.opacity(theme.glass.tintOpacity))
            }
        case .outlined, .tactile3D:
            shape.fill(theme.colors.surfaceCard)
        case .elevated:
            shape.fill(theme.colors.surfaceElevated)
        case .flat:
            shape.fill(theme.colors.surfaceSubtle)
        }
    }

    @ViewBuilder
    private func surfaceBorder(shape: UnevenRoundedRectangle) -> some View {
        switch resolvedSurfaceStyle {
        case .glass:
            ZStack {
                shape.strokeBorder(theme.glass.borderGradient, lineWidth: 1)
                shape.strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
            }
        case .outlined:
            shape.strokeBorder(theme.colors.borderDefault, lineWidth: 1)
        case .elevated:
            shape.strokeBorder(
                LinearGradient(
                    stops: [
                        .init(color: .craftDynamic(light: Color.white.opacity(0.8), dark: Color.white.opacity(0.18)), location: 0.0),
                        .init(color: theme.colors.borderDefault.opacity(0.4), location: 0.5),
                        .init(color: theme.colors.hairline, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1
            )
        case .tactile3D:
            shape.strokeBorder(
                LinearGradient(
                    stops: [
                        .init(color: .craftDynamic(light: Color.white.opacity(0.75), dark: Color.white.opacity(0.20)), location: 0.0),
                        .init(color: theme.colors.borderDefault.opacity(0.6), location: 0.4),
                        .init(color: theme.colors.borderDefault, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1
            )
        case .flat:
            EmptyView()
        }
    }

    // MARK: - Sensory Haptics

    @MainActor
    private func triggerFeedbackHaptics() {
        #if os(iOS)
        switch status {
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
        case .info:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        }
        #endif
    }
}

// MARK: - Convenience Init for Empty ExtraContent

public extension CraftFeedbackSheet where ExtraContent == EmptyView {
    init(
        status: CraftFeedbackStatus,
        title: String? = nil,
        message: String? = nil,
        actionTitle: String? = nil,
        secondaryActionTitle: String? = nil,
        surfaceStyle: CraftSurfaceStyle? = nil,
        onSecondaryAction: (() -> Void)? = nil,
        onContinue: @escaping () -> Void
    ) {
        self.init(
            status: status,
            title: title,
            message: message,
            actionTitle: actionTitle,
            secondaryActionTitle: secondaryActionTitle,
            surfaceStyle: surfaceStyle,
            onSecondaryAction: onSecondaryAction,
            onContinue: onContinue,
            extraContent: { EmptyView() }
        )
    }
}

// MARK: - Shadow ViewModifier

private struct FeedbackSheetShadowModifier: ViewModifier {
    let style: CraftSurfaceStyle
    let theme: CraftTheme

    func body(content: Content) -> some View {
        switch style {
        case .elevated:
            content.craftShadow(theme.shadows.lg)
        case .glass:
            content.craftShadow(theme.shadows.md)
        case .flat, .outlined, .tactile3D:
            content
        }
    }
}

// MARK: - Previews

#Preview("Feedback Sheets") {
    VStack(spacing: 24) {
        CraftFeedbackSheet(
            status: .success,
            title: "Correct!",
            message: "Great job! Keep the streak going.",
            onContinue: {}
        )

        CraftFeedbackSheet(
            status: .error,
            title: "Incorrect",
            message: "Correct answer: Phenomenon (/fəˈnɒmɪnən/)",
            secondaryActionTitle: "Explain",
            onSecondaryAction: {},
            onContinue: {}
        ) {
            HStack {
                CraftIcon("lightbulb.fill", size: .sm, color: .orange)
                Text("Hint: Remember the Greek root 'phainomenon'.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }
    .padding()
}
