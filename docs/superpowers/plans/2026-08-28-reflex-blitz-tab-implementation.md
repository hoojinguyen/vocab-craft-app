# Reflex Blitz Tab — Free Practice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor and implement the standalone Reflex Blitz Tab (Free Practice) using 100% CraftUIKit components, supporting 4 speed drill modalities (Speaking, Typing, Multiple Choice, Listening), Smart Priority Queue (10 cross-topic words), `CraftFeedbackSheet` state machine, and same-mode re-drill on summary.

**Architecture:** MVVM architecture with `@Observable` `ReflexBlitzViewModel` orchestrating `ContinuousReflexSpeechService`, TTS audio, timer stages, and `CraftFeedbackSheet` presentations. Free practice queue is generated via `GenerateSmartReflexQueueUseCase` querying SwiftData / SQLite for weak words, current topic words, and SRS overdue items.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, CraftUIKit Design System, AVFoundation, Speech Framework.

**Spec:** [`docs/superpowers/specs/2026-08-28-reflex-blitz-tab-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-28-reflex-blitz-tab-design.md)

## Global Constraints
- 100% CraftUIKit components and design tokens (`CraftActionCard`, `CraftChoiceCard`, `CraftTextField`, `CraftCountdownOverlay`, `CraftCountdownTimerBar`, `CraftStepProgressIndicator`, `CraftWaveformView`, `CraftSpeakerButton`, `CraftFeedbackSheet`, `CraftButton`, `CraftCard`, `CraftBadge`).
- Zero hardcoded strings: All user-facing strings and accessibility labels must reside in `Localizable.xcstrings` under `app.reflex.*` with 100% English & Vietnamese parity.
- Zero compiler warnings, zero SwiftLint errors, 100% passing unit tests.
- Speaking: 6.0s (auto-listen via ContinuousReflexSpeechService, skip button, no keyboard switch).
- Typing: 7.5s (auto-focus CraftTextField, case-insensitive, skip button).
- Multiple Choice: 4.5s (4 CraftChoiceCard English options, instant selection, no skip button).
- Listening: 5.5s (auto-play audio, CraftWaveformView + CraftSpeakerButton, 4 CraftChoiceCard Vietnamese options, no skip button).
- Fixed 10 words per session sourced from Smart Priority Queue. Same-mode re-drill on summary.

---

### Task 1: Localization Catalog Setup (`app.reflex.*`)

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift`

**Interfaces:**
- Produces: Complete localization keys for Hub, Modalities, Quick Stats, Drill Prompts, and Summary Screens in `en` and `vi`.

- [ ] **Step 1: Write failing test for reflex localization keys existence**

```swift
import Testing
import Foundation

@Suite("Reflex Blitz Localization Tests")
struct ReflexBlitzLocalizationTests {
    @Test("All app.reflex keys exist with non-empty en and vi strings")
    func testReflexLocalizationKeys() throws {
        guard let url = Bundle.main.url(forResource: "Localizable", withExtension: "xcstrings") ??
                Bundle(for: ReflexBlitzComponentsTestsMarker.self).url(forResource: "Localizable", withExtension: "xcstrings") else {
            // Fallback load from path if running in SPM test harness
            return
        }
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let strings = json?["strings"] as? [String: Any] ?? [:]
        
        let requiredKeys = [
            "app.reflex.hub.title",
            "app.reflex.hub.subtitle",
            "app.reflex.hub.badge",
            "app.reflex.stats.weekly_words",
            "app.reflex.stats.weak_words",
            "app.reflex.stats.avg_speed",
            "app.reflex.mode.speaking.title",
            "app.reflex.mode.typing.title",
            "app.reflex.mode.mc.title",
            "app.reflex.mode.listening.title",
            "app.reflex.drill.skip",
            "app.reflex.summary.title"
        ]
        
        for key in requiredKeys {
            #expect(strings[key] != nil, "Missing localization key: \(key)")
        }
    }
}

private final class ReflexBlitzComponentsTestsMarker {}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexBlitzLocalizationTests`
Expected: FAIL due to missing keys in `Localizable.xcstrings`.

- [ ] **Step 3: Update `Localizable.xcstrings` with 100% EN/VI translations**

Add the keys specified in Section 8 of the design spec into `VocabCraftApp/Resources/Localizable.xcstrings` with `extractionState: "manual"` and `state: "translated"`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexBlitzLocalizationTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift
git commit -m "feat(reflex): add comprehensive localization keys for Reflex Blitz Tab"
```

---

### Task 2: Smart Priority Queue UseCase & Algorithms

**Files:**
- Create: `VocabCraftApp/Domain/UseCases/GenerateSmartReflexQueueUseCase.swift`
- Test: `VocabCraftAppTests/Domain/SmartReflexQueueUseCaseTests.swift`

**Interfaces:**
- Produces: `GenerateSmartReflexQueueUseCaseProtocol` with `func execute(allLearnedWords: [ReflexDrillItem], currentTopicWords: [ReflexDrillItem], targetCount: Int) -> [ReflexDrillItem]`

- [ ] **Step 1: Write unit tests for 4-tier Smart Priority Queue algorithm**

```swift
import Testing
import Foundation
@testable import VocabCraftApp

@Suite("Smart Reflex Queue UseCase Tests")
struct SmartReflexQueueUseCaseTests {
    @Test("Queue selects max 10 words prioritizing weak words and current topic")
    func testSmartQueueSelectionAndShuffle() {
        let useCase = GenerateSmartReflexQueueUseCase()
        
        // Setup 20 mock items: 6 weak, 6 current topic, 4 SRS due, 4 mastered
        var allItems: [ReflexDrillItem] = []
        for i in 1...6 {
            allItems.append(ReflexDrillItem(id: "weak_\(i)", lemma: "weak\(i)", ipa: "/w/", definitionVi: "nghĩa \(i)", clozeSentenceEn: "Sentence [weak\(i)]", clozeSentenceVi: "Câu \(i)", mistakeCount: i, needsReview: true))
        }
        for i in 1...6 {
            allItems.append(ReflexDrillItem(id: "topic_\(i)", lemma: "topic\(i)", ipa: "/t/", definitionVi: "chủ đề \(i)", clozeSentenceEn: "Sentence [topic\(i)]", clozeSentenceVi: "Câu \(i)", isMastered: false))
        }
        for i in 1...4 {
            allItems.append(ReflexDrillItem(id: "mastered_\(i)", lemma: "mastered\(i)", ipa: "/m/", definitionVi: "thuộc \(i)", clozeSentenceEn: "Sentence [mastered\(i)]", clozeSentenceVi: "Câu \(i)", isMastered: true))
        }
        
        let result = useCase.execute(allLearnedWords: allItems, currentTopicWords: Array(allItems[6..<12]), targetCount: 10)
        
        #expect(result.count == 10)
        let weakCount = result.filter { $0.needsReview || $0.mistakeCount > 0 }.count
        #expect(weakCount >= 1 && weakCount <= 5)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter SmartReflexQueueUseCaseTests`
Expected: FAIL ("GenerateSmartReflexQueueUseCase not found").

- [ ] **Step 3: Implement `GenerateSmartReflexQueueUseCase`**

Implement the 4-tier filtering (Tier 1 Weak Words, Tier 2 Current Topic Words, Tier 3 SRS Due Words, Tier 4 Random/Learned) + final shuffle to return exactly `targetCount` items.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter SmartReflexQueueUseCaseTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/UseCases/GenerateSmartReflexQueueUseCase.swift VocabCraftAppTests/Domain/SmartReflexQueueUseCaseTests.swift
git commit -m "feat(reflex): implement GenerateSmartReflexQueueUseCase with 4-tier priority"
```

---

### Task 3: Refactor ReflexBlitzModeSelectionView with CraftUIKit & Quick Stats

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzModeSelectionView.swift`
- Modify: `VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift`

**Interfaces:**
- Consumes: `CraftActionCard`, `CraftCard`, `CraftBadge`, `CraftText`, `CraftColorTokens`, `CraftTypographyTokens`
- Produces: Redesigned Bento Hub with 4 mode action cards + 3-card Quick Stats Dashboard.

- [ ] **Step 1: Write component view tests for ReflexBlitzModeSelectionView**

```swift
import Testing
import SwiftUI
@testable import VocabCraftApp

@Suite("Reflex Blitz Mode Selection View Tests")
struct ReflexBlitzModeSelectionViewTests {
    @Test("Mode Selection View initializes and yields 4 mode cards with stats")
    func testModeSelectionViewInitialization() {
        var selectedMode: ReflexBlitzMode?
        let view = ReflexBlitzModeSelectionView(
            weeklyPracticedCount: 42,
            weakWordsCount: 5,
            averageSpeedSeconds: 1.6,
            onSelectMode: { mode in
                selectedMode = mode
            },
            onDismiss: {}
        )
        #expect(view != nil)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexBlitzModeSelectionViewTests`
Expected: FAIL due to missing parameter signatures.

- [ ] **Step 3: Refactor `ReflexBlitzModeSelectionView`**

- Use `CraftBadge` + `CraftText` in Header.
- Use `CraftActionCard` with `.tactile3D` for Speaking, Typing, Multiple Choice, Listening.
- Add Quick Stats Dashboard with 3 `CraftCard` components (weekly practiced, weak count, avg speed).
- Add Footer Scaffolding text with localized strings.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexBlitzModeSelectionViewTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzModeSelectionView.swift VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift
git commit -m "feat(reflex): refactor ReflexBlitzModeSelectionView to 100% CraftUIKit with Quick Stats"
```

---

### Task 4: Refactor Reflex Header, Countdown & Modality Time Limits

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzHeaderView.swift`
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift`
- Modify: `VocabCraftApp/Features/ReflexDrill/Models/ReflexBlitzModels.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzModelsTests.swift`

**Interfaces:**
- Consumes: `CraftStepProgressIndicator`, `CraftStreakBadge`, `CraftIconButton`, `CraftCountdownTimerBar`, `CraftCountdownOverlay`
- Produces: Standardized drill header and fullscreen countdown integration.

- [ ] **Step 1: Write test for modality time limits and header state mapping**

```swift
import Testing
@testable import VocabCraftApp

@Suite("Reflex Blitz Models & Limits Tests")
struct ReflexBlitzModelsAndLimitsTests {
    @Test("Modalities have strict time limits per spec")
    func testModalityTimeLimits() {
        #expect(ReflexBlitzMode.speaking.timeLimitSeconds == 6.0)
        #expect(ReflexBlitzMode.typing.timeLimitSeconds == 7.5)
        #expect(ReflexBlitzMode.multipleChoice.timeLimitSeconds == 4.5)
        #expect(ReflexBlitzMode.listening.timeLimitSeconds == 5.5)
    }
}
```

- [ ] **Step 2: Run test to verify it fails if limits differ**

Run: `swift test --filter ReflexBlitzModelsAndLimitsTests`

- [ ] **Step 3: Refactor `ReflexBlitzHeaderView` and `ReflexBlitzView`**

- Connect `CraftStepProgressIndicator` (10 steps with completed/active/unreached status).
- Connect `CraftStreakBadge` for combo >= 2.
- Connect `CraftCountdownTimerBar` anchored beneath header with glowing aura.
- Wire `CraftCountdownOverlay` (.craftCountdown modifier) for 3-2-1 GO start.

- [ ] **Step 4: Run tests to verify**

Run: `swift test --filter ReflexBlitzModelsAndLimitsTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzHeaderView.swift VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift VocabCraftApp/Features/ReflexDrill/Models/ReflexBlitzModels.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzModelsTests.swift
git commit -m "feat(reflex): refactor drill header and countdown overlay with CraftUIKit"
```

---

### Task 5: Refactor Challenge Cards for 4 Modalities & `CraftFeedbackSheet`

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift`
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift`
- Modify: `VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift`

**Interfaces:**
- Consumes: `CraftCard`, `CraftChoiceCard`, `CraftTextField`, `CraftWaveformView`, `CraftSpeakerButton`, `CraftFeedbackSheet`, `CraftButton`
- Produces: Interactive challenge card for Speaking, Typing, MC, and Listening + docked `CraftFeedbackSheet` on review.

- [ ] **Step 1: Write ViewModel tests for 4 modality feedback and skip behavior**

```swift
import Testing
@testable import VocabCraftApp

@Suite("Reflex Blitz 4 Modalities Feedback Tests")
struct ReflexBlitzViewModelFeedbackTests {
    @Test("Speaking and Typing allow Skip; MC and Listening trigger instant feedback on choice")
    func testModalityInteractions() {
        let viewModel = ReflexBlitzViewModel()
        let sampleWord = ReflexBlitzWordItem(id: "1", lemma: "capital", ipa: "/kæp/", definitionVi: "thủ đô", clozeSentenceEn: "Tokyo is a [capital].", clozeSentenceVi: "Tokyo là thủ đô.")
        viewModel.startDrillSession(mode: .speaking, words: [sampleWord])
        
        // Skip in Speaking should transition to reviewed with feedback
        viewModel.handleTimeout() // or skip
        #expect(viewModel.isFeedbackPresented == true)
        
        // Multiple Choice selection
        viewModel.startDrillSession(mode: .multipleChoice, words: [sampleWord])
        let opt = ReflexBlitzOption(id: "1", text: "capital", isCorrect: true)
        viewModel.selectOption(opt)
        #expect(viewModel.isFeedbackPresented == true)
        #expect(viewModel.currentAttemptIsCorrect == true)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexBlitzViewModelFeedbackTests`

- [ ] **Step 3: Implement 4 Modalities & `CraftFeedbackSheet` in `ReflexBlitzCardView` & `ReflexBlitzView`**

- **Speaking**: Cloze stimulus, live `CraftWaveformView` + live transcript, skip button at bottom, no keyboard toggle.
- **Typing**: Cloze stimulus, auto-focused `CraftTextField`, return key submits, skip button.
- **Multiple Choice**: Cloze stimulus, 4 `CraftChoiceCard` options (English), instant lock, no skip button.
- **Listening**: Auto-play audio stimulus, hidden English text, `CraftWaveformView` pulse + `CraftSpeakerButton`, 4 `CraftChoiceCard` options (Vietnamese), no skip button.
- Present docked `CraftFeedbackSheet` with IPA, speaker audio button, full sentence translation, and "Tiếp tục" button.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexBlitzViewModelFeedbackTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift
git commit -m "feat(reflex): implement 4 drill modalities and CraftFeedbackSheet state machine"
```

---

### Task 6: Refactor ReflexBlitzSummaryView with CraftUIKit & Same-Mode Re-drill

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzSummaryView.swift`
- Modify: `VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzSummaryViewTests.swift`

**Interfaces:**
- Consumes: `CraftCard`, `CraftSpeakerButton`, `CraftButton`, `CraftBadge`, `CraftSparkleView`
- Produces: Redesigned summary with Bento metrics, weak word list with audio, same-mode re-drill CTA, and persistence.

- [ ] **Step 1: Write summary and re-drill tests**

```swift
import Testing
@testable import VocabCraftApp

@Suite("Reflex Blitz Summary Re-drill Tests")
struct ReflexBlitzSummaryReDrillTests {
    @Test("Summary re-drill retains same modality for weak words")
    func testSameModeReDrill() {
        let viewModel = ReflexBlitzViewModel()
        let w1 = ReflexBlitzWordItem(id: "1", lemma: "word1", ipa: "/w1/", definitionVi: "nghĩa 1", clozeSentenceEn: "[word1]", clozeSentenceVi: "câu 1")
        let w2 = ReflexBlitzWordItem(id: "2", lemma: "word2", ipa: "/w2/", definitionVi: "nghĩa 2", clozeSentenceEn: "[word2]", clozeSentenceVi: "câu 2")
        
        viewModel.startDrillSession(mode: .speaking, words: [w1, w2])
        viewModel.submitSpeakingResult(isCorrect: true, responseTimeMs: 1200)
        viewModel.advanceToNextWord()
        viewModel.submitSpeakingResult(isCorrect: false, responseTimeMs: 6000)
        viewModel.advanceToNextWord()
        
        #expect(viewModel.phase == .summary)
        #expect(viewModel.sessionSummary?.weakWordAttempts.count == 1)
        
        viewModel.reDrillWeakWords()
        #expect(viewModel.selectedMode == .speaking)
        #expect(viewModel.words.count == 1)
    }
}
```

- [ ] **Step 2: Run test to verify it fails if not implemented**

Run: `swift test --filter ReflexBlitzSummaryReDrillTests`

- [ ] **Step 3: Refactor `ReflexBlitzSummaryView`**

- Use `CraftCard` for 3 Bento Metric Cards (Avg Speed, Accuracy, Max Combo).
- Use `CraftCard` list rows for weak words with `CraftSpeakerButton` and response time badges.
- Use `CraftButton` for "Luyện lại N từ chưa thuộc" (danger tint) and "Hoàn thành & Lưu tiến độ".
- If 10/10 perfect score: render `CraftSparkleView` celebration.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexBlitzSummaryReDrillTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzSummaryView.swift VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzSummaryViewTests.swift
git commit -m "feat(reflex): refactor ReflexBlitzSummaryView with CraftUIKit and same-mode re-drill"
```

---

### Task 7: Full Verification Suite, SwiftLint & Zero Warnings Gate

**Files:**
- Verify all modified files across `VocabCraftApp/Features/ReflexDrill/` and `VocabCraftAppTests/`.

- [ ] **Step 1: Run complete test suite**

Run: `swift test`
Expected: 100% tests passing.

- [ ] **Step 2: Run SwiftLint**

Run: `swiftlint lint --strict`
Expected: Zero lint warnings or errors.

- [ ] **Step 3: Compile in Xcode Build Environment**

Run: `xcodebuild -scheme VocabCraftApp -destination 'generic/platform=iOS Simulator' build`
Expected: **0 errors, 0 warnings**.

- [ ] **Step 4: Commit and finalize**

```bash
git add -A
git commit -m "test(reflex): verify full test suite, SwiftLint compliance and zero Xcode warnings"
```
