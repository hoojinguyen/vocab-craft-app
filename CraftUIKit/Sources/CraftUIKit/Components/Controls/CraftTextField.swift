import SwiftUI

// MARK: - TextField Style

/// Visual style variants for `CraftTextField`.
public enum CraftTextFieldStyle: String, Sendable, Equatable, CaseIterable {
    case standard
    case recessed
    case underlined
    case glass
}

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
    public let style: CraftTextFieldStyle

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
        showClearButton: Bool = true,
        style: CraftTextFieldStyle = .standard
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
        self.style = style
    }

    public init(
        _ placeholderKey: LocalizedStringKey,
        text: Binding<String>,
        label: LocalizedStringKey? = nil,
        helperText: LocalizedStringKey? = nil,
        errorMessage: LocalizedStringKey? = nil,
        leadingIcon: String? = nil,
        isSecure: Bool = false,
        showClearButton: Bool = true,
        style: CraftTextFieldStyle = .standard
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
        self.style = style
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
                            isPasswordVisible ? CraftSymbol.eyeSlash.rawValue : CraftSymbol.eye.rawValue,
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
                        CraftIcon(.wrongCircle, size: .sm, color: theme.colors.textMuted)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(CraftLocalized.string("craft.search.clearA11y"))
                }
            }
            .padding(.horizontal, style == .underlined ? 0 : theme.spacing.md)
            .padding(.vertical, theme.spacing.xs)
            .frame(minHeight: 44)
            .background(inputBackground)
            .clipShape(inputClipShape)
            .overlay(inputBorderOverlay)
            .shadow(
                color: isFocused ? theme.colors.borderFocus.opacity(style == .recessed ? 0.25 : 0.12) : Color.clear,
                radius: style == .recessed ? 6 : 4,
                x: 0,
                y: 0
            )
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(theme.animations.springSnappy, value: isFocused)
            .animation(theme.animations.springSnappy, value: hasError)

            // Feedback: Error or Helper Text
            if let errorMessageKey, hasError {
                HStack(spacing: theme.spacing.xs) {
                    CraftIcon(.danger, size: .sm, color: theme.colors.statusDanger)
                    Text(errorMessageKey)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.statusDanger)
                }
                .transition(.opacity)
            } else if let rawErrorMessage, hasError {
                HStack(spacing: theme.spacing.xs) {
                    CraftIcon(.danger, size: .sm, color: theme.colors.statusDanger)
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

    @ViewBuilder
    private var inputBackground: some View {
        switch style {
        case .standard:
            theme.colors.surfaceCard
        case .recessed:
            ZStack {
                theme.colors.surfaceSubtle.opacity(0.6)
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.15),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        case .underlined:
            Color.clear
        case .glass:
            ZStack {
                RoundedRectangle(cornerRadius: theme.radii.md)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: theme.radii.md)
                    .fill(theme.colors.surfaceCard.opacity(theme.glass.tintOpacity))
            }
        }
    }

    private var inputClipShape: some Shape {
        if style == .underlined {
            return AnyShape(Rectangle())
        } else {
            return AnyShape(RoundedRectangle(cornerRadius: theme.radii.md))
        }
    }

    @ViewBuilder
    private var inputBorderOverlay: some View {
        if style == .underlined {
            VStack {
                Spacer()
                Rectangle()
                    .fill(borderColor)
                    .frame(height: borderWidth)
            }
        } else if style == .glass {
            if isFocused {
                RoundedRectangle(cornerRadius: theme.radii.md)
                    .strokeBorder(theme.colors.borderFocus, lineWidth: borderWidth)
            } else {
                RoundedRectangle(cornerRadius: theme.radii.md)
                    .strokeBorder(theme.glass.borderGradient, lineWidth: borderWidth)
            }
        } else if style == .recessed {
            RoundedRectangle(cornerRadius: theme.radii.md)
                .strokeBorder(isFocused ? theme.colors.borderFocus : theme.colors.hairline, lineWidth: borderWidth)
        } else {
            RoundedRectangle(cornerRadius: theme.radii.md)
                .strokeBorder(borderColor, lineWidth: borderWidth)
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

#Preview("CraftTextField") {
    @Previewable @State var text1 = ""
    @Previewable @State var text2 = "user@example.com"
    @Previewable @State var text3 = "wrong_password"
    @Previewable @State var text4 = "secret123"
    
    return ScrollView {
        VStack(spacing: 24) {
            CraftTextField(
                placeholder: "Enter username...",
                text: $text1,
                label: "Username"
            )
            
            CraftTextField(
                placeholder: "Email address",
                text: $text2,
                label: "Email",
                leadingIcon: "envelope"
            )
            
            CraftTextField(
                placeholder: "Password",
                text: $text3,
                label: "Password",
                errorMessage: "Password must be at least 8 characters",
                isSecure: true
            )
            
            CraftTextField(
                placeholder: "Password",
                text: $text4,
                label: "Secure Field",
                helperText: "Must contain numbers and symbols",
                leadingIcon: "lock",
                isSecure: true
            )
        }
        .padding()
    }
}
