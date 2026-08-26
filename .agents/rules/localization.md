# Localization & Text Rendering Rules

## 1. Zero Hardcoded Strings Policy (Toàn dự án)

> [!IMPORTANT]
> **Tuyệt đối không hardcode text**: Không bao giờ viết chuỗi ký tự thô (raw literal English hoặc Vietnamese) trực tiếp trong SwiftUI view bodies, view models, controllers, component initializers, fallback logic, hay các Accessibility modifiers (`.accessibilityLabel`, `.accessibilityHint`, `.accessibilityValue`).
>
> Mọi chuỗi hiển thị đều phải được định nghĩa trong `Localizable.xcstrings` theo đúng tầng phụ trách và format chuẩn.

---

## 2. Phân định Kiến trúc Localization theo Tầng (2-Layer Architecture)

Dự án phân tách thành 2 tầng rõ ràng với tiền tố và phạm vi riêng biệt:

| Tiêu chí | Tầng 1: `CraftUIKit` (Design System Package) | Tầng 2: `VocabCraftApp` (Main Application) |
| :--- | :--- | :--- |
| **Tiền tố Root** | `craft.*` | `app.*` |
| **Tài nguyên Catalog** | `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings` | `VocabCraftApp/Resources/Localizable.xcstrings` |
| **Bundle & Truy xuất** | `Bundle.module` qua `CraftLocalized.string/format` | `Bundle.main` / `LocalizedStringKey` / `String(localized:)` |
| **Phạm vi chuỗi** | UI controls, widget states, token labels, VoiceOver mặc định của component | Tiêu đề màn hình, luồng nghiệp vụ, Deck từ vựng, SRS Reflex Drills, Onboarding, Profile, Settings, Notifications |

---

## 3. Quy chuẩn Đặt tên Key (Key Taxonomy Standard)

### 3.1 Tầng 1: `CraftUIKit` (`craft.*`)
Cấu trúc:
$$\text{craft} \ . \ \langle\text{scope}\rangle \ . \ \langle\text{element/context}\rangle \ . \ \langle\text{role/state/a11y}\rangle$$

- **`craft.common.action.*`**: Shared actions (`confirm`, `cancel`, `close`, `dismiss`, `continue`, `retry`, `action`).
- **`craft.common.state.*`**: Progression states (`loading`, `empty`, `on`, `off`, `completed`, `active`, `locked`, `upcoming`).
- **`craft.common.unit.*`**: Units & counts (`days_format`, `days_single`, `minutes_format`, `words_format`, `percent_format`, `percent_word_format`).
- **Component Scopes**:
  - `craft.button.*`, `craft.choice.*`, `craft.search.*`, `craft.stepper.*`, `craft.textfield.*`, `craft.toggle.*`
  - `craft.flipcard.*`, `craft.progress.*`, `craft.segmented_bar.*`, `craft.step_node.*`
  - `craft.streak.*`, `craft.learning_path.*`, `craft.tab_bar.*`, `craft.waveform.*`, `craft.countdown.*`, `craft.sparkle.*`

### 3.2 Tầng 2: `VocabCraftApp` (`app.*`)
Cấu trúc:
$$\text{app} \ . \ \langle\text{feature}\rangle \ . \ \langle\text{screen/flow}\rangle \ . \ \langle\text{element}\rangle \ . \ \langle\text{role/state/a11y}\rangle$$

- **`app.common.*`**:
  - `app.common.nav.*`: Tab bar items (`tab_home`, `tab_study`, `tab_practice`, `tab_profile`).
  - `app.common.error.*`: Lỗi mạng/hệ thống (`network_unavailable`, `speech_recognition_failed`, `save_failed`).
- **`app.onboarding.*`**: Welcome screens, level assessment, daily study goal selection (`app.onboarding.welcome.title`, `app.onboarding.level_picker.header`, `app.onboarding.daily_goal.cta`).
- **`app.study.*`**: Luồng học bài, flashcards, session complete summary (`app.study.session.flip_hint`, `app.study.session.complete_title`, `app.study.summary.xp_earned_format`).
- **`app.reflex.*`**: SRS Engine, Speed drills, pronunciation checks (`app.reflex.drill.speed_round_title`, `app.reflex.card.listen_and_choose`, `app.reflex.result.accuracy_format`).
- **`app.deck.*` / `app.topic.*`**: Quản lý Deck từ vựng, SubTopics, danh sách từ (`app.deck.detail.total_words_format`, `app.deck.list.search_placeholder`, `app.deck.empty.title`).
- **`app.streak.*`**: Thông tin chuỗi streak trên app, freeze token store (`app.streak.freeze_used_alert_title`, `app.streak.banner_subtitle`).
- **`app.profile.*` & `app.settings.*`**: Thông tin cá nhân, thống kê XP, tùy chỉnh giọng đọc, dark mode (`app.settings.voice_accent.title`, `app.profile.stats.words_learned_format`).
- **`app.notification.*`**: Nội dung push notifications và local reminders (`app.notification.daily_reminder.title`, `app.notification.streak_freeze.body`).

---

## 4. Nguyên tắc Bắt buộc về Dữ liệu Song ngữ (100% Bilingual Parity)

Bất kỳ khi nào tạo hoặc cập nhật key trong bất kỳ file `Localizable.xcstrings` nào (`CraftUIKit` hoặc `VocabCraftApp`):
1. **Đầy đủ cả 2 ngôn ngữ**: Cả `en` và `vi` đều phải có bản dịch chuẩn xác, không được để trống bất kỳ ngôn ngữ nào.
2. **Không lẫn lộn ngôn ngữ**: Tuyệt đối không để text tiếng Việt sang nhánh `en` hoặc để tiếng Anh giữ chỗ ở nhánh `vi`.
3. **Đồng nhất Format Specifiers**: Thứ tự và kiểu định dạng format token (`%lld`, `%@`, `%%`) phải khớp chính xác 100% giữa tiếng Anh và tiếng Việt.
4. **Extraction State**: Luôn thiết lập `extractionState: "manual"` và `state: "translated"` cho các key được thêm bằng tay để tránh Xcode tự sinh ra các key rác trùng lặp không có namespace.

---

## 5. Cách thức Render Text trong Code

- **Trong `CraftUIKit`**: Sử dụng `CraftLocalized`:
  ```swift
  let buttonLabel = CraftLocalized.string("craft.common.action.confirm")
  let formattedTime = CraftLocalized.format("craft.common.unit.minutes_format", 15)
  ```
- **Trong `VocabCraftApp`**: Sử dụng `LocalizedStringKey` hoặc `String(localized:)`:
  ```swift
  Text("app.study.session.complete_title")
  let progressText = String(localized: "app.study.summary.xp_earned_format", defaultValue: "Earned %lld XP")
  ```
- **Tương tác giữa App và CraftUIKit**:
  - Khi App sử dụng các components từ `CraftUIKit`, truyền dữ liệu domain (như title, subtitle, custom objectives) thông qua parameters dạng `LocalizedStringKey` hoặc `String`.
  - Component trong `CraftUIKit` sẽ ưu tiên hiển thị text được truyền từ App, và chỉ fallback về key mặc định của `CraftUIKit` khi tham số truyền vào là `nil`.

---

## 6. Yêu cầu Kiểm tra (Verification Gate)
Trước khi kết thúc bất kỳ task nào có liên quan đến UI text hoặc localization:
- Chạy `swift test --filter LocalizationTests` (đối với `CraftUIKit`).
- Chạy toàn bộ test suites liên quan để đảm bảo không có lỗi biên dịch hay sai lệch format token.
