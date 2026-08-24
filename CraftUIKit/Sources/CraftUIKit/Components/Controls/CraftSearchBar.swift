import SwiftUI

// MARK: - SearchBar Enums

/// Visual style variants for CraftSearchBar.
public enum CraftSearchBarStyle: String, Sendable, CaseIterable {
    case standard
    case recessed
    case glass
}

/// Border geometry shape for CraftSearchBar.
public enum CraftSearchBarShape: Sendable, Equatable {
    case capsule
    case roundedRectangle(radius: CGFloat)
}

// MARK: - Backing Shape

private struct CraftSearchBarBackingShape: Shape {
    let shape: CraftSearchBarShape

    func path(in rect: CGRect) -> Path {
        switch shape {
        case .capsule:
            return Capsule().path(in: rect)
        case .roundedRectangle(let radius):
            return RoundedRectangle(cornerRadius: radius).path(in: rect)
        }
    }
}

// MARK: - CraftSearchBar Component

/// A pill or rounded search input bar with focus glow, clear action button, and optional trailing actions.
public struct CraftSearchBar: View {
    @Environment(\.craftTheme) private var theme
    @FocusState private var isFocused: Bool

    public var text: Binding<String>
    private let placeholderKey: LocalizedStringKey?
    private let rawPlaceholder: String?
    public let style: CraftSearchBarStyle
    public let shape: CraftSearchBarShape
    public let trailingIcon: String?
    public let trailingAction: (() -> Void)?
    public let onCancel: (() -> Void)?
    public let onSubmit: (() -> Void)?

    public var placeholder: String {
        rawPlaceholder ?? "Search..."
    }

    public init(
        text: Binding<String>,
        placeholder: String = "Search...",
        style: CraftSearchBarStyle = .standard,
        shape: CraftSearchBarShape = .capsule,
        trailingIcon: String? = nil,
        trailingAction: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self.text = text
        self.placeholderKey = nil
        self.rawPlaceholder = placeholder
        self.style = style
        self.shape = shape
        self.trailingIcon = trailingIcon
        self.trailingAction = trailingAction
        self.onCancel = onCancel
        self.onSubmit = onSubmit
    }

    public init(
        text: Binding<String>,
        placeholder: LocalizedStringKey,
        style: CraftSearchBarStyle = .standard,
        shape: CraftSearchBarShape = .capsule,
        trailingIcon: String? = nil,
        trailingAction: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self.text = text
        self.placeholderKey = placeholder
        self.rawPlaceholder = nil
        self.style = style
        self.shape = shape
        self.trailingIcon = trailingIcon
        self.trailingAction = trailingAction
        self.onCancel = onCancel
        self.onSubmit = onSubmit
    }

    public var body: some View {
        HStack(spacing: theme.spacing.sm) {
            // Search Input Pill
            HStack(spacing: theme.spacing.sm) {
                CraftIcon(
                    .search,
                    size: .md,
                    color: isFocused ? theme.colors.borderFocus : theme.colors.textMuted
                )

                if let placeholderKey {
                    TextField(placeholderKey, text: text)
                        .font(theme.typography.bodyMedium)
                        .foregroundStyle(theme.colors.textPrimary)
                        .focused($isFocused)
                        .onSubmit {
                            onSubmit?()
                        }
                } else {
                    TextField(placeholder, text: text)
                        .font(theme.typography.bodyMedium)
                        .foregroundStyle(theme.colors.textPrimary)
                        .focused($isFocused)
                        .onSubmit {
                            onSubmit?()
                        }
                }

                if !text.wrappedValue.isEmpty {
                    Button(action: {
                        text.wrappedValue = ""
                    }) {
                        CraftIcon(.wrongCircle, size: .sm, color: theme.colors.textMuted)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(CraftLocalized.string("craft.search.clearA11y"))
                }

                if let trailingIcon, let trailingAction {
                    Button(action: trailingAction) {
                        CraftIcon(trailingIcon, size: .sm, color: isFocused ? theme.colors.brandPrimary : theme.colors.textMuted)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Trailing action")
                }
            }
            .padding(.horizontal, theme.spacing.base)
            .frame(minHeight: 44)
            .background(backgroundView)
            .clipShape(searchShape)
            .overlay(borderOverlay)
            .shadow(
                color: isFocused ? theme.colors.borderFocus.opacity(style == .recessed ? 0.25 : 0.12) : (style == .glass ? Color.black.opacity(0.04) : Color.clear),
                radius: style == .recessed ? 6 : 4,
                x: 0,
                y: 0
            )
            .animation(theme.animations.springSnappy, value: isFocused)

            // Cancel Button
            if isFocused && onCancel != nil {
                Button(action: {
                    isFocused = false
                    onCancel?()
                }) {
                    Text(CraftLocalized.string("craft.action.cancel"))
                        .font(theme.typography.bodyMedium)
                        .foregroundStyle(theme.colors.brandPrimary)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(theme.animations.springSnappy, value: isFocused)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .standard:
            theme.colors.surfaceSubtle
        case .recessed:
            ZStack {
                theme.colors.surfaceSubtle.opacity(0.6)
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.2),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        case .glass:
            ZStack {
                searchShape.fill(.ultraThinMaterial)
                searchShape.fill(theme.colors.surfaceCard.opacity(theme.glass.tintOpacity))
            }
        }
    }

    private var searchShape: CraftSearchBarBackingShape {
        CraftSearchBarBackingShape(shape: shape)
    }

    @ViewBuilder
    private var borderOverlay: some View {
        let strokeWidth: CGFloat = isFocused ? 1.5 : 1.0

        if isFocused {
            shapeStroke(color: theme.colors.borderFocus, width: strokeWidth)
        } else {
            switch style {
            case .standard:
                shapeStroke(color: theme.colors.borderDefault, width: strokeWidth)
            case .recessed:
                shapeStroke(color: theme.colors.hairline, width: strokeWidth)
            case .glass:
                shapeStroke(gradient: theme.glass.borderGradient, width: strokeWidth)
            }
        }
    }

    @ViewBuilder
    private func shapeStroke(color: Color, width: CGFloat) -> some View {
        switch shape {
        case .capsule:
            Capsule().strokeBorder(color, lineWidth: width)
        case .roundedRectangle(let radius):
            RoundedRectangle(cornerRadius: radius).strokeBorder(color, lineWidth: width)
        }
    }

    @ViewBuilder
    private func shapeStroke(gradient: LinearGradient, width: CGFloat) -> some View {
        switch shape {
        case .capsule:
            Capsule().strokeBorder(gradient, lineWidth: width)
        case .roundedRectangle(let radius):
            RoundedRectangle(cornerRadius: radius).strokeBorder(gradient, lineWidth: width)
        }
    }
}

#Preview("CraftSearchBar") {
    @Previewable @State var emptyText = ""
    @Previewable @State var filledText = "SwiftUI"
    
    return ScrollView {
        VStack(spacing: 24) {
            CraftSearchBar(
                text: $emptyText,
                placeholder: "Search vocabulary..."
            )
            
            CraftSearchBar(
                text: $filledText,
                onCancel: { filledText = "" }
            )
        }
        .padding()
    }
}
