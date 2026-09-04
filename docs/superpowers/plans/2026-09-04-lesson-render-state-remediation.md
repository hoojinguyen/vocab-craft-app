# Lesson Render and State Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent dependency construction and broad lesson-state mutation from blocking keyboard input and step transitions.

**Architecture:** Preserve the current MV structure while stabilizing the environment fallback, moving draft typing state to the leaf view, and reducing per-frame sparkle computation. No navigation, layout, or lesson-content behavior changes.

**Tech Stack:** SwiftUI Observation, Swift Testing/XCTest, CraftUIKit, Instruments.

**Spec:** `docs/superpowers/specs/2026-09-04-real-device-lesson-runtime-remediation-design.md`

## Global Constraints

- Do not change visible design, spacing, button placement, scrolling, copy, or lesson progression.
- `AppContainer.mock` remains a fresh factory for test isolation.
- CraftUIKit styling continues to use existing tokens only.
- Follow RED-GREEN-REFACTOR for each behavior change.
- Final verification uses a Release build on the same iPhone 16 Pro.

---

### Task 1: Stabilize the SwiftUI environment fallback

**Files:**
- Modify: `VocabCraftApp/App/DI/EnvironmentKeys.swift`
- Modify: `VocabCraftAppTests/App/AppContainerVocabularyTests.swift`

**Interfaces:**
- Consumes: `AppContainer.mock` factory.
- Produces: `EnvironmentFallbacks.appContainer`, a lazily created stable identity used only when injection is absent.

- [ ] **Step 1: Write a failing identity test**

```swift
@Test("Environment fallback container identity is stable")
@MainActor
func environmentFallbackIsStable() {
    let first = EnvironmentValues().appContainer
    let second = EnvironmentValues().appContainer
    #expect(first === second)
}
```

- [ ] **Step 2: Run and verify RED**

Expected: identities differ because `.mock` is a computed factory.

- [ ] **Step 3: Add a stable fallback without changing the test factory**

```swift
@MainActor
private enum EnvironmentFallbacks {
    static let appContainer = AppContainer.mock
}

public extension EnvironmentValues {
    @MainActor
    var appContainer: AppContainer {
        get { self[AppContainerKey.self] ?? EnvironmentFallbacks.appContainer }
        set { self[AppContainerKey.self] = newValue }
    }
}
```

- [ ] **Step 4: Verify GREEN and confirm explicit environment injection still wins**

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/App/DI/EnvironmentKeys.swift VocabCraftAppTests/App/AppContainerVocabularyTests.swift
git commit -m "fix: stabilize app environment fallback"
```

### Task 2: Keep typing drafts local to the leaf exercise

**Files:**
- Modify: `VocabCraftApp/Features/Lesson/Views/Components/LessonExerciseContainerView.swift`
- Modify: `VocabCraftApp/Features/Lesson/ViewModels/LessonLearningViewModel.swift`
- Modify: `VocabCraftAppTests/Features/Lesson/LessonLearningViewModelTests.swift`

**Interfaces:**
- Consumes: `ReflexTypingModeView(typingText:onSubmit:)`.
- Produces: `@State private var typingDraft` and `submitTypingAnswer(_:for:)`.

- [ ] **Step 1: Write a failing submission test**

```swift
@Test("Typing answer is evaluated from the submitted draft")
@MainActor
func typingSubmissionUsesDraft() {
    let vm = makeViewModel()
    let item = makeTypingItem(lemma: "apple")
    vm.submitTypingAnswer(" APPLE ", for: item)
    #expect(vm.lastAttemptCorrect)
    #expect(vm.totalAnswered == 1)
}
```

- [ ] **Step 2: Run and verify RED**

Expected: `submitTypingAnswer` does not exist.

- [ ] **Step 3: Implement the narrow submission API**

```swift
public func submitTypingAnswer(_ draft: String, for item: LessonExerciseItem) {
    let answer = draft.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let target = item.word.lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    submitAnswer(isCorrect: answer == target, for: item)
}
```

- [ ] **Step 4: Verify GREEN**

- [ ] **Step 5: Move draft ownership into `LessonExerciseContainerView`**

```swift
@State private var typingDraft = ""

ReflexTypingModeView(
    word: drillableWord,
    typingText: $typingDraft,
    userSubmittedText: typingDraft,
    onSubmit: { viewModel.submitTypingAnswer(typingDraft, for: item) }
)
.onChange(of: item.id, initial: true) { _, _ in typingDraft = "" }
```

Remove the production use of `LessonLearningViewModel.typingText`; retain it only temporarily if existing tests require staged migration, then delete it after all callers are removed.

- [ ] **Step 6: Run lesson tests and commit**

```bash
git add VocabCraftApp/Features/Lesson/Views/Components/LessonExerciseContainerView.swift VocabCraftApp/Features/Lesson/ViewModels/LessonLearningViewModel.swift VocabCraftAppTests/Features/Lesson/LessonLearningViewModelTests.swift
git commit -m "perf: isolate lesson typing draft state"
```

### Task 3: Bound sparkle rendering work

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftSparkleView.swift`
- Modify: `Packages/CraftUIKit/Tests/CraftUIKitTests/FeedbackFXTests.swift`

**Interfaces:**
- Consumes: existing one-second sparkle lifecycle.
- Produces: deterministic completion and precomputed particle render constants.

- [ ] **Step 1: Write a failing lifecycle test using an injected clock**

```swift
@Test("Sparkle timeline stops at animation duration")
@MainActor
func sparkleStopsAtDuration() async {
    // ManualTestClock is a lightweight in-tree Clock<Duration> test double
    let clock = ManualTestClock()
    let model = CraftSparkleLifecycle(clock: clock)
    model.start()
    await clock.advance(by: .seconds(1))
    #expect(model.isRunning == false)
}
```

- [ ] **Step 2: Verify RED because the lifecycle seam does not exist**

- [ ] **Step 3: Extract the minimal lifecycle and precompute decay rates when particles are created**

Store `decayRate` and immutable geometry on `FXParticle`; `drawParticles` must not recompute `-log(particle.drag) * 60` every frame.

- [ ] **Step 4: Verify GREEN and run all `FeedbackFXTests`**

- [ ] **Step 5: Run the full CraftUIKit suite and commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftSparkleView.swift Packages/CraftUIKit/Tests/CraftUIKitTests/FeedbackFXTests.swift
git commit -m "perf: bound sparkle render work"
```

### Task 4: Verify render-state remediation

**Files:**
- Evidence: `.performance-traces/lesson-render-after.trace` (untracked unless requested).

**Interfaces:**
- Consumes: Tasks 1-3 and the completed speech plan.
- Produces: before/after metrics for typing and transitions.

- [ ] **Step 1: Run app tests, CraftUIKit tests, localization tests, and SwiftLint**
- [ ] **Step 2: Build Release for the connected iPhone with zero warnings**
- [ ] **Step 3: Record SwiftUI + Time Profiler + Hangs during the identical two-lesson flow**
- [ ] **Step 4: Confirm no `AppContainer.mock` construction appears after initial fallback creation**
- [ ] **Step 5: Confirm no lesson-related main-thread hang exceeds 250 ms and keystrokes render without queueing**
- [ ] **Step 6: Compare CPU samples for `CraftSparkleView.drawParticles` against the baseline count of 228**
- [ ] **Step 7: Commit only source/tests/docs; keep raw trace artifacts untracked unless the user explicitly approves them**

