import SwiftUI

// MARK: - Toast Enums & Models

/// Visual styles for toast notifications.
public enum CraftToastStyle: String, Sendable, CaseIterable {
    case info
    case success
    case warning
    case danger

    public var defaultSymbol: CraftSymbol {
        switch self {
        case .info: return .info
        case .success: return .checkmarkCircle
        case .warning: return .warning
        case .danger: return .wrongCircle
        }
    }

    public var defaultIconName: String {
        defaultSymbol.rawValue
    }
}

/// Screen placement for toast notifications.
public enum CraftToastPosition: Sendable, CaseIterable {
    case top
    case bottom
}

/// Model encapsulating toast notification data.
public struct CraftToastData: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let title: String?
    public let message: String
    public let iconName: String?
    public let style: CraftToastStyle
    public let duration: TimeInterval

    public init(
        id: UUID = UUID(),
        title: String? = nil,
        message: String,
        iconName: String? = nil,
        style: CraftToastStyle = .info,
        duration: TimeInterval = 3.0
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.iconName = iconName
        self.style = style
        self.duration = duration
    }
}

// MARK: - CraftToast Component

/// A standalone HUD toast view displaying an icon, title, and message.
public struct CraftToast: View {
    @Environment(\.craftTheme) private var theme

    public let title: String?
    public let message: String
    public let iconName: String?
    public let style: CraftToastStyle
    public let onDismiss: (() -> Void)?

    public init(
        message: String,
        title: String? = nil,
        iconName: String? = nil,
        style: CraftToastStyle = .info,
        onDismiss: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.iconName = iconName
        self.style = style
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(spacing: theme.spacing.sm) {
            let icon = iconName ?? style.defaultIconName
            CraftIcon(icon, size: .md, color: statusColor)

            VStack(alignment: .leading, spacing: 2) {
                if let title, !title.isEmpty {
                    CraftText(title, style: .headline, color: theme.colors.textPrimary)
                }
                CraftText(message, style: .bodyMedium, color: theme.colors.textSecondary)
            }

            Spacer(minLength: theme.spacing.xs)

            if let onDismiss {
                Button(action: onDismiss) {
                    CraftIcon(.close, size: .sm, color: theme.colors.textMuted)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Dismiss")
                .frame(minWidth: 44, minHeight: 44)
            }
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.vertical, theme.spacing.sm)
        .background(theme.colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.lg)
                .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
        )
        .craftShadow(theme.shadows.lg)
        .padding(.horizontal, theme.spacing.base)
    }

    private var statusColor: Color {
        switch style {
        case .info: return theme.colors.statusInfo
        case .success: return theme.colors.statusSuccess
        case .warning: return theme.colors.statusWarning
        case .danger: return theme.colors.statusDanger
        }
    }
}

// MARK: - Toast View Modifier

public struct CraftToastModifier: ViewModifier {
    @Environment(\.craftTheme) private var theme
    @Binding public var isPresented: Bool
    public let data: CraftToastData
    public let position: CraftToastPosition

    public func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                VStack {
                    if position == .bottom {
                        Spacer()
                    }

                    CraftToast(
                        message: data.message,
                        title: data.title,
                        iconName: data.iconName,
                        style: data.style,
                        onDismiss: {
                            withAnimation(theme.animations.springSmooth) {
                                isPresented = false
                            }
                        }
                    )
                    .transition(
                        .move(edge: position == .top ? .top : .bottom)
                        .combined(with: .opacity)
                    )

                    if position == .top {
                        Spacer()
                    }
                }
                .padding(position == .top ? .top : .bottom, theme.spacing.sm)
                .zIndex(9999)
                .task(id: "\(isPresented)-\(data.id)") {
                    if isPresented {
                        try? await Task.sleep(nanoseconds: UInt64(data.duration * 1_000_000_000))
                        withAnimation(theme.animations.springSmooth) {
                            isPresented = false
                        }
                    }
                }
            }
        }
        .animation(theme.animations.springSmooth, value: isPresented)
    }
}

// MARK: - View Extension

public extension View {
    /// Presents a HUD toast message over this view with spring animations and auto-dismiss timer.
    func craftToast(
        isPresented: Binding<Bool>,
        toast: CraftToastData,
        position: CraftToastPosition = .top
    ) -> some View {
        modifier(CraftToastModifier(isPresented: isPresented, data: toast, position: position))
    }

    /// Convenience modifier to present a toast directly with string message and parameters.
    func craftToast(
        isPresented: Binding<Bool>,
        message: String,
        title: String? = nil,
        iconName: String? = nil,
        style: CraftToastStyle = .info,
        duration: TimeInterval = 3.0,
        position: CraftToastPosition = .top
    ) -> some View {
        let data = CraftToastData(
            title: title,
            message: message,
            iconName: iconName,
            style: style,
            duration: duration
        )
        return craftToast(isPresented: isPresented, toast: data, position: position)
    }

    /// Presents a toast bound to an optional identifiable item.
    func craftToast(
        item: Binding<CraftToastData?>,
        position: CraftToastPosition = .top
    ) -> some View {
        let isPresented = Binding<Bool>(
            get: { item.wrappedValue != nil },
            set: { if !$0 { item.wrappedValue = nil } }
        )
        let data = item.wrappedValue ?? CraftToastData(message: "")
        return modifier(CraftToastModifier(isPresented: isPresented, data: data, position: position))
    }
}

#Preview("CraftToast") {
    @Previewable @State var showInfo = false
    @Previewable @State var showSuccess = false
    
    return ScrollView {
        VStack(spacing: 24) {
            Button("Show Info Toast") { showInfo = true }
            Button("Show Success Toast") { showSuccess = true }
            
            Divider()
            
            CraftToast(message: "Static preview warning", title: "Warning", style: .warning)
            CraftToast(message: "Static preview danger", style: .danger)
        }
        .padding()
    }
    .craftToast(
        isPresented: $showInfo,
        message: "This is an info toast",
        style: .info
    )
    .craftToast(
        isPresented: $showSuccess,
        message: "Action completed successfully!",
        style: .success,
        position: .bottom
    )
}
