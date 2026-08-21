import SwiftUI

/// Search bar and typography-first category filter pills for the Personal Vault.
/// Strictly adheres to Apple HIG with no emoji decorations on tab labels.
public struct PersonalSearchFilterBar: View {
    @Binding public var searchQuery: String
    public let selectedFilter: PersonalVaultFilter
    public let metrics: PersonalVaultMetrics
    public let onFilterChanged: (PersonalVaultFilter) -> Void
    public var onSearchSubmitted: (() -> Void)?

    public init(
        searchQuery: Binding<String>,
        selectedFilter: PersonalVaultFilter,
        metrics: PersonalVaultMetrics,
        onFilterChanged: @escaping (PersonalVaultFilter) -> Void,
        onSearchSubmitted: (() -> Void)? = nil
    ) {
        self._searchQuery = searchQuery
        self.selectedFilter = selectedFilter
        self.metrics = metrics
        self.onFilterChanged = onFilterChanged
        self.onSearchSubmitted = onSearchSubmitted
    }

    public var body: some View {
        VStack(spacing: 10) {
            // Quick Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.vocabMuted)
                    .font(.system(size: 14, weight: .semibold))

                TextField("Tìm kiếm theo từ hoặc nghĩa...", text: $searchQuery)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.vocabInk)
                    .onSubmit {
                        onSearchSubmitted?()
                    }

                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
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

            // Typography-First Filter Pills (No Emojis)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PersonalVaultFilter.allCases, id: \.self) { filter in
                        filterPill(filter)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 2)
        }
    }

    private func count(for filter: PersonalVaultFilter) -> Int {
        switch filter {
        case .all:
            return metrics.totalWords
        case .needsReview:
            return metrics.needsReviewCount
        case .mastered:
            return metrics.masteredCount
        case .bookmarked:
            return metrics.bookmarkedCount
        }
    }

    private func filterPill(_ filter: PersonalVaultFilter) -> some View {
        let isSelected = selectedFilter == filter
        let filterCount = count(for: filter)

        return Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                onFilterChanged(filter)
            }
        }) {
            HStack(spacing: 4) {
                Text(filter.title)
                Text("(\(filterCount))")
                    .monospacedDigit()
            }
            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
            .foregroundColor(isSelected ? Color.vocabCanvas : Color.vocabInk)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(isSelected ? Color.vocabInk : Color.vocabSurfaceCard)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Color.clear : Color.vocabHairline, lineWidth: 1.2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(BentoCardButtonStyle())
        .sensoryFeedback(.selection, trigger: selectedFilter)
    }
}
