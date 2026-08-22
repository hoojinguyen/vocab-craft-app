import SwiftUI

// MARK: - CraftSearchBar Component

/// A pill-shaped search input bar with focus ring and clear action button.
public struct CraftSearchBar: View {
    @Environment(\.craftTheme) private var theme
    @FocusState private var isFocused: Bool

    public var text: Binding<String>
    private let placeholderKey: LocalizedStringKey?
    private let rawPlaceholder: String?
    public let onCancel: (() -> Void)?
    public let onSubmit: (() -> Void)?

    public var placeholder: String {
        rawPlaceholder ?? "Search..."
    }

    public init(
        text: Binding<String>,
        placeholder: String = "Search...",
        onCancel: (() -> Void)? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self.text = text
        self.placeholderKey = nil
        self.rawPlaceholder = placeholder
        self.onCancel = onCancel
        self.onSubmit = onSubmit
    }

    public init(
        text: Binding<String>,
        placeholder: LocalizedStringKey,
        onCancel: (() -> Void)? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self.text = text
        self.placeholderKey = placeholder
        self.rawPlaceholder = nil
        self.onCancel = onCancel
        self.onSubmit = onSubmit
    }

    public var body: some View {
        HStack(spacing: theme.spacing.sm) {
            // Search Input Pill
            HStack(spacing: theme.spacing.sm) {
                CraftIcon(
                    "magnifyingglass",
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
                        CraftIcon("xmark.circle.fill", size: .sm, color: theme.colors.textMuted)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, theme.spacing.base)
            .frame(minHeight: 44)
            .background(theme.colors.surfaceSubtle)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        isFocused ? theme.colors.borderFocus : theme.colors.borderDefault,
                        lineWidth: isFocused ? 1.5 : 1.0
                    )
            )
            .shadow(
                color: isFocused ? theme.colors.borderFocus.opacity(0.12) : Color.clear,
                radius: 4,
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
}
