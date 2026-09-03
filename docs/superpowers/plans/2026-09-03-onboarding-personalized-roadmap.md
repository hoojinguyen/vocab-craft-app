# Onboarding & Personalized Learning Roadmap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a 4-step onboarding flow for VocabCraft that captures learner goals, self-assesses CEFR proficiency, sets daily habits and reminders, synthesizes a customized learning roadmap on `CraftLearningPath`, and delivers an immediate "First Win" 3-word mini-lesson unlocking Day-1 streak.

**Architecture:** MVVM architecture with Domain Use Cases. `OnboardingCoordinatorView` coordinates 4 child step views using `CraftStepProgressIndicator` and `CraftChoiceCard`. `InitializeUserRoadmapUseCase` writes user choices into `UserSettingsStore`, applies the auto-unlock algorithm in `StageProgressRepositoryProtocol`, schedules push notifications, and provisions initial words for `OnboardingFirstLessonView`.

**Tech Stack:** Swift 6 / SwiftUI, Observation framework (`@Observable`), SwiftData, CraftUIKit design system, SpeechKit (TTS), Swift Testing (`@Test` / XCTest), Localizable.xcstrings (bilingual EN & VI).

## Global Constraints

- 100% CraftUIKit-First: Re-use `CraftChoiceCard`, `CraftButton`, `CraftStepProgressIndicator`, `CraftPulsingAuraRing`, `CraftCard`, `CraftBadge`, `CraftStreakBadge`. No custom raw styling or ad-hoc colors.
- Zero Hardcoded Strings: All user-facing strings must use `app.onboarding.*` keys in `VocabCraftApp/Resources/Localizable.xcstrings` with 100% pair completeness for both English (`en`) and Vietnamese (`vi`).
- Zero Compiler Warnings & Zero SwiftLint Violations: A task is not complete if any warning or lint error exists.
- TDD Discipline: Write failing test first, verify failure, implement code, verify pass, and commit.

---

### Task 1: Update UserSettingsStore with Onboarding Properties & Tests

**Files:**
- Modify: `VocabCraftApp/Core/Database/UserSettingsStore.swift`
- Modify: `VocabCraftAppTests/UserSettingsStoreTests.swift`

**Interfaces:**
- Consumes: `UserDefaults.standard`
- Produces: 
  - `UserSettingsStore.hasCompletedOnboarding: Bool` (read/write, persistent key `"has_completed_onboarding"`, default: `false`)
  - `UserSettingsStore.selectedGoalDeckId: String` (read/write, persistent key `"selected_goal_deck_id"`, default: `"deck_daily"`)
  - `UserSettingsStore.assessedCefrLevel: String` (read/write, persistent key `"assessed_cefr_level"`, default: `"A1"`)

- [ ] **Step 1: Write the failing tests in UserSettingsStoreTests**

Add test methods to `VocabCraftAppTests/UserSettingsStoreTests.swift`:
```swift
    func testOnboardingSettingsDefaultAndPersistence() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "has_completed_onboarding")
        defaults.removeObject(forKey: "selected_goal_deck_id")
        defaults.removeObject(forKey: "assessed_cefr_level")

        let store = UserSettingsStore()
        XCTAssertFalse(store.hasCompletedOnboarding)
        XCTAssertEqual(store.selectedGoalDeckId, "deck_daily")
        XCTAssertEqual(store.assessedCefrLevel, "A1")

        store.hasCompletedOnboarding = true
        store.selectedGoalDeckId = "deck_business"
        store.assessedCefrLevel = "B2"

        XCTAssertTrue(defaults.bool(forKey: "has_completed_onboarding"))
        XCTAssertEqual(defaults.string(forKey: "selected_goal_deck_id"), "deck_business")
        XCTAssertEqual(defaults.string(forKey: "assessed_cefr_level"), "B2")
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter UserSettingsStoreTests/testOnboardingSettingsDefaultAndPersistence`
Expected: FAIL with error "value of type 'UserSettingsStore' has no member 'hasCompletedOnboarding'"

- [ ] **Step 3: Implement minimal properties in UserSettingsStore.swift**

In `VocabCraftApp/Core/Database/UserSettingsStore.swift`:
```swift
    public var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "has_completed_onboarding")
        }
    }

    public var selectedGoalDeckId: String {
        didSet {
            UserDefaults.standard.set(selectedGoalDeckId, forKey: "selected_goal_deck_id")
        }
    }

    public var assessedCefrLevel: String {
        didSet {
            UserDefaults.standard.set(assessedCefrLevel, forKey: "assessed_cefr_level")
        }
    }
```
And inside `init()`:
```swift
        self.hasCompletedOnboarding = defaults.bool(forKey: "has_completed_onboarding")
        self.selectedGoalDeckId = defaults.string(forKey: "selected_goal_deck_id") ?? "deck_daily"
        self.assessedCefrLevel = defaults.string(forKey: "assessed_cefr_level") ?? "A1"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter UserSettingsStoreTests/testOnboardingSettingsDefaultAndPersistence`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Database/UserSettingsStore.swift VocabCraftAppTests/UserSettingsStoreTests.swift
git commit -m "feat(settings): add onboarding flags and goal properties to UserSettingsStore"
```

---

### Task 2: Localization Keys in Localizable.xcstrings

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Create: `VocabCraftAppTests/Features/OnboardingLocalizationTests.swift`

**Interfaces:**
- Consumes: `Localizable.xcstrings` schema
- Produces: All `app.onboarding.*` strings with 100% EN & VI parity.

- [ ] **Step 1: Write the failing localization parity test**

Create `VocabCraftAppTests/Features/OnboardingLocalizationTests.swift`:
```swift
import Foundation
import XCTest

final class OnboardingLocalizationTests: XCTestCase {
    func testOnboardingKeysHaveBilingualParity() throws {
        let bundle = Bundle.module
        let requiredKeys = [
            "app.onboarding.common.skip",
            "app.onboarding.common.continue",
            "app.onboarding.goal.title",
            "app.onboarding.goal.subtitle",
            "app.onboarding.goal.daily",
            "app.onboarding.goal.daily_desc",
            "app.onboarding.goal.business",
            "app.onboarding.goal.business_desc",
            "app.onboarding.goal.academic",
            "app.onboarding.goal.academic_desc",
            "app.onboarding.goal.tech",
            "app.onboarding.goal.tech_desc",
            "app.onboarding.level.title",
            "app.onboarding.level.subtitle",
            "app.onboarding.level.a1",
            "app.onboarding.level.a1_desc",
            "app.onboarding.level.a2",
            "app.onboarding.level.a2_desc",
            "app.onboarding.level.b1_b2",
            "app.onboarding.level.b1_b2_desc",
            "app.onboarding.level.c1",
            "app.onboarding.level.c1_desc",
            "app.onboarding.habit.title",
            "app.onboarding.habit.subtitle",
            "app.onboarding.habit.words_per_day_format",
            "app.onboarding.habit.minutes_per_day_format",
            "app.onboarding.habit.popular_badge",
            "app.onboarding.habit.reminder_morning",
            "app.onboarding.habit.reminder_lunch",
            "app.onboarding.habit.reminder_evening",
            "app.onboarding.reveal.analyzing",
            "app.onboarding.reveal.curating",
            "app.onboarding.reveal.ready",
            "app.onboarding.reveal.projection_format",
            "app.onboarding.reveal.starting_stage_label",
            "app.onboarding.reveal.cta",
            "app.onboarding.mini_lesson.listen_cta",
            "app.onboarding.mini_lesson.check_cta",
            "app.onboarding.mini_lesson.next_cta",
            "app.onboarding.celebration.title",
            "app.onboarding.celebration.subtitle",
            "app.onboarding.celebration.cta"
        ]

        for key in requiredKeys {
            let enString = String(localized: String.LocalizationValue(key), locale: Locale(identifier: "en"), bundle: bundle)
            let viString = String(localized: String.LocalizationValue(key), locale: Locale(identifier: "vi"), bundle: bundle)
            XCTAssertNotEqual(enString, key, "Missing EN translation for \(key)")
            XCTAssertNotEqual(viString, key, "Missing VI translation for \(key)")
            XCTAssertFalse(enString.isEmpty, "Empty EN translation for \(key)")
            XCTAssertFalse(viString.isEmpty, "Empty VI translation for \(key)")
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter OnboardingLocalizationTests`
Expected: FAIL with "Missing EN translation for app.onboarding..."

- [ ] **Step 3: Add all required strings to Localizable.xcstrings**

In `VocabCraftApp/Resources/Localizable.xcstrings`, add entries for all 42 keys with matching `en` and `vi` translations, setting `"extractionState": "manual"` and `"state": "translated"`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter OnboardingLocalizationTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftAppTests/Features/OnboardingLocalizationTests.swift
git commit -m "feat(l10n): add comprehensive onboarding localization keys in EN and VI"
```

---

### Task 3: InitializeUserRoadmapUseCase & Unit Tests

**Files:**
- Create: `VocabCraftApp/Domain/UseCases/InitializeUserRoadmapUseCase.swift`
- Create: `VocabCraftAppTests/Domain/InitializeUserRoadmapUseCaseTests.swift`

**Interfaces:**
- Consumes: `VocabularyDataSourceProtocol`, `StageProgressRepositoryProtocol`, `UserSettingsStore`
- Produces: `InitializeUserRoadmapUseCaseProtocol` returning `RoadmapInitializationResult` (startingStage: `SubTopicStageDTO`, starterWords: `[TopicWordDTO]`).

- [ ] **Step 1: Write the failing unit tests**

Create `VocabCraftAppTests/Domain/InitializeUserRoadmapUseCaseTests.swift`:
```swift
import Foundation
@testable import VocabCraftApp
import XCTest

final class InitializeUserRoadmapUseCaseTests: XCTestCase {
    @MainActor
    func testInitializeRoadmapForBeginnerA1() async throws {
        let dataSource = SampleVocabularyDataSource()
        let stageRepo = MockStageProgressRepository()
        let settings = UserSettingsStore()

        let useCase = InitializeUserRoadmapUseCase(
            dataSource: dataSource,
            stageRepo: stageRepo,
            userSettings: settings
        )

        let result = try await useCase.execute(
            deckId: "deck_daily",
            cefrLevel: "A1",
            dailyGoalCount: 10,
            notificationTimeInterval: 72000
        )

        XCTAssertEqual(settings.selectedGoalDeckId, "deck_daily")
        XCTAssertEqual(settings.assessedCefrLevel, "A1")
        XCTAssertEqual(settings.dailyGoalCount, 10)
        XCTAssertEqual(settings.notificationTimeInterval, 72000)

        // Stage 1 of deck_daily should be the starting stage
        XCTAssertEqual(result.startingStage.id, "stage_daily_1")
        XCTAssertEqual(result.starterWords.count, 3)

        // No stages should be prematurely marked completed for A1
        let allProgress = try await stageRepo.fetchAllStageProgress()
        XCTAssertTrue(allProgress.isEmpty || allProgress.allSatisfy { !$0.isCompleted })
    }

    @MainActor
    func testInitializeRoadmapForIntermediateB1AutoUnlocksFoundationalStage() async throws {
        let dataSource = SampleVocabularyDataSource()
        let stageRepo = MockStageProgressRepository()
        let settings = UserSettingsStore()

        let useCase = InitializeUserRoadmapUseCase(
            dataSource: dataSource,
            stageRepo: stageRepo,
            userSettings: settings
        )

        let result = try await useCase.execute(
            deckId: "deck_daily",
            cefrLevel: "B1",
            dailyGoalCount: 15,
            notificationTimeInterval: 28800
        )

        // Preceding stage (stage_daily_1) should be marked completed
        let progressList = try await stageRepo.fetchAllStageProgress()
        let completedStage = progressList.first { $0.stageId == "stage_daily_1" }
        XCTAssertNotNil(completedStage)
        XCTAssertTrue(completedStage?.isCompleted == true)
        XCTAssertEqual(completedStage?.progressFraction, 1.0)

        // Starting stage is stage_daily_2
        XCTAssertEqual(result.startingStage.id, "stage_daily_2")
        XCTAssertEqual(result.starterWords.count, 3)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter InitializeUserRoadmapUseCaseTests`
Expected: FAIL with "cannot find type 'InitializeUserRoadmapUseCase'"

- [ ] **Step 3: Implement InitializeUserRoadmapUseCase.swift**

Create `VocabCraftApp/Domain/UseCases/InitializeUserRoadmapUseCase.swift`:
```swift
import Foundation

public struct RoadmapInitializationResult: Sendable, Equatable {
    public let startingStage: SubTopicStageDTO
    public let starterWords: [TopicWordDTO]

    public init(startingStage: SubTopicStageDTO, starterWords: [TopicWordDTO]) {
        self.startingStage = startingStage
        self.starterWords = starterWords
    }
}

public protocol InitializeUserRoadmapUseCaseProtocol: Sendable {
    @MainActor
    func execute(
        deckId: String,
        cefrLevel: String,
        dailyGoalCount: Int,
        notificationTimeInterval: Double
    ) async throws -> RoadmapInitializationResult
}

public final class InitializeUserRoadmapUseCase: InitializeUserRoadmapUseCaseProtocol, Sendable {
    private let dataSource: VocabularyDataSourceProtocol
    private let stageRepo: StageProgressRepositoryProtocol
    private let userSettings: UserSettingsStore

    public init(
        dataSource: VocabularyDataSourceProtocol,
        stageRepo: StageProgressRepositoryProtocol,
        userSettings: UserSettingsStore
    ) {
        self.dataSource = dataSource
        self.stageRepo = stageRepo
        self.userSettings = userSettings
    }

    @MainActor
    public func execute(
        deckId: String,
        cefrLevel: String,
        dailyGoalCount: Int,
        notificationTimeInterval: Double
    ) async throws -> RoadmapInitializationResult {
        // 1. Persist user preferences
        userSettings.selectedGoalDeckId = deckId
        userSettings.assessedCefrLevel = cefrLevel
        userSettings.dailyGoalCount = dailyGoalCount
        userSettings.notificationTimeInterval = notificationTimeInterval

        // 2. Fetch stages for the target deck
        let stages = try await dataSource.fetchSubTopicStages(deckId: deckId)
        let sortedStages = stages.sorted { $0.sortOrder < $1.sortOrder }

        guard let firstStage = sortedStages.first else {
            throw VocabularyDomainError.stageNotFound(deckId)
        }

        let isAdvancedLevel = (cefrLevel == "B1" || cefrLevel == "B2" || cefrLevel == "C1")
        let startingStage: SubTopicStageDTO

        if isAdvancedLevel && sortedStages.count > 1 {
            // Auto-unlock foundational stage 1
            try await stageRepo.saveStageProgress(
                stageId: firstStage.id,
                deckId: deckId,
                isCompleted: true,
                score: 100,
                progressFraction: 1.0
            )
            startingStage = sortedStages[1]
        } else {
            startingStage = firstStage
        }

        // 3. Fetch starter words
        let words = try await dataSource.fetchWordsForStage(stageId: startingStage.id)
        let starterWords = Array(words.prefix(3))

        return RoadmapInitializationResult(
            startingStage: startingStage,
            starterWords: starterWords
        )
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter InitializeUserRoadmapUseCaseTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/UseCases/InitializeUserRoadmapUseCase.swift VocabCraftAppTests/Domain/InitializeUserRoadmapUseCaseTests.swift
git commit -m "feat(domain): add InitializeUserRoadmapUseCase with CEFR auto-unlock and starter words retrieval"
```

---

### Task 4: OnboardingViewModel & Step State Management

**Files:**
- Create: `VocabCraftApp/Features/Onboarding/Models/OnboardingStep.swift`
- Create: `VocabCraftApp/Features/Onboarding/ViewModels/OnboardingViewModel.swift`
- Create: `VocabCraftAppTests/Features/OnboardingViewModelTests.swift`

**Interfaces:**
- Consumes: `InitializeUserRoadmapUseCaseProtocol`, `UserSettingsStore`
- Produces: `@Observable OnboardingViewModel` managing step index, user selections, roadmap synthesis, and mini-lesson payload.

- [ ] **Step 1: Write failing unit tests for OnboardingViewModel**

Create `VocabCraftAppTests/Features/OnboardingViewModelTests.swift`:
```swift
import Foundation
@testable import VocabCraftApp
import XCTest

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    func testInitialStateAndStepProgression() {
        let settings = UserSettingsStore()
        let useCase = MockInitializeUserRoadmapUseCase()
        let vm = OnboardingViewModel(useCase: useCase, userSettings: settings)

        XCTAssertEqual(vm.currentStep, .goal)
        XCTAssertFalse(vm.canGoBack)
        XCTAssertTrue(vm.canContinue) // Default goal is selected

        vm.nextStep()
        XCTAssertEqual(vm.currentStep, .proficiency)
        XCTAssertTrue(vm.canGoBack)

        vm.nextStep()
        XCTAssertEqual(vm.currentStep, .habit)

        vm.nextStep()
        XCTAssertEqual(vm.currentStep, .roadmapReveal)

        vm.previousStep()
        XCTAssertEqual(vm.currentStep, .habit)
    }

    func testSkipSetsDefaultsAndCompletes() {
        let settings = UserSettingsStore()
        settings.hasCompletedOnboarding = false
        let useCase = MockInitializeUserRoadmapUseCase()
        let vm = OnboardingViewModel(useCase: useCase, userSettings: settings)

        vm.skipOnboarding()

        XCTAssertTrue(settings.hasCompletedOnboarding)
        XCTAssertEqual(settings.selectedGoalDeckId, "deck_daily")
        XCTAssertEqual(settings.assessedCefrLevel, "A1")
        XCTAssertEqual(settings.dailyGoalCount, 10)
    }

    func testGenerateRoadmapPopulatesResult() async {
        let settings = UserSettingsStore()
        let useCase = MockInitializeUserRoadmapUseCase()
        let vm = OnboardingViewModel(useCase: useCase, userSettings: settings)

        vm.selectedDeckId = "deck_business"
        vm.selectedCefrLevel = "B1"
        vm.selectedDailyWords = 15

        await vm.synthesizeRoadmap()

        XCTAssertNotNil(vm.roadmapResult)
        XCTAssertEqual(vm.roadmapResult?.starterWords.count, 3)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter OnboardingViewModelTests`
Expected: FAIL with "cannot find type 'OnboardingViewModel'"

- [ ] **Step 3: Implement OnboardingStep.swift and OnboardingViewModel.swift**

Create `VocabCraftApp/Features/Onboarding/Models/OnboardingStep.swift`:
```swift
import Foundation

public enum OnboardingStep: Int, CaseIterable, Sendable, Comparable {
    case goal = 0
    case proficiency = 1
    case habit = 2
    case roadmapReveal = 3

    public static func < (lhs: OnboardingStep, rhs: OnboardingStep) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
```

Create `VocabCraftApp/Features/Onboarding/ViewModels/OnboardingViewModel.swift`:
```swift
import Foundation
import Observation

@MainActor
@Observable
public final class OnboardingViewModel {
    public var currentStep: OnboardingStep = .goal
    public var selectedDeckId: String = "deck_daily"
    public var selectedCefrLevel: String = "A1"
    public var selectedDailyWords: Int = 10
    public var selectedReminderInterval: Double = 72000 // 20:00

    public var isSynthesizing: Bool = false
    public var synthesisPhaseTextKey: String = "app.onboarding.reveal.analyzing"
    public var roadmapResult: RoadmapInitializationResult?
    public var isPresentingMiniLesson: Bool = false
    public var errorMessage: String?

    private let useCase: InitializeUserRoadmapUseCaseProtocol
    private let userSettings: UserSettingsStore

    public init(useCase: InitializeUserRoadmapUseCaseProtocol, userSettings: UserSettingsStore) {
        self.useCase = useCase
        self.userSettings = userSettings
    }

    public var canGoBack: Bool {
        currentStep.rawValue > 0 && !isSynthesizing
    }

    public var canContinue: Bool {
        switch currentStep {
        case .goal: return !selectedDeckId.isEmpty
        case .proficiency: return !selectedCefrLevel.isEmpty
        case .habit: return selectedDailyWords > 0
        case .roadmapReveal: return roadmapResult != nil && !isSynthesizing
        }
    }

    public func nextStep() {
        guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = next
        if currentStep == .roadmapReveal && roadmapResult == nil {
            Task { await synthesizeRoadmap() }
        }
    }

    public func previousStep() {
        guard let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prev
    }

    public func skipOnboarding() {
        userSettings.selectedGoalDeckId = "deck_daily"
        userSettings.assessedCefrLevel = "A1"
        userSettings.dailyGoalCount = 10
        userSettings.notificationTimeInterval = 72000
        userSettings.hasCompletedOnboarding = true
    }

    public func synthesizeRoadmap() async {
        isSynthesizing = true
        errorMessage = nil

        // Visual animation staging
        synthesisPhaseTextKey = "app.onboarding.reveal.analyzing"
        try? await Task.sleep(nanoseconds: 500_000_000)

        synthesisPhaseTextKey = "app.onboarding.reveal.curating"
        try? await Task.sleep(nanoseconds: 600_000_000)

        do {
            let result = try await useCase.execute(
                deckId: selectedDeckId,
                cefrLevel: selectedCefrLevel,
                dailyGoalCount: selectedDailyWords,
                notificationTimeInterval: selectedReminderInterval
            )
            self.roadmapResult = result
            self.synthesisPhaseTextKey = "app.onboarding.reveal.ready"
        } catch {
            self.errorMessage = error.localizedDescription
        }

        try? await Task.sleep(nanoseconds: 400_000_000)
        self.isSynthesizing = false
    }

    public func startFirstLesson() {
        isPresentingMiniLesson = true
    }

    public func completeOnboardingAndDismiss() {
        userSettings.hasCompletedOnboarding = true
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter OnboardingViewModelTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Onboarding/Models/OnboardingStep.swift VocabCraftApp/Features/Onboarding/ViewModels/OnboardingViewModel.swift VocabCraftAppTests/Features/OnboardingViewModelTests.swift
git commit -m "feat(onboarding): implement OnboardingStep and OnboardingViewModel state management"
```

---

### Task 5: Step 1 & 2 Views (Goal & Proficiency)

**Files:**
- Create: `VocabCraftApp/Features/Onboarding/Views/OnboardingGoalStepView.swift`
- Create: `VocabCraftApp/Features/Onboarding/Views/OnboardingProficiencyStepView.swift`

**Interfaces:**
- Consumes: `CraftChoiceCard`, `CraftButton`, `CraftTheme`, `@Bindable OnboardingViewModel`
- Produces: SwiftUI Views for Step 1 (Topic Decks) and Step 2 (CEFR Levels)

- [ ] **Step 1: Implement OnboardingGoalStepView.swift**

Create `VocabCraftApp/Features/Onboarding/Views/OnboardingGoalStepView.swift`:
```swift
import CraftUIKit
import SwiftUI

public struct OnboardingGoalStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.craftTheme) private var theme

    private let goals: [(id: String, titleKey: LocalizedStringKey, descKey: LocalizedStringKey, icon: String)] = [
        ("deck_daily", "app.onboarding.goal.daily", "app.onboarding.goal.daily_desc", "bubble.left.and.bubble.right"),
        ("deck_business", "app.onboarding.goal.business", "app.onboarding.goal.business_desc", "briefcase"),
        ("deck_academic", "app.onboarding.goal.academic", "app.onboarding.goal.academic_desc", "graduationcap"),
        ("deck_tech", "app.onboarding.goal.tech", "app.onboarding.goal.tech_desc", "cpu")
    ]

    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text("app.onboarding.goal.title")
                    .font(theme.typography.title2)
                    .foregroundStyle(theme.colors.textPrimary)

                Text("app.onboarding.goal.subtitle")
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            .padding(.horizontal, theme.spacing.base)

            ScrollView(showsIndicators: false) {
                VStack(spacing: theme.spacing.md) {
                    ForEach(goals, id: \.id) { goal in
                        CraftChoiceCard(
                            prefix: nil,
                            prefixStyle: .none,
                            title: goal.titleKey,
                            subtitle: goal.descKey,
                            state: viewModel.selectedDeckId == goal.id ? .selected : .idle,
                            showsStatusIndicator: false,
                            action: {
                                CraftHaptics.shared.selection()
                                viewModel.selectedDeckId = goal.id
                            }
                        )
                    }
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.bottom, theme.spacing.xl)
            }

            Spacer()

            CraftButton(
                "app.onboarding.common.continue",
                variant: .primary,
                size: .lg,
                isEnabled: viewModel.canContinue
            ) {
                viewModel.nextStep()
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.bottom, theme.spacing.base)
        }
    }
}
```

- [ ] **Step 2: Implement OnboardingProficiencyStepView.swift**

Create `VocabCraftApp/Features/Onboarding/Views/OnboardingProficiencyStepView.swift`:
```swift
import CraftUIKit
import SwiftUI

public struct OnboardingProficiencyStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.craftTheme) private var theme

    private let levels: [(id: String, titleKey: LocalizedStringKey, descKey: LocalizedStringKey)] = [
        ("A1", "app.onboarding.level.a1", "app.onboarding.level.a1_desc"),
        ("A2", "app.onboarding.level.a2", "app.onboarding.level.a2_desc"),
        ("B1", "app.onboarding.level.b1_b2", "app.onboarding.level.b1_b2_desc"),
        ("C1", "app.onboarding.level.c1", "app.onboarding.level.c1_desc")
    ]

    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text("app.onboarding.level.title")
                    .font(theme.typography.title2)
                    .foregroundStyle(theme.colors.textPrimary)

                Text("app.onboarding.level.subtitle")
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            .padding(.horizontal, theme.spacing.base)

            ScrollView(showsIndicators: false) {
                VStack(spacing: theme.spacing.md) {
                    ForEach(levels, id: \.id) { level in
                        CraftChoiceCard(
                            prefix: level.id,
                            prefixStyle: .roundedSquare,
                            title: level.titleKey,
                            subtitle: level.descKey,
                            state: viewModel.selectedCefrLevel == level.id ? .selected : .idle,
                            showsStatusIndicator: false,
                            action: {
                                CraftHaptics.shared.selection()
                                viewModel.selectedCefrLevel = level.id
                            }
                        )
                    }
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.bottom, theme.spacing.xl)
            }

            Spacer()

            CraftButton(
                "app.onboarding.common.continue",
                variant: .primary,
                size: .lg,
                isEnabled: viewModel.canContinue
            ) {
                viewModel.nextStep()
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.bottom, theme.spacing.base)
        }
    }
}
```

- [ ] **Step 3: Verify build**

Run: `swift build --target VocabCraftApp`
Expected: PASS with 0 warnings.

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Features/Onboarding/Views/OnboardingGoalStepView.swift VocabCraftApp/Features/Onboarding/Views/OnboardingProficiencyStepView.swift
git commit -m "feat(onboarding): add OnboardingGoalStepView and OnboardingProficiencyStepView"
```

---

### Task 6: Step 3 & 4 Views (Habit & Roadmap Reveal)

**Files:**
- Create: `VocabCraftApp/Features/Onboarding/Views/OnboardingHabitStepView.swift`
- Create: `VocabCraftApp/Features/Onboarding/Views/OnboardingRoadmapRevealStepView.swift`

**Interfaces:**
- Consumes: `CraftChoiceCard`, `CraftPulsingAuraRing`, `CraftCard`, `CraftBadge`, `CraftButton`
- Produces: SwiftUI Views for Step 3 (Habit & Reminder) and Step 4 (Roadmap Reveal & Projection)

- [ ] **Step 1: Implement OnboardingHabitStepView.swift**

Create `VocabCraftApp/Features/Onboarding/Views/OnboardingHabitStepView.swift`:
```swift
import CraftUIKit
import SwiftUI
import UserNotifications

public struct OnboardingHabitStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.craftTheme) private var theme

    private let wordOptions: [(words: Int, minutes: Int, isPopular: Bool)] = [
        (5, 5, false),
        (10, 10, true),
        (15, 15, false),
        (20, 20, false)
    ]

    private let reminderOptions: [(titleKey: LocalizedStringKey, interval: Double)] = [
        ("app.onboarding.habit.reminder_morning", 28800),  // 08:00
        ("app.onboarding.habit.reminder_lunch", 45000),    // 12:30
        ("app.onboarding.habit.reminder_evening", 72000)   // 20:00
    ]

    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text("app.onboarding.habit.title")
                    .font(theme.typography.title2)
                    .foregroundStyle(theme.colors.textPrimary)

                Text("app.onboarding.habit.subtitle")
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            .padding(.horizontal, theme.spacing.base)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: theme.spacing.lg) {
                    // Daily Word Goals
                    VStack(spacing: theme.spacing.md) {
                        ForEach(wordOptions, id: \.words) { opt in
                            CraftChoiceCard(
                                prefix: nil,
                                prefixStyle: .none,
                                title: String(localized: "app.onboarding.habit.words_per_day_format", defaultValue: "\(opt.words) words per day", bundle: .module),
                                subtitle: String(localized: "app.onboarding.habit.minutes_per_day_format", defaultValue: "\(opt.minutes) minutes / day", bundle: .module),
                                state: viewModel.selectedDailyWords == opt.words ? .selected : .idle,
                                showsStatusIndicator: false,
                                action: {
                                    CraftHaptics.shared.selection()
                                    viewModel.selectedDailyWords = opt.words
                                }
                            )
                        }
                    }

                    // Reminder Time Header
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        Text(verbatim: "Daily Reminder")
                            .font(theme.typography.headline)
                            .foregroundStyle(theme.colors.textPrimary)

                        HStack(spacing: theme.spacing.sm) {
                            ForEach(reminderOptions, id: \.interval) { opt in
                                Button {
                                    CraftHaptics.shared.selection()
                                    viewModel.selectedReminderInterval = opt.interval
                                } label: {
                                    Text(opt.titleKey)
                                        .font(theme.typography.caption)
                                        .fontWeight(.semibold)
                                        .padding(.vertical, theme.spacing.sm)
                                        .padding(.horizontal, theme.spacing.md)
                                        .background(
                                            viewModel.selectedReminderInterval == opt.interval
                                                ? theme.colors.brandPrimary
                                                : theme.colors.surfaceCard
                                        )
                                        .foregroundStyle(
                                            viewModel.selectedReminderInterval == opt.interval
                                                ? theme.colors.textInverse
                                                : theme.colors.textPrimary
                                        )
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.bottom, theme.spacing.xl)
            }

            Spacer()

            CraftButton(
                "app.onboarding.common.continue",
                variant: .primary,
                size: .lg,
                isEnabled: viewModel.canContinue
            ) {
                requestNotificationPermissionAndAdvance()
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.bottom, theme.spacing.base)
        }
    }

    private func requestNotificationPermissionAndAdvance() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            DispatchQueue.main.async {
                viewModel.nextStep()
            }
        }
    }
}
```

- [ ] **Step 2: Implement OnboardingRoadmapRevealStepView.swift**

Create `VocabCraftApp/Features/Onboarding/Views/OnboardingRoadmapRevealStepView.swift`:
```swift
import CraftUIKit
import SwiftUI

public struct OnboardingRoadmapRevealStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.craftTheme) private var theme

    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: theme.spacing.xl) {
            Spacer()

            if viewModel.isSynthesizing {
                VStack(spacing: theme.spacing.lg) {
                    CraftPulsingAuraRing(
                        size: 120,
                        ringCount: 3,
                        tintColor: theme.colors.brandPrimary
                    )

                    Text(LocalizedStringKey(viewModel.synthesisPhaseTextKey))
                        .font(theme.typography.title3)
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
            } else if let result = viewModel.roadmapResult {
                VStack(spacing: theme.spacing.lg) {
                    CraftCard {
                        VStack(spacing: theme.spacing.base) {
                            HStack {
                                CraftBadge(
                                    viewModel.selectedCefrLevel,
                                    variant: .brand,
                                    size: .md
                                )
                                Spacer()
                                Text(result.startingStage.title)
                                    .font(theme.typography.caption)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                                Text("app.onboarding.reveal.ready")
                                    .font(theme.typography.title2)
                                    .foregroundStyle(theme.colors.textPrimary)

                                let projectedWords = viewModel.selectedDailyWords * 30
                                Text(String(localized: "app.onboarding.reveal.projection_format", defaultValue: "With \(viewModel.selectedDailyWords) words/day, you'll master \(projectedWords) words in 30 days!", bundle: .module))
                                    .font(theme.typography.bodyMedium)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, theme.spacing.base)

                    CraftButton(
                        "app.onboarding.reveal.cta",
                        variant: .primary,
                        size: .lg
                    ) {
                        viewModel.startFirstLesson()
                    }
                    .padding(.horizontal, theme.spacing.base)
                }
                .transition(.scale.combined(with: .opacity))
            }

            Spacer()
        }
    }
}
```

- [ ] **Step 3: Verify build**

Run: `swift build --target VocabCraftApp`
Expected: PASS with 0 warnings.

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Features/Onboarding/Views/OnboardingHabitStepView.swift VocabCraftApp/Features/Onboarding/Views/OnboardingRoadmapRevealStepView.swift
git commit -m "feat(onboarding): add OnboardingHabitStepView and OnboardingRoadmapRevealStepView"
```

---

### Task 7: First Win Mini-Lesson & Streak Celebration Sheet

**Files:**
- Create: `VocabCraftApp/Features/Onboarding/Views/OnboardingFirstLessonView.swift`
- Create: `VocabCraftApp/Features/Onboarding/Views/OnboardingCelebrationSheet.swift`

**Interfaces:**
- Consumes: `TextToSpeechProtocol`, `CraftChoiceCard`, `CraftButton`, `CraftStreakBadge`
- Produces: 3-word mini-lesson view and Day-1 celebration sheet triggering completion.

- [ ] **Step 1: Implement OnboardingFirstLessonView.swift**

Create `VocabCraftApp/Features/Onboarding/Views/OnboardingFirstLessonView.swift`:
```swift
import CraftUIKit
import SpeechKit
import SwiftUI

public struct OnboardingFirstLessonView: View {
    public let words: [TopicWordDTO]
    public let onFinish: () -> Void

    @State private var currentIndex: Int = 0
    @State private var selectedAnswer: String?
    @State private var isAnswerCorrect: Bool?
    @State private var isCelebrationPresented: Bool = false
    @Environment(\.craftTheme) private var theme
    @Environment(\.ttsService) private var ttsService

    public init(words: [TopicWordDTO], onFinish: @escaping () -> Void) {
        self.words = words.isEmpty ? [
            TopicWordDTO(id: 1, stageId: "starter", lemma: "Resilience", phonetic: "/rɪˈzɪl.jəns/", pos: "noun", cefrLevel: "B1", definitionVi: "Sự kiên cường", definitionEn: "Ability to recover quickly", exampleEn: "Her resilience inspired everyone.", exampleVi: "Sự kiên cường của cô ấy đã truyền cảm hứng.")
        ] : words
        self.onFinish = onFinish
    }

    private var currentWord: TopicWordDTO {
        words[currentIndex]
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground.ignoresSafeArea()

            VStack(spacing: theme.spacing.lg) {
                // Header Progress
                CraftStepProgressIndicator(
                    totalSteps: words.count,
                    currentStep: currentIndex,
                    counterStyle: .ratio
                )
                .padding(.horizontal, theme.spacing.base)
                .padding(.top, theme.spacing.base)

                Spacer()

                // Word Flashcard Surface
                VStack(spacing: theme.spacing.md) {
                    Text(currentWord.lemma)
                        .font(theme.typography.displaySmall)
                        .foregroundStyle(theme.colors.textPrimary)

                    if let phonetic = currentWord.phonetic {
                        Text(phonetic)
                            .font(theme.typography.headline)
                            .foregroundStyle(theme.colors.textSecondary)
                    }

                    CraftIconButton(icon: .speakerWave2, size: .lg) {
                        ttsService?.speak(text: currentWord.lemma, language: "en-US")
                    }
                }
                .padding(theme.spacing.xl)
                .frame(maxWidth: .infinity)
                .background(theme.colors.surfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg))
                .padding(.horizontal, theme.spacing.base)

                // Quick Meaning Choice
                VStack(spacing: theme.spacing.sm) {
                    CraftChoiceCard(
                        prefix: nil,
                        prefixStyle: .none,
                        title: currentWord.definitionVi ?? currentWord.definitionEn ?? "",
                        state: selectedAnswer != nil ? .correct : .idle,
                        showsStatusIndicator: false
                    ) {
                        handleSelection(answer: currentWord.definitionVi ?? "")
                    }
                }
                .padding(.horizontal, theme.spacing.base)

                Spacer()

                CraftButton(
                    currentIndex == words.count - 1 ? "app.onboarding.mini_lesson.check_cta" : "app.onboarding.mini_lesson.next_cta",
                    variant: .primary,
                    size: .lg,
                    isEnabled: selectedAnswer != nil
                ) {
                    advanceNextWord()
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.bottom, theme.spacing.base)
            }
        }
        .sheet(isPresented: $isCelebrationPresented) {
            OnboardingCelebrationSheet {
                isCelebrationPresented = false
                onFinish()
            }
        }
        .onAppear {
            ttsService?.speak(text: currentWord.lemma, language: "en-US")
        }
    }

    private func handleSelection(answer: String) {
        selectedAnswer = answer
        CraftHaptics.shared.success()
    }

    private func advanceNextWord() {
        if currentIndex + 1 < words.count {
            currentIndex += 1
            selectedAnswer = nil
            ttsService?.speak(text: currentWord.lemma, language: "en-US")
        } else {
            isCelebrationPresented = true
        }
    }
}
```

- [ ] **Step 2: Implement OnboardingCelebrationSheet.swift**

Create `VocabCraftApp/Features/Onboarding/Views/OnboardingCelebrationSheet.swift`:
```swift
import CraftUIKit
import SwiftUI

public struct OnboardingCelebrationSheet: View {
    public let onDismiss: () -> Void
    @State private var confettiTrigger: Bool = false
    @Environment(\.craftTheme) private var theme

    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground.ignoresSafeArea()

            VStack(spacing: theme.spacing.xl) {
                Spacer()

                VStack(spacing: theme.spacing.base) {
                    CraftStreakBadge(streak: 1, size: .lg)

                    Text("app.onboarding.celebration.title")
                        .font(theme.typography.title1)
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("app.onboarding.celebration.subtitle")
                        .font(theme.typography.bodyMedium)
                        .foregroundStyle(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, theme.spacing.base)
                }

                Spacer()

                CraftButton(
                    "app.onboarding.celebration.cta",
                    variant: .primary,
                    size: .lg
                ) {
                    onDismiss()
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.bottom, theme.spacing.xl)
            }
        }
        .craftConfetti(isTriggered: $confettiTrigger, particleCount: 40)
        .onAppear {
            confettiTrigger = true
            CraftHaptics.shared.success()
        }
    }
}
```

- [ ] **Step 3: Verify build**

Run: `swift build --target VocabCraftApp`
Expected: PASS with 0 warnings.

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Features/Onboarding/Views/OnboardingFirstLessonView.swift VocabCraftApp/Features/Onboarding/Views/OnboardingCelebrationSheet.swift
git commit -m "feat(onboarding): add OnboardingFirstLessonView and Day 1 OnboardingCelebrationSheet"
```

---

### Task 8: OnboardingCoordinatorView, DI in AppContainer & App Integration

**Files:**
- Create: `VocabCraftApp/Features/Onboarding/Views/OnboardingCoordinatorView.swift`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Modify: `VocabCraftApp/App/VocabCraftApp.swift`

**Interfaces:**
- Consumes: `AppContainer`, `OnboardingViewModel`, `OnboardingCoordinatorView`
- Produces: Seamless root-level presentation conditionally checking `hasCompletedOnboarding`.

- [ ] **Step 1: Implement OnboardingCoordinatorView.swift**

Create `VocabCraftApp/Features/Onboarding/Views/OnboardingCoordinatorView.swift`:
```swift
import CraftUIKit
import SwiftUI

public struct OnboardingCoordinatorView: View {
    @State private var viewModel: OnboardingViewModel
    @Environment(\.craftTheme) private var theme

    public init(viewModel: OnboardingViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation Header
                HStack {
                    if viewModel.canGoBack {
                        CraftIconButton(icon: .chevronLeft, size: .md) {
                            viewModel.previousStep()
                        }
                    } else {
                        Spacer().frame(width: 44)
                    }

                    Spacer()

                    CraftStepProgressIndicator(
                        totalSteps: 4,
                        currentStep: viewModel.currentStep.rawValue,
                        counterStyle: .phrase
                    )

                    Spacer()

                    Button {
                        viewModel.skipOnboarding()
                    } label: {
                        Text("app.onboarding.common.skip")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: 44)
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.top, theme.spacing.sm)

                // Current Step Transition
                Group {
                    switch viewModel.currentStep {
                    case .goal:
                        OnboardingGoalStepView(viewModel: viewModel)
                    case .proficiency:
                        OnboardingProficiencyStepView(viewModel: viewModel)
                    case .habit:
                        OnboardingHabitStepView(viewModel: viewModel)
                    case .roadmapReveal:
                        OnboardingRoadmapRevealStepView(viewModel: viewModel)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(theme.animations.springSmooth, value: viewModel.currentStep)
            }
        }
        .fullScreenCover(isPresented: $viewModel.isPresentingMiniLesson) {
            OnboardingFirstLessonView(
                words: viewModel.roadmapResult?.starterWords ?? []
            ) {
                viewModel.completeOnboardingAndDismiss()
            }
        }
    }
}
```

- [ ] **Step 2: Add factory method to AppContainer.swift**

In `VocabCraftApp/App/DI/AppContainer.swift`:
```swift
    public func makeInitializeUserRoadmapUseCase() -> InitializeUserRoadmapUseCaseProtocol {
        InitializeUserRoadmapUseCase(
            dataSource: vocabularyDataSource,
            stageRepo: stageProgressRepository,
            userSettings: userSettingsStore
        )
    }

    public func makeOnboardingViewModel() -> OnboardingViewModel {
        OnboardingViewModel(
            useCase: makeInitializeUserRoadmapUseCase(),
            userSettings: userSettingsStore
        )
    }
```

- [ ] **Step 3: Update VocabCraftApp.swift to conditionally present OnboardingCoordinatorView**

In `VocabCraftApp/App/VocabCraftApp.swift`:
```swift
            Group {
                if NSClassFromString("XCTestCase") != nil {
                    Text("Testing...")
                } else if !appContainer.userSettingsStore.hasCompletedOnboarding {
                    OnboardingCoordinatorView(viewModel: appContainer.makeOnboardingViewModel())
                        .environment(\.appContainer, appContainer)
                        .environment(\.appRouter, appContainer.appRouter)
                        .environment(\.ttsService, appContainer.ttsService)
                        .environment(\.speechAssessmentService, appContainer.speechAssessmentService)
                } else {
                    HomepageView(viewModel: appContainer.makeHomepageViewModel())
                        .environment(\.appContainer, appContainer)
                        .environment(\.appRouter, appContainer.appRouter)
                        .environment(\.ttsService, appContainer.ttsService)
                        .environment(\.speechAssessmentService, appContainer.speechAssessmentService)
                        .onOpenURL { url in
                            appContainer.appRouter.handleDeepLink(url: url)
                        }
                }
            }
```

- [ ] **Step 4: Verify build and tests pass**

Run: `swift test`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Onboarding/Views/OnboardingCoordinatorView.swift VocabCraftApp/App/DI/AppContainer.swift VocabCraftApp/App/VocabCraftApp.swift
git commit -m "feat(app): integrate OnboardingCoordinatorView and DI container routing"
```

---

### Task 9: End-to-End Verification & Quality Gates

**Files:**
- Audit all modified and new files.

**Interfaces:**
- Zero compiler warnings, 100% test pass rate, 0 SwiftLint violations.

- [ ] **Step 1: Run complete test suite**

Run: `swift test`
Expected: 100% tests passing across CraftUIKitTests, SpeechKitTests, and VocabCraftAppTests.

- [ ] **Step 2: Run SwiftLint check**

Run: `swiftlint lint --strict`
Expected: 0 errors, 0 warnings.

- [ ] **Step 3: Verify Xcode build with zero warnings**

Run: `xcodebuild -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build`
Expected: BUILD SUCCEEDED with 0 warnings.

- [ ] **Step 4: Final commit**

```bash
git commit --allow-empty -m "chore: verify onboarding implementation with 100% test pass and zero warnings"
```
