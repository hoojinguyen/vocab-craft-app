import SwiftUI

// MARK: - CraftText Atom

/// A standardized text component driven by `CraftTypographyStyle` and semantic theme colors.
public struct CraftText: View {
    @Environment(\.craftTheme) private var theme

    public let text: String
    public let style: CraftTypographyStyle
    public let color: Color?
    public let lineLimit: Int?
    public let textAlignment: TextAlignment?

    public init(
        _ text: String,
        style: CraftTypographyStyle = .bodyMedium,
        color: Color? = nil,
        lineLimit: Int? = nil,
        textAlignment: TextAlignment? = nil
    ) {
        self.text = text
        self.style = style
        self.color = color
        self.lineLimit = lineLimit
        self.textAlignment = textAlignment
    }

    public var body: some View {
        Text(text)
            .font(theme.typography.font(for: style))
            .foregroundColor(color ?? theme.colors.textPrimary)
            .lineLimit(lineLimit)
            .multilineTextAlignment(textAlignment ?? .leading)
    }
}
