import AppIntents
import CraftUIKit
import SwiftUI
#if !WIDGET_EXTENSION && canImport(VocabCraftApp)
import VocabCraftApp
#endif
import WidgetKit

// MARK: - Shared pieces

struct WidgetRevealButton: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.colorScheme) private var colorScheme

    let wordId: Int64

    var body: some View {
        Button(intent: RevealCardIntent(wordId: wordId)) {
            WidgetPillLabel(
                titleKey: "app.widget.action.reveal",
                symbol: .eye,
                tint: theme.colors.brandPrimary,
                showsTitle: true
            )
        }
        .buttonStyle(.plain)
    }
}

struct WidgetGradeButtons: View {
    @Environment(\.craftTheme) private var theme

    let wordId: Int64
    let showsTitle: Bool

    var body: some View {
        HStack(spacing: theme.spacing.sm) {
            Button(intent: GradeCardIntent(wordId: wordId, remembered: false)) {
                WidgetPillLabel(
                    titleKey: "app.widget.action.forgot",
                    symbol: .wrongCircle,
                    tint: theme.colors.statusDanger,
                    showsTitle: showsTitle
                )
            }
            .buttonStyle(.plain)
            Button(intent: GradeCardIntent(wordId: wordId, remembered: true)) {
                WidgetPillLabel(
                    titleKey: "app.widget.action.remembered",
                    symbol: .checkmarkCircle,
                    tint: theme.colors.statusSuccess,
                    showsTitle: showsTitle
                )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct WidgetLemmaText: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.colorScheme) private var colorScheme

    let lemma: String
    let font: Font

    var body: some View {
        Text(lemma)
            .font(font)
            .foregroundStyle(WidgetPalette(theme: theme, renderingMode: renderingMode, colorScheme: colorScheme).foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .widgetAccentable()
    }
}

private struct WidgetDefinitionText: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.colorScheme) private var colorScheme

    let text: String
    let lines: Int

    var body: some View {
        Text(text)
            .font(theme.typography.bodyMedium)
            .foregroundStyle(WidgetPalette(theme: theme, renderingMode: renderingMode, colorScheme: colorScheme).foreground)
            .lineLimit(lines)
            .transition(.opacity)
    }
}

private func progressLabel(practiced: Int, total: Int) -> String {
    String(format: String(localized: "app.widget.progress_format"), practiced, total)
}

// MARK: - Small

struct WidgetSmallView: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.colorScheme) private var colorScheme

    let entry: VocabWidgetEntry
    let card: WidgetCard

    private var palette: WidgetPalette {
        WidgetPalette(theme: theme, renderingMode: renderingMode, colorScheme: colorScheme)
    }
    private var progress: WidgetProgress.Snapshot {
        WidgetProgress.make(practiced: entry.practicedToday, due: entry.dueCount)
    }

    /// Progress lives in the header, so the IPA row and accent bar go before it does.
    var body: some View {
        ViewThatFits(in: .vertical) {
            layout(showsHeader: true, showsMeta: true, showsAccentBar: true)
            layout(showsHeader: true, showsMeta: true, showsAccentBar: false)
            layout(showsHeader: true, showsMeta: false, showsAccentBar: true)
            layout(showsHeader: true, showsMeta: false, showsAccentBar: false)
            layout(showsHeader: true, showsMeta: false, showsAccentBar: false, compactLemma: true)
            layout(showsHeader: false, showsMeta: false, showsAccentBar: false, compactLemma: true)
        }
    }

    private func layout(
        showsHeader: Bool,
        showsMeta: Bool,
        showsAccentBar: Bool,
        compactLemma: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            if showsHeader {
                header
            }
            WidgetLemmaText(
                lemma: card.lemma,
                font: entry.mode == .flashcardBack || compactLemma
                    ? theme.typography.titleMedium
                    : theme.typography.titleLarge
            )
            if showsMeta, entry.mode != .flashcardBack {
                WidgetMetaRow(card: card)
            }
            if showsAccentBar {
                WidgetAccentBar()
            }
            switch entry.mode {
            case .flashcardFront:
                WidgetHiddenMeaningBar()
                Spacer(minLength: 0)
                WidgetRevealButton(wordId: card.wordId)
            case .flashcardBack:
                WidgetDefinitionText(text: card.definitionVi, lines: 3)
                Spacer(minLength: 0)
                WidgetGradeButtons(wordId: card.wordId, showsTitle: false)
            default:
                WidgetDefinitionText(text: card.definitionVi, lines: 3)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        HStack {
            WidgetSourceChip(source: card.source)
            Spacer(minLength: 0)
            if entry.mode == .flashcardFront, progress.total > 0 {
                WidgetProgressDots(
                    filled: progress.filledDots,
                    label: progressLabel(practiced: entry.practicedToday, total: progress.total)
                )
            } else if entry.mode == .passive, WidgetProgress.showsPracticedFooter(entry.practicedToday) {
                practicedBadge
            }
        }
    }

    private var practicedBadge: some View {
        HStack(spacing: theme.spacing.xxs) {
            CraftIcon(.checkmarkCircle, size: .sm, color: palette.secondary)
            Text(verbatim: "\(entry.practicedToday)")
                .font(theme.typography.label)
                .foregroundStyle(palette.foreground)
                .contentTransition(.numericText())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: String(
            format: String(localized: "app.widget.practiced_today_format"),
            entry.practicedToday
        )))
    }
}

// MARK: - Medium

struct WidgetMediumView: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.colorScheme) private var colorScheme

    let entry: VocabWidgetEntry
    let card: WidgetCard

    /// Left / right column split when the card has an example sentence.
    private static let leftShare: CGFloat = 0.55

    private var palette: WidgetPalette {
        WidgetPalette(theme: theme, renderingMode: renderingMode, colorScheme: colorScheme)
    }
    private var progress: WidgetProgress.Snapshot {
        WidgetProgress.make(practiced: entry.practicedToday, due: entry.dueCount)
    }
    private var showsDefinition: Bool { entry.mode != .flashcardFront }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            GeometryReader { geometry in
                let available = geometry.size.width - theme.spacing.md
                HStack(alignment: .top, spacing: theme.spacing.md) {
                    if card.exampleEn.isEmpty {
                        leftColumn.frame(width: geometry.size.width)
                    } else {
                        leftColumn.frame(width: available * Self.leftShare)
                        exampleCard.frame(width: available * (1 - Self.leftShare))
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            bottomRow
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var bottomRow: some View {
        switch entry.mode {
        case .flashcardFront:
            HStack(spacing: theme.spacing.sm) {
                WidgetRevealButton(wordId: card.wordId)
                if progress.total > 0 {
                    Text(verbatim: progressLabel(practiced: entry.practicedToday, total: progress.total))
                        .font(theme.typography.label)
                        .foregroundStyle(palette.foreground)
                        .contentTransition(.numericText())
                }
            }
        case .flashcardBack:
            WidgetGradeButtons(wordId: card.wordId, showsTitle: true)
        default:
            EmptyView()
        }
    }

    /// Tries the richest column first and sheds the accent bar, the source chip and a definition
    /// line, in that order, until it fits above the button row.
    private var leftColumn: some View {
        ViewThatFits(in: .vertical) {
            column(showsChip: true, showsAccentBar: true, definitionLines: 2)
            column(showsChip: true, showsAccentBar: false, definitionLines: 2)
            column(showsChip: false, showsAccentBar: false, definitionLines: 2)
            column(showsChip: false, showsAccentBar: false, definitionLines: 1)
        }
    }

    private func column(showsChip: Bool, showsAccentBar: Bool, definitionLines: Int) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            if showsChip {
                HStack {
                    WidgetSourceChip(source: card.source)
                    if entry.mode == .passive, WidgetProgress.showsPracticedFooter(entry.practicedToday) {
                        Text(verbatim: String(
                            format: String(localized: "app.widget.practiced_today_format"),
                            entry.practicedToday
                        ))
                        .font(theme.typography.caption)
                        .foregroundStyle(palette.secondary)
                        .lineLimit(1)
                        .contentTransition(.numericText())
                    }
                }
            }
            WidgetLemmaText(lemma: card.lemma, font: theme.typography.titleLarge)
            WidgetMetaRow(card: card)
            if showsAccentBar {
                WidgetAccentBar()
            }
            if showsDefinition {
                WidgetDefinitionText(text: card.definitionVi, lines: definitionLines)
            } else {
                WidgetHiddenMeaningBar()
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var exampleCard: some View {
        Group {
            if entry.mode == .flashcardFront {
                MaskedExampleText(example: card.exampleEn, lemma: card.lemma)
            } else {
                Text(card.exampleEn)
                    .font(theme.typography.bodySerif)
                    .foregroundStyle(palette.foreground)
            }
        }
        .lineLimit(4)
        .minimumScaleFactor(0.7)
        .padding(theme.spacing.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            if palette.isFullColor {
                RoundedRectangle(cornerRadius: theme.radius.lg).fill(theme.gradients.surfaceGlass)
            } else {
                RoundedRectangle(cornerRadius: theme.radius.lg)
                    .strokeBorder(palette.foreground.opacity(0.5), lineWidth: 1)
            }
        }
    }
}
