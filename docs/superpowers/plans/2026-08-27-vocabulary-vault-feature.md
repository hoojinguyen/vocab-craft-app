# Feature 4: Kho Từ — Vocabulary Vault Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Xây dựng hoàn chỉnh phân hệ Kho Từ (Vocabulary Vault) với giao diện tối giản hỗ trợ Active Recall (chỉ hiện từ, loại từ, IPA, nút bookmark), bộ lọc 3 tab có số đếm, nút Ôn luyện nổi bật trên top tích hợp Mixed Reflex Session, và Bottom Sheet chi tiết từ vựng song ngữ.

**Architecture:** Áp dụng Clean Architecture và mô hình MV (@Observable) hiện đại trong SwiftUI: `FetchPersonalVaultUseCase` kết hợp SQLite dataset và SwiftData `UserWordProgress`, `PersonalVaultViewModel` quản lý state tập trung, giao diện lắp ghép (composed) 100% từ Design Tokens và atomic components của `CraftUIKit`.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, SQLite, CraftUIKit (Design System), SpeechKit / AVSpeechSynthesizer, Swift Testing (`@Suite`, `@Test`, `#expect`).

**Spec:** `docs/superpowers/specs/2026-08-27-vocabulary-vault-feature-design.md`

## Global Constraints

- **Zero Hardcoded Strings**: 100% chuỗi hiển thị sử dụng `Localizable.xcstrings` với tiền tố `app.vault.*`, đảm bảo đầy đủ bản dịch song ngữ EN và VI với `extractionState: "manual"` và `state: "translated"`.
- **Zero Raw Styling**: 100% màu sắc, typography, khoảng cách, bo góc sử dụng Design Tokens từ `CraftUIKit` (`CraftColor`, `CraftFont`, `CraftSpacingTokens`, `CraftRadiusTokens`).
- **Quality Gate**: 0 lỗi compiler, 0 Swift Concurrency diagnostics, 0 SwiftLint warning, 100% unit tests pass.

---

### Task 1: Khai báo Chuỗi Đa Ngôn Ngữ (Localization Keys)

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Test: `VocabCraftAppTests/Features/PersonalVaultLocalizationTests.swift`

**Interfaces:**
- Produces: Chuỗi bản dịch chuẩn hóa cho toàn bộ màn hình Kho Từ với taxonomy `app.vault.*`.

- [ ] **Step 1: Viết test kiểm tra sự tồn tại của các key đa ngôn ngữ cho Kho Từ**

```swift
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("PersonalVault Localization Tests")
struct PersonalVaultLocalizationTests {
    @Test("Kiểm tra sự tồn tại của các localization keys trong kho từ")
    func testVaultLocalizationKeysExist() {
        let keys = [
            "app.vault.title",
            "app.vault.search_placeholder",
            "app.vault.filter.not_mastered",
            "app.vault.filter.mastered",
            "app.vault.filter.bookmarked",
            "app.vault.action.review_words",
            "app.vault.empty.not_mastered",
            "app.vault.empty.mastered",
            "app.vault.empty.bookmarked",
            "app.vault.empty.search_no_results",
            "app.vault.detail.definitions_title",
            "app.vault.detail.examples_title",
            "app.vault.detail.progress_title",
            "app.vault.detail.streak_count",
            "app.vault.detail.practiced_modes"
        ]

        for key in keys {
            let localizedVI = String(localized: String.LocalizationValue(key), bundle: Bundle.main, locale: Locale(identifier: "vi"))
            #expect(!localizedVI.isEmpty, "Missing Vietnamese localization for key: \(key)")
            #expect(localizedVI != key, "Key \(key) is not localized in Vietnamese")
        }
    }
}
```

- [ ] **Step 2: Chạy test để xác nhận test fail khi chưa thêm keys**

Run: `swift test --filter PersonalVaultLocalizationTests`
Expected: FAIL (Keys not found or equals key name)

- [ ] **Step 3: Thêm các localization keys vào `Localizable.xcstrings`**

Cập nhật `VocabCraftApp/Resources/Localizable.xcstrings` thêm các mục:
- `app.vault.title`: VI = "Kho Từ", EN = "Vocabulary Vault"
- `app.vault.search_placeholder`: VI = "Tìm kiếm từ vựng...", EN = "Search vocabulary..."
- `app.vault.filter.not_mastered`: VI = "Chưa thuộc (%lld)", EN = "Learning (%lld)"
- `app.vault.filter.mastered`: VI = "Đã thuộc (%lld)", EN = "Mastered (%lld)"
- `app.vault.filter.bookmarked`: VI = "Đã lưu (%lld)", EN = "Saved (%lld)"
- `app.vault.action.review_words`: VI = "⚡ Ôn luyện (%lld từ)", EN = "⚡ Review (%lld words)"
- `app.vault.empty.not_mastered`: VI = "Bạn không có từ nào chưa thuộc", EN = "No unmastered words"
- `app.vault.empty.mastered`: VI = "Chưa có từ nào đạt mức thành thạo", EN = "No mastered words yet"
- `app.vault.empty.bookmarked`: VI = "Chưa có từ nào được lưu", EN = "No saved words yet"
- `app.vault.empty.search_no_results`: VI = "Không tìm thấy từ nào phù hợp", EN = "No matching words found"
- `app.vault.detail.definitions_title`: VI = "Định nghĩa", EN = "Definitions"
- `app.vault.detail.examples_title`: VI = "Ví dụ thực tế", EN = "Examples"
- `app.vault.detail.progress_title`: VI = "Tiến độ phản xạ", EN = "Reflex Progress"
- `app.vault.detail.streak_count`: VI = "Chuỗi đúng %lld", EN = "%lld streak"
- `app.vault.detail.practiced_modes`: VI = "Chế độ đã luyện", EN = "Practiced modes"

- [ ] **Step 4: Chạy test để xác nhận test pass**

Run: `swift test --filter PersonalVaultLocalizationTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftAppTests/Features/PersonalVaultLocalizationTests.swift
git commit -m "feat(vault): add localization keys for Vocabulary Vault"
```

---

### Task 2: Cập nhật Domain UseCase & ViewModel Logic

**Files:**
- Modify: `VocabCraftApp/Domain/UseCases/FetchPersonalVaultUseCase.swift`
- Modify: `VocabCraftApp/Features/Vocabulary/PersonalVault/ViewModels/PersonalVaultViewModel.swift`
- Test: `VocabCraftAppTests/Features/PersonalVaultViewModelTests.swift`

**Interfaces:**
- Consumes: `VaultWordItem`, `VaultTabFilter`, `UserProgressRepositoryProtocol`, `VocabularyDataSourceProtocol`, `TextToSpeechProtocol`.
- Produces: `PersonalVaultViewModel` hoàn thiện với `selectedWordForDetail`, `prepareReviewWords()`, `playAudio(for:)`, `toggleBookmark(wordId:)`, cập nhật `metrics` và nạp từ ôn luyện theo tab.

- [ ] **Step 1: Viết Unit Tests cho các tính năng mới trong `PersonalVaultViewModelTests`**

Bổ sung các test case:
- `testPrepareReviewWordsMatchesActiveTab()`: Ở tab `.notMastered` nạp tối đa 15 từ chưa thuộc; ở tab `.bookmarked` nạp từ lưu.
- `testDetailSheetSelection()`: Chọn từ để mở sheet chi tiết và đóng sheet.
- `testPlayAudioTriggersTTS()`: Phát âm thanh từ vựng khi gọi `playAudio`.

- [ ] **Step 2: Chạy test để xác nhận các test mới fail**

Run: `swift test --filter PersonalVaultViewModelTests`
Expected: FAIL (Properties or methods not implemented yet)

- [ ] **Step 3: Cập nhật `FetchPersonalVaultUseCase.swift` và `PersonalVaultViewModel.swift`**

1. Trong `FetchPersonalVaultUseCase`: Đảm bảo `fetchVaultWords` tính toán chính xác `unmasteredCount`, `masteredCount`, `bookmarkedCount` trong `metrics`, và hỗ trợ tìm kiếm theo cả `lemma` và `definitionVi`.
2. Trong `PersonalVaultViewModel`:
   - Thêm `selectedWordForDetail: VaultWordItem?`
   - Thêm `reviewWords: [VaultWordItem]` và phương thức `prepareReviewWords() -> [VaultWordItem]`
   - Thêm `playAudio(for word: VaultWordItem)` thông qua `TextToSpeechProtocol`
   - Đảm bảo khi `toggleBookmark(wordId:)` hoàn tất sẽ tự động làm mới `vaultWords` và `metrics`.

- [ ] **Step 4: Chạy lại toàn bộ test suite của ViewModel**

Run: `swift test --filter PersonalVaultViewModelTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/UseCases/FetchPersonalVaultUseCase.swift VocabCraftApp/Features/Vocabulary/PersonalVault/ViewModels/PersonalVaultViewModel.swift VocabCraftAppTests/Features/PersonalVaultViewModelTests.swift
git commit -m "feat(vault): enhance FetchPersonalVaultUseCase and PersonalVaultViewModel for tab review and detail sheet"
```

---

### Task 3: Xây dựng UI Components Tinh gọn cho Kho Từ

**Files:**
- Create: `VocabCraftApp/Features/Vocabulary/Views/Components/VaultSegmentedControl.swift`
- Create: `VocabCraftApp/Features/Vocabulary/Views/Components/VaultReviewActionButton.swift`
- Create: `VocabCraftApp/Features/Vocabulary/Views/Components/VaultWordRowView.swift`
- Create: `VocabCraftApp/Features/Vocabulary/Views/Components/VaultWordDetailSheet.swift`
- Modify: `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift`
- Test: `VocabCraftAppTests/Features/Vocabulary/PersonalVaultViewsTests.swift`

**Interfaces:**
- Consumes: `VaultWordItem`, `VaultTabFilter`, `PersonalVaultViewModel`, `CraftCard`, `CraftBadge`, `CraftButton`, `CraftIconButton`, `CraftSearchBar`, `CraftColor`, `CraftFont`.
- Produces: Hệ thống component hoàn chỉnh của Kho Từ tuân thủ chuẩn CraftUIKit và Active Recall.

- [ ] **Step 1: Xây dựng `VaultSegmentedControl.swift`**

Tạo bộ chọn 3 tab: `Chưa thuộc (%lld)`, `Đã thuộc (%lld)`, `Đã lưu (%lld)`.
- Hiển thị pill background animated mượt mà.
- Sử dụng `CraftFont.labelMedium`, `CraftSpacingTokens`, và `CraftColor.surfaceSecondary`.

- [ ] **Step 2: Xây dựng `VaultReviewActionButton.swift`**

Nút bấm hành động đặt ngay dưới filter:
- Hiển thị: `⚡ Ôn luyện (%lld từ)`
- Sử dụng `CraftButton` dạng prominent với nền `CraftColor.accentPrimary`.
- Vô hiệu hóa hoặc ẩn khi số lượng từ = 0.

- [ ] **Step 3: Xây dựng `VaultWordRowView.swift` (Active Recall)**

Dòng thẻ từ tối giản:
- Từ/Cụm từ hiển thị rõ với `CraftFont.titleSmall`.
- Nhãn loại từ `CraftBadge` (ví dụ `[adj]`, `[noun]`, `[phrase]`).
- Phiên âm IPA tùy chọn (chỉ hiện khi `!word.phonetic.isEmpty`).
- Nút `CraftIconButton` bookmark góc phải với phản hồi Haptic khi chạm.
- Chạm vào thẻ gọi callback `onSelect(word)`.

- [ ] **Step 4: Xây dựng `VaultWordDetailSheet.swift`**

Bottom Sheet chi tiết:
- Header: Từ gốc to rõ, POS badge, CEFR level, IPA, nút Loa to phát âm, nút bookmark.
- Định nghĩa: Song ngữ Anh - Việt.
- Ví dụ: Câu tiếng Anh (tô đậm từ mục tiêu) + Bản dịch tiếng Việt.
- Tiến độ phản xạ: Streak count và các icon chế độ phản xạ đã từng luyện.

- [ ] **Step 5: Tái cấu trúc `VocabularyView.swift`**

Lắp ráp hoàn chỉnh `VocabularyView`:
- Navigation Title: "Kho Từ" (`app.vault.title`).
- Thanh tìm kiếm: `CraftSearchBar`.
- `VaultSegmentedControl` + `VaultReviewActionButton`.
- `ScrollView` với `LazyVStack` hiển thị danh sách `VaultWordRowView`.
- Contextual Empty State đơn giản cho từng tab.
- Sheet presentation cho `VaultWordDetailSheet`.
- Tích hợp điều hướng sang `MixedReflexDrillView` khi bấm nút Ôn luyện.

- [ ] **Step 6: Chạy View Tests và Xcode Build để xác minh giao diện và tương tác**

Run: `swift test --filter PersonalVaultViewsTests`
Expected: PASS with 0 warnings.

- [ ] **Step 7: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/Components/* VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift VocabCraftAppTests/Features/Vocabulary/PersonalVaultViewsTests.swift
git commit -m "feat(vault): implement minimal active-recall UI, segmented tabs, and detail sheet"
```

---

### Task 4: Kiểm Thử Tích Hợp Toàn Diện & Quality Gate Verification

**Files:**
- Test: Toàn bộ test suite của App và CraftUIKit

- [ ] **Step 1: Chạy kiểm tra Localization**

Run: `swift test --filter LocalizationTests`
Expected: PASS (100% song ngữ EN-VI hợp lệ).

- [ ] **Step 2: Chạy toàn bộ Unit & Integration Test Suite**

Run: `swift test`
Expected: 100% tests pass.

- [ ] **Step 3: Chạy SwiftLint và kiểm tra Zero Compiler Warnings**

Run: `swiftlint` và build app qua XcodeBuild MCP
Expected: 0 errors, 0 warnings.

- [ ] **Step 4: Commit và kết thúc implementation**

```bash
git commit --allow-empty -m "chore(vault): verify all tests pass with zero warnings"
```
