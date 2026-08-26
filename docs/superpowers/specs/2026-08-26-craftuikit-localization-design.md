# CraftUIKit Localization Standardization & Component Text Audit Design Spec

## 1. Executive Summary

This design specification establishes a standardized, scalable localization architecture for `CraftUIKit`, eliminating all hardcoded English/Vietnamese text across all 34 UI components, fixing string catalog defects in `Localizable.xcstrings`, and providing full bilingual (`en` and `vi`) support with consistent key taxonomy.

---

## 2. Goals & Success Criteria

### Goals
1. **Zero Hardcoded Strings**: Eliminate every hardcoded user-facing string, accessibility label, hint, and fallback across all Atoms, Containers, Controls, Feedback, Navigation, Overlays, and Models in `CraftUIKit`.
2. **Standardized Key Taxonomy**: Establish a hierarchical dot-separated snake_case naming scheme (`craft.<scope>.<element>.<role>`).
3. **Clean & Complete String Catalog**: Clean up `CraftUIKit/.../Localizable.xcstrings`, removing auto-extracted junk strings, correcting English entries that were mistakenly written in Vietnamese, and providing 100% translated pairs for English (`en`) and Vietnamese (`vi`).
4. **Dynamic Custom Objectives**: Enable `CraftLessonDetailSheet` to accept custom `objectives: [String]?` from host applications while retaining standard bilingual default objectives as fallback.
5. **Comprehensive Verification**: 100% unit test coverage for all localization keys in both languages with 0 test failures.

---

## 3. Key Naming Taxonomy Standard

Every localization key in `CraftUIKit` follows this hierarchical structure:

$$\text{craft} \ . \ \langle\text{scope}\rangle \ . \ \langle\text{element}\rangle \ . \ \langle\text{role/state/a11y}\rangle$$

### Formatting Rules
- All lowercase snake_case for individual segments.
- `_a11y`: Accessibility label or accessibility value.
- `_hint`: Accessibility hint (VoiceOver interaction instructions).
- `_format`: Format string requiring `String(format:)` / `CraftLocalized.format(_:_:)` with specifiers like `%lld` or `%@`.

---

## 4. Complete Localization Catalog (`Localizable.xcstrings`)

### 4.1 Common Scope (`craft.common.*`)

| Key | English (`en`) | Vietnamese (`vi`) | Description |
| :--- | :--- | :--- | :--- |
| `craft.common.action.confirm` | Confirm | Xác nhận | Standard confirmation action |
| `craft.common.action.cancel` | Cancel | Hủy | Standard cancel action |
| `craft.common.action.close` | Close | Đóng | Standard close action |
| `craft.common.action.dismiss` | Dismiss | Đóng | Standard dismiss action |
| `craft.common.action.continue` | Continue | Tiếp tục | Standard continue action |
| `craft.common.action.retry` | Retry | Thử lại | Standard retry action |
| `craft.common.action.action` | Action | Tác vụ | Fallback generic button label |
| `craft.common.state.loading` | Loading | Đang tải | General loading state |
| `craft.common.state.empty` | Empty | Trống | General empty state |
| `craft.common.state.on` | On | Bật | Toggle/switch state ON |
| `craft.common.state.off` | Off | Tắt | Toggle/switch state OFF |
| `craft.common.unit.days_format` | %lld days | %lld ngày | Pluralized/quantified days |
| `craft.common.unit.days_single` | days | ngày | Unit word for days |
| `craft.common.unit.minutes_format` | %lld min | %lld phút | Quantified minutes |
| `craft.common.unit.words_format` | %lld new words | %lld từ vựng mới | Quantified vocabulary count |
| `craft.common.unit.percent_format` | %lld%% | %lld%% | Visual percentage |
| `craft.common.unit.percent_word_format` | %lld percent | %lld phần trăm | VoiceOver percentage |

### 4.2 Controls Scope (`craft.button.*`, `craft.choice.*`, `craft.search.*`, `craft.stepper.*`, `craft.textfield.*`)

| Key | English (`en`) | Vietnamese (`vi`) | Description |
| :--- | :--- | :--- | :--- |
| `craft.button.loading_a11y` | Loading | Đang tải | Button loading accessibility |
| `craft.choice.selected_a11y` | Selected | Đã chọn | Choice card selected state |
| `craft.choice.correct_a11y` | Correct Answer | Đáp án đúng | Choice card correct state |
| `craft.choice.wrong_a11y` | Incorrect Answer | Đáp án chưa đúng | Choice card wrong state |
| `craft.choice.disabled_a11y` | Disabled | Vô hiệu hóa | Choice card disabled state |
| `craft.search.placeholder` | Search... | Tìm kiếm... | Search bar placeholder |
| `craft.search.clear_a11y` | Clear search | Xóa tìm kiếm | Search bar clear button |
| `craft.search.trailing_action_a11y` | Trailing action | Tác vụ mở rộng | Search bar trailing icon |
| `craft.stepper.default_label` | Stepper | Bộ đếm | Stepper fallback label |
| `craft.stepper.decrease_a11y` | Decrease | Giảm | Stepper minus button |
| `craft.stepper.increase_a11y` | Increase | Tăng | Stepper plus button |
| `craft.textfield.show_password_a11y` | Show password | Hiện mật khẩu | Secure field show button |
| `craft.textfield.hide_password_a11y` | Hide password | Ẩn mật khẩu | Secure field hide button |

### 4.3 Containers & Roadmap Scope (`craft.flipcard.*`, `craft.progress.*`, `craft.segmented_bar.*`, `craft.step_node.*`)

| Key | English (`en`) | Vietnamese (`vi`) | Description |
| :--- | :--- | :--- | :--- |
| `craft.flipcard.flip_to_back_action` | Flip to back | Lật ra mặt sau | Flip card flip action |
| `craft.flipcard.flip_to_front_action` | Flip to front | Lật ra mặt trước | Flip card flip action |
| `craft.flipcard.front_side_hint` | Front of card | Mặt trước của thẻ | Flip card front hint |
| `craft.flipcard.back_side_hint` | Back of card | Mặt sau của thẻ | Flip card back hint |
| `craft.progress.label` | Progress | Tiến độ | Progress bar/ring label |
| `craft.segmented_bar.label_a11y` | Segmented metric bar | Thanh tỉ lệ phân đoạn | Segmented bar label |
| `craft.segmented_bar.segment_fallback` | Segment | Phân đoạn | Segment item fallback |
| `craft.step_node.step_format` | Step %lld: %@ | Bước %lld: %@ | Step node label format |
| `craft.step_node.tap_hint` | Double tap to select this step | Chạm hai lần để chọn bước này | Step node selection hint |

### 4.4 Streak & Activity Scope (`craft.streak.*`)

| Key | English (`en`) | Vietnamese (`vi`) | Description |
| :--- | :--- | :--- | :--- |
| `craft.streak.tier_starter` | Starter Streak | Chuỗi khởi đầu | Starter tier name |
| `craft.streak.tier_blaze` | Blaze Streak | Chuỗi rực lửa | Blaze tier name |
| `craft.streak.tier_legendary` | Legendary Streak | Chuỗi huyền thoại | Legendary tier name |
| `craft.streak.today_completed` | Completed for today | Hôm nay đã hoàn thành | Daily completion status |
| `craft.streak.today_pending` | Pending completion for today | Hôm nay chưa hoàn thành | Daily pending status |
| `craft.streak.badge_a11y_format` | %lld-day study streak, %@ tier. %@ | Chuỗi %lld ngày học liên tiếp, Cấp độ %@. %@ | Streak badge accessibility |
| `craft.streak.badge_a11y_hint` | Double tap to view streak details. | Chạm hai lần để xem chi tiết chuỗi ngày. | Streak badge hint |
| `craft.streak.best_record_format` | Best: %lld days | Kỷ lục: %lld ngày | Best streak record |
| `craft.streak.freeze_shield_format` | %lld/%lld Shields | %lld/%lld Khiên | Freeze shields counter |
| `craft.streak.milestone_title_format` | %lld-Day Milestone! | Cột mốc %lld ngày! | Milestone celebration title |
| `craft.streak.celebration_title` | Streak Extended! | Chuỗi ngày rực lửa! | Regular celebration title |
| `craft.streak.continue_action` | Continue Learning | Tiếp tục học | Celebration sheet CTA |
| `craft.streak.celebration_hint` | Double tap to dismiss and continue learning. | Chạm hai lần để đóng màn hình và tiếp tục học. | Celebration sheet hint |
| `craft.streak.day_status_completed` | Completed | Đã hoàn thành | Day node completed status |
| `craft.streak.day_status_pending` | Pending | Đang chờ hoàn thành | Day node pending status |
| `craft.streak.day_status_saved` | Freeze shield used | Đã dùng khiên bảo vệ | Day node shielded status |
| `craft.streak.day_status_missed` | Missed | Bỏ lỡ | Day node missed status |
| `craft.streak.day_status_upcoming` | Upcoming | Chưa đến | Day node upcoming status |
| `craft.streak.day_inspect_hint` | Double tap to inspect day details. | Chạm hai lần để kiểm tra chi tiết ngày. | Day node inspection hint |
| `craft.streak.view_shield_action` | View freeze shields | Xem khiên bảo vệ | Custom accessibility action |
| `craft.streak.view_milestone_action` | View milestone rewards | Xem mốc thưởng | Custom accessibility action |
| `craft.streak.card_a11y_overview` | Displays weekly streak overview and activity status. | Hiển thị tổng quan chuỗi ngày học trong tuần. | Streak card overview hint |
| `craft.streak.msg_starter_1` | Great start! Keep up the daily habit of learning. | Khởi đầu tuyệt vời! Hãy duy trì thói quen học mỗi ngày nhé. | Motivational message |
| `craft.streak.msg_starter` | Great progress! You are building a solid learning habit. | Tuyệt vời! Bạn đang xây dựng một thói quen học tập vững chắc. | Motivational message |
| `craft.streak.msg_blaze` | Great streak! Your learning flame is burning bright. | Phong độ tuyệt vời! Ngọn lửa học tập của bạn đang rực sáng. | Motivational message |
| `craft.streak.msg_blaze_milestone` | Awesome! You've achieved a blaze streak, keep up the momentum! | Đẳng cấp! Bạn đã đạt chuỗi rực lửa, tiếp tục duy trì đà tiến bộ này! | Motivational message |
| `craft.streak.msg_legendary` | Unstoppable! You are an inspiring example of consistency. | Không thể ngăn cản! Bạn là tấm gương học tập đầy cảm hứng. | Motivational message |
| `craft.streak.msg_legendary_milestone` | Legendary! You've reached a pinnacle milestone with extraordinary dedication! | Huyền thoại! Bạn đã chinh phục cột mốc đỉnh cao với sự kiên trì phi thường! | Motivational message |

### 4.5 Learning Path & Journey Scope (`craft.learning_path.*`)

| Key | English (`en`) | Vietnamese (`vi`) | Description |
| :--- | :--- | :--- | :--- |
| `craft.learning_path.empty_title` | No Lessons Available | Chưa có bài học nào | Empty learning path title |
| `craft.learning_path.empty_desc` | There are no lesson sections available in this learning path. | Hiện chưa có bài học nào trong lộ trình này. | Empty learning path description |
| `craft.learning_path.default_unit_label` | UNIT | BÀI HỌC | Section gateway fallback label |
| `craft.learning_path.continue_callout` | CONTINUE | TIẾP TỤC | Active node speech bubble callout |
| `craft.learning_path.start_lesson` | START LESSON | BẮT ĐẦU HỌC | Modal sheet CTA to start |
| `craft.learning_path.continue_lesson_format` | CONTINUE (%lld%%) | TIẾP TỤC HỌC (%lld%%) | Modal sheet CTA to resume |
| `craft.learning_path.review_lesson_format` | REVIEW (+%lld XP) | ÔN TẬP LẠI (+%lld XP) | Modal sheet CTA to review |
| `craft.learning_path.challenge_lesson` | CONQUER CHALLENGE | CHINH PHỤC THỬ THÁCH | Modal sheet CTA checkpoint |
| `craft.learning_path.locked_lesson` | LESSON LOCKED | BÀI HỌC ĐANG KHÓA | Modal sheet CTA locked |
| `craft.learning_path.objectives_header` | Lesson Objectives | Mục tiêu bài học | Sheet objectives section header |
| `craft.learning_path.default_objective_1` | Master standard pronunciation and core vocabulary meanings | Nắm vững phát âm chuẩn và ý nghĩa từ vựng trọng tâm | Fallback objective 1 |
| `craft.learning_path.default_objective_2` | Practice sentence reflex via interactive Spaced Repetition drills | Thực hành phản xạ câu qua bài tập tương tác Spaced Repetition | Fallback objective 2 |
| `craft.learning_path.default_objective_3_format` | Earn %@ and maintain daily study streak | Tích lũy %@ và duy trì chuỗi Streak học tập | Fallback objective 3 format |
| `craft.learning_path.node_completed_a11y` | Lesson: %@, Completed | Bài học: %@, Đã hoàn thành | Node completed accessibility label |
| `craft.learning_path.node_current_format_a11y` | Lesson: %@, Current lesson. %lld%% complete | Bài học: %@, Bài học hiện tại. Đã hoàn thành %lld%% | Node active accessibility with % |
| `craft.learning_path.node_current_a11y` | Lesson: %@, Current lesson | Bài học: %@, Bài học hiện tại | Node active accessibility without % |
| `craft.learning_path.node_in_progress_format_a11y` | Lesson: %@, In progress. %lld%% complete | Bài học: %@, Đang học dở. Đã hoàn thành %lld%% | Node in-progress accessibility with % |
| `craft.learning_path.node_in_progress_a11y` | Lesson: %@, In progress | Bài học: %@, Đang học dở | Node in-progress accessibility without % |
| `craft.learning_path.node_upcoming_a11y` | Lesson: %@, Upcoming lesson | Bài học: %@, Bài học sắp tới | Node upcoming accessibility |
| `craft.learning_path.node_locked_a11y` | Lesson: %@, Locked | Bài học: %@, Đang khóa | Node locked accessibility |
| `craft.learning_path.node_bonus_a11y` | Bonus Lesson: %@ | Bài học thử thách: %@ | Bonus node accessibility |
| `craft.learning_path.reward_format_a11y` | Reward: %lld XP | Phần thưởng: %lld XP | Node XP reward accessibility |
| `craft.learning_path.tap_to_review_hint` | Double tap to review | Nhấn đúp để ôn tập | Node review hint |
| `craft.learning_path.tap_to_continue_hint` | Double tap to continue | Nhấn đúp để tiếp tục học | Node resume hint |
| `craft.learning_path.tap_to_start_hint` | Double tap to start | Nhấn đúp để bắt đầu học | Node start hint |
| `craft.learning_path.unlock_requirement_hint` | Complete previous lessons to unlock | Hoàn thành bài học trước để mở khóa | Locked node hint |
| `craft.learning_path.close_sheet_hint` | Double tap to close lesson details | Nhấn đúp để đóng thông tin bài học | Detail sheet close button hint |

### 4.6 Navigation, Feedback & Audio Scope (`craft.tab_bar.*`, `craft.waveform.*`, `craft.countdown.*`, `craft.sparkle.*`)

| Key | English (`en`) | Vietnamese (`vi`) | Description |
| :--- | :--- | :--- | :--- |
| `craft.tab_bar.badge_count_format` | %lld new items | %lld mục mới | Tab bar badge item accessibility |
| `craft.tab_bar.center_action_fallback` | Action | Tác vụ | Tab bar center FAB fallback |
| `craft.waveform.recording_active_a11y` | Audio waveform recording active | Đang thu âm sóng âm thanh | Waveform active recording a11y |
| `craft.waveform.visualizer_a11y` | Audio waveform visualizer | Trình hiển thị sóng âm | Waveform idle visualizer a11y |
| `craft.waveform.audio_level_format` | %lld percent average audio level | Mức âm thanh trung bình %lld phần trăm | Waveform audio level value |
| `craft.countdown.label_format` | Countdown %lld | Đếm ngược %lld | Countdown voiceover label |
| `craft.countdown.go_text` | GO! | BẮT ĐẦU! | Countdown finish banner |
| `craft.sparkle.sparkle_label` | Sparkle! | Lấp lánh! | Sparkle reduce motion fallback text |
| `craft.sparkle.celebration_label` | Celebration! | Chúc mừng! | Confetti reduce motion fallback text |

---

## 5. Architectural & Implementation Details

### 5.1 Component & Model Updates

1. **`CraftStreakModels.swift` & `CraftActivityModels.swift`**:
   - Refactor `asActivityTrackerData` to use `unitKey: "craft.common.unit.days_single"`, removing `"ngày"` hardcoding.
2. **`CraftLearningPathModels.swift` & `CraftLessonDetailSheet.swift`**:
   - `LessonNodeModel`: Add optional `objectives: [String]? = nil` and `objectiveKeys: [String]? = nil`.
   - `CraftLessonDetailSheet`: Render `objectives` if provided; otherwise, render the 3 standardized fallback objectives.
   - Refactor `formattedDuration`, `formattedVocabularyCount`, `ctaTitle`, and all accessibility hints to use `CraftLocalized`.
3. **`CraftLessonNode.swift` & `CraftPathNode.swift`**:
   - `ActiveCalloutBubble`: Default `text` fetched from `CraftLocalized.string("craft.learning_path.continue_callout")`.
   - `accessibilityLabelText` and `accessibilityHintText`: Generated via `CraftLocalized.format` / `CraftLocalized.string`.
4. **`CraftLearningPath.swift`**:
   - Replace literal strings in `ContentUnavailableView` with `craft.learning_path.empty_title` and `craft.learning_path.empty_desc`.
5. **`CraftStepNode.swift`**:
   - Map `CraftStepState.accessibilityDescription` to `craft.common.state.*`.
   - Format accessibility labels with `craft.step_node.step_format` and `craft.step_node.tap_hint`.
6. **`CraftProgressBar.swift` & `CraftProgressRing.swift`**:
   - Default accessibility label uses `craft.progress.label`.
   - Accessibility value uses `craft.common.unit.percent_word_format`.
7. **`CraftSearchBar.swift` & `CraftTextField.swift`**:
   - Replace default placeholders and accessibility labels with `craft.search.*` and `craft.textfield.*`.
8. **`CraftToggle.swift`**:
   - Accessibility values use `craft.common.state.on` and `craft.common.state.off`.
9. **`CraftSegmentedBar.swift`**:
   - Accessibility label and empty status use `craft.segmented_bar.label_a11y` and `craft.common.state.empty`.
10. **`CraftWaveformView.swift`, `CraftSparkleView.swift`, `CraftCountdownOverlay.swift`, `CraftFloatingTabBar.swift`**:
    - Update all accessibility strings to their corresponding `craft.*` keys.

---

## 6. Verification Plan

1. **Automated Unit Tests**:
   - Update `LocalizationTests.swift` to test all keys in both `en` and `vi` languages, formatted string arguments, and fallback logic.
   - Run `swift test` across all suites in `CraftUIKit` to verify 0 regressions.
2. **Interactive Gallery Verification**:
   - Verify `CraftCatalogView.swift` language switcher toggles between English and Vietnamese seamlessly across all 34 components.
