import CraftUIKit
import SwiftUI

/// 3-tab segmented category filter for Vocabulary Vault:
/// - Chưa thuộc (%lld)
/// - Đã thuộc (%lld)
/// - Đã lưu (%lld)
/// Uses Craft design tokens for typography, spacing, radius, and animated selection background.
public struct VaultSegmentedControl: View {
    @Environment(\.craftTheme) private var theme
    @Binding public var selectedTab: VaultTabFilter
    public let unmasteredCount: Int
    public let masteredCount: Int
    public let bookmarkedCount: Int
    public var onSelect: ((VaultTabFilter) -> Void)?

    public init(
        selectedTab: Binding<VaultTabFilter>,
        unmasteredCount: Int = 0,
        masteredCount: Int = 0,
        bookmarkedCount: Int = 0,
        onSelect: ((VaultTabFilter) -> Void)? = nil
    ) {
        self._selectedTab = selectedTab
        self.unmasteredCount = unmasteredCount
        self.masteredCount = masteredCount
        self.bookmarkedCount = bookmarkedCount
        self.onSelect = onSelect
    }

    public init(
        selectedTab: Binding<VaultTabFilter>,
        metrics: PersonalVaultMetrics,
        onSelect: ((VaultTabFilter) -> Void)? = nil
    ) {
        self.init(
            selectedTab: selectedTab,
            unmasteredCount: metrics.unmasteredCount,
            masteredCount: metrics.masteredCount,
            bookmarkedCount: metrics.bookmarkedCount,
            onSelect: onSelect
        )
    }

    public var body: some View {
        HStack(spacing: theme.spacing.xs) {
            ForEach(VaultTabFilter.allCases, id: \.self) { tab in
                let isSelected = selectedTab == tab
                let title = tabTitle(for: tab)

                Button(action: {
                    withAnimation(theme.animations.springSnappy) {
                        selectedTab = tab
                        onSelect?(tab)
                    }
                }) {
                    Text(verbatim: title)
                        .font(theme.typography.label)
                        .fontWeight(isSelected ? .bold : .medium)
                        .foregroundStyle(isSelected ? theme.colors.textPrimary : theme.colors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .padding(.vertical, theme.spacing.sm)
                        .padding(.horizontal, theme.spacing.xs)
                        .frame(maxWidth: .infinity)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: theme.radii.sm)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: theme.radii.sm)
                                            .strokeBorder(theme.glass.borderGradient, lineWidth: 1)
                                    )
                                    .craftShadow(theme.shadows.sm)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(theme.spacing.xs)
        .background(.ultraThinMaterial)
        .background(theme.colors.surfaceCard.opacity(theme.glass.tintOpacity))
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.md)
                .strokeBorder(theme.glass.borderGradient, lineWidth: 1)
        )
        .sensoryFeedback(.selection, trigger: selectedTab)
    }

    private func tabTitle(for tab: VaultTabFilter) -> String {
        switch tab {
        case .notMastered:
            return AppStrings.Vault.filterNotMastered(unmasteredCount)
        case .mastered:
            return AppStrings.Vault.filterMastered(masteredCount)
        case .bookmarked:
            return AppStrings.Vault.filterBookmarked(bookmarkedCount)
        }
    }
}

#Preview("VaultSegmentedControl") {
    @Previewable @State var filter: VaultTabFilter = .notMastered
    VStack(spacing: 20) {
        VaultSegmentedControl(
            selectedTab: $filter,
            unmasteredCount: 12,
            masteredCount: 45,
            bookmarkedCount: 8
        )
    }
    .padding()
}
