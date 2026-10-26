import CraftUIKit
import SwiftUI
#if !WIDGET_EXTENSION && canImport(VocabCraftApp)
import VocabCraftApp
#endif
import WidgetKit

/// Colors that depend on the widget rendering mode: white-on-gradient in full color,
/// system foreground in accented / vibrant modes (where the system recolors everything).
struct WidgetPalette {
    let theme: any CraftTheme
    let renderingMode: WidgetRenderingMode

    var isFullColor: Bool { renderingMode == .fullColor }

    /// Same token the app's home header uses on the brand gradient; the scrim keeps it readable.
    var foreground: Color { isFullColor ? theme.colors.textInverse : .primary }
    var secondary: Color { foreground.opacity(0.9) }
    var dimmed: Color { foreground.opacity(0.30) }
}

/// Glass capsule in full color, outlined capsule otherwise.
struct WidgetCapsuleBackground: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        let palette = WidgetPalette(theme: theme, renderingMode: renderingMode)
        if palette.isFullColor {
            Capsule().fill(theme.gradients.surfaceGlass)
        } else {
            Capsule().strokeBorder(palette.foreground.opacity(0.5), lineWidth: 1)
        }
    }
}

struct WidgetChip: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.widgetRenderingMode) private var renderingMode

    let titleKey: LocalizedStringKey
    var symbol: CraftSymbol?

    var body: some View {
        let palette = WidgetPalette(theme: theme, renderingMode: renderingMode)
        HStack(spacing: theme.spacing.xxs) {
            if let symbol {
                CraftIcon(symbol, size: .sm, color: palette.foreground)
            }
            Text(titleKey)
                .font(theme.typography.caption)
                .foregroundStyle(palette.foreground)
                .lineLimit(1)
        }
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, theme.spacing.xxs)
        .background { WidgetCapsuleBackground() }
        .widgetAccentable()
    }
}

struct WidgetSourceChip: View {
    let source: WidgetCard.Source

    var body: some View {
        switch source {
        case .upcoming:
            WidgetChip(titleKey: "app.widget.badge.new", symbol: .sparkles)
        case .recent, .due:
            WidgetChip(titleKey: "app.widget.badge.review", symbol: .refresh)
        }
    }
}

/// Part-of-speech chip followed by the IPA. Renders nothing when the card has neither.
struct WidgetMetaRow: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.widgetRenderingMode) private var renderingMode

    let card: WidgetCard

    var body: some View {
        let parts = WidgetCardMeta.parts(partOfSpeech: card.partOfSpeech, ipa: card.ipa)
        let palette = WidgetPalette(theme: theme, renderingMode: renderingMode)
        if parts.posKey != nil || parts.ipa != nil {
            HStack(spacing: theme.spacing.xs) {
                if let key = parts.posKey {
                    WidgetChip(titleKey: LocalizedStringKey(key))
                }
                if let ipa = parts.ipa {
                    Text(ipa)
                        .font(theme.typography.phonetic)
                        .foregroundStyle(palette.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }
}

struct WidgetAccentBar: View {
    @Environment(\.craftTheme) private var theme

    var body: some View {
        Capsule()
            .fill(theme.colors.accent)
            .frame(width: 24, height: 3)
            .widgetAccentable()
            .accessibilityHidden(true)
    }
}

/// Oversized first letter of the lemma, drawn faintly behind the content. Full color only.
struct WidgetDepthGlyph: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.widgetRenderingMode) private var renderingMode

    let lemma: String
    let scale: CGFloat

    var body: some View {
        if renderingMode == .fullColor, let first = lemma.first {
            Text(String(first).uppercased())
                .font(theme.typography.displayHero)
                .scaleEffect(scale)
                .foregroundStyle(WidgetPalette(theme: theme, renderingMode: renderingMode).foreground.opacity(0.08))
                .rotationEffect(.degrees(-12))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

struct WidgetProgressDots: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.widgetRenderingMode) private var renderingMode

    let filled: Int
    let label: String

    var body: some View {
        let palette = WidgetPalette(theme: theme, renderingMode: renderingMode)
        HStack(spacing: theme.spacing.xxs) {
            ForEach(0..<WidgetProgress.dotCount, id: \.self) { index in
                if index < filled {
                    Circle().fill(palette.foreground).frame(width: 6, height: 6).widgetAccentable()
                } else {
                    Circle().fill(palette.dimmed).frame(width: 6, height: 6)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
    }
}

/// Label for a full-width pill button. The caller wraps it in `Button(intent:)`.
/// Full color: opaque card-surface pill with a tinted icon, so red/green stay legible on the gradient.
struct WidgetPillLabel: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.widgetRenderingMode) private var renderingMode

    let titleKey: LocalizedStringKey
    let symbol: CraftSymbol
    let tint: Color
    let showsTitle: Bool

    var body: some View {
        let palette = WidgetPalette(theme: theme, renderingMode: renderingMode)
        let iconColor = palette.isFullColor ? tint : palette.foreground
        let titleColor = palette.isFullColor ? theme.colors.textPrimary : palette.foreground
        HStack(spacing: theme.spacing.xs) {
            CraftIcon(symbol, size: .md, color: iconColor).widgetAccentable()
            if showsTitle {
                Text(titleKey)
                    .font(theme.typography.label)
                    .foregroundStyle(titleColor)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 36)
        .background {
            if palette.isFullColor {
                Capsule().fill(theme.colors.surfaceCard)
            } else {
                WidgetCapsuleBackground()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(titleKey))
    }
}

/// Stand-in for the definition on the front of a flashcard: two blurred-out lines.
struct WidgetHiddenMeaningBar: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        let palette = WidgetPalette(theme: theme, renderingMode: renderingMode)
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Capsule().fill(palette.dimmed).frame(height: theme.spacing.sm)
            Capsule().fill(palette.dimmed).frame(height: theme.spacing.sm).padding(.trailing, theme.spacing.xl)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("app.widget.hidden_meaning"))
    }
}

/// Example sentence with the target word replaced by a highlighted blank.
struct MaskedExampleText: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.widgetRenderingMode) private var renderingMode

    /// Data punctuation, not a user-facing word.
    nonisolated static let maskToken = "_____"

    let example: String
    let lemma: String

    /// Replaces every case-insensitive occurrence of `lemma` in `example` with the mask token.
    nonisolated static func maskedExample(_ example: String, lemma: String) -> String {
        guard !lemma.isEmpty else { return example }
        return example.replacingOccurrences(of: lemma, with: maskToken, options: .caseInsensitive)
    }

    /// Same as `maskedExample`, with each mask token carrying a background highlight.
    nonisolated static func maskedAttributed(_ example: String, lemma: String, highlight: Color) -> AttributedString {
        guard !lemma.isEmpty else { return AttributedString(example) }
        var result = AttributedString()
        var cursor = example.startIndex
        while let match = example.range(of: lemma, options: .caseInsensitive, range: cursor..<example.endIndex) {
            result += AttributedString(example[cursor..<match.lowerBound])
            var token = AttributedString(maskToken)
            token.backgroundColor = highlight
            result += token
            cursor = match.upperBound
        }
        result += AttributedString(example[cursor...])
        return result
    }

    /// What VoiceOver reads: the lemma is replaced by the spoken blank, never the answer.
    nonisolated static func accessibilityText(_ example: String, lemma: String, blank: String) -> String {
        maskedExample(example, lemma: lemma).replacingOccurrences(of: maskToken, with: blank)
    }

    var body: some View {
        let palette = WidgetPalette(theme: theme, renderingMode: renderingMode)
        let highlight = palette.isFullColor ? theme.colors.accent.opacity(0.35) : palette.foreground.opacity(0.25)
        Text(Self.maskedAttributed(example, lemma: lemma, highlight: highlight))
            .font(theme.typography.bodySerif)
            .foregroundStyle(palette.foreground)
            .accessibilityLabel(
                Text(Self.accessibilityText(example, lemma: lemma, blank: String(localized: "app.widget.accessibility.blank")))
            )
    }
}
