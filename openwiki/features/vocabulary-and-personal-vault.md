---
type: feature
title: Vocabulary and Personal Vault
description: The Vocabulary tab's personal vault (search, three-tab filtering for not mastered, mastered, and bookmarked words, bookmarks, word details, practice selection, and smart review of weak words), the view models behind them, and the vault's localized strings.
tags: ["vocabulary", "vault", "bookmarks", "smart-review", "filters", "localization"]
verified:
  - by: openwiki/0.7.2
    at: 2026-10-26T17:49:24.607Z
sources:
  - id: openwiki-source-fb58e0a18af45b08425b5baf
    resource: repo://VocabCraftApp/Domain/UseCases/FetchPersonalVaultUseCase.swift
  - id: openwiki-source-109a0b693d6235ffb0b2128c
    resource: repo://VocabCraftApp/Domain/UseCases/SmartVaultWordSelector.swift
  - id: openwiki-source-46a88bf9d70d12348ae5c723
    resource: repo://VocabCraftApp/Features/Vocabulary/PersonalVault/ViewModels/PersonalVaultViewModel.swift
generated: { by: "claude-code", at: "2026-10-26T17:49:24.607Z" }
---

## Responsibility

The Vocabulary tab is where the learner browses the words they have studied. Each word shows its mastery state and bookmark state. The learner can search, switch between filter tabs, open a word's details, bookmark words, and start a drill from a selection of words. Smart review pulls the weak and due words into a focused session.

## Entrypoints

- **Tab screen**: `VocabularyView` (`VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift`) hosts the search bar, the three-tab category control, the word list, and the sheets for practice selection and smart review. It uses `AppContainer.makePersonalVaultViewModel()`.
- **Vault ViewModel**: `PersonalVaultViewModel` (`Features/Vocabulary/PersonalVault/ViewModels/PersonalVaultViewModel.swift`) is `@Observable`. It owns the word lists, the selection, the search, the filters, and the bookmark actions.
- **Smart review**: `SmartReviewViewModel` and `SmartReviewSessionView` (`Features/Vocabulary/PersonalVault`). The view model is created by `AppContainer.makeSmartReviewViewModel(weakWords:)`.
- **Practice selection**: `PracticeSelectionView`, `PracticeSelectionRow`, and `DynamicReflexModeBadge` (`Features/Vocabulary/Views`) let the learner pick words for a reflex drill.
- **Word details**: `VaultWordDetailSheet`, and `VaultWordRowView` for each list row.
- **Filter presentation**: `PersonalVaultFilter+Presentation.swift` (`Features/Vocabulary/PersonalVault/Models`) holds the labels and display values for the filters.
- **Domain**: `FetchPersonalVaultUseCase`, `ToggleWordBookmarkUseCase`, `ReviewWeakWordsUseCase`, and `SmartVaultWordSelector` in `VocabCraftApp/Domain`.

## Filters

Two filter types are used:

- `PersonalVaultFilter` (`Domain/UseCases/FetchPersonalVaultUseCase.swift`) has four cases: `all`, `needsReview`, `mastered`, and `bookmarked`. It is used by the use case.
- `VaultTabFilter` has three cases: `notMastered`, `mastered`, and `bookmarked`. These are the three segments of the vault screen, and `setVaultFilter(_:)` applies them.

## Mechanisms

1. **Load** — `loadData()` runs the `FetchPersonalVaultUseCase` for the current filter and search query. It builds `PersonalWord` values from the catalog and the learner's progress, then converts them to `VaultWordItem` values for display. Each request has an ID, so a late result from an earlier request is ignored.
2. **Search and filter** — `setSearchQuery(_:)` trims the query and reloads. `setVaultFilter(_:)` and `setFilter(_:)` cancel the running search task, start a new one, and reload. The result includes `PersonalVaultMetrics` with counts for each filter.
3. **Selection** — `toggleWordSelection(id:)`, `selectAll()`, and `deselectAll()` manage the selected word IDs. `selectedWords` is what the practice selection uses.
4. **Smart pick** — `smartPickWords(targetCount:)` takes the words that match the current tab and asks `SmartVaultWordSelector` for a set of about `dailyGoalCount` words (default 10). It sets those words as the selection.
5. **Bookmarks** — `toggleBookmark(wordId:)` updates the displayed state at once, then calls `ToggleWordBookmarkUseCase`. The metrics' bookmarked count is updated the same way. Pending mutations are tracked so a reload does not overwrite a bookmark that is still being saved.
6. **Audio** — `playAudio(for:)` plays a word's pronunciation through `ttsService`. See [Audio and Speech](../core/audio-and-speech.md).
7. **Smart review** — `ReviewWeakWordsUseCase.fetchDueWords(now:)` returns the words that are due for review or flagged `needsReview`, most overdue first. `SmartReviewViewModel` steps through them. `markCurrentReviewed(isCorrect:)` records the answer and schedules the next review. See [SRS Engine](../core/srs-engine.md).
8. **Drill handoff** — The reflex drills start from the selected words. `VocabularyView` also handles `appRouter.pendingSmartReview`, which the `vocabcraft://review` deep link sets, by opening smart review. See [Reflex Drill System](reflex-drill-system.md).

## Relationships

- **Upstream**: `VocabularyRepositoryImpl` joins the catalog (see [Dataset and Sync](../core/dataset-and-sync.md)) with the `UserProgressModelActor` (see [Persistence](../core/persistence.md)). `AppContainer` builds the use cases and view models.
- **Downstream**: Drill sessions use the selected words. Bookmark and review results update the progress store.

## State and Lifecycle

- `PersonalVaultViewModel` is created when the Vocabulary tab opens, and the view reloads it when the filter, query, or data changes.
- Search tasks are cancelled when a new search starts. Only the latest search result is applied.
- Selected word IDs are kept in the view model (`selectedWordIds`).

## Invariants

- The displayed bookmark state follows the write it was started with. The view model keeps the previous state so it can roll back.
- Smart pick only chooses from the words that match the current tab.

## Failure

- Loading errors are stored in `errorMessage`.
- When a bookmark write fails, the UI state is restored to the previous value.

## Localization

Vault strings live in `VocabCraftApp/Core/Localization/AppStrings+Vault.swift`, and the filter labels come from `PersonalVaultFilter+Presentation.swift`. See [Localization and Theming](../operations/localization-and-theming.md).

## Configuration

- The default smart-pick count is the daily goal (`dailyGoalCount`), falling back to 10.
- The three tab filters are fixed in `VaultTabFilter`.

## Extension

- Add a filter by adding a case to `PersonalVaultFilter` or `VaultTabFilter`, updating `smartPickWords` and the presentation extension.
- Add a word action by adding a use case and a method on `PersonalVaultViewModel`, then a control in `VaultWordDetailSheet`.

## Tests

- `VocabCraftAppTests/Features/PersonalVaultViewModelTests.swift` covers the vault view model.
- `VocabCraftAppTests/Features/Vocabulary/PersonalVaultViewsTests.swift` and `VocabularyHubIntegrationTests.swift` cover the views and the tab.
- `VocabCraftAppTests/Domain/SmartVaultWordSelectorTests.swift` covers smart pick.
- `VocabCraftAppTests/Features/PersonalVaultLocalizationTests.swift` covers the vault strings.
