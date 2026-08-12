import Foundation
import SwiftUI

@Observable
public final class VocabularyViewModel {
    public var searchText = ""
    public var selectedFilter = "Tất cả"
    public var selectedTab = 0 // 0: Kho từ cá nhân, 1: Bộ từ chủ đề
    public var expandedWordId: Int64? = 1 // Expand first word by default
    public var wordItems: [WordItem] = WordItem.mockData
    public var selectedDeckId: String? = nil
    public var selectedDrillWord: WordItem? = nil

    public init() {}

    public var filteredWords: [WordItem] {
        var result = wordItems
        if !searchText.isEmpty {
            result = result.filter { $0.lemma.localizedCaseInsensitiveContains(searchText) || $0.definition.localizedCaseInsensitiveContains(searchText) }
        }
        if selectedFilter == "A1-A2" {
            result = result.filter { $0.cefrLevel == "A1" || $0.cefrLevel == "A2" }
        } else if selectedFilter == "B1-B2" {
            result = result.filter { $0.cefrLevel == "B1" || $0.cefrLevel == "B2" }
        } else if selectedFilter == "C1-C2" {
            result = result.filter { $0.cefrLevel == "C1" || $0.cefrLevel == "C2" }
        } else if selectedFilter == "Cần ôn ⚡" {
            result = result.filter { $0.masteryLevel < 3 }
        } else if selectedFilter == "Đã thuộc ⭐5" {
            result = result.filter { $0.masteryLevel >= 4 }
        }
        return result
    }

    public func filterCount(for title: String) -> Int {
        switch title {
        case "Tất cả": return wordItems.count
        case "Cần ôn ⚡": return wordItems.filter { $0.masteryLevel < 3 }.count
        case "Đã thuộc ⭐5": return wordItems.filter { $0.masteryLevel >= 4 }.count
        case "A1-A2": return wordItems.filter { $0.cefrLevel == "A1" || $0.cefrLevel == "A2" }.count
        case "B1-B2": return wordItems.filter { $0.cefrLevel == "B1" || $0.cefrLevel == "B2" }.count
        case "C1-C2": return wordItems.filter { $0.cefrLevel == "C1" || $0.cefrLevel == "C2" }.count
        default: return wordItems.count
        }
    }
}
