import SwiftUI

/// Main Vocabulary Hub view integrating the Personal Vault tab and the Topic Decks tab.
/// Uses a clean Apple HIG segmented bar, Bento card design system, and unified navigation.
public struct VocabularyView: View {
    @Environment(\.appContainer) private var appContainer
    @State private var vaultVM: PersonalVaultViewModel?
    @State private var legacyVM: VocabularyViewModel?
    @State private var selectedTab: Int = 0
    @State private var selectedDeckId: String?
    @State private var selectedStage: SubTopicStage?
    @State private var activeChallengeStage: SubTopicStage?
    @State private var isPresentingSmartReview: Bool = false
    @State private var expandedWordId: Int64?

    @MainActor
    public init(
        vaultViewModel: PersonalVaultViewModel? = nil,
        viewModel: VocabularyViewModel? = nil
    ) {
        self._vaultVM = State(initialValue: vaultViewModel)
        self._legacyVM = State(initialValue: viewModel)
    }

    private var activeVaultVM: PersonalVaultViewModel {
        if let vm = vaultVM {
            return vm
        }
        let vm = appContainer.makePersonalVaultViewModel()
        return vm
    }

    public var body: some View {
        let currentVaultVM = activeVaultVM
        @Bindable var bindableVaultVM = currentVaultVM

        ZStack {
            Color.vocabCanvas
                .ignoresSafeArea()

            if let deckId = selectedDeckId {
                TopicRoadmapView(
                    deckId: deckId,
                    onBack: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedDeckId = nil
                        }
                    },
                    onStageSelected: { stage in
                        selectedStage = stage
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

                    if selectedTab == 0 {
                        // Personal Vault Tab
                        personalVaultTabContent(vaultVM: currentVaultVM, bindableVM: bindableVaultVM)
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
        .sheet(isPresented: $isPresentingSmartReview) {
            SmartReviewSessionView(
                viewModel: appContainer.makeSmartReviewViewModel(
                    weakWords: currentVaultVM.words.filter(\.needsReview)
                ),
                onDismiss: {
                    isPresentingSmartReview = false
                    Task {
                        await currentVaultVM.loadData()
                    }
                }
            )
        }
        .sheet(item: $selectedStage) { stage in
            StagePreviewSheet(
                stage: stage,
                onStartChallenge: {
                    let challengeStage = stage
                    selectedStage = nil
                    activeChallengeStage = challengeStage
                },
                onClose: {
                    selectedStage = nil
                },
                ttsService: appContainer.ttsService
            )
        }
        .sheet(item: $activeChallengeStage) { stage in
            StageChallengeView(
                viewModel: appContainer.makeStageChallengeViewModel(stage: stage),
                onClose: {
                    activeChallengeStage = nil
                    Task {
                        await currentVaultVM.loadData()
                    }
                },
                onCompleted: { _ in
                    Task {
                        await currentVaultVM.loadData()
                    }
                }
            )
        }
        .task {
            if vaultVM == nil {
                vaultVM = appContainer.makePersonalVaultViewModel()
            }
            if let vm = vaultVM, vm.words.isEmpty && !vm.isLoading {
                await vm.loadData()
            }
        }
    }

    // MARK: - Personal Vault Content
    @ViewBuilder
    private func personalVaultTabContent(
        vaultVM: PersonalVaultViewModel,
        bindableVM: PersonalVaultViewModel
    ) -> some View {
        VStack(spacing: 12) {
            // Search Bar and Filter Pills
            PersonalSearchFilterBar(
                searchQuery: Binding(
                    get: { bindableVM.searchQuery },
                    set: { bindableVM.setSearchQuery($0) }
                ),
                selectedFilter: vaultVM.selectedFilter,
                metrics: vaultVM.metrics,
                onFilterChanged: { filter in
                    vaultVM.setFilter(filter)
                }
            )

            // Scrollable List of Hero Card and Clean Word Cards
            List {
                PersonalVaultHeroCard(
                    metrics: vaultVM.metrics,
                    onStartSmartReview: {
                        isPresentingSmartReview = true
                    }
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                if vaultVM.isLoading && vaultVM.words.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding(.vertical, 20)
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                } else if vaultVM.words.isEmpty {
                    emptyVaultView
                        .listRowInsets(EdgeInsets(top: 20, leading: 16, bottom: 20, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(vaultVM.words) { word in
                        CleanWordCardView(
                            word: word,
                            isExpanded: expandedWordId == word.id,
                            onTap: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    if expandedWordId == word.id {
                                        expandedWordId = nil
                                    } else {
                                        expandedWordId = word.id
                                    }
                                }
                            },
                            onAudioTap: {
                                vaultVM.playAudio(for: word)
                            },
                            onBookmarkTap: {
                                Task {
                                    await vaultVM.toggleBookmark(wordId: word.id)
                                }
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                Task {
                                    await vaultVM.toggleBookmark(wordId: word.id)
                                }
                            } label: {
                                Label(
                                    word.isBookmarked ? "Bỏ ghim" : "Ghim từ",
                                    systemImage: word.isBookmarked ? "bookmark.slash.fill" : "bookmark.fill"
                                )
                            }
                            .tint(Color.vocabPeach)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .padding(.bottom, 60)
            .refreshable {
                await vaultVM.loadData()
            }
        }
    }

    // MARK: - Empty Vault View
    private var emptyVaultView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray.fill")
                .font(.system(size: 36))
                .foregroundColor(Color.vocabMuted.opacity(0.6))
                .padding(.top, 20)

            Text("Chưa có từ vựng nào")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.vocabInk)

            Text("Hoàn thành các chặng trong Bộ Từ Chủ Đề để nạp từ vựng mới vào kho cá nhân của bạn.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.vocabMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.vocabHairline, lineWidth: 1)
        )
    }

    // MARK: - Segmented Tab Button
    private func segmentedTabButton(title: LocalizedStringKey, tabIndex: Int) -> some View {
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
}
