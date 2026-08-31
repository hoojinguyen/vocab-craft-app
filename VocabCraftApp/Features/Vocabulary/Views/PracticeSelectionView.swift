import CraftUIKit
import SwiftUI

/// Screen allowing the user to select words for a Mixed Reflex Drill practice session.
/// Features a navigation header, 3-tab segmented category filter (Chưa thuộc / Đã thuộc / Đã lưu),
/// quick "⚡️ Luyện tập nhanh" Smart Pick button, "Chọn tất cả" toggle action,
/// lazy scrollable list of selectable words with mini sensory mode indicators,
/// and a sticky bottom CTA bar anchored with `.safeAreaInset(edge: .bottom)`.
public struct PracticeSelectionView: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Bindable public var vaultViewModel: PersonalVaultViewModel

    public let onStartPractice: ([VaultWordItem]) -> Void
    public let onClose: (() -> Void)?

    public init(
        vaultViewModel: PersonalVaultViewModel,
        onStartPractice: @escaping ([VaultWordItem]) -> Void,
        onClose: (() -> Void)? = nil
    ) {
        self.vaultViewModel = vaultViewModel
        self.onStartPractice = onStartPractice
        self.onClose = onClose
    }

    private var isAllSelected: Bool {
        !vaultViewModel.vaultWords.isEmpty &&
        vaultViewModel.vaultWords.allSatisfy { vaultViewModel.selectedWordIds.contains($0.id) }
    }

    private var selectedWordsCount: Int {
        vaultViewModel.selectedWords.count
    }

    private var vaultSegmentOptions: [CraftSegmentOption<VaultTabFilter>] {
        [
            CraftSegmentOption(.notMastered, title: AppStrings.Vault.filterNotMasteredTitle, count: vaultViewModel.metrics.unmasteredCount),
            CraftSegmentOption(.mastered, title: AppStrings.Vault.filterMasteredTitle, count: vaultViewModel.metrics.masteredCount),
            CraftSegmentOption(.bookmarked, title: AppStrings.Vault.filterBookmarkedTitle, count: vaultViewModel.metrics.bookmarkedCount)
        ]
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                navigationHeader
                    .padding(.horizontal, theme.spacing.base)
                    .padding(.top, theme.spacing.md)
                    .padding(.bottom, theme.spacing.xs)

                // 3-Tab Segmented Filter
                segmentedFilterBar
                    .padding(.horizontal, theme.spacing.base)
                    .padding(.vertical, theme.spacing.xs)

                // Quick Action Toolbar (Smart Pick & Select All Toggle)
                actionToolbar
                    .padding(.horizontal, theme.spacing.base)
                    .padding(.vertical, theme.spacing.xs)

                // Scrollable Word List
                wordListContent
            }
        }
        .safeAreaInset(edge: .bottom) {
            stickyBottomBar
        }
        .task {
            if vaultViewModel.vaultWords.isEmpty && !vaultViewModel.isLoading {
                await vaultViewModel.loadData()
            }
        }
    }

    // MARK: - Navigation Header
    private var navigationHeader: some View {
        HStack(alignment: .center) {
            Button(action: {
                if let onClose {
                    onClose()
                } else {
                    dismiss()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                    Text(AppStrings.Practice.back)
                        .font(theme.typography.label)
                        .fontWeight(.medium)
                }
                .foregroundStyle(theme.colors.textPrimary)
                .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppStrings.Practice.backText)

            Spacer()

            Text(AppStrings.Practice.title)
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.textPrimary)

            Spacer()

            // Selected count pill badge
            if selectedWordsCount > 0 {
                CraftBadge(
                    verbatim: AppStrings.Practice.selectedCount(selectedWordsCount),
                    variant: .subtle,
                    tone: .primary,
                    size: .sm
                )
                .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
            }
        }
    }

    // MARK: - 3-Tab Segmented Filter
    private var segmentedFilterBar: some View {
        CraftSegmentedControl(
            selection: Binding(
                get: { vaultViewModel.vaultTabFilter },
                set: { vaultViewModel.setVaultFilter($0) }
            ),
            options: vaultSegmentOptions,
            style: .tactile3D
        )
    }

    // MARK: - Action Toolbar (Smart Pick & Select All Toggle)
    private var actionToolbar: some View {
        VStack(spacing: theme.spacing.xs) {
            HStack {
                Text(verbatim: AppStrings.Practice.totalCount(vaultViewModel.vaultWords.count))
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)

                Spacer()
            }

            HStack(spacing: theme.spacing.sm) {
                // "⚡️ Luyện tập nhanh" Smart Pick Button
                CraftButton(
                    verbatim: AppStrings.Practice.smartPickText,
                    variant: .tactile,
                    size: .sm,
                    action: {
                        withAnimation(theme.animations.springSnappy) {
                            _ = vaultViewModel.smartPickWords()
                        }
                    }
                )
                .disabled(vaultViewModel.vaultWords.isEmpty)

                Spacer()

                // Select All / Deselect All Toggle Button
                CraftButton(
                    verbatim: isAllSelected ? AppStrings.Practice.deselectAllText : AppStrings.Practice.selectAllText,
                    iconName: isAllSelected ? "xmark.circle" : "checkmark.circle",
                    variant: .ghost,
                    size: .sm,
                    action: {
                        withAnimation(theme.animations.springSnappy) {
                            if isAllSelected {
                                vaultViewModel.deselectAll()
                            } else {
                                vaultViewModel.selectAll()
                            }
                        }
                    }
                )
                .disabled(vaultViewModel.vaultWords.isEmpty)
            }
        }
    }

    // MARK: - Word List Content
    private var wordListContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if vaultViewModel.isLoading && vaultViewModel.vaultWords.isEmpty {
                VStack {
                    Spacer(minLength: 40)
                    CraftSpinner(size: .lg, color: theme.colors.brandPrimary)
                        .padding(.vertical, 40)
                    Spacer(minLength: 40)
                }
            } else if vaultViewModel.vaultWords.isEmpty {
                emptyListView
                    .padding(.top, theme.spacing.xl)
            } else {
                LazyVStack(spacing: theme.spacing.sm) {
                    ForEach(vaultViewModel.vaultWords) { word in
                        PracticeSelectionRow(
                            word: word,
                            isSelected: vaultViewModel.selectedWordIds.contains(word.id),
                            onToggle: {
                                vaultViewModel.toggleWordSelection(id: word.id)
                            },
                            onAudioTap: {
                                vaultViewModel.playAudio(for: word)
                            }
                        )
                    }
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.top, theme.spacing.xs)
                .padding(.bottom, theme.spacing.xl + 40)
            }
        }
    }

    // MARK: - Empty State View
    private var emptyListView: some View {
        CraftEmptyState(
            symbol: .study,
            title: AppStrings.Practice.emptyTitle,
            message: AppStrings.Practice.emptyMessage
        )
        .padding(.horizontal, theme.spacing.base)
    }

    // MARK: - Sticky Bottom Bar
    private var stickyBottomBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(theme.colors.borderDefault)

            VStack(spacing: theme.spacing.xs) {
                CraftButton(
                    verbatim: selectedWordsCount > 0
                        ? AppStrings.Practice.startButton(selectedWordsCount)
                        : AppStrings.Practice.emptyPromptText,
                    iconName: "bolt.fill",
                    variant: .tactile,
                    size: .lg,
                    isFullWidth: true,
                    action: {
                        let selected = vaultViewModel.selectedWords
                        guard !selected.isEmpty else { return }
                        onStartPractice(selected)
                    }
                )
                .disabled(selectedWordsCount == 0)
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.top, theme.spacing.sm)
            .padding(.bottom, theme.spacing.xs)
            .background(theme.colors.canvasBackground.opacity(0.95))
            .background(.ultraThinMaterial)
        }
    }
}
