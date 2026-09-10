# Data Safety & Concurrency Isolation (Package 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chấm dứt nguy cơ mất dữ liệu người dùng do tự động xoá SQLite store, đóng băng VersionedSchema (V1/V2) kèm kiểm thử migration, và cô lập hoàn toàn SwiftData `@Model` qua ranh giới actor bằng `UserStageProgressData: Sendable`.

**Architecture:** Áp dụng mẫu DTO Sendable (`UserStageProgressData`) ngăn chặn `@Model` rò rỉ ra Domain/Presentation; triển khai cơ chế Quarantine Backup kèm `DatabaseStoreError` và `DatabaseRecoveryView` (dùng CraftUIKit tokens, 100% song ngữ EN/VI); đóng băng models lịch sử của `SchemaV1` và `SchemaV2` với kiểm thử migration trên file SQLite thật.

**Tech Stack:** Swift 5.10 / Swift 6 Concurrency, SwiftData, SwiftUI, CraftUIKit, XCTest.

**Spec:** `docs/superpowers/specs/2026-09-09-data-safety-concurrency-design.md`

## Global Constraints
- Target iOS 17+, Swift language mode 5 tương thích Swift 6.
- Tuân thủ nghiêm ngặt AGENTS.md:
  - Zero Hardcoded Strings (100% qua `Localizable.xcstrings`, hỗ trợ cả `en` và `vi`).
  - CraftUIKit-First: sử dụng design tokens (`CraftColor`, `CraftFont`, `CraftSpacingTokens`, `CraftRadiusTokens`) và components (`CraftCard`, `CraftIcon`, `CraftIconButton`).
  - Strict Quality Gate: 0 warnings, 0 errors, 100% pass unit & integration tests.

---

### Task 1: Frozen VersionedSchema (SchemaV1, SchemaV2) & Migration Tests

**Files:**
- Create: `VocabCraftApp/Core/Database/Schemas/AppSchemaV1.swift`
- Modify: `VocabCraftApp/Core/Database/SharedAppGroupContainer.swift:7-36`
- Create: `VocabCraftAppTests/Core/Database/SchemaMigrationTests.swift`

**Interfaces:**
- Consumes: SwiftData `VersionedSchema`, `SchemaMigrationPlan`, existing top-level `@Model` classes.
- Produces: `SchemaV1` (with frozen inner models), `SchemaV2`, and `AppMigrationPlan`.

- [ ] **Step 1: Write the failing migration test**

Tạo file `VocabCraftAppTests/Core/Database/SchemaMigrationTests.swift`:
```swift
#if canImport(SwiftDataMacros)
import Foundation
import SwiftData
import XCTest
@testable import VocabCraftApp

final class SchemaMigrationTests: XCTestCase {
    private var tempDirectory: URL!
    private var storeURL: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try! FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        storeURL = tempDirectory.appendingPathComponent("test_migration.sqlite")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    @MainActor
    func test_v1_to_v2_lightweight_migration_preserves_records() throws {
        // Step 1: Initialize container with SchemaV1 and insert baseline data
        let v1Schema = Schema(versionedSchema: SchemaV1.self)
        let v1Config = ModelConfiguration(schema: v1Schema, url: storeURL)
        let v1Container = try ModelContainer(for: v1Schema, configurations: [v1Config])

        let v1Word = SchemaV1.UserWordProgress(
            wordId: 101,
            repetitionLevel: 2,
            interval: 6.0,
            easeFactor: 2.6,
            nextReviewDate: Date(),
            isBookmarked: true,
            isMastered: false,
            correctStreak: 3,
            mistakeCount: 1
        )
        v1Container.mainContext.insert(v1Word)

        let sessionID = UUID()
        let v1Session = SchemaV1.ReflexSessionLog(
            id: sessionID,
            drillId: 202,
            responseTimeMs: 850,
            accuracyScore: 0.95,
            timestamp: Date()
        )
        v1Container.mainContext.insert(v1Session)
        try v1Container.mainContext.save()

        // Step 2: Open with SchemaV2 using AppMigrationPlan
        let v2Schema = Schema(versionedSchema: SchemaV2.self)
        let v2Config = ModelConfiguration(schema: v2Schema, url: storeURL)
        let v2Container = try ModelContainer(for: v2Schema, migrationPlan: AppMigrationPlan.self, configurations: [v2Config])

        // Step 3: Verify migrated records exist and match
        let wordDesc = FetchDescriptor<UserWordProgress>(predicate: #Predicate { $0.wordId == 101 })
        let words = try v2Container.mainContext.fetch(wordDesc)
        XCTAssertEqual(words.count, 1)
        XCTAssertEqual(words.first?.wordId, 101)
        XCTAssertEqual(words.first?.correctStreak, 3)
        XCTAssertTrue(words.first?.isBookmarked ?? false)

        let sessionDesc = FetchDescriptor<ReflexSessionLog>(predicate: #Predicate { $0.id == sessionID })
        let sessions = try v2Container.mainContext.fetch(sessionDesc)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.drillId, 202)

        // Step 4: Verify new V2 model can be saved
        let stageProgress = UserStageProgress(stageId: "stage_test_1", deckId: "deck_test", isCompleted: true, score: 100)
        v2Container.mainContext.insert(stageProgress)
        try v2Container.mainContext.save()

        let stageDesc = FetchDescriptor<UserStageProgress>(predicate: #Predicate { $0.stageId == "stage_test_1" })
        let stages = try v2Container.mainContext.fetch(stageDesc)
        XCTAssertEqual(stages.count, 1)
    }
}
#endif
```

- [ ] **Step 2: Run test to verify it fails**

Chạy: `swift test --filter SchemaMigrationTests`
Kỳ vọng: Compile error do `SchemaV1.UserWordProgress` chưa được khai báo.

- [ ] **Step 3: Implement `AppSchemaV1.swift` and update `SharedAppGroupContainer.swift`**

Tạo `VocabCraftApp/Core/Database/Schemas/AppSchemaV1.swift`:
```swift
import Foundation
#if canImport(SwiftData)
import SwiftData
#endif

#if canImport(SwiftDataMacros)
public enum SchemaV1: VersionedSchema {
    public static var versionIdentifier = Schema.Version(1, 0, 0)
    public static var models: [any PersistentModel.Type] {
        [
            SchemaV1.UserWordProgress.self,
            SchemaV1.ReflexSessionLog.self,
            SchemaV1.WidgetCurrentState.self
        ]
    }

    @Model
    public final class UserWordProgress {
        @Attribute(.unique) public var wordId: Int64
        public var repetitionLevel: Int
        public var interval: Double
        public var easeFactor: Double
        public var nextReviewDate: Date
        public var isBookmarked: Bool
        public var isMastered: Bool
        public var correctStreak: Int
        public var mistakeCount: Int
        public var lastReviewedAt: Date?
        public var modeSuccessCountsRaw: String = "{}"

        public init(
            wordId: Int64,
            repetitionLevel: Int = 0,
            interval: Double = 0,
            easeFactor: Double = 2.5,
            nextReviewDate: Date = Date(),
            isBookmarked: Bool = false,
            isMastered: Bool = false,
            correctStreak: Int = 0,
            mistakeCount: Int = 0,
            lastReviewedAt: Date? = nil,
            modeSuccessCountsRaw: String = "{}"
        ) {
            self.wordId = wordId
            self.repetitionLevel = repetitionLevel
            self.interval = interval
            self.easeFactor = easeFactor
            self.nextReviewDate = nextReviewDate
            self.isBookmarked = isBookmarked
            self.isMastered = isMastered
            self.correctStreak = correctStreak
            self.mistakeCount = mistakeCount
            self.lastReviewedAt = lastReviewedAt
            self.modeSuccessCountsRaw = modeSuccessCountsRaw
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
    public final class WidgetCurrentState {
        @Attribute(.unique) public var id: String
        public var activeWord: String
        public var phonetic: String
        public var meaningVi: String
        public var exampleSentence: String
        public var updatedAt: Date

        public init(
            id: String = "current",
            activeWord: String,
            phonetic: String,
            meaningVi: String,
            exampleSentence: String,
            updatedAt: Date = Date()
        ) {
            self.id = id
            self.activeWord = activeWord
            self.phonetic = phonetic
            self.meaningVi = meaningVi
            self.exampleSentence = exampleSentence
            self.updatedAt = updatedAt
        }
    }
}
#endif
```

Trong `SharedAppGroupContainer.swift`, bỏ định nghĩa cũ của `SchemaV1` và giữ `SchemaV2` cùng `AppMigrationPlan`.

- [ ] **Step 4: Run test to verify it passes**

Chạy: `swift test --filter SchemaMigrationTests`
Kỳ vọng: PASS (100%).

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Core/Database/Schemas/AppSchemaV1.swift VocabCraftApp/Core/Database/SharedAppGroupContainer.swift VocabCraftAppTests/Core/Database/SchemaMigrationTests.swift
git commit -m "feat(database): freeze SchemaV1 and add lightweight migration test"
```

---

### Task 2: Sendable DTO `UserStageProgressData` & Actor Isolation

**Files:**
- Create: `VocabCraftApp/Domain/Models/UserStageProgressData.swift`
- Modify: `VocabCraftApp/Core/Database/SwiftDataModels.swift:71-95`
- Modify: `VocabCraftApp/Core/Database/Repositories/StageProgressRepository.swift:1-190`
- Modify: `VocabCraftApp/Features/Homepage/ViewModels/LearningPathDataMapper.swift:17-230`
- Modify: `VocabCraftApp/Domain/UseCases/FetchLearningPathUseCase.swift:1-66`
- Create: `VocabCraftAppTests/Core/Database/StageProgressRepositoryConcurrencyTests.swift`
- Modify: `VocabCraftAppTests/Core/StageProgressRepositoryTests.swift`
- Modify: `VocabCraftAppTests/Features/Homepage/LearningPathDataMapperTests.swift`

**Interfaces:**
- Consumes: `@Model UserStageProgress`.
- Produces: `UserStageProgressData: Sendable, Equatable, Hashable, Identifiable`.
- Updates `StageProgressRepositoryProtocol`:
  - `fetchStageProgress(stageId: String) async throws -> UserStageProgressData?`
  - `fetchAllStageProgress() async throws -> [UserStageProgressData]`

- [ ] **Step 1: Write failing concurrency and repository test**

Tạo `VocabCraftAppTests/Core/Database/StageProgressRepositoryConcurrencyTests.swift`:
```swift
#if canImport(SwiftDataMacros)
import Foundation
import SwiftData
import XCTest
@testable import VocabCraftApp

final class StageProgressRepositoryConcurrencyTests: XCTestCase {
    @MainActor
    func test_concurrent_reads_and_writes_return_sendable_snapshots() async throws {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let repo: StageProgressRepositoryProtocol = StageProgressRepositoryImpl(modelContext: container.mainContext)

        // Seed initial stage
        try await repo.saveStageProgress(stageId: "stage_0", deckId: "deck_0", isCompleted: false, score: 0, progressFraction: 0.0)

        // Execute concurrent operations across multiple tasks
        await withTaskGroup(of: Void.self) { group in
            for i in 1...10 {
                group.addTask {
                    try? await repo.saveStageProgress(
                        stageId: "stage_\(i)",
                        deckId: "deck_0",
                        isCompleted: true,
                        score: i * 10,
                        progressFraction: 1.0
                    )
                }
            }
        }

        let allProgress: [UserStageProgressData] = try await repo.fetchAllStageProgress()
        XCTAssertGreaterThanOrEqual(allProgress.count, 10)
        XCTAssertTrue(allProgress.allSatisfy { $0 is Sendable })
    }
}
#endif
```

- [ ] **Step 2: Run test to verify it fails**

Chạy: `swift test --filter StageProgressRepositoryConcurrencyTests`
Kỳ vọng: FAIL (kiểu `UserStageProgressData` chưa tồn tại).

- [ ] **Step 3: Implement `UserStageProgressData.swift` and update repository & mapper**

Tạo `VocabCraftApp/Domain/Models/UserStageProgressData.swift`:
```swift
import Foundation

public struct UserStageProgressData: Sendable, Equatable, Hashable, Identifiable {
    public var id: String { stageId }
    public let stageId: String
    public let deckId: String
    public let isCompleted: Bool
    public let score: Int
    public let progressFraction: Double
    public let completedAt: Date

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
```

Thêm extension chuyển đổi trong `SwiftDataModels.swift`:
```swift
extension UserStageProgress {
    public func toData() -> UserStageProgressData {
        UserStageProgressData(
            stageId: stageId,
            deckId: deckId,
            isCompleted: isCompleted,
            score: score,
            progressFraction: progressFraction,
            completedAt: completedAt
        )
    }
}
```

Cập nhật `StageProgressRepositoryProtocol` và `StageProgressRepositoryImpl`:
- `fetchStageProgress` trả về `UserStageProgressData?`
- `fetchAllStageProgress` trả về `[UserStageProgressData]`
- Cập nhật `MockStageProgressRepository` lưu trữ `[String: UserStageProgressData]`.
- Cập nhật `LearningPathDataMapper.map(..., progressList: [UserStageProgressData])`.
- Cập nhật các test sites liên quan trong `StageProgressRepositoryTests.swift` và `LearningPathDataMapperTests.swift`.

- [ ] **Step 4: Run tests to verify they pass**

Chạy: `swift test --filter StageProgress`
Kỳ vọng: PASS (100%).

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Domain/Models/UserStageProgressData.swift VocabCraftApp/Core/Database/ VocabCraftApp/Features/Homepage/ VocabCraftApp/Domain/UseCases/ VocabCraftAppTests/
git commit -m "feat(concurrency): isolate UserStageProgress behind Sendable UserStageProgressData"
```

---

### Task 3: Safe Quarantine Store Recovery & Typed Errors

**Files:**
- Create: `VocabCraftApp/Core/Database/DatabaseStoreError.swift`
- Modify: `VocabCraftApp/Core/Database/SharedAppGroupContainer.swift:52-100`
- Create: `VocabCraftAppTests/Core/Database/DatabaseQuarantineTests.swift`

**Interfaces:**
- Consumes: `FileManager`, SQLite file URLs.
- Produces: `DatabaseStoreError`, `SharedAppGroupContainer.createContainer()`, `SharedAppGroupContainer.resetStoreWithQuarantine()`.

- [ ] **Step 1: Write failing quarantine and failure recovery tests**

Tạo `VocabCraftAppTests/Core/Database/DatabaseQuarantineTests.swift`:
```swift
#if canImport(SwiftDataMacros)
import Foundation
import SwiftData
import XCTest
@testable import VocabCraftApp

final class DatabaseQuarantineTests: XCTestCase {
    private var tempDirectory: URL!
    private var corruptStoreURL: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try! FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        corruptStoreURL = tempDirectory.appendingPathComponent("corrupt.sqlite")
        // Write corrupt junk data
        try! "CORRUPT_INVALID_SQLITE_HEADER".write(to: corruptStoreURL, atomically: true, encoding: .utf8)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    func test_corrupt_store_triggers_quarantine_and_throws_typed_error() {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let config = ModelConfiguration(schema: schema, url: corruptStoreURL)

        XCTAssertThrowsError(
            try SharedAppGroupContainer.createContainer(configuration: config, storeURL: corruptStoreURL)
        ) { error in
            guard let dbError = error as? DatabaseStoreError else {
                XCTFail("Expected DatabaseStoreError, got \(error)")
                return
            }
            switch dbError {
            case .storeInitializationFailed(_, let backupURL):
                XCTAssertNotNil(backupURL)
                XCTAssertTrue(FileManager.default.fileExists(atPath: backupURL!.path))
            default:
                XCTFail("Unexpected error case: \(dbError)")
            }
        }

        // Original file must NOT be deleted
        XCTAssertTrue(FileManager.default.fileExists(atPath: corruptStoreURL.path))
    }
}
#endif
```

- [ ] **Step 2: Run test to verify it fails**

Chạy: `swift test --filter DatabaseQuarantineTests`
Kỳ vọng: FAIL (`DatabaseStoreError` chưa tồn tại).

- [ ] **Step 3: Implement `DatabaseStoreError.swift` and update `SharedAppGroupContainer.swift`**

Tạo `VocabCraftApp/Core/Database/DatabaseStoreError.swift`:
```swift
import Foundation

public enum DatabaseStoreError: LocalizedError, Sendable, Equatable {
    case storeInitializationFailed(description: String, backupURL: URL?)
    case quarantineBackupFailed(description: String)
    case manualResetFailed(description: String)

    public var errorDescription: String? {
        switch self {
        case .storeInitializationFailed(let desc, let backupURL):
            if let backupURL {
                return String(localized: "app.database.error.init_failed_backed_up", defaultValue: "Failed to load database. Backup created at \(backupURL.lastPathComponent): \(desc)")
            } else {
                return String(localized: "app.database.error.init_failed", defaultValue: "Failed to load database: \(desc)")
            }
        case .quarantineBackupFailed(let desc):
            return String(localized: "app.database.error.backup_failed", defaultValue: "Failed to create quarantine backup: \(desc)")
        case .manualResetFailed(let desc):
            return String(localized: "app.database.error.reset_failed", defaultValue: "Failed to reset database: \(desc)")
        }
    }
}
```

Cập nhật `SharedAppGroupContainer.swift`:
- Bỏ đoạn `try? FileManager.default.removeItem(...)` trong catch block của `createContainer`.
- Thêm `quarantineCorruptStoreFiles(from storeURL: URL) -> URL?`.
- Thêm `resetStoreWithQuarantine() throws -> ModelContainer`.
- Ném `DatabaseStoreError.storeInitializationFailed(description: error.localizedDescription, backupURL: backupURL)`.

- [ ] **Step 4: Run test to verify it passes**

Chạy: `swift test --filter DatabaseQuarantineTests`
Kỳ vọng: PASS (100%).

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Core/Database/DatabaseStoreError.swift VocabCraftApp/Core/Database/SharedAppGroupContainer.swift VocabCraftAppTests/Core/Database/DatabaseQuarantineTests.swift
git commit -m "feat(database): implement quarantine backup and typed DatabaseStoreError"
```

---

### Task 4: App Bootstrapper, Recovery Flow & `DatabaseRecoveryView`

**Files:**
- Create: `VocabCraftApp/App/Bootstrap/AppBootstrapper.swift`
- Create: `VocabCraftApp/App/Views/DatabaseRecoveryView.swift`
- Modify: `VocabCraftApp/App/VocabCraftApp.swift:18-55`
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings` (Bổ sung key EN và VI)
- Create: `VocabCraftAppTests/App/AppBootstrapperTests.swift`

**Interfaces:**
- Consumes: `SharedAppGroupContainer`, `DatabaseStoreError`, `CraftUIKit` design tokens.
- Produces: `AppBootstrapper`, `DatabaseRecoveryView`, localized error & recovery strings.

- [ ] **Step 1: Add localization keys with 100% EN & VI parity**

Bổ sung vào `VocabCraftApp/Resources/Localizable.xcstrings`:
- `app.database.error.init_failed_backed_up`
- `app.database.error.init_failed`
- `app.database.error.backup_failed`
- `app.database.error.reset_failed`
- `app.recovery.title` (EN: "Data Loading Error" | VI: "Lỗi tải dữ liệu")
- `app.recovery.message` (EN: "Unable to load your study progress. A safety backup has been created." | VI: "Không thể tải tiến độ học tập. Bản sao lưu an toàn đã được khởi tạo.")
- `app.recovery.retry_button` (EN: "Retry" | VI: "Thử lại")
- `app.recovery.reset_button` (EN: "Reset Database" | VI: "Đặt lại dữ liệu")
- `app.recovery.reset_confirm_title` (EN: "Reset Database?" | VI: "Đặt lại cơ sở dữ liệu?")
- `app.recovery.reset_confirm_message` (EN: "Your previous data was securely backed up. Are you sure you want to start fresh?" | VI: "Dữ liệu cũ đã được sao lưu an toàn. Bạn có chắc chắn muốn tạo mới không?")
- `app.recovery.cancel_button` (EN: "Cancel" | VI: "Huỷ")

- [ ] **Step 2: Write failing Bootstrapper unit test**

Tạo `VocabCraftAppTests/App/AppBootstrapperTests.swift`:
```swift
#if canImport(SwiftDataMacros)
import Foundation
import SwiftData
import XCTest
@testable import VocabCraftApp

@MainActor
final class AppBootstrapperTests: XCTestCase {
    func test_bootstrapper_initial_state_transitions_to_ready_with_memory_container() {
        let sut = AppBootstrapper(inMemoryOnly: true)
        XCTAssertEqual(sut.state, .loading)
        sut.bootstrap()
        switch sut.state {
        case .ready:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected .ready, got \(sut.state)")
        }
    }

    func test_bootstrapper_transitions_to_error_when_container_fails() {
        let sut = AppBootstrapper(containerProvider: {
            throw DatabaseStoreError.storeInitializationFailed(description: "Mock Error", backupURL: nil)
        })
        sut.bootstrap()
        switch sut.state {
        case .error(let error):
            XCTAssertEqual(error, DatabaseStoreError.storeInitializationFailed(description: "Mock Error", backupURL: nil))
        default:
            XCTFail("Expected .error, got \(sut.state)")
        }
    }
}
#endif
```

- [ ] **Step 3: Implement `AppBootstrapper.swift` and `DatabaseRecoveryView.swift`**

Tạo `VocabCraftApp/App/Bootstrap/AppBootstrapper.swift`:
```swift
import Foundation
import Observation
import SwiftData

@Observable
@MainActor
public final class AppBootstrapper {
    public enum BootState: Equatable {
        case loading
        case ready
        case error(DatabaseStoreError)
    }

    public var state: BootState = .loading
    public private(set) var container: ModelContainer?
    public private(set) var appContainer: AppContainer?

    private let inMemoryOnly: Bool
    private let containerProvider: (() throws -> ModelContainer)?

    public init(
        inMemoryOnly: Bool = false,
        containerProvider: (() throws -> ModelContainer)? = nil
    ) {
        self.inMemoryOnly = inMemoryOnly
        self.containerProvider = containerProvider
    }

    public func bootstrap() {
        do {
            let resolvedContainer: ModelContainer
            if let customProvider = containerProvider {
                resolvedContainer = try customProvider()
            } else {
                resolvedContainer = try SharedAppGroupContainer.createContainer(inMemory: inMemoryOnly)
            }
            self.container = resolvedContainer
            let engine = DatasetEngine()
            self.appContainer = AppContainer(datasetEngine: engine, modelContainer: resolvedContainer)
            self.state = .ready
        } catch let error as DatabaseStoreError {
            self.state = .error(error)
        } catch {
            self.state = .error(.storeInitializationFailed(description: error.localizedDescription, backupURL: nil))
        }
    }

    public func retry() {
        self.state = .loading
        bootstrap()
    }

    public func confirmReset() {
        self.state = .loading
        do {
            let freshContainer = try SharedAppGroupContainer.resetStoreWithQuarantine()
            self.container = freshContainer
            let engine = DatasetEngine()
            self.appContainer = AppContainer(datasetEngine: engine, modelContainer: freshContainer)
            self.state = .ready
        } catch {
            self.state = .error(.manualResetFailed(description: error.localizedDescription))
        }
    }
}
```

Tạo `VocabCraftApp/App/Views/DatabaseRecoveryView.swift`:
Sử dụng `CraftCard`, `CraftIcon`, `CraftIconButton`, token spacing & colors, confirmation dialog và 100% localization keys.

Cập nhật `VocabCraftApp.swift` để sử dụng `AppBootstrapper` quản lý trạng thái, hiển thị `DatabaseRecoveryView` khi gặp `.error`.

- [ ] **Step 4: Run tests to verify they pass**

Chạy: `swift test --filter AppBootstrapperTests`
Kỳ vọng: PASS (100%).

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/App/ VocabCraftApp/Resources/Localizable.xcstrings VocabCraftAppTests/App/AppBootstrapperTests.swift
git commit -m "feat(app): add AppBootstrapper and DatabaseRecoveryView"
```

---

### Task 5: End-to-End Verification & Quality Gate

**Files:**
- Verification only

- [ ] **Step 1: Run complete SwiftPM test suite**

Chạy: `swift test`
Kỳ vọng: 100% test cases pass (Root, CraftUIKit, SpeechKit).

- [ ] **Step 2: Run SwiftLint**

Chạy: `swiftlint lint --quiet --no-cache`
Kỳ vọng: Exit 0, không có warnings hoặc errors.

- [ ] **Step 3: Build & Test on Xcode Simulator**

Chạy build và test target `VocabCraftApp` trên iOS Simulator thông qua MCP hoặc `xcodebuild`.
Kỳ vọng: 0 compiler warnings, 0 compiler errors, 100% test pass.

- [ ] **Step 4: Verify Git Working Tree Cleanliness**

Kiểm tra `git status` và `git diff` đảm bảo không có file sinh tự động ngoài ý muốn.
Commit hoặc hoàn thiện message tổng kết.
