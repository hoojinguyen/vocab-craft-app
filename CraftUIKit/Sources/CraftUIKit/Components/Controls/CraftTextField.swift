import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - CraftTextField Component

/// A refined, accessible text input field supporting focus glow, error states, helper text, and icon slots.
public struct CraftTextField: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    @FocusState private var isFocused: Bool
    @State private var isPasswordVisible: Bool = false

    public let placeholder: String
    public var text: Binding<String>
    public let label: String?
    public let helperText: String?
    public let errorMessage: String?
    public let leadingIcon: String?
    public let isSecure: Bool
    public let showClearButton: Bool

    /// Indicates whether the text field is in an error state.
    public var hasError: Bool {
        if let errorMessage, !errorMessage.isEmpty {
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
        self.placeholder = placeholder
        self.text = text
        self.label = label
        self.helperText = helperText
        self.errorMessage = errorMessage
        self.leadingIcon = leadingIcon
        self.isSecure = isSecure
        self.showClearButton = showClearButton
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            // Optional Label
            if let label, !label.isEmpty {
                Text(label)
                    .font(theme.typography.label)
                    .foregroundColor(theme.colors.textSecondary)
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
                        SecureField(placeholder, text: text)
                    } else {
                        TextField(placeholder, text: text)
                    }
                }
                .font(theme.typography.bodyLarge)
                .foregroundColor(theme.colors.textPrimary)
                .focused($isFocused)

                // Trailing Actions (Password Visibility / Clear Button)
                if isSecure {
                    Button(action: {
                        #if os(iOS)
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                        #endif
                        isPasswordVisible.toggle()
                    }) {
                        CraftIcon(
                            isPasswordVisible ? "eye.slash.fill" : "eye.fill",
                            size: .md,
                            color: theme.colors.textMuted
                        )
                    }
                    .buttonStyle(.plain)
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
            if let errorMessage, hasError {
                HStack(spacing: theme.spacing.xs) {
                    CraftIcon("exclamationmark.circle.fill", size: .sm, color: theme.colors.statusDanger)
                    Text(errorMessage)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.statusDanger)
                }
                .transition(.opacity)
            } else if let helperText, !helperText.isEmpty {
                Text(helperText)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textMuted)
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
