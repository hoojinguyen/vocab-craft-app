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
    @State private var isSearchHiddenByScroll: Bool = false
    @State private var isScrolledPastHeader: Bool = false
    @State private var measuredHeaderHeight: CGFloat = 50
    @State private var lastScrollOffset: CGFloat = 0
    @State private var searchText: String = ""
    @State private var isPresentingPracticeSelection: Bool = false
    @State private var activeDrillViewModel: MixedReflexDrillViewModel?
    @State private var isPresentingSmartReview: Bool = false

    @MainActor
    public init(
        vaultViewModel: PersonalVaultViewModel? = nil,
        viewModel: VocabularyViewModel? = nil,
        isSearchHiddenByScroll: Bool = false,
        isScrolledPastHeader: Bool = false
    ) {
        self._vaultVM = State(initialValue: vaultViewModel)
        self._legacyVM = State(initialValue: viewModel)
        self._isSearchHiddenByScroll = State(initialValue: isSearchHiddenByScroll)
        self._isScrolledPastHeader = State(initialValue: isScrolledPastHeader)
        self._searchText = State(initialValue: vaultViewModel?.searchQuery ?? "")
    }

    // MARK: - Testing Inspection Accessors
    internal var isSearchHiddenByScrollForTesting: Bool { isSearchHiddenByScroll }
    internal var isScrolledPastHeaderForTesting: Bool { isScrolledPastHeader }
    internal var measuredHeaderHeightForTesting: CGFloat { measuredHeaderHeight }

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
                            // 1. Page Header at the top of the scroll view (outside LazyVStack, never virtualized/recycled)
                            CraftPageHeader(
                                AppStrings.Vault.title,
                                alignment: .leading,
                                enableScrollFade: true
                            )
                            .background(
                                GeometryReader { proxy in
                                    Color.clear
                                        .preference(
                                            key: HeaderOffsetPreferenceKey.self,
                                            value: proxy.frame(in: .named("vocabScroll")).minY
                                        )
                                        .preference(
                                            key: HeaderHeightPreferenceKey.self,
                                            value: proxy.size.height
                                        )
                                }
                            )
                            .padding(.bottom, theme.spacing.md)

                            // 2. Pinned Search & Filter Section inside LazyVStack
                            LazyVStack(spacing: theme.spacing.md, pinnedViews: [.sectionHeaders]) {
                                Section {
                                    VStack(spacing: theme.spacing.md) {
                                        // Practice button — scrolls with content
                                        CraftButton(
                                            verbatim: AppStrings.Vault.actionPracticeText,
                                            variant: .tactile,
                                            size: .lg,
                                            isFullWidth: true,
                                            action: {
                                                if currentVaultVM.selectedWordIds.isEmpty {
                                                    _ = currentVaultVM.smartPickWords()
                                                }
                                                isPresentingPracticeSelection = true
                                            }
                                        )
                                        .disabled(currentVaultVM.vaultWords.isEmpty)
                                        .padding(.horizontal, theme.spacing.base)

                                        // Main Word List / Empty State
                                        wordListContent(vaultVM: currentVaultVM)
                                    }
                                } header: {
                                    VStack(spacing: 0) {
                                        // Expandable Search Bar — sticky, auto-hides on scroll direction
                                        if !isSearchHiddenByScroll {
                                            CraftSearchBar(
                                                text: $searchText,
                                                placeholder: AppStrings.Vault.searchPlaceholder,
                                                size: .md,
                                                style: .flat,
                                                onCancel: {
                                                    withAnimation(theme.animations.springSnappy) {
                                                        searchText = ""
                                                        currentVaultVM.setSearchQuery("")
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
                    .onPreferenceChange(HeaderHeightPreferenceKey.self) { height in
                        if height > 0 && abs(measuredHeaderHeight - height) > 1 {
                            measuredHeaderHeight = height
                        }
                    }
                    .onPreferenceChange(HeaderOffsetPreferenceKey.self) { offset in
                        let threshold = -max(measuredHeaderHeight, 20)
                        let shouldBePastHeader = offset < threshold
                        if isScrolledPastHeader != shouldBePastHeader {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isScrolledPastHeader = shouldBePastHeader
                            }
                        }

                        let delta = offset - lastScrollOffset

                        if abs(delta) > 2 {
                            if delta < -2 {
                                // Scroll Down: Hide search bar to save space
                                if !isSearchHiddenByScroll && searchText.isEmpty {
                                    withAnimation(theme.animations.springSnappy) {
                                        isSearchHiddenByScroll = true
                                    }
                                }
                            } else if delta > 2 {
                                // Scroll Up: Reveal search bar
                                if isSearchHiddenByScroll {
                                    withAnimation(theme.animations.springSnappy) {
                                        isSearchHiddenByScroll = false
                                    }
                                }
                            }
                        }

                        // Safety check: if text is not empty, always show
                        if !searchText.isEmpty && isSearchHiddenByScroll {
                            withAnimation(theme.animations.springSnappy) {
                                isSearchHiddenByScroll = false
                            }
                        }

                        lastScrollOffset = offset
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
            #if os(iOS)
            .fullScreenCover(item: $activeDrillViewModel) { drillVM in
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
            #else
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
            #endif
            .sheet(isPresented: $isPresentingPracticeSelection) {
                PracticeSelectionView(
                    vaultViewModel: currentVaultVM,
                    onStartPractice: { selectedWords in
                        isPresentingPracticeSelection = false
                        let drillVM = appContainer.makeMixedReflexDrillViewModel(
                            selectedWords: selectedWords,
                            allowSpeakingSkip: true
                        )
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
            isSearchHiddenByScroll = false
        case "personal-search-empty":
            searchText = "không_tìm_thấy_từ"
            vm.setSearchQuery("không_tìm_thấy_từ")
            isSearchHiddenByScroll = false
        default:
            break
        }
    }

    private func applyAutomationPresentation(state: String) {
        if state == "practice-selection" {
            isPresentingPracticeSelection = true
        } else if state == "practice-selection-selected" {
            _ = vaultVM?.smartPickWords()
            isPresentingPracticeSelection = true
        } else if state == "practice-countdown" || state == "practice-drill" {
            if let words = vaultVM?.smartPickWords(), !words.isEmpty {
                let drillVM = appContainer.makeMixedReflexDrillViewModel(
                    selectedWords: words,
                    allowSpeakingSkip: true
                )
                activeDrillViewModel = drillVM
            }
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

// MARK: - Header Height Preference Key

/// Tracks dynamic rendered height of the page header (adapting to Dynamic Type accessibility scaling).
struct HeaderHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 50

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        if next > 0 {
            value = next
        }
    }
}
