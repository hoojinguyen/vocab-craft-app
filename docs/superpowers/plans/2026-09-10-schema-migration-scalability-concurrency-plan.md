# Package 4: Schema Migration Scalability & Strict Concurrency Quality Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish an immutable SwiftData VersionedSchema architecture, verify persistent SQLite migration safety, eliminate dead code, and enforce strict concurrency with complete diagnostics resolution across all targets.

**Architecture:** Freeze SchemaV2 into an isolated namespace with self-contained model classes, providing transparent top-level typealiases for caller compatibility. Coordinate lightweight migrations through AppMigrationPlan with comprehensive SQLite persistent tests. Enable SWIFT_STRICT_CONCURRENCY = complete across Xcode and SPM build settings, fixing all nonisolated mutable statics and actor isolation warnings.

**Tech Stack:** Swift 5.10, SwiftData, Swift Concurrency, XCTest, Swift Testing, SPM, Xcode 16 / iOS 17+.

**Spec:** [docs/superpowers/specs/2026-09-10-schema-migration-scalability-concurrency-design.md](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-09-10-schema-migration-scalability-concurrency-design.md)

## Global Constraints
- **Platform & Language Target:** iOS 17+, Swift 5.10 with upcoming strict concurrency complete feature.
- **Zero Hardcoded Strings:** Display strings and recovery messages must reside in `Localizable.xcstrings` with 100% EN/VI parity.
- **Zero Raw Styling:** Any UI elements must use `CraftUIKit` tokens (CraftColor, CraftFont, CraftSpacing).
- **Strict Quality Gate:** Zero compiler warnings, zero SwiftLint violations, 100% test pass rate across all suites.
- **Schema Stability:** Once defined in a `VersionedSchema`, models must remain completely immutable.

---

### Task 1: Dead Code Cleanup & Repository Hygiene

**Files:**
- Delete: `VocabCraftApp/Features/Vocabulary/Views/Components/DynamicPulseTimerBar.swift`
- Delete: `VocabCraftApp/Features/Reflex/Core/Components/Container/ReflexCardContainerView.swift`
- Modify: `VocabCraftApp/Core/DesignSystem/VocabTheme.swift:148-162`
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift:19-24, 134-142, 413-477`
- Modify: `VocabCraftAppTests/Features/Reflex/ReflexContainerComponentsTests.swift:84-115`
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp.xcodeproj/project.pbxproj` (remove references to deleted files)

**Interfaces:**
- Consumes: Existing project structure
- Produces: Clean git workspace without superseded or dead code components

- [ ] **Step 1: Verify test baseline before cleanup**

Run: `swift test --filter ReflexContainerComponentsTests`
Expected: PASS

- [ ] **Step 2: Remove references to deleted files in project.pbxproj**

Remove PBXBuildFile and PBXFileReference for `DynamicPulseTimerBar.swift` and `ReflexCardContainerView.swift` in `VocabCraftApp.xcodeproj/project.pbxproj`.

- [ ] **Step 3: Run full tests to verify clean build after deletion**

Run: `swift test`
Expected: PASS (all 298 tests in 48 suites)

- [ ] **Step 4: Verify localization test suite**

Run: `swift test --package-path Packages/CraftUIKit --filter LocalizationTests`
Expected: PASS (13 passed)

- [ ] **Step 5: Check git status and commit dead code cleanup**

Run:
```bash
git add -u
git commit -m "chore(cleanup): remove deprecated reflex card container and pulse timer dead code"
```
Expected: Clean commit created on main branch.

---

### Task 2: Immutable SchemaV2 Implementation & Model Freezing

**Files:**
- Create: `VocabCraftApp/Core/Database/Schemas/AppSchemaV2.swift`
- Modify: `VocabCraftApp/Core/Database/SwiftDataModels.swift:1-246`
- Modify: `VocabCraftApp/Core/Database/SharedAppGroupContainer.swift:7-18, 101-102, 154-155`
- Modify: `VocabCraftApp.xcodeproj/project.pbxproj` (add `AppSchemaV2.swift` to Sources & Widget Sources)

**Interfaces:**
- Consumes: `SchemaV1` from `AppSchemaV1.swift`
- Produces: `SchemaV2: VersionedSchema` with embedded models:
  - `SchemaV2.UserWordProgress`
  - `SchemaV2.UserStageProgress`
  - `SchemaV2.ReflexSessionLog`
  - `SchemaV2.WidgetCurrentState`
  - `SchemaV2.QuickReflexAttemptRecord`
  - `public typealias UserWordProgress = SchemaV2.UserWordProgress`
  - `public typealias UserStageProgress = SchemaV2.UserStageProgress`
  - `public typealias ReflexSessionLog = SchemaV2.ReflexSessionLog`
  - `public typealias WidgetCurrentState = SchemaV2.WidgetCurrentState`
  - `public typealias QuickReflexAttemptRecord = SchemaV2.QuickReflexAttemptRecord`

- [ ] **Step 1: Create `VocabCraftApp/Core/Database/Schemas/AppSchemaV2.swift`**

Implement `public enum SchemaV2: VersionedSchema` with `versionIdentifier = Schema.Version(2, 0, 0)` containing all 5 models as nested classes inside `SchemaV2`.

```swift
import Foundation
#if canImport(SwiftData)
import SwiftData
#endif

#if canImport(SwiftDataMacros)
public enum SchemaV2: VersionedSchema {
    public static var versionIdentifier = Schema.Version(2, 0, 0)
    public static var models: [any PersistentModel.Type] {
        [
            SchemaV2.UserWordProgress.self,
            SchemaV2.UserStageProgress.self,
            SchemaV2.ReflexSessionLog.self,
            SchemaV2.WidgetCurrentState.self,
            SchemaV2.QuickReflexAttemptRecord.self
        ]
    }

    @Model
    public final class UserWordProgress {
        @Attribute(.unique) public var wordId: Int64
        public var cefrLevel: String = "A1"
        public var masteryLevel: Int = 0
        public var isBookmarked: Bool = false
        public var easeFactor: Double = 2.5
        public var intervalDays: Int = 1
        public var nextReviewDate: Date = Date()
        public var lastReviewDate: Date = Date()
        public var totalReviews: Int = 0
        public var needsReview: Bool = false
        public var mistakeCount: Int = 0
        public var sourceDeckId: String?
        public var sourceNodeId: String?
        @Attribute(originalName: "correctStreak") public var consecutiveCorrectStreak: Int = 0
        public var practicedModesRaw: String = ""
        public var isMastered: Bool = false
        public var modeSuccessCountsRaw: String = "{}"

        public init(
            wordId: Int64,
            cefrLevel: String = "A1",
            masteryLevel: Int = 0,
            isBookmarked: Bool = false,
            easeFactor: Double = 2.5,
            intervalDays: Int = 1,
            nextReviewDate: Date = Date(),
            lastReviewDate: Date = Date(),
            totalReviews: Int = 0,
            needsReview: Bool = false,
            mistakeCount: Int = 0,
            sourceDeckId: String? = nil,
            sourceNodeId: String? = nil,
            consecutiveCorrectStreak: Int = 0,
            practicedModesRaw: String = "",
            isMastered: Bool = false,
            modeSuccessCountsRaw: String = ""
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
            self.needsReview = needsReview
            self.mistakeCount = mistakeCount
            self.sourceDeckId = sourceDeckId
            self.sourceNodeId = sourceNodeId
            self.consecutiveCorrectStreak = consecutiveCorrectStreak
            self.practicedModesRaw = practicedModesRaw
            self.isMastered = isMastered
            self.modeSuccessCountsRaw = modeSuccessCountsRaw
        }

        public var correctStreak: Int {
            get { consecutiveCorrectStreak }
            set { consecutiveCorrectStreak = newValue }
        }
    }

    @Model
    public final class UserStageProgress {
        @Attribute(.unique) public var stageId: String
        public var deckId: String
        public var isCompleted: Bool
        public var score: Int
        public var progressFraction: Double
        public var completedAt: Date

        public init(
            stageId: String,
            deckId: String,
            isCompleted: Bool = false,
            score: Int = 0,
            progressFraction: Double = 0.0,
            completedAt: Date = Date()
        ) {
            self.stageId = stageId
            self.deckId = deckId
            self.isCompleted = isCompleted
            self.score = score
            self.progressFraction = progressFraction
            self.completedAt = completedAt
        }
    }

    @Model
    public final class ReflexSessionLog {
        @Attribute(.unique) public var id: UUID
        public var drillId: Int64
        public var responseTimeMs: Int
        public var accuracyScore: Double
        public var timestamp: Date

        public init(
            id: UUID = UUID(),
            drillId: Int64,
            responseTimeMs: Int,
            accuracyScore: Double,
            timestamp: Date = Date()
        ) {
            self.id = id
            self.drillId = drillId
            self.responseTimeMs = responseTimeMs
            self.accuracyScore = accuracyScore
            self.timestamp = timestamp
        }
    }

    @Model
    public final class QuickReflexAttemptRecord {
        @Attribute(.unique) public var id: UUID
        public var wordId: Int64
        public var recallWordTimeMs: Int
        public var collocationTimeMs: Int
        public var produceSentenceTimeMs: Int
        public var recallWordSucceeded: Bool
        public var collocationSucceeded: Bool
        public var produceSentenceSucceeded: Bool
        public var shadowPronunciationScore: Double?
        public var maxHintLevel: Int
        public var inputModeRawValue: String
        public var retryCount: Int
        public var confidenceRawValue: String
        public var timestamp: Date

        public var retrieveTimeMs: Int {
            get { recallWordTimeMs }
            set { recallWordTimeMs = newValue }
        }
        public var useTimeMs: Int {
            get { produceSentenceTimeMs }
            set { produceSentenceTimeMs = newValue }
        }
        public var retrieveSucceeded: Bool {
            get { recallWordSucceeded }
            set { recallWordSucceeded = newValue }
        }
        public var useSucceeded: Bool {
            get { produceSentenceSucceeded }
            set { produceSentenceSucceeded = newValue }
        }

        public init(
            id: UUID = UUID(),
            wordId: Int64,
            recallWordTimeMs: Int,
            collocationTimeMs: Int = 0,
            produceSentenceTimeMs: Int,
            recallWordSucceeded: Bool,
            collocationSucceeded: Bool,
            produceSentenceSucceeded: Bool,
            shadowPronunciationScore: Double? = nil,
            maxHintLevel: Int,
            inputModeRawValue: String,
            retryCount: Int,
            confidenceRawValue: String,
            timestamp: Date = Date()
        ) {
            self.id = id
            self.wordId = wordId
            self.recallWordTimeMs = recallWordTimeMs
            self.collocationTimeMs = collocationTimeMs
            self.produceSentenceTimeMs = produceSentenceTimeMs
            self.recallWordSucceeded = recallWordSucceeded
            self.collocationSucceeded = collocationSucceeded
            self.produceSentenceSucceeded = produceSentenceSucceeded
            self.shadowPronunciationScore = shadowPronunciationScore
            self.maxHintLevel = maxHintLevel
            self.inputModeRawValue = inputModeRawValue
            self.retryCount = retryCount
            self.confidenceRawValue = confidenceRawValue
            self.timestamp = timestamp
        }
    }

    @Model
    public final class WidgetCurrentState {
        @Attribute(.unique) public var id: String
        public var currentWordId: Int64 = 0
        public var lemma: String = ""
        public var ipaUs: String = ""
        public var definitionVi: String = ""
        public var exampleEn: String = ""
        public var lastUpdated: Date = Date()

        public init(
            id: String = "default_widget",
            currentWordId: Int64,
            lemma: String,
            ipaUs: String,
            definitionVi: String,
            exampleEn: String,
            lastUpdated: Date = Date()
        ) {
            self.id = id
            self.currentWordId = currentWordId
            self.lemma = lemma
            self.ipaUs = ipaUs
            self.definitionVi = definitionVi
            self.exampleEn = exampleEn
            self.lastUpdated = lastUpdated
        }
    }
}
#endif
```

- [ ] **Step 2: Update `SwiftDataModels.swift` with typealiases**

Replace the top-level `@Model` classes in `SwiftDataModels.swift` with:
```swift
#if canImport(SwiftDataMacros)
public typealias UserWordProgress = SchemaV2.UserWordProgress
public typealias UserStageProgress = SchemaV2.UserStageProgress
public typealias ReflexSessionLog = SchemaV2.ReflexSessionLog
public typealias QuickReflexAttemptRecord = SchemaV2.QuickReflexAttemptRecord
public typealias WidgetCurrentState = SchemaV2.WidgetCurrentState
#else
...
```

- [ ] **Step 3: Update `SharedAppGroupContainer.swift`**

Remove the inline duplicate `SchemaV2` declaration from `SharedAppGroupContainer.swift` and use the canonical `SchemaV2` from `AppSchemaV2.swift`.

- [ ] **Step 4: Add `AppSchemaV2.swift` to `project.pbxproj`**

Add `AppSchemaV2.swift` file reference and build file to both `VocabCraftApp` and `VocabCraftWidgetExtension` targets.

- [ ] **Step 5: Run tests to verify compilation and baseline execution**

Run: `swift test`
Expected: PASS (all tests pass)

- [ ] **Step 6: Commit Task 2**

Run:
```bash
git add VocabCraftApp/Core/Database/Schemas/AppSchemaV2.swift VocabCraftApp/Core/Database/SwiftDataModels.swift VocabCraftApp/Core/Database/SharedAppGroupContainer.swift VocabCraftApp.xcodeproj/project.pbxproj
git commit -m "refactor(database): freeze SchemaV2 and establish immutable VersionedSchema architecture"
```

---

### Task 3: Persistent SQLite Migration Verification Suite

**Files:**
- Modify: `VocabCraftAppTests/Core/Database/SchemaMigrationTests.swift`

**Interfaces:**
- Consumes: `SchemaV1`, `SchemaV2`, `AppMigrationPlan`, `SharedAppGroupContainer`
- Produces: Thorough migration test scenarios verifying data persistence across schema upgrades on real on-disk SQLite databases

- [ ] **Step 1: Write expanded migration tests in `SchemaMigrationTests.swift`**

Add tests:
1. `test_v1_to_v2_migration_preserves_multiple_word_progress_and_logs`: Verifies that multiple words with various streak counts, mistake counts, bookmarks, review dates, and reflex session logs are preserved 100% across container open/close cycles on a persistent SQLite store.
2. `test_v2_container_rejects_corrupted_store_and_creates_backup`: Verifies `SharedAppGroupContainer.createContainer` quarantines corrupt store files and throws typed `DatabaseStoreError`.

- [ ] **Step 2: Run migration tests**

Run: `swift test --filter SchemaMigrationTests`
Expected: PASS (all migration tests pass)

- [ ] **Step 3: Commit Task 3**

Run:
```bash
git add VocabCraftAppTests/Core/Database/SchemaMigrationTests.swift
git commit -m "test(database): add comprehensive persistent SQLite schema migration tests"
```

---

### Task 4: Strict Concurrency Enablement & Concurrency Diagnostics Elimination

**Files:**
- Modify: `VocabCraftApp.xcodeproj/project.pbxproj` (add `SWIFT_STRICT_CONCURRENCY = complete;` across targets)
- Modify: `Package.swift:25-63` (add `.enableUpcomingFeature("StrictConcurrency")`)
- Modify: `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift:432-452`
- Modify: `VocabCraftWidgetExtension/AppIntents/MarkLearnedIntent.swift:10-15`
- Modify: `VocabCraftWidgetExtension/AppIntents/NextWordIntent.swift:10-15`
- Modify: `VocabCraftAppTests/Core/StageProgressRepositoryTests.swift:13-25`
- Modify: `VocabCraftAppTests/SettingsLocalizationTests.swift:270-280`

**Interfaces:**
- Consumes: Swift 5.10 Strict Concurrency compiler checks
- Produces: 0 warnings, 0 errors under complete data-race safety enforcement

- [ ] **Step 1: Update `Package.swift` to enable StrictConcurrency**

Add `swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]` to `VocabCraftApp`, `VocabCraftWidgetExtension`, and `VocabCraftAppTests`.

- [ ] **Step 2: Update `project.pbxproj` to add `SWIFT_STRICT_CONCURRENCY = complete;`**

Add `SWIFT_STRICT_CONCURRENCY = complete;` to Debug and Release configurations of all targets.

- [ ] **Step 3: Fix mutable static properties in `VocabularyView.swift`**

In `HeaderOffsetPreferenceKey`:
```swift
struct HeaderOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
```
In `HeaderHeightPreferenceKey`:
```swift
struct HeaderHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 50
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
```

- [ ] **Step 4: Fix mutable static properties in `MarkLearnedIntent.swift` & `NextWordIntent.swift`**

Change `static var title` and `static var description` to `static let`.

- [ ] **Step 5: Fix actor isolation in `StageProgressRepositoryTests.swift`**

Mark `StageProgressRepositoryTests` as `@MainActor` or isolate `setUp()`/`tearDown()` to match actor isolation.

- [ ] **Step 6: Fix global mutable state in `SettingsLocalizationTests.swift`**

Convert `static var catalogStrings` to safely isolated property or isolate on `@MainActor`.

- [ ] **Step 7: Verify compilation under strict concurrency**

Run: `swift build --build-tests -Xswiftc -strict-concurrency=complete`
Expected: PASS (0 warnings, 0 errors)

- [ ] **Step 8: Run all tests with strict concurrency**

Run: `swift test -Xswiftc -strict-concurrency=complete`
Expected: PASS (all tests pass)

- [ ] **Step 9: Commit Task 4**

Run:
```bash
git add Package.swift VocabCraftApp.xcodeproj/project.pbxproj VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift VocabCraftWidgetExtension/AppIntents/MarkLearnedIntent.swift VocabCraftWidgetExtension/AppIntents/NextWordIntent.swift VocabCraftAppTests/Core/StageProgressRepositoryTests.swift VocabCraftAppTests/SettingsLocalizationTests.swift
git commit -m "feat(concurrency): enable SWIFT_STRICT_CONCURRENCY complete and resolve all diagnostics"
```

---

### Task 5: Whole-Package Verification & Final Quality Gate

**Files:**
- Documentation & artifacts: `walkthrough.md`

- [ ] **Step 1: Run Root SPM Test Suite**

Run: `swift test`
Expected: 100% tests passed across all suites.

- [ ] **Step 2: Run Package Test Suites**

Run:
```bash
swift test --package-path Packages/CraftUIKit
swift test --package-path Packages/SpeechKit
```
Expected: 100% passed.

- [ ] **Step 3: Run Localization Tests**

Run: `swift test --package-path Packages/CraftUIKit --filter LocalizationTests`
Expected: 100% passed.

- [ ] **Step 4: Run SwiftLint**

Run: `swiftlint lint --quiet --no-cache`
Expected: 0 violations, 0 warnings.

- [ ] **Step 5: Run Simulator Build & Tests**

Run: `xcodebuild test-without-building -scheme VocabCraftAppTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet`
Expected: 0 compiler warnings, 100% passed.

- [ ] **Step 6: Generate and present Walkthrough artifact**
