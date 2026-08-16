# Quick Reflex Collocation Ladder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the single-word quick reflex practice into a 3-tier productive reflex ladder (Word Recall $\rightarrow$ Collocation Chunking $\rightarrow$ Sentence Production & Native Shadowing with SpeechKit assessment).

**Architecture:** Add a pure domain `CollocationExtractor` and expand `QuickReflexPromptFactory` for cloze and collocation generation. Upgrade `QuickReflexDrillViewModel` to orchestrate the 3-phase state machine with optional native shadowing evaluation, and redesign `QuickReflexDrillSheetView` for smooth stage transitions, audio mirror playback, and pronunciation feedback.

**Tech Stack:** Swift 5.10 / Swift 6, SwiftUI (Observation), SwiftData, AVFoundation (TTS/STT), SpeechKit (`SpeechAssessmentProtocol`), XCTest.

**Spec:** `docs/superpowers/specs/2026-08-16-quick-reflex-collocation-ladder-design.md`

## Global Constraints

- Platform: iOS 17.0+ (SwiftUI, Observation framework).
- Localization: All user-facing strings must use `AppStrings.Reflex` and `Localizable.xcstrings`. No hardcoded UI strings.
- Speech & Audio: TTS and STT resources must be cleanly managed and torn down on sheet dismissal/pause.
- Architecture: ViewModel depends only on domain models and protocols (`SpeechAssessmentProtocol`, `EvaluateSRSUseCaseProtocol`, `QuickReflexAttemptRepositoryProtocol`).

---

### Task 1: Domain Models, CollocationExtractor & 3-Tier Prompt Factory

**Files:**
- Create: `VocabCraftApp/Features/Vocabulary/Services/CollocationExtractor.swift`
- Modify: `VocabCraftApp/Features/Vocabulary/Models/WordItem.swift`
- Modify: `VocabCraftApp/Core/Database/DatasetModels.swift`
- Modify: `VocabCraftApp/Features/Vocabulary/Models/QuickReflexPrompt.swift`
- Modify: `VocabCraftApp/Features/Vocabulary/Services/QuickReflexPromptFactory.swift`
- Create: `VocabCraftAppTests/Features/Vocabulary/CollocationExtractorTests.swift`
- Modify: `VocabCraftAppTests/Features/Vocabulary/QuickReflexPromptFactoryTests.swift`

**Interfaces:**
- Consumes: `WordItem`, `WordRecord`, `StringNormalizer`
- Produces: `CollocationExtractor.extract(for word: WordItem) -> String`, `QuickReflexPhase` (`.recallWord`, `.recallCollocation`, `.produceSentence`, `.shadowModel`, `.result`), `QuickReflexStagePrompt`, `QuickReflexPrompts`

- [ ] **Step 1: Write failing unit tests for CollocationExtractor**

```swift
// VocabCraftAppTests/Features/Vocabulary/CollocationExtractorTests.swift
import XCTest
@testable import VocabCraftApp

final class CollocationExtractorTests: XCTestCase {
    func testExtractUsesExplicitCollocationWhenAvailable() {
        let word = WordItem(
            id: 1,
            lemma: "Ephemeral",
            phonetic: "/ɪˈfem.ər.əl/",
            pos: "adj.",
            definition: "Phù du",
            exampleSentenceEn: "Her fame proved to be ephemeral.",
            exampleSentenceVi: "Danh tiếng ngắn ngủi",
            cefrLevel: "B2",
            masteryLevel: 3,
            collocationEn: "ephemeral fame"
        )
        let collocation = CollocationExtractor.extract(for: word)
        XCTAssertEqual(collocation, "ephemeral fame")
    }

    func testExtractFromExampleSentenceWhenExplicitCollocationMissing() {
        let word = WordItem(
            id: 2,
            lemma: "Resilience",
            phonetic: "/rɪˈzɪl.jəns/",
            pos: "n.",
            definition: "Kiên cường",
            exampleSentenceEn: "Courage and resilience are essential for victory.",
            exampleSentenceVi: "Kiên cường",
            cefrLevel: "C1",
            masteryLevel: 4
        )
        let collocation = CollocationExtractor.extract(for: word)
        XCTAssertFalse(collocation.isEmpty)
        XCTAssertTrue(collocation.lowercased().contains("resilience"))
    }

    func testExtractFallbackByPartOfSpeech() {
        let word = WordItem(
            id: 3,
            lemma: "innovate",
            phonetic: "/ˈɪn.ə.veɪt/",
            pos: "v.",
            definition: "Đổi mới",
            exampleSentenceEn: "",
            exampleSentenceVi: "",
            cefrLevel: "B2",
            masteryLevel: 1
        )
        let collocation = CollocationExtractor.extract(for: word)
        XCTAssertEqual(collocation, "to innovate actively")
    }
}
```

- [ ] **Step 2: Run test and verify failure**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/CollocationExtractorTests`
Expected: FAIL (Type not found).

- [ ] **Step 3: Implement CollocationExtractor and update WordItem/WordRecord models**

Extend `WordItem` and `WordRecord` with `collocationEn: String? = nil` and `collocationVi: String? = nil`.
Implement `CollocationExtractor`:
```swift
// VocabCraftApp/Features/Vocabulary/Services/CollocationExtractor.swift
import Foundation

public enum CollocationExtractor {
    public static func extract(for word: WordItem) -> String {
        if let explicit = word.collocationEn?.trimmingCharacters(in: .whitespacesAndNewlines), !explicit.isEmpty {
            return explicit
        }
        
        let example = word.exampleSentenceEn.trimmingCharacters(in: .whitespacesAndNewlines)
        if !example.isEmpty {
            if let chunk = extractChunk(lemma: word.lemma, from: example) {
                return chunk
            }
        }
        
        return ruleBasedFallback(lemma: word.lemma, pos: word.pos)
    }

    private static func extractChunk(lemma: String, from sentence: String) -> String? {
        let cleanSentence = sentence.replacingOccurrences(of: "[\"',.!?]", with: "", options: .regularExpression)
        let tokens = cleanSentence.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard let index = tokens.firstIndex(where: { $0.caseInsensitiveCompare(lemma) == .orderedSame }) else {
            return nil
        }
        
        let start = max(0, index - 1)
        let end = min(tokens.count, index + 2)
        let chunk = tokens[start..<end].joined(separator: " ")
        return chunk.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : chunk.lowercased()
    }

    private static func ruleBasedFallback(lemma: String, pos: String) -> String {
        let normalizedPos = pos.lowercased()
        if normalizedPos.contains("verb") || normalizedPos.contains("v.") {
            return "to \(lemma.lowercased()) actively"
        }
        if normalizedPos.contains("noun") || normalizedPos.contains("n.") {
            return "great \(lemma.lowercased())"
        }
        if normalizedPos.contains("adj") {
            return "\(lemma.lowercased()) situation"
        }
        return "\(lemma.lowercased()) in practice"
    }
}
```

- [ ] **Step 4: Update QuickReflexPrompt and QuickReflexPromptFactory for 3 stages**

Update `QuickReflexPhase`:
```swift
public enum QuickReflexPhase: Equatable, Sendable {
    case recallWord
    case recallCollocation
    case produceSentence
    case shadowModel
    case result
}

public struct QuickReflexStagePrompt: Equatable, Sendable {
    public let phase: QuickReflexPhase
    public let promptText: String
    public let targetExpression: String
    public let hints: [String]
    public let sentenceFrame: String?
    public let modelAudioSentenceEn: String?
    
    public init(
        phase: QuickReflexPhase,
        promptText: String,
        targetExpression: String,
        hints: [String] = [],
        sentenceFrame: String? = nil,
        modelAudioSentenceEn: String? = nil
    ) {
        self.phase = phase
        self.promptText = promptText
        self.targetExpression = targetExpression
        self.hints = hints
        self.sentenceFrame = sentenceFrame
        self.modelAudioSentenceEn = modelAudioSentenceEn
    }
}

public struct QuickReflexPrompts: Equatable, Sendable {
    public let recallWord: QuickReflexStagePrompt
    public let recallCollocation: QuickReflexStagePrompt
    public let produceSentence: QuickReflexStagePrompt
    public let modelSentenceEn: String
}
```

Update `QuickReflexPromptFactory` to create cloze prompts for stage 1, collocation prompts for stage 2, and sentence + model audio prompts for stage 3.

- [ ] **Step 5: Run tests and verify passing**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/CollocationExtractorTests -only-testing:VocabCraftAppTests/QuickReflexPromptFactoryTests`
Expected: `TEST SUCCEEDED`.

- [ ] **Step 6: Commit Task 1**

```bash
git add VocabCraftApp/Features/Vocabulary/Models/WordItem.swift VocabCraftApp/Core/Database/DatasetModels.swift VocabCraftApp/Features/Vocabulary/Models/QuickReflexPrompt.swift VocabCraftApp/Features/Vocabulary/Services/CollocationExtractor.swift VocabCraftApp/Features/Vocabulary/Services/QuickReflexPromptFactory.swift VocabCraftAppTests/Features/Vocabulary/CollocationExtractorTests.swift VocabCraftAppTests/Features/Vocabulary/QuickReflexPromptFactoryTests.swift
git commit -m "feat: add CollocationExtractor and 3-tier quick reflex prompt factory"
```

---

### Task 2: QuickReflexAttempt Model & Persistence Record

**Files:**
- Modify: `VocabCraftApp/Domain/Models/QuickReflexAttempt.swift`
- Modify: `VocabCraftApp/Core/Database/SwiftDataModels.swift`
- Modify: `VocabCraftApp/Data/Repositories/QuickReflexAttemptRepositoryImpl.swift`
- Modify: `VocabCraftAppTests/SwiftDataModelsTests.swift`
- Modify: `VocabCraftAppTests/Features/Vocabulary/QuickReflexAttemptRepositoryTests.swift`

**Interfaces:**
- Consumes: `QuickReflexAttempt`, `QuickReflexAttemptRecord`
- Produces: `QuickReflexAttemptRepositoryProtocol` storing 3-phase timing (`recallWordTimeMs`, `collocationTimeMs`, `produceSentenceTimeMs`, `shadowPronunciationScore`)

- [ ] **Step 1: Update QuickReflexAttempt domain model and write failing tests**

Update `QuickReflexAttempt`:
```swift
public struct QuickReflexAttempt: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let wordId: Int64
    public let recallWordTimeMs: Int
    public let collocationTimeMs: Int
    public let produceSentenceTimeMs: Int
    public let recallWordSucceeded: Bool
    public let collocationSucceeded: Bool
    public let produceSentenceSucceeded: Bool
    public let shadowPronunciationScore: Double?
    public let maxHintLevel: Int
    public let inputMode: QuickReflexInputMode
    public let retryCount: Int
    public let confidence: QuickReflexConfidence
    public let timestamp: Date
}
```

Write failing tests in `QuickReflexAttemptRepositoryTests.swift` testing storage and retrieval with the new fields.

- [ ] **Step 2: Run tests and verify failure**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/QuickReflexAttemptRepositoryTests`

- [ ] **Step 3: Update SwiftData QuickReflexAttemptRecord and RepositoryImpl**

Update `QuickReflexAttemptRecord` in `SwiftDataModels.swift` and mapping in `QuickReflexAttemptRepositoryImpl.swift`.

- [ ] **Step 4: Run tests and verify passing**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/QuickReflexAttemptRepositoryTests -only-testing:VocabCraftAppTests/SwiftDataModelsTests`
Expected: `TEST SUCCEEDED`.

- [ ] **Step 5: Commit Task 2**

```bash
git add VocabCraftApp/Domain/Models/QuickReflexAttempt.swift VocabCraftApp/Core/Database/SwiftDataModels.swift VocabCraftApp/Data/Repositories/QuickReflexAttemptRepositoryImpl.swift VocabCraftAppTests/Features/Vocabulary/QuickReflexAttemptRepositoryTests.swift VocabCraftAppTests/SwiftDataModelsTests.swift
git commit -m "feat: update quick reflex attempt persistence for 3-tier metrics"
```

---

### Task 3: QuickReflexDrillViewModel 3-Tier State Machine & SpeechKit Integration

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/ViewModels/QuickReflexDrillViewModel.swift`
- Modify: `VocabCraftAppTests/Features/Vocabulary/QuickReflexDrillViewModelTests.swift`

**Interfaces:**
- Consumes: `SpeechRecognitionProtocol`, `TextToSpeechProtocol`, `SpeechAssessmentProtocol`, `QuickReflexAttemptRepositoryProtocol`, `EvaluateSRSUseCaseProtocol`
- Produces: `QuickReflexDrillViewModel` managing `.recallWord` $\rightarrow$ `.recallCollocation` $\rightarrow$ `.produceSentence` $\rightarrow$ `.shadowModel` $\rightarrow$ `.result`

- [ ] **Step 1: Write failing unit tests for the 3-tier ViewModel state transitions**

```swift
// VocabCraftAppTests/Features/Vocabulary/QuickReflexDrillViewModelTests.swift
func testFullLadderProgressesThroughAllStagesAndRecordsSRS() async throws {
    let viewModel = makeViewModel()
    
    // Stage 1: Recall Word
    XCTAssertEqual(viewModel.state.phase, .recallWord)
    viewModel.submitTypedAnswer("Ephemeral")
    XCTAssertEqual(viewModel.state.phase, .recallCollocation)
    XCTAssertTrue(viewModel.state.recallWordSucceeded)
    
    // Stage 2: Recall Collocation
    viewModel.submitTypedAnswer("ephemeral fame")
    XCTAssertEqual(viewModel.state.phase, .produceSentence)
    XCTAssertTrue(viewModel.state.collocationSucceeded)
    
    // Stage 3: Sentence Production -> Shadow Model
    viewModel.submitTypedAnswer("Her fame was ephemeral.")
    XCTAssertEqual(viewModel.state.phase, .shadowModel)
    
    // Shadowing action / skip
    viewModel.proceedToResult()
    XCTAssertEqual(viewModel.state.phase, .result)
    
    try await viewModel.finish(confidence: .comfortable)
    XCTAssertEqual(mockSRS.recordedCalls.count, 1)
    XCTAssertEqual(mockAttempts.saved.count, 1)
}

func testShadowingInvokesSpeechAssessment() {
    let viewModel = makeViewModel()
    viewModel.state.phase = .shadowModel
    viewModel.startShadowingAssessment()
    XCTAssertTrue(mockSpeechAssessment.isListening)
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/QuickReflexDrillViewModelTests`

- [ ] **Step 3: Implement QuickReflexDrillViewModel state transitions & audio orchestration**

Implement:
- `submit(_:mode:)`: transitions through `.recallWord` $\rightarrow$ `.recallCollocation` $\rightarrow$ `.produceSentence` $\rightarrow$ `.shadowModel`.
- In `.shadowModel`, automatically play TTS model sentence `ttsService.speak(modelSentenceEn)`.
- `startShadowingAssessment()`: calls `speechAssessmentService.startAssessing(targetSentence: modelSentenceEn)` and binds `speechEvaluationResult`.
- `proceedToResult()`: moves to `.result`.
- `finish(confidence:)`: calls SRS record review only if `recallWordSucceeded && collocationSucceeded`. Saves `QuickReflexAttempt`.

- [ ] **Step 4: Run ViewModel test suite and verify passing**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/QuickReflexDrillViewModelTests`
Expected: `TEST SUCCEEDED`.

- [ ] **Step 5: Commit Task 3**

```bash
git add VocabCraftApp/Features/Vocabulary/ViewModels/QuickReflexDrillViewModel.swift VocabCraftAppTests/Features/Vocabulary/QuickReflexDrillViewModelTests.swift
git commit -m "feat: implement 3-tier state machine and shadowing in QuickReflexDrillViewModel"
```

---

### Task 4: QuickReflexDrillSheetView Redesign & Localization

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/Views/QuickReflexDrillSheetView.swift`
- Modify: `VocabCraftApp/Core/Localization/AppStrings.swift`
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftAppTests/Features/Vocabulary/QuickReflexDrillSheetViewTests.swift`

**Interfaces:**
- Consumes: `QuickReflexDrillViewModel`, `VocabMicControlHubView`, `VocabSpeechVisualizerView`, `AppStrings.Reflex`
- Produces: Native SwiftUI `QuickReflexDrillSheetView` with 3-segment progress, interactive shadowing card, and comprehensive result summary.

- [ ] **Step 1: Write failing UI snapshot/initialization tests for 3-tier sheet**

Write tests in `QuickReflexDrillSheetViewTests.swift` asserting header indicator renders `stageNumber/3` for stages 1, 2, 3 and result card displays 3-tier breakdown.

- [ ] **Step 2: Run test to verify failure**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/QuickReflexDrillSheetViewTests`

- [ ] **Step 3: Update AppStrings & Localizable.xcstrings**

Add localization keys for:
- `quickProgressSegment`: `"Nấc %lld/3"`
- `quickStage1Title`: `"Nấc 1: Điền từ vào ngữ cảnh"`
- `quickStage2Title`: `"Nấc 2: Phản xạ Cụm từ (Collocation)"`
- `quickStage3Title`: `"Nấc 3: Đặt câu & Nhại lại mẫu"`
- `quickShadowButton`: `"🎙️ Nhại lại (Shadow)"`
- `quickShadowScoreLabel`: `"Điểm phát âm: %lld%%"`
- `quickListenModelAgain`: `"Nghe lại câu mẫu"`
- `quickContinue`: `"Tiếp tục"`

- [ ] **Step 4: Redesign QuickReflexDrillSheetView**

Implement:
- Progress bar with 3 segments.
- Stage 1 Card: Cloze prompt + definition badge + progressive hints.
- Stage 2 Card: Lemma badge + collocation prompt + hints.
- Stage 3 Card:
  - Phase 3a: Free sentence input.
  - Phase 3b (Shadowing): Expands with `.spring()`, displays native model sentence, audio play button, shadow mic button with word-by-word `VocabSpeechVisualizerView`, and "Tiếp tục" button.
- Result View: 3-tier status rows + time delta comparison + confidence buttons.

- [ ] **Step 5: Run UI tests and verify passing**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/QuickReflexDrillSheetViewTests`
Expected: `TEST SUCCEEDED`.

- [ ] **Step 6: Commit Task 4**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/QuickReflexDrillSheetView.swift VocabCraftApp/Core/Localization/AppStrings.swift VocabCraftApp/Resources/Localizable.xcstrings VocabCraftAppTests/Features/Vocabulary/QuickReflexDrillSheetViewTests.swift
git commit -m "feat: redesign QuickReflexDrillSheetView for 3-tier ladder and shadowing"
```

---

### Task 5: Integration & Full Regression Verification

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift`
- Modify: `VocabCraftAppTests/Features/Vocabulary/VocabularyViewTests.swift`

- [ ] **Step 1: Verify sheet presentation wiring in VocabularyView**

Confirm `speechAssessmentService` and `attemptRepository` from `appContainer` are properly injected into `QuickReflexDrillSheetView`.

- [ ] **Step 2: Run the complete test suite**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 3: Run project build**

Run: `xcodebuild build -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit integration and verification**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift VocabCraftAppTests/Features/Vocabulary/VocabularyViewTests.swift
git commit -m "feat: integrate 3-tier quick reflex collocation ladder into vocabulary view"
```
