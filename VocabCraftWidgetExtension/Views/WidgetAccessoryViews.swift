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

/// Lock screen: one word to remember per glance, with its part of speech, IPA and meaning.
/// Lock screen timelines never carry flashcards (see `WidgetSurface`), so there is no review state here.
struct WidgetRectangularView: View {
    @Environment(\.craftTheme) private var theme

    let card: WidgetCard

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            Text(card.lemma)
                .font(theme.typography.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .widgetAccentable()
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WidgetInlineView: View {
    let card: WidgetCard

    var body: some View {
        Text(verbatim: WidgetInlineText.passive(
            lemma: card.lemma,
            abbreviation: localizedAbbreviation(for: card.partOfSpeech),
            definition: card.definitionVi
        ))
    }
}
#endif
