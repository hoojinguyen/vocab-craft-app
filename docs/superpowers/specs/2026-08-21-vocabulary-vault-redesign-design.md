# Đặc tả Thiết kế: Tái cấu trúc Kho từ (Vocabulary Vault) & Chế độ Luyện tập Nhanh Ngẫu nhiên (Mixed Reflex Drill)

- **Ngày tạo**: 2026-08-21
- **Trạng thái**: Đã thống nhất (Approved)
- **Kiến trúc áp dụng**: Clean Architecture + MVVM với Observation (`@Observable`) + Swift Concurrency (Swift 6)
- **Nền tảng mục tiêu**: iOS 17+ / iOS 26+ (SwiftUI)

---

## 1. Tổng quan & Mục tiêu (Overview & Objectives)

### 1.1. Bối cảnh
Trước đây, màn hình "Kho từ" trong ứng dụng bị phân mảnh giữa 2 tab "Kho từ cá nhân" và "Bộ từ chủ đề". Trải nghiệm luyện tập còn hạn chế ở các chế độ đơn lẻ được chọn cố định trước phiên học.

### 1.2. Mục tiêu thay đổi
1. **Tái cấu trúc Kho từ (Word Bank / Library)**: Trở thành trung tâm quản lý từ vựng tinh gọn, duy nhất với 3 trạng thái phân loại:
   - **Chưa thuộc (Unknown / Not Mastered)**: Từ mới học hoặc làm sai trong quá trình luyện tập.
   - **Đã thuộc (Known / Mastered)**: Từ đã đạt chuẩn thành thạo ($\ge 3$ lần đúng liên tiếp trên $\ge 2$ chế độ).
   - **Đã lưu (Bookmarked)**: Các từ người dùng gắn cờ yêu thích.
2. **Loại bỏ phân mảnh Tab**: Tách toàn bộ "Chặng học / Bộ từ chủ đề" ra khỏi Kho từ để thiết kế lại và đưa lên Home Screen *(được ghi nhận trong TODO cho session sau)*.
3. **Màn hình Chọn từ Luyện tập (Practice Selection)**: Cho phép người dùng tick chọn thủ công các từ hoặc bấm "Chọn tất cả" (`Add all`) để bắt đầu bài luyện.
4. **Chế độ Luyện tập Nhanh Đa Giác Quan (Mixed Reflex Drill)**: Khi luyện tập danh sách từ đã chọn, mỗi từ được gán **ngẫu nhiên 1 trong 4 chế độ** (*Trắc nghiệm*, *Luyện nói*, *Gõ từ*, *Phản xạ nghe*). Áp dụng cơ chế **Loop-back**: từ làm sai hoặc hết giờ sẽ được đẩy xuống cuối hàng đợi với một chế độ ngẫu nhiên mới cho đến khi hoàn thành toàn bộ.

---

## 2. Tiêu chuẩn Thiết kế UI/UX & Chống AI-Slop (Design Standards)

### 2.1. Quy tắc Chống AI-Slop (Anti-AI-Slop Rules)
- 🚫 **Tuyệt đối không lạm dụng icon**: Không rải icon trang trí tràn lan; ưu tiên phân cấp chữ (Typography) rõ ràng và khoảng trắng tự nhiên.
- 🚫 **Chỉ sử dụng 100% SF Symbols nguyên bản của Apple**: Tuyệt đối không dùng bộ icon ngoài hoặc file vector custom không chuẩn.
- 🚫 **Không sử dụng gradient tím-xanh rẻ tiền**: Sử dụng bảng màu Semantic chuẩn của VocabCraft (`Color.vocabCanvas`, `Color.vocabSurfaceCard`, `Color.vocabAccent`, `Color.vocabHairline`).
- ✅ **Đảm bảo Touch Target $\ge 44 \times 44\text{ pt}$** cho tất cả các nút bấm, checkbox và icon tương tác.

### 2.2. Điểm nhấn Đặc trưng (Signature Details)
1. **Kho từ**: Thẻ Carousel xem nhanh trên cùng (`TabView` với `.tabViewStyle(.page)`), highlight từ vựng trong câu mẫu và hỗ trợ nghe phát âm nhanh.
2. **Luyện tập nhanh**: Đồng hồ phản xạ đổi màu động (*Dynamic Pulse Timer*), chuyển màu từ `vocabAccent` $\rightarrow$ Vàng hổ phách $\rightarrow$ Đỏ san hô kèm nhịp thở nhẹ khi thời gian sắp hết.

---

## 3. Kiến trúc Hệ thống & Mô hình Dữ liệu (System Architecture)

```
┌─────────────────────────────────────────────────────────────────┐
│                       Presentation Layer                        │
│  - VocabularyView / PersonalVaultViewModel                      │
│  - PracticeSelectionView                                        │
│  - MixedReflexDrillView / MixedReflexDrillViewModel             │
│  - MixedReflexSummaryView                                       │
└────────────────────────────────┬────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                          Domain Layer                           │
│  - Entities: VaultWordItem, MixedReflexDrillItem                │
│  - Policies: MasteryEvaluationPolicy (Pure Business Rule)       │
│  - Use Cases: FetchPersonalVaultUseCase, ToggleBookmarkUseCase, │
│               RecordDrillAttemptUseCase, GenerateQueueUseCase   │
└────────────────────────────────┬────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                           Data Layer                            │
│  - Repositories: UserProgressRepositoryImpl, VocabularyRepoImpl │
│  - Local Storage: SwiftData (UserWordProgressEntity)            │
└─────────────────────────────────────────────────────────────────┘
```

### 3.1. Domain Entities & Policies

#### `VaultWordItem` (Domain Entity - Bất biến)
```swift
public struct VaultWordItem: Identifiable, Sendable, Equatable {
    public let id: Int64
    public let lemma: String
    public let pos: String
    public let phonetic: String
    public let definitionVi: String
    public let exampleSentenceEn: String
    public let exampleSentenceVi: String
    public let cefrLevel: String?
    
    // Tiến độ & Trạng thái (Bất biến)
    public let isMastered: Bool
    public let isBookmarked: Bool
    public let correctStreak: Int
    public let practicedModes: Set<ReflexBlitzMode>
    public let lastPracticedAt: Date?
}
```

#### `MasteryEvaluationPolicy` (Chính sách Đánh giá Thành thạo)
```swift
public struct MasteryEvaluationPolicy: Sendable {
    public static let requiredStreakForMastery = 3
    public static let requiredDistinctModesForMastery = 2

    public static func evaluate(
        currentStreak: Int,
        practicedModes: Set<ReflexBlitzMode>,
        isCorrect: Bool,
        currentMode: ReflexBlitzMode
    ) -> (newStreak: Int, newPracticedModes: Set<ReflexBlitzMode>, isMastered: Bool) {
        if !isCorrect {
            // Sai 1 lần: Reset streak về 0, chuyển ngay về Chưa thuộc
            return (newStreak: 0, newPracticedModes: [], isMastered: false)
        }
        
        let newStreak = currentStreak + 1
        var newModes = practicedModes
        newModes.insert(currentMode)
        
        let isMastered = (newStreak >= requiredStreakForMastery) && 
                         (newModes.count >= requiredDistinctModesForMastery)
        
        return (newStreak: newStreak, newPracticedModes: newModes, isMastered: isMastered)
    }
}
```

#### `MixedReflexDrillItem` (Phần tử trong Hàng đợi Luyện tập)
```swift
public struct MixedReflexDrillItem: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let word: VaultWordItem
    public let assignedMode: ReflexBlitzMode
    public let isRetry: Bool
    
    public init(id: UUID = UUID(), word: VaultWordItem, assignedMode: ReflexBlitzMode, isRetry: Bool = false) {
        self.id = id
        self.word = word
        self.assignedMode = assignedMode
        self.isRetry = isRetry
    }
}
```

---

## 4. Chi tiết Giao diện & Tương tác UI/UX

### 4.1. Màn hình Kho từ (`VocabularyView`)
- **Header**: Tiêu đề "Kho từ", thanh tìm kiếm `TextField` bo góc có icon `magnifyingglass`.
- **Bộ lọc Segmented (3 Tabs)**:
  - `Chưa thuộc` (kèm số lượng, ví dụ: 12)
  - `Đã thuộc` (kèm số lượng, ví dụ: 35)
  - `Đã lưu` (kèm số lượng, ví dụ: 8)
- **Nút CTA "LUYỆN TẬP"**: Đặt ngay dưới bộ lọc, full-width, góc bo 16pt, hiệu ứng màu chủ đạo thương hiệu. Bấm vào sẽ mở modal `PracticeSelectionView`.
- **Top Carousel Card**: `TabView` với `.tabViewStyle(.page)` hiển thị thẻ từ mẫu dạng flashcard lướt ngang.
- **Danh sách từ vựng**: `ScrollView` + `LazyVStack`, mỗi hàng hiển thị từ, phiên âm, từ loại, nghĩa tóm tắt, icon loa phát âm và icon trạng thái (`checkmark.circle.fill` nếu đã thuộc).

### 4.2. Màn hình Chọn từ Luyện tập (`PracticeSelectionView`)
- **Header**: Nút quay lại (`chevron.left`), tiêu đề "Luyện tập".
- **Tab chuyển danh mục**: Cho phép lọc nhanh danh sách từ để chọn (*Chưa thuộc* / *Đã thuộc* / *Đã lưu*).
- **Thanh thao tác nhanh**: Hiển thị tổng số từ và nút **"Chọn tất cả" / "Bỏ chọn tất cả"** (`Add all / Deselect all`).
- **Danh sách chọn từ**: Mỗi hàng có checkbox tròn bên phải (`circle` $\leftrightarrow$ `checkmark.circle.fill`), hỗ trợ Spring Animation và Haptic Feedback.
- **Nút bấm Ghim đáy (`.safeAreaInset(edge: .bottom)`)**:
  - Khi chưa chọn từ: Disabled với chữ *"VUI LÒNG CHỌN TỪ ĐỂ BẮT ĐẦU"*.
  - Khi đã chọn $\ge 1$ từ: Active với chữ *"BẮT ĐẦU LUYỆN TẬP (X TỪ)"*.

### 4.3. Màn hình Luyện tập Nhanh (`MixedReflexDrillView`)
- **Header**: Nút thoát (`xmark`), thanh tiến trình `ProgressView`, bộ đếm `⚡️ Combo xN`, và thanh đếm ngược thời gian phản xạ.
- **Dynamic Mode Badge**: Hiển thị chế độ ngẫu nhiên của câu:
  1. 🎯 **Trắc nghiệm (`.multipleChoice`)** (4.5s): 4 lựa chọn phản xạ nhanh.
  2. 🎙️ **Luyện nói (`.speaking`)** (6.0s): Ghi âm giọng nói liên tục, visualizer sóng âm và highlight từ phát âm đúng.
  3. ⌨️ **Gõ từ (`.typing`)** (7.5s): Điền từ vào chỗ trống câu mẫu, bàn phím tự focus.
  4. 🎧 **Phản xạ nghe (`.listening`)** (5.5s): Phát audio TTS tự động, chọn nghĩa hoặc từ đúng.
- **Cơ chế Loop-Back**:
  - Trả lời sai hoặc hết giờ $\rightarrow$ Rung cảnh báo, reset Combo về 0 $\rightarrow$ Tự động sinh chế độ ngẫu nhiên mới $\neq$ chế độ cũ $\rightarrow$ Đẩy xuống cuối hàng đợi `queue`.
- **Màn hình Tổng kết (`MixedReflexSummaryView`)**:
  - Thống kê: Độ chính xác, tốc độ phản xạ trung bình, danh hiệu phản xạ (*Reflex Master* / *Swift Reflex* / *Steady Learner*).
  - Danh sách từ đã hoàn thành kèm huy hiệu thăng hạng "Đã thuộc" nếu đạt tiêu chuẩn.
  - Nút "Luyện tập lại" và "Hoàn thành".

---

## 5. Xử lý Ngoại lệ & Dữ liệu Bền vững (Persistence & Edge Cases)

1. **Lưu trữ SwiftData**:
   - `UserWordProgressEntity` lưu trữ `consecutiveCorrectStreak: Int`, `practicedModesRaw: String`, `isMastered: Bool`, `isBookmarked: Bool`.
   - Cơ chế migration tự động, đảm bảo tương thích ngược 100% với dữ liệu hiện có.
2. **Xử lý Ngoại lệ**:
   - Kho từ rỗng $\rightarrow$ Hiển thị Empty State với hướng dẫn học từ mới trên Trang chủ.
   - Chưa cấp quyền Micro ở chế độ Luyện nói $\rightarrow$ Tự động fallback sang Gõ từ/Trắc nghiệm hoặc hiển thị banner nhắc nhở cấp quyền.
   - Thoát giữa phiên $\rightarrow$ Alert xác nhận, bảo toàn kết quả của các từ đã hoàn thành đúng trước đó.

---

## 6. Chiến lược Kiểm thử (Testing Strategy)

- **Unit Tests với Swift Testing (`@Suite`, `@Test`, `#expect`)**:
  - `MasteryEvaluationPolicyTests`: Kiểm tra chuyển trạng thái Đã thuộc (3 đúng + 2 modes) và Chưa thuộc (khi làm sai).
  - `MixedReflexQueueEngineTests`: Kiểm tra phân phối 4 chế độ ngẫu nhiên và cơ chế Loop-back.
  - `PersonalVaultViewModelTests`: Kiểm tra lọc 3 tabs, tìm kiếm từ khoá, chọn/bỏ chọn từ, chọn tất cả.
- **UI / Automation Verification**:
  - Kiểm tra luồng chọn từ $\rightarrow$ luyện tập $\rightarrow$ tổng kết $\rightarrow$ cập nhật số lượng từ trên Kho từ.

---

## 7. Kế hoạch Phiên làm việc Tiếp theo (TODO Note)
- 📌 **TODO Session sau**: Thiết kế lại toàn bộ hệ thống **Chặng học (Learning Stages / Topic Roadmap)** và tích hợp hiển thị trực quan lên **Home Screen**.
