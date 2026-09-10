# Package 2: Clean Architecture & DI Hygiene Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Decouple Domain UseCases from UI frameworks (`CraftUIKit`, `SwiftUI`) and feature folders, extract focused protocols for Core stores, eliminate uncontrolled sample data seeding on real user stores, and clean up redundant speech engine allocations at startup.

**Architecture:** Domain entities and protocols are isolated from Presentation and UI components; `FetchLearningPathUseCase` returns pure domain `LearningPathCurriculum`; filter presentation strings are moved to presentation extensions; `UserSettingsStore` is abstracted behind `UserRoadmapSettingsProtocol`; `VocabularyView` renders an empty state instead of auto-seeding sample records; and unused speech services are pruned from `AppContainer`.

**Tech Stack:** Swift 5 (Swift 6 compatible), SwiftData, SwiftUI, CraftUIKit, XCTest / Swift Testing.

**Spec:** `docs/superpowers/specs/2026-09-09-clean-architecture-di-design.md`

## Global Constraints
- Target iOS 17+, Swift 5 language mode compatible with Swift 6 strict concurrency.
- Zero Hardcoded Strings: all display strings must use `Localizable.xcstrings` (100% EN/VI bilingual parity).
- CraftUIKit-First: design tokens and components only, zero raw styling.
- Strict Quality Gate: 0 compiler warnings, 0 SwiftLint violations, 100% test pass rate.

---

### Task 1: Shared Reflex Domain Models & Drill Plan Generator

**Files:**
- Move: `VocabCraftApp/Features/Reflex/Core/Models/ReflexMode.swift` -> `VocabCraftApp/Domain/Models/Reflex/ReflexMode.swift`
- Move: `VocabCraftApp/Features/Reflex/Core/Models/ReflexDrillSessionPlan.swift` -> `VocabCraftApp/Domain/Models/Reflex/ReflexDrillSessionPlan.swift`
- Modify: `VocabCraftApp/Domain/UseCases/PracticeDrillPlanGenerator.swift`
- Modify: `scripts/generate_xcodeproj.py`
- Test: `VocabCraftAppTests/Domain/UseCases/PracticeDrillPlanGeneratorTests.swift`

**Interfaces:**
- Consumes: `ReflexMode`, `ReflexDrillSessionPlan`, `VaultWordItem`.
- Produces: `ReflexMode` and `ReflexDrillSessionPlan` at `Domain/Models/Reflex/` accessible without feature-level imports.

- [ ] **Step 1: Move ReflexMode and ReflexDrillSessionPlan to Domain/Models/Reflex**

```bash
mkdir -p VocabCraftApp/Domain/Models/Reflex
git mv VocabCraftApp/Features/Reflex/Core/Models/ReflexMode.swift VocabCraftApp/Domain/Models/Reflex/ReflexMode.swift
git mv VocabCraftApp/Features/Reflex/Core/Models/ReflexDrillSessionPlan.swift VocabCraftApp/Domain/Models/Reflex/ReflexDrillSessionPlan.swift
```

- [ ] **Step 2: Update scripts/generate_xcodeproj.py and regenerate pbxproj**

Ensure `VocabCraftApp/Domain/Models/Reflex/` files are registered in PBX build phases.
Run `python3 scripts/generate_xcodeproj.py`.

- [ ] **Step 3: Run existing drill plan generator and reflex tests**

Run: `swift test --filter PracticeDrillPlanGeneratorTests`
Run: `swift test --filter Reflex`
Expected: PASS (100%).

- [ ] **Step 4: Commit changes**

```bash
git add VocabCraftApp/Domain/Models/Reflex/ VocabCraftApp/Features/Reflex/Core/Models/ VocabCraftApp.xcodeproj/ scripts/generate_xcodeproj.py
git commit -m "refactor(domain): move ReflexMode and ReflexDrillSessionPlan into Domain"
```

---

### Task 2: Personal Vault Filter Domain Separation

**Files:**
- Modify: `VocabCraftApp/Domain/UseCases/FetchPersonalVaultUseCase.swift:1-55`
- Create: `VocabCraftApp/Features/Vocabulary/PersonalVault/Models/PersonalVaultFilter+Presentation.swift`
- Modify: `scripts/generate_xcodeproj.py`
- Test: `VocabCraftAppTests/Features/PersonalVaultLocalizationTests.swift`
- Test: `VocabCraftAppTests/Features/PersonalVaultViewModelTests.swift`

**Interfaces:**
- Consumes: `PersonalVaultFilter`, `VaultTabFilter`.
- Produces: Pure domain enums without `SwiftUI` in Domain; presentation extensions with `titleKey: LocalizedStringKey` in Presentation.

- [ ] **Step 1: Write failing test verifying Domain does not import SwiftUI**

Review `FetchPersonalVaultUseCase.swift` and remove `import SwiftUI`.
Strip `titleKey` and `title` from `PersonalVaultFilter` and `VaultTabFilter` in `FetchPersonalVaultUseCase.swift`.

- [ ] **Step 2: Create PersonalVaultFilter+Presentation.swift in Features**

Create `VocabCraftApp/Features/Vocabulary/PersonalVault/Models/PersonalVaultFilter+Presentation.swift`:
```swift
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
```

- [ ] **Step 3: Regenerate project and run tests**

Run `python3 scripts/generate_xcodeproj.py`.
Run: `swift test --filter PersonalVault`
Expected: PASS (100%).

- [ ] **Step 4: Commit changes**

```bash
git add VocabCraftApp/Domain/UseCases/FetchPersonalVaultUseCase.swift VocabCraftApp/Features/Vocabulary/PersonalVault/Models/PersonalVaultFilter+Presentation.swift VocabCraftApp.xcodeproj/ scripts/generate_xcodeproj.py
git commit -m "refactor(vault): decouple SwiftUI and display titles from PersonalVaultFilter domain model"
```

---

### Task 3: Learning Path Domain Decoupling

**Files:**
- Create: `VocabCraftApp/Domain/Models/LearningPathCurriculum.swift`
- Modify: `VocabCraftApp/Domain/UseCases/FetchLearningPathUseCase.swift`
- Modify: `VocabCraftApp/Features/Homepage/ViewModels/LearningPathDataMapper.swift`
- Modify: `VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift`
- Modify: `VocabCraftAppTests/Domain/UseCases/LearningPathUseCasesTests.swift`
- Modify: `VocabCraftAppTests/Features/Homepage/LearningPathDataMapperTests.swift`
- Modify: `scripts/generate_xcodeproj.py`

**Interfaces:**
- Consumes: `TopicDeckDTO`, `SubTopicStageDTO`, `TopicWordDTO`, `UserStageProgressData`.
- Produces: `LearningPathCurriculum` in Domain; `FetchLearningPathUseCase.execute() -> LearningPathCurriculum`; `LearningPathDataMapper.map(curriculum:) -> [LessonSection]` in Presentation.

- [ ] **Step 1: Create LearningPathCurriculum.swift in Domain**

Create `VocabCraftApp/Domain/Models/LearningPathCurriculum.swift`:
```swift
import Foundation

public struct LearningPathCurriculum: Sendable, Equatable {
    public let decks: [TopicDeckDTO]
    public let stages: [SubTopicStageDTO]
    public let words: [TopicWordDTO]
    public let progressList: [UserStageProgressData]

    public init(
        decks: [TopicDeckDTO],
        stages: [SubTopicStageDTO],
        words: [TopicWordDTO],
        progressList: [UserStageProgressData]
    ) {
        self.decks = decks
        self.stages = stages
        self.words = words
        self.progressList = progressList
    }
}
```

- [ ] **Step 2: Update FetchLearningPathUseCase to return LearningPathCurriculum without CraftUIKit**

Update `FetchLearningPathUseCase.swift`:
- Remove `import CraftUIKit`.
- Return `LearningPathCurriculum(decks: decks, stages: allStages, words: allWords, progressList: progressList)`.
- Protocol:
```swift
public protocol FetchLearningPathUseCaseProtocol: Sendable {
    func execute() async throws -> LearningPathCurriculum
}
```

- [ ] **Step 3: Update LearningPathDataMapper and HomepageViewModel**

Add overload to `LearningPathDataMapper`:
```swift
public static func map(curriculum: LearningPathCurriculum) -> [LessonSection] {
    map(
        decks: curriculum.decks,
        stages: curriculum.stages,
        words: curriculum.words,
        progressList: curriculum.progressList
    )
}
```

Update `HomepageViewModel`:
```swift
let curriculum = try await fetchLearningPathUseCase.execute()
self.sections = LearningPathDataMapper.map(curriculum: curriculum)
```

- [ ] **Step 4: Update test suites and verify**

Update `LearningPathUseCasesTests.swift` and `LearningPathDataMapperTests.swift`.
Run `python3 scripts/generate_xcodeproj.py`.
Run: `swift test --filter LearningPath`
Run: `swift test --filter Homepage`
Expected: PASS (100%).

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Domain/ VocabCraftApp/Features/Homepage/ VocabCraftAppTests/ VocabCraftApp.xcodeproj/ scripts/generate_xcodeproj.py
git commit -m "refactor(learning-path): decouple FetchLearningPathUseCase from CraftUIKit and presentation mapper"
```

---

### Task 4: User Roadmap Settings Protocol Abstraction

**Files:**
- Create: `VocabCraftApp/Domain/Protocols/UserRoadmapSettingsProtocol.swift`
- Modify: `VocabCraftApp/Core/Storage/UserSettingsStore.swift`
- Modify: `VocabCraftApp/Domain/UseCases/InitializeUserRoadmapUseCase.swift`
- Modify: `VocabCraftAppTests/Domain/UseCases/InitializeUserRoadmapUseCaseTests.swift`
- Modify: `scripts/generate_xcodeproj.py`

**Interfaces:**
- Consumes: None.
- Produces: `UserRoadmapSettingsProtocol` in Domain; `UserSettingsStore` conformance in Core; `InitializeUserRoadmapUseCase` decoupled from Core concrete type.

- [ ] **Step 1: Create UserRoadmapSettingsProtocol.swift**

Create `VocabCraftApp/Domain/Protocols/UserRoadmapSettingsProtocol.swift`:
```swift
import Foundation

public protocol UserRoadmapSettingsProtocol: Sendable {
    @MainActor
    func saveRoadmapPreferences(
        deckId: String,
        cefrLevel: String,
        dailyGoalCount: Int,
        notificationTimeInterval: Double
    )
}
```

- [ ] **Step 2: Conform UserSettingsStore to UserRoadmapSettingsProtocol**

In `UserSettingsStore.swift`:
Add conformance `extension UserSettingsStore: UserRoadmapSettingsProtocol {}`.
Implement `saveRoadmapPreferences(deckId:cefrLevel:dailyGoalCount:notificationTimeInterval:)` using existing properties.

- [ ] **Step 3: Refactor InitializeUserRoadmapUseCase to inject protocol**

In `InitializeUserRoadmapUseCase.swift`:
Change `private let userSettings: UserSettingsStore` to `private let userSettings: UserRoadmapSettingsProtocol`.
In initializer: `userSettings: UserRoadmapSettingsProtocol`.

- [ ] **Step 4: Update unit tests and verify**

Create a lightweight mock conforming to `UserRoadmapSettingsProtocol` in `InitializeUserRoadmapUseCaseTests.swift`.
Run `python3 scripts/generate_xcodeproj.py`.
Run: `swift test --filter InitializeUserRoadmapUseCaseTests`
Expected: PASS (100%).

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Domain/Protocols/UserRoadmapSettingsProtocol.swift VocabCraftApp/Core/Storage/UserSettingsStore.swift VocabCraftApp/Domain/UseCases/InitializeUserRoadmapUseCase.swift VocabCraftAppTests/Domain/UseCases/InitializeUserRoadmapUseCaseTests.swift VocabCraftApp.xcodeproj/ scripts/generate_xcodeproj.py
git commit -m "refactor(onboarding): abstract UserSettingsStore behind UserRoadmapSettingsProtocol"
```

---

### Task 5: Sample Data Seeding Control & Audio Startup Cleanup

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift:285-300`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Modify: `VocabCraftApp/App/VocabCraftApp.swift`
- Modify: `VocabCraftApp/App/DI/EnvironmentKeys.swift`
- Modify: `VocabCraftAppTests/App/AppContainerVocabularyTests.swift`

**Interfaces:**
- Consumes: `AppContainer`, `VocabularyView`.
- Produces: Clean cold launch without eager `AVAudioEngine` allocations; safe empty state in `VocabularyView` with sample seeding conditional on `-seed-sample-vault`.

- [ ] **Step 1: Remove unconditional sample seeding from VocabularyView**

In `VocabularyView.swift`:
Replace unconditional `await SampleVaultDataSeeder.seedIfEmpty(...)` with:
```swift
if ProcessInfo.processInfo.arguments.contains("-seed-sample-vault") {
    await SampleVaultDataSeeder.seedIfEmpty(repository: appContainer.userProgressRepository)
}
```

- [ ] **Step 2: Clean up sttService and speechAssessmentService from AppContainer**

In `AppContainer.swift`:
- Remove `public let sttService: SpeechRecognitionProtocol`.
- Remove `public let speechAssessmentService: SpeechAssessmentProtocol`.
- Remove initializer arguments and instantiation of `SpeechRecognitionService()` and `SpeechAssessmentService()`.

- [ ] **Step 3: Clean up environment injection in VocabCraftApp and EnvironmentKeys**

In `VocabCraftApp.swift`:
- Remove `.environment(\.speechAssessmentService, appContainer.speechAssessmentService)`.
In `EnvironmentKeys.swift`:
- Remove `speechAssessmentService` environment entry.

- [ ] **Step 4: Verify tests and run full test suite**

Run: `swift test --filter AppContainer`
Run: `swift test` (all 48 suites)
Run: `swiftlint lint --quiet --no-cache`
Expected: PASS (100%), 0 violations.

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift VocabCraftApp/App/DI/ VocabCraftApp/App/VocabCraftApp.swift VocabCraftAppTests/
git commit -m "feat(di): eliminate eager speech engine startup and guard sample vault seeding"
```

---

### Task 6: End-to-End Verification & Whole-Package Review

**Files:**
- Verification only

- [ ] **Step 1: Run Root SPM test suite**

Run: `swift test`
Expected: 100% test cases pass.

- [ ] **Step 2: Run CraftUIKit test suite**

Run: `swift test --package-path Packages/CraftUIKit`
Expected: 100% test cases pass.

- [ ] **Step 3: Run SwiftLint**

Run: `swiftlint lint --quiet --no-cache`
Expected: 0 warnings, 0 errors.

- [ ] **Step 4: Build on Xcode Simulator**

Run Xcode simulator build via XcodeBuildMCP or `xcodebuild`.
Expected: 0 errors, 0 warnings.

- [ ] **Step 5: Whole-Package Code Review**

Dispatch independent whole-package reviewer to verify architectural decoupling, clean DI, and data safety.
