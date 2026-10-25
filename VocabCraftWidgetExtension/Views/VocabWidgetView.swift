import AppIntents
import CraftUIKit
import SwiftUI
#if !WIDGET_EXTENSION && canImport(VocabCraftApp)
import VocabCraftApp
#endif
import WidgetKit

public struct VocabWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.craftTheme) private var theme
    @Environment(\.widgetRenderingMode) private var renderingMode
    public var entry: VocabWidgetEntry

    public init(entry: VocabWidgetEntry) {
        self.entry = entry
    }

    public var body: some View {
        content
            .containerBackground(for: .widget) { background }
    }

    // MARK: Background

    @ViewBuilder
    private var background: some View {
        if renderingMode == .fullColor {
            ZStack(alignment: .bottomTrailing) {
                Rectangle().fill(theme.gradients.brandHero)
                if let card = entry.card, entry.mode != .placeholder, isSystemFamily {
                    WidgetDepthGlyph(lemma: card.lemma, scale: family == .systemSmall ? 3 : 4)
                        .offset(x: theme.spacing.lg, y: theme.spacing.lg)
                }
            }
        } else {
            theme.colors.surfaceCard
        }
    }

    private var isSystemFamily: Bool {
        family == .systemSmall || family == .systemMedium
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        if entry.mode == .placeholder || entry.card == nil {
            emptyView
        } else if let card = entry.card {
            Group {
                switch family {
                case .systemSmall:
                    WidgetSmallView(entry: entry, card: card)
                #if os(iOS)
                case .accessoryRectangular:
                    rectangularView(card)
                case .accessoryInline:
                    inlineView(card)
                #endif
                default:
                    WidgetMediumView(entry: entry, card: card)
                }
            }
            .id(card.wordId)
            .transition(.push(from: .trailing))
        }
    }

    private var isFlashcard: Bool {
        entry.mode == .flashcardFront || entry.mode == .flashcardBack
    }

    private var dueCountString: String {
        String(format: String(localized: "app.widget.due_count_format"), entry.dueCount)
    }

    // MARK: Empty

    private var emptyView: some View {
        let palette = WidgetPalette(theme: theme, renderingMode: renderingMode)
        return VStack(spacing: theme.spacing.sm) {
            CraftIcon(.sparkles, size: .lg, color: palette.isFullColor ? theme.colors.accent : palette.foreground)
                .widgetAccentable()
            Text("app.widget.empty.title")
                .font(theme.typography.headline)
                .foregroundStyle(palette.foreground)
                .multilineTextAlignment(.center)
            Text("app.widget.empty.subtitle")
                .font(theme.typography.caption)
                .foregroundStyle(palette.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "vocabcraft://home"))
    }

    #if os(iOS)
    // MARK: Lock Screen

    private func rectangularView(_ card: WidgetCard) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            Text(card.lemma)
                .font(theme.typography.headline)
                .lineLimit(1)
                .widgetAccentable()
            if entry.mode == .flashcardFront {
                Text("app.widget.hidden_meaning")
                    .font(theme.typography.caption)
                    .lineLimit(2)
            } else {
                if entry.mode == .passive, !card.ipa.isEmpty {
                    Text(card.ipa)
                        .font(theme.typography.caption)
                        .lineLimit(1)
                }
                Text(card.definitionVi)
                    .font(theme.typography.caption)
                    .lineLimit(entry.mode == .passive ? 1 : 2)
            }
            if isFlashcard {
                Text("app.widget.lock.open_to_review")
                    .font(theme.typography.caption)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(isFlashcard ? URL(string: "vocabcraft://review") : nil)
    }

    @ViewBuilder
    private func inlineView(_ card: WidgetCard) -> some View {
        if isFlashcard {
            Text(verbatim: dueCountString)
        } else {
            Text(verbatim: "\(card.lemma): \(card.definitionVi)")
        }
    }
    #endif
}
