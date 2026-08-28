import SwiftUI

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

// MARK: - CraftFeedbackHintCard Helper

/// An accessible, tokenized hint and auxiliary note card designed for `CraftFeedbackSheet` extraContent.
public struct CraftFeedbackHintCard: View {
    @Environment(\.craftTheme) private var theme

    public let text: String
    public let icon: String
    public let tint: Color?

    public init(_ text: String, icon: String = "lightbulb.fill", tint: Color? = nil) {
        self.text = text
        self.icon = icon
        self.tint = tint
    }

    public var body: some View {
        let resolvedTint = tint ?? theme.colors.statusWarning
        HStack(alignment: .top, spacing: theme.spacing.xs) {
            CraftIcon(icon, size: .sm, color: resolvedTint)
                .padding(.top, 2)

            Text(text)
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, theme.spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: theme.radii.sm)
                .fill(resolvedTint.opacity(0.12))
        }
        .overlay {
            RoundedRectangle(cornerRadius: theme.radii.sm)
                .strokeBorder(resolvedTint.opacity(0.25), lineWidth: 1)
        }
    }
}
