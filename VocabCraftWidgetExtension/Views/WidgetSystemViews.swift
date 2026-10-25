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

    let wordId: Int64

    var body: some View {
        Button(intent: RevealCardIntent(wordId: wordId)) {
            WidgetPillLabel(
                titleKey: "app.widget.action.reveal",
                symbol: .eye,
                tint: WidgetPalette(theme: theme, renderingMode: renderingMode).foreground,
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

    let lemma: String
    let font: Font

    var body: some View {
        Text(lemma)
            .font(font)
            .foregroundStyle(WidgetPalette(theme: theme, renderingMode: renderingMode).foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .widgetAccentable()
    }
}

private struct WidgetDefinitionText: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.widgetRenderingMode) private var renderingMode

    let text: String
    let lines: Int

    var body: some View {
        Text(text)
            .font(theme.typography.bodyMedium)
            .foregroundStyle(WidgetPalette(theme: theme, renderingMode: renderingMode).foreground)
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

    let entry: VocabWidgetEntry
    let card: WidgetCard

    private var palette: WidgetPalette { WidgetPalette(theme: theme, renderingMode: renderingMode) }
    private var progress: (fraction: Double, filledDots: Int, total: Int) {
        WidgetProgress.make(practiced: entry.practicedToday, due: entry.dueCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            header
            WidgetLemmaText(
                lemma: card.lemma,
                font: entry.mode == .flashcardBack ? theme.typography.titleMedium : theme.typography.titleLarge
            )
            if entry.mode != .flashcardBack {
                WidgetMetaRow(card: card)
            }
            WidgetAccentBar()
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
                WidgetDefinitionText(text: card.definitionVi, lines: 2)
                Spacer(minLength: 0)
                practicedFooter
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
            }
        }
    }

    @ViewBuilder
    private var practicedFooter: some View {
        if WidgetProgress.showsPracticedFooter(entry.practicedToday) {
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

// MARK: - Medium

struct WidgetMediumView: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.widgetRenderingMode) private var renderingMode

    let entry: VocabWidgetEntry
    let card: WidgetCard

    private var palette: WidgetPalette { WidgetPalette(theme: theme, renderingMode: renderingMode) }
    private var progress: (fraction: Double, filledDots: Int, total: Int) {
        WidgetProgress.make(practiced: entry.practicedToday, due: entry.dueCount)
    }
    private var showsDefinition: Bool { entry.mode != .flashcardFront }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack(alignment: .top, spacing: theme.spacing.md) {
                leftColumn
                if !card.exampleEn.isEmpty {
                    exampleCard
                }
            }
            switch entry.mode {
            case .flashcardFront:
                HStack(spacing: theme.spacing.sm) {
                    WidgetRevealButton(wordId: card.wordId)
                    if progress.total > 0 {
                        Text(verbatim: progressLabel(practiced: entry.practicedToday, total: progress.total))
                            .font(theme.typography.caption)
                            .foregroundStyle(palette.secondary)
                            .contentTransition(.numericText())
                            .accessibilityLabel(Text(verbatim: progressLabel(
                                practiced: entry.practicedToday,
                                total: progress.total
                            )))
                    }
                }
            case .flashcardBack:
                WidgetGradeButtons(wordId: card.wordId, showsTitle: true)
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack {
                WidgetSourceChip(source: card.source)
                if WidgetProgress.showsPracticedFooter(entry.practicedToday), entry.mode == .passive {
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
            WidgetLemmaText(lemma: card.lemma, font: theme.typography.displayLarge)
            WidgetMetaRow(card: card)
            WidgetAccentBar()
            if showsDefinition {
                WidgetDefinitionText(text: card.definitionVi, lines: 2)
            } else {
                WidgetHiddenMeaningBar()
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
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
        .lineLimit(5)
        .padding(theme.spacing.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            if palette.isFullColor {
                RoundedRectangle(cornerRadius: theme.radius.lg).fill(theme.gradients.surfaceGlass)
            } else {
                RoundedRectangle(cornerRadius: theme.radius.lg).strokeBorder(palette.foreground.opacity(0.5), lineWidth: 1)
            }
        }
        .containerRelativeFrame(.horizontal) { width, _ in width * 0.45 }
    }
}
