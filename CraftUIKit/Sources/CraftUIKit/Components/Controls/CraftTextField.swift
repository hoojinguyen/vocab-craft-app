import SwiftUI

// MARK: - CraftTextField Component

/// A refined, accessible text input field supporting focus glow, error states, helper text, and icon slots.
public struct CraftTextField: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    @FocusState private var isFocused: Bool
    @State private var isPasswordVisible: Bool = false

    private let placeholderKey: LocalizedStringKey?
    private let rawPlaceholder: String?
    private let labelKey: LocalizedStringKey?
    private let rawLabel: String?
    private let helperTextKey: LocalizedStringKey?
    private let rawHelperText: String?
    private let errorMessageKey: LocalizedStringKey?
    private let rawErrorMessage: String?

    public var placeholder: String { rawPlaceholder ?? "" }
    public var text: Binding<String>
    public var label: String? { rawLabel }
    public var helperText: String? { rawHelperText }
    public var errorMessage: String? { rawErrorMessage }
    public let leadingIcon: String?
    public let isSecure: Bool
    public let showClearButton: Bool

    /// Indicates whether the text field is in an error state.
    public var hasError: Bool {
        if let rawErrorMessage, !rawErrorMessage.isEmpty {
            return true
        }
        if errorMessageKey != nil {
            return true
        }
        return false
    }

    public init(
        placeholder: String = "",
        text: Binding<String>,
        label: String? = nil,
        helperText: String? = nil,
        errorMessage: String? = nil,
        leadingIcon: String? = nil,
        isSecure: Bool = false,
        showClearButton: Bool = true
    ) {
        self.placeholderKey = nil
        self.rawPlaceholder = placeholder
        self.text = text
        self.labelKey = nil
        self.rawLabel = label
        self.helperTextKey = nil
        self.rawHelperText = helperText
        self.errorMessageKey = nil
        self.rawErrorMessage = errorMessage
        self.leadingIcon = leadingIcon
        self.isSecure = isSecure
        self.showClearButton = showClearButton
    }

    public init(
        _ placeholderKey: LocalizedStringKey,
        text: Binding<String>,
        label: LocalizedStringKey? = nil,
        helperText: LocalizedStringKey? = nil,
        errorMessage: LocalizedStringKey? = nil,
        leadingIcon: String? = nil,
        isSecure: Bool = false,
        showClearButton: Bool = true
    ) {
        self.placeholderKey = placeholderKey
        self.rawPlaceholder = nil
        self.text = text
        self.labelKey = label
        self.rawLabel = nil
        self.helperTextKey = helperText
        self.rawHelperText = nil
        self.errorMessageKey = errorMessage
        self.rawErrorMessage = nil
        self.leadingIcon = leadingIcon
        self.isSecure = isSecure
        self.showClearButton = showClearButton
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            // Optional Label
            if let labelKey {
                Text(labelKey)
                    .font(theme.typography.label)
                    .foregroundStyle(theme.colors.textSecondary)
            } else if let rawLabel, !rawLabel.isEmpty {
                Text(rawLabel)
                    .font(theme.typography.label)
                    .foregroundStyle(theme.colors.textSecondary)
            }

            // Input Field Container
            HStack(spacing: theme.spacing.sm) {
                // Leading Icon Slot
                if let leadingIcon {
                    CraftIcon(leadingIcon, size: .md, color: iconColor)
                }

                // Text Input
                Group {
                    if isSecure && !isPasswordVisible {
                        if let placeholderKey {
                            SecureField(placeholderKey, text: text)
                        } else {
                            SecureField(placeholder, text: text)
                        }
                    } else {
                        if let placeholderKey {
                            TextField(placeholderKey, text: text)
                        } else {
                            TextField(placeholder, text: text)
                        }
                    }
                }
                .font(theme.typography.bodyLarge)
                .foregroundStyle(theme.colors.textPrimary)
                .focused($isFocused)

                // Trailing Actions (Password Visibility / Clear Button)
                if isSecure {
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        CraftIcon(
                            isPasswordVisible ? "eye.slash.fill" : "eye.fill",
                            size: .md,
                            color: theme.colors.textMuted
                        )
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.selection, trigger: isPasswordVisible)
                    .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
                } else if showClearButton && !text.wrappedValue.isEmpty {
                    Button(action: {
                        text.wrappedValue = ""
                    }) {
                        CraftIcon("xmark.circle.fill", size: .sm, color: theme.colors.textMuted)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear text")
                }
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.xs)
            .frame(minHeight: 44)
            .background(theme.colors.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.md)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
            .shadow(
                color: isFocused ? theme.colors.borderFocus.opacity(0.12) : Color.clear,
                radius: 4,
                x: 0,
                y: 0
            )
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(theme.animations.springSnappy, value: isFocused)
            .animation(theme.animations.springSnappy, value: hasError)

            // Feedback: Error or Helper Text
            if let errorMessageKey, hasError {
                HStack(spacing: theme.spacing.xs) {
                    CraftIcon("exclamationmark.circle.fill", size: .sm, color: theme.colors.statusDanger)
                    Text(errorMessageKey)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.statusDanger)
                }
                .transition(.opacity)
            } else if let rawErrorMessage, hasError {
                HStack(spacing: theme.spacing.xs) {
                    CraftIcon("exclamationmark.circle.fill", size: .sm, color: theme.colors.statusDanger)
                    Text(rawErrorMessage)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.statusDanger)
                }
                .transition(.opacity)
            } else if let helperTextKey {
                Text(helperTextKey)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textMuted)
            } else if let rawHelperText, !rawHelperText.isEmpty {
                Text(rawHelperText)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textMuted)
            }
        }
    }

    private var iconColor: Color {
        if hasError {
            return theme.colors.statusDanger
        }
        if isFocused {
            return theme.colors.borderFocus
        }
        return theme.colors.textMuted
    }

    private var borderColor: Color {
        if hasError {
            return theme.colors.statusDanger
        }
        if isFocused {
            return theme.colors.borderFocus
        }
        return theme.colors.borderDefault
    }

    private var borderWidth: CGFloat {
        if hasError || isFocused {
            return 1.5
        }
        return 1.0
    }
}
