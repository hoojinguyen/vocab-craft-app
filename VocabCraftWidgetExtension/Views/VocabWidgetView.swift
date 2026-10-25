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
                    WidgetRectangularView(entry: entry, card: card)
                case .accessoryInline:
                    WidgetInlineView(entry: entry, card: card)
                #endif
                default:
                    WidgetMediumView(entry: entry, card: card)
                }
            }
            .id(card.wordId)
            .transition(.push(from: .trailing))
        }
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
}
