import SwiftUI

// MARK: - CraftText Atom

/// A standardized text component driven by `CraftTypographyStyle` and semantic theme colors.
public struct CraftText: View {
    @Environment(\.craftTheme) private var theme

    private let textKey: LocalizedStringKey?
    private let rawText: String?
    private let isVerbatim: Bool
    public let style: CraftTypographyStyle
    public let color: Color?
    public let lineLimit: Int?
    public let textAlignment: TextAlignment?

    public var text: String? {
        rawText
    }

    public init(
        _ textKey: LocalizedStringKey,
        style: CraftTypographyStyle = .bodyMedium,
        color: Color? = nil,
        lineLimit: Int? = nil,
        textAlignment: TextAlignment? = nil
    ) {
        self.textKey = textKey
        self.rawText = nil
        self.isVerbatim = false
        self.style = style
        self.color = color
        self.lineLimit = lineLimit
        self.textAlignment = textAlignment
    }

    public init(
        _ text: String,
        style: CraftTypographyStyle = .bodyMedium,
        color: Color? = nil,
        lineLimit: Int? = nil,
        textAlignment: TextAlignment? = nil
    ) {
        self.textKey = nil
        self.rawText = text
        self.isVerbatim = false
        self.style = style
        self.color = color
        self.lineLimit = lineLimit
        self.textAlignment = textAlignment
    }

    public init(
        verbatim text: String,
        style: CraftTypographyStyle = .bodyMedium,
        color: Color? = nil,
        lineLimit: Int? = nil,
        textAlignment: TextAlignment? = nil
    ) {
        self.textKey = nil
        self.rawText = text
        self.isVerbatim = true
        self.style = style
        self.color = color
        self.lineLimit = lineLimit
        self.textAlignment = textAlignment
    }

    public var body: some View {
        Group {
            if let textKey {
                Text(textKey)
            } else if let rawText {
                if isVerbatim {
                    Text(verbatim: rawText)
                } else {
                    Text(rawText)
                }
            }
        }
        .font(theme.typography.font(for: style))
        .foregroundStyle(color ?? theme.colors.textPrimary)
        .lineLimit(lineLimit)
        .multilineTextAlignment(textAlignment ?? .leading)
    }
}

#Preview("CraftText") {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(CraftTypographyStyle.allCases, id: \.self) { style in
                CraftText(style.rawValue, style: style)
            }
        }
        .padding()
    }
}
