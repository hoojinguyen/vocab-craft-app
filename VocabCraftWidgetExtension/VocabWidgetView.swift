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

    /// Data punctuation, not a user-facing word.
    nonisolated static let maskToken = "_____"

    public init(entry: VocabWidgetEntry) {
        self.entry = entry
    }

    /// Replaces every case-insensitive occurrence of `lemma` in `example` with the mask token.
    nonisolated static func maskedExample(_ example: String, lemma: String) -> String {
        guard !lemma.isEmpty else { return example }
        return example.replacingOccurrences(of: lemma, with: maskToken, options: .caseInsensitive)
    }

    public var body: some View {
        content
            .containerBackground(theme.colors.surfaceCard, for: .widget)
    }

    @ViewBuilder
    private var content: some View {
        if entry.mode == .placeholder || entry.card == nil {
            emptyView
        } else if let card = entry.card {
            switch family {
            case .systemSmall:
                smallView(card)
            #if os(iOS)
            case .accessoryRectangular:
                rectangularView(card)
            case .accessoryInline:
                inlineView(card)
            #endif
            default:
                mediumView(card)
            }
        }
    }

    private var isFlashcard: Bool {
        entry.mode == .flashcardFront || entry.mode == .flashcardBack
    }

    private var showsBack: Bool {
        entry.mode != .flashcardFront
    }

    // MARK: Pieces

    private func badge(_ card: WidgetCard) -> some View {
        Group {
            switch card.source {
            case .upcoming:
                CraftBadge(LocalizedStringKey("app.widget.badge.new"), symbol: .sparkles, tone: .primary, size: .sm)
            case .recent, .due:
                CraftBadge(LocalizedStringKey("app.widget.badge.review"), symbol: .refresh, tone: .success, size: .sm)
            }
        }
        .widgetAccentable()
    }

    private func lemmaText(_ card: WidgetCard, font: Font) -> some View {
        Text(card.lemma)
            .font(font)
            .foregroundStyle(theme.colors.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .widgetAccentable()
    }

    private func ipaText(_ card: WidgetCard) -> some View {
        Text(card.ipa)
            .font(theme.typography.caption)
            .foregroundStyle(theme.colors.textMuted)
            .lineLimit(1)
    }

    private func definitionText(_ card: WidgetCard, lines: Int) -> some View {
        Text(card.definitionVi)
            .font(theme.typography.bodyMedium)
            .foregroundStyle(theme.colors.textPrimary)
            .lineLimit(lines)
    }

    private var dueCountString: String {
        String(format: String(localized: "app.widget.due_count_format"), entry.dueCount)
    }

    private var dueCountText: some View {
        Text(verbatim: dueCountString)
            .font(theme.typography.caption)
            .foregroundStyle(theme.colors.textSecondary)
            .lineLimit(1)
    }

    private func actionLabel(
        _ key: LocalizedStringKey,
        symbol: CraftSymbol,
        color: Color,
        showsTitle: Bool
    ) -> some View {
        HStack(spacing: theme.spacing.xs) {
            CraftIcon(symbol, size: .sm, color: color)
            if showsTitle {
                Text(key)
                    .font(theme.typography.caption)
                    .foregroundStyle(color)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.spacing.xs)
        .background {
            if renderingMode == .fullColor {
                RoundedRectangle(cornerRadius: theme.radius.md).fill(theme.colors.surfaceSubtle)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(key))
    }

    private func revealButton(_ card: WidgetCard) -> some View {
        Button(intent: RevealCardIntent(wordId: card.wordId)) {
            actionLabel("app.widget.action.reveal", symbol: .eye, color: theme.colors.brandPrimary, showsTitle: true)
        }
        .buttonStyle(.plain)
    }

    private func gradeButtons(_ card: WidgetCard, showsTitle: Bool) -> some View {
        HStack(spacing: theme.spacing.sm) {
            Button(intent: GradeCardIntent(wordId: card.wordId, remembered: false)) {
                actionLabel(
                    "app.widget.action.forgot",
                    symbol: .wrongCircle,
                    color: theme.colors.statusDanger,
                    showsTitle: showsTitle
                )
            }
            .buttonStyle(.plain)
            Button(intent: GradeCardIntent(wordId: card.wordId, remembered: true)) {
                actionLabel(
                    "app.widget.action.remembered",
                    symbol: .checkmarkCircle,
                    color: theme.colors.statusSuccess,
                    showsTitle: showsTitle
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Empty

    private var emptyView: some View {
        VStack(spacing: theme.spacing.sm) {
            CraftIcon(.sparkles, size: .lg, color: theme.colors.brandPrimary)
            Text("app.widget.empty.title")
                .font(theme.typography.bodyMedium)
                .foregroundStyle(theme.colors.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "vocabcraft://home"))
    }

    // MARK: Small

    private func smallView(_ card: WidgetCard) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            badge(card)
            lemmaText(card, font: theme.typography.titleMedium)
            if entry.mode == .flashcardBack {
                definitionText(card, lines: 2)
                Spacer(minLength: 0)
                gradeButtons(card, showsTitle: false)
            } else if entry.mode == .flashcardFront {
                ipaText(card)
                Text("app.widget.hidden_meaning")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textMuted)
                    .lineLimit(2)
                Spacer(minLength: 0)
                dueCountText
                revealButton(card)
            } else {
                ipaText(card)
                definitionText(card, lines: 2)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: Medium

    private func mediumView(_ card: WidgetCard) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: theme.spacing.sm) {
                lemmaText(card, font: theme.typography.titleLarge)
                ipaText(card)
                Spacer(minLength: 0)
                badge(card)
            }
            if showsBack {
                definitionText(card, lines: 2)
            }
            if !card.exampleEn.isEmpty {
                exampleText(card)
            }
            Spacer(minLength: 0)
            if isFlashcard {
                dueCountText
            }
            switch entry.mode {
            case .flashcardFront:
                revealButton(card)
            case .flashcardBack:
                gradeButtons(card, showsTitle: true)
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func exampleText(_ card: WidgetCard) -> some View {
        if entry.mode == .flashcardFront {
            Text(Self.maskedExample(card.exampleEn, lemma: card.lemma))
                .font(theme.typography.bodySerif)
                .foregroundStyle(theme.colors.textSecondary)
                .lineLimit(2)
                .accessibilityLabel(
                    Text(verbatim: Self.maskedExample(card.exampleEn, lemma: card.lemma)
                        .replacingOccurrences(of: Self.maskToken, with: String(localized: "app.widget.accessibility.blank")))
                )
        } else {
            Text(card.exampleEn)
                .font(theme.typography.bodySerif)
                .foregroundStyle(theme.colors.textSecondary)
                .lineLimit(2)
        }
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
                .widgetURL(URL(string: "vocabcraft://review"))
        } else {
            Text(verbatim: "\(card.lemma): \(card.definitionVi)")
        }
    }
    #endif
}
