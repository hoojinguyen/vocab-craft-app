import Foundation
#if canImport(XCTest)
import XCTest
#endif
@testable import CraftUIKit

final class LocalizationTests: XCTestCase {
    
    // MARK: - Common Actions & States
    
    func testCommonStrings() {
        // Confirm
        XCTAssertEqual(CraftLocalized.string("craft.common.action.confirm"), "Confirm")
        XCTAssertEqual(CraftLocalized.string("craft.common.action.confirm", language: "vi"), "Xác nhận")
        
        // Cancel
        XCTAssertEqual(CraftLocalized.string("craft.common.action.cancel"), "Cancel")
        XCTAssertEqual(CraftLocalized.string("craft.common.action.cancel", language: "vi"), "Hủy")
        
        // Close
        XCTAssertEqual(CraftLocalized.string("craft.common.action.close"), "Close")
        XCTAssertEqual(CraftLocalized.string("craft.common.action.close", language: "vi"), "Đóng")
        
        // Dismiss
        XCTAssertEqual(CraftLocalized.string("craft.common.action.dismiss"), "Dismiss")
        XCTAssertEqual(CraftLocalized.string("craft.common.action.dismiss", language: "vi"), "Đóng")
        
        // Continue
        XCTAssertEqual(CraftLocalized.string("craft.common.action.continue"), "Continue")
        XCTAssertEqual(CraftLocalized.string("craft.common.action.continue", language: "vi"), "Tiếp tục")
        
        // Retry
        XCTAssertEqual(CraftLocalized.string("craft.common.action.retry"), "Retry")
        XCTAssertEqual(CraftLocalized.string("craft.common.action.retry", language: "vi"), "Thử lại")
        
        // Generic Action
        XCTAssertEqual(CraftLocalized.string("craft.common.action.action"), "Action")
        XCTAssertEqual(CraftLocalized.string("craft.common.action.action", language: "vi"), "Tác vụ")
        
        // Loading
        XCTAssertEqual(CraftLocalized.string("craft.common.state.loading"), "Loading")
        XCTAssertEqual(CraftLocalized.string("craft.common.state.loading", language: "vi"), "Đang tải")
        
        // Empty
        XCTAssertEqual(CraftLocalized.string("craft.common.state.empty"), "Empty")
        XCTAssertEqual(CraftLocalized.string("craft.common.state.empty", language: "vi"), "Trống")
        
        // Active / Completed / Locked / Upcoming States
        XCTAssertEqual(CraftLocalized.string("craft.common.state.active"), "Active")
        XCTAssertEqual(CraftLocalized.string("craft.common.state.active", language: "vi"), "Đang hoạt động")
        XCTAssertEqual(CraftLocalized.string("craft.common.state.completed"), "Completed")
        XCTAssertEqual(CraftLocalized.string("craft.common.state.completed", language: "vi"), "Đã hoàn thành")
        XCTAssertEqual(CraftLocalized.string("craft.common.state.locked"), "Locked")
        XCTAssertEqual(CraftLocalized.string("craft.common.state.locked", language: "vi"), "Đang khóa")
        XCTAssertEqual(CraftLocalized.string("craft.common.state.upcoming"), "Upcoming")
        XCTAssertEqual(CraftLocalized.string("craft.common.state.upcoming", language: "vi"), "Chưa đến")
        
        // On / Off
        XCTAssertEqual(CraftLocalized.string("craft.common.state.on"), "On")
        XCTAssertEqual(CraftLocalized.string("craft.common.state.on", language: "vi"), "Bật")
        XCTAssertEqual(CraftLocalized.string("craft.common.state.off"), "Off")
        XCTAssertEqual(CraftLocalized.string("craft.common.state.off", language: "vi"), "Tắt")
    }

    // MARK: - Formatted Units
    
    func testCommonUnits() {
        XCTAssertEqual(CraftLocalized.format("craft.common.unit.days_format", 5), "5 days")
        XCTAssertEqual(CraftLocalized.format("craft.common.unit.days_format", language: "vi", 5), "5 ngày")
        
        XCTAssertEqual(CraftLocalized.string("craft.common.unit.days_single"), "days")
        XCTAssertEqual(CraftLocalized.string("craft.common.unit.days_single", language: "vi"), "ngày")
        
        XCTAssertEqual(CraftLocalized.format("craft.common.unit.minutes_format", 10), "10 min")
        XCTAssertEqual(CraftLocalized.format("craft.common.unit.minutes_format", language: "vi", 10), "10 phút")
        
        XCTAssertEqual(CraftLocalized.format("craft.common.unit.words_format", 15), "15 new words")
        XCTAssertEqual(CraftLocalized.format("craft.common.unit.words_format", language: "vi", 15), "15 từ vựng mới")
        
        XCTAssertEqual(CraftLocalized.format("craft.common.unit.percent_format", 80), "80%")
        XCTAssertEqual(CraftLocalized.format("craft.common.unit.percent_format", language: "vi", 80), "80%")
        
        XCTAssertEqual(CraftLocalized.format("craft.common.unit.percent_word_format", 75), "75 percent")
        XCTAssertEqual(CraftLocalized.format("craft.common.unit.percent_word_format", language: "vi", 75), "75 phần trăm")
    }

    // MARK: - Controls Scope
    
    func testControlStrings() {
        // Button
        XCTAssertEqual(CraftLocalized.string("craft.button.loading_a11y"), "Loading")
        XCTAssertEqual(CraftLocalized.string("craft.button.loading_a11y", language: "vi"), "Đang tải")
        
        // Choice Card
        XCTAssertEqual(CraftLocalized.string("craft.choice.selected_a11y"), "Selected")
        XCTAssertEqual(CraftLocalized.string("craft.choice.selected_a11y", language: "vi"), "Đã chọn")
        XCTAssertEqual(CraftLocalized.string("craft.choice.correct_a11y"), "Correct Answer")
        XCTAssertEqual(CraftLocalized.string("craft.choice.correct_a11y", language: "vi"), "Đáp án đúng")
        XCTAssertEqual(CraftLocalized.string("craft.choice.wrong_a11y"), "Incorrect Answer")
        XCTAssertEqual(CraftLocalized.string("craft.choice.wrong_a11y", language: "vi"), "Đáp án chưa đúng")
        XCTAssertEqual(CraftLocalized.string("craft.choice.disabled_a11y"), "Disabled")
        XCTAssertEqual(CraftLocalized.string("craft.choice.disabled_a11y", language: "vi"), "Vô hiệu hóa")
        
        // Search Bar
        XCTAssertEqual(CraftLocalized.string("craft.search.placeholder"), "Search...")
        XCTAssertEqual(CraftLocalized.string("craft.search.placeholder", language: "vi"), "Tìm kiếm...")
        XCTAssertEqual(CraftLocalized.string("craft.search.clear_a11y"), "Clear search")
        XCTAssertEqual(CraftLocalized.string("craft.search.clear_a11y", language: "vi"), "Xóa tìm kiếm")
        XCTAssertEqual(CraftLocalized.string("craft.search.trailing_action_a11y"), "Trailing action")
        XCTAssertEqual(CraftLocalized.string("craft.search.trailing_action_a11y", language: "vi"), "Tác vụ mở rộng")
        
        // Stepper
        XCTAssertEqual(CraftLocalized.string("craft.stepper.default_label"), "Stepper")
        XCTAssertEqual(CraftLocalized.string("craft.stepper.default_label", language: "vi"), "Bộ đếm")
        XCTAssertEqual(CraftLocalized.string("craft.stepper.decrease_a11y"), "Decrease")
        XCTAssertEqual(CraftLocalized.string("craft.stepper.decrease_a11y", language: "vi"), "Giảm")
        XCTAssertEqual(CraftLocalized.string("craft.stepper.increase_a11y"), "Increase")
        XCTAssertEqual(CraftLocalized.string("craft.stepper.increase_a11y", language: "vi"), "Tăng")
        
        // TextField
        XCTAssertEqual(CraftLocalized.string("craft.textfield.show_password_a11y"), "Show password")
        XCTAssertEqual(CraftLocalized.string("craft.textfield.show_password_a11y", language: "vi"), "Hiện mật khẩu")
        XCTAssertEqual(CraftLocalized.string("craft.textfield.hide_password_a11y"), "Hide password")
        XCTAssertEqual(CraftLocalized.string("craft.textfield.hide_password_a11y", language: "vi"), "Ẩn mật khẩu")
    }

    // MARK: - Containers & Roadmap Scope
    
    func testContainerStrings() {
        // FlipCard
        XCTAssertEqual(CraftLocalized.string("craft.flipcard.flip_to_back_action"), "Flip to back")
        XCTAssertEqual(CraftLocalized.string("craft.flipcard.flip_to_back_action", language: "vi"), "Lật ra mặt sau")
        XCTAssertEqual(CraftLocalized.string("craft.flipcard.flip_to_front_action"), "Flip to front")
        XCTAssertEqual(CraftLocalized.string("craft.flipcard.flip_to_front_action", language: "vi"), "Lật ra mặt trước")
        XCTAssertEqual(CraftLocalized.string("craft.flipcard.front_side_hint"), "Front of card")
        XCTAssertEqual(CraftLocalized.string("craft.flipcard.front_side_hint", language: "vi"), "Mặt trước của thẻ")
        XCTAssertEqual(CraftLocalized.string("craft.flipcard.back_side_hint"), "Back of card")
        XCTAssertEqual(CraftLocalized.string("craft.flipcard.back_side_hint", language: "vi"), "Mặt sau của thẻ")
        
        // Progress
        XCTAssertEqual(CraftLocalized.string("craft.progress.label"), "Progress")
        XCTAssertEqual(CraftLocalized.string("craft.progress.label", language: "vi"), "Tiến độ")
        
        // Segmented Bar
        XCTAssertEqual(CraftLocalized.string("craft.segmented_bar.label_a11y"), "Segmented metric bar")
        XCTAssertEqual(CraftLocalized.string("craft.segmented_bar.label_a11y", language: "vi"), "Thanh tỉ lệ phân đoạn")
        XCTAssertEqual(CraftLocalized.string("craft.segmented_bar.segment_fallback"), "Segment")
        XCTAssertEqual(CraftLocalized.string("craft.segmented_bar.segment_fallback", language: "vi"), "Phân đoạn")
        
        // Step Progress
        XCTAssertEqual(CraftLocalized.format("craft.step_progress.a11y_value_format", 2, 5), "Step 2 of 5")
        XCTAssertEqual(CraftLocalized.format("craft.step_progress.a11y_value_format", language: "vi", 2, 5), "Bước 2 trên 5")
        
        // Step Node
        XCTAssertEqual(CraftLocalized.format("craft.step_node.step_format", 2, "Review"), "Step 2: Review")
        XCTAssertEqual(CraftLocalized.format("craft.step_node.step_format", language: "vi", 2, "Ôn tập"), "Bước 2: Ôn tập")
        XCTAssertEqual(CraftLocalized.string("craft.step_node.tap_hint"), "Double tap to select this step")
        XCTAssertEqual(CraftLocalized.string("craft.step_node.tap_hint", language: "vi"), "Chạm hai lần để chọn bước này")

        // Page Header
        XCTAssertEqual(CraftLocalized.string("craft.header.a11y.title"), "Page Header")
        XCTAssertEqual(CraftLocalized.string("craft.header.a11y.title", language: "vi"), "Tiêu đề trang")
        XCTAssertEqual(CraftLocalized.string("craft.header.a11y.search_toggle"), "Toggle Search")
        XCTAssertEqual(CraftLocalized.string("craft.header.a11y.search_toggle", language: "vi"), "Bật tắt tìm kiếm")
    }

    // MARK: - Streak & Activity Scope
    
    func testStreakStrings() {
        // Tiers
        XCTAssertEqual(CraftLocalized.string("craft.streak.tier_starter"), "Starter Streak")
        XCTAssertEqual(CraftLocalized.string("craft.streak.tier_starter", language: "vi"), "Chuỗi khởi đầu")
        XCTAssertEqual(CraftLocalized.string("craft.streak.tier_blaze"), "Blaze Streak")
        XCTAssertEqual(CraftLocalized.string("craft.streak.tier_blaze", language: "vi"), "Chuỗi rực lửa")
        XCTAssertEqual(CraftLocalized.string("craft.streak.tier_legendary"), "Legendary Streak")
        XCTAssertEqual(CraftLocalized.string("craft.streak.tier_legendary", language: "vi"), "Chuỗi huyền thoại")
        
        // Today Status
        XCTAssertEqual(CraftLocalized.string("craft.streak.today_completed"), "Completed for today")
        XCTAssertEqual(CraftLocalized.string("craft.streak.today_completed", language: "vi"), "Hôm nay đã hoàn thành")
        XCTAssertEqual(CraftLocalized.string("craft.streak.today_pending"), "Pending completion for today")
        XCTAssertEqual(CraftLocalized.string("craft.streak.today_pending", language: "vi"), "Hôm nay chưa hoàn thành")
        
        // Formatted Badge & Records
        let badgeEN = CraftLocalized.format("craft.streak.badge_a11y_format", 7, "Blaze", "Completed for today")
        XCTAssertEqual(badgeEN, "7-day study streak, Blaze tier. Completed for today")
        let badgeVI = CraftLocalized.format("craft.streak.badge_a11y_format", language: "vi", 7, "Rực lửa", "Hôm nay đã hoàn thành")
        XCTAssertEqual(badgeVI, "Chuỗi 7 ngày học liên tiếp, Cấp độ Rực lửa. Hôm nay đã hoàn thành")
        
        XCTAssertEqual(CraftLocalized.string("craft.streak.badge_a11y_hint"), "Double tap to view streak details.")
        XCTAssertEqual(CraftLocalized.string("craft.streak.badge_a11y_hint", language: "vi"), "Chạm hai lần để xem chi tiết chuỗi ngày.")
        
        XCTAssertEqual(CraftLocalized.format("craft.streak.best_record_format", 14), "Best: 14 days")
        XCTAssertEqual(CraftLocalized.format("craft.streak.best_record_format", language: "vi", 14), "Kỷ lục: 14 ngày")
        
        XCTAssertEqual(CraftLocalized.format("craft.streak.freeze_shield_format", 2, 3), "2/3 Shields")
        XCTAssertEqual(CraftLocalized.format("craft.streak.freeze_shield_format", language: "vi", 2, 3), "2/3 Khiên")
        
        XCTAssertEqual(CraftLocalized.format("craft.streak.milestone_title_format", 30), "30-Day Milestone!")
        XCTAssertEqual(CraftLocalized.format("craft.streak.milestone_title_format", language: "vi", 30), "Cột mốc 30 ngày!")
        
        XCTAssertEqual(CraftLocalized.string("craft.streak.celebration_title"), "Streak Extended!")
        XCTAssertEqual(CraftLocalized.string("craft.streak.celebration_title", language: "vi"), "Chuỗi ngày rực lửa!")
        
        XCTAssertEqual(CraftLocalized.string("craft.streak.continue_action"), "Continue Learning")
        XCTAssertEqual(CraftLocalized.string("craft.streak.continue_action", language: "vi"), "Tiếp tục học")
        
        XCTAssertEqual(CraftLocalized.string("craft.streak.celebration_hint"), "Double tap to dismiss and continue learning.")
        XCTAssertEqual(CraftLocalized.string("craft.streak.celebration_hint", language: "vi"), "Chạm hai lần để đóng màn hình và tiếp tục học.")
        
        // Day Statuses
        XCTAssertEqual(CraftLocalized.string("craft.streak.day_status_completed"), "Completed")
        XCTAssertEqual(CraftLocalized.string("craft.streak.day_status_completed", language: "vi"), "Đã hoàn thành")
        XCTAssertEqual(CraftLocalized.string("craft.streak.day_status_pending"), "Pending")
        XCTAssertEqual(CraftLocalized.string("craft.streak.day_status_pending", language: "vi"), "Đang chờ hoàn thành")
        XCTAssertEqual(CraftLocalized.string("craft.streak.day_status_saved"), "Freeze shield used")
        XCTAssertEqual(CraftLocalized.string("craft.streak.day_status_saved", language: "vi"), "Đã dùng khiên bảo vệ")
        XCTAssertEqual(CraftLocalized.string("craft.streak.day_status_missed"), "Missed")
        XCTAssertEqual(CraftLocalized.string("craft.streak.day_status_missed", language: "vi"), "Bỏ lỡ")
        XCTAssertEqual(CraftLocalized.string("craft.streak.day_status_upcoming"), "Upcoming")
        XCTAssertEqual(CraftLocalized.string("craft.streak.day_status_upcoming", language: "vi"), "Chưa đến")
        
        // Actions & Overview
        XCTAssertEqual(CraftLocalized.string("craft.streak.day_inspect_hint"), "Double tap to inspect day details.")
        XCTAssertEqual(CraftLocalized.string("craft.streak.day_inspect_hint", language: "vi"), "Chạm hai lần để kiểm tra chi tiết ngày.")
        XCTAssertEqual(CraftLocalized.string("craft.streak.view_shield_action"), "View freeze shields")
        XCTAssertEqual(CraftLocalized.string("craft.streak.view_shield_action", language: "vi"), "Xem khiên bảo vệ")
        XCTAssertEqual(CraftLocalized.string("craft.streak.view_milestone_action"), "View milestone rewards")
        XCTAssertEqual(CraftLocalized.string("craft.streak.view_milestone_action", language: "vi"), "Xem mốc thưởng")
        XCTAssertEqual(CraftLocalized.string("craft.streak.card_a11y_overview"), "Displays weekly streak overview and activity status.")
        XCTAssertEqual(CraftLocalized.string("craft.streak.card_a11y_overview", language: "vi"), "Hiển thị tổng quan chuỗi ngày học trong tuần.")
        
        // Motivational Messages
        XCTAssertEqual(CraftLocalized.string("craft.streak.msg_starter_1"), "Great start! Keep up the daily habit of learning.")
        XCTAssertEqual(CraftLocalized.string("craft.streak.msg_starter_1", language: "vi"), "Khởi đầu tuyệt vời! Hãy duy trì thói quen học mỗi ngày nhé.")
        XCTAssertEqual(CraftLocalized.string("craft.streak.msg_starter"), "Great progress! You are building a solid learning habit.")
        XCTAssertEqual(CraftLocalized.string("craft.streak.msg_starter", language: "vi"), "Tuyệt vời! Bạn đang xây dựng một thói quen học tập vững chắc.")
        XCTAssertEqual(CraftLocalized.string("craft.streak.msg_blaze"), "Great streak! Your learning flame is burning bright.")
        XCTAssertEqual(CraftLocalized.string("craft.streak.msg_blaze", language: "vi"), "Phong độ tuyệt vời! Ngọn lửa học tập của bạn đang rực sáng.")
        XCTAssertEqual(CraftLocalized.string("craft.streak.msg_blaze_milestone"), "Awesome! You've achieved a blaze streak, keep up the momentum!")
        XCTAssertEqual(CraftLocalized.string("craft.streak.msg_blaze_milestone", language: "vi"), "Đẳng cấp! Bạn đã đạt chuỗi rực lửa, tiếp tục duy trì đà tiến bộ này!")
        XCTAssertEqual(CraftLocalized.string("craft.streak.msg_legendary"), "Unstoppable! You are an inspiring example of consistency.")
        XCTAssertEqual(CraftLocalized.string("craft.streak.msg_legendary", language: "vi"), "Không thể ngăn cản! Bạn là tấm gương học tập đầy cảm hứng.")
        XCTAssertEqual(CraftLocalized.string("craft.streak.msg_legendary_milestone"), "Legendary! You've reached a pinnacle milestone with extraordinary dedication!")
        XCTAssertEqual(CraftLocalized.string("craft.streak.msg_legendary_milestone", language: "vi"), "Huyền thoại! Bạn đã chinh phục cột mốc đỉnh cao với sự kiên trì phi thường!")
    }

    // MARK: - Learning Path & Journey Scope
    
    func testLearningPathStrings() {
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.empty_title"), "No Lessons Available")
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.empty_title", language: "vi"), "Chưa có bài học nào")
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.empty_desc"), "There are no lesson sections available in this learning path.")
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.empty_desc", language: "vi"), "Hiện chưa có bài học nào trong lộ trình này.")
        
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.default_unit_label"), "UNIT")
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.default_unit_label", language: "vi"), "BÀI HỌC")
        
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.continue_callout"), "CONTINUE")
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.continue_callout", language: "vi"), "TIẾP TỤC")
        
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.start_lesson"), "START LESSON")
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.start_lesson", language: "vi"), "BẮT ĐẦU HỌC")
        
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.continue_lesson_format", 40), "CONTINUE (40%)")
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.continue_lesson_format", language: "vi", 40), "TIẾP TỤC HỌC (40%)")
        
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.review_lesson_format", 5), "REVIEW (+5 XP)")
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.review_lesson_format", language: "vi", 5), "ÔN TẬP LẠI (+5 XP)")
        
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.challenge_lesson"), "CONQUER CHALLENGE")
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.challenge_lesson", language: "vi"), "CHINH PHỤC THỬ THÁCH")
        
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.locked_lesson"), "LESSON LOCKED")
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.locked_lesson", language: "vi"), "BÀI HỌC ĐANG KHÓA")
        
        // Objectives
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.objectives_header"), "Lesson Objectives")
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.objectives_header", language: "vi"), "Mục tiêu bài học")
        
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.default_objective_1"), "Master standard pronunciation and core vocabulary meanings")
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.default_objective_1", language: "vi"), "Nắm vững phát âm chuẩn và ý nghĩa từ vựng trọng tâm")
        
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.default_objective_2"), "Practice sentence reflex via interactive Spaced Repetition drills")
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.default_objective_2", language: "vi"), "Thực hành phản xạ câu qua bài tập tương tác Spaced Repetition")
        
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.default_objective_3_format", "+10 XP"), "Earn +10 XP and maintain daily study streak")
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.default_objective_3_format", language: "vi", "+10 XP"), "Tích lũy +10 XP và duy trì chuỗi Streak học tập")
        
        // Accessibility labels & hints
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.node_completed_a11y", "Basics"), "Lesson: Basics, Completed")
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.node_completed_a11y", language: "vi", "Cơ bản"), "Bài học: Cơ bản, Đã hoàn thành")
        
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.node_current_format_a11y", "Basics", 50), "Lesson: Basics, Current lesson. 50% complete")
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.node_current_format_a11y", language: "vi", "Cơ bản", 50), "Bài học: Cơ bản, Bài học hiện tại. Đã hoàn thành 50%")
        
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.node_current_a11y", "Basics"), "Lesson: Basics, Current lesson")
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.node_current_a11y", language: "vi", "Cơ bản"), "Bài học: Cơ bản, Bài học hiện tại")
        
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.node_in_progress_format_a11y", "Basics", 30), "Lesson: Basics, In progress. 30% complete")
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.node_in_progress_format_a11y", language: "vi", "Cơ bản", 30), "Bài học: Cơ bản, Đang học dở. Đã hoàn thành 30%")
        
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.node_in_progress_a11y", "Basics"), "Lesson: Basics, In progress")
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.node_in_progress_a11y", language: "vi", "Cơ bản"), "Bài học: Cơ bản, Đang học dở")
        
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.node_upcoming_a11y", "Basics"), "Lesson: Basics, Upcoming lesson")
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.node_upcoming_a11y", language: "vi", "Cơ bản"), "Bài học: Cơ bản, Bài học sắp tới")
        
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.node_locked_a11y", "Basics"), "Lesson: Basics, Locked")
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.node_locked_a11y", language: "vi", "Cơ bản"), "Bài học: Cơ bản, Đang khóa")
        
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.node_bonus_a11y", "Bonus Challenge"), "Bonus Lesson: Bonus Challenge")
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.node_bonus_a11y", language: "vi", "Thử thách phụ"), "Bài học thử thách: Thử thách phụ")
        
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.reward_format_a11y", 20), "Reward: 20 XP")
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.reward_format_a11y", language: "vi", 20), "Phần thưởng: 20 XP")
        
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.tap_to_review_hint"), "Double tap to review")
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.tap_to_review_hint", language: "vi"), "Nhấn đúp để ôn tập")
        
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.tap_to_continue_hint"), "Double tap to continue")
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.tap_to_continue_hint", language: "vi"), "Nhấn đúp để tiếp tục học")
        
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.tap_to_start_hint"), "Double tap to start")
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.tap_to_start_hint", language: "vi"), "Nhấn đúp để bắt đầu học")
        
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.unlock_requirement_hint"), "Complete previous lessons to unlock")
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.unlock_requirement_hint", language: "vi"), "Hoàn thành bài học trước để mở khóa")
        
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.duration_format_a11y", "3 min"), "Duration: 3 min")
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.duration_format_a11y", language: "vi", "3 phút"), "Thời lượng: 3 phút")

        XCTAssertEqual(CraftLocalized.string("craft.learning_path.close_sheet_hint"), "Double tap to close lesson details")
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.close_sheet_hint", language: "vi"), "Nhấn đúp để đóng thông tin bài học")
    }

    func testLearningPathStickyHUDTapToScrollHintLocalization() {
        let key = "craft.learning_path.tap_to_scroll_unit_hint"
        let enValue = CraftLocalized.string(key, locale: Locale(identifier: "en"))
        let viValue = CraftLocalized.string(key, locale: Locale(identifier: "vi"))

        XCTAssertFalse(enValue.isEmpty)
        XCTAssertFalse(viValue.isEmpty)
        XCTAssertEqual(enValue, "Double tap to scroll to the top of this unit")
        XCTAssertEqual(viValue, "Chạm hai lần để cuộn về đầu bài học này")
    }

    // MARK: - Fluid Journey Scope

    func testFluidJourneyStrings() {
        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.start_lesson"), "START LESSON")
        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.start_lesson", language: "vi"), "BẮT ĐẦU HỌC")

        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.start"), "START")
        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.start", language: "vi"), "BẮT ĐẦU")

        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.continue"), "CONTINUE")
        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.continue", language: "vi"), "TIẾP TỤC")

        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.keep_going"), "KEEP GOING!")
        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.keep_going", language: "vi"), "TIẾP BƯỚC!")

        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.almost_there"), "ALMOST THERE!")
        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.almost_there", language: "vi"), "SẮP VỀ ĐÍCH!")

        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.challenge"), "CHALLENGE!")
        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.challenge", language: "vi"), "THỬ THÁCH!")

        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.claim_gift"), "CLAIM GIFT")
        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.claim_gift", language: "vi"), "MỞ QUÀ")

        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.completed_status"), "Completed")
        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.completed_status", language: "vi"), "Đã xong")

        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.current_status"), "Current")
        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.current_status", language: "vi"), "Đang học")

        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.drawer_title"), "Learning Path")
        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.drawer_title", language: "vi"), "Lộ trình học")

        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.drawer_subtitle"), "Pick a topic to jump to")
        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.drawer_subtitle", language: "vi"), "Chọn topic để đi tới")

        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.unit_picker_title"), "Curriculum & Units")
        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.unit_picker_title", language: "vi"), "Lộ trình & Chủ đề")

        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.adjust_plan"), "Adjust plan")
        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.adjust_plan", language: "vi"), "Tuỳ chỉnh lộ trình")

        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.select_unit_hint"), "Double tap to switch to this unit")
        XCTAssertEqual(CraftLocalized.string("craft.fluid_journey.select_unit_hint", language: "vi"), "Chạm hai lần để chuyển sang chủ đề này")

        XCTAssertEqual(CraftLocalized.format("craft.fluid_journey.reward_xp", 25), "+25 XP")
        XCTAssertEqual(CraftLocalized.format("craft.fluid_journey.reward_xp", language: "vi", 25), "+25 XP")
    }

    // MARK: - Navigation, Feedback & Audio Scope
    
    func testNavigationAndAudioFeedbackStrings() {
        // Tab Bar
        XCTAssertEqual(CraftLocalized.format("craft.tab_bar.badge_count_format", 3), "3 new items")
        XCTAssertEqual(CraftLocalized.format("craft.tab_bar.badge_count_format", language: "vi", 3), "3 mục mới")
        
        XCTAssertEqual(CraftLocalized.string("craft.tab_bar.center_action_fallback"), "Action")
        XCTAssertEqual(CraftLocalized.string("craft.tab_bar.center_action_fallback", language: "vi"), "Tác vụ")
        
        // Waveform
        XCTAssertEqual(CraftLocalized.string("craft.waveform.recording_active_a11y"), "Audio waveform recording active")
        XCTAssertEqual(CraftLocalized.string("craft.waveform.recording_active_a11y", language: "vi"), "Đang thu âm sóng âm thanh")
        
        XCTAssertEqual(CraftLocalized.string("craft.waveform.visualizer_a11y"), "Audio waveform visualizer")
        XCTAssertEqual(CraftLocalized.string("craft.waveform.visualizer_a11y", language: "vi"), "Trình hiển thị sóng âm")
        
        XCTAssertEqual(CraftLocalized.format("craft.waveform.audio_level_format", 60), "60 percent average audio level")
        XCTAssertEqual(CraftLocalized.format("craft.waveform.audio_level_format", language: "vi", 60), "Mức âm thanh trung bình 60 phần trăm")
        
        // Countdown
        XCTAssertEqual(CraftLocalized.format("craft.countdown.label_format", 3), "Countdown 3")
        XCTAssertEqual(CraftLocalized.format("craft.countdown.label_format", language: "vi", 3), "Đếm ngược 3")
        
        XCTAssertEqual(CraftLocalized.string("craft.countdown.go_text"), "GO!")
        XCTAssertEqual(CraftLocalized.string("craft.countdown.go_text", language: "vi"), "BẮT ĐẦU!")
        
        XCTAssertEqual(CraftLocalized.string("craft.countdown.time_remaining_label"), "Time remaining")
        XCTAssertEqual(CraftLocalized.string("craft.countdown.time_remaining_label", language: "vi"), "Thời gian còn lại")
        
        XCTAssertEqual(CraftLocalized.string("craft.countdown.tap_to_skip"), "Tap anywhere to skip")
        XCTAssertEqual(CraftLocalized.string("craft.countdown.tap_to_skip", language: "vi"), "Chạm để bỏ qua")
        
        XCTAssertEqual(CraftLocalized.string("craft.countdown.tap_to_skip_hint"), "Double tap to start immediately")
        XCTAssertEqual(CraftLocalized.string("craft.countdown.tap_to_skip_hint", language: "vi"), "Nhấn đúp để bắt đầu ngay")
        
        // Sparkle
        XCTAssertEqual(CraftLocalized.string("craft.sparkle.sparkle_label"), "Sparkle!")
        XCTAssertEqual(CraftLocalized.string("craft.sparkle.sparkle_label", language: "vi"), "Lấp lánh!")
        
        XCTAssertEqual(CraftLocalized.string("craft.sparkle.celebration_label"), "Celebration!")
        XCTAssertEqual(CraftLocalized.string("craft.sparkle.celebration_label", language: "vi"), "Chúc mừng!")

        // Speaker / Pronunciation Audio
        XCTAssertEqual(CraftLocalized.string("craft.audio.pronounce"), "Pronounce word")
        XCTAssertEqual(CraftLocalized.string("craft.audio.pronounce", language: "vi"), "Phát âm từ vựng")
        XCTAssertEqual(CraftLocalized.string("craft.audio.playing"), "Playing pronunciation...")
        XCTAssertEqual(CraftLocalized.string("craft.audio.playing", language: "vi"), "Đang phát âm...")
    }

    func testFeedbackSheetLocalizationKeys() {
        let successEn = CraftLocalized.string("craft.feedback.success_title", language: "en")
        let successVi = CraftLocalized.string("craft.feedback.success_title", language: "vi")
        let errorEn = CraftLocalized.string("craft.feedback.error_title", language: "en")
        let errorVi = CraftLocalized.string("craft.feedback.error_title", language: "vi")
        let warningEn = CraftLocalized.string("craft.feedback.warning_title", language: "en")
        let warningVi = CraftLocalized.string("craft.feedback.warning_title", language: "vi")
        let infoEn = CraftLocalized.string("craft.feedback.info_title", language: "en")
        let infoVi = CraftLocalized.string("craft.feedback.info_title", language: "vi")
        let continueEn = CraftLocalized.string("craft.feedback.continue_action", language: "en")
        let continueVi = CraftLocalized.string("craft.feedback.continue_action", language: "vi")

        XCTAssertEqual(successEn, "Nice work!")
        XCTAssertEqual(successVi, "Chính xác!")
        XCTAssertEqual(errorEn, "Incorrect")
        XCTAssertEqual(errorVi, "Chưa chính xác")
        XCTAssertEqual(warningEn, "Almost!")
        XCTAssertEqual(warningVi, "Gần đúng!")
        XCTAssertEqual(infoEn, "Explanation")
        XCTAssertEqual(infoVi, "Giải thích")
        XCTAssertEqual(continueEn, "Continue")
        XCTAssertEqual(continueVi, "Tiếp tục")
    }

    // MARK: - Speech Scope

    func testSpeechLocalizationKeys() {
        XCTAssertEqual(CraftLocalized.string("craft.speech.tap_to_speak"), "Tap to speak")
        XCTAssertEqual(CraftLocalized.string("craft.speech.tap_to_speak", language: "vi"), "Chạm để nói")

        XCTAssertEqual(CraftLocalized.string("craft.speech.listening"), "Listening...")
        XCTAssertEqual(CraftLocalized.string("craft.speech.listening", language: "vi"), "Đang lắng nghe...")

        XCTAssertEqual(CraftLocalized.string("craft.speech.analyzing"), "Analyzing pronunciation...")
        XCTAssertEqual(CraftLocalized.string("craft.speech.analyzing", language: "vi"), "Đang phân tích phát âm...")

        XCTAssertEqual(CraftLocalized.string("craft.speech.try_again"), "Try speaking again")
        XCTAssertEqual(CraftLocalized.string("craft.speech.try_again", language: "vi"), "Thử nói lại")

        XCTAssertEqual(CraftLocalized.string("craft.speech.mic_start_a11y"), "Start speaking")
        XCTAssertEqual(CraftLocalized.string("craft.speech.mic_start_a11y", language: "vi"), "Bắt đầu nói")

        XCTAssertEqual(CraftLocalized.string("craft.speech.mic_stop_a11y"), "Stop recording")
        XCTAssertEqual(CraftLocalized.string("craft.speech.mic_stop_a11y", language: "vi"), "Dừng ghi âm")

        XCTAssertEqual(CraftLocalized.format("craft.speech.score_format", 95), "Score: 95%")
        XCTAssertEqual(CraftLocalized.format("craft.speech.score_format", language: "vi", 95), "Điểm: 95%")
    }

    // MARK: - Fallback and Missing Keys
    
    func testFallbackToKeyWhenMissing() {
        let missingKey = "craft.nonexistent.key"
        XCTAssertEqual(CraftLocalized.string(missingKey), missingKey)
        XCTAssertEqual(CraftLocalized.string(missingKey, language: "vi"), missingKey)
    }
    
    func testCommentParameter() {
        let confirmWithComment = CraftLocalized.string("craft.common.action.confirm", comment: "Confirm button action")
        XCTAssertEqual(confirmWithComment, "Confirm")
    }
}
