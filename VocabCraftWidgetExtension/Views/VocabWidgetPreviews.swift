#if DEBUG
import SwiftUI
#if !WIDGET_EXTENSION && canImport(VocabCraftApp)
import VocabCraftApp
#endif
import WidgetKit

enum VocabWidgetPreviewData {
    static let serendipity = WidgetCard(
        wordId: 1,
        lemma: "serendipity",
        ipa: "/ˌser.ənˈdɪp.ə.ti/",
        definitionVi: "sự tình cờ may mắn",
        exampleEn: "Finding that café was pure serendipity.",
        source: .upcoming,
        partOfSpeech: "noun"
    )
    static let longLemma = WidgetCard(
        wordId: 2,
        lemma: "internationalization",
        ipa: "/ˌɪn.təˌnæʃ.ən.əl.aɪˈzeɪ.ʃən/",
        definitionVi: "quốc tế hóa",
        exampleEn: "Internationalization takes planning.",
        source: .recent,
        partOfSpeech: "noun"
    )
    static let noMeta = WidgetCard(
        wordId: 3,
        lemma: "run",
        ipa: "",
        definitionVi: "chạy",
        exampleEn: "I run every morning.",
        source: .due
    )
    static let noExample = WidgetCard(
        wordId: 4,
        lemma: "quickly",
        ipa: "/ˈkwɪk.li/",
        definitionVi: "một cách nhanh chóng",
        exampleEn: "",
        source: .recent,
        partOfSpeech: "adverb"
    )

    static func entry(
        _ card: WidgetCard?,
        _ mode: WidgetEntryMode,
        due: Int = 0,
        practiced: Int = 0
    ) -> VocabWidgetEntry {
        VocabWidgetEntry(date: Date(), card: card, mode: mode, dueCount: due, practicedToday: practiced)
    }
}

#Preview("Small", as: .systemSmall) {
    VocabWidget()
} timeline: {
    VocabWidgetPreviewData.entry(VocabWidgetPreviewData.serendipity, .passive, practiced: 7)
    VocabWidgetPreviewData.entry(VocabWidgetPreviewData.serendipity, .flashcardFront, due: 2, practiced: 3)
    VocabWidgetPreviewData.entry(VocabWidgetPreviewData.serendipity, .flashcardBack, due: 2, practiced: 3)
    VocabWidgetPreviewData.entry(VocabWidgetPreviewData.longLemma, .passive)
    VocabWidgetPreviewData.entry(VocabWidgetPreviewData.noMeta, .flashcardFront, due: 1)
    VocabWidgetPreviewData.entry(nil, .placeholder)
}

#Preview("Medium", as: .systemMedium) {
    VocabWidget()
} timeline: {
    VocabWidgetPreviewData.entry(VocabWidgetPreviewData.serendipity, .passive, practiced: 7)
    VocabWidgetPreviewData.entry(VocabWidgetPreviewData.serendipity, .flashcardFront, due: 2, practiced: 3)
    VocabWidgetPreviewData.entry(VocabWidgetPreviewData.serendipity, .flashcardBack, due: 2, practiced: 3)
    VocabWidgetPreviewData.entry(VocabWidgetPreviewData.noExample, .passive)
    VocabWidgetPreviewData.entry(VocabWidgetPreviewData.longLemma, .flashcardFront, due: 1)
    VocabWidgetPreviewData.entry(nil, .placeholder)
}

#if os(iOS)
#Preview("Lock Screen rectangular", as: .accessoryRectangular) {
    VocabWidget()
} timeline: {
    VocabWidgetPreviewData.entry(VocabWidgetPreviewData.serendipity, .passive)
    VocabWidgetPreviewData.entry(VocabWidgetPreviewData.longLemma, .passive)
    VocabWidgetPreviewData.entry(VocabWidgetPreviewData.noMeta, .passive)
}

#Preview("Lock Screen inline", as: .accessoryInline) {
    VocabWidget()
} timeline: {
    VocabWidgetPreviewData.entry(VocabWidgetPreviewData.serendipity, .passive)
    VocabWidgetPreviewData.entry(VocabWidgetPreviewData.noMeta, .passive)
}
#endif
#endif
