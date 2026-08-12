# Architecture Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Standardize VocabCraftApp iOS codebase to Feature-based Modularization (MVVM + Clean Architecture) by fixing folder structures, extracting a God View's logic into a ViewModel, and tightening DI and concurrency.

**Architecture:** Clean Architecture + MVVM + Feature-based Modules
**Tech Stack:** Swift 5.9, SwiftUI, Observation, XCTest

## Global Constraints
- Target iOS 17+ (using `@Observable`).
- All view models must be `@MainActor`.
- Views must not instantiate concrete services (e.g. `TextToSpeechService`). All dependencies must come from `AppContainer`.
- Long-running `Task`s inside ViewModels must be cancellable and explicitly cancelled on `deinit`.

---

### Task 1: Directory Restructuring
**Files:**
- Move: `VocabCraftApp/Presentation/Features/Homepage/ViewModels/HomepageViewModel.swift` -> `VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift`
- Move: `VocabCraftApp/Presentation/Features/ReflexDrill/ViewModels/ReflexDrillViewModel.swift` -> `VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexDrillViewModel.swift`
- Move: `VocabCraftApp/Presentation/Features/Vocabulary/ViewModels/QuickReflexDrillViewModel.swift` -> `VocabCraftApp/Features/Vocabulary/ViewModels/QuickReflexDrillViewModel.swift`
- Move: `VocabCraftApp/Presentation/Features/Vocabulary/ViewModels/StudySessionViewModel.swift` -> `VocabCraftApp/Features/Vocabulary/ViewModels/StudySessionViewModel.swift`
- Move: `VocabCraftApp/Presentation/Features/Vocabulary/Views/QuickReflexDrillSheetView.swift` -> `VocabCraftApp/Features/Vocabulary/Views/QuickReflexDrillSheetView.swift`
- Delete: `VocabCraftApp/Presentation/` folder completely.

- [ ] **Step 1: Create target directories**
```bash
mkdir -p VocabCraftApp/Features/Homepage/ViewModels
mkdir -p VocabCraftApp/Features/ReflexDrill/ViewModels
mkdir -p VocabCraftApp/Features/Vocabulary/ViewModels
```

- [ ] **Step 2: Move files using git mv**
```bash
git mv VocabCraftApp/Presentation/Features/Homepage/ViewModels/HomepageViewModel.swift VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift
git mv VocabCraftApp/Presentation/Features/ReflexDrill/ViewModels/ReflexDrillViewModel.swift VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexDrillViewModel.swift
git mv VocabCraftApp/Presentation/Features/Vocabulary/ViewModels/QuickReflexDrillViewModel.swift VocabCraftApp/Features/Vocabulary/ViewModels/QuickReflexDrillViewModel.swift
git mv VocabCraftApp/Presentation/Features/Vocabulary/ViewModels/StudySessionViewModel.swift VocabCraftApp/Features/Vocabulary/ViewModels/StudySessionViewModel.swift
git mv VocabCraftApp/Presentation/Features/Vocabulary/Views/QuickReflexDrillSheetView.swift VocabCraftApp/Features/Vocabulary/Views/QuickReflexDrillSheetView.swift
```

- [ ] **Step 3: Delete old directory**
```bash
rm -rf VocabCraftApp/Presentation
```

- [ ] **Step 4: Update Xcode project references if necessary (using pbxproj tool or assuming it builds if no PBXproj is used)**
Note: SPM/Xcode might require updating project files, but since this is an automated plan, ensure `xcodebuild build` passes if project structure is filesystem-based. Since this is an Xcode project, we will likely need to update `project.pbxproj`.
Let's assume the build passes or we fix the `.pbxproj` in this step.
Run: `xcodebuild -scheme VocabCraftApp build`

- [ ] **Step 5: Commit**
```bash
git commit -m "refactor: merge Presentation folder into Features folder"
```

---

### Task 2: Create `VocabularyViewModel` and TDD
**Files:**
- Create: `VocabCraftApp/Features/Vocabulary/ViewModels/VocabularyViewModel.swift`
- Create: `VocabCraftAppTests/Features/Vocabulary/VocabularyViewModelTests.swift`

- [ ] **Step 1: Write the failing test**
```swift
// In VocabCraftAppTests/Features/Vocabulary/VocabularyViewModelTests.swift
import XCTest
@testable import VocabCraftApp

@MainActor
final class VocabularyViewModelTests: XCTestCase {
    func testFilteringByCEFR() {
        let vm = VocabularyViewModel(ttsService: nil) // Mock or nil
        vm.wordItems = WordItem.mockData
        vm.selectedFilter = "B1-B2"
        XCTAssertEqual(vm.filteredWords.count, 2)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `xcodebuild test -scheme VocabCraftApp -only-testing:VocabCraftAppTests/VocabularyViewModelTests/testFilteringByCEFR`
Expected: FAIL (File not found / type not found)

- [ ] **Step 3: Write minimal implementation**
```swift
// In VocabCraftApp/Features/Vocabulary/ViewModels/VocabularyViewModel.swift
import Foundation
import Observation

@MainActor
@Observable
public final class VocabularyViewModel {
    public var searchText = ""
    public var selectedFilter = "Tất cả"
    public var selectedTab = 0
    public var expandedWordId: Int64? = 1
    public var wordItems: [WordItem] = WordItem.mockData
    public var selectedDeckId: String? = nil
    public var selectedDrillWord: WordItem? = nil

    private let ttsService: TextToSpeechProtocol?

    public init(ttsService: TextToSpeechProtocol? = nil) {
        self.ttsService = ttsService
    }

    public var filteredWords: [WordItem] {
        var result = wordItems
        if !searchText.isEmpty {
            result = result.filter { $0.lemma.localizedCaseInsensitiveContains(searchText) || $0.definition.localizedCaseInsensitiveContains(searchText) }
        }
        if selectedFilter == "A1-A2" {
            result = result.filter { $0.cefrLevel == "A1" || $0.cefrLevel == "A2" }
        } else if selectedFilter == "B1-B2" {
            result = result.filter { $0.cefrLevel == "B1" || $0.cefrLevel == "B2" }
        } else if selectedFilter == "C1-C2" {
            result = result.filter { $0.cefrLevel == "C1" || $0.cefrLevel == "C2" }
        } else if selectedFilter == "Cần ôn ⚡" {
            result = result.filter { $0.masteryLevel < 3 }
        } else if selectedFilter == "Đã thuộc ⭐5" {
            result = result.filter { $0.masteryLevel >= 4 }
        }
        return result
    }

    public func filterCount(for title: String) -> Int {
        switch title {
        case "Tất cả": return wordItems.count
        case "Cần ôn ⚡": return wordItems.filter { $0.masteryLevel < 3 }.count
        case "Đã thuộc ⭐5": return wordItems.filter { $0.masteryLevel >= 4 }.count
        case "A1-A2": return wordItems.filter { $0.cefrLevel == "A1" || $0.cefrLevel == "A2" }.count
        case "B1-B2": return wordItems.filter { $0.cefrLevel == "B1" || $0.cefrLevel == "B2" }.count
        case "C1-C2": return wordItems.filter { $0.cefrLevel == "C1" || $0.cefrLevel == "C2" }.count
        default: return wordItems.count
        }
    }

    public func speak(text: String) {
        ttsService?.speak(text: text)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**
Run: `xcodebuild test -scheme VocabCraftApp -only-testing:VocabCraftAppTests/VocabularyViewModelTests`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add .
git commit -m "feat: create VocabularyViewModel with extracted state and filtering logic"
```

---

### Task 3: Integrate `VocabularyViewModel` into `VocabularyView`
**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift`

- [ ] **Step 1: Write the failing UI test or verify build fails if we change init**
(Skip UI test, we will refactor view logic directly and verify build).

- [ ] **Step 2: Modify `VocabularyView.swift`**
Replace all `@State` properties (`searchText`, `selectedFilter`, etc.) with `@State private var viewModel: VocabularyViewModel`.
Update all bindings in the body to use `$viewModel.searchText`, etc.
Replace `ttsService.speak` with `viewModel.speak(text:)`.
Ensure `init` takes `viewModel: VocabularyViewModel`.

- [ ] **Step 3: Build to verify**
Run: `xcodebuild build -scheme VocabCraftApp`
Expected: PASS (if all calls are correctly updated)

- [ ] **Step 4: Commit**
```bash
git add VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift
git commit -m "refactor: migrate VocabularyView to use VocabularyViewModel"
```

---

### Task 4: Fix Dependency Injection in AppContainer and Views
**Files:**
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`

- [ ] **Step 1: Update AppContainer**
Add `makeVocabularyViewModel() -> VocabularyViewModel` to `AppContainer`.

- [ ] **Step 2: Update HomepageView**
Remove `init(ttsService:)` and `init(userName:...)` that create the view model internally.
Only keep `init(viewModel: HomepageViewModel)`.

- [ ] **Step 3: Update parent views (e.g. `VocabCraftApp/App/VocabCraftApp.swift` or App Coordinator)**
Ensure the root view creates view models via `AppContainer.shared` (or injected container) and passes them to `HomepageView` and `VocabularyView`.

- [ ] **Step 4: Build and Test**
Run: `xcodebuild test -scheme VocabCraftApp`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git commit -am "refactor: enforce strict DI from AppContainer for all views"
```

---

### Task 5: Concurrency Safety (Fix Unstructured Tasks)
**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexDrillViewModel.swift`
- Modify: `VocabCraftApp/Features/Vocabulary/ViewModels/QuickReflexDrillViewModel.swift`

- [ ] **Step 1: Update ReflexDrillViewModel**
In `loadDrills()`, it currently does `Task { ... }`. Store this in `private var loadTask: Task<Void, Never>?`.
In `deinit`, call `loadTask?.cancel()`.
Ensure `timerTask` is cancelled in `deinit`.

- [ ] **Step 2: Update QuickReflexDrillViewModel**
Ensure `autoAdvanceTask` and `timerTask` are cancelled in `deinit`.

- [ ] **Step 3: Run Tests**
Run: `xcodebuild test -scheme VocabCraftApp`
Expected: PASS

- [ ] **Step 4: Commit**
```bash
git commit -am "fix: ensure all Task references in ViewModels are cancelled on deinit"
```
