import Foundation

/// Domain service providing pure business logic for filtering vocabulary items.
public struct VocabularyFilterService: Sendable {
    public init() {}

    /// Filters a list of word items by search query and category filter.
    public func filter(
        words: [WordItem],
        filter: VocabularyFilter,
        searchText: String
    ) -> [WordItem] {
        var result = words
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result = result.filter { word in
                word.lemma.localizedCaseInsensitiveContains(searchText)
                    || word.definition.localizedCaseInsensitiveContains(searchText)
            }
        }
        switch filter {
        case .all:
            break
        case .needsReview:
            result = result.filter { $0.masteryLevel < 3 }
        case .mastered:
            result = result.filter { $0.masteryLevel >= 4 }
        case .a1a2:
            result = result.filter { $0.cefrLevel == "A1" || $0.cefrLevel == "A2" }
        case .b1b2:
            result = result.filter { $0.cefrLevel == "B1" || $0.cefrLevel == "B2" }
        case .c1c2:
            result = result.filter { $0.cefrLevel == "C1" || $0.cefrLevel == "C2" }
        }
        return result
    }

    /// Counts how many words match a given category filter.
    public func countMatches(
        in words: [WordItem],
        for filter: VocabularyFilter
    ) -> Int {
        switch filter {
        case .all:
            return words.count
        case .needsReview:
            return words.filter { $0.masteryLevel < 3 }.count
        case .mastered:
            return words.filter { $0.masteryLevel >= 4 }.count
        case .a1a2:
            return words.filter { $0.cefrLevel == "A1" || $0.cefrLevel == "A2" }.count
        case .b1b2:
            return words.filter { $0.cefrLevel == "B1" || $0.cefrLevel == "B2" }.count
        case .c1c2:
            return words.filter { $0.cefrLevel == "C1" || $0.cefrLevel == "C2" }.count
        }
    }
}
