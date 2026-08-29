# Reflex Architecture & Folder Structure Refactoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the Reflex feature into a modular, clean-architecture structure under `Features/Reflex/`, extracting 4 independent mode views, preserving 100% of the verified Multiple Choice UI/UX, and abstracting data input via `ReflexDrillable`.

**Architecture:** Domain Protocol Abstraction (`ReflexDrillable`) + Pure Reusable Stateless Mode Views (`ReflexMultipleChoiceModeView`, `ReflexSpeakingModeView`, `ReflexTypingModeView`, `ReflexListeningModeView`) + Unified Container & Consolidation Card + Feature Session ViewModels (`Blitz` & `Mixed`).

**Tech Stack:** Swift 6, SwiftUI, CraftUIKit, Observation (`@Observable`), SpeechKit, Foundation.

## Global Constraints
- Zero Hardcoded Strings: All user-facing texts must come from `AppStrings` or `Localizable.xcstrings`.
- CraftUIKit-First: Use Design Tokens (`theme.colors`, `theme.typography`, `theme.radii`, `theme.spacing`, `theme.shadows`) and CraftUIKit components (`CraftChoiceCard`, `CraftFlipCard`, `CraftBadge`, `CraftTextField`, `CraftButton`, `CraftFeedbackSheet`, `CraftWaveformView`, `CraftSpeakerButton`).
- Multiple Choice Preservation: Do not alter the visual styling, 3D flip dynamics, or option elimination behavior of `ReflexMultipleChoiceModeView`.
- Quality Gate: 0 compiler warnings, 0 lint warnings, 100% test pass rate.

---

### Task 1: Domain Protocol & Entity Conformances (`ReflexDrillable`)

**Files:**
- Create: `VocabCraftApp/Domain/Protocols/ReflexDrillable.swift`
- Modify: `VocabCraftApp/Domain/Entities/Word.swift`
- Modify: `VocabCraftApp/Domain/Entities/VaultWordItem.swift`
- Modify: `VocabCraftApp/Domain/Entities/MixedReflexDrillItem.swift`
- Test: `VocabCraftAppTests/Domain/ReflexDrillableTests.swift`

**Interfaces:**
- Consumes: Foundation types.
- Produces: `protocol ReflexDrillable` with standard properties (`id`, `lemma`, `pos`, `ipa`, `definitionVi`, `exampleSentenceEn`, `exampleSentenceVi`, `clozeSentenceEn`, `cefrLevel`, `audioResourceUrl`, `cleanPos`, `cleanLevel`, `cleanInitialLetterHint`).

- [ ] **Step 1: Write the failing unit test for `ReflexDrillable` protocol and default extensions**

```swift
import Testing
@testable import VocabCraftApp

@Suite("ReflexDrillable Protocol Tests")
struct ReflexDrillableTests {
    struct MockDrillItem: ReflexDrillable {
        let id: String
        let lemma: String
        let pos: String
        let ipa: String
        let definitionVi: String
        let exampleSentenceEn: String
        let exampleSentenceVi: String
        let clozeSentenceEn: String
        let cefrLevel: String
        let audioResourceUrl: String?
    }

    @Test("Verifies cleanPos, cleanLevel, and cleanInitialLetterHint extensions")
    func testDrillableExtensions() {
        let item = MockDrillItem(
            id: "1",
            lemma: "habit",
            pos: "n.",
            ipa: "/ˈhæb.ɪt/",
            definitionVi: "Thói quen",
            exampleSentenceEn: "Reading books is a habit.",
            exampleSentenceVi: "Đọc sách là một thói quen.",
            clozeSentenceEn: "Reading books is a [ _________ ].",
            cefrLevel: "B1",
            audioResourceUrl: nil
        )

        #expect(item.cleanPos == "noun")
        #expect(item.cleanLevel == "B1")
        #expect(item.cleanInitialLetterHint == "h... • noun")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexDrillableTests`
Expected: FAIL (types not found)

- [ ] **Step 3: Implement `ReflexDrillable.swift` and conformances**

Create `VocabCraftApp/Domain/Protocols/ReflexDrillable.swift`:
```swift
import Foundation

public protocol ReflexDrillable: Sendable {
    var id: String { get }
    var lemma: String { get }
    var pos: String { get }
    var ipa: String { get }
    var definitionVi: String { get }
    var exampleSentenceEn: String { get }
    var exampleSentenceVi: String { get }
    var clozeSentenceEn: String { get }
    var cefrLevel: String { get }
    var audioResourceUrl: String? { get }
}

public extension ReflexDrillable {
    var cleanPos: String {
        let trimmed = pos.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ".", with: "").lowercased()
        switch trimmed {
        case "v", "verb": return "verb"
        case "n", "noun": return "noun"
        case "adj", "adjective": return "adj"
        case "adv", "adverb": return "adv"
        case "prep", "preposition": return "prep"
        case "conj", "conjunction": return "conj"
        case "pron", "pronoun": return "pron"
        default: return trimmed.isEmpty ? "word" : trimmed
        }
    }

    var cleanLevel: String {
        cefrLevel.isEmpty ? "B2" : cefrLevel
    }

    var cleanInitialLetterHint: String {
        let firstLetter = lemma.prefix(1).lowercased()
        return "\(firstLetter)... • \(cleanPos)"
    }
}

extension VaultWordItem: ReflexDrillable {
    public var id: String { "\(wordId)" }
    public var pos: String { wordPos }
    public var ipa: String { wordPhonetic }
    public var exampleSentenceVi: String { "" }
    public var clozeSentenceEn: String { exampleSentenceEn }
    public var cefrLevel: String { "" }
    public var audioResourceUrl: String? { nil }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexDrillableTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/Protocols/ReflexDrillable.swift VocabCraftAppTests/Domain/ReflexDrillableTests.swift
git commit -m "feat(domain): add ReflexDrillable protocol and entity conformances"
```

---

### Task 2: Core Models & Pure Utilities (`Features/Reflex/Core/`)

**Files:**
- Create: `VocabCraftApp/Features/Reflex/Core/Models/ReflexMode.swift`
- Create: `VocabCraftApp/Features/Reflex/Core/Models/ReflexCardPhase.swift`
- Create: `VocabCraftApp/Features/Reflex/Core/Models/ReflexCardResult.swift`
- Create: `VocabCraftApp/Features/Reflex/Core/Models/ReflexBlitzOption.swift`
- Create: `VocabCraftApp/Features/Reflex/Core/Models/ReflexBlitzWordItem.swift`
- Create: `VocabCraftApp/Features/Reflex/Core/Models/ReflexSessionSummary.swift`
- Create: `VocabCraftApp/Features/Reflex/Core/Utilities/ReflexClozeFormatter.swift`
- Create: `VocabCraftApp/Features/Reflex/Core/Utilities/ReflexDistractorGenerator.swift`
- Test: `VocabCraftAppTests/Features/Reflex/ReflexCoreUtilitiesTests.swift`

**Interfaces:**
- Consumes: `ReflexDrillable`, `AppStrings`.
- Produces: `ReflexMode`, `ReflexCardPhase`, `ReflexCardResult`, `ReflexBlitzOption`, `ReflexClozeFormatter`, `ReflexDistractorGenerator`.

- [ ] **Step 1: Write unit tests for `ReflexClozeFormatter` and `ReflexDistractorGenerator`**

```swift
import Testing
@testable import VocabCraftApp

@Suite("ReflexCoreUtilities Tests")
struct ReflexCoreUtilitiesTests {
    @Test("Cloze formatter creates template and extracts prefix/suffix")
    func testClozeFormatter() {
        let sentence = "Practice helps you improve your English skills."
        let formatted = ReflexClozeFormatter.formatCloze(sentenceEn: sentence, lemma: "improve")
        #expect(formatted.contains("[ _________ ]"))

        let parts = ReflexClozeFormatter.extractTemplateParts(from: formatted)
        #expect(parts.prefix == "Practice helps you ")
        #expect(parts.suffix == " your English skills.")
    }

    @Test("Distractor generator creates 4 unique options including target")
    func testDistractorGenerator() {
        let options = ReflexDistractorGenerator.generateOptions(
            mode: .multipleChoice,
            targetLemma: "habit",
            targetDefinition: "Thói quen",
            pool: ReflexBlitzWordItem.defaultStarterWords
        )
        #expect(options.count == 4)
        #expect(options.filter { $0.isCorrect }.count == 1)
        #expect(options.first(where: { $0.isCorrect })?.text == "habit")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexCoreUtilitiesTests`
Expected: FAIL

- [ ] **Step 3: Implement Core Models and Utilities in `Features/Reflex/Core/`**

Create `VocabCraftApp/Features/Reflex/Core/Utilities/ReflexClozeFormatter.swift` and `ReflexDistractorGenerator.swift`, plus models `ReflexMode.swift`, `ReflexCardPhase.swift`, `ReflexCardResult.swift`, `ReflexBlitzOption.swift`, `ReflexBlitzWordItem.swift`, `ReflexSessionSummary.swift`. Ensure `ReflexBlitzWordItem` conforms to `ReflexDrillable`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexCoreUtilitiesTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Reflex/Core/ VocabCraftAppTests/Features/Reflex/ReflexCoreUtilitiesTests.swift
git commit -m "feat(reflex): create core models and pure utilities under Features/Reflex/Core"
```

---

### Task 3: Preserve 100% of Multiple Choice Mode (`ReflexMultipleChoiceModeView`)

**Files:**
- Create: `VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexMultipleChoiceModeView.swift`
- Test: `VocabCraftAppTests/Features/Reflex/ReflexMultipleChoiceModeViewTests.swift`

**Interfaces:**
- Consumes: `ReflexDrillable`, `ReflexBlitzOption`, `CraftFlipCard`, `CraftChoiceCard`, `CraftText`, `CraftBadge`, `CraftSpeakerButton`.
- Produces: `ReflexMultipleChoiceModeView: View`.

- [ ] **Step 1: Write SwiftUI Component Test for `ReflexMultipleChoiceModeView`**

```swift
import SwiftUI
import Testing
@testable import VocabCraftApp

@Suite("ReflexMultipleChoiceModeView Tests")
struct ReflexMultipleChoiceModeViewTests {
    @Test("Instantiates ReflexMultipleChoiceModeView in active and reviewed states")
    func testMultipleChoiceView() {
        let item = ReflexBlitzWordItem.defaultStarterWords[0]
        let options = [
            ReflexBlitzOption(text: "habit", isCorrect: true),
            ReflexBlitzOption(text: "improve", isCorrect: false)
        ]

        let view = ReflexMultipleChoiceModeView(
            word: item,
            options: options,
            isReviewed: false,
            isResultCorrect: false,
            isResultTimeout: false,
            showHint: true,
            hintStage: 1,
            selectedOptionText: nil,
            clozeParts: nil,
            displayedSentence: item.clozeSentenceEn,
            cardBorderColor: .clear,
            eliminatedOptionId: nil,
            onSelectOption: nil,
            onReplayAudio: nil
        )
        #expect(view.options.count == 2)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexMultipleChoiceModeViewTests`
Expected: FAIL

- [ ] **Step 3: Move and preserve `ReflexBlitzMultipleChoiceCardView.swift` into `ReflexMultipleChoiceModeView.swift`**

Create `VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexMultipleChoiceModeView.swift` with exact 3D flip stimulus card, front prompt, back result face, cloze styling, and options list.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexMultipleChoiceModeViewTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexMultipleChoiceModeView.swift VocabCraftAppTests/Features/Reflex/ReflexMultipleChoiceModeViewTests.swift
git commit -m "feat(reflex): preserve and isolate ReflexMultipleChoiceModeView"
```

---

### Task 4: Modularize Speaking, Typing, and Listening Modes

**Files:**
- Create: `VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexSpeakingModeView.swift`
- Create: `VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexTypingModeView.swift`
- Create: `VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexListeningModeView.swift`
- Test: `VocabCraftAppTests/Features/Reflex/ReflexOtherModesTests.swift`

**Interfaces:**
- Consumes: `ReflexDrillable`, `CraftWaveformView`, `CraftTextField`, `CraftIconButton`, `CraftChoiceCard`, `CraftSpeakerButton`.
- Produces: `ReflexSpeakingModeView`, `ReflexTypingModeView`, `ReflexListeningModeView`.

- [ ] **Step 1: Write component unit test for Speaking, Typing, and Listening mode views**

```swift
import SwiftUI
import Testing
@testable import VocabCraftApp

@Suite("ReflexOtherModes Tests")
struct ReflexOtherModesTests {
    @Test("Instantiates Speaking, Typing, and Listening views")
    func testInstantiateModes() {
        let item = ReflexBlitzWordItem.defaultStarterWords[0]
        let speakingView = ReflexSpeakingModeView(
            word: item,
            liveTranscript: "habit",
            elapsedTimeMs: 1200,
            onSwitchToKeyboard: {}
        )
        #expect(speakingView.liveTranscript == "habit")

        var text = ""
        let typingBinding = Binding(get: { text }, set: { text = $0 })
        let typingView = ReflexTypingModeView(
            word: item,
            typingText: typingBinding,
            onSubmit: {}
        )
        #expect(typingView.word.lemma == "habit")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexOtherModesTests`
Expected: FAIL

- [ ] **Step 3: Extract and implement `ReflexSpeakingModeView.swift`, `ReflexTypingModeView.swift`, and `ReflexListeningModeView.swift`**

Extract clean implementations from `ReflexBlitzCardView` and `MixedDrillSectionViews` without coupling to other modes.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexOtherModesTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Reflex/Core/Components/Modes/ VocabCraftAppTests/Features/Reflex/ReflexOtherModesTests.swift
git commit -m "feat(reflex): modularize Speaking, Typing, and Listening mode views"
```

---

### Task 5: Container, Consolidation, and Header Components

**Files:**
- Create: `VocabCraftApp/Features/Reflex/Core/Components/Consolidation/ReflexReviewedConsolidationView.swift`
- Create: `VocabCraftApp/Features/Reflex/Core/Components/Container/ReflexCardContainerView.swift`
- Create: `VocabCraftApp/Features/Reflex/Core/Components/Container/ReflexHeaderBarView.swift`
- Test: `VocabCraftAppTests/Features/Reflex/ReflexContainerComponentsTests.swift`

**Interfaces:**
- Consumes: Mode Views, `ReflexCardPhase`, `ReflexCardResult`, `CraftFeedbackSheet`.
- Produces: `ReflexCardContainerView`, `ReflexReviewedConsolidationView`, `ReflexHeaderBarView`.

- [ ] **Step 1: Write unit tests for Container & Consolidation components**

```swift
import SwiftUI
import Testing
@testable import VocabCraftApp

@Suite("ReflexContainerComponents Tests")
struct ReflexContainerComponentsTests {
    @Test("Validates ReflexReviewedConsolidationView instantiation")
    func testReviewedView() {
        let item = ReflexBlitzWordItem.defaultStarterWords[0]
        let result = ReflexCardResult(isCorrect: true, responseTimeMs: 1200, isTimeout: false)
        let view = ReflexReviewedConsolidationView(
            word: item,
            mode: .speaking,
            reviewResult: result,
            displayedSentence: item.exampleSentenceEn,
            onReplayAudio: nil
        )
        #expect(view.isResultCorrect == true)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexContainerComponentsTests`
Expected: FAIL

- [ ] **Step 3: Implement `ReflexReviewedConsolidationView`, `ReflexCardContainerView`, and `ReflexHeaderBarView`**

Build clean, reusable container views using CraftUIKit design tokens and components.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexContainerComponentsTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Reflex/Core/Components/ VocabCraftAppTests/Features/Reflex/ReflexContainerComponentsTests.swift
git commit -m "feat(reflex): implement container, consolidation, and header views"
```

---

### Task 6: Refactor Reflex Blitz Feature (`Features/Reflex/Blitz/`)

**Files:**
- Create: `VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift`
- Create: `VocabCraftApp/Features/Reflex/Blitz/Views/ReflexBlitzView.swift`
- Create: `VocabCraftApp/Features/Reflex/Blitz/Views/ReflexBlitzModeSelectionView.swift`
- Create: `VocabCraftApp/Features/Reflex/Blitz/Views/ReflexBlitzSummaryView.swift`
- Create: `VocabCraftApp/Features/Reflex/Blitz/Views/ReflexCountdownOverlayView.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift`

**Interfaces:**
- Consumes: `Features/Reflex/Core/` components, models, and utilities.
- Produces: `ReflexBlitzView`, `ReflexBlitzViewModel`.

- [ ] **Step 1: Migrate and update `ReflexBlitzViewModel` and Views into `Features/Reflex/Blitz/`**
- [ ] **Step 2: Run existing `ReflexBlitzViewModelTests` and component tests**

Run: `swift test --filter ReflexBlitz`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add VocabCraftApp/Features/Reflex/Blitz/ VocabCraftAppTests/Features/ReflexDrill/
git commit -m "refactor(reflex): organize Reflex Blitz feature under Features/Reflex/Blitz"
```

---

### Task 7: Refactor Mixed Reflex Drill Feature (`Features/Reflex/Mixed/`)

**Files:**
- Create: `VocabCraftApp/Features/Reflex/Mixed/ViewModels/MixedReflexDrillViewModel.swift`
- Create: `VocabCraftApp/Features/Reflex/Mixed/Views/MixedReflexDrillView.swift`
- Create: `VocabCraftApp/Features/Reflex/Mixed/Views/MixedReflexSummaryView.swift`
- Test: `VocabCraftAppTests/Features/MixedReflexDrillViewModelTests.swift`
- Test: `VocabCraftAppTests/Features/MixedReflexDrillViewsTests.swift`

**Interfaces:**
- Consumes: `Features/Reflex/Core/` components & `ReflexDrillable`.
- Produces: `MixedReflexDrillView`, `MixedReflexDrillViewModel`.

- [ ] **Step 1: Migrate and update `MixedReflexDrillViewModel` and Views to reuse `Features/Reflex/Core/Components`**
- [ ] **Step 2: Run test suite for Mixed Reflex Drill**

Run: `swift test --filter MixedReflex`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add VocabCraftApp/Features/Reflex/Mixed/ VocabCraftAppTests/Features/MixedReflexDrill*
git commit -m "refactor(reflex): organize Mixed Reflex Drill under Features/Reflex/Mixed"
```

---

### Task 8: Cleanup Obsolete Files & Update App Navigation References

**Files:**
- Delete: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift`
- Delete: `VocabCraftApp/Features/Vocabulary/Views/Components/MixedDrillSectionViews.swift`
- Delete: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzMultipleChoiceCardView.swift`
- Delete: `VocabCraftApp/Features/ReflexDrill/ReflexDrillView.swift`
- Modify: App navigation/tab views referencing old Reflex paths.

- [ ] **Step 1: Remove redundant and monolithic files**
- [ ] **Step 2: Update all import/type references across the app**
- [ ] **Step 3: Run full test suite and verify no broken imports**

Run: `swift test`
Expected: 100% PASS

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor(reflex): remove deprecated monolithic files and unify references"
```

---

### Task 9: Final Quality Gate & Verification

**Files:**
- All modified files

- [ ] **Step 1: Run SwiftLint**

Run: `swiftlint`
Expected: 0 errors, 0 warnings

- [ ] **Step 2: Run Full Swift Tests**

Run: `swift test`
Expected: All tests PASS

- [ ] **Step 3: Commit final refactor validation**

```bash
git commit --allow-empty -m "chore(reflex): complete reflex architecture refactor verification"
```
