# YouTube Shadowing Studio (Production Grade) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the single-video Shadowing demo into a production-grade 3-round speech training system (Immersion, Speed Shadowing, Echo Drilling & SRS bookmarking) with a dedicated video discovery Hub and bundled SQLite catalog.

**Architecture:** Unidirectional MVVM with Observation (`@Observable`). `ShadowingHubView` queries `ShadowingCatalogRepository` (bundled SQLite) and `ShadowingProgressRepository` (local progress store). Selecting a video boots `ShadowingStudioContainerView` powered by `ShadowingStudioViewModel`, orchestrating transitions between Round 1 (Immersion), Round 2 (Simultaneous Shadowing with Karaoke Teleprompter), Round 3 (Echo Shadowing with `SpeechKit` & `CraftVoiceMatchCard`), and `ShadowingSummaryReportView`.

**Tech Stack:** Swift 6, SwiftUI, Observation, SQLite3 (C-API / sqlite3 wrapper), `SpeechKit`, `CraftUIKit` design tokens, `AVFoundation` route detection.

**Spec:** `docs/superpowers/specs/2026-10-22-youtube-shadowing-production-design.md`

## Global Constraints

- **Zero Raw Styling:** Strictly use `CraftUIKit` design tokens (`theme.colors.*`, `theme.typography.*`, `theme.spacing.*`, `theme.radius.*`).
- **Zero Hardcoded Strings:** All text and accessibility labels must reside in `Localizable.xcstrings` with 100% bilingual parity (EN & VI).
- **Swift Concurrency:** All ViewModels are `@MainActor`, data operations are `async throws Sendable`.
- **Quality Gate:** Zero build errors, zero compiler warnings, zero SwiftLint violations.

## Review Focus

1. **Missing or Corrupted SQLite database in Bundle:** App must fall back gracefully to empty state without crashing if `ShadowingCatalog.sqlite` is missing or unreadable.
2. **Headphone disconnect/reconnect mid-session:** Round 2 audio recording must cleanly handle route changes without throwing fatal unhandled errors.
3. **Zero-length or single-word sentences in Teleprompter:** Teleprompter word highlight index must never produce out-of-bounds index exceptions during rapid seeks.
4. **Keyword bookmarking for unlinked dictionary words:** Tapping bookmark on a keyword lacking a dictionary `linked_word_id` must save to local favorites without throwing an invalid foreign key exception.
5. **Video playback error in WKWebView:** If YouTube iframe fails or is blocked, the studio container must show an actionable retry / error state rather than a blank black box.

---

### Task 1: SQLite Catalog Engine & Domain Models

**Files:**
- Create: `VocabCraftApp/Domain/Models/Shadowing/ShadowingWordTimestamp.swift`
- Modify: `VocabCraftApp/Domain/Models/Shadowing/ShadowingVideoModels.swift`
- Create: `VocabCraftApp/Data/DataSources/ShadowingSQLiteDatabase.swift`
- Create: `VocabCraftApp/Domain/Protocols/ShadowingCatalogRepositoryProtocol.swift`
- Create: `VocabCraftApp/Data/Repositories/ShadowingCatalogRepository.swift`
- Create: `VocabCraftApp/Resources/ShadowingCatalog.sqlite`
- Test: `VocabCraftAppTests/Data/ShadowingCatalogRepositoryTests.swift`

**Interfaces:**
- Consumes: None (Root catalog data access).
- Produces:
  - `struct ShadowingWordTimestamp: Sendable, Codable, Equatable { let word: String; let start: Double; let end: Double }`
  - `protocol ShadowingCatalogRepositoryProtocol: Sendable { func fetchTopics() async throws -> [ShadowingTopicItem]; func fetchVideos(topicId: String?, level: String?) async throws -> [ShadowingVideo]; func fetchVideo(byId id: String) async throws -> ShadowingVideo? }`
  - `ShadowingCatalogRepository: ShadowingCatalogRepositoryProtocol`

- [ ] **Step 1: Write failing unit test for `ShadowingCatalogRepository`**

```swift
// VocabCraftAppTests/Data/ShadowingCatalogRepositoryTests.swift
import Testing
@testable import VocabCraftApp

struct ShadowingCatalogRepositoryTests {
    @Test func testFetchTopicsAndVideosFromSQLite() async throws {
        let repo = try ShadowingCatalogRepository(bundle: .main)
        let topics = try await repo.fetchTopics()
        #expect(!topics.isEmpty)
        let videos = try await repo.fetchVideos(topicId: nil, level: nil)
        #expect(!videos.isEmpty)
        let first = try #require(videos.first)
        #expect(!first.sentences.isEmpty)
        #expect(first.sentences[0].words.count >= 0)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/ShadowingCatalogRepositoryTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: FAIL with compilation error (missing `ShadowingCatalogRepository`).

- [ ] **Step 3: Create `ShadowingWordTimestamp` and update `ShadowingVideoModels.swift`**

Add `words: [ShadowingWordTimestamp] = []` to `ShadowingSentence`. Add `accent: String` and `thumbnailUrl: String?` to `ShadowingVideo`.

- [ ] **Step 4: Implement `ShadowingSQLiteDatabase` and `ShadowingCatalogRepository`**

Use SQLite3 C-APIs to open `ShadowingCatalog.sqlite` in read-only mode, executing parameterized queries for `topics`, `videos`, `sentences`, and `sentence_keywords`. Parse `words_json` into `[ShadowingWordTimestamp]`.

- [ ] **Step 5: Generate bundled seed `ShadowingCatalog.sqlite` with 5 curated video lessons**

Include topics `dailyLife`, `moviesAndSeries`, `businessEnglish`, `techAndScience`, with video lessons for A1, A2, and B1.

- [ ] **Step 6: Run test to verify it passes**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/ShadowingCatalogRepositoryTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add VocabCraftApp/Domain/Models/Shadowing/ VocabCraftApp/Data/ VocabCraftApp/Resources/ShadowingCatalog.sqlite VocabCraftAppTests/Data/
git commit -m "feat(shadowing): implement SQLite catalog database and repository with seed data"
```

---

### Task 2: Local Progress & Mastery Persistence

**Files:**
- Create: `VocabCraftApp/Domain/Models/Shadowing/ShadowingProgressRecord.swift`
- Create: `VocabCraftApp/Domain/Protocols/ShadowingProgressRepositoryProtocol.swift`
- Create: `VocabCraftApp/Data/Repositories/ShadowingProgressRepositoryImpl.swift`
- Test: `VocabCraftAppTests/Data/ShadowingProgressRepositoryTests.swift`

**Interfaces:**
- Consumes: None.
- Produces:
  - `struct ShadowingProgressRecord: Codable, Sendable, Identifiable { let videoId: String; var bestScore: Double; var lastCompletedAt: Date; var timesCompleted: Int; var sentenceScores: [String: Double] }`
  - `protocol ShadowingProgressRepositoryProtocol: Sendable { func getProgress(videoId: String) async -> ShadowingProgressRecord?; func recordCompletion(videoId: String, score: Double, sentenceScores: [String: Double]) async throws; func getAllProgress() async -> [String: ShadowingProgressRecord] }`

- [ ] **Step 1: Write failing test for `ShadowingProgressRepository`**

```swift
// VocabCraftAppTests/Data/ShadowingProgressRepositoryTests.swift
import Testing
@testable import VocabCraftApp

struct ShadowingProgressRepositoryTests {
    @Test func testRecordAndRetrieveProgress() async throws {
        let repo = ShadowingProgressRepositoryImpl(userDefaults: UserDefaults(suiteName: "test_shadowing")!)
        await repo.recordCompletion(videoId: "vid_01", score: 92.5, sentenceScores: ["s_1": 95.0, "s_2": 90.0])
        let record = await repo.getProgress(videoId: "vid_01")
        #expect(record?.bestScore == 92.5)
        #expect(record?.timesCompleted == 1)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/ShadowingProgressRepositoryTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: FAIL.

- [ ] **Step 3: Implement `ShadowingProgressRepositoryImpl`**

Persist `[String: ShadowingProgressRecord]` safely with concurrency locks using `UserDefaults` / JSON serialization.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/ShadowingProgressRepositoryTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/Models/Shadowing/ShadowingProgressRecord.swift VocabCraftApp/Domain/Protocols/ShadowingProgressRepositoryProtocol.swift VocabCraftApp/Data/Repositories/ShadowingProgressRepositoryImpl.swift VocabCraftAppTests/Data/ShadowingProgressRepositoryTests.swift
git commit -m "feat(shadowing): implement ShadowingProgressRepository for local score persistence"
```

---

### Task 3: Localization Keys & Bilingual Parity

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Test: `VocabCraftAppTests/Resources/LocalizationShadowingTests.swift`

**Interfaces:**
- Consumes: None.
- Produces: Fully translated strings for `app.shadowing.hub.*`, `app.shadowing.round1.*`, `app.shadowing.round2.*`, `app.shadowing.round3.*`, `app.shadowing.summary.*`.

- [ ] **Step 1: Write failing test verifying required Shadowing keys exist in EN & VI**

```swift
// VocabCraftAppTests/Resources/LocalizationShadowingTests.swift
import Testing
import Foundation

struct LocalizationShadowingTests {
    @Test func testShadowingKeysAreBilingual() throws {
        let url = Bundle.main.url(forResource: "Localizable", withExtension: "xcstrings")!
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let strings = json["strings"] as! [String: Any]
        
        let requiredKeys = [
            "app.shadowing.hub.title",
            "app.shadowing.hub.daily_challenge",
            "app.shadowing.round2.title",
            "app.shadowing.round2.pacer_hint",
            "app.shadowing.round2.rewind_5s",
            "app.shadowing.summary.title"
        ]
        for key in requiredKeys {
            let entry = try #require(strings[key] as? [String: Any], "Missing key: \(key)")
            let localizations = try #require(entry["localizations"] as? [String: Any])
            #expect(localizations["en"] != nil)
            #expect(localizations["vi"] != nil)
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/LocalizationShadowingTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: FAIL.

- [ ] **Step 3: Add all Shadowing keys from Section 6.2 of the spec to `Localizable.xcstrings`**

Ensure both English and Vietnamese translations are present with `state: "translated"`, `extractionState: "manual"`.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/LocalizationShadowingTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftAppTests/Resources/LocalizationShadowingTests.swift
git commit -m "feat(shadowing): add bilingual strings for Shadowing Studio Hub and 3-round flow"
```

---

### Task 4: Shadowing Studio Hub (`ShadowingHubViewModel` & `ShadowingHubView`)

**Files:**
- Create: `VocabCraftApp/Features/Shadowing/ViewModels/ShadowingHubViewModel.swift`
- Create: `VocabCraftApp/Features/Shadowing/Views/Components/DailyChallengeHeroCard.swift`
- Create: `VocabCraftApp/Features/Shadowing/Views/Components/LevelFilterChipsView.swift`
- Create: `VocabCraftApp/Features/Shadowing/Views/Components/ShadowingVideoCardView.swift`
- Create: `VocabCraftApp/Features/Shadowing/Views/ShadowingHubView.swift`
- Test: `VocabCraftAppTests/Features/Shadowing/ShadowingHubViewModelTests.swift`

**Interfaces:**
- Consumes: `ShadowingCatalogRepositoryProtocol`, `ShadowingProgressRepositoryProtocol`.
- Produces: `ShadowingHubViewModel`, `ShadowingHubView`.

- [ ] **Step 1: Write failing test for `ShadowingHubViewModel`**

```swift
// VocabCraftAppTests/Features/Shadowing/ShadowingHubViewModelTests.swift
import Testing
@testable import VocabCraftApp

@MainActor
struct ShadowingHubViewModelTests {
    @Test func testFilterByCEFRLevel() async throws {
        let catalogRepo = MockShadowingCatalogRepository()
        let progressRepo = MockShadowingProgressRepository()
        let vm = ShadowingHubViewModel(catalogRepository: catalogRepo, progressRepository: progressRepo)
        await vm.loadCatalog()
        #expect(!vm.videosByTopic.isEmpty)
        
        vm.selectedLevelFilter = "A2"
        #expect(vm.filteredVideos.allSatisfy { $0.level == "A2" })
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/ShadowingHubViewModelTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: FAIL.

- [ ] **Step 3: Implement `ShadowingHubViewModel`**

Load topics, videos, and local progress asynchronously. Compute `dailyChallengeVideo` and filter videos by `selectedLevelFilter`.

- [ ] **Step 4: Implement `DailyChallengeHeroCard`, `LevelFilterChipsView`, `ShadowingVideoCardView`, and `ShadowingHubView`**

Compose views using `CraftUIKit` tokens (`theme.colors.canvasBackground`, `theme.colors.surfacePrimary`, `theme.typography.titleLarge`).

- [ ] **Step 5: Run test to verify it passes**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/ShadowingHubViewModelTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add VocabCraftApp/Features/Shadowing/ViewModels/ShadowingHubViewModel.swift VocabCraftApp/Features/Shadowing/Views/ VocabCraftAppTests/Features/Shadowing/
git commit -m "feat(shadowing): implement ShadowingHubViewModel and discovery hub views"
```

---

### Task 5: Vòng 2 Karaoke Teleprompter (`CraftShadowingTeleprompterView`)

**Files:**
- Create: `VocabCraftApp/Features/Shadowing/Components/CraftShadowingTeleprompterView.swift`
- Create: `VocabCraftApp/Features/Shadowing/Components/CraftShadowingWordHighlightToken.swift`
- Test: `VocabCraftAppTests/Features/Shadowing/CraftShadowingTeleprompterTests.swift`

**Interfaces:**
- Consumes: `ShadowingSentence`, `ShadowingWordTimestamp`.
- Produces: `CraftShadowingTeleprompterView(currentSentence:nextSentence:currentTime:playbackSpeed:)`.

- [ ] **Step 1: Write failing test for Teleprompter word active index calculation**

```swift
// VocabCraftAppTests/Features/Shadowing/CraftShadowingTeleprompterTests.swift
import Testing
@testable import VocabCraftApp

struct CraftShadowingTeleprompterTests {
    @Test func testActiveWordIndexComputation() {
        let words = [
            ShadowingWordTimestamp(word: "Can", start: 1.0, end: 1.3),
            ShadowingWordTimestamp(word: "I", start: 1.3, end: 1.5),
            ShadowingWordTimestamp(word: "get", start: 1.5, end: 1.9)
        ]
        let helper = TeleprompterPacerCalculator(words: words)
        #expect(helper.activeWordIndex(at: 1.2) == 0)
        #expect(helper.activeWordIndex(at: 1.4) == 1)
        #expect(helper.activeWordIndex(at: 1.7) == 2)
        #expect(helper.activeWordIndex(at: 0.5) == 0) // clamp start
        #expect(helper.activeWordIndex(at: 3.0) == 2) // clamp end
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/CraftShadowingTeleprompterTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: FAIL.

- [ ] **Step 3: Implement `TeleprompterPacerCalculator` and `CraftShadowingTeleprompterView`**

Support `words_json` word timestamps with proportional word duration fallback. Highlight past words in soft green, active word with glowing pill, and upcoming words in gray. Render next sentence preview.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/CraftShadowingTeleprompterTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Shadowing/Components/CraftShadowingTeleprompterView.swift VocabCraftApp/Features/Shadowing/Components/CraftShadowingWordHighlightToken.swift VocabCraftAppTests/Features/Shadowing/CraftShadowingTeleprompterTests.swift
git commit -m "feat(shadowing): implement Karaoke Teleprompter component with pacer highlight"
```

---

### Task 6: 3-Round Studio State Coordinator & ViewModel

**Files:**
- Create: `VocabCraftApp/Features/Shadowing/ViewModels/ShadowingStudioViewModel.swift`
- Test: `VocabCraftAppTests/Features/Shadowing/ShadowingStudioViewModelTests.swift`

**Interfaces:**
- Consumes: `ShadowingVideo`, `ShadowingSessionCoordinator`, `SpeechAssessmentProtocol`, `ToggleWordBookmarkUseCaseProtocol`, `ShadowingProgressRepositoryProtocol`.
- Produces: `ShadowingStudioViewModel(video:...)` driving:
  - `activeRound: ShadowingRoundStage (.round1, .round2, .round3, .summary)`
  - Round 2 controls: `speed: Float`, `rewind5s()`, `isHeadphonesConnected: Bool`, `togglePause()`
  - Round 3 scoring: sentence attempts, `SpeechKit` results, dual-audio replay
  - Summary report computation and persistence

- [ ] **Step 1: Write failing test for `ShadowingStudioViewModel` stage transitions**

```swift
// VocabCraftAppTests/Features/Shadowing/ShadowingStudioViewModelTests.swift
import Testing
@testable import VocabCraftApp

@MainActor
struct ShadowingStudioViewModelTests {
    @Test func testRoundStageProgression() async throws {
        let video = ShadowingVideoRepositoryImpl.sampleVideo
        let vm = ShadowingStudioViewModel(video: video)
        #expect(vm.activeRound == .round1)
        
        vm.advanceToNextRound()
        #expect(vm.activeRound == .round2)
        
        vm.setPlaybackSpeed(0.85)
        #expect(vm.playbackSpeed == 0.85)
        
        vm.advanceToNextRound()
        #expect(vm.activeRound == .round3)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/ShadowingStudioViewModelTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: FAIL.

- [ ] **Step 3: Implement `ShadowingStudioViewModel`**

Integrate headphone route observer (`AVAudioSession.sharedInstance().currentRoute`), speed controls, 5s rewind math, Round 3 `SpeechKit` scoring, and final score persistence via `ShadowingProgressRepository`.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/ShadowingStudioViewModelTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Shadowing/ViewModels/ShadowingStudioViewModel.swift VocabCraftAppTests/Features/Shadowing/ShadowingStudioViewModelTests.swift
git commit -m "feat(shadowing): implement ShadowingStudioViewModel driving 3-round session state"
```

---

### Task 7: 3-Round Interactive Views & App Integration

**Files:**
- Create: `VocabCraftApp/Features/Shadowing/Views/Rounds/ShadowingImmersionView.swift`
- Create: `VocabCraftApp/Features/Shadowing/Views/Rounds/ShadowingSpeedView.swift`
- Create: `VocabCraftApp/Features/Shadowing/Views/Rounds/ShadowingEchoView.swift`
- Create: `VocabCraftApp/Features/Shadowing/Views/Summary/ShadowingSummaryReportView.swift`
- Create: `VocabCraftApp/Features/Shadowing/Views/ShadowingStudioContainerView.swift`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Modify: `VocabCraftApp/Features/AIAssistant/Views/AIAssistantHubView.swift`
- Test: `VocabCraftAppTests/Features/Shadowing/ShadowingStudioContainerViewTests.swift`

**Interfaces:**
- Consumes: `ShadowingStudioViewModel`, `CraftYouTubePlayerView`, `CraftShadowingTeleprompterView`, `CraftVoiceMatchCard`.
- Produces: Complete navigable user experience from `ShadowingHubView` into `ShadowingStudioContainerView` and back.

- [ ] **Step 1: Write failing UI integration test for `ShadowingStudioContainerView`**

```swift
// VocabCraftAppTests/Features/Shadowing/ShadowingStudioContainerViewTests.swift
import Testing
import SwiftUI
@testable import VocabCraftApp

@MainActor
struct ShadowingStudioContainerViewTests {
    @Test func testContainerInstantiatesAllRounds() {
        let video = ShadowingVideoRepositoryImpl.sampleVideo
        let vm = ShadowingStudioViewModel(video: video)
        let view = ShadowingStudioContainerView(viewModel: vm)
        #expect(view != nil)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/ShadowingStudioContainerViewTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: FAIL.

- [ ] **Step 3: Implement round views (`ShadowingImmersionView`, `ShadowingSpeedView`, `ShadowingEchoView`, `ShadowingSummaryReportView`)**

Assemble each round view using `CraftUIKit` components and bind to `ShadowingStudioViewModel`.

- [ ] **Step 4: Wire `AppContainer` and navigation from `AIAssistantHubView` / Tab Bar to `ShadowingHubView`**

Add `makeShadowingHubViewModel()` and `makeShadowingStudioViewModel(for:)` to `AppContainer`.

- [ ] **Step 5: Run test to verify it passes**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/ShadowingStudioContainerViewTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add VocabCraftApp/Features/Shadowing/Views/ VocabCraftApp/App/DI/AppContainer.swift VocabCraftApp/Features/AIAssistant/Views/AIAssistantHubView.swift VocabCraftAppTests/Features/Shadowing/
git commit -m "feat(shadowing): assemble 3-round studio container and wire navigation in AppContainer"
```

---

### Task 8: Quality Gate & Full Verification Suite

**Files:**
- Entire repository

- [ ] **Step 1: Run Swift Package Manager test suites**

```bash
swift test --package-path Packages/SpeechKit
swift test --package-path Packages/CraftUIKit
```
Expected: 100% tests PASS.

- [ ] **Step 2: Run full iOS App test suite via `xcodebuild`**

```bash
xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
Expected: **0 failures**, 100% tests PASS.

- [ ] **Step 3: Run SwiftLint**

```bash
swiftlint --strict
```
Expected: **0 errors, 0 warnings**.

- [ ] **Step 4: Verify 0 Xcode build warnings**

```bash
xcodebuild clean build -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' | grep -i "warning:"
```
Expected: Zero warnings.

- [ ] **Step 5: Final Git commit and hygiene check**

Verify `git status` is clean with no untracked generated files.
