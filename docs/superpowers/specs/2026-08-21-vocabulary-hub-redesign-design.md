# Thiết Kế Đặc Tả: Tái Cấu Trúc Toàn Diện Tính Năng "Kho Từ" (Vocabulary Hub Redesign)

- **Ngày tạo:** 2026-08-21
- **Kiến trúc chính:** Clean Architecture (Domain / Data / Presentation) + MVVM (`@Observable`)
- **Nền tảng mục tiêu:** iOS 17.0+ (Swift 6 Strict Concurrency, SwiftData, SwiftUI)
- **Tài liệu tham chiếu:** `swift-architecture-skill`, `apple-hig-design-system`

---

## 1. Bối Cảnh & Mục Tiêu Thiết Kế (Overview & Core Philosophy)

### 1.1 Vấn đề hiện tại
- Tính năng "Kho từ" trước đây kết hợp vụn vặt giữa danh sách từ cá nhân và bộ từ chủ đề mà không có triết lý rõ ràng.
- Gắn nút "Luyện tập ngay" trên từng thẻ từ vựng đơn lẻ gây cảm giác rời rạc, làm phân tán trải nghiệm và không đúng với cơ chế ghi nhớ ngữ cảnh theo chặng.
- Dữ liệu tĩnh và dữ liệu thật chưa có tầng trừu tượng hóa (Data Source abstraction), khiến việc phát triển frontend song song với backend gặp khó khăn.
- Giao diện có nguy cơ rơi vào "AI Slop" nếu lạm dụng emoji và icon trang trí không cần thiết trên các nhãn văn bản.

### 1.2 Triết lý thiết kế mới (The New Philosophy)
1. **Bộ từ chủ đề (Topic Decks):** Là **"Lò luyện lộ trình" (Learning Path)**. Người học tiếp thu từ mới theo từng **Chặng (Stage / Milestone)** cụ thể (6 - 8 từ/chặng), đi từ Khám phá ngữ cảnh -> Thử thách kiểm tra chặng -> Mở khóa chặng tiếp theo.
2. **Kho từ cá nhân (Personal Vault):** Là **"Sổ tay tri thức sống & Tra cứu thông minh" (Smart Knowledge Hub)**. Toàn bộ từ vựng được tự động nạp vào từ các chặng đã học. Từ nào trả lời sai ở chặng hoặc đến hạn SRS sẽ tự động gắn cờ `Cần ôn tập`.
3. **Ôn tập tập trung (Focused Session Review):** Loại bỏ hoàn toàn nút luyện lẻ từng từ. Thay vào đó, Kho cá nhân có duy nhất 1 thẻ hành động thông minh kích hoạt **Mini-session ôn tập tập trung** cho các từ yếu.
4. **Chuẩn mực Apple HIG (Typography-first & Anti-AI Slop):** Loại bỏ emoji khỏi các tab lọc, sử dụng SF Symbols đúng chuẩn tỉ lệ và phân cấp thị giác bằng typography, khoảng thở (whitespace).
5. **Data Source Abstraction & 50 Sample Dataset:** Tách biệt hoàn toàn mock dataset (50 từ tuyển chọn) qua protocol, cho phép chuyển sang backend/SQLite thật ở 1 nơi duy nhất (`AppContainer.swift`).

---

## 2. Kiến Trúc Hệ Thống (Clean Architecture + MVVM)

### 2.1 Sơ đồ Phụ thuộc (Dependency Inward Rule)
```
Presentation Layer (SwiftUI Views & @Observable ViewModels)
    ↓
Domain Layer (Entities & Single-Responsibility Use Cases)
    ↑
Data Layer (Repositories, SwiftData Models, SQLite / Sample Data Sources)
    ↑
App / DI Layer (AppContainer - Composition Root)
```

### 2.2 Phân rã Thư mục & File

```text
VocabCraftApp/
├── Core/
│   ├── Database/
│   │   ├── SwiftDataModels.swift                # UserWordProgress, UserStageProgress
│   │   ├── SampleData/                          # [CÔ LẬP] Bộ 50 từ mẫu & Chặng học mẫu
│   │   │   ├── VocabularySampleDataset.swift    # 50 từ chất lượng cao (A2 -> C1)
│   │   │   ├── TopicDecksSampleDataset.swift    # 4 chủ đề & các chặng mẫu
│   │   │   └── SampleVocabularyDataSource.swift # Implement VocabularyDataSourceProtocol
│   │   ├── DataSources/
│   │   │   ├── VocabularyDataSourceProtocol.swift # Contract chung cho Mock & Real DB
│   │   │   └── SQLiteDatasetEngine.swift        # DataSource khi dùng SQLite
│   │   └── Repositories/
│   │       ├── VocabularyRepositoryImpl.swift   # Live Repo điều phối DataSource + SwiftData
│   │       └── StageProgressRepositoryImpl.swift# Quản lý tiến độ hoàn thành các chặng
│   └── SRS/
│       └── SRSEngine.swift                      # Thuật toán tính giãn cách trí nhớ
│
├── Domain/                                      # Pure Swift (Không import SwiftUI)
│   ├── Entities/
│   │   ├── TopicDeck.swift                      # Deck entity (id, title, cefrLevel, icon, progress)
│   │   ├── SubTopicStage.swift                  # Stage Node entity (id, title, state, words)
│   │   ├── TopicWord.swift                      # Từ vựng chi tiết trong chặng
│   │   ├── PersonalWord.swift                   # Từ vựng trong kho cá nhân (mastery, isBookmarked, needsReview)
│   │   └── StageChallenge.swift                 # Câu hỏi trắc nghiệm/phản xạ & kết quả chặng
│   └── UseCases/
│       ├── FetchTopicDecksUseCase.swift         # Lấy danh sách chủ đề kèm tiến độ %
│       ├── FetchDeckRoadmapUseCase.swift        # Lấy lộ trình các chặng theo chủ đề
│       ├── CompleteStageChallengeUseCase.swift  # Chấm điểm, mở khóa chặng mới, gắn cờ từ sai
│       ├── FetchPersonalVaultUseCase.swift      # Lấy & lọc kho từ cá nhân + thống kê
│       ├── ReviewWeakWordsUseCase.swift         # Lấy từ yếu & cập nhật sau mini-session
│       └── ToggleWordBookmarkUseCase.swift      # Đánh dấu ghim / bỏ ghim từ vựng
│
├── Features/
│   └── Vocabulary/                              # Presentation Layer
│       ├── VocabularyHubView.swift              # Container chính với Segmented Bar chuẩn Apple
│       │
│       ├── PersonalVault/                       # [Slices 1] Kho Từ Cá Nhân
│       │   ├── ViewModels/
│       │   │   ├── PersonalVaultViewModel.swift # Quản lý State, search, filter, counts
│       │   │   └── SmartReviewViewModel.swift   # Quản lý mini-session ôn từ yếu
│       │   └── Views/
│       │       ├── PersonalVaultView.swift      # Giao diện chính của Kho cá nhân
│       │       ├── PersonalVaultHeroCard.swift  # Smart Action Card (hiện nút khi có từ cần ôn)
│       │       ├── PersonalSearchFilterBar.swift# Search bar + Filter Pills (Typography thuần)
│       │       ├── CleanWordCardView.swift      # Thẻ từ vựng tra cứu (KHÔNG có nút luyện lẻ)
│       │       └── SmartReviewSessionView.swift # Trình diễn ôn tập tập trung (Sheet/FullCover)
│       │
│       └── TopicDecks/                          # [Slices 2] Bộ Từ Chủ Đề Theo Chặng
│           ├── ViewModels/
│           │   ├── TopicDecksViewModel.swift    # Quản lý danh sách chủ đề
│           │   ├── TopicRoadmapViewModel.swift  # Quản lý bản đồ lộ trình các chặng
│           │   ├── StagePreviewViewModel.swift  # Quản lý bước khám phá từ vựng
│           │   └── StageChallengeViewModel.swift# Quản lý bài kiểm tra thử thách chặng
│           └── Views/
│               ├── TopicDecksGridView.swift     # Lưới thẻ chủ đề Bento Card
│               ├── TopicRoadmapView.swift       # Bản đồ lộ trình Timeline dọc
│               ├── StagePreviewSheet.swift      # Bước 1: Khám phá từ vựng & câu ví dụ
│               ├── StageChallengeView.swift     # Bước 2: Thử thách kiểm tra chặng
│               └── StageSummarySheet.swift      # Bước 3: Tổng kết nạp từ & mở khóa chặng mới
│
└── App/
    └── DI/
        └── AppContainer.swift                   # Composition Root (Nơi duy nhất cấu hình Data Source)
```

---

## 3. Data Source Abstraction & Dataset Mẫu 50 Từ (Sample Data Architecture)

### 3.1 Giao ước Data Source (`VocabularyDataSourceProtocol`)

```swift
public protocol VocabularyDataSourceProtocol: Sendable {
    func fetchTopicDecks() async throws -> [TopicDeckDTO]
    func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO]
    func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO]
    func searchWords(query: String) async throws -> [TopicWordDTO]
    func fetchWordById(id: Int64) async throws -> TopicWordDTO?
}
```

### 3.2 Cấu hình duy nhất tại `AppContainer.swift`
```swift
@MainActor
public final class AppContainer {
    // Để chuyển đổi giữa Mock và Real, chỉ cần sửa dòng này:
    private let useSampleData: Bool = true

    public init(...) {
        let dataSource: VocabularyDataSourceProtocol = useSampleData
            ? SampleVocabularyDataSource()
            : SQLiteDatasetEngine() // hoặc RemoteBackendDataSource()
            
        let stageProgressRepo = StageProgressRepositoryImpl(modelContext: modelContainer?.mainContext)
        let vocabRepo = VocabularyRepositoryImpl(
            dataSource: dataSource,
            stageProgressRepo: stageProgressRepo,
            progressActor: progressActor
        )
        // Inject vào các Use Cases...
    }
}
```

### 3.3 Danh mục 50 từ mẫu được tuyển chọn (4 Chủ đề & 8 Chặng)

#### Chủ đề 1: Giao Tiếp Hằng Ngày & Đời Sống (Daily Life & Social - A2/B1)
- **Chặng 1: Thói quen & Cảm xúc (7 từ):**
  1. `Resilience` (/rɪˈzɪl.jəns/ - n): Khả năng phục hồi, kiên cường. Ví dụ: *"Her resilience helped her overcome difficulties."*
  2. `Overwhelmed` (/ˌoʊ.vɚˈwelmd/ - adj): Bị ngợp, quá tải. Ví dụ: *"He felt overwhelmed by the workload."*
  3. `Spontaneous` (/spɑːnˈteɪ.ni.əs/ - adj): Tự phát, ngẫu hứng. Ví dụ: *"We took a spontaneous road trip."*
  4. `Gratitude` (/ˈɡræt̬.ə.tuːd/ - n): Lòng biết ơn. Ví dụ: *"She expressed gratitude for his help."*
  5. `Procrastinate` (/proʊˈkræs.tə.neɪt/ - v): Trì hoãn. Ví dụ: *"Don't procrastinate on important tasks."*
  6. `Empathy` (/ˈem.pə.θi/ - n): Sự đồng cảm. Ví dụ: *"Empathy is vital for healthy relationships."*
  7. `Reliable` (/rɪˈlaɪ.ə.bəl/ - adj): Đáng tin cậy. Ví dụ: *"She is a reliable and honest friend."*
- **Chặng 2: Giao tiếp & Ứng xử (6 từ):**
  8. `Compromise` (/ˈkɑːm.prə.maɪz/ - n/v): Thỏa hiệp. Ví dụ: *"They reached a fair compromise."*
  9. `Misunderstanding` (/ˌmɪs.ʌn.dɚˈstæn.dɪŋ/ - n): Sự hiểu lầm. Ví dụ: *"Clear communication prevents misunderstanding."*
  10. `Heartfelt` (/ˈhɑːrt.felt/ - adj): Chân thành. Ví dụ: *"He gave a heartfelt apology."*
  11. `Hesitate` (/ˈhez.ə.teɪt/ - v): Lưỡng lự, do dự. Ví dụ: *"Do not hesitate to ask questions."*
  12. `Optimistic` (/ˌɑːp.təˈmɪs.tɪk/ - adj): Lạc quan. Ví dụ: *"She remains optimistic about the future."*
  13. `Genuine` (/ˈdʒen.ju.ɪn/ - adj): Thật lòng, chân thật. Ví dụ: *"He showed genuine interest in the project."*

#### Chủ đề 2: Môi Trường Công Sở & Kinh Doanh (Workplace & Business - B1/B2)
- **Chặng 1: Quản lý Công việc & Kế hoạch (6 từ):**
  14. `Prioritize` (/praɪˈɔːr.ə.taɪz/ - v): Ưu tiên. Ví dụ: *"Prioritize your urgent tasks daily."*
  15. `Deadline` (/ˈded.laɪn/ - n): Hạn chót. Ví dụ: *"We must meet the strict deadline."*
  16. `Collaborate` (/kəˈlæb.ə.reɪt/ - v): Hợp tác. Ví dụ: *"Teams collaborate across departments."*
  17. `Milestone` (/ˈmaɪl.stoʊn/ - n): Cột mốc quan trọng. Ví dụ: *"Launching the app was a major milestone."*
  18. `Delegation` (/ˌdel.əˈɡeɪ.ʃən/ - n): Sự ủy quyền. Ví dụ: *"Effective delegation saves time."*
  19. `Productivity` (/ˌproʊ.dʌkˈtɪv.ə.t̬i/ - n): Năng suất. Ví dụ: *"Quiet workspaces boost productivity."*
- **Chặng 2: Đàm phán & Phát triển Năng lực (6 từ):**
  20. `Negotiation` (/nəˌɡoʊ.ʃiˈeɪ.ʃən/ - n): Đàm phán. Ví dụ: *"The contract negotiation was successful."*
  21. `Feedback` (/ˈfiːd.bæk/ - n): Phản hồi. Ví dụ: *"Constructive feedback helps employees grow."*
  22. `Competence` (/ˈkɑːm.pə.t̬əns/ - n): Năng lực. Ví dụ: *"She demonstrated high technical competence."*
  23. `Benchmark` (/ˈbentʃ.mɑːrk/ - n): Tiêu chuẩn đối sánh. Ví dụ: *"The project sets a new quality benchmark."*
  24. `Incentive` (/ɪnˈsen.t̬ɪv/ - n): Sự khuyến khích, động lực. Ví dụ: *"Bonuses serve as a strong incentive."*
  25. `Transparency` (/trænˈspær.ən.si/ - n): Sự minh bạch. Ví dụ: *"We value transparency in management."*

#### Chủ đề 3: Công Nghệ & Trí Tuệ Nhân Tạo (Technology & AI - B2/C1)
- **Chặng 1: Kỷ nguyên Kỹ thuật số (6 từ):**
  26. `Algorithm` (/ˈæl.ɡə.rɪ.ðəm/ - n): Thuật toán. Ví dụ: *"Search algorithms rank relevant content."*
  27. `Automation` (/ˌɑː.t̬əˈmeɪ.ʃən/ - n): Sự tự động hóa. Ví dụ: *"Factory automation cuts production costs."*
  28. `Data-driven` (/ˈdeɪ.t̬əˌdrɪv.ən/ - adj): Dựa trên dữ liệu. Ví dụ: *"We make data-driven marketing decisions."*
  29. `Cutting-edge` (/ˌkʌt̬.ɪŋˈedʒ/ - adj): Tối tân, tiên tiến. Ví dụ: *"They use cutting-edge AI technology."*
  30. `Cybersecurity` (/ˌsaɪ.bɚ.səˈkjʊr.ə.t̬i/ - n): An ninh mạng. Ví dụ: *"Cybersecurity protects sensitive customer data."*
  31. `Scalability` (/ˌskeɪ.ləˈbɪl.ə.t̬i/ - n): Khả năng mở rộng. Ví dụ: *"Cloud computing ensures system scalability."*
- **Chặng 2: Trí tuệ Nhân tạo & Đổi mới (6 từ):**
  32. `Neural network` (/ˈnʊr.əl ˈnet.wɜːrk/ - n): Mạng nơ-ron. Ví dụ: *"Neural networks recognize complex speech patterns."*
  33. `Autonomous` (/ɑːˈtɑː.nə.məs/ - adj): Tự hành, tự chủ. Ví dụ: *"Autonomous vehicles navigate city roads."*
  34. `Predictive` (/prɪˈdɪk.tɪv/ - adj): Dự đoán. Ví dụ: *"Predictive analytics forecast market trends."*
  35. `Disruptive` (/dɪsˈrʌp.tɪv/ - adj): Mang tính đột phá, thay đổi cuộc chơi. Ví dụ: *"Generative AI is a disruptive technology."*
  36. `Infrastructure` (/ˈɪn.frəˌstrʌk.tʃɚ/ - n): Hạ tầng. Ví dụ: *"Server infrastructure supports heavy traffic."*
  37. `Virtualization` (/ˌvɜːr.tʃu.ə.laɪˈzeɪ.ʃən/ - n): Ảo hóa. Ví dụ: *"Server virtualization reduces hardware costs."*

#### Chủ đề 4: Học Thuật & IELTS Cao Cấp (Academic & IELTS Mastery - B2/C1)
- **Chặng 1: Môi trường & Xã hội (7 từ):**
  38. `Biodiversity` (/ˌbaɪ.oʊ.daɪˈvɜːr.sə.t̬i/ - n): Đa dạng sinh học. Ví dụ: *"Deforestation threatens regional biodiversity."*
  39. `Sustainability` (/səˌsteɪ.nəˈbɪl.ə.t̬i/ - n): Sự bền vững. Ví dụ: *"Environmental sustainability is a global goal."*
  40. `Urbanization` (/ˌɝː.bən.əˈzeɪ.ʃən/ - n): Sự đô thị hóa. Ví dụ: *"Rapid urbanization strains public transport."*
  41. `Detrimental` (/ˌdet.rəˈmen.t̬əl/ - adj): Có hại, bất lợi. Ví dụ: *"Pollution has a detrimental effect on health."*
  42. `Phenomenon` (/fəˈnɑː.mə.nɑːn/ - n): Hiện tượng. Ví dụ: *"Climate change is a complex phenomenon."*
  43. `Preservation` (/ˌprez.ɚˈveɪ.ʃən/ - n): Sự bảo tồn. Ví dụ: *"Forest preservation prevents soil erosion."*
  44. `Depletion` (/dɪˈpliː.ʃən/ - n): Sự cạn kiệt. Ví dụ: *"Resource depletion is an urgent challenge."*
- **Chặng 2: Tư duy & Kinh tế Toàn cầu (6 từ):**
  45. `Fluctuation` (/ˌflʌk.tʃuˈeɪ.ʃən/ - n): Sự biến động. Ví dụ: *"Currency fluctuations impact import prices."*
  46. `Unprecedented` (/ʌnˈpres.ə.den.t̬ɪd/ - adj): Chưa từng có tiền lệ. Ví dụ: *"The crisis caused unprecedented economic loss."*
  47. `Discrepancy` (/dɪˈskrep.ən.si/ - n): Sự khác biệt, không nhất quán. Ví dụ: *"There was a discrepancy in the budget report."*
  48. `Paradigm shift` (/ˈpær.ə.daɪm ʃɪft/ - n): Bước chuyển dịch mô hình/nhận thức. Ví dụ: *"Remote work created a cultural paradigm shift."*
  49. `Substantial` (/səbˈstæn.ʃəl/ - adj): Đáng kể, to lớn. Ví dụ: *"They made substantial progress this quarter."*
  50. `Feasibility` (/ˌfiː.zəˈbɪl.ə.t̬i/ - n): Tính khả thi. Ví dụ: *"Engineers tested the technical feasibility of the design."*

---

## 4. Đặc Tả Giao Diện & Trải Nghiệm Người Dùng (UI/UX Specification)

### 4.1 Triết lý Visual Chuẩn Apple HIG (Anti-AI Slop)
- **Không emoji trong Tab & Pill nhãn:** Dùng Text thuần túy (`Tất cả`, `Cần ôn tập`, `Đã thuộc`, `Đã lưu`).
- **SF Symbols chuẩn mực:**
  - `speaker.wave.2.fill` (phát âm từ)
  - `bookmark` / `bookmark.fill` (ghim từ vựng)
  - `checkmark` (hoàn thành chặng / đã thuộc)
  - `chevron.left`, `chevron.right` (điều hướng)
- **Màu sắc & Phân cấp:**
  - `vocabInk` cho Text tiêu đề chính.
  - `vocabMuted` cho IPA, phụ đề, từ loại.
  - `vocabMint` cho trạng thái thành công / đã nhớ.
  - `vocabPeach` cho trạng thái đang học / cần ôn tập.
  - `vocabSurfaceCard` và `vocabHairline` cho các thẻ với viền mảnh 1pt tinh tế.

---

### 4.2 Module 1: Bộ Từ Chủ Đề (Topic Decks)

#### Màn hình 1: Lưới Chủ Đề (`TopicDecksGridView`)
- Bento Card hiển thị từng chủ đề:
  - Icon chủ đề (SF Symbol chuẩn).
  - Tên chủ đề & Badge cấp độ (`B1-B2`).
  - Thanh tiến độ Capsule gradient thanh mảnh kèm nhãn `X / Y từ đã nạp`.
- Chạm vào thẻ chuyển mượt mà sang Bản đồ Lộ trình Chặng (`TopicRoadmapView`).

#### Màn hình 2: Bản đồ Lộ trình Chặng (`TopicRoadmapView`)
- **Top Header Card:**
  - Nút quay lại (`chevron.left`).
  - Tên chủ đề & % hoàn thành toàn bộ chủ đề.
  - Nút CTA nhanh: `[ Tiếp tục Chặng X ]`.
- **Dòng thời gian (Timeline Roadmap):**
  - Node `.completed`: Circle viền xanh ngọc mint, icon `checkmark`, hiển thị số từ đã thuộc.
  - Node `.active`: Circle màu cam đào (`vocabPeach`), hiển thị số thứ tự chặng, phát sáng nhẹ.
  - Node `.locked`: Circle xám mờ (`vocabSurfaceSoft`), icon `lock.fill`.
- Chạm vào Chặng đang học (`.active`) sẽ mở **Khám phá Chặng (`StagePreviewSheet`)**.

#### Màn hình 3: Bước 1 — Khám Phá Từ Vựng (`StagePreviewSheet`)
- Header: Tên chặng & số lượng từ (ví dụ: *Chặng 1: Thói quen & Cảm xúc - 7 từ*).
- Danh sách từ vựng chi tiết:
  - Từ vựng (Serif font đậm).
  - Phiên âm IPA + nút loa phát âm nhanh.
  - Nghĩa tiếng Việt rõ ràng.
  - Câu ví dụ tiếng Anh in nghiêng + bản dịch tiếng Việt bên dưới.
  - Nút ghim 🔖 nhanh.
- Nút CTA cố định dưới đáy: `[ Bắt đầu Thử thách Chặng (7 câu) → ]`.

#### Màn hình 4: Bước 2 — Thử Thách Chặng (`StageChallengeView`)
- Thanh tiến độ Segmented trên cùng hiển thị trạng thái từng câu hỏi.
- Mini-quiz tương tác:
  - Dạng câu hỏi trắc nghiệm ngữ nghĩa và điền từ vào câu ví dụ.
  - Chọn đáp án -> Phản hồi tức thì với SFX và haptic feedback nhẹ nhàng.
  - Câu đúng: Tăng XP (+10 XP) và nạp vào Kho cá nhân dạng "Đã học".
  - Câu sai: Hiển thị đáp án đúng để học viên ghi nhớ, đồng thời **tự động gắn cờ `needsReview = true`** chuyển vào Kho cá nhân.

#### Màn hình 5: Bước 3 — Tổng Kết Chặng (`StageSummarySheet`)
- Hiển thị thành tích:
  - Tổng số XP đạt được.
  - Số từ nạp thành công vào Kho cá nhân.
  - Số từ cần ôn lại (nếu có câu sai).
- Nút CTA: `[ Hoàn thành & Tiếp tục ]` -> Tự động cập nhật `StageState = .completed` và mở khóa chặng kế tiếp (`.active`).

---

### 4.3 Module 2: Kho Từ Cá Nhân (Personal Vault)

#### Màn hình 1: Giao diện Kho Cá Nhân (`PersonalVaultView`)
- **Thẻ Hành Động Thông Minh (`PersonalVaultHeroCard`):**
  - **Trường hợp có từ cần ôn:** Hiển thị thông báo: *"Bạn có **N từ** cần củng cố lại"* + Nút CTA duy nhất `[ Ôn tập từ yếu ngay (N từ) ]`.
  - **Trường hợp không có từ yếu:** Hiển thị thẻ tóm tắt số từ đã tích lũy và % trí nhớ SRS khỏe mạnh.
- **Thanh Tìm Kiếm & Bộ Lọc Typography (`PersonalSearchFilterBar`):**
  - Search bar tra cứu từ tiếng Anh hoặc tiếng Việt.
  - Dải Filter Pills ngang: `Tất cả (N)` | `Cần ôn (N)` | `Đã thuộc (N)` | `Đã lưu (N)`.
- **Danh Sách Thẻ Từ Vựng Tinh Gọn (`CleanWordCardView`):**
  - Thẻ Accordion thanh lịch:
    - Thu gọn: Từ vựng, IPA, nút loa nghe phát âm, nhãn CEFR, thanh 5 vạch Mastery.
    - Mở rộng: Định nghĩa tiếng Việt, câu ví dụ tiếng Anh + dịch Việt, nguồn chặng học, nút ghim `bookmark`.
    - **HOÀN TOÀN KHÔNG CÓ NÚT "LUYỆN TẬP NGAY" TRÊN TỪNG TỪ.**
  - Swipe Actions: Vuốt phải để ghim/bỏ ghim, vuốt trái để xóa từ khỏi kho nếu muốn.

#### Màn hình 2: Phiên Ôn Tập Tập Trung (`SmartReviewSessionView`)
- Kích hoạt khi bấm `[ Ôn tập từ yếu ngay ]` trên thẻ Hero Card.
- Mini-session ngắn (1 - 2 phút) chỉ gồm danh sách các từ đang bị gắn cờ `needsReview`.
- Sau khi hoàn thành phiên ôn tập:
  - Các từ làm đúng được tăng điểm Mastery và gỡ cờ `needsReview = false`.
  - Quay lại Kho cá nhân với trạng thái cập nhật ngay lập tức.

---

## 5. Kế Hoạch Kiểm Thử & Xác Minh (Testing & Verification Strategy)

1. **Unit Tests cho Domain & Use Cases:**
   - `CompleteStageChallengeUseCaseTests`: Kiểm tra tính điểm chặng, mở khóa chặng tiếp theo và gắn cờ từ sai vào `needsReview`.
   - `FetchPersonalVaultUseCaseTests`: Kiểm tra lọc danh mục (`all`, `needsReview`, `mastered`, `bookmarked`) và đếm số lượng chính xác.
   - `ReviewWeakWordsUseCaseTests`: Kiểm tra gỡ cờ `needsReview` sau khi hoàn thành phiên ôn tập.
2. **Data Source Tests:**
   - `SampleVocabularyDataSourceTests`: Đảm bảo 50 từ mẫu và 4 chủ đề tải đầy đủ, không thiếu trường dữ liệu nào.
3. **ViewModel Tests (State Transitions & Cancellation):**
   - `PersonalVaultViewModelTests`: Kiểm tra luồng tải dữ liệu, tìm kiếm từ khóa, và hủy task khi thay đổi bộ lọc nhanh.
   - `StageChallengeViewModelTests`: Kiểm tra chuyển câu hỏi, tính XP và phát tín hiệu hoàn thành chặng.
4. **UI Snapshot / Manual Verification:**
   - Kiểm tra hiển thị chuẩn Apple trên Light/Dark mode.
   - Xác nhận không có emoji trong nhãn bộ lọc, typography cân đối, và không còn nút "Luyện ngay" lẻ tẻ.

---

## 6. Kế Hoạch Triển Khai (Phases of Implementation)

- **Giai đoạn 1: Data Layer & Sample Dataset**
  - Tạo `VocabularyDataSourceProtocol`.
  - Tạo `VocabularySampleDataset.swift` (50 từ) & `TopicDecksSampleDataset.swift`.
  - Tạo `SampleVocabularyDataSource.swift`.
  - Mở rộng `UserWordProgress` & tạo `StageProgress` trong SwiftData.
  - Cập nhật `AppContainer.swift`.

- **Giai đoạn 2: Domain Layer & Use Cases**
  - Xây dựng các Entities (`SubTopicStage`, `PersonalWord`, `StageChallenge`).
  - Xây dựng 6 Use Cases độc lập kèm Unit Tests.

- **Giai đoạn 3: Presentation Layer - Bộ Từ Chủ Đề (Topic Decks)**
  - Xây dựng `TopicDecksGridView`, `TopicRoadmapView`.
  - Xây dựng luồng học 3 bước: `StagePreviewSheet` -> `StageChallengeView` -> `StageSummarySheet`.

- **Giai đoạn 4: Presentation Layer - Kho Từ Cá Nhân (Personal Vault)**
  - Xây dựng `PersonalVaultHeroCard`, `PersonalSearchFilterBar`, `CleanWordCardView`.
  - Xây dựng `SmartReviewSessionView` (mini-session ôn tập tập trung).
  - Tích hợp vào `VocabularyHubView`.

- **Giai đoạn 5: Xác Minh & Kiểm Thử Toàn Diện**
  - Chạy toàn bộ Unit Tests & Build kiểm tra trên iOS Simulator.
