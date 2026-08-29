# Reflex Blitz Typing Mode Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the Reflex Blitz Typing Mode to feature a 3D tactile stimulus `CraftFlipCard` (consistent with Multiple Choice mode), an auto-focused keyboard-docked floating input pill, smooth dismissal of keyboard and input bar upon Return/timeout, subtle display of the user's typed text on the back card face, and removal of the skip button.

**Architecture:** 
- Presentation: SwiftUI view `ReflexTypingModeView` leveraging `CraftFlipCard` and a floating keyboard-docked input bar with `@FocusState` and `.submitLabel(.go)`.
- State Management: `ReflexBlitzViewModel` handles timing, typing submission evaluation (correct/incorrect), streak updates, audio feedback, and transition to `.reviewed` state.
- Design System: Strict adherence to `CraftUIKit` tokens (`CraftTheme`), `CraftFlipCard`, `CraftText`, `CraftBadge`, `CraftFeedbackSheet`, and zero hardcoded strings.

**Tech Stack:** Swift 6, SwiftUI, CraftUIKit Design System, Foundation, XCTest / Swift Testing.

**Spec:** [`docs/superpowers/specs/2026-08-29-reflex-typing-mode-redesign-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-29-reflex-typing-mode-redesign-design.md)

## Global Constraints

- 100% Bilingual Parity (`en` and `vi`) in `Localizable.xcstrings` with `extractionState: "manual"` and `state: "translated"`.
- Zero hardcoded colors, fonts, margins, or strings.
- Strictly use `CraftTheme` tokens via `@Environment(\.craftTheme) private var theme`.
- Zero compiler warnings and clean `swiftlint` execution.

---

### Task 1: Localization Strings & AppStrings Helpers

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Core/Localization/AppStrings+ReflexBlitz.swift`
- Test: `VocabCraftAppTests/Reflex/ReflexLocalizationTests.swift`

**Interfaces:**
- Produces:
  - `AppStrings.ReflexBlitz.typingPlaceholderText: String`
  - `AppStrings.ReflexBlitz.typingPlaceholder: LocalizedStringKey`
  - `AppStrings.ReflexBlitz.typingEnteredPrefix(_ text: String) -> String`
  - `AppStrings.ReflexBlitz.typingYouTypedPrefix(_ text: String) -> String`

- [ ] **Step 1: Write the failing test for new typing localization keys**

Create or update `VocabCraftAppTests/Reflex/ReflexLocalizationTests.swift`:
```swift
import Testing
import SwiftUI
@testable import VocabCraftApp

@Suite("Reflex Typing Localization Tests")
struct ReflexTypingLocalizationTests {
    @Test("Typing localized string helpers return formatted values")
    func testTypingLocalizationHelpers() {
        let enteredStr = AppStrings.ReflexBlitz.typingEnteredPrefix("apple")
        #expect(enteredStr.contains("apple"))

        let youTypedStr = AppStrings.ReflexBlitz.typingYouTypedPrefix("aple")
        #expect(youTypedStr.contains("aple"))

        let placeholder = AppStrings.ReflexBlitz.typingPlaceholderText
        #expect(!placeholder.isEmpty)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexTypingLocalizationTests`
Expected: FAIL due to missing `typingEnteredPrefix` and `typingYouTypedPrefix` methods.

- [ ] **Step 3: Update `Localizable.xcstrings` and `AppStrings+ReflexBlitz.swift`**

In `VocabCraftApp/Resources/Localizable.xcstrings`, update `app.reflex.drill.typing_placeholder` and add `app.reflex.drill.typing_entered` and `app.reflex.drill.typing_you_typed`:
```json
    "app.reflex.drill.typing_entered" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Entered: \"%@\""
          }
        },
        "vi" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Đã nhập: \"%@\""
          }
        }
      }
    },
    "app.reflex.drill.typing_placeholder" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Type your answer..."
          }
        },
        "vi" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Nhập câu trả lời..."
          }
        }
      }
    },
    "app.reflex.drill.typing_you_typed" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "You typed: \"%@\""
          }
        },
        "vi" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Bạn đã nhập: \"%@\""
          }
        }
      }
    },
```

In `VocabCraftApp/Core/Localization/AppStrings+ReflexBlitz.swift`:
```swift
        public static func typingEnteredPrefix(_ text: String) -> String {
            String(format: String(localized: "app.reflex.drill.typing_entered", defaultValue: "Đã nhập: \"%@\"", bundle: .module), text)
        }
        public static func typingYouTypedPrefix(_ text: String) -> String {
            String(format: String(localized: "app.reflex.drill.typing_you_typed", defaultValue: "Bạn đã nhập: \"%@\"", bundle: .module), text)
        }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexTypingLocalizationTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftApp/Core/Localization/AppStrings+ReflexBlitz.swift VocabCraftAppTests/Reflex/ReflexLocalizationTests.swift
git commit -m "feat(reflex): add localization strings for typing mode redesign"
```

---

### Task 2: Update `ReflexBlitzViewModel.submitTypingAnswer` Logic & ViewModel Tests

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift:427-472`
- Test: `VocabCraftAppTests/Reflex/ReflexBlitzViewModelTests.swift`

**Interfaces:**
- Consumes: `ReflexBlitzWordItem`, `ReflexCardResult`, `SoundEffectServiceProtocol`
- Produces: Updated `submitTypingAnswer(_ text: String)` supporting both correct and incorrect submissions and ignoring empty strings.

- [ ] **Step 1: Write failing test in ViewModel tests for typing submission**

In `VocabCraftAppTests/Reflex/ReflexBlitzViewModelTests.swift`, add:
```swift
    @Test("Typing submission handles empty, correct, and incorrect inputs")
    func testTypingSubmission() async {
        let sampleWord = ReflexBlitzWordItem(
            id: 1, lemma: "apple", pos: "n.", ipa: "/ˈæpl/",
            definitionVi: "quả táo", level: "A1", clozeSentenceEn: "I eat an [apple].",
            exampleSentenceVi: "Tôi ăn một quả táo."
        )
        let viewModel = ReflexBlitzViewModel(words: [sampleWord])
        viewModel.selectMode(.typing)
        viewModel.beginSessionDirectly()

        // Empty string should be ignored
        viewModel.submitTypingAnswer("   ")
        #expect(viewModel.cardPhase == .activeCountdown)

        // Incorrect string should transition to reviewed with isCorrect = false
        viewModel.submitTypingAnswer("aple")
        if case .reviewed(let result) = viewModel.cardPhase {
            #expect(result.isCorrect == false)
            #expect(result.typedText == "aple")
        } else {
            Issue.record("Expected reviewed phase on incorrect typing")
        }
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexBlitzViewModelTests`
Expected: FAIL (empty or incorrect behavior currently exits without review transition).

- [ ] **Step 3: Update `submitTypingAnswer` in `ReflexBlitzViewModel.swift`**

```swift
    public func submitTypingAnswer(_ text: String) {
        guard phase == .drilling, cardPhase == .activeCountdown, let word = currentWord else { return }
        let cleanInput = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanInput.isEmpty else { return }

        cancelActiveTimers()
        let isCorrect = cleanInput.lowercased() == word.lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        currentAttemptIsCorrect = isCorrect

        if isCorrect {
            soundEffectService.playSuccessChime()
            comboStreak += 1
            if comboStreak > maxComboStreak {
                maxComboStreak = comboStreak
            }
        } else {
            soundEffectService.playIncorrectChime()
            comboStreak = 0
        }

        let responseMs: Int
        if elapsedTimeMs > 0 {
            responseMs = elapsedTimeMs
        } else if let start = wordStartTime {
            responseMs = max(0, Int(Date().timeIntervalSince(start) * 1000))
            self.elapsedTimeMs = responseMs
        } else {
            responseMs = 0
        }

        let attempt = ReflexBlitzAttempt(
            wordId: word.id, lemma: word.lemma, pos: word.pos, ipa: word.ipa,
            definitionVi: word.definitionVi, responseTimeMs: responseMs,
            usedHint: showHint, isCorrect: isCorrect
        )
        attempts.append(attempt)

        Task {
            _ = try? await self.evaluateSRSUseCase.recordReview(
                wordId: Int64(word.id), isCorrect: isCorrect, responseTimeMs: responseMs
            )
        }

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            self.cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: isCorrect, responseTimeMs: responseMs, isTimeout: false,
                selectedOption: nil, typedText: cleanInput, recognizedSpoken: nil
            ))
        }

        if !isCorrect {
            ttsService.speak(text: word.lemma, rate: 0.5, locale: "en-US")
        }
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexBlitzViewModelTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift VocabCraftAppTests/Reflex/ReflexBlitzViewModelTests.swift
git commit -m "feat(reflex): support full typing validation and feedback in ViewModel"
```

---

### Task 3: Redesign `ReflexTypingModeView` (3D FlipCard & Keyboard-Docked Floating Bar)

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexTypingModeView.swift`

**Interfaces:**
- Produces:
```swift
public struct ReflexTypingModeView: View {
    public let word: any ReflexDrillable
    public let isReviewed: Bool
    public let isResultCorrect: Bool
    public let isResultTimeout: Bool
    public let showHint: Bool
    public let hintStage: Int
    @Binding public var typingText: String
    public let userSubmittedText: String?
    public let clozeParts: ClozeSentenceParts?
    public let displayedSentence: String
    public let onSubmit: (() -> Void)?
    public let onReplayAudio: (() -> Void)?
}
```

- [ ] **Step 1: Write `ReflexTypingModeView.swift` implementation**

Implement `ReflexTypingModeView` with:
1. `flipStimulusCard` using `CraftFlipCard`:
   - Front Face: Definition VI, POS & Level badges, cloze sentence with blank `___`.
   - Back Face: Lemma + `CraftSpeakerButton`, IPA, user input subtitle (`typingEnteredPrefix` or `typingYouTypedPrefix`), POS & Level badges, Definition VI, completed example sentence (EN + VI).
2. Floating input pill dock:
   - Visible when `!isReviewed`.
   - Pinned above keyboard using `@FocusState private var isTextFieldFocused: Bool`.
   - Rounded pill style with `surfaceElevated` background, `hairline` border, SF Symbol `keyboard`, placeholder `AppStrings.ReflexBlitz.typingPlaceholderText`.
   - `.submitLabel(.go)` and `.onSubmit { onSubmit?() }`.
   - Auto-focus `isTextFieldFocused = true` on appear, and dismiss when `isReviewed` is true.

- [ ] **Step 2: Verify compilation and preview rendering**

Run: `swift build` (or XcodeBuildMCP) to verify 0 errors and 0 warnings on `ReflexTypingModeView.swift`.

- [ ] **Step 3: Commit**

```bash
git add VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexTypingModeView.swift
git commit -m "feat(reflex): redesign ReflexTypingModeView with 3D flip card and floating input dock"
```

---

### Task 4: Integrate `ReflexTypingModeView` into `ReflexBlitzView` & Remove Skip Button

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Blitz/Views/ReflexBlitzView.swift`

**Interfaces:**
- Integrates `ReflexTypingModeView` directly in `cardContent(for:)` without the legacy card container.
- Ensures the bottom Skip button is removed for Typing mode (`viewModel.selectedMode == .speaking` only).
- Manages smooth keyboard dismissal and feedback sheet slide-up upon review.

- [ ] **Step 1: Update `ReflexBlitzView.swift`**

1. In `cardContent(for word: ReflexBlitzWordItem)`:
   - For `selectedMode == .typing`:
```swift
ReflexTypingModeView(
    word: word,
    isReviewed: isReviewed,
    isResultCorrect: viewModel.currentAttemptIsCorrect,
    isResultTimeout: isReviewedTimeout,
    showHint: viewModel.showHint,
    hintStage: viewModel.hintStage,
    typingText: $typingInput,
    userSubmittedText: reviewResult?.typedText ?? typingInput,
    clozeParts: ReflexClozeFormatter.extractTemplateParts(from: word.clozeSentenceEn),
    displayedSentence: isReviewed ? word.completedSentenceWithTargetWord : word.clozeSentenceEn,
    onSubmit: {
        viewModel.submitTypingAnswer(typingInput)
    },
    onReplayAudio: {
        viewModel.speakCurrentWord()
    }
)
.padding(.horizontal, theme.spacing.base)
```
2. In Skip button condition:
   - Change `viewModel.selectedMode == .speaking || viewModel.selectedMode == .typing` to `viewModel.selectedMode == .speaking`.

- [ ] **Step 2: Verify smooth transition in `drillingView`**

Ensure `CraftFeedbackSheet` displays cleanly without keyboard interference when review state triggers.

- [ ] **Step 3: Commit**

```bash
git add VocabCraftApp/Features/Reflex/Blitz/Views/ReflexBlitzView.swift
git commit -m "feat(reflex): integrate redesigned typing mode into ReflexBlitzView and remove skip button"
```

---

### Task 5: Full Verification & Quality Gate

**Files:**
- All touched files

- [ ] **Step 1: Run Localization Verification**
Run: `swift test --filter ReflexLocalizationTests`

- [ ] **Step 2: Run All App Tests**
Run: `swift test`

- [ ] **Step 3: Run SwiftLint**
Run: `swiftlint` (or via package plugin) and fix any warnings.

- [ ] **Step 4: Verify 0 Compiler Warnings**
Compile with Xcode/Swift build to ensure 0 errors and 0 warnings.

- [ ] **Step 5: Final Commit**
```bash
git commit -m "chore: complete quality gate verification for typing mode redesign"
```
