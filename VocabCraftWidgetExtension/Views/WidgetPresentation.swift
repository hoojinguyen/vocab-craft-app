import Foundation
import SwiftUI
import WidgetKit

/// Today's practice progress shown as dots, a fraction or a gauge.
enum WidgetProgress {
    static let dotCount = 5

    struct Snapshot: Equatable {
        let fraction: Double
        let filledDots: Int
        let total: Int
    }

    /// `fraction = practiced / (practiced + due)`; no work at all gives an empty indicator.
    static func make(practiced: Int, due: Int) -> Snapshot {
        let practiced = max(0, practiced)
        let due = max(0, due)
        let total = practiced + due
        guard total > 0 else { return Snapshot(fraction: 0, filledDots: 0, total: 0) }
        let fraction = Double(practiced) / Double(total)
        let dots = min(dotCount, max(0, Int((fraction * Double(dotCount)).rounded())))
        return Snapshot(fraction: fraction, filledDots: dots, total: total)
    }

    static func showsPracticedFooter(_ practicedToday: Int) -> Bool {
        practicedToday > 0
    }
}

/// Maps the catalog's `senses.part_of_speech` value to a localized abbreviation key.
enum WidgetPartOfSpeech {
    private static let known: Set<String> = [
        "noun", "verb", "adjective", "adverb", "pronoun", "preposition", "conjunction", "determiner"
    ]

    static func abbreviationKey(for raw: String?) -> String? {
        guard let raw, known.contains(raw) else { return nil }
        return "app.widget.pos.\(raw)"
    }
}

/// The part-of-speech chip and IPA that sit under the lemma. Empty parts are dropped.
enum WidgetCardMeta {
    static func parts(partOfSpeech: String?, ipa: String) -> (posKey: String?, ipa: String?) {
        let trimmed = ipa.trimmingCharacters(in: .whitespacesAndNewlines)
        return (WidgetPartOfSpeech.abbreviationKey(for: partOfSpeech), trimmed.isEmpty ? nil : trimmed)
    }

    /// Single plain-text line ("n. · /ipa/") for Lock Screen widgets, `nil` when there is nothing to show.
    static func line(abbreviation: String?, ipa: String?) -> String? {
        let parts = [abbreviation, ipa].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

enum WidgetInlineText {
    /// "lemma (n.): definition", dropping the part of speech when the card has none.
    static func passive(lemma: String, abbreviation: String?, definition: String) -> String {
        guard let abbreviation else { return "\(lemma): \(definition)" }
        return "\(lemma) (\(abbreviation)): \(definition)"
    }
}

enum WidgetAppearance {
    /// The brand gradient is identical in light and dark, so full-color widgets keep the light
    /// scheme (white text, white pills). Tinted and vibrant modes follow the system.
    static func colorScheme(for renderingMode: WidgetRenderingMode, system: ColorScheme) -> ColorScheme {
        renderingMode == .fullColor ? .light : system
    }
}
