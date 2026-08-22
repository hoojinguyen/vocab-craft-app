import SwiftUI

// MARK: - SearchBar Enums

/// Visual style variants for CraftSearchBar.
public enum CraftSearchBarStyle: String, Sendable, CaseIterable {
    case standard
    case recessed
}

/// Border geometry shape for CraftSearchBar.
public enum CraftSearchBarShape: Sendable, Equatable {
    case capsule
    case roundedRectangle(radius: CGFloat)
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
                    .accessibilityLabel("Clear search")
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
                color: isFocused ? theme.colors.borderFocus.opacity(style == .recessed ? 0.25 : 0.12) : Color.clear,
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
                    Text("Cancel")
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
        }
    }

    private var searchShape: some Shape {
        switch shape {
        case .capsule:
            return AnyShape(Capsule())
        case .roundedRectangle(let radius):
            return AnyShape(RoundedRectangle(cornerRadius: radius))
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        let strokeColor = isFocused ? theme.colors.borderFocus : (style == .recessed ? theme.colors.hairline : theme.colors.borderDefault)
        let strokeWidth: CGFloat = isFocused ? 1.5 : 1.0

        switch shape {
        case .capsule:
            Capsule()
                .strokeBorder(strokeColor, lineWidth: strokeWidth)
        case .roundedRectangle(let radius):
            RoundedRectangle(cornerRadius: radius)
                .strokeBorder(strokeColor, lineWidth: strokeWidth)
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
