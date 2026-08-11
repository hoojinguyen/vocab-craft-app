import SwiftUI

public struct VocabularyView: View {
    @State private var searchText = ""
    @State private var selectedFilter = "Tất cả"
    @State private var selectedTab = 0 // 0: Kho từ cá nhân, 1: Bộ từ chủ đề
    @State private var expandedWordId: Int64? = 1 // Expand first word by default
    @State private var wordItems: [WordItem] = WordItem.mockData
    @State private var selectedDeckId: String? = nil
    @State private var selectedDrillWord: WordItem? = nil
    private let ttsService: TextToSpeechProtocol

    private let filterOptions = ["Tất cả", "Cần ôn ⚡", "Đã thuộc ⭐5", "A1-A2", "B1-B2", "C1-C2"]

    @MainActor
    public init(ttsService: TextToSpeechProtocol? = nil) {
        self.ttsService = ttsService ?? TextToSpeechService()
    }

    public var body: some View {
        ZStack {
            Color.vocabCanvas
                .ignoresSafeArea()

            if let deckId = selectedDeckId {
                TopicDeckDetailView(
                    deckId: deckId,
                    onBack: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedDeckId = nil
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
            } else {
                VStack(spacing: 14) {
                    // Segmented Switch (Kho Từ Cá Nhân vs Bộ Từ Chủ Đề)
                    HStack(spacing: 0) {
                        segmentedTabButton(title: "Kho Từ Cá Nhân", tabIndex: 0)
                        segmentedTabButton(title: "Bộ Từ Chủ Đề", tabIndex: 1)
                    }
                    .padding(4)
                    .background(Color.vocabSurfaceCard)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.vocabHairline, lineWidth: 1.5)
                    )
                    .padding(.horizontal)
                    .padding(.top, 12)

                    if selectedTab == 0 {
                        // Quick Search Bar
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color.vocabMuted)
                                .font(.system(size: 14, weight: .semibold))
                            TextField("Tìm kiếm từ vựng, nghĩa...", text: $searchText)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.vocabInk)
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color.vocabMuted)
                                        .font(.system(size: 14))
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 40)
                        .background(Color.vocabSurfaceCard)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.vocabHairline, lineWidth: 1.2)
                        )
                        .padding(.horizontal)

                        // Filter Pills (Horizontal Scroll with Dynamic Counts)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(filterOptions, id: \.self) { filter in
                                    filterPill(filter)
                                }
                            }
                            .padding(.horizontal)
                        }

                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 12) {
                                // Bento Summary Strip
                                VocabularySummaryCard(
                                    totalWords: wordItems.count * 473,
                                    srsRetentionPercentage: 0.85,
                                    dueCount: 24
                                )

                                // Word Accordion Cards List
                                VStack(spacing: 10) {
                                    ForEach(filteredWords) { item in
                                        WordAccordionCard(
                                            item: item,
                                            isExpanded: expandedWordId == item.id,
                                            onTap: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    if expandedWordId == item.id {
                                                        expandedWordId = nil
                                                    } else {
                                                        expandedWordId = item.id
                                                    }
                                                }
                                            },
                                            onAudioTap: {
                                                ttsService.speak(text: item.lemma)
                                            },
                                            onDrillTap: {
                                                selectedDrillWord = item
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.bottom, 90) // Clear floating tab bar
                        }
                    } else {
                        // Topic Decks Grid Tab
                        ScrollView(.vertical, showsIndicators: false) {
                            TopicDecksGridView(onDeckSelected: { deckId in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedDeckId = deckId
                                }
                            })
                            .padding(.top, 4)
                            .padding(.bottom, 90)
                        }
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
            }
        }
        .sheet(item: $selectedDrillWord) { targetWord in
            QuickReflexDrillSheetView(
                targetWord: targetWord,
                allWords: wordItems,
                onComplete: { updatedMastery in
                    if let idx = wordItems.firstIndex(where: { $0.id == targetWord.id }) {
                        wordItems[idx].masteryLevel = updatedMastery
                    }
                }
            )
        }
    }

    private var filteredWords: [WordItem] {
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

    private func filterCount(for title: String) -> Int {
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

    private func segmentedTabButton(title: String, tabIndex: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                selectedTab = tabIndex
            }
        }) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(selectedTab == tabIndex ? Color.vocabInk : Color.vocabMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(selectedTab == tabIndex ? Color.vocabInk.opacity(0.08) : Color.clear)
                .cornerRadius(12)
                .contentShape(Rectangle())
        }
        .buttonStyle(BentoCardButtonStyle())
        .sensoryFeedback(.selection, trigger: selectedTab)
    }

    private func filterPill(_ title: String) -> some View {
        let isSelected = selectedFilter == title
        let count = filterCount(for: title)
        let displayTitle = "\(title) (\(count))"

        return Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                selectedFilter = title
            }
        }) {
            Text(displayTitle)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? Color.vocabCanvas : Color.vocabInk)
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(isSelected ? Color.vocabInk : Color.vocabSurfaceCard)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isSelected ? Color.clear : Color.vocabHairline, lineWidth: 1.5)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(BentoCardButtonStyle())
        .sensoryFeedback(.selection, trigger: selectedFilter)
    }
}
