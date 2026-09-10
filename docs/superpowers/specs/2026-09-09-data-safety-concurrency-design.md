# Thiết kế Kiến trúc: An toàn Dữ liệu & Cô lập Concurrency (Gói 1)

- **Ngày tạo**: 09/09/2026
- **Trạng thái**: Bản thảo thiết kế (Design Spec)
- **Thuộc gói**: Gói 1 trong lộ trình cải thiện kiến trúc theo báo cáo audit [`2026-09-09-architecture-performance-audit.md`](../../reviews/2026-09-09-architecture-performance-audit.md)
- **Vấn đề xử lý**:
  - P1 #1: Recovery database có thể xoá tiến độ học & schema versioning chưa đóng băng.
  - P1 #3: SwiftData model (`UserStageProgress`) vượt ranh giới actor trong use case.

---

## 1. Bối cảnh & Mục tiêu

Trong đợt audit kiến trúc ngày 09/09/2026, hai vấn đề ưu tiên cao (P1) đã được xác định:
1. **Chính sách khôi phục SQLite store tự động xoá file**: `SharedAppGroupContainer.createContainer()` tự động `removeItem` các file `.sqlite`, `.sqlite-shm`, `.sqlite-wal` khi gặp lỗi mở hoặc migration, dẫn đến rủi ro xoá sạch tiến độ học tập. Đồng thời, `VocabCraftApp.init()` âm thầm fallback sang in-memory container khi persistent container lỗi, tạo ấn tượng sai lệch rằng dữ liệu vẫn đang được lưu. Các `VersionedSchema` (`SchemaV1`, `SchemaV2`) đang cùng trỏ vào các model mutable dùng chung ở top-level, vi phạm nguyên tắc đóng băng schema của SwiftData.
2. **Model SwiftData vượt ranh giới Actor**: `StageProgressRepositoryProtocol.fetchAllStageProgress()` trả về `[UserStageProgress]` là các `@Model` thuộc context của MainActor. `FetchLearningPathUseCase.execute()` (non-isolated `Sendable`) nhận các model này qua `async let` và chuyển tiếp cho `LearningPathDataMapper`, vi phạm ranh giới cách ly dữ liệu trong Swift 6 Concurrency.

### Mục tiêu thiết kế
- **Tuyệt đối không tự ý xoá dữ liệu**: Lưu trữ bản sao cách ly (Quarantine Backup) khi store gặp sự cố, ném lỗi có kiểu `DatabaseStoreError`.
- **Minh bạch trạng thái ứng dụng**: Loại bỏ fallback in-memory ngầm; cung cấp màn hình `DatabaseRecoveryView` chuyên dụng để người dùng chủ động chọn Thử lại hoặc Xác nhận đặt lại dữ liệu.
- **Đóng băng VersionedSchema**: Tạo độc lập `SchemaV1` và `SchemaV2` với các model bất biến theo tài liệu chuẩn của Apple SwiftData; xây dựng test migration với fixture SQLite V1 thật.
- **Cô lập Concurrency 100% bằng Sendable DTO**: Định nghĩa `UserStageProgressData: Sendable` để toàn bộ dữ liệu đi qua ranh giới actor đều là value type, không để `@Model` rò rỉ ra Domain hay Presentation.

---

## 2. Thiết kế Chi tiết Kiến trúc

### 2.1 Đóng băng VersionedSchema (`SchemaV1` & `SchemaV2`)

Các model của `SchemaV1` được khai báo bên trong namespace `SchemaV1`:

```swift
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
```

`SchemaV2` đại diện cho phiên bản database hiện hành của ứng dụng, bổ sung `UserStageProgress` và `QuickReflexAttemptRecord`:

```swift
public enum SchemaV2: VersionedSchema {
    public static var versionIdentifier = Schema.Version(2, 0, 0)
    public static var models: [any PersistentModel.Type] {
        [
            UserWordProgress.self,
            UserStageProgress.self,
            ReflexSessionLog.self,
            WidgetCurrentState.self,
            QuickReflexAttemptRecord.self
        ]
    }
}
```

Kế hoạch di trú:
```swift
public enum AppMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }
    public static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)
        ]
    }
}
```

---

### 2.2 An toàn Store & Phục hồi lỗi có kiểm soát

#### 1. Định nghĩa lỗi `DatabaseStoreError`
```swift
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

#### 2. `SharedAppGroupContainer`: Quy trình cách ly Quarantine
- Bỏ logic tự xoá trong `createContainer`.
- Khi khởi tạo `ModelContainer` thất bại:
  1. Gọi `quarantineCorruptStoreFiles(from: storeURL) -> URL?`: Copy `.sqlite`, `.sqlite-shm`, `.sqlite-wal` sang thư mục backup dạng `user_progress.sqlite.corrupt.<timestamp>`.
  2. Ném lỗi `DatabaseStoreError.storeInitializationFailed(description: error.localizedDescription, backupURL: backupURL)`.
- Cung cấp hàm `resetStoreWithQuarantine() throws -> ModelContainer`: Hàm này chỉ được kích hoạt khi người dùng xác nhận Reset trên UI. Trước khi xoá file để tạo lại container mới, nó vẫn đảm bảo file cũ đã được sao lưu cách ly an toàn.

#### 3. Điều phối trạng thái khởi động tại `VocabCraftApp`
Thay vì gán `container` trực tiếp trong `init()` với fallback in-memory:
- Tạo `@Observable @MainActor final class AppBootstrapper`:
  - `state: .loading`, `.ready(container: ModelContainer, appContainer: AppContainer)`, `.error(DatabaseStoreError)`.
  - Hàm `retry()`: Gọi lại việc nạp persistent container.
  - Hàm `confirmReset()`: Gọi `SharedAppGroupContainer.resetStoreWithQuarantine()` và chuyển state về `.ready`.
- UI Root:
  - Khi `.loading`: Hiển thị Splash / Progress view.
  - Khi `.ready`: Hiển thị Main View (`HomepageView`).
  - Khi `.error(let error)`: Hiển thị `DatabaseRecoveryView`.

#### 4. Giao diện Phục hồi `DatabaseRecoveryView`
- **Tuân thủ CraftUIKit**:
  - Dùng `CraftCard` làm khung chứa thông báo trung tâm.
  - Dùng `CraftIcon` (`exclamationmark.triangle.fill`, semantic tint `CraftColor.warning`).
  - Dùng token typography (`CraftFont.headline`, `CraftFont.body`, `CraftFont.caption`).
  - Dùng token spacing (`CraftSpacingTokens.lg`, `CraftSpacingTokens.xl`).
- **Nút tương tác**:
  - Nút **"Thử lại"** (Primary): Kích hoạt `bootstrapper.retry()`.
  - Nút **"Đặt lại dữ liệu"** (Destructive): Mở confirmation dialog:
    - Tiêu đề: `app.recovery.reset_confirm_title`
    - Nội dung: `app.recovery.reset_confirm_message` ("Tiến độ cũ của bạn đã được sao lưu an toàn. Bạn có muốn đặt lại cơ sở dữ liệu để tiếp tục không?")
    - Xác nhận: Kích hoạt `bootstrapper.confirmReset()`.
- **Localization**: 100% các chuỗi trong `DatabaseRecoveryView` đều dùng key `app.recovery.*` khai báo trong `VocabCraftApp/Resources/Localizable.xcstrings` với đầy đủ bản dịch tiếng Anh và tiếng Việt.

---

### 2.2 Sendable DTO & Concurrency Boundary

#### 1. Struct `UserStageProgressData`
Tạo struct giá trị bất biến, tuân thủ `Sendable`:

```swift
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

#### 2. Cập nhật `StageProgressRepositoryProtocol`
Giao thức chỉ trả về DTO:
```swift
public protocol StageProgressRepositoryProtocol: Sendable {
    @MainActor func fetchStageProgress(stageId: String) async throws -> UserStageProgressData?
    @MainActor func fetchCompletedStageIds(deckId: String) async throws -> Set<String>
    @MainActor func fetchAllStageProgress() async throws -> [UserStageProgressData]
    @MainActor func saveStageProgress(
        stageId: String,
        deckId: String,
        isCompleted: Bool,
        score: Int,
        progressFraction: Double
    ) async throws
    @MainActor func saveStageProgress(
        stageId: String,
        deckId: String,
        isCompleted: Bool,
        score: Int
    ) async throws
}
```

`StageProgressRepositoryImpl` query `@Model UserStageProgress` trên `@MainActor` và map sang `UserStageProgressData` trước khi return.

#### 3. Đồng bộ với `FetchLearningPathUseCase` & `LearningPathDataMapper`
- `FetchLearningPathUseCase.execute()` gọi `stageRepo.fetchAllStageProgress()` qua `async let` hoàn toàn an toàn do nhận về `[UserStageProgressData]` tuân thủ `Sendable`.
- `LearningPathDataMapper.map` nhận `progressList: [UserStageProgressData]` và xử lý tương thích 100% với các thuộc tính hiện hữu.

---

## 3. Kế hoạch Kiểm thử & Xác minh

### 3.1 Migration Tests (`SchemaMigrationTests`)
- Sử dụng temporary directory để tạo SQLite container chạy `SchemaV1`.
- Ghi 3 bản ghi word progress, 2 bản ghi reflex session log, 1 bản ghi widget state.
- Đóng container V1 và nạp lại chính file SQLite đó bằng `SchemaV2` cùng `AppMigrationPlan`.
- Kiểm tra toàn bộ thuộc tính của dữ liệu cũ được giữ nguyên vẹn; thử ghi thêm `UserStageProgress` và `QuickReflexAttemptRecord` mới thành công.

### 3.2 Quarantine & Recovery Tests (`DatabaseQuarantineTests`)
- Tạo file `.sqlite` chứa dữ liệu byte ngẫu nhiên (hỏng).
- Gọi `SharedAppGroupContainer.createContainer()`.
- Xác nhận hàm ném lỗi `DatabaseStoreError.storeInitializationFailed`.
- Xác nhận file `.corrupt.<timestamp>.sqlite` được tạo ra và file gốc không bị mất.
- Gọi `resetStoreWithQuarantine()` xác nhận tạo thành công container mới sạch và có thể đọc/ghi.

### 3.3 Concurrency Tests (`StageProgressRepositoryConcurrencyTests`)
- Chạy 20 Task song song thực hiện đọc và ghi stage progress.
- Xác minh không có deadlock, race condition hoặc vi phạm actor isolation.

### 3.4 Quality Gate Verification
- `swift test` (Toàn bộ test suites pass 100%).
- `swiftlint --quiet --no-cache` (0 warnings, 0 errors).
- Build Xcode (0 compiler warnings, 0 errors).
- Kiểm tra Localization song ngữ EN/VI đầy đủ.
