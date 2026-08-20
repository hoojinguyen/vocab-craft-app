# VocabCraft Performance & Reliability Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate fatal crash vectors (SQLite NULL dereferencing, Simulator CoreAudio exceptions), eliminate N+1 SwiftData queries causing multi-second freezes, remove 10Hz regex compilation in SwiftUI view bodies, optimize audio latency/deadlocks, and prevent Widget extension memory crashes.

**Architecture:** Apply Clean Architecture and thread-safe data flow. Move heavy computation and disk queries off `@MainActor`, batch fetch user progress records into $O(1)$ in-memory lookups, cache system resources (`AVSpeechSynthesisVoice`, `NSRegularExpression`), and isolate widget storage in a shared static container.

**Tech Stack:** Swift 5.10 / Swift 6, SwiftUI, SwiftData, AVFoundation, SpeechKit (SFSpeechRecognizer), SQLite3, Swift Testing / XCTest.

**Spec:** [`docs/superpowers/specs/2026-08-20-swiftui-performance-refactor-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-20-swiftui-performance-refactor-design.md)

## Global Constraints
- Target platforms: iOS 17.0+, macOS 14.0+.
- No third-party dependencies; use Foundation, SwiftUI, SwiftData, SQLite3, AVFoundation, and Speech frameworks directly.
- Maintain full backward compatibility for existing view models and views.
- Swift strict concurrency compliance (`@MainActor`, `Sendable`, Actor isolation).

---

### Task 1: Safe SQLite C-String Extraction in `DatasetEngine`

**Files:**
- Modify: `VocabCraftApp/Core/Database/DatasetEngine.swift`
- Test: `VocabCraftAppTests/DatasetEngineTests.swift` (or existing dataset tests)

**Interfaces:**
- Consumes: Raw SQLite statement pointers from `sqlite3_step`.
- Produces: Safe non-optional and optional `String` values without nil dereferencing.

- [ ] **Step 1: Add private safe string helper methods to `DatasetEngine`**
```swift
private func columnText(_ statement: OpaquePointer?, _ index: Int32) -> String {
    guard let cStr = sqlite3_column_text(statement, index) else { return "" }
    return String(cString: cStr)
}

private func optionalColumnText(_ statement: OpaquePointer?, _ index: Int32) -> String? {
    guard let cStr = sqlite3_column_text(statement, index) else { return nil }
    return String(cString: cStr)
}
```

- [ ] **Step 2: Replace all 16 unsafe `String(cString: sqlite3_column_text(...))` calls in `DatasetEngine.swift`**
Update:
- `getRandomReflexDrill` (lines 44, 46)
- `getWordDetails` (line 84)
- `fetchWordRecords` (line 133)
- `searchWords` (line 177)
- `fetchWordById` (line 215)
- `fetchTopicDecks` (lines 257-260)
- `fetchSubTopicNodes` (lines 287-290)
- `fetchWordsForNode` (line 319)

- [ ] **Step 3: Run tests to verify `DatasetEngine` compiles and passes**
Run: `swift test --filter DatasetEngine`

- [ ] **Step 4: Commit changes**
```bash
git add VocabCraftApp/Core/Database/DatasetEngine.swift
git commit -m "fix(database): prevent SIGSEGV by safely extracting SQLite text columns"
```

---

### Task 2: Batch SwiftData Progress Retrieval in `UserProgressModelActor` & `VocabularyRepositoryImpl`

**Files:**
- Modify: `VocabCraftApp/Data/Local/Actors/UserProgressModelActor.swift`
- Modify: `VocabCraftApp/Data/Repositories/VocabularyRepositoryImpl.swift`
- Test: `VocabCraftAppTests/VocabularyRepositoryTests.swift`

**Interfaces:**
- Consumes: SwiftData `UserWordProgress` model context.
- Produces: `fetchAllMasteryLevels() async throws -> [Int64: Int]` and `fetchAllProgressDTO() async throws -> [Int64: SRSProgressItem]`.

- [ ] **Step 1: Add batch fetch methods in `UserProgressModelActor.swift`**
```swift
public func fetchAllMasteryLevels() throws -> [Int64: Int] {
    var descriptor = FetchDescriptor<UserWordProgress>()
    descriptor.propertiesToFetch = [\.wordId, \.masteryLevel]
    let items = try modelContext.fetch(descriptor)
    var map: [Int64: Int] = [:]
    map.reserveCapacity(items.count)
    for item in items {
        map[item.wordId] = item.masteryLevel
    }
    return map
}

public func fetchAllProgressMap() throws -> [Int64: SRSProgressItem] {
    let descriptor = FetchDescriptor<UserWordProgress>()
    let items = try modelContext.fetch(descriptor)
    var map: [Int64: SRSProgressItem] = [:]
    map.reserveCapacity(items.count)
    for item in items {
        map[item.wordId] = SRSProgressItem(
            wordId: item.wordId,
            masteryLevel: item.masteryLevel,
            easeFactor: item.easeFactor,
            intervalDays: item.intervalDays,
            nextReviewDate: item.nextReviewDate,
            lastReviewDate: item.lastReviewDate,
            totalReviews: item.totalReviews
        )
    }
    return map
}
```

- [ ] **Step 2: Refactor `fetchTopicDecks()` in `VocabularyRepositoryImpl.swift` to use batch lookup**
```swift
public func fetchTopicDecks() async throws -> [TopicDeck] {
    guard let engine = datasetEngine else { return MockVocabularyDataSource.shared.mockTopicDecks }
    let records = engine.fetchTopicDecks()
    if records.isEmpty {
        return MockVocabularyDataSource.shared.mockTopicDecks
    }

    let masteryMap = (try? await progressActor?.fetchAllMasteryLevels()) ?? [:]

    var decks: [TopicDeck] = []
    for r in records {
        let nodeRecords = engine.fetchSubTopicNodes(deckId: r.id)
        var totalWords = 0
        var learnedWords = 0

        for nodeRecord in nodeRecords {
            let wordRecords = engine.fetchWordsForNode(nodeId: nodeRecord.id)
            totalWords += wordRecords.count
            for w in wordRecords {
                if (masteryMap[w.id] ?? 0) >= 5 {
                    learnedWords += 1
                }
            }
        }

        let percentage = totalWords > 0 ? Double(learnedWords) / Double(totalWords) : 0.0
        decks.append(TopicDeck(
            id: r.id,
            title: r.title,
            wordCount: totalWords,
            completionPercentage: percentage,
            badgeColor: Color(hex: r.badgeColorHex),
            iconName: r.iconName
        ))
    }
    return decks
}
```

- [ ] **Step 3: Refactor `fetchTopicDeckDetails(deckId:)` to use batch lookup**
Load `progressMap` once prior to the node iteration loop.

- [ ] **Step 4: Run tests to verify batch retrieval**
Run: `swift test --filter VocabularyRepository`

- [ ] **Step 5: Commit changes**
```bash
git add VocabCraftApp/Data/Local/Actors/UserProgressModelActor.swift VocabCraftApp/Data/Repositories/VocabularyRepositoryImpl.swift
git commit -m "perf(repository): eliminate N+1 queries in topic decks using batch progress lookup"
```

---

### Task 3: Simulator Audio Mock & Thread-Safe Speech Recognition in `ContinuousReflexSpeechService`

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Services/ContinuousReflexSpeechService.swift`

**Interfaces:**
- Consumes: `ContinuousReflexSpeechProtocol`
- Produces: Safe audio streaming on device and simulated streaming on Simulator.

- [ ] **Step 1: Add Simulator fallback in `ContinuousReflexSpeechService.startSession`**
```swift
#if targetEnvironment(simulator)
isSessionActive = true
// Start simulation task emitting progressive results without touching CoreAudio hardware
#else
requestAuthorization { [weak self] authorized in
    ...
}
#endif
```

- [ ] **Step 2: Dispatch speech recognizer callbacks to `@MainActor`**
Wrap `onTranscriptUpdate`, `onMatchDetected`, and `onError` in `DispatchQueue.main.async` or `Task { @MainActor in }`.

- [ ] **Step 3: Test speech service on simulator and unit tests**
Run: `swift test`

- [ ] **Step 4: Commit changes**
```bash
git add VocabCraftApp/Features/ReflexDrill/Services/ContinuousReflexSpeechService.swift
git commit -m "fix(speech): add simulator audio fallback and thread-safe callbacks in reflex speech service"
```

---

### Task 4: Voice Caching & Timeout Safety in `TextToSpeechService`

**Files:**
- Modify: `VocabCraftApp/Core/Audio/TextToSpeechService.swift`

**Interfaces:**
- Consumes: `AVSpeechSynthesizer`
- Produces: Low-latency non-blocking TTS with continuation safety.

- [ ] **Step 1: Implement static voice cache in `TextToSpeechService`**
```swift
private static var cachedVoices: [String: AVSpeechSynthesisVoice] = [:]
private static let voiceLock = NSLock()

private static func resolveVoice(for locale: String) -> AVSpeechSynthesisVoice? {
    voiceLock.lock()
    defer { voiceLock.unlock() }
    if let cached = cachedVoices[locale] { return cached }
    let voice = AVSpeechSynthesisVoice(language: locale)
        ?? AVSpeechSynthesisVoice.speechVoices().first(where: { $0.language.hasPrefix("en") })
        ?? AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
    if let voice { cachedVoices[locale] = voice }
    return voice
}
```

- [ ] **Step 2: Add safety timeout to `speakAsync`**
Add a 10s timeout to prevent indefinite hangs if `didFinish` is never called.

- [ ] **Step 3: Run tests to verify TTS service**
Run: `swift test`

- [ ] **Step 4: Commit changes**
```bash
git add VocabCraftApp/Core/Audio/TextToSpeechService.swift
git commit -m "perf(audio): cache synthesis voices and add timeout safety to async speech"
```

---

### Task 5: Static Cloze Regex & Score Percentage Fix

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift`
- Modify: `VocabCraftApp/Core/DesignSystem/VocabSpeechVisualizerView.swift`

**Interfaces:**
- Consumes: `ReflexBlitzWordItem`, `SpeechEvaluationResult`
- Produces: High-performance cloze parsing and accurate score badges.

- [ ] **Step 1: Pre-compile cloze regex in `ReflexBlitzCardView`**
```swift
private static let clozeRegex: NSRegularExpression? = {
    try? NSRegularExpression(pattern: "\\[\\s*_{3,}\\s*\\]|_{3,}")
}()
```

- [ ] **Step 2: Fix percentage display in `VocabSpeechVisualizerView.swift:171`**
```swift
Text("⚡️ \(Int(eval.overallScore))%")
```

- [ ] **Step 3: Run tests to verify view rendering**
Run: `swift test`

- [ ] **Step 4: Commit changes**
```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift VocabCraftApp/Core/DesignSystem/VocabSpeechVisualizerView.swift
git commit -m "perf(ui): pre-compile cloze regex and fix speech evaluation percentage display"
```

---

### Task 6: Shared ModelContainer Singleton in Widget Extension

**Files:**
- Modify: `VocabCraftWidgetExtension/VocabWidget.swift`

**Interfaces:**
- Consumes: `SharedAppGroupContainer`
- Produces: Singleton `ModelContainer` for widget extension to maintain memory under 15MB.

- [ ] **Step 1: Add `WidgetContainerHolder` in `VocabWidget.swift`**
```swift
private enum WidgetContainerHolder {
    static let sharedContainer: ModelContainer? = try? SharedAppGroupContainer.createContainer()
}
```

- [ ] **Step 2: Update `fetchCurrentEntry` to use `WidgetContainerHolder.sharedContainer`**
```swift
public func fetchCurrentEntry(in container: ModelContainer? = nil) -> VocabWidgetEntry? {
    guard let targetContainer = container ?? WidgetContainerHolder.sharedContainer else {
        return nil
    }
    let context = ModelContext(targetContainer)
    ...
}
```

- [ ] **Step 3: Run widget tests**
Run: `swift test`

- [ ] **Step 4: Commit changes**
```bash
git add VocabCraftWidgetExtension/VocabWidget.swift
git commit -m "perf(widget): use singleton ModelContainer to prevent widget memory limit crashes"
```

---

### Task 7: Persistent Tab ViewModels in `HomepageView`

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`

**Interfaces:**
- Consumes: `AppContainer` ViewModels
- Produces: Stable view hierarchy preserving scroll position and state on tab switches.

- [ ] **Step 1: Introduce `@State` view models in `HomepageView`**
```swift
@State private var vocabularyVM: VocabularyViewModel?
@State private var settingsVM: SettingsViewModel?
```

- [ ] **Step 2: Initialize view models once on appearance or lazily via `@State`**
```swift
case .vocabulary:
    VocabularyView(viewModel: vocabularyVM ?? {
        let vm = appContainer.makeVocabularyViewModel()
        vocabularyVM = vm
        return vm
    }())
```

- [ ] **Step 3: Run tests and verify tab switching behavior**
Run: `swift test`

- [ ] **Step 4: Commit changes**
```bash
git add VocabCraftApp/Features/Homepage/Views/HomepageView.swift
git commit -m "fix(ui): preserve child view models and view state across tab navigation"
```

---

### Task 8: End-to-End Verification & Benchmark Check

- [ ] **Step 1: Run full test suite**
Run: `swift test`

- [ ] **Step 2: Verify build across all targets**
Run: `swift build`

- [ ] **Step 3: Final sanity check on Git status and documentation**
Ensure all files are formatted and committed cleanly.
