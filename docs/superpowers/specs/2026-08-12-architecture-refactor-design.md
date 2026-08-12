# Swift Architecture Refactor Design

## Objective
Standardize the VocabCraftApp iOS codebase to strict Feature-based Modularization (MVVM + Clean Architecture), removing inconsistencies in directory structures, resolving MVVM violations, and tightening dependency injection and concurrency safety.

## 1. Folder Structure (Feature-Based Modularization)
**Current Issue:** ViewModels are split between `Features/` and `Presentation/Features/`.
**Design:**
- Move all ViewModels from `VocabCraftApp/Presentation/Features/...` to `VocabCraftApp/Features/...`.
- The new structure for a feature (e.g., Homepage) will be:
  - `Features/Homepage/Views/`
  - `Features/Homepage/ViewModels/`
  - `Features/Homepage/Models/` (if any)
- Completely remove the `VocabCraftApp/Presentation/` directory.

## 2. Refactoring `VocabularyView` (MVVM Standardization)
**Current Issue:** `VocabularyView` is a massive view (230+ lines) that handles complex data filtering, state management, and view logic directly, rather than delegating to a ViewModel.
**Design:**
- Create `VocabularyViewModel` inside `Features/Vocabulary/ViewModels/`.
- Extract the following `@State` properties into the ViewModel:
  - `searchText: String`
  - `selectedFilter: String`
  - `selectedTab: Int`
  - `wordItems: [WordItem]`
  - `expandedWordId: Int64?`
- Move filtering logic (`filteredWords`, `filterCount`) to the ViewModel.
- The `VocabularyView` will simply observe the `VocabularyViewModel` via `@Bindable` (or normal initialization) and delegate user intents (like tab selection, search) to it.

## 3. Dependency Injection Boundary
**Current Issue:** `AppContainer` exists as a Composition Root, but views like `HomepageView` and `VocabularyView` bypass it by instantiating default services (e.g., `TextToSpeechService()`) directly in their initializers.
**Design:**
- Update `AppContainer` to provide a factory method for the newly created `VocabularyViewModel`: `makeVocabularyViewModel()`.
- Remove default initializations of concrete services (e.g., `TextToSpeechService()`) inside the Views.
- Ensure that Views receive their ViewModels strictly via injection. (The parent view or router instantiates the ViewModel using `AppContainer` and passes it down).

## 4. Concurrency Safety
**Current Issue:** Unstructured `Task { }` calls exist in view models without proper lifecycle management (cancellation).
**Design:**
- Audit ViewModels (`ReflexDrillViewModel`, `QuickReflexDrillViewModel`, `SettingsViewModel`).
- Ensure any background or long-running tasks are stored in a `Task<Void, Never>?` reference.
- Call `cancel()` on these tasks during `deinit` or when a new operation overrides the previous one.
- In SwiftUI views, ensure that data fetching is tied to the View's lifecycle (using the `.task { }` modifier where appropriate).
