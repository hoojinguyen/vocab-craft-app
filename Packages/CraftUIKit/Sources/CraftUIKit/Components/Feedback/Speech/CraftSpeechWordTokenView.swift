import SwiftUI

// MARK: - CraftSpeechWordTokenView

/// A status-tinted word chip displaying a target word and its speech matching status (pending, matched, fuzzy, mismatched).
public struct CraftSpeechWordTokenView: View {
    @Environment(\.craftTheme) private var theme
    public let token: CraftSpeechWordToken

    public init(token: CraftSpeechWordToken) {
        self.token = token
    }

    public var body: some View {
        HStack(spacing: 4) {
            if token.status == .matched {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.colors.statusSuccess)
            }

            Text(token.targetWord)
                .font(theme.typography.titleMedium)
                .foregroundColor(foregroundColor)
        }
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, theme.spacing.xs)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.md, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .animation(theme.animations.springSnappy, value: token.status)
    }

    private var foregroundColor: Color {
        switch token.status {
        case .pending:
            return theme.colors.textPrimary
        case .matched:
            return theme.colors.statusSuccess
        case .fuzzy:
            return theme.colors.statusWarning
        case .mismatched:
            return theme.colors.statusDanger
        }
    }

    private var backgroundColor: Color {
        switch token.status {
        case .pending:
            return theme.colors.surfaceCard.opacity(0.6)
        case .matched:
            return theme.colors.statusSuccess.opacity(0.12)
        case .fuzzy:
            return theme.colors.statusWarning.opacity(0.12)
        case .mismatched:
            return theme.colors.statusDanger.opacity(0.12)
        }
    }

    private var borderColor: Color {
        switch token.status {
        case .pending:
            return theme.colors.borderDefault.opacity(0.4)
        case .matched:
            return theme.colors.statusSuccess.opacity(0.4)
        case .fuzzy:
            return theme.colors.statusWarning.opacity(0.4)
        case .mismatched:
            return theme.colors.statusDanger.opacity(0.4)
        }
    }
}

// MARK: - Previews

#Preview("Word Token Statuses") {
    VStack(spacing: 16) {
        CraftSpeechWordTokenView(token: CraftSpeechWordToken(targetWord: "Pending", status: .pending))
        CraftSpeechWordTokenView(token: CraftSpeechWordToken(targetWord: "Matched", status: .matched))
        CraftSpeechWordTokenView(token: CraftSpeechWordToken(targetWord: "Fuzzy", status: .fuzzy))
        CraftSpeechWordTokenView(token: CraftSpeechWordToken(targetWord: "Mismatched", status: .mismatched))
    }
    .padding()
}
