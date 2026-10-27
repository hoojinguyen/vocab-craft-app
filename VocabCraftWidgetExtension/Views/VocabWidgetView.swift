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
    @Environment(\.colorScheme) private var colorScheme
    public var entry: VocabWidgetEntry

    public init(entry: VocabWidgetEntry) {
        self.entry = entry
    }

    public var body: some View {
        let entryTheme = entry.themePreset.theme
        content
            .craftTheme(entryTheme)
            .environment(\.colorScheme, WidgetAppearance.colorScheme(for: renderingMode, system: colorScheme))
            .containerBackground(for: .widget) {
                WidgetBackground(entry: entry, family: family).craftTheme(entryTheme)
            }
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
                .lineLimit(3)
                .minimumScaleFactor(0.8)
            Text("app.widget.empty.subtitle")
                .font(theme.typography.caption)
                .foregroundStyle(palette.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "vocabcraft://home"))
    }
}

/// Brand gradient with scrims in full color; clear in tinted/vibrant so WidgetKit supplies the system surface.
/// Also holds the faint depth glyph.
/// White text needs the scrims: the top one for the header row, the bottom ones for the rows near the buttons.
struct WidgetBackground: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.colorScheme) private var colorScheme

    let entry: VocabWidgetEntry
    let family: WidgetFamily

    private var isSystemFamily: Bool {
        family == .systemSmall || family == .systemMedium
    }

    /// Dark enough that white text reaches 4.5:1 on every preset's brand gradient, including the light green ones.
    private static let topScrimOpacity = 0.8
    private static let bottomScrimOpacity = 0.6

    private var topScrim: LinearGradient {
        LinearGradient(
            colors: [theme.colors.textPrimary.opacity(Self.topScrimOpacity), theme.colors.textPrimary.opacity(0)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var bottomScrim: LinearGradient {
        LinearGradient(
            colors: [theme.colors.textPrimary.opacity(0), theme.colors.textPrimary.opacity(Self.bottomScrimOpacity)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        Group {
            if renderingMode == .fullColor {
                ZStack(alignment: .bottomTrailing) {
                    Rectangle().fill(theme.gradients.brandHero)
                    Rectangle().fill(topScrim)
                    Rectangle().fill(theme.gradients.fadeBottom)
                    Rectangle().fill(bottomScrim)
                    if let card = entry.card, entry.mode != .placeholder, isSystemFamily {
                        WidgetDepthGlyph(lemma: card.lemma, scale: family == .systemSmall ? 3 : 4)
                            .offset(x: theme.spacing.lg, y: theme.spacing.lg)
                    }
                }
            } else {
                Color.clear
            }
        }
        .environment(\.colorScheme, WidgetAppearance.colorScheme(for: renderingMode, system: colorScheme))
    }
}
