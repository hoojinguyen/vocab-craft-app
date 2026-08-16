# Quick Reflex Ladder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current three-step multiple-choice quick drill with a voice-first, two-stage productive-recall exercise that updates SRS only after successful word retrieval.

**Architecture:** Add deterministic prompt-generation and target-expression matching domain units. Refactor the quick-drill view model into a two-stage state machine, persist rich attempt history separately from SRS, then present the state through a redesigned sheet with speech and typed entry fallbacks.

**Tech Stack:** Swift 5.10, SwiftUI/Observation, SwiftData, XCTest, existing SpeechKit and SRS use cases.

---

## File Structure

- Create `VocabCraftApp/Features/Vocabulary/Models/QuickReflexPrompt.swift`: immutable phase, prompt, hint, input-mode, and result value types.
- Create `VocabCraftApp/Features/Vocabulary/Services/QuickReflexPromptFactory.swift`: deterministic prompts from `WordItem`.
- Create `VocabCraftApp/Features/Vocabulary/Services/TargetExpressionMatcher.swift`: normalized whole-expression matching.
- Create `VocabCraftApp/Domain/Models/QuickReflexAttempt.swift`: persistence-neutral attempt record.
- Create `VocabCraftApp/Domain/Protocols/QuickReflexAttemptRepositoryProtocol.swift` and `VocabCraftApp/Data/Repositories/QuickReflexAttemptRepositoryImpl.swift`: store/fetch attempt history.
- Modify `VocabCraftApp/Core/Database/SwiftDataModels.swift` and `VocabCraftApp/Core/Database/SharedAppGroupContainer.swift`: add `QuickReflexAttemptRecord` and schema v2 migration.
- Modify `VocabCraftApp/App/DI/AppContainer.swift`, `QuickReflexDrillViewModel.swift`, `QuickReflexDrillSheetView.swift`, `VocabularyView.swift`, and `AppStrings.swift`/`Localizable.xcstrings`: inject services, replace state/UI, and expose localised copy.
- Modify/create focused XCTest files under `VocabCraftAppTests/Features/Vocabulary/` plus `SwiftDataModelsTests.swift`.

### Task 1: Define prompt and matching domain behavior

**Files:**
- Create: `VocabCraftApp/Features/Vocabulary/Models/QuickReflexPrompt.swift`
- Create: `VocabCraftApp/Features/Vocabulary/Services/QuickReflexPromptFactory.swift`
- Create: `VocabCraftApp/Features/Vocabulary/Services/TargetExpressionMatcher.swift`
- Create: `VocabCraftAppTests/Features/Vocabulary/QuickReflexPromptFactoryTests.swift`
- Create: `VocabCraftAppTests/Features/Vocabulary/TargetExpressionMatcherTests.swift`

- [ ] **Step 1: Write failing prompt-factory tests.**

```swift
func testMakePromptsUsesDefinitionForRetrievalAndExampleForUsage() {
    let prompts = QuickReflexPromptFactory().makePrompts(for: word)
    XCTAssertEqual(prompts.retrieve.targetExpression, "resilient")
    XCTAssertTrue(prompts.retrieve.promptText.contains(word.definition))
    XCTAssertTrue(prompts.use.promptText.contains(word.exampleSentenceVi))
    XCTAssertEqual(prompts.retrieve.hints, ["adj.", "r"])
}

func testMakePromptsFallsBackWhenExampleTranslationIsEmpty() {
    let prompts = QuickReflexPromptFactory().makePrompts(for: wordWithEmptyVietnameseExample)
    XCTAssertTrue(prompts.use.promptText.contains("một câu tiếng Anh"))
}
```

- [ ] **Step 2: Run the focused test and confirm it fails because the factory does not exist.**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/QuickReflexPromptFactoryTests`

Expected: compilation failure mentioning `QuickReflexPromptFactory`.

- [ ] **Step 3: Implement the model and factory.**

```swift
public enum QuickReflexPhase: Equatable, Sendable { case retrieve, useInSentence, result }
public enum QuickReflexInputMode: Equatable, Sendable { case voice, typing }

public struct QuickReflexStagePrompt: Equatable, Sendable {
    public let phase: QuickReflexPhase
    public let promptText: String
    public let targetExpression: String
    public let hints: [String]
}

public struct QuickReflexPrompts: Equatable, Sendable {
    public let retrieve: QuickReflexStagePrompt
    public let use: QuickReflexStagePrompt
}

public struct QuickReflexPromptFactory {
    public init() {}
    public func makePrompts(for word: WordItem) -> QuickReflexPrompts {
        let retrieve = QuickReflexStagePrompt(phase: .retrieve, promptText: word.definition,
            targetExpression: word.lemma, hints: [word.pos, String(word.lemma.prefix(1))])
        let useText = word.exampleSentenceVi.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Hãy nói một câu tiếng Anh có dùng \(word.lemma)."
            : word.exampleSentenceVi
        let use = QuickReflexStagePrompt(phase: .useInSentence, promptText: useText,
            targetExpression: word.lemma, hints: ["Dùng \(word.lemma) trong câu của bạn."])
        return QuickReflexPrompts(retrieve: retrieve, use: use)
    }
}
```

Build retrieve hints as `[word.pos, String(word.lemma.prefix(1))]`; build use text from `exampleSentenceVi`, else use `"Hãy nói một câu tiếng Anh có dùng \\(word.lemma)."`.

- [ ] **Step 4: Write failing matcher tests.**

```swift
func testContainsExpressionAcceptsCaseAndPunctuation() {
    XCTAssertTrue(TargetExpressionMatcher.contains("Resilient!", expression: "resilient"))
}
func testContainsExpressionRejectsSubstring() {
    XCTAssertFalse(TargetExpressionMatcher.contains("resiliently", expression: "resilient"))
}
func testContainsExpressionFindsMultiWordExpression() {
    XCTAssertTrue(TargetExpressionMatcher.contains("I look forward to it.", expression: "look forward"))
}
```

- [ ] **Step 5: Implement the matcher using token windows, then run both test targets.**

```swift
public enum TargetExpressionMatcher {
    public static func contains(_ response: String, expression: String) -> Bool {
        let responseTokens = StringNormalizer.tokenize(response)
        let expressionTokens = StringNormalizer.tokenize(expression)
        guard !expressionTokens.isEmpty, responseTokens.count >= expressionTokens.count else { return false }
        return responseTokens.indices.contains { index in
            responseTokens.dropFirst(index).prefix(expressionTokens.count).elementsEqual(expressionTokens)
        }
    }
}
```

Run the two commands from Steps 2 and 4 with their respective test targets. Expected: `TEST SUCCEEDED`.

- [ ] **Step 6: Commit the domain units and tests.**

```bash
git add VocabCraftApp/Features/Vocabulary/Models/QuickReflexPrompt.swift VocabCraftApp/Features/Vocabulary/Services/QuickReflexPromptFactory.swift VocabCraftApp/Features/Vocabulary/Services/TargetExpressionMatcher.swift VocabCraftAppTests/Features/Vocabulary/QuickReflexPromptFactoryTests.swift VocabCraftAppTests/Features/Vocabulary/TargetExpressionMatcherTests.swift
git commit -m "feat: add quick reflex prompt and matching services"
```

### Task 2: Persist attempts without coupling them to SRS

**Files:**
- Create: `VocabCraftApp/Domain/Models/QuickReflexAttempt.swift`
- Create: `VocabCraftApp/Domain/Protocols/QuickReflexAttemptRepositoryProtocol.swift`
- Create: `VocabCraftApp/Data/Repositories/QuickReflexAttemptRepositoryImpl.swift`
- Modify: `VocabCraftApp/Core/Database/SwiftDataModels.swift`
- Modify: `VocabCraftApp/Core/Database/SharedAppGroupContainer.swift`
- Modify: `VocabCraftAppTests/SwiftDataModelsTests.swift`

- [ ] **Step 1: Add failing in-memory SwiftData tests for a record and latest lookup.**

```swift
func testQuickReflexAttemptRecordStoresAllLearningSignals() throws {
    let record = QuickReflexAttemptRecord(wordId: 7, retrieveTimeMs: 1100, useTimeMs: 2600,
        retrieveSucceeded: true, useSucceeded: true, maxHintLevel: 1,
        inputModeRawValue: "voice", retryCount: 1, confidenceRawValue: "comfortable")
    context.insert(record); try context.save()
    XCTAssertEqual(try context.fetch(FetchDescriptor<QuickReflexAttemptRecord>()).count, 1)
}
```

- [ ] **Step 2: Run `SwiftDataModelsTests` and confirm it fails because the record is absent.**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/SwiftDataModelsTests`

Expected: compilation failure mentioning `QuickReflexAttemptRecord`.

- [ ] **Step 3: Add the SwiftData record, V2 schema, migration, and repository.**

```swift
@Model public final class QuickReflexAttemptRecord {
    @Attribute(.unique) public var id: UUID
    public var wordId: Int64; public var retrieveTimeMs: Int; public var useTimeMs: Int
    public var retrieveSucceeded: Bool; public var useSucceeded: Bool; public var maxHintLevel: Int
    public var inputModeRawValue: String; public var retryCount: Int; public var confidenceRawValue: String
    public var timestamp: Date
}

public protocol QuickReflexAttemptRepositoryProtocol: AnyObject {
    func save(_ attempt: QuickReflexAttempt) async throws
    func mostRecentSuccessfulAttempt(for wordId: Int64) async throws -> QuickReflexAttempt?
}
```

Create `SchemaV2` with all V1 models plus `QuickReflexAttemptRecord`; make `AppMigrationPlan.schemas` `[SchemaV1.self, SchemaV2.self]` and add `.lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)`.

- [ ] **Step 4: Run the model tests, then add repository tests for save/latest-success.**

The repository test must insert one failed and two successful records and assert the newest successful record is returned. Run its focused test target; expected `TEST SUCCEEDED`.

- [ ] **Step 5: Commit persistence independently.**

```bash
git add VocabCraftApp/Core/Database VocabCraftApp/Domain/Models/QuickReflexAttempt.swift VocabCraftApp/Domain/Protocols/QuickReflexAttemptRepositoryProtocol.swift VocabCraftApp/Data/Repositories/QuickReflexAttemptRepositoryImpl.swift VocabCraftAppTests/SwiftDataModelsTests.swift VocabCraftAppTests/Features/Vocabulary/QuickReflexAttemptRepositoryTests.swift
git commit -m "feat: persist quick reflex attempts"
```

### Task 3: Replace the quick-drill view-model state machine

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/ViewModels/QuickReflexDrillViewModel.swift`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Modify: `VocabCraftAppTests/Features/Vocabulary/QuickReflexDrillViewModelTests.swift`

- [ ] **Step 1: Replace obsolete three-step tests with failing two-stage tests.**

```swift
func testSuccessfulRetrieveThenUseRecordsSRSOnce() async throws {
    viewModel.submitTypedAnswer("Ephemeral")
    XCTAssertEqual(viewModel.state.phase, .useInSentence)
    viewModel.submitTypedAnswer("The trend is ephemeral.")
    try await viewModel.finish(confidence: .comfortable)
    XCTAssertEqual(mockSRS.recordedCalls.count, 1)
    XCTAssertEqual(mockAttempts.saved.count, 1)
}

func testRevealAnswerDoesNotRecordSRS() async throws {
    viewModel.revealAnswer()
    try await viewModel.finish(confidence: .uncertain)
    XCTAssertTrue(mockSRS.recordedCalls.isEmpty)
}
```

- [ ] **Step 2: Run the view-model target and confirm it fails against the legacy `steps` API.**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/QuickReflexDrillViewModelTests`

Expected: compilation failures for `phase`, `submitTypedAnswer`, and attempt injection.

- [ ] **Step 3: Implement the state machine and safe lifecycle.**

```swift
public struct QuickReflexDrillState: Equatable, Sendable {
    public var phase: QuickReflexPhase = .retrieve
    public var inputMode: QuickReflexInputMode = .voice
    public var visibleHintLevel = 0; public var retryCount = 0
    public var retrieveSucceeded = false; public var useSucceeded = false
    public var retrieveTimeMs = 0; public var useTimeMs = 0
    public var isCompleted = false; public var isCancelled = false; public var errorMessage: String?
}

private func submit(_ answer: String, mode: QuickReflexInputMode) {
    guard !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
    state.inputMode = mode
    let target = state.phase == .retrieve ? prompts.retrieve.targetExpression : prompts.use.targetExpression
    let correct = TargetExpressionMatcher.contains(answer, expression: target)
    let elapsed = Int(clock().timeIntervalSince(activePhaseStartedAt) * 1_000)
    if state.phase == .retrieve {
        state.retrieveSucceeded = correct; state.retrieveTimeMs = elapsed
        if correct { state.phase = .useInSentence; activePhaseStartedAt = clock() }
    } else if state.phase == .useInSentence {
        state.useSucceeded = correct; state.useTimeMs = elapsed; state.phase = .result
    }
}
public func submitTypedAnswer(_ answer: String) { submit(answer, mode: .typing) }
public func revealAnswer() { state.phase = .result }
public func cancel() { stopListeningAndTimers(); state.isCancelled = true }
```

Inject `QuickReflexPromptFactory`, `QuickReflexAttemptRepositoryProtocol`, a clock closure (`() -> Date`), and `EvaluateSRSUseCaseProtocol`. Start raw STT for both stages, match transcripts with `TargetExpressionMatcher`, give one retry for empty/unclear speech, and expose typing on errors. Inside `finish`, call `try await evaluateSRSUseCase.recordReview(wordId: targetWord.id, isCorrect: true, responseTimeMs: state.retrieveTimeMs)` only when `retrieveSucceeded`; save every completed result as an attempt.

- [ ] **Step 4: Add and run tests for hint progression, retry/error typing fallback, cancellation stop, and one-way transitions.**

Assert: 4/7-second timer events raise hint level without changing correctness; a speech error changes `inputMode` to `.typing`; `cancel()` calls mock `stopListening`; a use-stage answer cannot return to retrieve.

- [ ] **Step 5: Wire the repository in `AppContainer` and commit.**

```bash
git add VocabCraftApp/Features/Vocabulary/ViewModels/QuickReflexDrillViewModel.swift VocabCraftApp/App/DI/AppContainer.swift VocabCraftAppTests/Features/Vocabulary/QuickReflexDrillViewModelTests.swift
git commit -m "feat: add productive quick reflex state machine"
```

### Task 4: Redesign the sheet for voice-first productive practice

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/Views/QuickReflexDrillSheetView.swift`
- Modify: `VocabCraftApp/Core/Localization/AppStrings.swift`
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftAppTests/Features/Vocabulary/QuickReflexDrillSheetViewTests.swift`

- [ ] **Step 1: Add failing view-construction tests for all phase configurations and type fallback.**

```swift
func testSheetInitializesForRetrieveAndTypingFallback() {
    let view = QuickReflexDrillSheetView(targetWord: word, allWords: [word], onComplete: { _ in })
    XCTAssertNotNil(view)
}
```

- [ ] **Step 2: Replace option rows/countdown with a phase card.**

Use one card that renders `state.phase`: retrieve hides `lemma`; use shows it; both expose `VocabMicControlHubView`, transcript feedback, a 44pt `TextField`/submit button fallback, progressive hints, reveal/skip, and close. The result card renders two independent status rows, latest-time comparison if available, and the two confidence buttons.

Add localisation keys for retrieve/use prompts, voice/type actions, hints, retry, reveal, skip, result labels, and confidence. Do not leave Vietnamese literals outside existing localisation conventions.

- [ ] **Step 3: Run the sheet test target, build the app, and perform VoiceOver/manual QA.**

Run:
`xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/QuickReflexDrillSheetViewTests`

Expected: `TEST SUCCEEDED`.

Manual checks: both mic and type controls are at least 44pt; VoiceOver announces stage and visible hint; microphone permission denial exposes typing; closing stops listening.

- [ ] **Step 4: Commit the UI slice.**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/QuickReflexDrillSheetView.swift VocabCraftApp/Core/Localization/AppStrings.swift VocabCraftApp/Resources/Localizable.xcstrings VocabCraftAppTests/Features/Vocabulary/QuickReflexDrillSheetViewTests.swift
git commit -m "feat: redesign quick reflex drill interface"
```

### Task 5: Integrate, verify regressions, and document manual checks

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift`
- Modify: `VocabCraftAppTests/Features/Vocabulary/VocabularyViewTests.swift`

- [ ] **Step 1: Write a failing integration test that constructs `VocabularyView` with a selected word and completes a successful retrieval callback.**

```swift
func testVocabularyViewCanPresentQuickReflexSheetForSelectedWord() {
    let view = VocabularyView(viewModel: mockViewModel, appContainer: .mock)
    XCTAssertNotNil(view)
}
```

- [ ] **Step 2: Keep the existing sheet binding but pass the attempt repository from `AppContainer`; update the completion callback only when `srsResult` exists.**

The callback must retain the current local-star update behavior, while a deferred attempt dismisses without overwriting `masteryLevel`.

- [ ] **Step 3: Run the complete suite and build.**

Run:
`xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16'`

Run:
`xcodebuild build -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16'`

Expected: both commands finish with `** TEST SUCCEEDED **` / `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit integration and verification-ready tests.**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift VocabCraftAppTests/Features/Vocabulary/VocabularyViewTests.swift
git commit -m "feat: integrate quick reflex ladder from vocabulary"
```
