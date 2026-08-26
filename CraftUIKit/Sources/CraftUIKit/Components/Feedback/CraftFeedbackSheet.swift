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

    private var semanticTint: Color {
        switch status {
        case .success:
            return .craftDynamic(light: theme.colors.statusSuccess.opacity(0.16), dark: theme.colors.statusSuccess.opacity(0.24))
        case .error:
            return .craftDynamic(light: theme.colors.statusDanger.opacity(0.12), dark: theme.colors.statusDanger.opacity(0.22))
        case .warning:
            return .craftDynamic(light: theme.colors.statusWarning.opacity(0.14), dark: theme.colors.statusWarning.opacity(0.22))
        case .info:
            return .craftDynamic(light: theme.colors.statusInfo.opacity(0.12), dark: theme.colors.statusInfo.opacity(0.20))
        }
    }

    public var accessibilityDescription: String {
        if let message {
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

        let sheetContent = VStack(alignment: .leading, spacing: theme.spacing.base) {
            // Header row: Status Pill Badge + Secondary Action Button
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

        if resolvedSurfaceStyle == .tactile3D {
            sheetContent
                .background {
                    ZStack {
                        sheetShape.fill(theme.colors.borderDefault)
                        sheetShape.fill(statusColor.opacity(0.35))
                    }
                    .offset(y: theme.depths.depthMd)
                }
                .padding(.bottom, theme.depths.depthMd)
        } else {
            sheetContent
        }
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack(alignment: .center, spacing: theme.spacing.sm) {
            statusBadge

            Spacer(minLength: theme.spacing.xs)

            if let secondaryActionTitle, let onSecondaryAction {
                CraftButton(
                    secondaryActionTitle,
                    variant: (resolvedSurfaceStyle == .tactile3D ? .tactile : .primary),
                    size: .sm,
                    style: resolvedSurfaceStyle,
                    customTint: statusColor,
                    action: onSecondaryAction
                )
            }
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            CraftIcon(
                status.iconName,
                size: .sm,
                color: statusColor
            )

            Text(resolvedTitle)
                .font(theme.typography.label)
                .fontWeight(.bold)
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .craftSurface(
            style: resolvedSurfaceStyle,
            shape: Capsule(),
            customTint: statusBadgeTint
        )
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
            content.craftShadow(theme.shadows.xl)
        case .glass:
            content.craftShadow(theme.shadows.md)
        case .flat, .outlined, .tactile3D:
            content
        }
    }
}

// MARK: - Feedback Sheet View Modifier

/// A ViewModifier that presents a docked `CraftFeedbackSheet` anchored to the bottom edge
/// when `isPresented` is true, using a smooth spring animation and slide-up transition.
public struct CraftFeedbackSheetModifier<ExtraContent: View>: ViewModifier {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding public var isPresented: Bool

    public let status: CraftFeedbackStatus
    public let title: String?
    public let message: String?
    public let actionTitle: String?
    public let secondaryActionTitle: String?
    public let surfaceStyle: CraftSurfaceStyle?
    public let onSecondaryAction: (() -> Void)?
    public let onContinue: () -> Void
    public let extraContent: ExtraContent

    public init(
        isPresented: Binding<Bool>,
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
        self._isPresented = isPresented
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

    public func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                VStack {
                    Spacer()
                    CraftFeedbackSheet(
                        status: status,
                        title: title,
                        message: message,
                        actionTitle: actionTitle,
                        secondaryActionTitle: secondaryActionTitle,
                        surfaceStyle: surfaceStyle,
                        onSecondaryAction: onSecondaryAction,
                        onContinue: onContinue,
                        extraContent: { extraContent }
                    )
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1000)
            }
        }
        .animation(reduceMotion ? .default : theme.animations.springSmooth, value: isPresented)
    }
}

public extension CraftFeedbackSheetModifier where ExtraContent == EmptyView {
    init(
        isPresented: Binding<Bool>,
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
            isPresented: isPresented,
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

// MARK: - View Extension

public extension View {
    /// Presents a docked feedback sheet anchored to the bottom edge when `isPresented` is true.
    func craftFeedbackSheet<ExtraContent: View>(
        isPresented: Binding<Bool>,
        status: CraftFeedbackStatus,
        title: String? = nil,
        message: String? = nil,
        actionTitle: String? = nil,
        secondaryActionTitle: String? = nil,
        surfaceStyle: CraftSurfaceStyle? = nil,
        onSecondaryAction: (() -> Void)? = nil,
        onContinue: @escaping () -> Void,
        @ViewBuilder extraContent: () -> ExtraContent
    ) -> some View {
        modifier(
            CraftFeedbackSheetModifier(
                isPresented: isPresented,
                status: status,
                title: title,
                message: message,
                actionTitle: actionTitle,
                secondaryActionTitle: secondaryActionTitle,
                surfaceStyle: surfaceStyle,
                onSecondaryAction: onSecondaryAction,
                onContinue: onContinue,
                extraContent: extraContent
            )
        )
    }

    /// Presents a docked feedback sheet anchored to the bottom edge when `isPresented` is true, without extra content.
    func craftFeedbackSheet(
        isPresented: Binding<Bool>,
        status: CraftFeedbackStatus,
        title: String? = nil,
        message: String? = nil,
        actionTitle: String? = nil,
        secondaryActionTitle: String? = nil,
        surfaceStyle: CraftSurfaceStyle? = nil,
        onSecondaryAction: (() -> Void)? = nil,
        onContinue: @escaping () -> Void
    ) -> some View {
        craftFeedbackSheet(
            isPresented: isPresented,
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
