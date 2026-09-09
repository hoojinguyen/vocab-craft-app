# Package 3: Runtime Performance & Resource Lifecycle Design Spec

**Date:** 2026-09-09  
**Status:** Approved by User  
**Scope:** Package 3 of Architecture & Performance Audit (Finding 5, Finding 6, Finding 8)

---

## 1. Executive Summary & Goals

Package 3 targets runtime performance bottlenecks, redundant database I/O, excessive SwiftUI re-render invalidations, and unbounded concurrency in data loading:

1. **Consolidated Personal Vault Loading Pipeline (Finding 5)**:
   - Eliminate duplicate progress and word lookup queries in `PersonalVaultViewModel` by providing a unified `fetchVaultSnapshot` API.
   - Implement generation-based request tracking to prevent race conditions during rapid search and filter changes.
   - Introduce optimistic local state updates for word bookmarking, eliminating full-screen reloads on every bookmark tap.
2. **Discrete Milestone-Driven Timer for Mixed Reflex (Finding 6)**:
   - Eliminate the 30ms (~33 Hz) polling loop modifying `@Observable` view model state and root view body.
   - Delegate continuous smooth countdown rendering to the leaf `CraftCountdownTimerBar` component (backed by `TimelineView`).
   - Transition root screen state only at discrete time milestones (warning threshold, urgent threshold, hint stages, timeout).
   - Enforce immediate cancellation guards after every `Task.sleep` to prevent zombie tasks from overwriting state.
3. **Static Curriculum Caching & Controlled Concurrency for Learning Path (Finding 8)**:
   - Implement in-memory caching of static curriculum data (topic decks, stages, and words) in `FetchLearningPathUseCase`.
   - Retain fast, lightweight dynamic fetching of user stage progress on Home refreshes without re-fetching immutable catalog entries.
   - Provide a `forceRefresh` capability and bound TaskGroup concurrency.

---

## 2. Architecture & Detailed Design

```mermaid
flowchart TD
    subgraph PersonalVault["Subsystem 1: Personal Vault Pipeline"]
        PVVM["PersonalVaultViewModel\n(currentRequestId: UInt64)"] -->|1 single call| UVS["FetchPersonalVaultUseCase\n.fetchVaultSnapshot()"]
        UVS -->|1x fetch| PR["UserProgressRepository"]
        UVS -->|1x fetch by IDs| DS["VocabularyDataSource"]
        UVS -->|Returns| Snap["PersonalVaultSnapshot\n(metrics + personalWords + vaultWords)"]
        Snap -->|Guard requestId == current| PVVM
        PVVM -. "Bookmark Tap" .-> Opt["Optimistic in-memory toggle\n+ Background async persist\n(Rollback on error)"]
    end

    subgraph MixedReflex["Subsystem 2: Mixed Reflex Timer"]
        MRView["MixedReflexDrillView"] -->|wordStartTime = Date()| LeafBar["ReflexHeaderBarView -> CraftCountdownTimerBar\n(Leaf TimelineView render)"]
        MRView -->|Schedule Milestone Tasks| Milestones["Sequential Milestone Sleeper\n- Sleep to Warning (60%) -> .warning\n- Sleep to Urgent (80%) -> .urgent\n- Sleep to Timeout -> handleTimeout()"]
        MRView -. "User Action" .-> ExactMs["responseTimeMs = Int(Date().timeIntervalSince(start) * 1000)\nCancel timer task"]
    end

    subgraph LearningPath["Subsystem 3: Static Curriculum Cache"]
        HomeVM["HomepageViewModel"] --> FLPUC["FetchLearningPathUseCase"]
        FLPUC --> Cache{"Static Cache\nPopulated?"}
        Cache -- "No / forceRefresh" --> LoadAll["Load Decks, Stages, Words\n(Bounded TaskGroup)"]
        LoadAll --> StoreCache["Store into in-memory cache"]
        StoreCache --> LoadProg["Fetch UserStageProgressData"]
        Cache -- "Yes" --> LoadProg
        LoadProg --> Assembly["Assemble LearningPathCurriculum"]
    end
```

---

### Subsystem 1: Personal Vault Loading Pipeline & Optimistic Updates

#### 1.1 Snapshot Model & Use Case Protocol
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

#### 1.2 Unified Single-Pass Implementation
`FetchPersonalVaultUseCase.fetchVaultSnapshot`:
- Fetches all user progress once: `progressRepo.fetchAllProgress()`.
- Extracts unique word IDs: `Set(allProgress.map(\.wordId))`.
- Fetches words by IDs once: `dataSource.fetchWordsByIds(ids: wordIds)`.
- Builds dictionary index: `wordsMap = Dictionary(wordsList.map { ($0.id, $0) }, ...)`.
- Maps into both `PersonalWord` and `VaultWordItem` arrays in a single iteration.
- Computes `PersonalVaultMetrics` from the combined data.
- Applies `personalFilter`, `vaultFilter`, and `searchQuery` filtering.
- Returns `PersonalVaultSnapshot`.

#### 1.3 View Model Generation Tracking & Optimistic Bookmark
In `PersonalVaultViewModel.swift`:
```swift
private var currentRequestId: UInt64 = 0

public func loadData() async {
    currentRequestId &+= 1
    let requestId = currentRequestId
    isLoading = true
    errorMessage = nil

    do {
        let snapshot = try await fetchVaultUseCase.fetchVaultSnapshot(
            personalFilter: selectedFilter,
            vaultFilter: vaultTabFilter,
            searchQuery: searchQuery
        )
        guard currentRequestId == requestId && !Task.isCancelled else { return }
        self.metrics = snapshot.metrics
        self.words = snapshot.personalWords
        self.vaultWords = snapshot.vaultWords
    } catch {
        guard currentRequestId == requestId && !Task.isCancelled else { return }
        self.errorMessage = error.localizedDescription
    }
    guard currentRequestId == requestId && !Task.isCancelled else { return }
    self.isLoading = false
}

public func toggleBookmark(wordId: Int64) async {
    // 1. Optimistic local update
    guard let index = vaultWords.firstIndex(where: { $0.id == wordId }) else { return }
    let previousState = vaultWords[index].isBookmarked
    let newState = !previousState
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

    // 2. Persist in background
    if let toggleBookmarkUseCase {
        do {
            _ = try await toggleBookmarkUseCase.execute(wordId: wordId)
        } catch {
            // Rollback on failure
            if let rollbackIndex = vaultWords.firstIndex(where: { $0.id == wordId }) {
                vaultWords[rollbackIndex].isBookmarked = previousState
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

---

### Subsystem 2: Mixed Reflex Discrete Milestone Timer

#### 2.1 Problem Analysis
In `MixedReflexDrillView.swift`, `startTimer` executes:
```swift
while !Task.isCancelled {
    try? await Task.sleep(for: .milliseconds(30))
    self.elapsedTimeMs = Int(elapsed * 1000)
    self.fractionRemaining = remaining
}
```
Every 30ms, two state writes trigger full view body re-evaluation.

#### 2.2 Discrete Milestone Engine
1. **Leaf Countdown Rendering**:
   `ReflexHeaderBarView` receives:
   - `startDate: wordStartTime`
   - `timeLimitSeconds: item.assignedMode.timeLimitSeconds`
   - `isTimerActive: cardPhase == .activeCountdown`
   The internal `CraftCountdownTimerBar` renders continuous progress using its dedicated leaf `TimelineView`, completely decoupled from the root view body.

2. **Sequential Milestone Task**:
   Replace the polling loop with discrete milestone delays:
   ```swift
   private func startTimer(for item: MixedReflexDrillItem) {
       timerTask?.cancel()
       let timeLimit = item.assignedMode.timeLimitSeconds
       let warningDelay = timeLimit * 0.60
       let urgentDelay = timeLimit * 0.80

       timerTask = Task { @MainActor in
           // 1. Wait until warning milestone
           try? await Task.sleep(for: .seconds(warningDelay))
           guard !Task.isCancelled else { return }
           self.timerStage = .warning

           // 2. Wait until urgent milestone
           let remainingToUrgent = urgentDelay - warningDelay
           try? await Task.sleep(for: .seconds(remainingToUrgent))
           guard !Task.isCancelled else { return }
           self.timerStage = .urgent

           // 3. Wait until timeout
           let remainingToTimeout = timeLimit - urgentDelay
           try? await Task.sleep(for: .seconds(remainingToTimeout))
           guard !Task.isCancelled else { return }
           self.handleTimeout()
       }
   }
   ```

3. **Accurate Response Time Calculation**:
   On user interaction (option tap, typing submission, speech result):
   ```swift
   let responseTimeMs = wordStartTime.map { Int(Date().timeIntervalSince($0) * 1000) } ?? 500
   timerTask?.cancel()
   ```
   Zero reliance on 30ms polling state.

4. **Hint Milestone Triggers**:
   Mode-specific hints (e.g. listening/speaking mode audio prompts at 2.5s / 4.0s / 5.0s) are triggered via scheduled milestone timers rather than checking elapsed ms on every frame.

---

### Subsystem 3: Learning Path Static Curriculum Cache

#### 3.1 Caching Architecture
In `FetchLearningPathUseCase.swift`:
```swift
public final class FetchLearningPathUseCase: FetchLearningPathUseCaseProtocol, Sendable {
    private let dataSource: VocabularyDataSourceProtocol
    private let stageRepo: StageProgressRepositoryProtocol
    private let curriculumCache = StaticCurriculumCache()

    public func execute(forceRefresh: Bool = false) async throws -> LearningPathCurriculum {
        let staticData: StaticCurriculumData
        if !forceRefresh, let cached = await curriculumCache.get() {
            staticData = cached
        } else {
            staticData = try await loadStaticCurriculum()
            await curriculumCache.set(staticData)
        }

        let progressList = try await stageRepo.fetchAllStageProgress()
        return LearningPathCurriculum(
            decks: staticData.decks,
            stages: staticData.stages,
            words: staticData.words,
            progressList: progressList
        )
    }
}
```

#### 3.2 Bounded Concurrency
During `loadStaticCurriculum()`:
- Use structured concurrency with bounded batching or sequential deck stage reads so that large future datasets don't explode thread pools.

---

## 3. Global Constraints & Verification Plan

### Global Constraints
- Target iOS 17+, Swift 5 (Swift 6 strict concurrency compatible with Sendable models).
- Zero Hardcoded Strings: all display strings use `Localizable.xcstrings` (100% EN/VI parity).
- CraftUIKit-First: design tokens and components only, zero raw styling.
- Strict Quality Gate: 0 compiler warnings, 0 SwiftLint violations, 100% test pass rate.

### Verification Plan
1. **Unit Tests**:
   - `PersonalVaultViewModelTests`: Verify single-call snapshot loading, generation cancellation, and optimistic bookmark toggling with error rollback.
   - `FetchPersonalVaultUseCaseTests`: Verify `fetchVaultSnapshot` returns identical data and metrics with single-pass reads.
   - `MixedReflexDrillViewsTests`: Verify milestone stage transitions, immediate cancellation safety, and accurate response time calculation without polling loops.
   - `FetchLearningPathUseCaseTests`: Verify static curriculum cache reuse across multiple calls and `forceRefresh` invalidation.
2. **Integration & Quality Gates**:
   - `swift test` (all suites pass 100%).
   - `swift test --package-path Packages/CraftUIKit` (100% pass).
   - `swiftlint lint --quiet --no-cache` (0 violations).
   - Xcode Simulator build & test (`xcodebuild`).
