import Foundation
import SwiftUI

/// Type-safe filter options replacing magic strings.
public enum VocabularyFilter: String, CaseIterable, Equatable, Sendable {
    case all = "Tất cả"
    case needsReview = "Cần ôn ⚡"
    case mastered = "Đã thuộc ⭐5"
    case a1a2 = "A1-A2"
    case b1b2 = "B1-B2"
    case c1c2 = "C1-C2"
}

@MainActor
@Observable
public final class VocabularyViewModel {
    public var searchText = ""
    public var selectedFilter: VocabularyFilter = .all
    public var selectedTab = 0 // 0: Kho từ cá nhân, 1: Bộ từ chủ đề
    public var expandedWordId: Int64? = 1 // Expand first word by default
    public var wordItems: [WordItem] = WordItem.mockData
    public var selectedDeckId: String? = nil
    public var selectedDrillWord: WordItem? = nil

    private let fetchVocabularyUseCase: FetchVocabularyUseCaseProtocol?
    public let ttsService: TextToSpeechProtocol?

    public init(
        fetchVocabularyUseCase: FetchVocabularyUseCaseProtocol? = nil,
        ttsService: TextToSpeechProtocol? = nil
    ) {
        self.fetchVocabularyUseCase = fetchVocabularyUseCase
        self.ttsService = ttsService
    }

    public var filteredWords: [WordItem] {
        var result = wordItems
        if !searchText.isEmpty {
            result = result.filter { $0.lemma.localizedCaseInsensitiveContains(searchText) || $0.definition.localizedCaseInsensitiveContains(searchText) }
        }
        switch selectedFilter {
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

    public func filterCount(for filter: VocabularyFilter) -> Int {
        switch filter {
        case .all: return wordItems.count
        case .needsReview: return wordItems.filter { $0.masteryLevel < 3 }.count
        case .mastered: return wordItems.filter { $0.masteryLevel >= 4 }.count
        case .a1a2: return wordItems.filter { $0.cefrLevel == "A1" || $0.cefrLevel == "A2" }.count
        case .b1b2: return wordItems.filter { $0.cefrLevel == "B1" || $0.cefrLevel == "B2" }.count
        case .c1c2: return wordItems.filter { $0.cefrLevel == "C1" || $0.cefrLevel == "C2" }.count
        }
    }

    /// Backward-compatible overload for string-based filter counts (used by existing views).
    public func filterCount(for title: String) -> Int {
        guard let filter = VocabularyFilter(rawValue: title) else { return wordItems.count }
        return filterCount(for: filter)
    }
}
