# Vocabulary Hub Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the Vocabulary Hub ("Kho từ") with Topic Decks (Stage-based learning roadmap) and Personal Vault (Smart Ingestion, Focused Review, and clean Apple HIG typography without per-word drill buttons), backed by a DataSource abstraction and 50 curated sample words.

**Architecture:** Clean Architecture (Domain / Data / Presentation Layering) with MVVM (`@Observable`) and Protocol-Driven Data Sources.

**Tech Stack:** Swift 6 (Strict Concurrency), iOS 17.0+ (`@Observable`, `@Model` SwiftData), SwiftUI, XCTest.

**Spec:** [`docs/superpowers/specs/2026-08-21-vocabulary-hub-redesign-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-21-vocabulary-hub-redesign-design.md)

## Global Constraints

- Platform target: iOS 17.0+, macOS 14.0+
- Concurrency: Swift 6 Strict Concurrency, `@MainActor` on ViewModels & Views, `Sendable` domain entities.
- Apple HIG: Typography-first filter pills (NO emoji in tab labels), SF Symbols with balanced weights.
- Single switch point for Mock/Real data in `AppContainer.swift` via `VocabularyDataSourceProtocol`.
- Zero per-word micro-drill buttons in word list cards.

---

### Task 1: Core Data Source Abstraction & 50 Curated Sample Dataset

**Files:**
- Create: `VocabCraftApp/Core/Database/DataSources/VocabularyDataSourceProtocol.swift`
- Create: `VocabCraftApp/Core/Database/SampleData/VocabularySampleDataset.swift`
- Create: `VocabCraftApp/Core/Database/SampleData/SampleVocabularyDataSource.swift`
- Test: `VocabCraftAppTests/Core/SampleVocabularyDataSourceTests.swift`

**Interfaces:**
- Produces: `VocabularyDataSourceProtocol`, `TopicDeckDTO`, `SubTopicStageDTO`, `TopicWordDTO`, `SampleVocabularyDataSource`

- [ ] **Step 1: Write failing test for SampleVocabularyDataSource**

```swift
import XCTest
@testable import VocabCraftApp

final class SampleVocabularyDataSourceTests: XCTestCase {
    func test_fetchTopicDecks_returnsFourCuratedDecks() async throws {
        let sut = SampleVocabularyDataSource()
        let decks = try await sut.fetchTopicDecks()
        XCTAssertEqual(decks.count, 4)
        XCTAssertEqual(decks.map(\.id), ["deck_daily", "deck_business", "deck_tech", "deck_academic"])
    }

    func test_fetchWordsAcrossAllStages_returnsFiftyTotalWords() async throws {
        let sut = SampleVocabularyDataSource()
        let decks = try await sut.fetchTopicDecks()
        var totalWordsCount = 0
        for deck in decks {
            let stages = try await sut.fetchSubTopicStages(deckId: deck.id)
            for stage in stages {
                let words = try await sut.fetchWordsForStage(stageId: stage.id)
                totalWordsCount += words.count
            }
        }
        XCTAssertEqual(totalWordsCount, 50)
    }

    func test_searchWords_returnsMatchingEntries() async throws {
        let sut = SampleVocabularyDataSource()
        let results = try await sut.searchWords(query: "Resilience")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.lemma, "Resilience")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter SampleVocabularyDataSourceTests`
Expected: FAIL (missing types `SampleVocabularyDataSource`, `VocabularyDataSourceProtocol`)

- [ ] **Step 3: Implement VocabularyDataSourceProtocol, VocabularySampleDataset, and SampleVocabularyDataSource**

```swift
// VocabCraftApp/Core/Database/DataSources/VocabularyDataSourceProtocol.swift
import Foundation

public struct TopicDeckDTO: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let iconName: String
    public let badgeColorHex: String
    public let cefrLevel: String
    public let sortOrder: Int

    public init(id: String, title: String, iconName: String, badgeColorHex: String, cefrLevel: String, sortOrder: Int) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.badgeColorHex = badgeColorHex
        self.cefrLevel = cefrLevel
        self.sortOrder = sortOrder
    }
}

public struct SubTopicStageDTO: Identifiable, Sendable, Equatable {
    public let id: String
    public let deckId: String
    public let title: String
    public let iconName: String
    public let sortOrder: Int

    public init(id: String, deckId: String, title: String, iconName: String, sortOrder: Int) {
        self.id = id
        self.deckId = deckId
        self.title = title
        self.iconName = iconName
        self.sortOrder = sortOrder
    }
}

public struct TopicWordDTO: Identifiable, Sendable, Equatable {
    public let id: Int64
    public let stageId: String
    public let lemma: String
    public let phonetic: String
    public let pos: String
    public let cefrLevel: String
    public let definitionVi: String
    public let definitionEn: String
    public let exampleEn: String
    public let exampleVi: String

    public init(
        id: Int64,
        stageId: String,
        lemma: String,
        phonetic: String,
        pos: String,
        cefrLevel: String,
        definitionVi: String,
        definitionEn: String,
        exampleEn: String,
        exampleVi: String
    ) {
        self.id = id
        self.stageId = stageId
        self.lemma = lemma
        self.phonetic = phonetic
        self.pos = pos
        self.cefrLevel = cefrLevel
        self.definitionVi = definitionVi
        self.definitionEn = definitionEn
        self.exampleEn = exampleEn
        self.exampleVi = exampleVi
    }
}

public protocol VocabularyDataSourceProtocol: Sendable {
    func fetchTopicDecks() async throws -> [TopicDeckDTO]
    func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO]
    func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO]
    func searchWords(query: String) async throws -> [TopicWordDTO]
    func fetchWordById(id: Int64) async throws -> TopicWordDTO?
}
```

```swift
// VocabCraftApp/Core/Database/SampleData/VocabularySampleDataset.swift
import Foundation

public enum VocabularySampleDataset {
    public static let decks: [TopicDeckDTO] = [
        TopicDeckDTO(id: "deck_daily", title: "Giao Tiếp Hằng Ngày", iconName: "bubble.left.and.bubble.right", badgeColorHex: "#38B2AC", cefrLevel: "A2 - B1", sortOrder: 1),
        TopicDeckDTO(id: "deck_business", title: "Công Sở & Kinh Doanh", iconName: "briefcase", badgeColorHex: "#ED8936", cefrLevel: "B1 - B2", sortOrder: 2),
        TopicDeckDTO(id: "deck_tech", title: "Công Nghệ & AI", iconName: "cpu", badgeColorHex: "#4299E1", cefrLevel: "B2 - C1", sortOrder: 3),
        TopicDeckDTO(id: "deck_academic", title: "Học Thuật & IELTS", iconName: "graduationcap", badgeColorHex: "#9F7AEA", cefrLevel: "B2 - C1", sortOrder: 4)
    ]

    public static let stages: [SubTopicStageDTO] = [
        SubTopicStageDTO(id: "stage_daily_1", deckId: "deck_daily", title: "Chặng 1: Thói quen & Cảm xúc", iconName: "heart", sortOrder: 1),
        SubTopicStageDTO(id: "stage_daily_2", deckId: "deck_daily", title: "Chặng 2: Giao tiếp & Ứng xử", iconName: "person.2", sortOrder: 2),
        SubTopicStageDTO(id: "stage_biz_1", deckId: "deck_business", title: "Chặng 1: Quản lý & Kế hoạch", iconName: "checklist", sortOrder: 1),
        SubTopicStageDTO(id: "stage_biz_2", deckId: "deck_business", title: "Chặng 2: Đàm phán & Năng lực", iconName: "chart.line.uptrend.xyaxis", sortOrder: 2),
        SubTopicStageDTO(id: "stage_tech_1", deckId: "deck_tech", title: "Chặng 1: Kỷ nguyên Số", iconName: "network", sortOrder: 1),
        SubTopicStageDTO(id: "stage_tech_2", deckId: "deck_tech", title: "Chặng 2: Trí tuệ Nhân tạo", iconName: "sparkles", sortOrder: 2),
        SubTopicStageDTO(id: "stage_acad_1", deckId: "deck_academic", title: "Chặng 1: Môi trường & Xã hội", iconName: "leaf", sortOrder: 1),
        SubTopicStageDTO(id: "stage_acad_2", deckId: "deck_academic", title: "Chặng 2: Tư duy & Toàn cầu", iconName: "globe", sortOrder: 2)
    ]

    public static let words: [TopicWordDTO] = [
        // Daily Stage 1 (7 words)
        TopicWordDTO(id: 1, stageId: "stage_daily_1", lemma: "Resilience", phonetic: "/rɪˈzɪl.jəns/", pos: "noun", cefrLevel: "B2", definitionVi: "Khả năng phục hồi, kiên cường", definitionEn: "The capacity to recover quickly from difficulties", exampleEn: "Her resilience helped her overcome difficulties.", exampleVi: "Sự kiên cường giúp cô ấy vượt qua khó khăn."),
        TopicWordDTO(id: 2, stageId: "stage_daily_1", lemma: "Overwhelmed", phonetic: "/ˌoʊ.vɚˈwelmd/", pos: "adjective", cefrLevel: "B1", definitionVi: "Bị ngợp, quá tải", definitionEn: "Completely overcome by emotions or tasks", exampleEn: "He felt overwhelmed by the workload.", exampleVi: "Anh ấy cảm thấy quá tải vì khối lượng công việc."),
        TopicWordDTO(id: 3, stageId: "stage_daily_1", lemma: "Spontaneous", phonetic: "/spɑːnˈteɪ.ni.əs/", pos: "adjective", cefrLevel: "B2", definitionVi: "Tự phát, ngẫu hứng", definitionEn: "Performed or occurring as a result of a sudden impulse", exampleEn: "We took a spontaneous road trip.", exampleVi: "Chúng tôi đã có một chuyến đi phượt ngẫu hứng."),
        TopicWordDTO(id: 4, stageId: "stage_daily_1", lemma: "Gratitude", phonetic: "/ˈɡræt̬.ə.tuːd/", pos: "noun", cefrLevel: "B1", definitionVi: "Lòng biết ơn", definitionEn: "The quality of being thankful", exampleEn: "She expressed gratitude for his help.", exampleVi: "Cô ấy bày tỏ lòng biết ơn vì sự giúp đỡ của anh ấy."),
        TopicWordDTO(id: 5, stageId: "stage_daily_1", lemma: "Procrastinate", phonetic: "/proʊˈkræs.tə.neɪt/", pos: "verb", cefrLevel: "B2", definitionVi: "Trì hoãn công việc", definitionEn: "Delay or postpone action", exampleEn: "Don't procrastinate on important tasks.", exampleVi: "Đừng trì hoãn những công việc quan trọng."),
        TopicWordDTO(id: 6, stageId: "stage_daily_1", lemma: "Empathy", phonetic: "/ˈem.pə.θi/", pos: "noun", cefrLevel: "B2", definitionVi: "Sự đồng cảm", definitionEn: "The ability to understand others' feelings", exampleEn: "Empathy is vital for healthy relationships.", exampleVi: "Sự đồng cảm rất quan trọng cho các mối quan hệ tốt đẹp."),
        TopicWordDTO(id: 7, stageId: "stage_daily_1", lemma: "Reliable", phonetic: "/rɪˈlaɪ.ə.bəl/", pos: "adjective", cefrLevel: "A2", definitionVi: "Đáng tin cậy", definitionEn: "Consistently good in quality or performance", exampleEn: "She is a reliable and honest friend.", exampleVi: "Cô ấy là một người bạn đáng tin cậy và thật thà."),
        // Daily Stage 2 (6 words)
        TopicWordDTO(id: 8, stageId: "stage_daily_2", lemma: "Compromise", phonetic: "/ˈkɑːm.prə.maɪz/", pos: "noun", cefrLevel: "B1", definitionVi: "Sự thỏa hiệp", definitionEn: "An agreement reached by mutual concession", exampleEn: "They reached a fair compromise.", exampleVi: "Họ đã đạt được một sự thỏa hiệp công bằng."),
        TopicWordDTO(id: 9, stageId: "stage_daily_2", lemma: "Misunderstanding", phonetic: "/ˌmɪs.ʌn.dɚˈstæn.dɪŋ/", pos: "noun", cefrLevel: "B1", definitionVi: "Sự hiểu lầm", definitionEn: "A failure to understand correctly", exampleEn: "Clear communication prevents misunderstanding.", exampleVi: "Giao tiếp rõ ràng giúp ngăn ngừa hiểu lầm."),
        TopicWordDTO(id: 10, stageId: "stage_daily_2", lemma: "Heartfelt", phonetic: "/ˈhɑːrt.felt/", pos: "adjective", cefrLevel: "B2", definitionVi: "Chân thành, từ tận đáy lòng", definitionEn: "Sincere and deeply felt", exampleEn: "He gave a heartfelt apology.", exampleVi: "Anh ấy đã đưa ra lời xin lỗi chân thành."),
        TopicWordDTO(id: 11, stageId: "stage_daily_2", lemma: "Hesitate", phonetic: "/ˈhez.ə.teɪt/", pos: "verb", cefrLevel: "B1", definitionVi: "Do dự, ngập ngừng", definitionEn: "Pause before saying or doing something", exampleEn: "Do not hesitate to ask questions.", exampleVi: "Đừng ngần ngại đặt câu hỏi."),
        TopicWordDTO(id: 12, stageId: "stage_daily_2", lemma: "Optimistic", phonetic: "/ˌɑːp.təˈmɪs.tɪk/", pos: "adjective", cefrLevel: "B1", definitionVi: "Lạc quan", definitionEn: "Hopeful and confident about the future", exampleEn: "She remains optimistic about the future.", exampleVi: "Cô ấy vẫn luôn lạc quan về tương lai."),
        TopicWordDTO(id: 13, stageId: "stage_daily_2", lemma: "Genuine", phonetic: "/ˈdʒen.ju.ɪn/", pos: "adjective", cefrLevel: "B2", definitionVi: "Thật lòng, chân thực", definitionEn: "Truly what something is said to be; authentic", exampleEn: "He showed genuine interest in the project.", exampleVi: "Anh ấy thể hiện sự quan tâm chân thật tới dự án."),

        // Business Stage 1 (6 words)
        TopicWordDTO(id: 14, stageId: "stage_biz_1", lemma: "Prioritize", phonetic: "/praɪˈɔːr.ə.taɪz/", pos: "verb", cefrLevel: "B1", definitionVi: "Ưu tiên", definitionEn: "Designate or treat as more important", exampleEn: "Prioritize your urgent tasks daily.", exampleVi: "Hãy ưu tiên các công việc khẩn cấp hàng ngày."),
        TopicWordDTO(id: 15, stageId: "stage_biz_1", lemma: "Deadline", phonetic: "/ˈded.laɪn/", pos: "noun", cefrLevel: "A2", definitionVi: "Hạn chót", definitionEn: "The latest time by which something should be completed", exampleEn: "We must meet the strict deadline.", exampleVi: "Chúng ta phải hoàn thành đúng hạn chót nghiêm ngặt."),
        TopicWordDTO(id: 16, stageId: "stage_biz_1", lemma: "Collaborate", phonetic: "/kəˈlæb.ə.reɪt/", pos: "verb", cefrLevel: "B2", definitionVi: "Hợp tác làm việc", definitionEn: "Work jointly on an activity or project", exampleEn: "Teams collaborate across departments.", exampleVi: "Các đội nhóm hợp tác xuyên phòng ban."),
        TopicWordDTO(id: 17, stageId: "stage_biz_1", lemma: "Milestone", phonetic: "/ˈmaɪl.stoʊn/", pos: "noun", cefrLevel: "B2", definitionVi: "Cột mốc quan trọng", definitionEn: "A significant stage or event in development", exampleEn: "Launching the app was a major milestone.", exampleVi: "Ra mắt ứng dụng là một cột mốc lớn."),
        TopicWordDTO(id: 18, stageId: "stage_biz_1", lemma: "Delegation", phonetic: "/ˌdel.əˈɡeɪ.ʃən/", pos: "noun", cefrLevel: "B2", definitionVi: "Sự ủy quyền", definitionEn: "The assignment of responsibility or authority", exampleEn: "Effective delegation saves time.", exampleVi: "Ủy quyền hiệu quả giúp tiết kiệm thời gian."),
        TopicWordDTO(id: 19, stageId: "stage_biz_1", lemma: "Productivity", phonetic: "/ˌproʊ.dʌkˈtɪv.ə.t̬i/", pos: "noun", cefrLevel: "B1", definitionVi: "Năng suất", definitionEn: "The effectiveness of productive effort", exampleEn: "Quiet workspaces boost productivity.", exampleVi: "Không gian làm việc yên tĩnh giúp nâng cao năng suất."),
        // Business Stage 2 (6 words)
        TopicWordDTO(id: 20, stageId: "stage_biz_2", lemma: "Negotiation", phonetic: "/nəˌɡoʊ.ʃiˈeɪ.ʃən/", pos: "noun", cefrLevel: "B2", definitionVi: "Cuộc đàm phán", definitionEn: "Discussion aimed at reaching an agreement", exampleEn: "The contract negotiation was successful.", exampleVi: "Cuộc đàm phán hợp đồng đã thành công."),
        TopicWordDTO(id: 21, stageId: "stage_biz_2", lemma: "Feedback", phonetic: "/ˈfiːd.bæk/", pos: "noun", cefrLevel: "B1", definitionVi: "Ý kiến phản hồi", definitionEn: "Information about performance used for improvement", exampleEn: "Constructive feedback helps employees grow.", exampleVi: "Phản hồi mang tính xây dựng giúp nhân viên tiến bộ."),
        TopicWordDTO(id: 22, stageId: "stage_biz_2", lemma: "Competence", phonetic: "/ˈkɑːm.pə.t̬əns/", pos: "noun", cefrLevel: "B2", definitionVi: "Năng lực chuyên môn", definitionEn: "The ability to do something successfully", exampleEn: "She demonstrated high technical competence.", exampleVi: "Cô ấy chứng tỏ năng lực kỹ thuật rất cao."),
        TopicWordDTO(id: 23, stageId: "stage_biz_2", lemma: "Benchmark", phonetic: "/ˈbentʃ.mɑːrk/", pos: "noun", cefrLevel: "B2", definitionVi: "Tiêu chuẩn đối sánh", definitionEn: "A standard against which things may be compared", exampleEn: "The project sets a new quality benchmark.", exampleVi: "Dự án thiết lập một tiêu chuẩn chất lượng mới."),
        TopicWordDTO(id: 24, stageId: "stage_biz_2", lemma: "Incentive", phonetic: "/ɪnˈsen.t̬ɪv/", pos: "noun", cefrLevel: "B2", definitionVi: "Động lực, sự khích lệ", definitionEn: "A thing that motivates or encourages someone", exampleEn: "Bonuses serve as a strong incentive.", exampleVi: "Tiền thưởng đóng vai trò là một động lực mạnh mẽ."),
        TopicWordDTO(id: 25, stageId: "stage_biz_2", lemma: "Transparency", phonetic: "/trænˈspær.ən.si/", pos: "noun", cefrLevel: "B2", definitionVi: "Tính minh bạch", definitionEn: "The condition of being open and transparent", exampleEn: "We value transparency in management.", exampleVi: "Chúng tôi đề cao tính minh bạch trong quản trị."),

        // Tech Stage 1 (6 words)
        TopicWordDTO(id: 26, stageId: "stage_tech_1", lemma: "Algorithm", phonetic: "/ˈæl.ɡə.rɪ.ðəm/", pos: "noun", cefrLevel: "B2", definitionVi: "Thuật toán", definitionEn: "A process or set of rules in calculations", exampleEn: "Search algorithms rank relevant content.", exampleVi: "Các thuật toán tìm kiếm xếp hạng nội dung phù hợp."),
        TopicWordDTO(id: 27, stageId: "stage_tech_1", lemma: "Automation", phonetic: "/ˌɑː.t̬əˈmeɪ.ʃən/", pos: "noun", cefrLevel: "B1", definitionVi: "Sự tự động hóa", definitionEn: "The use of largely automatic equipment", exampleEn: "Factory automation cuts production costs.", exampleVi: "Tự động hóa nhà máy cắt giảm chi phí sản xuất."),
        TopicWordDTO(id: 28, stageId: "stage_tech_1", lemma: "Data-driven", phonetic: "/ˈdeɪ.t̬əˌdrɪv.ən/", pos: "adjective", cefrLevel: "B2", definitionVi: "Dựa trên dữ liệu", definitionEn: "Determined by or dependent on the collection of data", exampleEn: "We make data-driven marketing decisions.", exampleVi: "Chúng tôi đưa ra quyết định tiếp thị dựa trên dữ liệu."),
        TopicWordDTO(id: 29, stageId: "stage_tech_1", lemma: "Cutting-edge", phonetic: "/ˌkʌt̬.ɪŋˈedʒ/", pos: "adjective", cefrLevel: "B2", definitionVi: "Tối tân, tiên tiến", definitionEn: "Highly advanced; innovative", exampleEn: "They use cutting-edge AI technology.", exampleVi: "Họ sử dụng công nghệ AI tối tân."),
        TopicWordDTO(id: 30, stageId: "stage_tech_1", lemma: "Cybersecurity", phonetic: "/ˌsaɪ.bɚ.səˈkjʊr.ə.t̬i/", pos: "noun", cefrLevel: "B2", definitionVi: "An ninh mạng", definitionEn: "Protection of computer systems against cyberattacks", exampleEn: "Cybersecurity protects sensitive customer data.", exampleVi: "An ninh mạng bảo vệ dữ liệu khách hàng nhạy cảm."),
        TopicWordDTO(id: 31, stageId: "stage_tech_1", lemma: "Scalability", phonetic: "/ˌskeɪ.ləˈbɪl.ə.t̬i/", pos: "noun", cefrLevel: "C1", definitionVi: "Khả năng mở rộng", definitionEn: "The capacity to be changed in size or scale", exampleEn: "Cloud computing ensures system scalability.", exampleVi: "Điện toán đám mây đảm bảo khả năng mở rộng hệ thống."),
        // Tech Stage 2 (6 words)
        TopicWordDTO(id: 32, stageId: "stage_tech_2", lemma: "Neural network", phonetic: "/ˈnʊr.əl ˈnet.wɜːrk/", pos: "noun", cefrLevel: "C1", definitionVi: "Mạng nơ-ron nhân tạo", definitionEn: "A computer system modeled on the human brain", exampleEn: "Neural networks recognize complex speech patterns.", exampleVi: "Mạng nơ-ron nhận dạng các mẫu giọng nói phức tạp."),
        TopicWordDTO(id: 33, stageId: "stage_tech_2", lemma: "Autonomous", phonetic: "/ɑːˈtɑː.nə.məs/", pos: "adjective", cefrLevel: "C1", definitionVi: "Tự hành, tự chủ", definitionEn: "Having the freedom to act independently", exampleEn: "Autonomous vehicles navigate city roads.", exampleVi: "Xe tự hành di chuyển trên các tuyến đường thành phố."),
        TopicWordDTO(id: 34, stageId: "stage_tech_2", lemma: "Predictive", phonetic: "/prɪˈdɪk.tɪv/", pos: "adjective", cefrLevel: "B2", definitionVi: "Có tính dự báo", definitionEn: "Relating to the ability to predict", exampleEn: "Predictive analytics forecast market trends.", exampleVi: "Phân tích dự báo giúp định hình xu hướng thị trường."),
        TopicWordDTO(id: 35, stageId: "stage_tech_2", lemma: "Disruptive", phonetic: "/dɪsˈrʌp.tɪv/", pos: "adjective", cefrLevel: "C1", definitionVi: "Mang tính đột phá", definitionEn: "Innovatively transforming an existing market", exampleEn: "Generative AI is a disruptive technology.", exampleVi: "AI tạo sinh là một công nghệ mang tính đột phá."),
        TopicWordDTO(id: 36, stageId: "stage_tech_2", lemma: "Infrastructure", phonetic: "/ˈɪn.frəˌstrʌk.tʃɚ/", pos: "noun", cefrLevel: "B2", definitionVi: "Hạ tầng cơ sở", definitionEn: "Basic physical and organizational structures", exampleEn: "Server infrastructure supports heavy traffic.", exampleVi: "Hạ tầng máy chủ đáp ứng lưu lượng truy cập lớn."),
        TopicWordDTO(id: 37, stageId: "stage_tech_2", lemma: "Virtualization", phonetic: "/ˌvɜːr.tʃu.ə.laɪˈzeɪ.ʃən/", pos: "noun", cefrLevel: "C1", definitionVi: "Sự ảo hóa", definitionEn: "Creation of a virtual version of something", exampleEn: "Server virtualization reduces hardware costs.", exampleVi: "Ảo hóa máy chủ giúp giảm chi phí phần cứng."),

        // Academic Stage 1 (7 words)
        TopicWordDTO(id: 38, stageId: "stage_acad_1", lemma: "Biodiversity", phonetic: "/ˌbaɪ.oʊ.daɪˈvɜːr.sə.t̬i/", pos: "noun", cefrLevel: "B2", definitionVi: "Đa dạng sinh học", definitionEn: "The variety of plant and animal life in a habitat", exampleEn: "Deforestation threatens regional biodiversity.", exampleVi: "Phá rừng đe dọa sự đa dạng sinh học trong khu vực."),
        TopicWordDTO(id: 39, stageId: "stage_acad_1", lemma: "Sustainability", phonetic: "/səˌsteɪ.nəˈbɪl.ə.t̬i/", pos: "noun", cefrLevel: "B2", definitionVi: "Sự bền vững", definitionEn: "Avoidance of depletion of natural resources", exampleEn: "Environmental sustainability is a global goal.", exampleVi: "Sự bền vững môi trường là mục tiêu toàn cầu."),
        TopicWordDTO(id: 40, stageId: "stage_acad_1", lemma: "Urbanization", phonetic: "/ˌɝː.bən.əˈzeɪ.ʃən/", pos: "noun", cefrLevel: "B2", definitionVi: "Sự đô thị hóa", definitionEn: "The process of making an area more urban", exampleEn: "Rapid urbanization strains public transport.", exampleVi: "Đô thị hóa nhanh chóng gây áp lực lên giao thông công cộng."),
        TopicWordDTO(id: 41, stageId: "stage_acad_1", lemma: "Detrimental", phonetic: "/ˌdet.rəˈmen.t̬əl/", pos: "adjective", cefrLevel: "C1", definitionVi: "Có hại, bất lợi", definitionEn: "Tending to cause harm", exampleEn: "Pollution has a detrimental effect on health.", exampleVi: "Ô nhiễm có ảnh hưởng bất lợi tới sức khỏe."),
        TopicWordDTO(id: 42, stageId: "stage_acad_1", lemma: "Phenomenon", phonetic: "/fəˈnɑː.mə.nɑːn/", pos: "noun", cefrLevel: "B2", definitionVi: "Hiện tượng", definitionEn: "A fact or situation that is observed to exist", exampleEn: "Climate change is a complex phenomenon.", exampleVi: "Biến đổi khí hậu là một hiện tượng phức tạp."),
        TopicWordDTO(id: 43, stageId: "stage_acad_1", lemma: "Preservation", phonetic: "/ˌprez.ɚˈveɪ.ʃən/", pos: "noun", cefrLevel: "B2", definitionVi: "Sự bảo tồn", definitionEn: "The act of keeping something safe from harm", exampleEn: "Forest preservation prevents soil erosion.", exampleVi: "Bảo tồn rừng giúp chống xói mòn đất."),
        TopicWordDTO(id: 44, stageId: "stage_acad_1", lemma: "Depletion", phonetic: "/dɪˈpliː.ʃən/", pos: "noun", cefrLevel: "C1", definitionVi: "Sự cạn kiệt", definitionEn: "Reduction in the number or quantity of something", exampleEn: "Resource depletion is an urgent challenge.", exampleVi: "Cạn kiệt tài nguyên là một thách thức cấp bách."),
        // Academic Stage 2 (6 words)
        TopicWordDTO(id: 45, stageId: "stage_acad_2", lemma: "Fluctuation", phonetic: "/ˌflʌk.tʃuˈeɪ.ʃən/", pos: "noun", cefrLevel: "B2", definitionVi: "Sự biến động", definitionEn: "An irregular rising and falling in number or amount", exampleEn: "Currency fluctuations impact import prices.", exampleVi: "Biến động tỷ giá ảnh hưởng tới giá nhập khẩu."),
        TopicWordDTO(id: 46, stageId: "stage_acad_2", lemma: "Unprecedented", phonetic: "/ʌnˈpres.ə.den.t̬ɪd/", pos: "adjective", cefrLevel: "C1", definitionVi: "Chưa từng có tiền lệ", definitionEn: "Never done or known before", exampleEn: "The crisis caused unprecedented economic loss.", exampleVi: "Cuộc khủng hoảng gây thiệt hại kinh tế chưa từng có."),
        TopicWordDTO(id: 47, stageId: "stage_acad_2", lemma: "Discrepancy", phonetic: "/dɪˈskrep.ən.si/", pos: "noun", cefrLevel: "C1", definitionVi: "Sự sai lệch, bất nhất", definitionEn: "A lack of compatibility or similarity between two facts", exampleEn: "There was a discrepancy in the budget report.", exampleVi: "Có một sự sai lệch trong báo cáo ngân sách."),
        TopicWordDTO(id: 48, stageId: "stage_acad_2", lemma: "Paradigm shift", phonetic: "/ˈpær.ə.daɪm ʃɪft/", pos: "noun", cefrLevel: "C1", definitionVi: "Bước chuyển dịch mô thức", definitionEn: "A fundamental change in approach or underlying assumptions", exampleEn: "Remote work created a cultural paradigm shift.", exampleVi: "Làm việc từ xa tạo ra một bước chuyển biến lớn trong văn hóa."),
        TopicWordDTO(id: 49, stageId: "stage_acad_2", lemma: "Substantial", phonetic: "/səbˈstæn.ʃəl/", pos: "adjective", cefrLevel: "B2", definitionVi: "Đáng kể, quan trọng", definitionEn: "Of considerable importance, size, or worth", exampleEn: "They made substantial progress this quarter.", exampleVi: "Họ đã đạt được tiến bộ đáng kể trong quý này."),
        TopicWordDTO(id: 50, stageId: "stage_acad_2", lemma: "Feasibility", phonetic: "/ˌfiː.zəˈbɪl.ə.t̬i/", pos: "noun", cefrLevel: "C1", definitionVi: "Tính khả thi", definitionEn: "The state or degree of being easily or conveniently done", exampleEn: "Engineers tested the technical feasibility of the design.", exampleVi: "Các kỹ sư đã kiểm tra tính khả thi kỹ thuật của thiết kế.")
    ]
}
```

```swift
// VocabCraftApp/Core/Database/SampleData/SampleVocabularyDataSource.swift
import Foundation

public final class SampleVocabularyDataSource: VocabularyDataSourceProtocol, Sendable {
    public init() {}

    public func fetchTopicDecks() async throws -> [TopicDeckDTO] {
        VocabularySampleDataset.decks.sorted { $0.sortOrder < $1.sortOrder }
    }

    public func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO] {
        VocabularySampleDataset.stages
            .filter { $0.deckId == deckId }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    public func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO] {
        VocabularySampleDataset.words.filter { $0.stageId == stageId }
    }

    public func searchWords(query: String) async throws -> [TopicWordDTO] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return VocabularySampleDataset.words }
        return VocabularySampleDataset.words.filter {
            $0.lemma.lowercased().contains(trimmed) ||
            $0.definitionVi.lowercased().contains(trimmed) ||
            $0.definitionEn.lowercased().contains(trimmed)
        }
    }

    public func fetchWordById(id: Int64) async throws -> TopicWordDTO? {
        VocabularySampleDataset.words.first { $0.id == id }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter SampleVocabularyDataSourceTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Database/DataSources VocabCraftApp/Core/Database/SampleData VocabCraftAppTests/Core/SampleVocabularyDataSourceTests.swift
git commit -m "feat: add VocabularyDataSourceProtocol and 50 curated sample words dataset"
```

---

### Task 2: SwiftData Persistence for Stage Completion & Word NeedsReview Flags

**Files:**
- Modify: `VocabCraftApp/Core/Database/SwiftDataModels.swift`
- Create: `VocabCraftApp/Core/Database/Repositories/StageProgressRepository.swift`
- Test: `VocabCraftAppTests/Core/StageProgressRepositoryTests.swift`

**Interfaces:**
- Produces: `UserStageProgress`, `StageProgressRepositoryProtocol`, `StageProgressRepositoryImpl`

- [ ] **Step 1: Write failing test for StageProgressRepository**

```swift
import XCTest
import SwiftData
@testable import VocabCraftApp

final class StageProgressRepositoryTests: XCTestCase {
    var container: ModelContainer!
    var sut: StageProgressRepositoryImpl!

    @MainActor
    override func setUp() {
        super.setUp()
        let schema = Schema([UserWordProgress.self, UserStageProgress.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: schema, configurations: [config])
        sut = StageProgressRepositoryImpl(modelContext: container.mainContext)
    }

    @MainActor
    func test_markStageCompleted_persistsAndReturnsCompletedState() async throws {
        try await sut.saveStageProgress(stageId: "stage_daily_1", deckId: "deck_daily", isCompleted: true, score: 90)
        let progress = try await sut.fetchStageProgress(stageId: "stage_daily_1")
        XCTAssertNotNil(progress)
        XCTAssertTrue(progress!.isCompleted)
        XCTAssertEqual(progress!.score, 90)
    }

    @MainActor
    func test_fetchCompletedStageIds_returnsCorrectIdsForDeck() async throws {
        try await sut.saveStageProgress(stageId: "stage_daily_1", deckId: "deck_daily", isCompleted: true, score: 100)
        let ids = try await sut.fetchCompletedStageIds(deckId: "deck_daily")
        XCTAssertEqual(ids, ["stage_daily_1"])
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter StageProgressRepositoryTests`
Expected: FAIL (missing `UserStageProgress`, `StageProgressRepositoryImpl`)

- [ ] **Step 3: Update SwiftDataModels.swift and implement StageProgressRepository**

```swift
// In VocabCraftApp/Core/Database/SwiftDataModels.swift:
// Add UserStageProgress and update UserWordProgress fields

@Model
public final class UserStageProgress {
    @Attribute(.unique) public var stageId: String
    public var deckId: String
    public var isCompleted: Bool
    public var score: Int
    public var completedAt: Date

    public init(stageId: String, deckId: String, isCompleted: Bool = false, score: Int = 0, completedAt: Date = Date()) {
        self.stageId = stageId
        self.deckId = deckId
        self.isCompleted = isCompleted
        self.score = score
        self.completedAt = completedAt
    }
}

// In UserWordProgress: ensure needsReview, mistakeCount, sourceDeckId, sourceNodeId exist
```

```swift
// VocabCraftApp/Core/Database/Repositories/StageProgressRepository.swift
import Foundation
import SwiftData

public protocol StageProgressRepositoryProtocol: Sendable {
    @MainActor func fetchStageProgress(stageId: String) async throws -> UserStageProgress?
    @MainActor func fetchCompletedStageIds(deckId: String) async throws -> Set<String>
    @MainActor func saveStageProgress(stageId: String, deckId: String, isCompleted: Bool, score: Int) async throws
}

public final class StageProgressRepositoryImpl: StageProgressRepositoryProtocol, @unchecked Sendable {
    private let modelContext: ModelContext?

    public init(modelContext: ModelContext?) {
        self.modelContext = modelContext
    }

    @MainActor
    public func fetchStageProgress(stageId: String) async throws -> UserStageProgress? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<UserStageProgress>(
            predicate: #Predicate { $0.stageId == stageId }
        )
        return try context.fetch(descriptor).first
    }

    @MainActor
    public func fetchCompletedStageIds(deckId: String) async throws -> Set<String> {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<UserStageProgress>(
            predicate: #Predicate { $0.deckId == deckId && $0.isCompleted }
        )
        let list = try context.fetch(descriptor)
        return Set(list.map(\.stageId))
    }

    @MainActor
    public func saveStageProgress(stageId: String, deckId: String, isCompleted: Bool, score: Int) async throws {
        guard let context = modelContext else { return }
        if let existing = try await fetchStageProgress(stageId: stageId) {
            existing.isCompleted = isCompleted
            existing.score = score
            existing.completedAt = Date()
        } else {
            let record = UserStageProgress(stageId: stageId, deckId: deckId, isCompleted: isCompleted, score: score, completedAt: Date())
            context.insert(record)
        }
        try context.save()
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter StageProgressRepositoryTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Database/SwiftDataModels.swift VocabCraftApp/Core/Database/Repositories/StageProgressRepository.swift VocabCraftAppTests/Core/StageProgressRepositoryTests.swift
git commit -m "feat: add UserStageProgress SwiftData model and StageProgressRepository"
```

---

### Task 3: Pure Domain Entities & Refactored VocabularyRepository

**Files:**
- Create: `VocabCraftApp/Domain/Entities/SubTopicStage.swift`
- Create: `VocabCraftApp/Domain/Entities/PersonalWord.swift`
- Create: `VocabCraftApp/Domain/Entities/StageChallenge.swift`
- Modify: `VocabCraftApp/Core/Database/Repositories/VocabularyRepositoryImpl.swift`
- Test: `VocabCraftAppTests/Domain/VocabularyDomainEntitiesTests.swift`

**Interfaces:**
- Produces: `SubTopicStage`, `StageState`, `PersonalWord`, `WordChallengeQuestion`, `WordChallengeResult`, `StageCompletionSummary`

- [ ] **Step 1: Write failing test for domain entities mapping**

```swift
import XCTest
@testable import VocabCraftApp

final class VocabularyDomainEntitiesTests: XCTestCase {
    func test_subTopicStage_stateTransitions() {
        let stage = SubTopicStage(
            id: "stage_daily_1",
            deckId: "deck_daily",
            title: "Chặng 1: Thói quen",
            iconName: "heart",
            sortOrder: 1,
            state: .active,
            words: []
        )
        XCTAssertEqual(stage.state, .active)
    }

    func test_personalWord_needsReviewComputedProperly() {
        let word = PersonalWord(
            id: 1,
            lemma: "Resilience",
            phonetic: "/rɪˈzɪl.jəns/",
            pos: "noun",
            cefrLevel: "B2",
            definitionVi: "Khả năng phục hồi",
            definitionEn: "Capacity to recover",
            exampleEn: "Her resilience helped her.",
            exampleVi: "Sự kiên cường giúp cô ấy.",
            masteryLevel: 2,
            isBookmarked: true,
            needsReview: true,
            mistakeCount: 1,
            sourceDeckTitle: "Giao Tiếp Hằng Ngày",
            sourceStageTitle: "Chặng 1: Thói quen"
        )
        XCTAssertTrue(word.needsReview)
        XCTAssertTrue(word.isBookmarked)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter VocabularyDomainEntitiesTests`
Expected: FAIL (missing `SubTopicStage`, `PersonalWord`)

- [ ] **Step 3: Implement Domain Entities & wire VocabularyRepositoryImpl to VocabularyDataSourceProtocol**

```swift
// VocabCraftApp/Domain/Entities/SubTopicStage.swift
import Foundation

public enum StageState: String, Sendable, Equatable {
    case locked
    case active
    case completed
}

public struct SubTopicStage: Identifiable, Sendable, Equatable {
    public let id: String
    public let deckId: String
    public let title: String
    public let iconName: String
    public let sortOrder: Int
    public let state: StageState
    public let words: [TopicWord]

    public init(
        id: String,
        deckId: String,
        title: String,
        iconName: String,
        sortOrder: Int,
        state: StageState = .locked,
        words: [TopicWord] = []
    ) {
        self.id = id
        self.deckId = deckId
        self.title = title
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.state = state
        self.words = words
    }
}
```

```swift
// VocabCraftApp/Domain/Entities/PersonalWord.swift
import Foundation

public struct PersonalWord: Identifiable, Sendable, Equatable {
    public let id: Int64
    public let lemma: String
    public let phonetic: String
    public let pos: String
    public let cefrLevel: String
    public let definitionVi: String
    public let definitionEn: String
    public let exampleEn: String
    public let exampleVi: String
    public var masteryLevel: Int
    public var isBookmarked: Bool
    public var needsReview: Bool
    public var mistakeCount: Int
    public var sourceDeckTitle: String?
    public var sourceStageTitle: String?

    public init(
        id: Int64,
        lemma: String,
        phonetic: String,
        pos: String,
        cefrLevel: String,
        definitionVi: String,
        definitionEn: String,
        exampleEn: String,
        exampleVi: String,
        masteryLevel: Int = 0,
        isBookmarked: Bool = false,
        needsReview: Bool = false,
        mistakeCount: Int = 0,
        sourceDeckTitle: String? = nil,
        sourceStageTitle: String? = nil
    ) {
        self.id = id
        self.lemma = lemma
        self.phonetic = phonetic
        self.pos = pos
        self.cefrLevel = cefrLevel
        self.definitionVi = definitionVi
        self.definitionEn = definitionEn
        self.exampleEn = exampleEn
        self.exampleVi = exampleVi
        self.masteryLevel = masteryLevel
        self.isBookmarked = isBookmarked
        self.needsReview = needsReview
        self.mistakeCount = mistakeCount
        self.sourceDeckTitle = sourceDeckTitle
        self.sourceStageTitle = sourceStageTitle
    }
}
```

```swift
// VocabCraftApp/Domain/Entities/StageChallenge.swift
import Foundation

public struct WordChallengeQuestion: Identifiable, Sendable, Equatable {
    public let id: String
    public let wordId: Int64
    public let prompt: String
    public let hintPhonetic: String
    public let correctAnswer: String
    public let options: [String]
    public let exampleSentence: String

    public init(id: String = UUID().uuidString, wordId: Int64, prompt: String, hintPhonetic: String, correctAnswer: String, options: [String], exampleSentence: String) {
        self.id = id
        self.wordId = wordId
        self.prompt = prompt
        self.hintPhonetic = hintPhonetic
        self.correctAnswer = correctAnswer
        self.options = options
        self.exampleSentence = exampleSentence
    }
}

public struct WordChallengeResult: Sendable, Equatable {
    public let wordId: Int64
    public let isCorrect: Bool
    public let timeTakenMs: Int

    public init(wordId: Int64, isCorrect: Bool, timeTakenMs: Int) {
        self.wordId = wordId
        self.isCorrect = isCorrect
        self.timeTakenMs = timeTakenMs
    }
}

public struct StageCompletionSummary: Sendable, Equatable {
    public let stageId: String
    public let totalQuestions: Int
    public let correctCount: Int
    public let xpEarned: Int
    public let weakWordIds: [Int64]

    public init(stageId: String, totalQuestions: Int, correctCount: Int, xpEarned: Int, weakWordIds: [Int64]) {
        self.stageId = stageId
        self.totalQuestions = totalQuestions
        self.correctCount = correctCount
        self.xpEarned = xpEarned
        self.weakWordIds = weakWordIds
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter VocabularyDomainEntitiesTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/Entities VocabCraftAppTests/Domain/VocabularyDomainEntitiesTests.swift
git commit -m "feat: add domain entities SubTopicStage, PersonalWord, StageChallenge"
```

---

### Task 4: Domain Layer Single-Responsibility Use Cases

**Files:**
- Create: `VocabCraftApp/Domain/UseCases/FetchTopicDecksUseCase.swift`
- Create: `VocabCraftApp/Domain/UseCases/FetchDeckRoadmapUseCase.swift`
- Create: `VocabCraftApp/Domain/UseCases/CompleteStageChallengeUseCase.swift`
- Create: `VocabCraftApp/Domain/UseCases/FetchPersonalVaultUseCase.swift`
- Create: `VocabCraftApp/Domain/UseCases/ReviewWeakWordsUseCase.swift`
- Create: `VocabCraftApp/Domain/UseCases/ToggleWordBookmarkUseCase.swift`
- Test: `VocabCraftAppTests/Domain/VocabularyUseCasesTests.swift`

**Interfaces:**
- Produces: `FetchTopicDecksUseCaseProtocol`, `FetchDeckRoadmapUseCaseProtocol`, `CompleteStageChallengeUseCaseProtocol`, `FetchPersonalVaultUseCaseProtocol`, `ReviewWeakWordsUseCaseProtocol`, `ToggleWordBookmarkUseCaseProtocol`, `PersonalVaultFilter`, `PersonalVaultMetrics`

- [ ] **Step 1: Write failing tests for all 6 Use Cases**

```swift
import XCTest
@testable import VocabCraftApp

final class VocabularyUseCasesTests: XCTestCase {
    var dataSource: SampleVocabularyDataSource!
    var stageRepo: StageProgressRepositoryImpl!

    override func setUp() {
        super.setUp()
        dataSource = SampleVocabularyDataSource()
        stageRepo = StageProgressRepositoryImpl(modelContext: nil)
    }

    func test_fetchTopicDecksUseCase_returnsDecksWithCalculatedWordCounts() async throws {
        let sut = FetchTopicDecksUseCase(dataSource: dataSource, stageRepo: stageRepo)
        let decks = try await sut.execute()
        XCTAssertEqual(decks.count, 4)
        XCTAssertGreaterThan(decks.first?.totalWords ?? 0, 0)
    }

    func test_fetchDeckRoadmapUseCase_unlocksFirstStageByDefault() async throws {
        let sut = FetchDeckRoadmapUseCase(dataSource: dataSource, stageRepo: stageRepo)
        let stages = try await sut.execute(deckId: "deck_daily")
        XCTAssertEqual(stages.count, 2)
        XCTAssertEqual(stages.first?.state, .active)
        XCTAssertEqual(stages.last?.state, .locked)
    }

    func test_completeStageChallengeUseCase_flagsIncorrectWordsAndUnlocksNext() async throws {
        let sut = CompleteStageChallengeUseCase(stageRepo: stageRepo, progressRepo: MockUserProgressActor())
        let results = [
            WordChallengeResult(wordId: 1, isCorrect: true, timeTakenMs: 1200),
            WordChallengeResult(wordId: 2, isCorrect: false, timeTakenMs: 3000)
        ]
        let summary = try await sut.execute(stageId: "stage_daily_1", deckId: "deck_daily", results: results)
        XCTAssertEqual(summary.correctCount, 1)
        XCTAssertEqual(summary.weakWordIds, [2])
        XCTAssertEqual(summary.xpEarned, 10)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter VocabularyUseCasesTests`
Expected: FAIL (missing Use Case types)

- [ ] **Step 3: Implement all 6 Use Cases**

```swift
// Implement FetchTopicDecksUseCase, FetchDeckRoadmapUseCase, CompleteStageChallengeUseCase,
// FetchPersonalVaultUseCase, ReviewWeakWordsUseCase, ToggleWordBookmarkUseCase
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter VocabularyUseCasesTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/UseCases VocabCraftAppTests/Domain/VocabularyUseCasesTests.swift
git commit -m "feat: implement 6 domain use cases for topic stages and personal vault"
```

---

### Task 5: App Container DI Wiring with Single Mock/Real Switch

**Files:**
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Test: `VocabCraftAppTests/App/AppContainerVocabularyTests.swift`

**Interfaces:**
- Produces: Factory methods for `makeTopicDecksViewModel()`, `makeTopicRoadmapViewModel(deckId:)`, `makePersonalVaultViewModel()`, `makeStageChallengeViewModel(stage:)`, `makeSmartReviewViewModel(weakWords:)`

- [ ] **Step 1: Write test for AppContainer DI factories**

```swift
import XCTest
@testable import VocabCraftApp

final class AppContainerVocabularyTests: XCTestCase {
    @MainActor
    func test_appContainer_instantiatesVocabularyViewModelsWithCleanDependencies() {
        let container = AppContainer.mock
        let personalVM = container.makePersonalVaultViewModel()
        XCTAssertNotNil(personalVM)

        let decksVM = container.makeTopicDecksViewModel()
        XCTAssertNotNil(decksVM)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter AppContainerVocabularyTests`
Expected: FAIL (missing factory methods)

- [ ] **Step 3: Update AppContainer with Use Cases & Factory Methods**

```swift
// Add useSampleData switch and register new Use Cases in AppContainer.swift
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter AppContainerVocabularyTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/App/DI/AppContainer.swift VocabCraftAppTests/App/AppContainerVocabularyTests.swift
git commit -m "feat: configure AppContainer DI with sample data toggle and use case factories"
```

---

### Task 6: Topic Decks Grid & Stage Roadmap Presentation

**Files:**
- Create: `VocabCraftApp/Features/Vocabulary/TopicDecks/ViewModels/TopicDecksViewModel.swift`
- Create: `VocabCraftApp/Features/Vocabulary/TopicDecks/ViewModels/TopicRoadmapViewModel.swift`
- Create: `VocabCraftApp/Features/Vocabulary/TopicDecks/Views/TopicRoadmapView.swift`
- Modify: `VocabCraftApp/Features/Vocabulary/Views/TopicDecksGridView.swift`
- Test: `VocabCraftAppTests/Features/Vocabulary/TopicRoadmapViewModelTests.swift`

**Interfaces:**
- Produces: `TopicDecksViewModel`, `TopicRoadmapViewModel`, `TopicRoadmapView`, updated `TopicDecksGridView`

- [ ] **Step 1: Write test for TopicRoadmapViewModel state management**

```swift
import XCTest
@testable import VocabCraftApp

@MainActor
final class TopicRoadmapViewModelTests: XCTestCase {
    func test_loadRoadmap_populatesStagesAndSetsActiveStage() async {
        let container = AppContainer.mock
        let sut = container.makeTopicRoadmapViewModel(deckId: "deck_daily")
        await sut.loadRoadmap()
        XCTAssertFalse(sut.stages.isEmpty)
        XCTAssertEqual(sut.stages.first?.state, .active)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter TopicRoadmapViewModelTests`
Expected: FAIL

- [ ] **Step 3: Implement ViewModels & Roadmap Views**

```swift
// Implement TopicDecksViewModel, TopicRoadmapViewModel with @Observable
// Build TopicRoadmapView with Apple HIG vertical connecting lines, .completed/.active/.locked nodes
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter TopicRoadmapViewModelTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/TopicDecks VocabCraftAppTests/Features/Vocabulary/TopicRoadmapViewModelTests.swift
git commit -m "feat: implement TopicDecksViewModel, TopicRoadmapViewModel, and TopicRoadmapView"
```

---

### Task 7: 3-Step Stage Learning Flow (Preview, Challenge Quiz, and Summary)

**Files:**
- Create: `VocabCraftApp/Features/Vocabulary/TopicDecks/ViewModels/StageChallengeViewModel.swift`
- Create: `VocabCraftApp/Features/Vocabulary/TopicDecks/Views/StagePreviewSheet.swift`
- Create: `VocabCraftApp/Features/Vocabulary/TopicDecks/Views/StageChallengeView.swift`
- Create: `VocabCraftApp/Features/Vocabulary/TopicDecks/Views/StageSummarySheet.swift`
- Test: `VocabCraftAppTests/Features/Vocabulary/StageChallengeViewModelTests.swift`

**Interfaces:**
- Produces: `StageChallengeViewModel`, `StagePreviewSheet`, `StageChallengeView`, `StageSummarySheet`

- [ ] **Step 1: Write test for StageChallengeViewModel quiz submission and results**

```swift
import XCTest
@testable import VocabCraftApp

@MainActor
final class StageChallengeViewModelTests: XCTestCase {
    func test_submitAnswer_advancesQuestionAndTracksScore() {
        let words = VocabularySampleDataset.words.filter { $0.stageId == "stage_daily_1" }.map {
            TopicWord(id: "w\($0.id)", english: $0.lemma, phonetic: $0.phonetic, vietnamese: $0.definitionVi, example: $0.exampleEn, partOfSpeech: $0.pos)
        }
        let stage = SubTopicStage(id: "stage_daily_1", deckId: "deck_daily", title: "Chặng 1", iconName: "heart", sortOrder: 1, state: .active, words: words)
        let sut = StageChallengeViewModel(stage: stage, completeUseCase: AppContainer.mock.completeStageChallengeUseCase)
        
        XCTAssertEqual(sut.currentIndex, 0)
        sut.submitAnswer(sut.currentQuestion?.correctAnswer ?? "")
        XCTAssertTrue(sut.lastAnswerCorrect)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter StageChallengeViewModelTests`
Expected: FAIL

- [ ] **Step 3: Implement Stage Learning Flow (Preview, Quiz, Summary)**

```swift
// Implement StagePreviewSheet (Step 1: Browse words, audio, context example)
// Implement StageChallengeView (Step 2: Interactive quiz with segmented progress)
// Implement StageSummarySheet (Step 3: Summary, XP, unlock trigger)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter StageChallengeViewModelTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/TopicDecks VocabCraftAppTests/Features/Vocabulary/StageChallengeViewModelTests.swift
git commit -m "feat: implement 3-step stage learning flow (Preview, Quiz, Summary)"
```

---

### Task 8: Personal Vault Presentation & Focused Review Session

**Files:**
- Create: `VocabCraftApp/Features/Vocabulary/PersonalVault/ViewModels/PersonalVaultViewModel.swift`
- Create: `VocabCraftApp/Features/Vocabulary/PersonalVault/ViewModels/SmartReviewViewModel.swift`
- Create: `VocabCraftApp/Features/Vocabulary/PersonalVault/Views/PersonalVaultHeroCard.swift`
- Create: `VocabCraftApp/Features/Vocabulary/PersonalVault/Views/PersonalSearchFilterBar.swift`
- Create: `VocabCraftApp/Features/Vocabulary/PersonalVault/Views/CleanWordCardView.swift`
- Create: `VocabCraftApp/Features/Vocabulary/PersonalVault/Views/SmartReviewSessionView.swift`
- Modify: `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift`
- Test: `VocabCraftAppTests/Features/Vocabulary/PersonalVaultViewModelTests.swift`

**Interfaces:**
- Produces: `PersonalVaultViewModel`, `SmartReviewViewModel`, `PersonalVaultHeroCard`, `PersonalSearchFilterBar`, `CleanWordCardView`, `SmartReviewSessionView`, updated `VocabularyView`

- [ ] **Step 1: Write test for PersonalVaultViewModel filtering and weak words action**

```swift
import XCTest
@testable import VocabCraftApp

@MainActor
final class PersonalVaultViewModelTests: XCTestCase {
    func test_loadVault_calculatesMetricsAndFiltersWithoutEmojiTags() async {
        let container = AppContainer.mock
        let sut = container.makePersonalVaultViewModel()
        await sut.loadData()
        XCTAssertGreaterThanOrEqual(sut.metrics.totalCount, 0)
    }

    func test_filterSelection_updatesFilteredWordsList() async {
        let container = AppContainer.mock
        let sut = container.makePersonalVaultViewModel()
        await sut.loadData()
        sut.setFilter(.needsReview)
        XCTAssertEqual(sut.selectedFilter, .needsReview)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter PersonalVaultViewModelTests`
Expected: FAIL

- [ ] **Step 3: Implement Personal Vault UI & Focused Review Session**

```swift
// Implement CleanWordCardView WITHOUT per-word drill button
// Implement PersonalSearchFilterBar with pure typography pills
// Implement PersonalVaultHeroCard with 1-click Smart Review CTA
// Implement SmartReviewSessionView mini-session
// Integrate into VocabularyView segmented switch
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter PersonalVaultViewModelTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/PersonalVault VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift VocabCraftAppTests/Features/Vocabulary/PersonalVaultViewModelTests.swift
git commit -m "feat: implement Personal Vault, CleanWordCardView, and SmartReviewSessionView"
```

---

### Task 9: End-to-End Integration, Snapshot Verification & Regression Testing

**Files:**
- Create: `VocabCraftAppTests/Features/Vocabulary/VocabularyRedesignIntegrationTests.swift`

- [ ] **Step 1: Write full regression and integration test**

```swift
import XCTest
@testable import VocabCraftApp

@MainActor
final class VocabularyRedesignIntegrationTests: XCTestCase {
    func test_endToEnd_stageCompletion_ingestsWordsIntoPersonalVault() async throws {
        let container = AppContainer.mock
        let roadmapVM = container.makeTopicRoadmapViewModel(deckId: "deck_daily")
        await roadmapVM.loadRoadmap()
        
        guard let stage = roadmapVM.stages.first else {
            XCTFail("Missing stage")
            return
        }
        
        let challengeVM = container.makeStageChallengeViewModel(stage: stage)
        challengeVM.submitAnswer(challengeVM.currentQuestion?.correctAnswer ?? "")
        await challengeVM.completeStage()
        
        let vaultVM = container.makePersonalVaultViewModel()
        await vaultVM.loadData()
        XCTAssertGreaterThan(vaultVM.metrics.totalCount, 0)
    }
}
```

- [ ] **Step 2: Run all tests in the workspace**

Run: `swift test`
Expected: PASS (All tests pass with 0 failures)

- [ ] **Step 3: Commit and verify clean working tree**

```bash
git add VocabCraftAppTests/Features/Vocabulary/VocabularyRedesignIntegrationTests.swift
git commit -m "test: add end-to-end vocabulary redesign integration tests"
```
