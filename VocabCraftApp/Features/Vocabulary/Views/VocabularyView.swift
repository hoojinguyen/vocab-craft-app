import CraftUIKit
import SwiftUI

/// Redesigned Vocabulary Vault (Kho từ) single view.
/// Features a native search bar, 3-tab segmented category filter (Chưa thuộc, Đã thuộc, Đã lưu),
/// top review action button, active recall word rows, and a bottom detail sheet.
public struct VocabularyView: View {
    @Environment(\.appContainer) private var appContainer
    @Environment(\.craftTheme) private var theme

    @State private var vaultVM: PersonalVaultViewModel?
    @State private var legacyVM: VocabularyViewModel?
    @State private var isSearchVisible: Bool = false
    @State private var isScrolledPastHeader: Bool = false
    @State private var searchText: String = ""
    @State private var isPresentingPracticeSelection: Bool = false
    @State private var activeDrillViewModel: MixedReflexDrillViewModel?
    @State private var isPresentingSmartReview: Bool = false

    @MainActor
    public init(
        vaultViewModel: PersonalVaultViewModel? = nil,
        viewModel: VocabularyViewModel? = nil,
        isSearchVisible: Bool = false,
        isScrolledPastHeader: Bool = false
    ) {
        self._vaultVM = State(initialValue: vaultViewModel)
        self._legacyVM = State(initialValue: viewModel)
        self._isSearchVisible = State(initialValue: isSearchVisible)
        self._isScrolledPastHeader = State(initialValue: isScrolledPastHeader)
        self._searchText = State(initialValue: vaultViewModel?.searchQuery ?? "")
    }

    private static let headerScrollThreshold: CGFloat = -50

    // MARK: - Testing Inspection Accessors
    internal var isSearchVisibleForTesting: Bool { isSearchVisible }
    internal var isScrolledPastHeaderForTesting: Bool { isScrolledPastHeader }

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

        NavigationStack {
            ZStack {
                theme.colors.canvasBackground
                    .ignoresSafeArea()

                if currentVaultVM.isLoading && currentVaultVM.vaultWords.isEmpty {
                    VStack {
                        Spacer()
                        CraftSpinner(size: .lg, color: theme.colors.brandPrimary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Non-virtualized scroll anchor at root of scroll view
                            Color.clear
                                .frame(height: 0)
                                .background(
                                    GeometryReader { proxy in
                                        Color.clear.preference(
                                            key: HeaderOffsetPreferenceKey.self,
                                            value: proxy.frame(in: .named("vocabScroll")).minY
                                        )
                                    }
                                )

                            LazyVStack(spacing: theme.spacing.md, pinnedViews: [.sectionHeaders]) {
                                // 1. Page Header at the top of the scroll view
                                CraftPageHeader(
                                    AppStrings.Vault.title,
                                    alignment: .leading,
                                    enableScrollFade: true
                                ) {
                                    CraftIconButton(
                                        iconName: (isSearchVisible || isScrolledPastHeader) ? "magnifyingglass.circle.fill" : "magnifyingglass",
                                        size: .md,
                                        shape: .circle,
                                        variant: (isSearchVisible || isScrolledPastHeader) ? .filled : .subtle,
                                        accessibilityLabel: AppStrings.Vault.searchToggleA11y,
                                        action: {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                isSearchVisible.toggle()
                                            }
                                        }
                                    )
                                }

                                // 2. Pinned Search & Filter Section
                                Section {
                                    VStack(spacing: theme.spacing.md) {
                                        // Practice button — scrolls with content
                                        CraftButton(
                                            verbatim: AppStrings.Vault.actionPracticeText,
                                            variant: .tactile,
                                            size: .lg,
                                            isFullWidth: true,
                                            action: {
                                                let words = currentVaultVM.prepareReviewWords()
                                                guard !words.isEmpty else { return }
                                                activeDrillViewModel = appContainer.makeMixedReflexDrillViewModel(selectedWords: words)
                                            }
                                        )
                                        .disabled(currentVaultVM.vaultWords.isEmpty)
                                        .padding(.horizontal, theme.spacing.base)

                                        // Main Word List / Empty State
                                        wordListContent(vaultVM: currentVaultVM)
                                    }
                                } header: {
                                    VStack(spacing: 0) {
                                        // Expandable Search Bar — sticky when visible or scrolled past header
                                        if isSearchVisible || isScrolledPastHeader {
                                            CraftSearchBar(
                                                text: $searchText,
                                                placeholder: AppStrings.Vault.searchPlaceholder,
                                                size: .md,
                                                style: .flat,
                                                onCancel: {
                                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                        searchText = ""
                                                        currentVaultVM.setSearchQuery("")
                                                        isSearchVisible = false
                                                    }
                                                }
                                            )
                                            .padding(.horizontal, theme.spacing.base)
                                            .padding(.vertical, theme.spacing.xs)
                                            .transition(.move(edge: .top).combined(with: .opacity))
                                        }

                                        // 3-Tab Segmented Filter — always sticky
                                        CraftSegmentedControl(
                                            selection: Binding(
                                                get: { bindableVaultVM.vaultTabFilter },
                                                set: { bindableVaultVM.setVaultFilter($0) }
                                            ),
                                            options: vaultSegmentOptions(metrics: currentVaultVM.metrics),
                                            style: .tactile3D
                                        )
                                        .padding(.horizontal, theme.spacing.base)
                                        .padding(.vertical, theme.spacing.xs)
                                    }
                                    .background(
                                        theme.colors.canvasBackground
                                            .craftShadow(isScrolledPastHeader ? theme.shadows.sm : CraftShadow(color: .clear, radius: 0))
                                    )
                                }
                            }
                        }
                        .padding(.top, theme.spacing.xs)
                        .padding(.bottom, theme.spacing.xxl + 40)
                    }
                    .coordinateSpace(.named("vocabScroll"))
                    .onPreferenceChange(HeaderOffsetPreferenceKey.self) { offset in
                        let shouldBePastHeader = offset < Self.headerScrollThreshold
                        if isScrolledPastHeader != shouldBePastHeader {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isScrolledPastHeader = shouldBePastHeader
                            }
                        }
                    }
                    .refreshable {
                        await currentVaultVM.loadData()
                    }
                    .task(id: searchText) {
                        if searchText.isEmpty {
                            if !currentVaultVM.searchQuery.isEmpty {
                                currentVaultVM.setSearchQuery("")
                            }
                            return
                        }
                        try? await Task.sleep(for: .milliseconds(300))
                        guard !Task.isCancelled else { return }
                        currentVaultVM.setSearchQuery(searchText)
                    }
                }
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
            .sheet(item: $bindableVaultVM.selectedWordForDetail) { word in
                VaultWordDetailSheet(
                    word: word,
                    viewModel: currentVaultVM,
                    onPlayAudio: {
                        currentVaultVM.playAudio(for: word)
                    },
                    onToggleBookmark: {
                        Task {
                            await currentVaultVM.toggleBookmark(wordId: word.id)
                        }
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
            .sheet(isPresented: $isPresentingPracticeSelection) {
                PracticeSelectionView(
                    vaultViewModel: currentVaultVM,
                    onStartPractice: { selectedWords in
                        isPresentingPracticeSelection = false
                        let drillVM = appContainer.makeMixedReflexDrillViewModel(selectedWords: selectedWords)
                        activeDrillViewModel = drillVM
                    },
                    onClose: {
                        isPresentingPracticeSelection = false
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
                await SampleVaultDataSeeder.seedIfEmpty(repository: appContainer.userProgressRepository)
                if let vm = vaultVM, vm.vaultWords.isEmpty && !vm.isLoading {
                    await vm.loadData()
                }
            }
        }
    }

    // MARK: - Word List Content
    @ViewBuilder
    private func wordListContent(vaultVM: PersonalVaultViewModel) -> some View {
        if vaultVM.vaultWords.isEmpty {
            emptyStateView(vaultVM: vaultVM)
                .padding(.top, theme.spacing.xl)
        } else {
            LazyVStack(spacing: theme.spacing.sm) {
                ForEach(vaultVM.vaultWords) { word in
                    VaultWordRowView(
                        word: word,
                        onTap: {
                            vaultVM.selectWordForDetail(word)
                        },
                        onBookmarkTap: {
                            Task {
                                await vaultVM.toggleBookmark(wordId: word.id)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.top, theme.spacing.xs)
        }
    }

    // MARK: - Contextual Empty State View
    @ViewBuilder
    private func emptyStateView(vaultVM: PersonalVaultViewModel) -> some View {
        if !vaultVM.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            CraftEmptyState(
                symbol: .search,
                title: AppStrings.Vault.emptySearchNoResults
            )
        } else {
            switch vaultVM.vaultTabFilter {
            case .notMastered:
                CraftEmptyState(
                    symbol: .study,
                    title: AppStrings.Vault.emptyNotMastered
                )
            case .mastered:
                CraftEmptyState(
                    symbol: .mastery,
                    title: AppStrings.Vault.emptyMastered
                )
            case .bookmarked:
                CraftEmptyState(
                    symbol: .bookmark,
                    title: AppStrings.Vault.emptyBookmarked
                )
            }
        }
    }

    // MARK: - Segment Options Helper
    private func vaultSegmentOptions(metrics: PersonalVaultMetrics) -> [CraftSegmentOption<VaultTabFilter>] {
        [
            CraftSegmentOption(.notMastered, title: AppStrings.Vault.filterNotMasteredTitle, count: metrics.unmasteredCount),
            CraftSegmentOption(.mastered, title: AppStrings.Vault.filterMasteredTitle, count: metrics.masteredCount),
            CraftSegmentOption(.bookmarked, title: AppStrings.Vault.filterBookmarkedTitle, count: metrics.bookmarkedCount)
        ]
    }

    // MARK: - Automation State Setup
    private func setupAutomationState() async {
        let args = ProcessInfo.processInfo.arguments
        guard let stateIdx = args.firstIndex(of: "-vocab-state"), stateIdx + 1 < args.count else { return }
        let state = args[stateIdx + 1]

        if state == "personal-empty" {
            vaultVM?.deselectAll()
            return
        }

        await seedSampleUserProgress()
        if let vm = vaultVM { await vm.loadData() }

        applyAutomationFilterAndSearch(state: state)
        applyAutomationPresentation(state: state)
    }

    private func applyAutomationFilterAndSearch(state: String) {
        guard let vm = vaultVM else { return }
        switch state {
        case "personal-filter-needs-review", "filter-not-mastered":
            vm.setVaultFilter(.notMastered)
        case "personal-filter-mastered":
            vm.setVaultFilter(.mastered)
        case "personal-filter-bookmarked":
            vm.setVaultFilter(.bookmarked)
        case "personal-search-match":
            searchText = "resilience"
            vm.setSearchQuery("resilience")
            isSearchVisible = true
        case "personal-search-empty":
            searchText = "không_tìm_thấy_từ"
            vm.setSearchQuery("không_tìm_thấy_từ")
            isSearchVisible = true
        default:
            break
        }
    }

    private func applyAutomationPresentation(state: String) {
        if state == "practice-selection" {
            isPresentingPracticeSelection = true
        } else if state.starts(with: "smart-review") {
            isPresentingSmartReview = true
        }
    }

    private func seedSampleUserProgress() async {
        await SampleVaultDataSeeder.seed(repository: appContainer.userProgressRepository)
    }
}

// MARK: - Header Offset Preference Key

/// Tracks vertical scroll offset of the page header relative to the scroll container.
struct HeaderOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
