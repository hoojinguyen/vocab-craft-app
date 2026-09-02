---
type: feature
title: Vocabulary and Personal Vault
description: Word browsing, filtering, bookmarks, PersonalVault and SmartReview flows.
tags: ["vocabulary", "vault", "bookmarks", "feature"]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-02T08:37:35.164Z
sources:
  - id: openwiki-source-386c062a7f66539bdc7462b8
    resource: repo://VocabCraftApp/Domain/Services/VocabularyFilterService.swift
  - id: openwiki-source-109a0b693d6235ffb0b2128c
    resource: repo://VocabCraftApp/Domain/UseCases/SmartVaultWordSelector.swift
  - id: openwiki-source-46a88bf9d70d12348ae5c723
    resource: repo://VocabCraftApp/Features/Vocabulary/PersonalVault/ViewModels/PersonalVaultViewModel.swift
generated: { by: "opencode", at: "2026-09-02T08:32:17.625Z" }
---

## Responsibility

Allows browsing catalog words, filtering, viewing details, bookmarking, and reviewing personal weak words.

## Entrypoints

- **Views**: `Features/Vocabulary/Views/VocabularyView.swift`, `PracticeSelectionView.swift`, `Features/Vocabulary/PersonalVault/Views/SmartReviewSessionView.swift`.
- **ViewModels**: `PersonalVaultViewModel`, `SmartReviewViewModel` + `Features/Vocabulary/ViewModels` (catalog).
- **Domain**: `FetchPersonalVaultUseCase`, `ReviewWeakWordsUseCase`, `ToggleWordBookmarkUseCase`, `SmartVaultWordSelector`, `VocabularyFilterService`, `PracticeDrillPlanGenerator`.
- **Models**: `Domain/Entities/{Word, PersonalWord, VaultWordItem, SuggestedWord}`, `Features/Vocabulary/Models/WordItem.swift`.

## Mechanisms

1. **Catalog**: VocabularyView loads words via `VocabularyRepository` + `VocabularyFilterService` (query, CEFR, bookmark filters); displays via `CraftCard` + `CraftSearchBar`; row tap shows detail sheet with `CraftFlipCard` (front EN, back VI).
2. **Vault**: `PersonalVaultViewModel.fetchVaultUseCase` merges dataset + progress to produce `VaultWordItem` list; supports search, filter by mastery/bookmark, and sort (recent, overdue). Bookmark toggle calls `ToggleWordBookmarkUseCase` which flips `UserWordProgress.isBookmarked` via actor.
3. **SmartReview**: `SmartReviewViewModel` initialized with weak words from `ReviewWeakWordsUseCase` / `SmartVaultWordSelector` (picks weakest by `mistakeCount` + `intervalDays` + `ModeSuccessStats`). Session uses same reflex pipeline but seeded with vault words.
4. **Practice selection**: `PracticeSelectionView` offers entry to Mixed drill with selected vault items; plans built via `PracticeDrillPlanGenerator`.

## Relationships

- **Upstream**: `DatasetEngine` + `UserProgressModelActor` → repos → vault use cases → ViewModels.
- **Downstream**: Vault selection feeds `MixedReflexDrillViewModel`; bookmark changes invalidate VocabularyView filter.

## State and Lifecycle

ViewModels are `@Observable`; fetch on appear/task; support pull-to-refresh. Vault state reflects actor writes immediately via refetch.

## Invariants

- Filtering is pure function; no mutation of source array.
- Bookmark is idempotent; SmartReview word selector never returns mastered words.
- TTS for word pronunciation via `ttsService` injected from container.

## Failure

- Empty vault shows `CraftEmptyState` with cta to browse.
- DataSource errors surface as retry + empty; TTS failure silent.

## Configuration

Smart selector thresholds in `SmartVaultWordSelector`; filter options in `VocabularyFilterService`.

## Extension

Add filter dimension by extending `VocabularyFilterService`; add vault tab by extending ViewModel.

## Tests

- `PersonalVaultViewModelTests.swift`, `PersonalVaultLocalizationTests.swift`, `Domain/SmartVaultWordSelectorTests.swift`, `VocabularyFilterServiceTests.swift`, `FetchPersonalVaultUseCaseTests` implicitly.
