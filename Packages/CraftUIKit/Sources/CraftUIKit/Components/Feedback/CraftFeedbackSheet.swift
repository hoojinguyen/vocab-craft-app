import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - CraftFeedbackSheet Component

/// A modal feedback bottom sheet presented after an answer or assessment submission,
/// featuring semantic status coloring, customizable surface style (`.glass`, `.tactile3D`, `.elevated`, `.outlined`, `.flat`),
/// non-competing auxiliary action hierarchy, accessible contrast, combo streak display, and optional custom extra content.
public struct CraftFeedbackSheet<ExtraContent: View>: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.craftSurfaceStyle) private var environmentSurfaceStyle

    public let status: CraftFeedbackStatus
    public let title: String?
    public let message: String?
    public let actionTitle: String?
    public let secondaryActionTitle: String?
    public let streakCount: Int?
    public let style: CraftSurfaceStyle?
    public let onSecondaryAction: (() -> Void)?
    public let onContinue: () -> Void
    public let extraContent: ExtraContent

    /// Backwards compatibility alias for `style`.
    public var surfaceStyle: CraftSurfaceStyle? {
        style
    }

    // MARK: - Initializers

    /// Primary initializer with direct `style` parameter.
    public init(
        status: CraftFeedbackStatus,
        title: String? = nil,
        message: String? = nil,
        actionTitle: String? = nil,
        secondaryActionTitle: String? = nil,
        streakCount: Int? = nil,
        style: CraftSurfaceStyle? = nil,
        onSecondaryAction: (() -> Void)? = nil,
        onContinue: @escaping () -> Void,
        @ViewBuilder extraContent: () -> ExtraContent
    ) {
        self.status = status
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.secondaryActionTitle = secondaryActionTitle
        self.streakCount = streakCount
        self.style = style
        self.onSecondaryAction = onSecondaryAction
        self.onContinue = onContinue
        self.extraContent = extraContent()
    }

    /// Convenience initializer supporting legacy `surfaceStyle:` parameter label.
    public init(
        status: CraftFeedbackStatus,
        title: String? = nil,
        message: String? = nil,
        actionTitle: String? = nil,
        secondaryActionTitle: String? = nil,
        streakCount: Int? = nil,
        surfaceStyle: CraftSurfaceStyle?,
        onSecondaryAction: (() -> Void)? = nil,
        onContinue: @escaping () -> Void,
        @ViewBuilder extraContent: () -> ExtraContent
    ) {
        self.init(
            status: status,
            title: title,
            message: message,
            actionTitle: actionTitle,
            secondaryActionTitle: secondaryActionTitle,
            streakCount: streakCount,
            style: surfaceStyle,
            onSecondaryAction: onSecondaryAction,
            onContinue: onContinue,
            extraContent: extraContent
        )
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

    public var resolvedSurfaceStyle: CraftSurfaceStyle {
        style ?? environmentSurfaceStyle
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

    private var semanticTint: Color {
        switch status {
        case .success:
            return .craftDynamic(
                light: theme.colors.statusSuccess.opacity(0.14),
                dark: theme.colors.statusSuccess.opacity(0.22)
            )
        case .error:
            return .craftDynamic(
                light: theme.colors.statusDanger.opacity(0.12),
                dark: theme.colors.statusDanger.opacity(0.20)
            )
        case .warning:
            return .craftDynamic(
                light: theme.colors.statusWarning.opacity(0.14),
                dark: theme.colors.statusWarning.opacity(0.20)
            )
        case .info:
            return .craftDynamic(
                light: theme.colors.statusInfo.opacity(0.12),
                dark: theme.colors.statusInfo.opacity(0.18)
            )
        }
    }

    public var accessibilityDescription: String {
        if let message, !message.isEmpty {
            return "\(resolvedTitle), \(message). Action: \(resolvedActionTitle)"
        } else {
            return "\(resolvedTitle). Action: \(resolvedActionTitle)"
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
            // Header row: Status Pill Badge + Streak Badge + Secondary Action Button
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

            // Optional extra content (inherits resolved surface style)
            if !(ExtraContent.self == EmptyView.self) {
                extraContent
            }

            // Primary progression button inheriting resolved surface style
            CraftButton(
                resolvedActionTitle,
                variant: (resolvedSurfaceStyle == .tactile3D ? .tactile : .primary),
                size: .lg,
                isFullWidth: true,
                style: resolvedSurfaceStyle,
                customTint: statusColor,
                action: onContinue
            )
            .padding(.top, theme.spacing.xs)
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.top, theme.spacing.base)
        .padding(.bottom, theme.spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .craftSurfaceStyle(resolvedSurfaceStyle)
        .background(surfaceBackground(shape: sheetShape))
        .clipShape(sheetShape)
        .overlay(surfaceBorder(shape: sheetShape))
        .modifier(FeedbackSheetShadowModifier(style: resolvedSurfaceStyle, theme: theme))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .task {
            triggerFeedbackHaptics()
        }
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack(alignment: .center, spacing: theme.spacing.sm) {
            statusTitleView

            if let streakCount, streakCount > 0 {
                CraftStreakBadge(
                    count: streakCount,
                    isCompletedToday: true,
                    size: .sm,
                    style: resolvedSurfaceStyle == .tactile3D ? .tactile3D : resolvedSurfaceStyle
                )
            }

            Spacer(minLength: theme.spacing.xs)

            if let secondaryActionTitle, let onSecondaryAction {
                secondaryActionButton(title: secondaryActionTitle, action: onSecondaryAction)
            }
        }
    }

    private var statusTitleView: some View {
        HStack(spacing: theme.spacing.xs) {
            CraftIcon(
                status.iconName,
                size: .md,
                color: statusColor
            )

            Text(resolvedTitle)
                .font(theme.typography.titleLarge)
                .fontWeight(.bold)
                .foregroundStyle(statusColor)
        }
    }

    @ViewBuilder
    private func secondaryActionButton(title: String, action: @escaping () -> Void) -> some View {
        switch resolvedSurfaceStyle {
        case .glass:
            CraftButton(
                title,
                variant: .secondary,
                size: .sm,
                style: .glass,
                customTint: statusColor,
                action: action
            )
        case .tactile3D:
            CraftButton(
                title,
                variant: .secondary,
                size: .sm,
                style: .tactile3D,
                customTint: statusColor,
                action: action
            )
        case .elevated:
            CraftButton(
                title,
                variant: .secondary,
                size: .sm,
                style: .elevated,
                customTint: statusColor,
                action: action
            )
        case .outlined:
            CraftButton(
                title,
                variant: .outline,
                size: .sm,
                style: .outlined,
                customTint: statusColor,
                action: action
            )
        case .flat:
            CraftButton(
                title,
                variant: .ghost,
                size: .sm,
                style: .flat,
                customTint: statusColor,
                action: action
            )
        }
    }

    private var statusBadgeTint: Color {
        switch resolvedSurfaceStyle {
        case .glass:
            return statusColor.opacity(theme.glass.tintOpacity)
        case .flat, .elevated, .outlined, .tactile3D:
            return .craftDynamic(
                light: statusColor.opacity(0.18),
                dark: statusColor.opacity(0.26)
            )
        }
    }

    // MARK: - Surface Background & Border

    @ViewBuilder
    private func surfaceBackground(shape: UnevenRoundedRectangle) -> some View {
        switch resolvedSurfaceStyle {
        case .glass:
            ZStack {
                shape.fill(.ultraThinMaterial)
                shape.fill(statusColor.opacity(theme.glass.tintOpacity))
            }
        case .outlined, .tactile3D:
            ZStack {
                shape.fill(theme.colors.surfaceCard)
                shape.fill(semanticTint)
            }
        case .elevated:
            ZStack {
                shape.fill(theme.colors.surfaceElevated)
                shape.fill(semanticTint)
            }
        case .flat:
            ZStack {
                shape.fill(theme.colors.surfaceSubtle)
                shape.fill(semanticTint)
            }
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
            shape.strokeBorder(theme.colors.borderDefault, lineWidth: 1.5)
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
                        .init(color: .craftDynamic(light: Color.white.opacity(0.85), dark: Color.white.opacity(0.25)), location: 0.0),
                        .init(color: statusColor.opacity(0.4), location: 0.35),
                        .init(color: theme.colors.borderDefault, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1.5
            )
        case .flat:
            EmptyView()
        }
    }

    // MARK: - Sensory Haptics

    @MainActor
    private func triggerFeedbackHaptics() {
        #if os(iOS) && !targetEnvironment(simulator)
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
    /// Initializer without extraContent, supporting direct `style:`.
    init(
        status: CraftFeedbackStatus,
        title: String? = nil,
        message: String? = nil,
        actionTitle: String? = nil,
        secondaryActionTitle: String? = nil,
        streakCount: Int? = nil,
        style: CraftSurfaceStyle? = nil,
        onSecondaryAction: (() -> Void)? = nil,
        onContinue: @escaping () -> Void
    ) {
        self.init(
            status: status,
            title: title,
            message: message,
            actionTitle: actionTitle,
            secondaryActionTitle: secondaryActionTitle,
            streakCount: streakCount,
            style: style,
            onSecondaryAction: onSecondaryAction,
            onContinue: onContinue,
            extraContent: { EmptyView() }
        )
    }

    /// Convenience initializer supporting legacy `surfaceStyle:` parameter name.
    init(
        status: CraftFeedbackStatus,
        title: String? = nil,
        message: String? = nil,
        actionTitle: String? = nil,
        secondaryActionTitle: String? = nil,
        streakCount: Int? = nil,
        surfaceStyle: CraftSurfaceStyle?,
        onSecondaryAction: (() -> Void)? = nil,
        onContinue: @escaping () -> Void
    ) {
        self.init(
            status: status,
            title: title,
            message: message,
            actionTitle: actionTitle,
            secondaryActionTitle: secondaryActionTitle,
            streakCount: streakCount,
            style: surfaceStyle,
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
            content.craftShadow(theme.shadows.xl)
        case .glass:
            content.craftShadow(theme.shadows.md)
        case .flat, .outlined, .tactile3D:
            content
        }
    }
}

// MARK: - Previews

#Preview("Feedback Sheets - All Styles") {
    ScrollView {
        VStack(spacing: 28) {
            // 1. Tactile 3D Success (Gamified with Streak)
            CraftFeedbackSheet(
                status: .success,
                title: "Chính xác!",
                message: "Great job! Keep the streak going.",
                streakCount: 5,
                style: .tactile3D,
                onContinue: {}
            )

            // 2. Liquid Glass Error with Hint (iOS 26+)
            CraftFeedbackSheet(
                status: .error,
                title: "Incorrect",
                message: "Correct answer: Phenomenon (/fəˈnɒmɪnən/)",
                secondaryActionTitle: "Explain",
                style: .glass,
                onSecondaryAction: {},
                onContinue: {}
            ) {
                CraftFeedbackHintCard("Hint: Remember the Greek root 'phainomenon'.")
            }

            // 3. Elevated Warning
            CraftFeedbackSheet(
                status: .warning,
                title: "Almost!",
                message: "Pay attention to the stress on the second syllable.",
                style: .elevated,
                onContinue: {}
            )

            // 4. Outlined Info
            CraftFeedbackSheet(
                status: .info,
                title: "Explanation",
                message: "'Phenomenon' is singular, 'phenomena' is plural.",
                style: .outlined,
                onContinue: {}
            )

            // 5. Flat Success
            CraftFeedbackSheet(
                status: .success,
                title: "Perfect Score!",
                message: "You completed all review words for today.",
                style: .flat,
                onContinue: {}
            )
        }
        .padding()
    }
}
