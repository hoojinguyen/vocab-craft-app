#if os(iOS)
import CraftUIKit
import SwiftUI
#if !WIDGET_EXTENSION && canImport(VocabCraftApp)
import VocabCraftApp
#endif
import WidgetKit

private func localizedAbbreviation(for partOfSpeech: String?) -> String? {
    WidgetPartOfSpeech.abbreviationKey(for: partOfSpeech).map { String(localized: String.LocalizationValue($0)) }
}

private func isFlashcard(_ mode: WidgetEntryMode) -> Bool {
    mode == .flashcardFront || mode == .flashcardBack
}

struct WidgetRectangularView: View {
    @Environment(\.craftTheme) private var theme

    let entry: VocabWidgetEntry
    let card: WidgetCard

    private var progress: (fraction: Double, filledDots: Int, total: Int) {
        WidgetProgress.make(practiced: entry.practicedToday, due: entry.dueCount)
    }

    var body: some View {
        HStack(alignment: .center, spacing: theme.spacing.sm) {
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(card.lemma)
                    .font(theme.typography.headline)
                    .lineLimit(1)
                    .widgetAccentable()
                if isFlashcard(entry.mode) {
                    Text("app.widget.lock.open_to_review")
                        .font(theme.typography.caption)
                        .lineLimit(1)
                } else {
                    if let line = WidgetCardMeta.line(
                        abbreviation: localizedAbbreviation(for: card.partOfSpeech),
                        ipa: WidgetCardMeta.parts(partOfSpeech: nil, ipa: card.ipa).ipa
                    ) {
                        Text(line)
                            .font(theme.typography.caption)
                            .lineLimit(1)
                    }
                    Text(card.definitionVi)
                        .font(theme.typography.caption)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if isFlashcard(entry.mode), progress.total > 0 {
                Gauge(value: progress.fraction) {
                    Text("app.widget.badge.review")
                } currentValueLabel: {
                    Text(verbatim: "\(entry.practicedToday)")
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .accessibilityLabel(Text(verbatim: String(
                    format: String(localized: "app.widget.progress_format"),
                    entry.practicedToday,
                    progress.total
                )))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(isFlashcard(entry.mode) ? URL(string: "vocabcraft://review") : nil)
    }
}

struct WidgetInlineView: View {
    let entry: VocabWidgetEntry
    let card: WidgetCard

    var body: some View {
        if isFlashcard(entry.mode) {
            let total = entry.practicedToday + entry.dueCount
            Text(verbatim: String(
                format: String(localized: "app.widget.inline_progress_format"),
                entry.practicedToday,
                total,
                entry.dueCount
            ))
        } else {
            Text(verbatim: WidgetInlineText.passive(
                lemma: card.lemma,
                abbreviation: localizedAbbreviation(for: card.partOfSpeech),
                definition: card.definitionVi
            ))
        }
    }
}
#endif
