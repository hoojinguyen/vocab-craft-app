# Feature 4: Kho Từ — Vocabulary Vault Design Spec

## 1. Overview & Mục tiêu

**Kho Từ (Vocabulary Vault)** là phân hệ quản lý và tra cứu toàn bộ vốn từ vựng mà người học đã tích lũy qua các bài học trong Lộ trình học (Learning Path) hoặc các phiên luyện phản xạ (Reflex Blitz).

### Mục tiêu cốt lõi:
1. **Active Recall (Chủ động gợi nhớ)**: Thiết kế thẻ từ tối giản (chỉ gồm từ/cụm từ, loại từ, phiên âm IPA tùy chọn, và nút lưu nhanh) — ẩn định nghĩa tiếng Việt trên danh sách để kích thích não bộ tự gợi nhớ nghĩa trước khi tra cứu chi tiết.
2. **Truy cập & Tra cứu tức thì**: Tìm kiếm nhanh theo từ gốc hoặc nghĩa tiếng Việt, hỗ trợ bộ lọc 3 trạng thái gọn gàng (`Chưa thuộc` | `Đã thuộc` | `Đã lưu`).
3. **Chuyển đổi trạng thái 1 chạm**: Lưu hoặc bỏ lưu từ yêu thích ngay trên dòng thẻ với phản hồi xúc giác nhẹ (Haptic).
4. **Ôn luyện tập trung (Contextual Review)**: Nút hành động "⚡ Ôn luyện" đặt ngay dưới bộ lọc trên đầu trang, tự động nạp danh sách từ theo ngữ cảnh tab hiện tại để luyện tập phiên phản xạ hỗn hợp 2-round.

---

## 2. Bố cục Giao diện (Screen Hierarchy & Layout)

Giao diện `VocabularyView` được thiết kế theo cấu trúc cuộn tự nhiên, loại bỏ các thành phần rườm rà (không có carousel, không có header thống kê phức tạp, không có floating button dưới đáy):

```
┌──────────────────────────────────────────────────────────┐
│  Tiêu đề màn hình: "Kho Từ" (Navigation Title)           │
├──────────────────────────────────────────────────────────┤
│  CraftSearchBar ("Tìm kiếm từ vựng...")                  │
├──────────────────────────────────────────────────────────┤
│  VaultSegmentedControl                                   │
│  [ Chưa thuộc (12) ]  [ Đã thuộc (33) ]  [ Đã lưu (8) ]  │
├──────────────────────────────────────────────────────────┤
│  Review Button (Đặt trên top, ngay dưới Filter):         │
│  [ ⚡ Ôn luyện (12 từ) ] (CraftButton prominent)         │
├──────────────────────────────────────────────────────────┤
│  ScrollView / LazyVStack (Danh sách từ vựng tối giản)   │
│  ┌────────────────────────────────────────────────────┐  │
│  │ VaultWordRowView (Từ đơn)                          │  │
│  │  resilient   [adj]                            [🔖] │  │
│  │  /rɪˈzɪl.jənt/                                     │  │
│  └────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────┐  │
│  │ VaultWordRowView (Cụm từ - Không có IPA)           │  │
│  │  break the ice   [phrase]                     [🔖] │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

---

## 3. Chi tiết Component & Tương tác

### 3.1. Header & Tìm kiếm
- **Navigation Title**: `"Kho Từ"` (chuẩn iOS Large / Inline Title).
- **Thanh tìm kiếm (`CraftSearchBar`)**:
  - Placeholder: `app.vault.search_placeholder` ("Tìm kiếm từ vựng...").
  - Hỗ trợ tìm kiếm theo `lemma` (từ gốc), `phonetic` (phiên âm), và `definitionVi` (nghĩa tiếng Việt).
  - Tự động lọc danh sách real-time hoặc debounced mượt mà.

### 3.2. Bộ lọc 3 Trạng thái (`VaultSegmentedControl`)
- Gồm 3 tab cố định:
  1. **Chưa thuộc (`notMastered`)**: Mặc định khi mở màn hình (`isMastered == false`).
  2. **Đã thuộc (`mastered`)**: Các từ đã đạt mức tinh thông (`isMastered == true` hoặc `consecutiveCorrectStreak >= 4`).
  3. **Đã lưu (`bookmarked`)**: Các từ người dùng đã đánh dấu lưu (`isBookmarked == true`).
- Mỗi tab hiển thị kèm số lượng từ tương ứng trong ngoặc đơn, ví dụ: `Chưa thuộc (12)`, `Đã thuộc (33)`, `Đã lưu (8)`.

### 3.3. Nút Hành Động Ôn Luyện (`VaultReviewActionButton`)
- **Vị trí**: Đặt ngay phía trên danh sách từ, bên dưới thanh `VaultSegmentedControl`.
- **Nội dung nhãn**: `⚡ Ôn luyện (%lld từ)` (ví dụ: `⚡ Ôn luyện (12 từ)`).
- **Hành vi**:
  - Chạm vào nút sẽ lấy tối đa 10–15 từ theo ngữ cảnh của tab hiện tại.
  - Khởi tạo và mở full-screen phiên **Mixed Reflex Session (2 rounds: Round 1 Nhận diện [Trắc nghiệm + Nghe] → Round 2 Sản xuất [Gõ + Nói])**.
  - Nếu tab hiện tại không có từ nào (count = 0), nút tự động ẩn hoặc làm mờ vô hiệu hóa.

### 3.4. Dòng Thẻ Từ Vựng Tối Giản (`VaultWordRowView`)
- **Khung thẻ**: Sử dụng `CraftCard` (phẳng, viền tinh tế, nền `CraftColor.surfacePrimary`).
- **Nội dung hiển thị**:
  1. **Từ hoặc Cụm từ (Lemma / Phrase)**: Hiển thị nổi bật với `CraftFont.titleSmall`.
  2. **Loại từ (Part of Speech)**: Hiển thị nhãn nhỏ gọn `[noun]`, `[adj]`, `[phrase]`, `[idiom]` cạnh từ gốc.
  3. **Phiên âm IPA (Tùy chọn)**:
     - Với từ đơn có IPA: Hiển thị dòng phụ `/.../` với `CraftColor.textTertiary`.
     - Với cụm từ / thành ngữ: Tự động ẩn dòng IPA, không tạo khoảng trống thừa.
  4. **Nút Lưu nhanh (Bookmark Action Button)**:
     - Nút icon bookmark ở góc phải (`CraftIconButton`).
     - Khi bấm: Bật/tắt trạng thái `isBookmarked` ngay trong SwiftData, cập nhật sang Tab "Đã lưu" và kích hoạt haptic feedback.
- **Tương tác chạm dòng thẻ**:
  - Chạm vào thân thẻ (ngoài nút bookmark): Mở **`VaultWordDetailSheet`**.

### 3.5. Bottom Sheet Chi Tiết Từ Vựng (`VaultWordDetailSheet`)
- Mở dạng Modal Sheet (`.presentationDetents([.fraction(0.55), .large])`).
- **Nội dung chi tiết**:
  1. **Header Section**: Từ gốc cỡ lớn, nhãn loại từ, cấp độ CEFR (nếu có), phiên âm IPA, nút Loa phát âm cỡ lớn (`TextToSpeech`), và nút Lưu yêu thích.
  2. **Nghĩa từ vựng**:
     - Định nghĩa tiếng Việt (`definitionVi`).
     - Định nghĩa tiếng Anh (`definitionEn`).
  3. **Ví dụ minh họa song ngữ**:
     - Câu tiếng Anh (`exampleSentenceEn`) có tô đậm/highlight từ mục tiêu.
     - Bản dịch tiếng Việt (`exampleSentenceVi`).
  4. **Tiến độ phản xạ**:
     - Chuỗi đúng liên tiếp (`consecutiveCorrectStreak`).
     - Ngày ôn gần nhất (`lastPracticedAt`).
     - Các chế độ phản xạ đã từng luyện (🗣️ Nói, ⌨️ Gõ, 🎯 Trắc nghiệm, 👂 Nghe).

### 3.6. Trạng Thái Rỗng (Empty States)
Hiển thị thông báo đơn giản, tinh gọn tùy theo ngữ cảnh của từng tab:
- Tab *Chưa thuộc* rỗng: `"Bạn không có từ nào chưa thuộc"`
- Tab *Đã thuộc* rỗng: `"Chưa có từ nào đạt mức thành thạo"`
- Tab *Đã lưu* rỗng: `"Chưa có từ nào được lưu"`
- Khi tìm kiếm không có kết quả: `"Không tìm thấy từ nào phù hợp"`

---

## 4. Kiến Trúc Kỹ Thuật & Dữ Liệu (Data Architecture)

### 4.1. Models & Filter Enums

```swift
public enum VaultTabFilter: String, CaseIterable, Sendable, Equatable {
    case notMastered
    case mastered
    case bookmarked
}

public struct PersonalVaultMetrics: Sendable, Equatable {
    public let totalLearnedWords: Int
    public let unmasteredCount: Int
    public let masteredCount: Int
    public let bookmarkedCount: Int
    
    public init(
        totalLearnedWords: Int = 0,
        unmasteredCount: Int = 0,
        masteredCount: Int = 0,
        bookmarkedCount: Int = 0
    ) {
        self.totalLearnedWords = totalLearnedWords
        self.unmasteredCount = unmasteredCount
        self.masteredCount = masteredCount
        self.bookmarkedCount = bookmarkedCount
    }
}
```

### 4.2. Use Case & Repository Layer
- **`FetchPersonalVaultUseCase`**:
  - Truy vấn danh sách `UserWordProgress` từ `UserProgressRepositoryProtocol`.
  - Kết hợp với SQLite `VocabularyDataSourceProtocol` để nạp dữ liệu từ điển (`WordDTO`).
  - Tính toán số lượng từ của cả 3 tab cho Header/Filter Counters.
  - Lọc theo `VaultTabFilter` và `searchQuery`.

### 4.3. ViewModel State (`PersonalVaultViewModel`)
```swift
@MainActor
@Observable
public final class PersonalVaultViewModel {
    public private(set) var vaultWords: [VaultWordItem] = []
    public private(set) var metrics: PersonalVaultMetrics = PersonalVaultMetrics()
    public private(set) var vaultTabFilter: VaultTabFilter = .notMastered
    public private(set) var searchQuery: String = ""
    public private(set) var selectedWordForDetail: VaultWordItem?
    public private(set) var isPresentingReviewSession: Bool = false
    public private(set) var reviewWords: [VaultWordItem] = []
    public private(set) var isLoading: Bool = false
    public private(set) var errorMessage: String?
    
    // Actions:
    // - loadData()
    // - setVaultFilter(_ filter: VaultTabFilter)
    // - setSearchQuery(_ query: String)
    // - toggleBookmark(wordId: Int64)
    // - playAudio(for word: VaultWordItem)
    // - prepareReviewSession()
}
```

---

## 5. Danh Mục Chuỗi Đa Ngôn Ngữ (Localization Keys)

Tất cả chuỗi hiển thị phải được khai báo trong `VocabCraftApp/Resources/Localizable.xcstrings` với taxonomy `app.vault.*`:

| Key | English (`en`) | Tiếng Việt (`vi`) |
|---|---|---|
| `app.vault.title` | Vocabulary Vault | Kho Từ |
| `app.vault.search_placeholder` | Search vocabulary... | Tìm kiếm từ vựng... |
| `app.vault.filter.not_mastered` | Learning (%lld) | Chưa thuộc (%lld) |
| `app.vault.filter.mastered` | Mastered (%lld) | Đã thuộc (%lld) |
| `app.vault.filter.bookmarked` | Saved (%lld) | Đã lưu (%lld) |
| `app.vault.action.review_words` | ⚡ Review (%lld words) | ⚡ Ôn luyện (%lld từ) |
| `app.vault.empty.not_mastered` | No unmastered words | Bạn không có từ nào chưa thuộc |
| `app.vault.empty.mastered` | No mastered words yet | Chưa có từ nào đạt mức thành thạo |
| `app.vault.empty.bookmarked` | No saved words yet | Chưa có từ nào được lưu |
| `app.vault.empty.search_no_results` | No matching words found | Không tìm thấy từ nào phù hợp |
| `app.vault.detail.definitions_title` | Definitions | Định nghĩa |
| `app.vault.detail.examples_title` | Examples | Ví dụ thực tế |
| `app.vault.detail.progress_title` | Reflex Progress | Tiến độ phản xạ |
| `app.vault.detail.streak_count` | %lld streak | Chuỗi đúng %lld |
| `app.vault.detail.practiced_modes` | Practiced modes | Chế độ đã luyện |

---

## 6. Kế Hoạch Kiểm Thử & Tiêu Chuẩn Chất Lượng (Verification Plan)

1. **Unit Tests (`PersonalVaultViewModelTests`)**:
   - Kiểm tra chuyển đổi 3 tab filter (`notMastered`, `mastered`, `bookmarked`).
   - Kiểm tra tìm kiếm real-time (tìm theo từ gốc, nghĩa, không phân biệt hoa thường).
   - Kiểm tra nạp từ vào phiên Ôn luyện (giới hạn 10-15 từ ưu tiên).
   - Kiểm tra cập nhật bookmark phản ánh tức thì.
2. **Swift Concurrency & Zero Warnings**:
   - Đảm bảo toàn bộ ViewModel, UseCase và Views tuân thủ Swift Concurrency, 0 warnings trên Xcode.
3. **CraftUIKit Token Compliance**:
   - 100% màu sắc và typography lấy từ `CraftColor` và `CraftFont`, tuyệt đối không hardcode màu/font/padding thô.
