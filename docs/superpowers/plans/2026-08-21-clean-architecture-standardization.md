# Clean Architecture & Swift Concurrency Standardization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor VocabCraftApp to strictly comply with Clean Architecture boundaries, isolate SwiftData actor concurrency with Sendable DTOs, unify navigation state under AppRouter, relocate Core Audio services, and guarantee 100% cross-platform test pass rate on macOS host and iOS Simulator.

**Architecture:** Enforce pure Swift Domain entities and protocols with inward dependencies. Connect `UserProgressModelActor` into `VocabularyRepositoryImpl` via `AppContainer` and sanitize actor boundary interfaces with `Sendable` value types. Elevate `AppRouter` to Single Source of Truth for navigation, and wrap iOS-specific `AVAudioSession` test calls with `#if os(iOS)`.

**Tech Stack:** Swift 5.10 / Swift 6, SwiftUI, SwiftData, AVFoundation, Speech, Swift Testing / XCTest.

**Spec:** [docs/superpowers/specs/2026-08-21-clean-architecture-standardization-design.md](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-21-clean-architecture-standardization-design.md)

## Global Constraints

- Domain Layer MUST contain zero imports of `SwiftUI`, `SwiftData`, or `AVFoundation`.
- `UserProgressModelActor` public APIs MUST NEVER return SwiftData `@Model` classes across actor boundaries.
- All 391+ unit tests MUST pass on both `swift test` (macOS host) and `xcodebuild test` (iOS Simulator).
- Do not introduce external dependencies or third-party frameworks.

---

### Task 1: Domain Entities & Protocols Clean Architecture Refactoring

**Files:**
- Create: `VocabCraftApp/Domain/Entities/TopicDeckEntities.swift`
- Create: `VocabCraftApp/Domain/Entities/ReflexDrillItem.swift`
- Create: `VocabCraftApp/Domain/Protocols/ContinuousReflexSpeechProtocol.swift`
- Modify: `VocabCraftApp/Domain/Protocols/VocabularyRepositoryProtocol.swift`
- Modify: `VocabCraftApp/Domain/UseCases/FetchVocabularyUseCase.swift`
- Modify: `VocabCraftApp/Features/Vocabulary/Models/TopicDeckModels.swift`
- Modify: `VocabCraftApp/Data/Local/Mock/MockVocabularyDataSource.swift`
- Modify: `VocabCraftApp/Data/Repositories/MockVocabularyRepository.swift`
- Test: `VocabCraftAppTests/DomainEntitiesTests.swift`

**Interfaces:**
- Consumes: None
- Produces: `TopicDeck`, `SubTopicNode`, `TopicWord`, `NodeState`, `ReflexDrillItem`, `ContinuousReflexSpeechProtocol` in `Domain`

- [ ] **Step 1: Write the failing domain test**

Create `VocabCraftAppTests/DomainEntitiesTests.swift`:
```swift
import Testing
import Foundation
@testable import VocabCraftApp

@Suite("Domain Entities Clean Architecture Tests")
struct DomainEntitiesTests {
    @Test("TopicDeck is pure domain entity with hex color")
    func testTopicDeckPureDomain() {
        let deck = TopicDeck(
            id: "ielts_tech",
            title: "Technology",
            wordCount: 20,
            completionPercentage: 0.5,
            badgeColorHex: "#3B82F6",
            iconName: "desktopcomputer"
        )
        #expect(deck.id == "ielts_tech")
        #expect(deck.badgeColorHex == "#3B82F6")
    }

    @Test("ReflexDrillItem domain entity initialization")
    func testReflexDrillItem() {
        let item = ReflexDrillItem(
            id: 101,
            drillType: "speed",
            promptText: "Thói quen",
            correctAnswer: "habit",
            distractors: ["hobby", "habitat"],
            targetTimeMs: 2500,
            sentenceTextEn: "It is a good habit."
        )
        #expect(item.id == 101)
        #expect(item.correctAnswer == "habit")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/DomainEntitiesTests`
Expected: FAIL with missing `ReflexDrillItem` or `badgeColorHex` parameter.

- [ ] **Step 3: Create pure domain entities and protocols**

1. Create `VocabCraftApp/Domain/Entities/TopicDeckEntities.swift`:
```swift
import Foundation

public enum NodeState: String, Equatable, Sendable {
    case locked
    case active
    case completed
}

public struct TopicWord: Identifiable, Equatable, Sendable {
    public let id: String
    public let english: String
    public let phonetic: String
    public let vietnamese: String
    public let example: String
    public let partOfSpeech: String
    public var isMastered: Bool
    public var isSavedToPersonalVault: Bool

    public init(
        id: String,
        english: String,
        phonetic: String,
        vietnamese: String,
        example: String,
        partOfSpeech: String,
        isMastered: Bool = false,
        isSavedToPersonalVault: Bool = false
    ) {
        self.id = id
        self.english = english
        self.phonetic = phonetic
        self.vietnamese = vietnamese
        self.example = example
        self.partOfSpeech = partOfSpeech
        self.isMastered = isMastered
        self.isSavedToPersonalVault = isSavedToPersonalVault
    }
}

public struct SubTopicNode: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let iconName: String
    public let totalWords: Int
    public let learnedWords: Int
    public let state: NodeState
    public let words: [TopicWord]

    public init(
        id: String,
        title: String,
        iconName: String,
        totalWords: Int,
        learnedWords: Int,
        state: NodeState,
        words: [TopicWord] = []
    ) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.totalWords = totalWords
        self.learnedWords = learnedWords
        self.state = state
        self.words = words
    }
}

public struct TopicDeck: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let wordCount: Int
    public let completionPercentage: Double
    public let badgeColorHex: String
    public let iconName: String

    public init(
        id: String,
        title: String,
        wordCount: Int,
        completionPercentage: Double,
        badgeColorHex: String,
        iconName: String
    ) {
        self.id = id
        self.title = title
        self.wordCount = wordCount
        self.completionPercentage = completionPercentage
        self.badgeColorHex = badgeColorHex
        self.iconName = iconName
    }
}
```

2. Create `VocabCraftApp/Domain/Entities/ReflexDrillItem.swift`:
```swift
import Foundation

public struct ReflexDrillItem: Identifiable, Equatable, Sendable {
    public let id: Int64
    public let drillType: String
    public let promptText: String
    public let correctAnswer: String
    public let distractors: [String]
    public let targetTimeMs: Int
    public let sentenceTextEn: String?

    public init(
        id: Int64,
        drillType: String,
        promptText: String,
        correctAnswer: String,
        distractors: [String],
        targetTimeMs: Int,
        sentenceTextEn: String? = nil
    ) {
        self.id = id
        self.drillType = drillType
        self.promptText = promptText
        self.correctAnswer = correctAnswer
        self.distractors = distractors
        self.targetTimeMs = targetTimeMs
        self.sentenceTextEn = sentenceTextEn
    }
}
```

3. Create `VocabCraftApp/Domain/Protocols/ContinuousReflexSpeechProtocol.swift`:
```swift
import Foundation

public protocol ContinuousReflexSpeechProtocol: AnyObject, Sendable {
    var isSessionActive: Bool { get }
    var isRecognitionMuted: Bool { get }
    var currentTranscript: String { get }
    var onMatchDetected: ((String) -> Void)? { get set }
    var onTranscriptUpdate: ((String) -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }

    func startSession(contextualPhrases: [String])
    func startSession()
    func stopSession()
    func pauseListening()
    func resumeListening()
    func setTargetWord(lemma: String, contextualPhrases: [String])
    func resetBuffer()
}

public extension ContinuousReflexSpeechProtocol {
    func startSession() {
        startSession(contextualPhrases: [])
    }
}
```

4. Update `VocabCraftApp/Domain/Protocols/VocabularyRepositoryProtocol.swift`:
```swift
import Foundation

public protocol VocabularyRepositoryProtocol: AnyObject {
    func fetchWordRecords(limit: Int) async throws -> [Word]
    func fetchWord(id: Int64) async throws -> Word?
    func fetchReflexDrillRecords(cefrLevel: String) async throws -> [ReflexDrillItem]
    func searchWords(query: String) async throws -> [Word]
    func fetchSuggestedWords(limit: Int) async throws -> [SuggestedWord]
    func fetchTopicDecks() async throws -> [TopicDeck]
    func fetchTopicDeckDetails(deckId: String) async throws -> [SubTopicNode]
}
```

5. Update `VocabCraftApp/Domain/UseCases/FetchVocabularyUseCase.swift`:
```swift
import Foundation

public protocol FetchVocabularyUseCaseProtocol: AnyObject {
    func executeFetchWords(limit: Int) async throws -> [Word]
    func executeSearch(query: String) async throws -> [Word]
    func executeFetchDrills(cefrLevel: String) async throws -> [ReflexDrillItem]
}

public final class FetchVocabularyUseCase: FetchVocabularyUseCaseProtocol {
    private let repository: VocabularyRepositoryProtocol

    public init(repository: VocabularyRepositoryProtocol) {
        self.repository = repository
    }

    public func executeFetchWords(limit: Int = 50) async throws -> [Word] {
        try await repository.fetchWordRecords(limit: limit)
    }

    public func executeSearch(query: String) async throws -> [Word] {
        try await repository.searchWords(query: query)
    }

    public func executeFetchDrills(cefrLevel: String) async throws -> [ReflexDrillItem] {
        try await repository.fetchReflexDrillRecords(cefrLevel: cefrLevel)
    }
}
```

6. Update `VocabCraftApp/Features/Vocabulary/Models/TopicDeckModels.swift` to add SwiftUI presentation extensions (`Color(hex: deck.badgeColorHex)`) and sample data.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/DomainEntitiesTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain VocabCraftApp/Features/Vocabulary/Models VocabCraftApp/Data VocabCraftAppTests/DomainEntitiesTests.swift
git commit -m "refactor(domain): relocate topic deck and reflex entities to domain layer with pure swift signatures"
```

---

### Task 2: Data Layer Concurrency & SwiftData Actor Isolation

**Files:**
- Modify: `VocabCraftApp/Data/Local/Actors/UserProgressModelActor.swift`
- Modify: `VocabCraftApp/Domain/Protocols/SRSRepositoryProtocol.swift`
- Modify: `VocabCraftApp/Data/Repositories/SRSRepositoryImpl.swift`
- Create: `VocabCraftApp/Domain/UseCases/ResetUserProgressUseCase.swift`
- Modify: `VocabCraftApp/Data/Repositories/VocabularyRepositoryImpl.swift`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Test: `VocabCraftAppTests/UserProgressModelActorConcurrencyTests.swift`

**Interfaces:**
- Consumes: `TopicDeck`, `ReflexDrillItem`, `UserProgressModelActor`
- Produces: `UserWordProgressData`, `ResetUserProgressUseCaseProtocol`, `AppContainer` fully wired with `progressActor`

- [ ] **Step 1: Write the failing concurrency & wiring test**

Create `VocabCraftAppTests/UserProgressModelActorConcurrencyTests.swift`:
```swift
import XCTest
import SwiftData
@testable import VocabCraftApp

@MainActor
final class UserProgressModelActorConcurrencyTests: XCTestCase {
    var container: ModelContainer!
    var actor: UserProgressModelActor!

    override func setUp() async throws {
        let schema = Schema([UserWordProgress.self, ReflexSessionLog.self, WidgetCurrentState.self, QuickReflexAttemptRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        actor = UserProgressModelActor(modelContainer: container)
    }

    func testActorReturnsSendableValueType() async throws {
        try await actor.saveProgress(wordId: 42, cefrLevel: "B2", masteryLevel: 3)
        let data = try await actor.getProgressData(wordId: 42)
        XCTAssertNotNil(data)
        XCTAssertEqual(data?.wordId, 42)
        XCTAssertEqual(data?.masteryLevel, 3)
    }

    func testResetAllProgressClearsData() async throws {
        try await actor.saveProgress(wordId: 42, masteryLevel: 4)
        let levelsBefore = try await actor.fetchAllMasteryLevels()
        XCTAssertEqual(levelsBefore[42], 4)

        try await actor.resetAllProgress()
        let levelsAfter = try await actor.fetchAllMasteryLevels()
        XCTAssertTrue(levelsAfter.isEmpty)
    }

    func testAppContainerWiresProgressActorToVocabRepo() async throws {
        let appContainer = AppContainer(datasetEngine: DatasetEngine(), modelContainer: container)
        let decks = try await appContainer.vocabularyRepository.fetchTopicDecks()
        XCTAssertFalse(decks.isEmpty)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/UserProgressModelActorConcurrencyTests`
Expected: FAIL with `getProgressData` or `resetAllProgress` undefined.

- [ ] **Step 3: Implement Sendable DTOs and AppContainer wiring**

1. In `VocabCraftApp/Data/Local/Actors/UserProgressModelActor.swift`:
Add `UserWordProgressData: Sendable` and update actor methods:
```swift
public struct UserWordProgressData: Sendable, Equatable {
    public let wordId: Int64
    public let cefrLevel: String
    public let masteryLevel: Int
    public let isBookmarked: Bool
    public let easeFactor: Double
    public let intervalDays: Int
    public let nextReviewDate: Date
    public let lastReviewDate: Date
    public let totalReviews: Int

    public init(
        wordId: Int64,
        cefrLevel: String,
        masteryLevel: Int,
        isBookmarked: Bool,
        easeFactor: Double,
        intervalDays: Int,
        nextReviewDate: Date,
        lastReviewDate: Date,
        totalReviews: Int
    ) {
        self.wordId = wordId
        self.cefrLevel = cefrLevel
        self.masteryLevel = masteryLevel
        self.isBookmarked = isBookmarked
        self.easeFactor = easeFactor
        self.intervalDays = intervalDays
        self.nextReviewDate = nextReviewDate
        self.lastReviewDate = lastReviewDate
        self.totalReviews = totalReviews
    }
}

// Inside UserProgressModelActor:
public func getProgressData(wordId: Int64) throws -> UserWordProgressData? {
    var descriptor = FetchDescriptor<UserWordProgress>(
        predicate: #Predicate { $0.wordId == wordId }
    )
    descriptor.fetchLimit = 1
    guard let item = try modelContext.fetch(descriptor).first else { return nil }
    return UserWordProgressData(
        wordId: item.wordId,
        cefrLevel: item.cefrLevel,
        masteryLevel: item.masteryLevel,
        isBookmarked: item.isBookmarked,
        easeFactor: item.easeFactor,
        intervalDays: item.intervalDays,
        nextReviewDate: item.nextReviewDate,
        lastReviewDate: item.lastReviewDate,
        totalReviews: item.totalReviews
    )
}

public func resetAllProgress() throws {
    try modelContext.delete(model: UserWordProgress.self)
    try modelContext.delete(model: ReflexSessionLog.self)
    try modelContext.delete(model: QuickReflexAttemptRecord.self)
    try modelContext.save()
}
```

2. In `VocabCraftApp/Domain/Protocols/SRSRepositoryProtocol.swift`:
```swift
public protocol SRSRepositoryProtocol: AnyObject {
    func getProgress(wordId: Int64) async throws -> SRSProgressItem?
    func saveProgress(_ item: SRSProgressItem) async throws
    func logReflexSession(drillId: Int64, responseTimeMs: Int, accuracyScore: Double) async throws
    func resetAllProgress() async throws
}
```

3. In `VocabCraftApp/Data/Repositories/SRSRepositoryImpl.swift`:
Implement `resetAllProgress()`:
```swift
public func resetAllProgress() async throws {
    guard let context = modelContext else { return }
    try context.delete(model: UserWordProgress.self)
    try context.delete(model: ReflexSessionLog.self)
    try context.save()
}
```

4. Create `VocabCraftApp/Domain/UseCases/ResetUserProgressUseCase.swift`:
```swift
import Foundation

public protocol ResetUserProgressUseCaseProtocol: AnyObject {
    func executeResetAllProgress() async throws
}

public final class ResetUserProgressUseCase: ResetUserProgressUseCaseProtocol {
    private let srsRepository: SRSRepositoryProtocol

    public init(srsRepository: SRSRepositoryProtocol) {
        self.srsRepository = srsRepository
    }

    public func executeResetAllProgress() async throws {
        try await srsRepository.resetAllProgress()
    }
}
```

5. In `VocabCraftApp/Data/Repositories/VocabularyRepositoryImpl.swift`:
Map `DatasetDataSourceProtocol` drill records to domain `ReflexDrillItem`.

6. In `VocabCraftApp/App/DI/AppContainer.swift`:
Wire `UserProgressModelActor` into `VocabularyRepositoryImpl` and expose `resetUserProgressUseCase`:
```swift
let progressActor: UserProgressModelActor? = modelContainer != nil
    ? UserProgressModelActor(modelContainer: modelContainer!)
    : nil

let vocabRepo: VocabularyRepositoryProtocol = shouldMock
    ? MockVocabularyRepository()
    : VocabularyRepositoryImpl(datasetEngine: datasetEngine, progressActor: progressActor)

self.resetUserProgressUseCase = ResetUserProgressUseCase(srsRepository: srsRepo)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/UserProgressModelActorConcurrencyTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Data VocabCraftApp/Domain VocabCraftApp/App/DI VocabCraftAppTests/UserProgressModelActorConcurrencyTests.swift
git commit -m "refactor(data): isolate swiftdata actor with sendable dto and wire progress actor in app container"
```

---

### Task 3: Core Audio Relocation & Cross-Platform Test Guarding

**Files:**
- Move: `VocabCraftApp/Features/ReflexDrill/Services/ContinuousReflexSpeechService.swift` $\rightarrow$ `VocabCraftApp/Core/Audio/ContinuousReflexSpeechService.swift`
- Modify: `VocabCraftAppTests/Features/ReflexDrill/ContinuousReflexSpeechServiceTests.swift`
- Modify: `VocabCraftApp.xcodeproj/project.pbxproj` (if needed for file move)

**Interfaces:**
- Consumes: `Domain/Protocols/ContinuousReflexSpeechProtocol`
- Produces: `Core/Audio/ContinuousReflexSpeechService`

- [ ] **Step 1: Verify failing macOS swift test**

Run: `swift test`
Expected: Compile failure on macOS due to `AVAudioSessionRouteChangeReasonKey` in `ContinuousReflexSpeechServiceTests.swift`.

- [ ] **Step 2: Move ContinuousReflexSpeechService to Core/Audio**

Move file:
```bash
git mv VocabCraftApp/Features/ReflexDrill/Services/ContinuousReflexSpeechService.swift VocabCraftApp/Core/Audio/ContinuousReflexSpeechService.swift
```

- [ ] **Step 3: Guard iOS-only test methods in ContinuousReflexSpeechServiceTests.swift**

In `VocabCraftAppTests/Features/ReflexDrill/ContinuousReflexSpeechServiceTests.swift`:
Wrap `testAudioSessionRouteChange_oldDeviceUnavailable_stopsSession` and `testAudioSessionRouteChange_nonDisconnectReasons_keepsSessionActive` inside `#if os(iOS) ... #endif`.

- [ ] **Step 4: Run macOS swift test and Xcode Simulator test**

Run 1: `swift test`
Expected: PASS (builds cleanly on macOS host).

Run 2: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17"`
Expected: PASS (runs all 391+ tests including the iOS-specific audio session tests).

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Audio VocabCraftAppTests/Features/ReflexDrill/ContinuousReflexSpeechServiceTests.swift
git commit -m "refactor(audio): relocate continuous speech service to core and guard ios audio session tests"
```

---

### Task 4: Navigation Unification & View Initialization Cleanup

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift`
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`
- Modify: `VocabCraftApp/Features/Settings/ViewModels/SettingsViewModel.swift`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Test: `VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift`
- Test: `VocabCraftAppTests/SettingsViewModelTests.swift`

**Interfaces:**
- Consumes: `AppRouter`, `ResetUserProgressUseCaseProtocol`
- Produces: Sanitized `HomepageView` and `SettingsViewModel`

- [ ] **Step 1: Write test for SettingsViewModel reset progress use case integration**

In `VocabCraftAppTests/SettingsViewModelTests.swift`:
```swift
@Test("SettingsViewModel resetSRSProgress executes reset use case")
func testResetSRSProgressCallsUseCase() async throws {
    let mockUseCase = MockResetUserProgressUseCase()
    let store = UserSettingsStore()
    let viewModel = SettingsViewModel(
        store: store,
        ttsService: MockTextToSpeechService(),
        resetProgressUseCase: mockUseCase
    )

    await viewModel.resetSRSProgress()
    #expect(mockUseCase.didCallReset == true)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/SettingsViewModelTests`
Expected: FAIL with `resetProgressUseCase` parameter missing.

- [ ] **Step 3: Update HomepageViewModel, HomepageView, and SettingsViewModel**

1. In `VocabCraftApp/Features/Settings/ViewModels/SettingsViewModel.swift`:
```swift
@MainActor
@Observable
public final class SettingsViewModel {
    public var store: UserSettingsStore
    public var isPlayingAudio: Bool = false
    public var cacheSizeString: String = "12.4 MB"
    private let ttsService: TextToSpeechProtocol
    private let resetProgressUseCase: ResetUserProgressUseCaseProtocol?

    public init(
        store: UserSettingsStore,
        ttsService: TextToSpeechProtocol,
        resetProgressUseCase: ResetUserProgressUseCaseProtocol? = nil
    ) {
        self.store = store
        self.ttsService = ttsService
        self.resetProgressUseCase = resetProgressUseCase
    }

    public func resetSRSProgress() async {
        store.dailyGoalCount = 15
        try? await resetProgressUseCase?.executeResetAllProgress()
    }
}
```

2. In `VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift`:
Remove `selectedTab` from `HomepageState` and remove `selectTab` proxy method.

3. In `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`:
- Remove `@State private var selectedTab`.
- Bind `LiquidGlassTabBar(selectedTab: Bindable(appRouter).selectedTab)`.
- Strip out 40+ lines of `ProcessInfo.processInfo.arguments` parsing in `init` and `onAppear` (delegated fully to `AppRouter` and `VocabCraftApp`).

4. In `VocabCraftApp/App/DI/AppContainer.swift`:
Update `makeSettingsViewModel()` to pass `resetUserProgressUseCase`.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17"`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Homepage VocabCraftApp/Features/Settings VocabCraftApp/App VocabCraftAppTests
git commit -m "refactor(presentation): unify navigation under app router and wire settings reset use case"
```

---

### Task 5: End-to-End Test Suite & Architecture Verification

**Files:**
- Verify: Full repository structure and all targets.

- [ ] **Step 1: Check Domain layer purity (zero UIKit/SwiftUI/SwiftData imports)**

Run:
```bash
grep -rn "import SwiftUI\|import SwiftData\|import AVFoundation" VocabCraftApp/Domain/
```
Expected: Empty output (zero matches).

- [ ] **Step 2: Run macOS host swift test**

Run:
```bash
swift test
```
Expected: All tests build and pass cleanly.

- [ ] **Step 3: Run iOS Simulator test suite**

Run:
```bash
xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17"
```
Expected: All 391+ tests pass with zero failures.

- [ ] **Step 4: Final commit & tag if clean**

```bash
git status
```
