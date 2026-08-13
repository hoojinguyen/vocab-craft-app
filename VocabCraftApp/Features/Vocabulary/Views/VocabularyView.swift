import SwiftUI

public struct VocabularyView: View {
    @State private var vm: VocabularyViewModel
    @Environment(\.appContainer) private var appContainer
    private let filterOptions = VocabularyFilter.allCases

    @MainActor
    public init(viewModel: VocabularyViewModel? = nil) {
        self._vm = State(initialValue: viewModel ?? VocabularyViewModel())
    }

    /// Resolved TTS service: from ViewModel injection, environment, or fallback.
    private var ttsService: TextToSpeechProtocol {
        vm.ttsService ?? appContainer.ttsService
    }

    public var body: some View {
        @Bindable var bindableVM = vm

        ZStack {
            Color.vocabCanvas
                .ignoresSafeArea()

            if let deckId = vm.selectedDeckId {
                TopicDeckDetailView(
                    deckId: deckId,
                    onBack: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            vm.selectedDeckId = nil
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
            } else {
                VStack(spacing: 14) {
                    // Segmented Switch (Kho Từ Cá Nhân vs Bộ Từ Chủ Đề)
                    HStack(spacing: 0) {
                        segmentedTabButton(title: AppStrings.Vocabulary.personalBank, tabIndex: 0)
                        segmentedTabButton(title: AppStrings.Vocabulary.topicDecks, tabIndex: 1)
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

                    if vm.selectedTab == 0 {
                        // Quick Search Bar
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color.vocabMuted)
                                .font(.system(size: 14, weight: .semibold))
                            TextField(AppStrings.Vocabulary.searchPlaceholder, text: $bindableVM.searchText)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.vocabInk)
                            if !vm.searchText.isEmpty {
                                Button(action: { vm.searchText = "" }) {
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
                        .padding(.vertical, 2)

                        List {
                            VocabularySummaryCard(
                                totalWords: vm.wordItems.count,
                                srsRetentionPercentage: 0.85,
                                dueCount: vm.filterCount(for: .needsReview)
                            )
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)

                            ForEach(vm.filteredWords) { item in
                                WordAccordionCard(
                                    item: item,
                                    isExpanded: vm.expandedWordId == item.id,
                                    onTap: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            if vm.expandedWordId == item.id {
                                                vm.expandedWordId = nil
                                            } else {
                                                vm.expandedWordId = item.id
                                            }
                                        }
                                    },
                                    onAudioTap: {
                                        ttsService.speak(text: item.lemma)
                                    },
                                    onDrillTap: {
                                        vm.selectedDrillWord = item
                                    }
                                )
                                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            vm.deleteWord(id: item.id)
                                        }
                                    } label: {
                                        Label("Xóa từ", systemImage: "trash.fill")
                                    }
                                    .tint(.red)
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            vm.toggleMastered(id: item.id)
                                        }
                                    } label: {
                                        Label(
                                            item.masteryLevel >= 5 ? "Cần ôn" : "Đã thuộc",
                                            systemImage: item.masteryLevel >= 5 ? "arrow.clockwise" : "checkmark.seal.fill"
                                        )
                                    }
                                    .tint(item.masteryLevel >= 5 ? .orange : .green)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .padding(.bottom, 60)
                    } else {
                        // Topic Decks Grid Tab
                        ScrollView(.vertical, showsIndicators: false) {
                            TopicDecksGridView(onDeckSelected: { deckId in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    vm.selectedDeckId = deckId
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
        .sheet(item: $bindableVM.selectedDrillWord) { targetWord in
            QuickReflexDrillSheetView(
                targetWord: targetWord,
                allWords: vm.wordItems,
                ttsService: appContainer.ttsService,
                sttService: appContainer.sttService,
                evaluateSRSUseCase: appContainer.evaluateSRSUseCase,
                onComplete: { updatedMastery in
                    if let idx = vm.wordItems.firstIndex(where: { $0.id == targetWord.id }) {
                        vm.wordItems[idx].masteryLevel = updatedMastery
                    }
                }
            )
        }
        .task {
            if vm.wordItems.isEmpty && !vm.isLoading {
                await vm.loadWords()
            }
        }
    }

    private func segmentedTabButton(title: LocalizedStringKey, tabIndex: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                vm.selectedTab = tabIndex
            }
        }) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(vm.selectedTab == tabIndex ? Color.vocabInk : Color.vocabMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(vm.selectedTab == tabIndex ? Color.vocabInk.opacity(0.08) : Color.clear)
                .cornerRadius(12)
                .contentShape(Rectangle())
        }
        .buttonStyle(BentoCardButtonStyle())
        .sensoryFeedback(.selection, trigger: vm.selectedTab)
    }

    private func filterPill(_ filter: VocabularyFilter) -> some View {
        let isSelected = vm.selectedFilter == filter
        let count = vm.filterCount(for: filter)

        return Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                vm.selectedFilter = filter
            }
        }) {
            HStack(spacing: 4) {
                Text(filter.title)
                Text("(\(count))")
            }
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
        .sensoryFeedback(.selection, trigger: vm.selectedFilter)
    }
}
