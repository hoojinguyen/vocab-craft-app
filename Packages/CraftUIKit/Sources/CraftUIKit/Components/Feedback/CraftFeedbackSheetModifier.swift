import SwiftUI

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
    public let streakCount: Int?
    public let style: CraftSurfaceStyle?
    public let onSecondaryAction: (() -> Void)?
    public let onContinue: () -> Void
    public let extraContent: ExtraContent

    /// Backwards compatibility alias for `style`.
    public var surfaceStyle: CraftSurfaceStyle? {
        style
    }

    public init(
        isPresented: Binding<Bool>,
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
        self._isPresented = isPresented
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

    /// Legacy initializer accepting `surfaceStyle:`.
    public init(
        isPresented: Binding<Bool>,
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
            isPresented: isPresented,
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
                        streakCount: streakCount,
                        style: style,
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
        streakCount: Int? = nil,
        style: CraftSurfaceStyle? = nil,
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
            streakCount: streakCount,
            style: style,
            onSecondaryAction: onSecondaryAction,
            onContinue: onContinue,
            extraContent: { EmptyView() }
        )
    }

    init(
        isPresented: Binding<Bool>,
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
            isPresented: isPresented,
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

// MARK: - View Extensions

public extension View {
    /// Presents a docked feedback sheet anchored to the bottom edge when `isPresented` is true.
    func craftFeedbackSheet<ExtraContent: View>(
        isPresented: Binding<Bool>,
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
    ) -> some View {
        modifier(
            CraftFeedbackSheetModifier(
                isPresented: isPresented,
                status: status,
                title: title,
                message: message,
                actionTitle: actionTitle,
                secondaryActionTitle: secondaryActionTitle,
                streakCount: streakCount,
                style: style,
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
        streakCount: Int? = nil,
        style: CraftSurfaceStyle? = nil,
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
            streakCount: streakCount,
            style: style,
            onSecondaryAction: onSecondaryAction,
            onContinue: onContinue,
            extraContent: { EmptyView() }
        )
    }

    /// Legacy view modifier accepting `surfaceStyle:`.
    func craftFeedbackSheet<ExtraContent: View>(
        isPresented: Binding<Bool>,
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
    ) -> some View {
        craftFeedbackSheet(
            isPresented: isPresented,
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

    /// Legacy view modifier without extra content, accepting `surfaceStyle:`.
    func craftFeedbackSheet(
        isPresented: Binding<Bool>,
        status: CraftFeedbackStatus,
        title: String? = nil,
        message: String? = nil,
        actionTitle: String? = nil,
        secondaryActionTitle: String? = nil,
        streakCount: Int? = nil,
        surfaceStyle: CraftSurfaceStyle?,
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
            streakCount: streakCount,
            style: surfaceStyle,
            onSecondaryAction: onSecondaryAction,
            onContinue: onContinue,
            extraContent: { EmptyView() }
        )
    }
}
