import Foundation
import SwiftUI
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

final class OnboardingLocalizationTests: XCTestCase {
    private let expectedOnboardingKeys: [String: (vi: String, en: String)] = [
        "app.onboarding.common.skip": ("Bỏ qua", "Skip"),
        "app.onboarding.common.continue": ("Tiếp tục", "Continue"),
        "app.onboarding.goal.title": ("Mục tiêu học tiếng Anh của bạn là gì?", "What is your English learning goal?"),
        "app.onboarding.goal.subtitle": ("Chúng tôi sẽ tập trung vào nhóm từ vựng bạn thực sự cần.", "We'll tailor vocabulary you actually use in daily life."),
        "app.onboarding.goal.daily": ("Giao tiếp hằng ngày", "Daily Communication"),
        "app.onboarding.goal.daily_desc": ("Du lịch, kết bạn, đời sống", "Travel, making friends, everyday life"),
        "app.onboarding.goal.business": ("Công sở & Sự nghiệp", "Career & Business"),
        "app.onboarding.goal.business_desc": ("Họp hành, đàm phán, viết email", "Meetings, negotiations, professional emails"),
        "app.onboarding.goal.academic": ("Học thuật & Luyện thi", "Academic & Exam Prep"),
        "app.onboarding.goal.academic_desc": ("IELTS, TOEIC, du học", "IELTS, TOEIC, studying abroad"),
        "app.onboarding.goal.tech": ("Công nghệ & AI", "Technology & AI"),
        "app.onboarding.goal.tech_desc": ("Lập trình, đổi mới sáng tạo", "Coding, software, tech innovation"),
        "app.onboarding.level.title": ("Trình độ tiếng Anh hiện tại của bạn?", "What is your current English level?"),
        "app.onboarding.level.subtitle": ("Đừng lo, bạn có thể điều chỉnh lại bất cứ lúc nào trong Cài đặt.", "You can always adjust your starting level in Settings."),
        "app.onboarding.level.a1": ("Mới bắt đầu / Mất gốc (A1)", "Beginner (A1)"),
        "app.onboarding.level.a1_desc": ("Chưa có nhiều từ vựng, muốn học từ nền tảng", "Starting fresh with everyday fundamentals"),
        "app.onboarding.level.a2": ("Sơ cấp (A2)", "Elementary (A2)"),
        "app.onboarding.level.a2_desc": ("Biết các từ đơn giản, nhưng phản xạ còn ngập ngừng", "Know basic words, but hesitate when speaking"),
        "app.onboarding.level.b1_b2": ("Trung cấp (B1 - B2)", "Intermediate (B1 - B2)"),
        "app.onboarding.level.b1_b2_desc": ("Tự tin trong các tình huống quen thuộc, muốn nói lưu loát hơn", "Comfortable in routine situations, want deeper fluency"),
        "app.onboarding.level.c1": ("Nâng cao (C1)", "Advanced (C1)"),
        "app.onboarding.level.c1_desc": ("Muốn làm chủ từ vựng chuyên sâu và tự nhiên", "Aiming for nuanced, academic, and native expressions"),
        "app.onboarding.habit.title": ("Bạn muốn học bao nhiêu từ mỗi ngày?", "How many words do you want to learn each day?"),
        "app.onboarding.habit.subtitle": ("Học đều đặn mỗi ngày là bí quyết ghi nhớ phản xạ lâu dài.", "Consistency is the secret to fluent vocabulary recall."),
        "app.onboarding.habit.words_per_day_format": ("%lld từ mỗi ngày", "%lld words per day"),
        "app.onboarding.habit.minutes_per_day_format": ("%lld phút / ngày", "%lld min / day"),
        "app.onboarding.habit.popular_badge": ("Phổ biến nhất", "Most Popular"),
        "app.onboarding.habit.reminder_header": ("Giờ nhắc nhở hằng ngày", "Daily Reminder"),
        "app.onboarding.habit.reminder_morning": ("Sáng 08:00", "Morning 08:00"),
        "app.onboarding.habit.reminder_lunch": ("Trưa 12:30", "Lunch 12:30"),
        "app.onboarding.habit.reminder_evening": ("Tối 20:00", "Evening 20:00"),
        "app.onboarding.reveal.analyzing": ("Đang phân tích mục tiêu & trình độ...", "Analyzing your profile & goals..."),
        "app.onboarding.reveal.curating": ("Đang cá nhân hóa bộ từ vựng tối ưu...", "Curating personalized vocabulary decks..."),
        "app.onboarding.reveal.ready": ("Lộ trình hoàn hảo của bạn đã sẵn sàng!", "Your personalized roadmap is ready!"),
        "app.onboarding.reveal.projection_format": ("Với %lld từ/ngày, bạn sẽ làm chủ %lld từ vựng sau 30 ngày!", "At %lld words/day, you'll master %lld words in 30 days!"),
        "app.onboarding.reveal.cta": ("Bắt đầu bài học đầu tiên (1 phút)", "Start First Lesson (1 min)"),
        "app.onboarding.mini_lesson.next_cta": ("Tiếp tục", "Continue"),
        "app.onboarding.mini_lesson.check_cta": ("Hoàn thành", "Finish"),
        "app.onboarding.celebration.title": ("🔥 Đã kích hoạt Streak Ngày 1!", "🔥 Day 1 Streak Unlocked!"),
        "app.onboarding.celebration.subtitle": ("Bạn đã hoàn thành xuất sắc bài học đầu tiên. Hãy duy trì thói quen mỗi ngày nhé!", "You crushed your first lesson! Keep the momentum going tomorrow."),
        "app.onboarding.celebration.cta": ("Khám phá lộ trình học", "Explore My Learning Path")
    ]

    func testOnboardingCatalogIntegrity() throws {
        let potentialPaths: [String?] = [
            Bundle.main.path(forResource: "Localizable", ofType: "xcstrings"),
            URL(fileURLWithPath: #file)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("VocabCraftApp/Resources/Localizable.xcstrings").path,
            "VocabCraftApp/Resources/Localizable.xcstrings"
        ]

        var data: Data?
        for case let path? in potentialPaths {
            if let fileData = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                data = fileData
                break
            }
        }

        let fileData = try XCTUnwrap(data, "Localizable.xcstrings should be found")
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: fileData) as? [String: Any],
            "Catalog should parse as JSON dictionary"
        )
        let strings = try XCTUnwrap(
            json["strings"] as? [String: [String: Any]],
            "Catalog should contain 'strings' key"
        )

        for (key, expected) in expectedOnboardingKeys {
            let entry = try XCTUnwrap(strings[key], "Missing required key in catalog: \(key)")
            XCTAssertEqual(
                entry["extractionState"] as? String,
                "manual",
                "Key \(key) must have extractionState: manual"
            )

            let localizations = try XCTUnwrap(
                entry["localizations"] as? [String: [String: Any]],
                "Key \(key) must have localizations dictionary"
            )

            // Verify EN
            let enLoc = try XCTUnwrap(localizations["en"], "Key \(key) missing EN localization")
            let enUnit = try XCTUnwrap(enLoc["stringUnit"] as? [String: Any], "Key \(key) missing EN stringUnit")
            XCTAssertEqual(enUnit["state"] as? String, "translated", "Key \(key) EN state must be 'translated'")
            let enVal = try XCTUnwrap(enUnit["value"] as? String, "Key \(key) missing EN value")
            XCTAssertEqual(enVal, expected.en, "Key \(key) EN value mismatch: expected '\(expected.en)' but got '\(enVal)'")

            // Verify VI
            let viLoc = try XCTUnwrap(localizations["vi"], "Key \(key) missing VI localization")
            let viUnit = try XCTUnwrap(viLoc["stringUnit"] as? [String: Any], "Key \(key) missing VI stringUnit")
            XCTAssertEqual(viUnit["state"] as? String, "translated", "Key \(key) VI state must be 'translated'")
            let viVal = try XCTUnwrap(viUnit["value"] as? String, "Key \(key) missing VI value")
            XCTAssertEqual(viVal, expected.vi, "Key \(key) VI value mismatch: expected '\(expected.vi)' but got '\(viVal)'")
        }
    }
}
