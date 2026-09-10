# Design Spec: Package 2 - Clean Architecture & DI Hygiene

**Status:** Proposed  
**Date:** 2026-09-09  
**Author:** AI Agent & Core Team  
**Scope:** Architecture & Performance Audit Resolution (Findings 2, 4, 7)  
**Parent Document:** `docs/reviews/2026-09-09-architecture-performance-audit.md`

---

## 1. Problem Statement & Background

The architecture audit identified architectural boundary leaks, unintended sample data persistence, and startup resource bloat:

1. **Finding 2 (Domain Inverse Dependencies):**
   - `FetchLearningPathUseCase` imports `CraftUIKit`, returns UI-specific `LessonSection` instances, and directly invokes presentation mapper `LearningPathDataMapper`.
   - `FetchPersonalVaultUseCase` imports `SwiftUI` and defines localized display titles (`LocalizedStringKey`, `String(localized:bundle:.module)`) directly inside domain filter enums.
   - `PracticeDrillPlanGenerator` resides in `Domain/UseCases` but depends on `ReflexMode` and `ReflexDrillSessionPlan` located in `Features/Reflex/Core/Models/`.
   - `InitializeUserRoadmapUseCase` depends directly on concrete `UserSettingsStore` (Core) rather than a domain-defined protocol.
2. **Finding 4 (Uncontrolled Sample Data Seeding):**
   - `VocabularyView.task` unconditionally executes `SampleVaultDataSeeder.seedIfEmpty(...)` on view appearance, writing sample words, fake streaks, and artificial review history into the user’s real persistent store.
3. **Finding 7 (Unused Startup Audio Engines):**
   - `AppContainer.init()` eagerly initializes `SpeechRecognitionService` and `SpeechAssessmentService`, both allocating `AVAudioEngine` and recognizers during app cold start, despite reflex practice using `ResilientReflexSpeechEngine` and `TextToSpeechService`. `sttService` has no consumers, and `speechAssessmentService` is injected into SwiftUI environment but never read.

---

## 2. Architecture & Design Specification

### 2.1 Domain Layer Decoupling & Inversion of Control

#### A. Learning Path Domain Boundary
- **New Domain Model**: `VocabCraftApp/Domain/Models/LearningPathCurriculum.swift`
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
- **Refactored `FetchLearningPathUseCase`**:
  - Removes `import CraftUIKit`.
  - Signature:
    ```swift
    public protocol FetchLearningPathUseCaseProtocol: Sendable {
        func execute() async throws -> LearningPathCurriculum
    }
    ```
  - Directly aggregates `decks`, `stages`, `words`, and `progressList` using parallel task groups and returns `LearningPathCurriculum`.
- **Presentation Mapping Responsibility**:
  - `LearningPathDataMapper.map(curriculum: LearningPathCurriculum) -> [LessonSection]` remains in `Features/Homepage/ViewModels/LearningPathDataMapper.swift`.
  - `HomepageViewModel.loadCurriculum()` calls `fetchLearningPathUseCase.execute()` to retrieve `LearningPathCurriculum` and applies `LearningPathDataMapper.map(curriculum:)` to update `@Published / @Observable var sections: [LessonSection]`.

#### B. Personal Vault Filter Domain Separation
- **`FetchPersonalVaultUseCase.swift`**:
  - Removes `import SwiftUI`.
  - `PersonalVaultFilter` and `VaultTabFilter` remain pure business enums without UI titles or localized keys:
    ```swift
    public enum PersonalVaultFilter: String, CaseIterable, Sendable, Equatable {
        case all
        case needsReview
        case mastered
        case bookmarked
    }

    public enum VaultTabFilter: String, CaseIterable, Sendable, Equatable {
        case notMastered
        case mastered
        case bookmarked
    }
    ```
- **New Presentation Extension**: `VocabCraftApp/Features/Vocabulary/PersonalVault/Models/PersonalVaultFilter+Presentation.swift`
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

#### C. Shared Reflex Drill Domain Models
- Move `ReflexMode.swift` and `ReflexDrillSessionPlan.swift` from `VocabCraftApp/Features/Reflex/Core/Models/` to `VocabCraftApp/Domain/Models/Reflex/`.
- Ensure `PracticeDrillPlanGenerator.swift` references domain-level models without importing feature folders.
- Downstream feature views and view models in `Features/Reflex/` and `Features/Vocabulary/` import Domain models naturally.

#### D. User Roadmap Settings Protocol Abstraction
- **New Domain Protocol**: `VocabCraftApp/Domain/Protocols/UserRoadmapSettingsProtocol.swift`
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
- **Conform `UserSettingsStore`**:
  Extend `UserSettingsStore: UserRoadmapSettingsProtocol` in Core.
- **Refactor `InitializeUserRoadmapUseCase`**:
  Accepts `userSettings: UserRoadmapSettingsProtocol` instead of concrete `UserSettingsStore`.

---

### 2.2 Sample Data Seeding Control (Finding 4)

- **`VocabularyView.swift`**:
  - Remove unconditional `await SampleVaultDataSeeder.seedIfEmpty(...)` from `.task`.
  - When the persistent vault contains no words, display `emptyStateView(vaultVM: vaultVM)` rather than auto-populating mock records.
  - Allow sample seeding only when explicitly requested:
    ```swift
    if ProcessInfo.processInfo.arguments.contains("-seed-sample-vault") {
        await SampleVaultDataSeeder.seedIfEmpty(repository: appContainer.userProgressRepository)
    }
    ```
  - Retain the explicit manual action in Settings/Developer options for developers/testers to trigger sample seeding on demand.

---

### 2.3 Audio Startup & Dependency Injection Cleanup (Finding 7)

- **`AppContainer.swift`**:
  - Remove `public let sttService: SpeechRecognitionProtocol` and `public let speechAssessmentService: SpeechAssessmentProtocol`.
  - Remove instantiation of `SpeechRecognitionService()` and `SpeechAssessmentService()` in `AppContainer.init()`.
  - Maintain `audioSessionCoordinator` and `ttsService` (`TextToSpeechService`) for active audio playback.
- **`VocabCraftApp.swift`**:
  - Remove `.environment(\.speechAssessmentService, appContainer.speechAssessmentService)` from scene view builders.
- **`EnvironmentKeys.swift`**:
  - Remove `speechAssessmentService` environment key definition.
- **Retain Implementations & Tests**:
  - Keep `SpeechRecognitionService.swift` in `Core/Audio/` and `SpeechAssessmentService.swift` in `Packages/SpeechKit/` with their existing unit tests intact so they remain available for future feature integration.

---

## 3. Quality & Verification Gates

1. **SwiftPM Test Suite**: Run `swift test` and ensure all test suites pass 100%.
2. **SwiftLint Compliance**: Run `swiftlint lint --quiet --no-cache` to ensure 0 violations across all modified files.
3. **Xcode Simulator Compilation**: Build target `VocabCraftApp` and test suites with 0 warnings and 0 errors.
4. **Localization**: Confirm all display text uses `Localizable.xcstrings` with 100% EN/VI parity.
5. **Project Synchronization**: Update `scripts/generate_xcodeproj.py` for moved and new files and re-generate `project.pbxproj`.
