import SwiftUI

// MARK: - CraftText Atom

/// A standardized text component driven by `CraftTypographyStyle` and semantic theme colors,
/// supporting plain text, localized keys, verbatim strings, and rich attributed strings (Markdown, bold, italic, links).
public struct CraftText: View {
    @Environment(\.craftTheme) private var theme

    private let textKey: LocalizedStringKey?
    private let rawText: String?
    private let attributedText: AttributedString?
    private let isVerbatim: Bool
    public let style: CraftTypographyStyle
    public let color: Color?
    public let lineLimit: Int?
    public let textAlignment: TextAlignment?
    public let tracking: CGFloat?
    public let lineSpacing: CGFloat?

    public var text: String? {
        if let rawText {
            return rawText
        }
        if let attributedText {
            return String(attributedText.characters)
        }
        return nil
    }

    public var attributedString: AttributedString? {
        attributedText
    }

    public init(
        _ textKey: LocalizedStringKey,
        style: CraftTypographyStyle = .bodyMedium,
        color: Color? = nil,
        lineLimit: Int? = nil,
        textAlignment: TextAlignment? = nil,
        tracking: CGFloat? = nil,
        lineSpacing: CGFloat? = nil
    ) {
        self.textKey = textKey
        self.rawText = nil
        self.attributedText = nil
        self.isVerbatim = false
        self.style = style
        self.color = color
        self.lineLimit = lineLimit
        self.textAlignment = textAlignment
        self.tracking = tracking
        self.lineSpacing = lineSpacing
    }

    public init(
        _ text: String,
        style: CraftTypographyStyle = .bodyMedium,
        color: Color? = nil,
        lineLimit: Int? = nil,
        textAlignment: TextAlignment? = nil,
        tracking: CGFloat? = nil,
        lineSpacing: CGFloat? = nil
    ) {
        self.textKey = nil
        self.rawText = text
        self.attributedText = nil
        self.isVerbatim = false
        self.style = style
        self.color = color
        self.lineLimit = lineLimit
        self.textAlignment = textAlignment
        self.tracking = tracking
        self.lineSpacing = lineSpacing
    }

    public init(
        verbatim text: String,
        style: CraftTypographyStyle = .bodyMedium,
        color: Color? = nil,
        lineLimit: Int? = nil,
        textAlignment: TextAlignment? = nil,
        tracking: CGFloat? = nil,
        lineSpacing: CGFloat? = nil
    ) {
        self.textKey = nil
        self.rawText = text
        self.attributedText = nil
        self.isVerbatim = true
        self.style = style
        self.color = color
        self.lineLimit = lineLimit
        self.textAlignment = textAlignment
        self.tracking = tracking
        self.lineSpacing = lineSpacing
    }

    public init(
        _ attributedText: AttributedString,
        style: CraftTypographyStyle = .bodyMedium,
        color: Color? = nil,
        lineLimit: Int? = nil,
        textAlignment: TextAlignment? = nil,
        tracking: CGFloat? = nil,
        lineSpacing: CGFloat? = nil
    ) {
        self.textKey = nil
        self.rawText = nil
        self.attributedText = attributedText
        self.isVerbatim = false
        self.style = style
        self.color = color
        self.lineLimit = lineLimit
        self.textAlignment = textAlignment
        self.tracking = tracking
        self.lineSpacing = lineSpacing
    }

    private var baseText: Text {
        let base: Text
        if let textKey {
            base = Text(textKey)
        } else if let rawText {
            base = isVerbatim ? Text(verbatim: rawText) : Text(rawText)
        } else if let attributedText {
            base = Text(attributedText)
        } else {
            base = Text(verbatim: "")
        }

        if let tracking {
            return base.tracking(tracking)
        }
        return base
    }

    public var body: some View {
        let styledText = baseText
            .font(theme.typography.font(for: style))
            .foregroundStyle(color ?? theme.colors.textPrimary)
            .lineLimit(lineLimit)
            .multilineTextAlignment(textAlignment ?? .leading)

        let withLineSpacing = Group {
            if let lineSpacing {
                styledText.lineSpacing(lineSpacing)
            } else {
                styledText
            }
        }

        if style == .metricRounded {
            withLineSpacing.monospacedDigit()
        } else {
            withLineSpacing
        }
    }
}

#if canImport(PreviewsMacros)
#Preview("CraftText") {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(CraftTypographyStyle.allCases, id: \.self) { style in
                CraftText(style.rawValue, style: style)
            }

            if let markdown = try? AttributedString(markdown: "Rich **Markdown** with *italics* and [link](https://apple.com)") {
                CraftText(markdown, style: .bodyMedium, tracking: 1.5, lineSpacing: 6)
            }
        }
        .padding()
    }
}
#endif

