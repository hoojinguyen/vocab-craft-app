# Vocabulary Vault Mixed Reflex Practice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the Vocabulary Vault (Kho từ) Practice feature into a multi-sensory Mixed Reflex Drill with smart word picking, fixed pre-assigned 4-modality drill plans, 3-2-1 countdown overlay, and a practice-exclusive "Can't Speak Now" fallback.

**Architecture:** Clean Architecture with separate domain use cases (`SmartVaultWordSelector`, `PracticeDrillPlanGenerator`, `RecordPracticeAttemptUseCase`), domain entity `ModeSuccessStats`, pre-computed immutable `ReflexDrillSessionPlan`, and observation-driven ViewModels (`PersonalVaultViewModel`, `MixedReflexDrillViewModel`).

**Tech Stack:** Swift 6, SwiftUI, SwiftData, Swift Testing (`@Test`, `#expect`), CraftUIKit tokens & components.

## Global Constraints

- Swift 6 strict concurrency compliance (0 errors, 0 warnings).
- Zero hardcoded strings: All UI text in `Localizable.xcstrings` under Layer 2 `app.*` taxonomy with 100% bilingual parity (EN & VI).
- CraftUIKit-first component hierarchy and strict design tokens.
- 100% test pass rate on `swift test` and clean SwiftLint.

---

### Task 1: `ModeSuccessStats` Entity & Model Persistence

**Files:**
- Create: `VocabCraftApp/Domain/Entities/ModeSuccessStats.swift`
- Create: `VocabCraftApp/Domain/Entities/ModeSuccessStatsCodec.swift`
- Modify: `VocabCraftApp/Core/Database/SwiftDataModels.swift`
- Modify: `VocabCraftApp/Domain/Entities/VaultWordItem.swift`
- Modify: `VocabCraftApp/Data/Local/Actors/UserProgressModelActor.swift` & `VocabCraftApp/Data/Repositories/MockUserProgressRepository.swift`
- Test: `VocabCraftAppTests/Domain/ModeSuccessStatsTests.swift`

**Interfaces:**
- Produces:
  ```swift
  public struct ModeSuccessStats: Codable, Equatable, Sendable {
      public var speaking: Int
      public var typing: Int
      public var multipleChoice: Int
      public var listening: Int
      public func count(for mode: ReflexBlitzMode) -> Int
      public mutating func increment(for mode: ReflexBlitzMode)
      public var totalSuccesses: Int { get }
      public var completedModes: Set<ReflexBlitzMode> { get }
      public var isFullyMasteredAllModes: Bool { get }
      public var lowestSuccessModes: [ReflexBlitzMode] { get }
  }
  public enum ModeSuccessStatsCodec {
      public static func encode(_ stats: ModeSuccessStats) -> String
      public static func decode(_ raw: String) -> ModeSuccessStats
  }
  ```

- [ ] **Step 1: Write the failing tests for `ModeSuccessStats` and Codec**

```swift
import Testing
@testable import VocabCraftApp

@Suite("ModeSuccessStats Tests")
struct ModeSuccessStatsTests {
    @Test("Default initialization has zero counts")
    func testDefaultInit() {
        let stats = ModeSuccessStats()
        #expect(stats.speaking == 0)
        #expect(stats.typing == 0)
        #expect(stats.multipleChoice == 0)
        #expect(stats.listening == 0)
        #expect(stats.totalSuccesses == 0)
        #expect(stats.completedModes.isEmpty)
        #expect(!stats.isFullyMasteredAllModes)
    }

    @Test("Incrementing modes updates counts and lowestSuccessModes")
    func testIncrementAndLowestModes() {
        var stats = ModeSuccessStats()
        stats.increment(for: .speaking)
        stats.increment(for: .speaking)
        stats.increment(for: .typing)
        
        #expect(stats.count(for: .speaking) == 2)
        #expect(stats.count(for: .typing) == 1)
        #expect(stats.count(for: .multipleChoice) == 0)
        #expect(stats.count(for: .listening) == 0)
        #expect(stats.lowestSuccessModes.contains(.multipleChoice))
        #expect(stats.lowestSuccessModes.contains(.listening))
        #expect(!stats.lowestSuccessModes.contains(.speaking))
    }

    @Test("Codec encode and decode matches exact values")
    func testCodecRoundTrip() {
        let stats = ModeSuccessStats(speaking: 3, typing: 5, multipleChoice: 1, listening: 2)
        let encoded = ModeSuccessStatsCodec.encode(stats)
        let decoded = ModeSuccessStatsCodec.decode(encoded)
        #expect(decoded == stats)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ModeSuccessStatsTests`
Expected: FAIL with compilation error (types not found)

- [ ] **Step 3: Implement `ModeSuccessStats` and `ModeSuccessStatsCodec`**

Implement `ModeSuccessStats.swift` and `ModeSuccessStatsCodec.swift` in `VocabCraftApp/Domain/Entities/`.
Update `UserWordProgress` and `VaultWordItem` to integrate `modeStats`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ModeSuccessStatsTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/Entities/ModeSuccessStats.swift VocabCraftApp/Domain/Entities/ModeSuccessStatsCodec.swift VocabCraftApp/Core/Database/SwiftDataModels.swift VocabCraftApp/Domain/Entities/VaultWordItem.swift VocabCraftAppTests/Domain/ModeSuccessStatsTests.swift
git commit -m "feat: add ModeSuccessStats entity, codec, and SwiftData mapping"
```

---

### Task 2: `SmartVaultWordSelector` Use Case

**Files:**
- Create: `VocabCraftApp/Domain/UseCases/SmartVaultWordSelector.swift`
- Test: `VocabCraftAppTests/Domain/SmartVaultWordSelectorTests.swift`

**Interfaces:**
- Consumes: `VaultWordItem`, `ModeSuccessStats`, `targetCount: Int` (passed from caller or `PersonalVaultViewModel` via `UserSettingsStore.dailyGoalCount`)
- Produces:
  ```swift
  public protocol SmartVaultWordSelectorProtocol: Sendable {
      func selectWords(from pool: [VaultWordItem], targetCount: Int) -> [VaultWordItem]
  }
  public final class SmartVaultWordSelector: SmartVaultWordSelectorProtocol, Sendable {
      public init()
      public func selectWords(from pool: [VaultWordItem], targetCount: Int) -> [VaultWordItem]
  }
  ```

- [ ] **Step 1: Write the failing tests for `SmartVaultWordSelector`**

```swift
import Testing
import Foundation
@testable import VocabCraftApp

@Suite("SmartVaultWordSelector Tests")
struct SmartVaultWordSelectorTests {
    @Test("Returns all words when pool is smaller than targetCount")
    func testPoolSmallerThanTarget() {
        let selector = SmartVaultWordSelector()
        let words = [
            VaultWordItem(id: 1, lemma: "apple", pos: "noun", definitionVi: "quả táo"),
            VaultWordItem(id: 2, lemma: "banana", pos: "noun", definitionVi: "quả chuối")
        ]
        let selected = selector.selectWords(from: words, targetCount: 10)
        #expect(selected.count == 2)
    }

    @Test("Prioritizes words with lowest mode count and lower streak")
    func testPriorityOrdering() {
        let selector = SmartVaultWordSelector()
        let wordWeak = VaultWordItem(
            id: 1,
            lemma: "weak",
            pos: "adj",
            definitionVi: "yếu",
            correctStreak: 0,
            modeStats: ModeSuccessStats(speaking: 0, typing: 0, multipleChoice: 0, listening: 0)
        )
        let wordMastered = VaultWordItem(
            id: 2,
            lemma: "strong",
            pos: "adj",
            definitionVi: "mạnh",
            correctStreak: 5,
            modeStats: ModeSuccessStats(speaking: 5, typing: 5, multipleChoice: 5, listening: 5)
        )
        let selected = selector.selectWords(from: [wordMastered, wordWeak], targetCount: 1)
        #expect(selected.first?.id == 1)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter SmartVaultWordSelectorTests`
Expected: FAIL

- [ ] **Step 3: Implement `SmartVaultWordSelector`**

Implement scoring algorithm calculating $S = (4 - \text{modeCount}) \times 10 + \max(0, 5 - \text{streak}) \times 3 + \min(10, \text{daysSinceLastPractice}) \times 2 + \text{jitter}$.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter SmartVaultWordSelectorTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/UseCases/SmartVaultWordSelector.swift VocabCraftAppTests/Domain/SmartVaultWordSelectorTests.swift
git commit -m "feat: implement SmartVaultWordSelector use case with priority scoring"
```

---

### Task 3: `PracticeDrillPlanGenerator` with Fixed Mode Balancing

**Files:**
- Create: `VocabCraftApp/Domain/UseCases/PracticeDrillPlanGenerator.swift`
- Test: `VocabCraftAppTests/Domain/PracticeDrillPlanGeneratorTests.swift`

**Interfaces:**
- Consumes: `VaultWordItem`, `ReflexDrillSessionPlan`, `ReflexDistractorGenerator`, `ReflexHintMaskGenerator`
- Produces:
  ```swift
  public protocol PracticeDrillPlanGeneratorProtocol: Sendable {
      func generatePlan(from words: [VaultWordItem]) -> ReflexDrillSessionPlan
  }
  public struct PracticeDrillPlanGenerator: PracticeDrillPlanGeneratorProtocol, Sendable {
      public init()
      public func generatePlan(from words: [VaultWordItem]) -> ReflexDrillSessionPlan
  }
  ```

- [ ] **Step 1: Write failing tests for `PracticeDrillPlanGenerator`**

```swift
import Testing
@testable import VocabCraftApp

@Suite("PracticeDrillPlanGenerator Tests")
struct PracticeDrillPlanGeneratorTests {
    @Test("Generates immutable plan with balanced modes")
    func testPlanGenerationBalance() {
        let generator = PracticeDrillPlanGenerator()
        let words = (1...12).map { id in
            VaultWordItem(id: Int64(id), lemma: "word\(id)", pos: "n", definitionVi: "nghĩa \(id)")
        }
        let plan = generator.generatePlan(from: words)
        #expect(plan.items.count == 12)
        
        let modes = plan.items.map(\.assignedMode)
        let uniqueModes = Set(modes)
        #expect(uniqueModes.count >= 3)
    }

    @Test("Respects individual word lowest success mode when possible")
    func testTargetModeAssignment() {
        let generator = PracticeDrillPlanGenerator()
        let wordWithTypingNeed = VaultWordItem(
            id: 1,
            lemma: "craft",
            pos: "n",
            definitionVi: "thủ công",
            modeStats: ModeSuccessStats(speaking: 10, typing: 0, multipleChoice: 10, listening: 10)
        )
        let plan = generator.generatePlan(from: [wordWithTypingNeed])
        #expect(plan.items.first?.assignedMode == .typing)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter PracticeDrillPlanGeneratorTests`
Expected: FAIL

- [ ] **Step 3: Implement `PracticeDrillPlanGenerator`**

Implement mode quota balancing and pre-generate distractors & cloze hint stages.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter PracticeDrillPlanGeneratorTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/UseCases/PracticeDrillPlanGenerator.swift VocabCraftAppTests/Domain/PracticeDrillPlanGeneratorTests.swift
git commit -m "feat: implement PracticeDrillPlanGenerator with balanced mode allocation"
```

---

### Task 4: `MixedReflexDrillViewModel` "Can't Speak Now" Requeue Enhancement

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Mixed/ViewModels/MixedReflexDrillViewModel.swift`
- Test: `VocabCraftAppTests/Features/Reflex/MixedReflexDrillViewModelTests.swift`

**Interfaces:**
- Consumes: `allowSpeakingSkip: Bool`
- Produces:
  ```swift
  public func skipSpeakingCurrentWord()
  ```

- [ ] **Step 1: Write failing test for `skipSpeakingCurrentWord`**

```swift
import Testing
@testable import VocabCraftApp

@Suite("MixedReflexDrillViewModel Skip Speaking Tests")
struct MixedReflexDrillViewModelSkipSpeakingTests {
    @Test("Skip speaking requeues word to end with non-speaking mode without penalty")
    func testSkipSpeakingRequeue() {
        let words = [
            VaultWordItem(id: 1, lemma: "voice", pos: "n", definitionVi: "tiếng nói")
        ]
        let vm = MixedReflexDrillViewModel(
            selectedWords: words,
            queueUseCase: GenerateMixedReflexQueueUseCase(),
            allowSpeakingSkip: true
        )
        #expect(vm.allowSpeakingSkip)
        vm.skipSpeakingCurrentWord()
        #expect(vm.comboStreak == 0)
        #expect(vm.attempts.isEmpty)
        #expect(vm.queue.count == 2)
        #expect(vm.queue.last?.assignedMode != .speaking)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter MixedReflexDrillViewModelSkipSpeakingTests`
Expected: FAIL

- [ ] **Step 3: Implement `skipSpeakingCurrentWord` in `MixedReflexDrillViewModel`**

Add `public let allowSpeakingSkip: Bool` flag, `skipSpeakingCurrentWord()` method, and link attempt recording to `ModeSuccessStats`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter MixedReflexDrillViewModelSkipSpeakingTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Reflex/Mixed/ViewModels/MixedReflexDrillViewModel.swift VocabCraftAppTests/Features/Reflex/MixedReflexDrillViewModelTests.swift
git commit -m "feat: add allowSpeakingSkip and skipSpeakingCurrentWord to MixedReflexDrillViewModel"
```

---

### Task 5: Localization & `PracticeSelectionView` Full Sheet Overhaul

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Features/Vocabulary/Views/PracticeSelectionView.swift`
- Modify: `VocabCraftApp/Features/Vocabulary/Views/Components/PracticeSelectionRow.swift`
- Modify: `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift`
- Modify: `VocabCraftApp/Features/Vocabulary/PersonalVault/ViewModels/PersonalVaultViewModel.swift`
- Test: `VocabCraftAppTests/Features/Vocabulary/PracticeSelectionViewTests.swift`

- [ ] **Step 1: Add localization keys into `Localizable.xcstrings`**
Add entries for `app.practice.selection.smart_pick`, `app.practice.drill.cant_speak_now`, `app.practice.selection.title`, etc.

- [ ] **Step 2: Enhance `PersonalVaultViewModel` with Smart Pick action**
Integrate `SmartVaultWordSelector` into `PersonalVaultViewModel.smartPickWords()`.

- [ ] **Step 3: Update `PracticeSelectionView` & `PracticeSelectionRow`**
Implement 3-tab segmented filter, "⚡️ Luyện tập nhanh" button, Select All toggle, mini sensory icons (🎙️ ⌨️ 🔲 🎧) on rows, and bottom CTA bar.

- [ ] **Step 4: Update `VocabularyView` to present `PracticeSelectionView` as Full Sheet**

- [ ] **Step 5: Run tests and verify view compilation**

Run: `swift test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftApp/Features/Vocabulary/ VocabCraftAppTests/
git commit -m "feat: overhaul PracticeSelectionView with Smart Pick and full sheet presentation"
```

---

### Task 6: In-Drill UI/UX Integration & Verification Suite

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Mixed/Views/MixedReflexDrillView.swift`
- Test: `VocabCraftAppTests/`

- [ ] **Step 1: Add Countdown Overlay state to `MixedReflexDrillView`**
Display `ReflexCountdownOverlayView` before first word.

- [ ] **Step 2: Add "Không thể nói lúc này" button to Speaking card in `MixedReflexDrillView`**
Render `CraftButton` for skip speaking when `viewModel.allowSpeakingSkip == true` and mode is `.speaking`.

- [ ] **Step 3: Run full verification suite**
Run: `swift test`
Run: `swiftlint`
Build Xcode project and verify 0 warnings, 0 errors.

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Features/Reflex/Mixed/Views/MixedReflexDrillView.swift
git commit -m "feat: integrate countdown overlay and can't-speak-now button into drill view"
```
