import SwiftUI

extension PersonalVaultFilter {
    public var titleKey: LocalizedStringKey {
        switch self {
        case .all: return AppStrings.Vocabulary.filterAll
        case .needsReview: return AppStrings.Vocabulary.filterReviewNeeded
        case .mastered: return AppStrings.Vocabulary.filterMastered
        case .bookmarked: return AppStrings.Vocabulary.filterSaved
        }
    }
}

extension VaultTabFilter {
    public var titleKey: LocalizedStringKey {
        switch self {
        case .notMastered: return AppStrings.Vault.filterNotMasteredTitleKey
        case .mastered: return AppStrings.Vault.filterMasteredTitleKey
        case .bookmarked: return AppStrings.Vault.filterBookmarkedTitleKey
        }
    }
}
