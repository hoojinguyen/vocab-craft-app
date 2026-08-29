# Reflex Hint Masking & Session Pre-generation Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a robust, pure domain pre-generation engine (`ReflexDrillPlanGenerator` & `ReflexHintMaskGenerator`) that generates 100% of a drill session's question blueprints, dynamic multi-pattern cloze hints, and randomized distractor eliminations upfront with zero runtime overhead.

**Architecture:** Pure Domain Services (`ReflexHintMaskGenerator`, `ReflexDrillPlanGenerator`) produce an immutable `ReflexDrillSessionPlan` composed of `ReflexDrillPlanItem`s. `ReflexBlitzViewModel` and mode views (`ReflexMultipleChoiceModeView`, `ReflexTypingModeView`, `ReflexSpeakingModeView`) consume this plan with $O(1)$ property lookups.

**Tech Stack:** Swift 6 (Strict Concurrency, Sendable), SwiftUI, CraftUIKit Design System, XCTest / Swift Testing.

## Global Constraints

- **Language & Platform**: Swift 6, iOS 17.0+
- **Zero Raw Styling**: All colors, fonts, spacing, and animations must strictly utilize `CraftUIKit` tokens (`theme.colors.*`, `theme.typography.*`, `theme.spacing.*`, `theme.radii.*`).
- **Zero Hardcoded Strings**: All user-facing strings and accessibility labels must come from `Localizable.xcstrings` or existing `AppStrings.ReflexBlitz`.
- **Quality Gates**: Zero compiler warnings, 100% test pass rate, strict SwiftLint compliance.

---

### Task 1: Core Domain Models & Data Structures

**Files:**
- Create: `VocabCraftApp/Features/Reflex/Core/Models/ReflexHintMaskStrategy.swift`
- Create: `VocabCraftApp/Features/Reflex/Core/Models/ReflexClozeStageSet.swift`
- Create: `VocabCraftApp/Features/Reflex/Core/Models/ReflexDrillPlanItem.swift`
- Create: `VocabCraftApp/Features/Reflex/Core/Models/ReflexDrillSessionPlan.swift`
- Test: `VocabCraftAppTests/Features/Reflex/ReflexDrillPlanModelsTests.swift`

**Interfaces:**
- Consumes: `ReflexDrillable`, `ReflexMode`, `ReflexBlitzOption`, `ClozeSentenceParts`
- Produces: `ReflexHintMaskStrategy`, `ReflexClozeStageSet`, `ReflexDrillPlanItem`, `ReflexDrillSessionPlan`

- [ ] **Step 1: Write the failing test for Core Models**

```swift
import Testing
@testable import VocabCraftApp

@Suite("Reflex Drill Plan Models Tests")
struct ReflexDrillPlanModelsTests {
    @Test("ReflexClozeStageSet holds initial, length masked, and pattern revealed parts")
    func testClozeStageSet() {
        let initial = ClozeSentenceParts(prefix: "She has a ", slot: "[ _________ ]", suffix: " of reading.")
        let lengthMasked = ClozeSentenceParts(prefix: "She has a ", slot: "[ _ _ _ _ _ ]", suffix: " of reading.")
        let revealed = ClozeSentenceParts(prefix: "She has a ", slot: "[ h _ _ _ t ]", suffix: " of reading.")
        let stageSet = ReflexClozeStageSet(
            initialParts: initial,
            lengthMaskedParts: lengthMasked,
            patternRevealedParts: revealed,
            maskedWordString: "h _ _ _ t",
            strategy: .prefix(count: 1)
        )
        #expect(stageSet.maskedWordString == "h _ _ _ t")
        #expect(stageSet.strategy == .prefix(count: 1))
    }

    @Test("ReflexDrillPlanItem creates immutable blueprint with options and eliminated distractor")
    func testDrillPlanItem() {
        let word = ReflexBlitzWordItem.defaultStarterWords[0]
        let options = [
            ReflexBlitzOption(text: "habit", isCorrect: true),
            ReflexBlitzOption(text: "focus", isCorrect: false),
            ReflexBlitzOption(text: "create", isCorrect: false),
            ReflexBlitzOption(text: "relax", isCorrect: false)
        ]
        let initial = ClozeSentenceParts(prefix: "She has a ", slot: "[ _________ ]", suffix: " of reading.")
        let stageSet = ReflexClozeStageSet(
            initialParts: initial,
            lengthMaskedParts: initial,
            patternRevealedParts: initial,
            maskedWordString: "h _ _ _ t",
            strategy: .prefix(count: 1)
        )
        let item = ReflexDrillPlanItem(
            id: "plan-1",
            word: word,
            assignedMode: .multipleChoice,
            options: options,
            correctOptionIndex: 0,
            eliminatedOptionId: options[1].id,
            clozeStages: stageSet,
            hintBadgeText: "h... • noun"
        )
        #expect(item.id == "plan-1")
        #expect(item.correctOptionIndex == 0)
        #expect(item.eliminatedOptionId == options[1].id)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexDrillPlanModelsTests`
Expected: FAIL with compilation error (types not defined)

- [ ] **Step 3: Implement Core Models**

Create `ReflexHintMaskStrategy.swift`:
```swift
import Foundation

public enum ReflexHintMaskStrategy: Equatable, Sendable {
    case shortWordPrefix
    case shortWordSuffix
    case prefix(count: Int)
    case suffix(count: Int)
    case middleCluster(text: String, range: Range<Int>)
    case consonantScaffold
}
```

Create `ReflexClozeStageSet.swift`:
```swift
import Foundation

public struct ReflexClozeStageSet: Equatable, Sendable {
    public let initialParts: ClozeSentenceParts
    public let lengthMaskedParts: ClozeSentenceParts
    public let patternRevealedParts: ClozeSentenceParts
    public let maskedWordString: String
    public let strategy: ReflexHintMaskStrategy

    public init(
        initialParts: ClozeSentenceParts,
        lengthMaskedParts: ClozeSentenceParts,
        patternRevealedParts: ClozeSentenceParts,
        maskedWordString: String,
        strategy: ReflexHintMaskStrategy
    ) {
        self.initialParts = initialParts
        self.lengthMaskedParts = lengthMaskedParts
        self.patternRevealedParts = patternRevealedParts
        self.maskedWordString = maskedWordString
        self.strategy = strategy
    }
}
```

Create `ReflexDrillPlanItem.swift`:
```swift
import Foundation

public struct ReflexDrillPlanItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let word: any ReflexDrillable
    public let assignedMode: ReflexMode
    public let options: [ReflexBlitzOption]
    public let correctOptionIndex: Int
    public let eliminatedOptionId: String?
    public let clozeStages: ReflexClozeStageSet
    public let hintBadgeText: String

    public init(
        id: String,
        word: any ReflexDrillable,
        assignedMode: ReflexMode,
        options: [ReflexBlitzOption],
        correctOptionIndex: Int,
        eliminatedOptionId: String?,
        clozeStages: ReflexClozeStageSet,
        hintBadgeText: String
    ) {
        self.id = id
        self.word = word
        self.assignedMode = assignedMode
        self.options = options
        self.correctOptionIndex = correctOptionIndex
        self.eliminatedOptionId = eliminatedOptionId
        self.clozeStages = clozeStages
        self.hintBadgeText = hintBadgeText
    }

    public static func == (lhs: ReflexDrillPlanItem, rhs: ReflexDrillPlanItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.word.lemma == rhs.word.lemma &&
        lhs.assignedMode == rhs.assignedMode &&
        lhs.options == rhs.options &&
        lhs.correctOptionIndex == rhs.correctOptionIndex &&
        lhs.eliminatedOptionId == rhs.eliminatedOptionId &&
        lhs.clozeStages == rhs.clozeStages &&
        lhs.hintBadgeText == rhs.hintBadgeText
    }
}
```

Create `ReflexDrillSessionPlan.swift`:
```swift
import Foundation

public struct ReflexDrillSessionPlan: Equatable, Sendable {
    public let id: UUID
    public let mode: ReflexMode
    public let items: [ReflexDrillPlanItem]

    public var count: Int { items.count }
    public var isEmpty: Bool { items.isEmpty }

    public init(
        id: UUID = UUID(),
        mode: ReflexMode,
        items: [ReflexDrillPlanItem]
    ) {
        self.id = id
        self.mode = mode
        self.items = items
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexDrillPlanModelsTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Reflex/Core/Models/ReflexHintMaskStrategy.swift VocabCraftApp/Features/Reflex/Core/Models/ReflexClozeStageSet.swift VocabCraftApp/Features/Reflex/Core/Models/ReflexDrillPlanItem.swift VocabCraftApp/Features/Reflex/Core/Models/ReflexDrillSessionPlan.swift VocabCraftAppTests/Features/Reflex/ReflexDrillPlanModelsTests.swift
git commit -m "feat(reflex): add core models for Hint Masking and Session Plan"
```

---

### Task 2: ReflexHintMaskGenerator Implementation & Tests

**Files:**
- Create: `VocabCraftApp/Features/Reflex/Core/Utilities/ReflexHintMaskGenerator.swift`
- Test: `VocabCraftAppTests/Features/Reflex/ReflexHintMaskGeneratorTests.swift`

**Interfaces:**
- Consumes: `ReflexClozeFormatter`, `ClozeSentenceParts`, `ReflexHintMaskStrategy`, `ReflexClozeStageSet`
- Produces: `ReflexHintMaskGenerator.generateStages(lemma:sentenceEn:pos:) -> ReflexClozeStageSet`

- [ ] **Step 1: Write the failing test for ReflexHintMaskGenerator**

```swift
import Testing
@testable import VocabCraftApp

@Suite("Reflex Hint Mask Generator Tests")
struct ReflexHintMaskGeneratorTests {
    @Test("Short word (<= 4 letters) generates prefix or suffix mask")
    func testShortWordMask() {
        let stages = ReflexHintMaskGenerator.generateStages(
            lemma: "book",
            sentenceEn: "I read a book daily.",
            pos: "noun"
        )
        #expect(stages.maskedWordString.contains("b") || stages.maskedWordString.contains("k"))
        #expect(stages.lengthMaskedParts.slot.contains("_"))
        #expect(stages.patternRevealedParts.prefix == "I read a ")
        #expect(stages.patternRevealedParts.suffix == " daily.")
    }

    @Test("Word with double consonant detects middle cluster")
    func testDoubleConsonantDetection() {
        let stages = ReflexHintMaskGenerator.generateStages(
            lemma: "challenge",
            sentenceEn: "Overcoming a challenge makes you stronger.",
            pos: "noun"
        )
        if case .middleCluster(let cluster, _) = stages.strategy {
            #expect(cluster == "ll")
            #expect(stages.maskedWordString.contains("l l"))
        } else {
            #expect(Bool(false), "Expected middleCluster strategy for challenge")
        }
    }

    @Test("Length mask accurately matches lemma character count")
    func testLengthMaskAccuracy() {
        let lemma = "protect"
        let stages = ReflexHintMaskGenerator.generateStages(
            lemma: lemma,
            sentenceEn: "We must protect nature.",
            pos: "verb"
        )
        let underscoreCount = stages.lengthMaskedParts.slot.filter { $0 == "_" }.count
        #expect(underscoreCount == lemma.count)
    }

    @Test("Phrasal verbs preserve whitespace in masking")
    func testPhrasalVerbPreservesSpaces() {
        let stages = ReflexHintMaskGenerator.generateStages(
            lemma: "look up",
            sentenceEn: "Please look up the word.",
            pos: "verb"
        )
        #expect(stages.lengthMaskedParts.slot.contains("   ") || stages.lengthMaskedParts.slot.contains("  "))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexHintMaskGeneratorTests`
Expected: FAIL with "ReflexHintMaskGenerator not found"

- [ ] **Step 3: Implement ReflexHintMaskGenerator**

Create `ReflexHintMaskGenerator.swift`:
```swift
import Foundation

public struct ReflexHintMaskGenerator: Sendable {
    private static let doubleConsonants = [
        "ll", "ss", "tt", "cc", "nn", "pp", "rr", "mm", "ff", "dd", "bb", "gg"
    ]
    private static let distinctiveDigraphs = [
        "ch", "sh", "th", "ph", "ng", "ck", "qu", "wh"
    ]
    private static let vowels: Set<Character> = ["a", "e", "i", "o", "u", "A", "E", "I", "O", "U"]

    public static func generateStages(
        lemma: String,
        sentenceEn: String,
        pos: String = ""
    ) -> ReflexClozeStageSet {
        let cleanLemma = lemma.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanLemma.isEmpty else {
            let empty = ClozeSentenceParts(prefix: sentenceEn, slot: "[ _________ ]", suffix: "")
            return ReflexClozeStageSet(
                initialParts: empty,
                lengthMaskedParts: empty,
                patternRevealedParts: empty,
                maskedWordString: "...",
                strategy: .shortWordPrefix
            )
        }

        // Generate length mask string: e.g. "_ _ _ _ _ _ _ _ _"
        let lengthMaskStr = formatLengthUnderscores(for: cleanLemma)
        let initialSlotStr = "[ _________ ]"
        let lengthSlotStr = "[ \(lengthMaskStr) ]"

        // Generate pattern mask strategy and string
        let (strategy, patternRevealedWord) = computePatternMask(for: cleanLemma)
        let patternSlotStr = "[ \(patternRevealedWord) ]"

        // Extract cloze sentence parts
        let formattedInitial = ReflexClozeFormatter.formatCloze(sentenceEn: sentenceEn, lemma: cleanLemma)
        let partsInitial = ReflexClozeFormatter.extractTemplateParts(from: formattedInitial) ?? ClozeSentenceParts(prefix: sentenceEn, slot: initialSlotStr, suffix: "")

        let partsLength = ClozeSentenceParts(prefix: partsInitial.prefix, slot: lengthSlotStr, suffix: partsInitial.suffix)
        let partsPattern = ClozeSentenceParts(prefix: partsInitial.prefix, slot: patternSlotStr, suffix: partsInitial.suffix)

        return ReflexClozeStageSet(
            initialParts: partsInitial,
            lengthMaskedParts: partsLength,
            patternRevealedParts: partsPattern,
            maskedWordString: patternRevealedWord,
            strategy: strategy
        )
    }

    private static func formatLengthUnderscores(for text: String) -> String {
        text.map { char in
            char == " " ? "  " : "_"
        }.joined(separator: " ")
    }

    private static func computePatternMask(for lemma: String) -> (ReflexHintMaskStrategy, String) {
        let chars = Array(lemma)
        let count = chars.count

        if count <= 4 {
            let usePrefix = Bool.random()
            if usePrefix {
                var masked = chars.enumerated().map { index, char -> String in
                    if index == 0 { return String(char) }
                    return char == " " ? " " : "_"
                }
                return (.shortWordPrefix, masked.joined(separator: " "))
            } else {
                var masked = chars.enumerated().map { index, char -> String in
                    if index == count - 1 { return String(char) }
                    return char == " " ? " " : "_"
                }
                return (.shortWordSuffix, masked.joined(separator: " "))
            }
        }

        // Long words (>= 5): Check for middle cluster
        let lower = lemma.lowercased()
        for cluster in (doubleConsonants + distinctiveDigraphs) {
            if let range = lower.range(of: cluster) {
                let startOffset = lower.distance(from: lower.startIndex, to: range.lowerBound)
                let endOffset = lower.distance(from: lower.startIndex, to: range.upperBound)

                // Must be an internal middle cluster (not starting at index 0 or ending at the very last letter)
                if startOffset > 0 && endOffset < count {
                    let rangeInt = startOffset..<endOffset
                    let masked = chars.enumerated().map { index, char -> String in
                        if rangeInt.contains(index) {
                            return String(char)
                        }
                        return char == " " ? " " : "_"
                    }.joined(separator: " ")
                    return (.middleCluster(text: cluster, range: rangeInt), masked)
                }
            }
        }

        // Fallback: Pick between prefix(2), suffix(2), or consonantScaffold
        let pick = Int.random(in: 0...2)
        switch pick {
        case 0:
            let masked = chars.enumerated().map { index, char -> String in
                if index < 2 { return String(char) }
                return char == " " ? " " : "_"
            }.joined(separator: " ")
            return (.prefix(count: 2), masked)

        case 1:
            let masked = chars.enumerated().map { index, char -> String in
                if index >= count - 2 { return String(char) }
                return char == " " ? " " : "_"
            }.joined(separator: " ")
            return (.suffix(count: 2), masked)

        default:
            let masked = chars.map { char -> String in
                if vowels.contains(char) {
                    return "_"
                }
                return String(char)
            }.joined(separator: " ")
            return (.consonantScaffold, masked)
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexHintMaskGeneratorTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Reflex/Core/Utilities/ReflexHintMaskGenerator.swift VocabCraftAppTests/Features/Reflex/ReflexHintMaskGeneratorTests.swift
git commit -m "feat(reflex): implement ReflexHintMaskGenerator with multi-pattern progressive cloze scaffolding"
```

---

### Task 3: ReflexDrillPlanGenerator Implementation & Tests

**Files:**
- Create: `VocabCraftApp/Features/Reflex/Core/Utilities/ReflexDrillPlanGenerator.swift`
- Test: `VocabCraftAppTests/Features/Reflex/ReflexDrillPlanGeneratorTests.swift`

**Interfaces:**
- Consumes: `ReflexDrillable`, `ReflexMode`, `ReflexDistractorGenerator`, `ReflexHintMaskGenerator`, `ReflexDrillSessionPlan`, `ReflexDrillPlanItem`
- Produces: `ReflexDrillPlanGenerator.generatePlan(words:mode:) -> ReflexDrillSessionPlan`

- [ ] **Step 1: Write the failing test for ReflexDrillPlanGenerator**

```swift
import Testing
@testable import VocabCraftApp

@Suite("Reflex Drill Plan Generator Tests")
struct ReflexDrillPlanGeneratorTests {
    @Test("Generates session plan with matching count and mode")
    func testPlanGeneration() {
        let pool = ReflexBlitzWordItem.defaultStarterWords
        let plan = ReflexDrillPlanGenerator.generatePlan(words: pool, mode: .multipleChoice)
        #expect(plan.count == pool.count)
        #expect(plan.mode == .multipleChoice)
    }

    @Test("Distractor elimination selects an incorrect option")
    func testDistractorElimination() {
        let pool = ReflexBlitzWordItem.defaultStarterWords
        let plan = ReflexDrillPlanGenerator.generatePlan(words: pool, mode: .multipleChoice)
        for item in plan.items {
            if let elimId = item.eliminatedOptionId {
                let eliminatedOption = item.options.first { $0.id == elimId }
                #expect(eliminatedOption != nil)
                #expect(eliminatedOption?.isCorrect == false)
            }
        }
    }

    @Test("Correct option positions are uniformly distributed over multiple runs")
    func testOptionDistributionUniformity() {
        let pool = ReflexBlitzWordItem.defaultStarterWords
        var positionCounts = [0, 0, 0, 0]
        for _ in 0..<100 {
            let plan = ReflexDrillPlanGenerator.generatePlan(words: pool, mode: .multipleChoice)
            for item in plan.items {
                positionCounts[item.correctOptionIndex] += 1
            }
        }
        // Over 1200 total questions, each position (0..3) should have at least 150 appearances
        for count in positionCounts {
            #expect(count > 150)
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexDrillPlanGeneratorTests`
Expected: FAIL with "ReflexDrillPlanGenerator not found"

- [ ] **Step 3: Implement ReflexDrillPlanGenerator**

Create `ReflexDrillPlanGenerator.swift`:
```swift
import Foundation

public struct ReflexDrillPlanGenerator: Sendable {
    public static func generatePlan(
        words: [some ReflexDrillable],
        mode: ReflexMode
    ) -> ReflexDrillSessionPlan {
        guard !words.isEmpty else {
            return ReflexDrillSessionPlan(mode: mode, items: [])
        }

        let shuffledWords = words.shuffled()
        var items: [ReflexDrillPlanItem] = []

        for (index, word) in shuffledWords.enumerated() {
            let options: [ReflexBlitzOption]
            if mode == .multipleChoice || mode == .listening {
                options = ReflexDistractorGenerator.generateOptions(
                    mode: mode,
                    target: word,
                    pool: words
                )
            } else {
                options = []
            }

            let correctIndex = options.firstIndex(where: { $0.isCorrect }) ?? 0
            let incorrectOptions = options.filter { !$0.isCorrect }
            let eliminatedId = incorrectOptions.randomElement()?.id

            let clozeStages = ReflexHintMaskGenerator.generateStages(
                lemma: word.lemma,
                sentenceEn: word.exampleSentenceEn,
                pos: word.cleanPos
            )

            let hintBadgeText: String
            switch clozeStages.strategy {
            case .middleCluster(let cluster, _):
                hintBadgeText = "...\(cluster)... • \(word.cleanPos)"
            case .prefix(let count):
                let prefixStr = String(word.lemma.prefix(count))
                hintBadgeText = "\(prefixStr)... • \(word.cleanPos)"
            case .suffix(let count):
                let suffixStr = String(word.lemma.suffix(count))
                hintBadgeText = "...\(suffixStr) • \(word.cleanPos)"
            case .consonantScaffold, .shortWordPrefix, .shortWordSuffix:
                hintBadgeText = "\(word.cleanInitialLetterHint)"
            }

            let planItem = ReflexDrillPlanItem(
                id: "\(mode.rawValue)-plan-\(index)-\(word.id)",
                word: word,
                assignedMode: mode,
                options: options,
                correctOptionIndex: correctIndex,
                eliminatedOptionId: eliminatedId,
                clozeStages: clozeStages,
                hintBadgeText: hintBadgeText
            )
            items.append(planItem)
        }

        return ReflexDrillSessionPlan(mode: mode, items: items)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexDrillPlanGeneratorTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Reflex/Core/Utilities/ReflexDrillPlanGenerator.swift VocabCraftAppTests/Features/Reflex/ReflexDrillPlanGeneratorTests.swift
git commit -m "feat(reflex): implement ReflexDrillPlanGenerator with session-level randomization and distractor elimination"
```

---

### Task 4: ViewModel Integration (ReflexBlitzViewModel & MixedReflexDrillViewModel)

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift`
- Test: `VocabCraftAppTests/Features/Reflex/ReflexBlitzViewModelTests.swift`

**Interfaces:**
- Consumes: `ReflexDrillSessionPlan`, `ReflexDrillPlanItem`, `ReflexDrillPlanGenerator`
- Produces: `sessionPlan`, `currentPlanItem`, `currentClozeStages`, `eliminatedOptionId`, `currentHintBadgeText`

- [ ] **Step 1: Write the failing test for ViewModel Pre-generation**

```swift
import Testing
@testable import VocabCraftApp

@Suite("Reflex Blitz ViewModel Pre-generation Tests")
struct ReflexBlitzViewModelTests {
    @Test("startDrillSession initializes sessionPlan and loads first plan item without runtime delay")
    @MainActor
    func testSessionPlanInitialization() {
        let viewModel = ReflexBlitzViewModel(words: ReflexBlitzWordItem.defaultStarterWords)
        viewModel.startDrillSession(mode: .multipleChoice)
        #expect(viewModel.sessionPlan != nil)
        #expect(viewModel.sessionPlan?.items.count == ReflexBlitzWordItem.defaultStarterWords.count)
        #expect(viewModel.currentPlanItem != nil)
        #expect(viewModel.currentOptions.count == 4)
    }

    @Test("Hint stages progress from 0 -> 1 -> 2 -> 3 with simulated elapsed time")
    @MainActor
    func testProgressiveHintStages() {
        let viewModel = ReflexBlitzViewModel(words: ReflexBlitzWordItem.defaultStarterWords)
        viewModel.startDrillSession(mode: .multipleChoice)
        
        viewModel.simulateElapsedTime(ms: 0)
        #expect(viewModel.hintStage == 0)
        
        viewModel.simulateElapsedTime(ms: 1700)
        #expect(viewModel.hintStage == 1)
        
        viewModel.simulateElapsedTime(ms: 2600)
        #expect(viewModel.hintStage == 2)
        
        viewModel.simulateElapsedTime(ms: 3500)
        #expect(viewModel.hintStage == 3)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexBlitzViewModelTests`
Expected: FAIL

- [ ] **Step 3: Update ReflexBlitzViewModel with Session Plan**

Modify `ReflexBlitzViewModel.swift`:
- Add `public var sessionPlan: ReflexDrillSessionPlan?`
- Add `public var currentPlanItem: ReflexDrillPlanItem?`
- Add `public var currentClozeStages: ReflexClozeStageSet?`
- Add `public var currentEliminatedOptionId: String?`
- Add `public var currentHintBadgeText: String?`
- In `startCountdown()` & `beginSessionDirectly()`:
  - Generate `self.sessionPlan = ReflexDrillPlanGenerator.generatePlan(words: words, mode: selectedMode)`
- In `loadWord(at index: Int)`:
  - Fetch `planItem = sessionPlan?.items[index]`
  - Bind `currentOptions = planItem.options`
  - Bind `currentClozeStages = planItem.clozeStages`
  - Bind `currentEliminatedOptionId = planItem.eliminatedOptionId`
  - Bind `currentHintBadgeText = planItem.hintBadgeText`

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexBlitzViewModelTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift VocabCraftAppTests/Features/Reflex/ReflexBlitzViewModelTests.swift
git commit -m "feat(reflex): integrate ReflexDrillPlanGenerator into ReflexBlitzViewModel"
```

---

### Task 5: UI Layer Integration (Mode Views & Blitz Container)

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexMultipleChoiceModeView.swift`
- Modify: `VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexTypingModeView.swift`
- Modify: `VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexSpeakingModeView.swift`
- Modify: `VocabCraftApp/Features/Reflex/Blitz/Views/ReflexBlitzView.swift`
- Test: `VocabCraftAppTests/Features/Reflex/ReflexContainerComponentsTests.swift`

**Interfaces:**
- Consumes: `ReflexClozeStageSet`, `hintStage`, `eliminatedOptionId`
- Produces: Dynamic animated progressive cloze slot text & randomized distractor elimination

- [ ] **Step 1: Update ReflexMultipleChoiceModeView to use ClozeStages**

Modify `ReflexMultipleChoiceModeView.swift`:
- Add `public let clozeStages: ReflexClozeStageSet?`
- In `sentenceView`:
  ```swift
  private var activeClozeParts: ClozeSentenceParts? {
      guard let stages = clozeStages else { return clozeParts }
      switch hintStage {
      case 0: return stages.initialParts
      case 1: return stages.lengthMaskedParts
      default: return stages.patternRevealedParts
      }
  }
  ```
- In `choiceState(for:)`:
  ```swift
  if hintStage >= 3 && option.id == eliminatedOptionId {
      return .disabled
  }
  ```

- [ ] **Step 2: Update ReflexTypingModeView and ReflexSpeakingModeView**

- Accept `clozeStages: ReflexClozeStageSet?` and `hintStage: Int`
- Use `activeClozeParts` based on `hintStage >= 1` and `hintStage >= 2`
- Display `hintBadgeText` when `showHint == true`

- [ ] **Step 3: Update ReflexBlitzView to bind Plan Properties**

Modify `ReflexBlitzView.swift`:
- Pass `clozeStages: viewModel.currentClozeStages` and `eliminatedOptionId: viewModel.currentEliminatedOptionId` directly to `ReflexMultipleChoiceModeView`, `ReflexTypingModeView`, and `ReflexSpeakingModeView`.

- [ ] **Step 4: Run component & view tests**

Run: `swift test --filter ReflexContainerComponentsTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexMultipleChoiceModeView.swift VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexTypingModeView.swift VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexSpeakingModeView.swift VocabCraftApp/Features/Reflex/Blitz/Views/ReflexBlitzView.swift VocabCraftAppTests/Features/Reflex/ReflexContainerComponentsTests.swift
git commit -m "feat(reflex): wire progressive cloze hint stages and random distractor elimination into UI views"
```

---

### Task 6: Full Verification, Localization & Quality Gates

**Files:**
- Test all test targets
- Verify SwiftLint & Zero compiler warnings

- [ ] **Step 1: Run Full Test Suite**

Run: `swift test`
Expected: 100% tests PASS

- [ ] **Step 2: Run SwiftLint**

Run: `swiftlint`
Expected: 0 errors, 0 warnings

- [ ] **Step 3: Build & Verify Zero Compiler Warnings**

Run: `xcodebuild -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -destination 'generic/platform=iOS Simulator' clean build`
Expected: **BUILD SUCCEEDED (0 errors, 0 warnings)**

- [ ] **Step 4: Final commit & summary**

```bash
git commit --allow-empty -m "chore(reflex): complete verification for Reflex Hint Masking and Session Pre-generation Engine"
```
