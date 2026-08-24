import XCTest
@testable import CraftUIKit

final class LocalizationTests: XCTestCase {
    
    // MARK: - English Default Localizations
    
    func testEnglishActionStrings() {
        XCTAssertEqual(CraftLocalized.string("craft.action.confirm"), "Confirm")
        XCTAssertEqual(CraftLocalized.string("craft.action.cancel"), "Cancel")
        XCTAssertEqual(CraftLocalized.string("craft.action.dismiss"), "Dismiss")
        XCTAssertEqual(CraftLocalized.string("craft.action.continue"), "Continue")
        XCTAssertEqual(CraftLocalized.string("craft.action.close"), "Close")
        XCTAssertEqual(CraftLocalized.string("craft.action.retry"), "Retry")
    }
    
    func testEnglishChoiceStrings() {
        XCTAssertEqual(CraftLocalized.string("craft.choice.correct"), "Correct Answer")
        XCTAssertEqual(CraftLocalized.string("craft.choice.wrong"), "Incorrect Answer")
        XCTAssertEqual(CraftLocalized.string("craft.choice.selected"), "Selected")
    }
    
    func testEnglishJourneyStrings() {
        XCTAssertEqual(CraftLocalized.string("craft.journey.completedA11y"), "Completed")
        XCTAssertEqual(CraftLocalized.string("craft.journey.continueCallout"), "CONTINUE")
        XCTAssertEqual(CraftLocalized.string("craft.journey.currentA11y"), "Current step")
        XCTAssertEqual(CraftLocalized.string("craft.journey.lockedA11y"), "Locked")
    }
    
    func testEnglishSearchAndStepperStrings() {
        XCTAssertEqual(CraftLocalized.string("craft.search.clearA11y"), "Clear search")
        XCTAssertEqual(CraftLocalized.string("craft.search.placeholder"), "Search...")
        XCTAssertEqual(CraftLocalized.string("craft.stepper.decreaseA11y"), "Decrease")
        XCTAssertEqual(CraftLocalized.string("craft.stepper.increaseA11y"), "Increase")
    }
    
    func testEnglishStreakStrings() {
        XCTAssertEqual(CraftLocalized.string("craft.streak.daysUnit"), "days")
        XCTAssertEqual(CraftLocalized.string("craft.streak.tierBlaze"), "Blaze Streak")
        XCTAssertEqual(CraftLocalized.string("craft.streak.tierLegendary"), "Legendary Streak")
        XCTAssertEqual(CraftLocalized.string("craft.streak.tierStarter"), "Starter Streak")
    }
    
    // MARK: - Formatted Strings
    
    func testEnglishFormattedStrings() {
        let bestRecord = CraftLocalized.format("craft.streak.bestRecord", 14)
        XCTAssertEqual(bestRecord, "Best: 14 days")
        
        let freezeShield = CraftLocalized.format("craft.streak.freezeShield", 2, 3)
        XCTAssertEqual(freezeShield, "2/3 Shields")
        
        let bestRecordArray = CraftLocalized.format("craft.streak.bestRecord", [14 as CVarArg])
        XCTAssertEqual(bestRecordArray, "Best: 14 days")
        
        let freezeShieldArray = CraftLocalized.format("craft.streak.freezeShield", [2 as CVarArg, 3 as CVarArg])
        XCTAssertEqual(freezeShieldArray, "2/3 Shields")
    }
    
    // MARK: - Vietnamese Localizations
    
    func testVietnameseActionStrings() {
        XCTAssertEqual(CraftLocalized.string("craft.action.confirm", language: "vi"), "Xác nhận")
        XCTAssertEqual(CraftLocalized.string("craft.action.cancel", language: "vi"), "Hủy")
        XCTAssertEqual(CraftLocalized.string("craft.action.dismiss", language: "vi"), "Đóng")
        XCTAssertEqual(CraftLocalized.string("craft.action.continue", language: "vi"), "Tiếp tục")
        XCTAssertEqual(CraftLocalized.string("craft.action.close", language: "vi"), "Đóng")
        XCTAssertEqual(CraftLocalized.string("craft.action.retry", language: "vi"), "Thử lại")
    }
    
    func testVietnameseChoiceStrings() {
        XCTAssertEqual(CraftLocalized.string("craft.choice.correct", language: "vi"), "Đáp án đúng")
        XCTAssertEqual(CraftLocalized.string("craft.choice.wrong", language: "vi"), "Đáp án chưa đúng")
        XCTAssertEqual(CraftLocalized.string("craft.choice.selected", language: "vi"), "Đã chọn")
    }
    
    func testVietnameseJourneyStrings() {
        XCTAssertEqual(CraftLocalized.string("craft.journey.completedA11y", language: "vi"), "Đã hoàn thành")
        XCTAssertEqual(CraftLocalized.string("craft.journey.continueCallout", language: "vi"), "TIẾP TỤC")
        XCTAssertEqual(CraftLocalized.string("craft.journey.currentA11y", language: "vi"), "Bước hiện tại")
        XCTAssertEqual(CraftLocalized.string("craft.journey.lockedA11y", language: "vi"), "Đang khóa")
    }
    
    func testVietnameseSearchAndStepperStrings() {
        XCTAssertEqual(CraftLocalized.string("craft.search.clearA11y", language: "vi"), "Xóa tìm kiếm")
        XCTAssertEqual(CraftLocalized.string("craft.search.placeholder", language: "vi"), "Tìm kiếm...")
        XCTAssertEqual(CraftLocalized.string("craft.stepper.decreaseA11y", language: "vi"), "Giảm")
        XCTAssertEqual(CraftLocalized.string("craft.stepper.increaseA11y", language: "vi"), "Tăng")
    }
    
    func testVietnameseStreakStrings() {
        XCTAssertEqual(CraftLocalized.string("craft.streak.daysUnit", language: "vi"), "ngày")
        XCTAssertEqual(CraftLocalized.string("craft.streak.tierBlaze", language: "vi"), "Chuỗi rực lửa")
        XCTAssertEqual(CraftLocalized.string("craft.streak.tierLegendary", language: "vi"), "Chuỗi huyền thoại")
        XCTAssertEqual(CraftLocalized.string("craft.streak.tierStarter", language: "vi"), "Chuỗi khởi đầu")
    }
    
    func testVietnameseFormattedStrings() {
        let bestRecord = CraftLocalized.format("craft.streak.bestRecord", language: "vi", 14)
        XCTAssertEqual(bestRecord, "Kỷ lục: 14 ngày")
        
        let freezeShield = CraftLocalized.format("craft.streak.freezeShield", language: "vi", 2, 3)
        XCTAssertEqual(freezeShield, "2/3 Khiên")
        
        let bestRecordArray = CraftLocalized.format("craft.streak.bestRecord", language: "vi", [14 as CVarArg])
        XCTAssertEqual(bestRecordArray, "Kỷ lục: 14 ngày")
        
        let freezeShieldArray = CraftLocalized.format("craft.streak.freezeShield", language: "vi", [2 as CVarArg, 3 as CVarArg])
        XCTAssertEqual(freezeShieldArray, "2/3 Khiên")
    }
    
    // MARK: - Fallback and Missing Keys
    
    func testFallbackToKeyWhenMissing() {
        let missingKey = "craft.nonexistent.key"
        XCTAssertEqual(CraftLocalized.string(missingKey), missingKey)
        XCTAssertEqual(CraftLocalized.string(missingKey, language: "vi"), missingKey)
    }
    
    func testCommentParameter() {
        let confirmWithComment = CraftLocalized.string("craft.action.confirm", comment: "Confirm button action")
        XCTAssertEqual(confirmWithComment, "Confirm")
    }
}
