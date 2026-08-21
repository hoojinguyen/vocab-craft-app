import SwiftUI

/// Redesigned Vocabulary Hub (Kho từ) single view.
/// Features a native search bar, 3-tab segmented category filter (Chưa thuộc, Đã thuộc, Đã lưu),
/// big 'LUYỆN TẬP' CTA button, top carousel flashcards with horizontal paging,
/// and a clean LazyVStack word list with expandable accordion cards.
public struct VocabularyView: View {
    @Environment(\.appContainer) private var appContainer
    @State private var vaultVM: PersonalVaultViewModel?
    @State private var legacyVM: VocabularyViewModel?
    @State private var isPresentingPracticeSelection: Bool = false
    @State private var activeDrillViewModel: MixedReflexDrillViewModel?
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

            VStack(spacing: 0) {
                // Header & Search Bar
                headerAndSearchBar(bindableVM: bindableVaultVM)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 6)

                // 3-Tab Segmented Filter (Chưa thuộc / Đã thuộc / Đã lưu)
                segmentedTabControl(vaultVM: currentVaultVM)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)

                // Big 'LUYỆN TẬP' CTA Button
                practiceCTAButton(vaultVM: currentVaultVM)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 10)

                // Main Scrollable Content (Carousel + Word List)
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 14) {
                        // Top Carousel Flashcard View
                        if !currentVaultVM.vaultWords.isEmpty {
                            TopCarouselFlashcardView(
                                words: Array(currentVaultVM.vaultWords.prefix(10)),
                                onAudioTap: { word in
                                    currentVaultVM.playAudio(for: word)
                                },
                                onBookmarkTap: { word in
                                    Task {
                                        await currentVaultVM.toggleBookmark(wordId: word.id)
                                    }
                                },
                                onWordSelected: { word in
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        expandedWordId = (expandedWordId == word.id) ? nil : word.id
                                    }
                                }
                            )
                        }

                        // Word List Section
                        wordListSection(vaultVM: currentVaultVM)
                    }
                    .padding(.bottom, 90)
                }
                .refreshable {
                    await currentVaultVM.loadData()
                }
            }
        }
        .sheet(isPresented: $isPresentingPracticeSelection) {
            PracticeSelectionView(
                vaultViewModel: currentVaultVM,
                onStartPractice: { selectedWords in
                    isPresentingPracticeSelection = false
                    let drillVM = MixedReflexDrillViewModel(
                        selectedWords: selectedWords,
                        queueUseCase: GenerateMixedReflexQueueUseCase(),
                        recordAttemptUseCase: RecordMixedDrillAttemptUseCase(
                            progressRepo: appContainer.userProgressRepository,
                            dataSource: appContainer.vocabularyDataSource
                        ),
                        ttsService: appContainer.ttsService
                    )
                    activeDrillViewModel = drillVM
                },
                onClose: {
                    isPresentingPracticeSelection = false
                }
            )
        }
        .sheet(item: $activeDrillViewModel) { drillVM in
            MixedReflexDrillView(
                viewModel: drillVM,
                speechService: ContinuousReflexSpeechService(),
                onFinish: {
                    activeDrillViewModel = nil
                    Task {
                        await currentVaultVM.loadData()
                    }
                }
            )
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
        .task {
            if vaultVM == nil {
                vaultVM = appContainer.makePersonalVaultViewModel()
            }
            await setupAutomationState()
            if let vm = vaultVM, vm.vaultWords.isEmpty && !vm.isLoading {
                await vm.loadData()
            }
        }
    }

    // MARK: - Header & Search Bar
    private func headerAndSearchBar(bindableVM: PersonalVaultViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Kho từ")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(Color.vocabInk)

                Spacer()
            }

            // Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.vocabMuted)
                    .font(.system(size: 14, weight: .semibold))

                TextField("Tìm kiếm từ vựng hoặc nghĩa...", text: Binding(
                    get: { bindableVM.searchQuery },
                    set: { bindableVM.setSearchQuery($0) }
                ))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.vocabInk)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif

                if !bindableVM.searchQuery.isEmpty {
                    Button(action: {
                        bindableVM.setSearchQuery("")
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.vocabMuted)
                            .font(.system(size: 15))
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 42)
            .background(Color.vocabSurfaceCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.vocabHairline, lineWidth: 1.2)
            )
        }
    }

    // MARK: - 3-Tab Segmented Filter
    private func segmentedTabControl(vaultVM: PersonalVaultViewModel) -> some View {
        HStack(spacing: 4) {
            ForEach(VaultTabFilter.allCases, id: \.self) { tab in
                let isSelected = vaultVM.vaultTabFilter == tab
                let count = tabCount(for: tab, vaultVM: vaultVM)

                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        vaultVM.setVaultFilter(tab)
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(tab.title)
                        if count > 0 {
                            Text("(\(count))")
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                        }
                    }
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? Color.vocabInk : Color.vocabMuted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(isSelected ? Color.vocabInk.opacity(0.08) : Color.clear)
                    .cornerRadius(10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .sensoryFeedback(.selection, trigger: isSelected)
            }
        }
        .padding(4)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.vocabHairline, lineWidth: 1)
        )
    }

    private func tabCount(for tab: VaultTabFilter, vaultVM: PersonalVaultViewModel) -> Int {
        switch tab {
        case .notMastered:
            return max(0, vaultVM.metrics.totalWords - vaultVM.metrics.masteredCount)
        case .mastered:
            return vaultVM.metrics.masteredCount
        case .bookmarked:
            return vaultVM.metrics.bookmarkedCount
        }
    }

    // MARK: - Big 'LUYỆN TẬP' CTA Button
    private func practiceCTAButton(vaultVM: PersonalVaultViewModel) -> some View {
        Button(action: {
            isPresentingPracticeSelection = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 17, weight: .bold))

                Text("LUYỆN TẬP PHẢN XẠ")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.vocabHeroAccent)
            .cornerRadius(16)
            .shadow(
                color: Color.vocabHeroAccent.opacity(0.28),
                radius: 8,
                x: 0,
                y: 4
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(BentoCardButtonStyle())
        .sensoryFeedback(.impact(weight: .medium), trigger: isPresentingPracticeSelection)
    }

    // MARK: - Word List Section
    @ViewBuilder
    private func wordListSection(vaultVM: PersonalVaultViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Danh sách từ vựng")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.vocabInk)

                if !vaultVM.vaultWords.isEmpty {
                    Text("\(vaultVM.vaultWords.count)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color.vocabMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.vocabSurfaceSoft)
                        .clipShape(Capsule())
                }

                Spacer()
            }
            .padding(.horizontal, 16)

            if vaultVM.isLoading && vaultVM.vaultWords.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, 30)
                    Spacer()
                }
            } else if vaultVM.vaultWords.isEmpty {
                emptyVaultView
                    .padding(.horizontal, 16)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(vaultVM.vaultWords) { word in
                        VaultWordCardView(
                            word: word,
                            isExpanded: expandedWordId == word.id,
                            onTap: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    expandedWordId = (expandedWordId == word.id) ? nil : word.id
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
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Empty State View
    private var emptyVaultView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray.fill")
                .font(.system(size: 36))
                .foregroundColor(Color.vocabMuted.opacity(0.6))
                .padding(.top, 16)

            Text("Chưa có từ vựng")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.vocabInk)

            Text("Không tìm thấy từ vựng nào trong danh mục này.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.vocabMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.vocabHairline, lineWidth: 1)
        )
    }

    // MARK: - Automation State Setup
    private func setupAutomationState() async {
        let args = ProcessInfo.processInfo.arguments
        guard let stateIdx = args.firstIndex(of: "-vocab-state"), stateIdx + 1 < args.count else { return }
        let state = args[stateIdx + 1]

        switch state {
        case "personal-empty":
            if let vm = vaultVM {
                vm.deselectAll()
            }

        case "personal-populated":
            await seedSampleUserProgress()
            if let vm = vaultVM { await vm.loadData() }

        case "personal-expanded":
            await seedSampleUserProgress()
            if let vm = vaultVM {
                await vm.loadData()
                expandedWordId = vm.vaultWords.first?.id
            }

        case "personal-filter-needs-review", "filter-not-mastered":
            await seedSampleUserProgress()
            if let vm = vaultVM {
                await vm.loadData()
                vm.setVaultFilter(.notMastered)
            }

        case "personal-filter-mastered":
            await seedSampleUserProgress()
            if let vm = vaultVM {
                await vm.loadData()
                vm.setVaultFilter(.mastered)
            }

        case "personal-filter-bookmarked":
            await seedSampleUserProgress()
            if let vm = vaultVM {
                await vm.loadData()
                vm.setVaultFilter(.bookmarked)
            }

        case "personal-search-match":
            await seedSampleUserProgress()
            if let vm = vaultVM {
                await vm.loadData()
                vm.setSearchQuery("resilience")
            }

        case "personal-search-empty":
            await seedSampleUserProgress()
            if let vm = vaultVM {
                await vm.loadData()
                vm.setSearchQuery("không_tìm_thấy_từ")
            }

        case "practice-selection":
            await seedSampleUserProgress()
            if let vm = vaultVM { await vm.loadData() }
            isPresentingPracticeSelection = true

        case "smart-review-question", "smart-review-revealed", "smart-review-completed":
            await seedSampleUserProgress()
            if let vm = vaultVM { await vm.loadData() }
            isPresentingSmartReview = true

        default:
            break
        }
    }

    private func seedSampleUserProgress() async {
        let repo = appContainer.userProgressRepository
        try? await repo.saveProgress(wordId: 1, cefrLevel: "B1", masteryLevel: 3, isBookmarked: false, needsReview: false, mistakeCount: 0, sourceDeckId: "deck_daily", sourceNodeId: "stage_daily_1")
        try? await repo.saveProgress(wordId: 2, cefrLevel: "B1", masteryLevel: 1, isBookmarked: true, needsReview: true, mistakeCount: 2, sourceDeckId: "deck_daily", sourceNodeId: "stage_daily_1")
        try? await repo.saveProgress(wordId: 3, cefrLevel: "B2", masteryLevel: 4, isBookmarked: false, needsReview: false, mistakeCount: 0, sourceDeckId: "deck_daily", sourceNodeId: "stage_daily_1")
        try? await repo.saveProgress(wordId: 4, cefrLevel: "A2", masteryLevel: 5, isBookmarked: true, needsReview: false, mistakeCount: 0, sourceDeckId: "deck_daily", sourceNodeId: "stage_daily_1")
        try? await repo.saveProgress(wordId: 5, cefrLevel: "B1", masteryLevel: 2, isBookmarked: false, needsReview: true, mistakeCount: 1, sourceDeckId: "deck_daily", sourceNodeId: "stage_daily_1")
        try? await repo.saveProgress(wordId: 6, cefrLevel: "B2", masteryLevel: 5, isBookmarked: false, needsReview: false, mistakeCount: 0, sourceDeckId: "deck_daily", sourceNodeId: "stage_daily_1")
        try? await repo.saveProgress(wordId: 7, cefrLevel: "A2", masteryLevel: 4, isBookmarked: true, needsReview: false, mistakeCount: 0, sourceDeckId: "deck_daily", sourceNodeId: "stage_daily_1")
    }
}
