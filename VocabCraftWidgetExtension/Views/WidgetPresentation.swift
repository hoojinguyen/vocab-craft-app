import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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

/// WCAG contrast helpers used to pick readable text on the brand gradient.
enum WidgetContrast {
    struct RGB: Equatable {
        let red: Double
        let green: Double
        let blue: Double
    }

    static func luminance(_ color: RGB) -> Double {
        func linear(_ value: Double) -> Double {
            value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(color.red) + 0.7152 * linear(color.green) + 0.0722 * linear(color.blue)
    }

    static func ratio(_ first: RGB, _ second: RGB) -> Double {
        let lhs = luminance(first)
        let rhs = luminance(second)
        return (max(lhs, rhs) + 0.05) / (min(lhs, rhs) + 0.05)
    }

    /// Index of the candidate with the highest contrast against `background`.
    static func bestIndex(on background: RGB, candidates: [RGB]) -> Int {
        candidates.indices.max { ratio(background, candidates[$0]) < ratio(background, candidates[$1]) } ?? 0
    }

    #if canImport(UIKit)
    static func rgb(of color: Color, scheme: ColorScheme) -> RGB {
        let style: UIUserInterfaceStyle = scheme == .dark ? .dark : .light
        let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return RGB(red: Double(red), green: Double(green), blue: Double(blue))
    }
    #endif

    /// The candidate that reads best on `background` in the given appearance.
    static func foreground(on background: Color, candidates: [Color], scheme: ColorScheme) -> Color {
        #if canImport(UIKit)
        let index = bestIndex(
            on: rgb(of: background, scheme: scheme),
            candidates: candidates.map { rgb(of: $0, scheme: scheme) }
        )
        return candidates[index]
        #else
        return candidates[0]
        #endif
    }
}
