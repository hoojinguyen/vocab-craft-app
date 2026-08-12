import SwiftUI
import Foundation

/// Centralized localization namespace for VocabCraftApp strings.
public enum AppStrings {
    
    // MARK: - Common Strings
    public enum Common {
        public static var ok: String { String(localized: "common.ok", defaultValue: "OK") }
        public static var cancel: String { String(localized: "common.cancel", defaultValue: "Hủy") }
        public static var save: String { String(localized: "common.save", defaultValue: "Lưu") }
        public static var reset: String { String(localized: "common.reset", defaultValue: "Reset") }
        public static var search: String { String(localized: "common.search", defaultValue: "Tìm kiếm") }
        public static var done: String { String(localized: "common.done", defaultValue: "Hoàn thành") }
        public static var back: String { String(localized: "common.back", defaultValue: "Quay lại") }
        public static var viewDetails: String { String(localized: "common.viewDetails", defaultValue: "Xem chi tiết") }
        public static var congratulations: String { String(localized: "common.congratulations", defaultValue: "Chúc mừng!") }
        public static var retry: String { String(localized: "common.retry", defaultValue: "Thử lại") }
        public static var close: String { String(localized: "common.close", defaultValue: "Đóng") }
        public static var wordUnit: String { String(localized: "common.wordUnit", defaultValue: "từ") }
    }
    
    // MARK: - Tab Bar Titles
    public enum Tabs {
        public static var home: String { String(localized: "tabs.home", defaultValue: "Trang chủ") }
        public static var vocabulary: String { String(localized: "tabs.vocabulary", defaultValue: "Kho từ") }
        public static var search: String { String(localized: "tabs.search", defaultValue: "Tra cứu") }
        public static var reflex: String { String(localized: "tabs.reflex", defaultValue: "Phản xạ") }
        public static var settings: String { String(localized: "tabs.settings", defaultValue: "Cài đặt") }
    }
    
    // MARK: - Homepage View
    public enum Homepage {
        public static var greeting: String { String(localized: "homepage.greeting", defaultValue: "Chào mừng trở lại!") }
        public static var streakDays: String { String(localized: "homepage.streakDays", defaultValue: "ngày chuỗi") }
        public static var dailyGoal: String { String(localized: "homepage.dailyGoal", defaultValue: "Mục tiêu hôm nay") }
        public static var suggestedWordsTitle: String { String(localized: "homepage.suggestedWordsTitle", defaultValue: "TỪ VỰNG GỢI Ý HÔM NAY") }
        public static var srsHeader: String { String(localized: "homepage.srsHeader", defaultValue: "TRÍ NHỚ DÀI HẠN (SRS)") }
        public static func srsRetentionMessage(_ percent: Int) -> String {
            String(localized: "\(percent)% từ đã đi vào bộ nhớ bền vững")
        }
        public static var reflexTitle: String { String(localized: "homepage.reflexTitle", defaultValue: "ÔN TẬP PHẢN XẠ") }
        public static func dueCardsSubtitle(_ count: Int) -> String {
            String(localized: "\(count) từ cần ôn")
        }
        public static var practiceNow: String { String(localized: "homepage.practiceNow", defaultValue: "LUYỆN NGAY") }
        public static var vocabLibraryTitle: String { String(localized: "homepage.vocabLibraryTitle", defaultValue: "KHO TỪ VỰNG") }
        public static var vocabLibrarySubtitle: String { String(localized: "homepage.vocabLibrarySubtitle", defaultValue: "Tất cả các bộ từ") }
        public static var explore: String { String(localized: "homepage.explore", defaultValue: "KHÁM PHÁ") }
        public static var cefrTitle: String { String(localized: "homepage.cefrTitle", defaultValue: "PHÂN BỔ TRÌNH ĐỘ CEFR") }
        public static var searchPlaceholder: String { String(localized: "homepage.searchPlaceholder", defaultValue: "Tra cứu từ mới...") }
        public static var newWordBadge: String { String(localized: "homepage.newWordBadge", defaultValue: "Từ mới") }
        public static var saved: String { String(localized: "homepage.saved", defaultValue: "Đã lưu") }
        public static var saveWord: String { String(localized: "homepage.saveWord", defaultValue: "Lưu từ") }
    }
    
    // MARK: - Vocabulary View
    public enum Vocabulary {
        public static var personalBank: String { String(localized: "vocabulary.personalBank", defaultValue: "Kho Từ Cá Nhân") }
        public static var topicDecks: String { String(localized: "vocabulary.topicDecks", defaultValue: "Bộ Từ Chủ Đề") }
        public static var searchPlaceholder: String { String(localized: "vocabulary.searchPlaceholder", defaultValue: "Tìm kiếm từ vựng, nghĩa...") }
        public static var filterAll: String { String(localized: "vocabulary.filterAll", defaultValue: "Tất cả") }
        public static var filterReviewNeeded: String { String(localized: "vocabulary.filterReviewNeeded", defaultValue: "Cần ôn tập") }
        public static var filterMastered: String { String(localized: "vocabulary.filterMastered", defaultValue: "Thành thạo") }
        public static var filterSaved: String { String(localized: "vocabulary.filterSaved", defaultValue: "Đã lưu") }
        public static var previewTopic: String { String(localized: "vocabulary.previewTopic", defaultValue: "Xem trước chủ đề") }
        public static var startLearning: String { String(localized: "vocabulary.startLearning", defaultValue: "Bắt đầu học ngay") }
        public static var wordCount: String { String(localized: "vocabulary.wordCount", defaultValue: "Số từ") }
        public static var level: String { String(localized: "vocabulary.level", defaultValue: "Trình độ") }
        public static var lessonCompleted: String { String(localized: "vocabulary.lessonCompleted", defaultValue: "Bạn đã hoàn thành bài học") }
        public static var wordsMasteredCount: String { String(localized: "vocabulary.wordsMasteredCount", defaultValue: "Số từ đã thuộc") }
        public static var studyAgain: String { String(localized: "vocabulary.studyAgain", defaultValue: "Học lại") }
        public static var backToHome: String { String(localized: "vocabulary.backToHome", defaultValue: "Về trang chủ") }
        public static var definition: String { String(localized: "vocabulary.definition", defaultValue: "Nghĩa") }
        public static var example: String { String(localized: "vocabulary.example", defaultValue: "Ví dụ") }
        public static var masteredBadge: String { String(localized: "vocabulary.masteredBadge", defaultValue: "Đã thuộc") }
        public static var reviewBadge: String { String(localized: "vocabulary.reviewBadge", defaultValue: "Cần ôn") }
    }
    
    // MARK: - Reflex Drill View
    public enum Reflex {
        public static var title: String { String(localized: "reflex.title", defaultValue: "LUYỆN PHẢN XẠ XUẤT QUỶ NHẬP THẦN") }
        public static var subtitle: String { String(localized: "reflex.subtitle", defaultValue: "Nói phản xạ hoặc chọn đáp án đúng trong thời gian ngắn nhất") }
        public static var startNow: String { String(localized: "reflex.startNow", defaultValue: "BẮT ĐẦU NGAY") }
        public static var holdToSpeak: String { String(localized: "reflex.holdToSpeak", defaultValue: "Giữ để nói...") }
        public static var listening: String { String(localized: "reflex.listening", defaultValue: "ĐANG LẮNG NGHE GIỌNG NÓI...") }
        public static var spokenAnswer: String { String(localized: "reflex.spokenAnswer", defaultValue: "ĐÁP ÁN BẠN NÓI") }
        public static var correct: String { String(localized: "reflex.correct", defaultValue: "Chính xác!") }
        public static var incorrect: String { String(localized: "reflex.incorrect", defaultValue: "Chưa chính xác") }
        public static var tapToFlip: String { String(localized: "reflex.tapToFlip", defaultValue: "Chạm để lật mặt sau") }
        public static var listenPronunciation: String { String(localized: "reflex.listenPronunciation", defaultValue: "Nghe phát âm") }
        public static var reflexStreakCompleted: String { String(localized: "reflex.reflexStreakCompleted", defaultValue: "Hoàn thành chuỗi phản xạ!") }
        public static var reflexAccuracy: String { String(localized: "reflex.reflexAccuracy", defaultValue: "Độ chính xác") }
        public static var continueNext: String { String(localized: "reflex.continueNext", defaultValue: "Tiếp tục bài tập tiếp theo") }
    }
    
    // MARK: - Settings View
    public enum Settings {
        public static var sectionLearningSRS: String { String(localized: "settings.sectionLearningSRS", defaultValue: "Học tập & Ôn tập (SRS)") }
        public static var sectionAudioTTS: String { String(localized: "settings.sectionAudioTTS", defaultValue: "Âm thanh & Phát âm") }
        public static var sectionAppearance: String { String(localized: "settings.sectionAppearance", defaultValue: "Giao diện & Trải nghiệm") }
        public static var sectionLanguage: String { String(localized: "settings.sectionLanguage", defaultValue: "Ngôn ngữ ứng dụng") }
        public static var sectionAppData: String { String(localized: "settings.sectionAppData", defaultValue: "Ứng dụng & Dữ liệu") }
        public static var dailyGoal: String { String(localized: "settings.dailyGoal", defaultValue: "Mục tiêu từ/ngày") }
        public static var reminderNotification: String { String(localized: "settings.reminderNotification", defaultValue: "Nhắc nhở ôn tập") }
        public static var reminderTime: String { String(localized: "settings.reminderTime", defaultValue: "Giờ nhắc nhở") }
        public static var resetSRS: String { String(localized: "settings.resetSRS", defaultValue: "Reset tiến trình SRS") }
        public static var resetSRSSubtitle: String { String(localized: "settings.resetSRSSubtitle", defaultValue: "Đặt lại tất cả các từ đã học") }
        public static var englishVoice: String { String(localized: "settings.englishVoice", defaultValue: "Giọng đọc tiếng Anh") }
        public static var speechSpeed: String { String(localized: "settings.speechSpeed", defaultValue: "Tốc độ đọc") }
        public static var testTTS: String { String(localized: "settings.testTTS", defaultValue: "Nghe thử phát âm TTS") }
        public static var playingAudio: String { String(localized: "settings.playingAudio", defaultValue: "Đang phát mẫu...") }
        public static var appTheme: String { String(localized: "settings.appTheme", defaultValue: "Giao diện App") }
        public static var themeDark: String { String(localized: "settings.themeDark", defaultValue: "Tối") }
        public static var themeLight: String { String(localized: "settings.themeLight", defaultValue: "Sáng") }
        public static var themeSystem: String { String(localized: "settings.themeSystem", defaultValue: "Hệ thống") }
        public static var haptics: String { String(localized: "settings.haptics", defaultValue: "Rung phản hồi (Haptics)") }
        public static var soundEffects: String { String(localized: "settings.soundEffects", defaultValue: "Hiệu ứng âm thanh") }
        public static var appLanguage: String { String(localized: "settings.appLanguage", defaultValue: "Ngôn ngữ giao diện") }
        public static var langSystem: String { String(localized: "settings.langSystem", defaultValue: "Theo hệ thống") }
        public static var langVietnamese: String { String(localized: "settings.langVietnamese", defaultValue: "Tiếng Việt") }
        public static var langEnglish: String { String(localized: "settings.langEnglish", defaultValue: "Tiếng Anh (English)") }
        public static var icloudSync: String { String(localized: "settings.icloudSync", defaultValue: "Đồng bộ iCloud") }
        public static var synced: String { String(localized: "settings.synced", defaultValue: "Đã đồng bộ") }
        public static var clearCache: String { String(localized: "settings.clearCache", defaultValue: "Dọn dẹp bộ nhớ đệm") }
        public static var appVersion: String { String(localized: "settings.appVersion", defaultValue: "Phiên bản ứng dụng") }
        public static var inputGoalTitle: String { String(localized: "settings.inputGoalTitle", defaultValue: "Nhập số lượng từ/ngày") }
        public static var inputGoalMessage: String { String(localized: "settings.inputGoalMessage", defaultValue: "Nhập số lượng từ mục tiêu cần học mỗi ngày từ 5 đến 100 từ.") }
        public static var resetConfirmTitle: String { String(localized: "settings.resetConfirmTitle", defaultValue: "Xác nhận Reset Tiến trình") }
        public static var resetConfirmMessage: String { String(localized: "settings.resetConfirmMessage", defaultValue: "Tất cả dữ liệu ôn tập SRS sẽ được đặt lại từ đầu. Hành động này không thể hoàn tác.") }
        public static var profileBadge: String { String(localized: "settings.profileBadge", defaultValue: "Học viên Chăm chỉ") }
    }
}
