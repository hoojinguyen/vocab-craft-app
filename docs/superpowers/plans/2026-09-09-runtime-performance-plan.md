# Package 3: Runtime Performance & Resource Lifecycle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate redundant database I/O in Personal Vault, stop excessive 33 Hz re-renders in Mixed Reflex Drill, and cache static curriculum data in Learning Path.

**Architecture:** A single-pass `fetchVaultSnapshot` with generation tracking and optimistic updates replaces duplicate queries in `PersonalVaultViewModel`; a discrete milestone-driven timer replaces the 30ms polling loop in `MixedReflexDrillView`; and an in-memory cache in `FetchLearningPathUseCase` avoids redundant catalog re-fetching on Home reloads.

**Tech Stack:** Swift 5 (Swift 6 compatible), SwiftData, SwiftUI, CraftUIKit, XCTest / Swift Testing.

**Spec:** `docs/superpowers/specs/2026-09-09-runtime-performance-design.md`

## Global Constraints
- Target iOS 17+, Swift 5 language mode compatible with Swift 6 strict concurrency.
- Zero Hardcoded Strings: all display strings must use `Localizable.xcstrings` (100% EN/VI bilingual parity).
- CraftUIKit-First: design tokens and components only, zero raw styling.
- Strict Quality Gate: 0 compiler warnings, 0 SwiftLint violations, 100% test pass rate.

---

### Task 1: Personal Vault Single-Pass Snapshot & Generation Tracking

**Files:**
- Modify: `VocabCraftApp/Domain/UseCases/FetchPersonalVaultUseCase.swift:50-160`
- Modify: `VocabCraftApp/Features/Vocabulary/PersonalVault/ViewModels/PersonalVaultViewModel.swift:50-85`
- Test: `VocabCraftAppTests/Domain/VocabularyUseCasesTests.swift`
- Test: `VocabCraftAppTests/Features/PersonalVaultViewModelTests.swift`

**Interfaces:**
- Consumes: `PersonalVaultFilter`, `VaultTabFilter`, `UserProgressRepositoryProtocol`, `VocabularyDataSourceProtocol`.
- Produces: `PersonalVaultSnapshot` struct, `FetchPersonalVaultUseCaseProtocol.fetchVaultSnapshot(...)`, generation-guarded `loadData()` in `PersonalVaultViewModel`.

- [ ] **Step 1: Define PersonalVaultSnapshot and protocol extension in FetchPersonalVaultUseCase.swift**

In `VocabCraftApp/Domain/UseCases/FetchPersonalVaultUseCase.swift`:
```swift
public struct PersonalVaultSnapshot: Sendable, Equatable {
    public let metrics: PersonalVaultMetrics
    public let personalWords: [PersonalWord]
    public let vaultWords: [VaultWordItem]

    public init(
        metrics: PersonalVaultMetrics,
        personalWords: [PersonalWord],
        vaultWords: [VaultWordItem]
    ) {
        self.metrics = metrics
        self.personalWords = personalWords
        self.vaultWords = vaultWords
    }
}

public protocol FetchPersonalVaultUseCaseProtocol: Sendable {
    func execute(filter: PersonalVaultFilter, searchQuery: String?) async throws -> PersonalVaultResult
    func fetchVaultWords(filter: VaultTabFilter, searchQuery: String?) async throws -> [VaultWordItem]
    func fetchVaultSnapshot(
        personalFilter: PersonalVaultFilter,
        vaultFilter: VaultTabFilter,
        searchQuery: String?
    ) async throws -> PersonalVaultSnapshot
}
```

- [ ] **Step 2: Implement single-pass fetchVaultSnapshot in FetchPersonalVaultUseCase**

Implement `fetchVaultSnapshot`:
```swift
public func fetchVaultSnapshot(
    personalFilter: PersonalVaultFilter = .all,
    vaultFilter: VaultTabFilter = .notMastered,
    searchQuery: String? = nil
) async throws -> PersonalVaultSnapshot {
    let allProgress = try await progressRepo.fetchAllProgress()
    let wordIds = Set(allProgress.map(\.wordId))
    let wordsList = try await dataSource.fetchWordsByIds(ids: wordIds)
    let wordsMap = Dictionary(wordsList.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

    var allPersonalWords: [PersonalWord] = []
    var allVaultWords: [VaultWordItem] = []
    allPersonalWords.reserveCapacity(allProgress.count)
    allVaultWords.reserveCapacity(allProgress.count)

    for progress in allProgress {
        guard let wordDTO = wordsMap[progress.wordId] else { continue }

        let personalWord = PersonalWord(
            id: wordDTO.id,
            lemma: wordDTO.lemma,
            phonetic: wordDTO.phonetic,
            pos: wordDTO.pos,
            cefrLevel: wordDTO.cefrLevel,
            definitionVi: wordDTO.definitionVi,
            definitionEn: wordDTO.definitionEn,
            exampleEn: wordDTO.exampleEn,
            exampleVi: wordDTO.exampleVi,
            masteryLevel: progress.masteryLevel,
            isBookmarked: progress.isBookmarked,
            needsReview: progress.needsReview,
            mistakeCount: progress.mistakeCount,
            sourceDeckTitle: nil,
            sourceStageTitle: nil
        )
        allPersonalWords.append(personalWord)

        let isMastered = progress.isMastered || progress.masteryLevel >= 4
        let vaultWord = VaultWordItem(
            id: wordDTO.id,
            lemma: wordDTO.lemma,
            pos: wordDTO.pos,
            phonetic: wordDTO.phonetic,
            definitionVi: wordDTO.definitionVi,
            exampleSentenceEn: wordDTO.exampleEn,
            exampleSentenceVi: wordDTO.exampleVi,
            cefrLevel: wordDTO.cefrLevel,
            isMastered: isMastered,
            isBookmarked: progress.isBookmarked,
            correctStreak: progress.consecutiveCorrectStreak,
            practicedModes: progress.practicedModes,
            lastPracticedAt: progress.lastReviewDate,
            nextReviewAt: progress.nextReviewDate,
            scheduledBucket: progress.scheduledBucket
        )
        allVaultWords.append(vaultWord)
    }

    let total = allPersonalWords.count
    let mastered = allPersonalWords.filter { $0.masteryLevel >= 4 }.count
    let bookmarked = allPersonalWords.filter(\.isBookmarked).count
    let needsReview = allPersonalWords.filter(\.needsReview).count
    let unmastered = max(0, total - mastered)

    let metrics = PersonalVaultMetrics(
        totalWords: total,
        needsReviewCount: needsReview,
        masteredCount: mastered,
        bookmarkedCount: bookmarked,
        unmasteredCount: unmastered
    )

    // Filter personalWords
    var filteredPersonal: [PersonalWord]
    switch personalFilter {
    case .all: filteredPersonal = allPersonalWords
    case .needsReview: filteredPersonal = allPersonalWords.filter(\.needsReview)
    case .mastered: filteredPersonal = allPersonalWords.filter { $0.masteryLevel >= 4 }
    case .bookmarked: filteredPersonal = allPersonalWords.filter(\.isBookmarked)
    }

    // Filter vaultWords
    var filteredVault: [VaultWordItem]
    switch vaultFilter {
    case .notMastered: filteredVault = allVaultWords.filter { !$0.isMastered }
    case .mastered: filteredVault = allVaultWords.filter(\.isMastered)
    case .bookmarked: filteredVault = allVaultWords.filter(\.isBookmarked)
    }

    if let query = searchQuery?.trimmingCharacters(in: .whitespacesAndNewlines), !query.isEmpty {
        let lowerQuery = query.lowercased()
        filteredPersonal = filteredPersonal.filter { word in
            word.lemma.lowercased().contains(lowerQuery) ||
            word.definitionVi.lowercased().contains(lowerQuery) ||
            word.definitionEn.lowercased().contains(lowerQuery) ||
            word.phonetic.lowercased().contains(lowerQuery)
        }
        filteredVault = filteredVault.filter { word in
            word.lemma.lowercased().contains(lowerQuery) ||
            word.definitionVi.lowercased().contains(lowerQuery) ||
            word.phonetic.lowercased().contains(lowerQuery)
        }
    }

    return PersonalVaultSnapshot(
        metrics: metrics,
        personalWords: filteredPersonal,
        vaultWords: filteredVault
    )
}
```

- [ ] **Step 3: Update PersonalVaultViewModel loadData and generation tracking**

In `VocabCraftApp/Features/Vocabulary/PersonalVault/ViewModels/PersonalVaultViewModel.swift`:
Add property:
```swift
private var currentRequestId: UInt64 = 0
```
Update `loadData()`:
```swift
public func loadData() async {
    currentRequestId &+= 1
    let requestId = currentRequestId
    isLoading = true
    errorMessage = nil

    let effectiveQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : searchQuery
    do {
        let snapshot = try await fetchVaultUseCase.fetchVaultSnapshot(
            personalFilter: selectedFilter,
            vaultFilter: vaultTabFilter,
            searchQuery: effectiveQuery
        )
        guard currentRequestId == requestId && !Task.isCancelled else { return }
        words = snapshot.personalWords
        metrics = snapshot.metrics
        vaultWords = snapshot.vaultWords
    } catch {
        guard currentRequestId == requestId && !Task.isCancelled else { return }
        errorMessage = error.localizedDescription
    }
    guard currentRequestId == requestId && !Task.isCancelled else { return }
    isLoading = false
}
```

- [ ] **Step 4: Update test suites and verify**

Update mocks and tests in:
- `VocabCraftAppTests/Domain/VocabularyUseCasesTests.swift`
- `VocabCraftAppTests/Features/PersonalVaultViewModelTests.swift`
Run: `swift test --filter PersonalVault`
Expected: PASS (100%).

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Domain/UseCases/FetchPersonalVaultUseCase.swift VocabCraftApp/Features/Vocabulary/PersonalVault/ViewModels/PersonalVaultViewModel.swift VocabCraftAppTests/
git commit -m "perf(vault): consolidate fetchVaultSnapshot into single-pass query with generation tracking"
```

---

### Task 2: Optimistic Bookmark Toggling & Rollback Safety in Personal Vault

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/PersonalVault/ViewModels/PersonalVaultViewModel.swift:165-200`
- Test: `VocabCraftAppTests/Features/PersonalVaultViewModelTests.swift`

**Interfaces:**
- Consumes: `PersonalVaultViewModel`, `ToggleBookmarkUseCaseProtocol`.
- Produces: Instant in-memory state toggle and metrics update with background sync and rollback on error.

- [ ] **Step 1: Write unit tests for optimistic bookmark update and error rollback**

In `VocabCraftAppTests/Features/PersonalVaultViewModelTests.swift`:
- Add test verifying `toggleBookmark(wordId:)` updates `vaultWords` and `metrics.bookmarkedCount` synchronously before async persistence completes.
- Add test verifying `toggleBookmark(wordId:)` rolls back to initial state if `toggleBookmarkUseCase` throws an error.

- [ ] **Step 2: Implement optimistic toggleBookmark with rollback in PersonalVaultViewModel**

In `PersonalVaultViewModel.swift`:
```swift
public func toggleBookmark(wordId: Int64) async {
    guard let index = vaultWords.firstIndex(where: { $0.id == wordId }) else { return }
    let previousState = vaultWords[index].isBookmarked
    let newState = !previousState

    // 1. Optimistic in-memory update
    vaultWords[index].isBookmarked = newState
    if var currentMetrics = metrics {
        let delta = newState ? 1 : -1
        currentMetrics = PersonalVaultMetrics(
            totalWords: currentMetrics.totalWords,
            needsReviewCount: currentMetrics.needsReviewCount,
            masteredCount: currentMetrics.masteredCount,
            bookmarkedCount: max(0, currentMetrics.bookmarkedCount + delta),
            unmasteredCount: currentMetrics.unmasteredCount
        )
        self.metrics = currentMetrics
    }

    // Also update words array if present
    if let personalIndex = words.firstIndex(where: { $0.id == wordId }) {
        words[personalIndex].isBookmarked = newState
    }

    // 2. Persist in background
    if let toggleBookmarkUseCase {
        do {
            _ = try await toggleBookmarkUseCase.execute(wordId: wordId)
        } catch {
            // Rollback on error
            if let rollbackIndex = vaultWords.firstIndex(where: { $0.id == wordId }) {
                vaultWords[rollbackIndex].isBookmarked = previousState
            }
            if let rollbackPersonal = words.firstIndex(where: { $0.id == wordId }) {
                words[rollbackPersonal].isBookmarked = previousState
            }
            if var currentMetrics = metrics {
                let revertDelta = previousState ? 1 : -1
                self.metrics = PersonalVaultMetrics(
                    totalWords: currentMetrics.totalWords,
                    needsReviewCount: currentMetrics.needsReviewCount,
                    masteredCount: currentMetrics.masteredCount,
                    bookmarkedCount: max(0, currentMetrics.bookmarkedCount + revertDelta),
                    unmasteredCount: currentMetrics.unmasteredCount
                )
            }
            errorMessage = error.localizedDescription
        }
    }
}
```

- [ ] **Step 3: Run tests and verify**

Run: `swift test --filter PersonalVaultViewModelTests`
Expected: PASS (100%).

- [ ] **Step 4: Commit changes**

```bash
git add VocabCraftApp/Features/Vocabulary/PersonalVault/ViewModels/PersonalVaultViewModel.swift VocabCraftAppTests/Features/PersonalVaultViewModelTests.swift
git commit -m "feat(vault): implement optimistic bookmark toggle with error rollback"
```

---

### Task 3: Mixed Reflex Discrete Milestone Engine & Elimination of 30ms Polling Loop

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Mixed/Views/MixedReflexDrillView.swift:465-495`
- Modify: `VocabCraftApp/Features/Reflex/Mixed/ViewModels/MixedReflexDrillViewModel.swift`
- Test: `VocabCraftAppTests/Features/MixedReflexDrillViewsTests.swift`
- Test: `VocabCraftAppTests/Features/MixedReflexDrillViewModelTests.swift`

**Interfaces:**
- Consumes: `MixedReflexDrillItem`, `ReflexHeaderBarView`.
- Produces: Smooth leaf countdown via `CraftCountdownTimerBar`, discrete milestone state updates without 33 Hz polling.

- [ ] **Step 1: Refactor startTimer in MixedReflexDrillView to use discrete milestones**

In `MixedReflexDrillView.swift`:
Replace polling loop in `startTimer(for item: MixedReflexDrillItem)` with sequential milestone delays:
```swift
private func startTimer(for item: MixedReflexDrillItem) {
    timerTask?.cancel()
    let timeLimit = item.assignedMode.timeLimitSeconds
    let warningDelay = timeLimit * 0.60
    let urgentDelay = timeLimit * 0.80

    timerTask = Task { @MainActor in
        // Milestone 1: Warning threshold (60%)
        try? await Task.sleep(for: .seconds(warningDelay))
        guard !Task.isCancelled else { return }
        self.timerStage = .warning

        // Milestone 2: Urgent threshold (80%)
        let delayToUrgent = urgentDelay - warningDelay
        try? await Task.sleep(for: .seconds(delayToUrgent))
        guard !Task.isCancelled else { return }
        self.timerStage = .urgent

        // Milestone 3: Timeout
        let delayToTimeout = timeLimit - urgentDelay
        try? await Task.sleep(for: .seconds(delayToTimeout))
        guard !Task.isCancelled else { return }
        self.handleTimeout()
    }
}
```

- [ ] **Step 2: Calculate accurate responseTimeMs using wordStartTime on answer submission**

In `selectOption`, `submitTypingAnswer`, and `handleSpeechResult`:
Calculate `responseTimeMs`:
```swift
let elapsedMs = wordStartTime.map { Int(Date().timeIntervalSince($0) * 1000) } ?? 500
let responseTimeMs = max(500, elapsedMs)
timerTask?.cancel()
```
Remove `self.elapsedTimeMs = Int(elapsed * 1000)` and `self.fractionRemaining = remaining` from 30ms timer.

- [ ] **Step 3: Run existing Reflex test suite and verify**

Run: `swift test --filter MixedReflex`
Run: `swift test --filter Reflex`
Expected: PASS (100%).

- [ ] **Step 4: Commit changes**

```bash
git add VocabCraftApp/Features/Reflex/Mixed/ VocabCraftAppTests/Features/
git commit -m "perf(reflex): replace 30ms polling loop with discrete milestone timer and leaf countdown"
```

---

### Task 4: Learning Path Static Curriculum Cache & Controlled Concurrency

**Files:**
- Modify: `VocabCraftApp/Domain/UseCases/FetchLearningPathUseCase.swift`
- Test: `VocabCraftAppTests/Domain/LearningPathUseCasesTests.swift`

**Interfaces:**
- Consumes: `VocabularyDataSourceProtocol`, `StageProgressRepositoryProtocol`.
- Produces: In-memory cached static curriculum (`decks`, `stages`, `words`) with fast progress overlay.

- [ ] **Step 1: Write failing test verifying curriculum cache avoids redundant data source calls**

In `VocabCraftAppTests/Domain/LearningPathUseCasesTests.swift`:
Add test calling `execute()` twice on `FetchLearningPathUseCase`, asserting `mockDataSource.fetchTopicDecksCallCount == 1`.
Add test calling `execute(forceRefresh: true)`, asserting call count increments to 2.

- [ ] **Step 2: Implement StaticCurriculumCache in FetchLearningPathUseCase.swift**

In `VocabCraftApp/Domain/UseCases/FetchLearningPathUseCase.swift`:
```swift
private struct StaticCurriculumData: Sendable {
    let decks: [TopicDeckDTO]
    let stages: [SubTopicStageDTO]
    let words: [TopicWordDTO]
}

private actor StaticCurriculumCache {
    private var data: StaticCurriculumData?

    func get() -> StaticCurriculumData? {
        data
    }

    func set(_ newData: StaticCurriculumData) {
        data = newData
    }

    func clear() {
        data = nil
    }
}
```

Update `FetchLearningPathUseCaseProtocol`:
```swift
public protocol FetchLearningPathUseCaseProtocol: Sendable {
    func execute() async throws -> LearningPathCurriculum
    func execute(forceRefresh: Bool) async throws -> LearningPathCurriculum
}

public extension FetchLearningPathUseCaseProtocol {
    func execute() async throws -> LearningPathCurriculum {
        try await execute(forceRefresh: false)
    }
}
```

Implement in `FetchLearningPathUseCase`:
```swift
private let curriculumCache = StaticCurriculumCache()

public func execute(forceRefresh: Bool = false) async throws -> LearningPathCurriculum {
    let staticData: StaticCurriculumData
    if !forceRefresh, let cached = await curriculumCache.get() {
        staticData = cached
    } else {
        let loaded = try await loadStaticCurriculum()
        await curriculumCache.set(loaded)
        staticData = loaded
    }

    let progressList = try await stageRepo.fetchAllStageProgress()
    return LearningPathCurriculum(
        decks: staticData.decks,
        stages: staticData.stages,
        words: staticData.words,
        progressList: progressList
    )
}
```

- [ ] **Step 3: Run test suite and verify**

Run: `swift test --filter LearningPath`
Run: `swift test --filter Homepage`
Expected: PASS (100%).

- [ ] **Step 4: Commit changes**

```bash
git add VocabCraftApp/Domain/UseCases/FetchLearningPathUseCase.swift VocabCraftAppTests/Domain/LearningPathUseCasesTests.swift
git commit -m "perf(learning-path): implement in-memory static curriculum cache with forceRefresh support"
```

---

### Task 5: End-to-End Verification & Whole-Package Review

**Files:**
- Verification only

- [ ] **Step 1: Run Root SPM test suite**

Run: `swift test`
Expected: 100% test cases pass.

- [ ] **Step 2: Run CraftUIKit test suite**

Run: `swift test --package-path Packages/CraftUIKit`
Expected: 100% test cases pass.

- [ ] **Step 3: Run SwiftLint**

Run: `swiftlint lint --quiet --no-cache`
Expected: 0 warnings, 0 errors.

- [ ] **Step 4: Build on Xcode Simulator**

Run: `xcodebuild build-for-testing -scheme VocabCraftAppTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet`
Expected: 0 errors, 0 warnings.

- [ ] **Step 5: Whole-Package Code Review**

Dispatch independent whole-package reviewer to verify performance optimizations, resource hygiene, and concurrency safety.
