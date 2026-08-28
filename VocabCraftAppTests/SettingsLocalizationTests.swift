import SwiftUI
@testable import VocabCraftApp
import XCTest

final class SettingsLocalizationTests: XCTestCase {
    private let expectedSettingsKeys: [String: (vi: String, en: String)] = [
        "app.settings.title": ("Cài đặt", "Settings"),
        "app.settings.profile.membership_active": ("PRO ACTIVE", "PRO ACTIVE"),
        "app.settings.profile.perks": ("Thành viên Pro · Đã mở khoá toàn bộ 3,000+ từ Oxford & Reflex Blitz", "Pro Member · Unlocked all 3,000+ Oxford words & Reflex Blitz"),
        "app.settings.profile.action_view": ("Xem hồ sơ & thành tích", "View Profile & Achievements"),
        "app.settings.section.learning": ("HỌC TẬP & ÔN TẬP (SRS)", "LEARNING & SRS"),
        "app.settings.learning.target_level": ("Trình độ mục tiêu", "Target Level"),
        "app.settings.learning.app_language": ("Ngôn ngữ ứng dụng", "App Language"),
        "app.settings.learning.lang_system": ("Hệ thống", "System"),
        "app.settings.learning.lang_vi": ("Tiếng Việt", "Vietnamese"),
        "app.settings.learning.lang_en": ("English", "English"),
        "app.settings.learning.daily_goal": ("Mục tiêu hàng ngày", "Daily Goal"),
        "app.settings.learning.reminders": ("Nhắc nhở ôn tập", "Review Reminders"),
        "app.settings.learning.reminder_time": ("Giờ nhắc nhở", "Reminder Time"),
        "app.settings.learning.reset_srs": ("Đặt lại tiến độ SRS", "Reset SRS Progress"),
        "app.settings.learning.reset_srs_subtitle": ("Xoá toàn bộ từ đã học và chuỗi ghi nhớ", "Reset all learned words and memory streaks"),
        "app.settings.learning.reset_confirm_title": ("Xác nhận đặt lại tiến độ?", "Confirm Reset Progress?"),
        "app.settings.learning.reset_confirm_message": ("Hành động này sẽ xoá toàn bộ thống kê SRS và không thể hoàn tác.", "This will erase all SRS statistics and cannot be undone."),
        "app.settings.section.audio": ("ÂM THANH & PHÁT ÂM", "AUDIO & PRONUNCIATION"),
        "app.settings.audio.accent": ("Giọng phát âm TTS", "TTS Voice Accent"),
        "app.settings.audio.accent_us": ("US (Mỹ)", "US (American)"),
        "app.settings.audio.accent_uk": ("UK (Anh)", "UK (British)"),
        "app.settings.audio.speed": ("Tốc độ đọc", "Speech Speed"),
        "app.settings.audio.test_tts": ("Nghe thử phát âm mẫu", "Test Speech Pronunciation"),
        "app.settings.audio.playing_preview": ("Đang phát âm thanh mẫu...", "Playing sample audio..."),
        "app.settings.section.appearance": ("GIAO DIỆN & TRẢI NGHIỆM", "APPEARANCE & EXPERIENCE"),
        "app.settings.appearance.theme_mode": ("Chế độ giao diện", "Appearance Mode"),
        "app.settings.appearance.theme_dark": ("Tối", "Dark"),
        "app.settings.appearance.theme_light": ("Sáng", "Light"),
        "app.settings.appearance.theme_system": ("Tự động", "System"),
        "app.settings.appearance.haptics": ("Rung phản hồi", "Haptic Feedback"),
        "app.settings.appearance.sound_effects": ("Âm thanh hiệu ứng", "Sound Effects"),
        "app.settings.section.dev_tools": ("CÔNG CỤ PHÁT TRIỂN (DEV ONLY)", "DEVELOPER TOOLS (DEV ONLY)"),
        "app.settings.dev.theme_preset": ("Theme thiết kế (Design Preset)", "Design Preset Theme"),
        "app.settings.dev.catalog_title": ("CraftUIKit Catalog", "CraftUIKit Catalog"),
        "app.settings.dev.catalog_subtitle": ("Bộ sưu tập linh kiện & token giao diện", "Interactive component & token gallery"),
        "app.settings.section.about": ("THÔNG TIN ỨNG DỤNG", "ABOUT & SYSTEM"),
        "app.settings.about.icloud_sync": ("Đồng bộ iCloud", "iCloud Sync"),
        "app.settings.about.synced": ("Đã đồng bộ", "Synced"),
        "app.settings.about.clear_cache": ("Xoá bộ nhớ đệm", "Clear Cache"),
        "app.settings.about.app_version": ("Phiên bản ứng dụng", "App Version"),
        "app.settings.profile.tagline": ("Chinh phục 3,000+ từ vựng Oxford & Phản xạ Reflex Blitz", "Master 3,000+ Oxford words with Reflex Blitz"),
        "app.profile.title": ("Hồ sơ & Thành tích", "Profile & Achievements"),
        "app.profile.words_learned": ("Từ đã học", "Words Learned"),
        "app.profile.reflex_accuracy": ("Chính xác phản xạ", "Reflex Accuracy"),
        "app.profile.avg_speed": ("Tốc độ phản xạ TB", "Avg Speed"),
        "app.profile.streak_days": ("Chuỗi ngày", "Streak Days"),
        "app.profile.cefr_mastery": ("Tiến độ Oxford CEFR", "Oxford CEFR Mastery"),
        "app.profile.achievements": ("Huy hiệu & Danh hiệu", "Badges & Achievements"),
        "app.profile.badge_reflex_master": ("Bậc thầy phản xạ", "Reflex Master"),
        "app.profile.badge_streak_blaze": ("Ngọn lửa 14 ngày", "14-Day Blaze"),
        "app.profile.badge_oxford_pioneer": ("Nhà thám hiểm Oxford", "Oxford Pioneer")
    ]

    func testAllSettingsStringsHaveBilingualTranslations() {
        let keys: [String] = [
            "app.settings.title",
            "app.settings.profile.membership_active",
            "app.settings.profile.perks",
            "app.settings.profile.action_view",
            "app.settings.section.learning",
            "app.settings.learning.target_level",
            "app.settings.learning.app_language",
            "app.settings.learning.lang_system",
            "app.settings.learning.lang_vi",
            "app.settings.learning.lang_en",
            "app.settings.learning.daily_goal",
            "app.settings.learning.reminders",
            "app.settings.learning.reminder_time",
            "app.settings.learning.reset_srs",
            "app.settings.learning.reset_srs_subtitle",
            "app.settings.learning.reset_confirm_title",
            "app.settings.learning.reset_confirm_message",
            "app.settings.section.audio",
            "app.settings.audio.accent",
            "app.settings.audio.accent_us",
            "app.settings.audio.accent_uk",
            "app.settings.audio.speed",
            "app.settings.audio.test_tts",
            "app.settings.audio.playing_preview",
            "app.settings.section.appearance",
            "app.settings.appearance.theme_mode",
            "app.settings.appearance.theme_dark",
            "app.settings.appearance.theme_light",
            "app.settings.appearance.theme_system",
            "app.settings.appearance.haptics",
            "app.settings.appearance.sound_effects",
            "app.settings.section.dev_tools",
            "app.settings.dev.theme_preset",
            "app.settings.dev.catalog_title",
            "app.settings.dev.catalog_subtitle",
            "app.settings.section.about",
            "app.settings.about.icloud_sync",
            "app.settings.about.synced",
            "app.settings.about.clear_cache",
            "app.settings.about.app_version",
            "app.settings.profile.tagline",
            "app.profile.title",
            "app.profile.words_learned",
            "app.profile.reflex_accuracy",
            "app.profile.avg_speed",
            "app.profile.streak_days",
            "app.profile.cefr_mastery",
            "app.profile.achievements",
            "app.profile.badge_reflex_master",
            "app.profile.badge_streak_blaze",
            "app.profile.badge_oxford_pioneer"
        ]

        XCTAssertEqual(keys.count, 51, "There must be exactly 51 required keys for Settings and Profile")

        for key in keys {
            XCTAssertNotNil(expectedSettingsKeys[key], "Key \(key) should be present in expected dictionary")
        }
    }

    func testSettingsCatalogIntegrity() throws {
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

        for (key, expected) in expectedSettingsKeys {
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

    func testAppStringsSettingsAccessors() {
        XCTAssertEqual(AppStrings.Settings.titleText, "Settings")
        XCTAssertEqual(AppStrings.Settings.membershipActiveText, "PRO ACTIVE")
        XCTAssertEqual(AppStrings.Settings.profilePerksText, "Pro Member · Unlocked all 3,000+ Oxford words & Reflex Blitz")
        XCTAssertEqual(AppStrings.Settings.profileTaglineText, "Master 3,000+ Oxford words with Reflex Blitz")
        XCTAssertEqual(AppStrings.Settings.profileActionViewText, "View Profile & Achievements")
        XCTAssertEqual(AppStrings.Settings.targetLevelText, "Target Level")
        XCTAssertEqual(AppStrings.Settings.appLanguageText, "App Language")
        XCTAssertEqual(AppStrings.Settings.dailyGoalText, "Daily Goal")
        XCTAssertEqual(AppStrings.Settings.accentUSText, "US (American)")
        XCTAssertEqual(AppStrings.Settings.accentUKText, "UK (British)")
        XCTAssertEqual(AppStrings.Settings.themeDarkText, "Dark")
        XCTAssertEqual(AppStrings.Settings.themeLightText, "Light")
        XCTAssertEqual(AppStrings.Settings.themeSystemText, "System")

        // LocalizedStringKey accessors
        XCTAssertNotNil(AppStrings.Settings.title)
        XCTAssertNotNil(AppStrings.Settings.membershipActive)
        XCTAssertNotNil(AppStrings.Settings.profilePerks)
        XCTAssertNotNil(AppStrings.Settings.profileTagline)
        XCTAssertNotNil(AppStrings.Settings.profileActionView)
        XCTAssertNotNil(AppStrings.Settings.sectionLearning)
        XCTAssertNotNil(AppStrings.Settings.targetLevel)
        XCTAssertNotNil(AppStrings.Settings.appLanguage)
        XCTAssertNotNil(AppStrings.Settings.langSystem)
        XCTAssertNotNil(AppStrings.Settings.langVietnamese)
        XCTAssertNotNil(AppStrings.Settings.langEnglish)
        XCTAssertNotNil(AppStrings.Settings.dailyGoal)
        XCTAssertNotNil(AppStrings.Settings.reminders)
        XCTAssertNotNil(AppStrings.Settings.reminderTime)
        XCTAssertNotNil(AppStrings.Settings.resetSRS)
        XCTAssertNotNil(AppStrings.Settings.resetSRSSubtitle)
        XCTAssertNotNil(AppStrings.Settings.resetConfirmTitle)
        XCTAssertNotNil(AppStrings.Settings.resetConfirmMessage)
        XCTAssertNotNil(AppStrings.Settings.sectionAudio)
        XCTAssertNotNil(AppStrings.Settings.audioAccent)
        XCTAssertNotNil(AppStrings.Settings.accentUS)
        XCTAssertNotNil(AppStrings.Settings.accentUK)
        XCTAssertNotNil(AppStrings.Settings.speechSpeed)
        XCTAssertNotNil(AppStrings.Settings.testTTS)
        XCTAssertNotNil(AppStrings.Settings.playingPreview)
        XCTAssertNotNil(AppStrings.Settings.sectionAppearance)
        XCTAssertNotNil(AppStrings.Settings.appearanceMode)
        XCTAssertNotNil(AppStrings.Settings.themeDark)
        XCTAssertNotNil(AppStrings.Settings.themeLight)
        XCTAssertNotNil(AppStrings.Settings.themeSystem)
        XCTAssertNotNil(AppStrings.Settings.haptics)
        XCTAssertNotNil(AppStrings.Settings.soundEffects)
        XCTAssertNotNil(AppStrings.Settings.sectionDevTools)
        XCTAssertNotNil(AppStrings.Settings.themePreset)
        XCTAssertNotNil(AppStrings.Settings.craftCatalog)
        XCTAssertNotNil(AppStrings.Settings.craftCatalogSubtitle)
        XCTAssertNotNil(AppStrings.Settings.sectionAbout)
        XCTAssertNotNil(AppStrings.Settings.icloudSync)
        XCTAssertNotNil(AppStrings.Settings.synced)
        XCTAssertNotNil(AppStrings.Settings.clearCache)
        XCTAssertNotNil(AppStrings.Settings.appVersion)

        // Profile Strings
        XCTAssertEqual(AppStrings.Profile.titleText, "Profile & Achievements")
        XCTAssertEqual(AppStrings.Profile.wordsLearnedText, "Words Learned")
        XCTAssertEqual(AppStrings.Profile.reflexAccuracyText, "Reflex Accuracy")
        XCTAssertEqual(AppStrings.Profile.avgSpeedText, "Avg Speed")
        XCTAssertEqual(AppStrings.Profile.streakDaysText, "Streak Days")
        XCTAssertEqual(AppStrings.Profile.cefrMasteryText, "Oxford CEFR Mastery")
        XCTAssertEqual(AppStrings.Profile.achievementsText, "Badges & Achievements")
        XCTAssertEqual(AppStrings.Profile.badgeReflexMasterText, "Reflex Master")
        XCTAssertEqual(AppStrings.Profile.badgeStreakBlazeText, "14-Day Blaze")
        XCTAssertEqual(AppStrings.Profile.badgeOxfordPioneerText, "Oxford Pioneer")

        XCTAssertNotNil(AppStrings.Profile.title)
        XCTAssertNotNil(AppStrings.Profile.wordsLearned)
        XCTAssertNotNil(AppStrings.Profile.reflexAccuracy)
        XCTAssertNotNil(AppStrings.Profile.avgSpeed)
        XCTAssertNotNil(AppStrings.Profile.streakDays)
        XCTAssertNotNil(AppStrings.Profile.cefrMastery)
        XCTAssertNotNil(AppStrings.Profile.achievements)
        XCTAssertNotNil(AppStrings.Profile.badgeReflexMaster)
        XCTAssertNotNil(AppStrings.Profile.badgeStreakBlaze)
        XCTAssertNotNil(AppStrings.Profile.badgeOxfordPioneer)
    }
}
