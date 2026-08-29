import SwiftUI

// MARK: - Reflex Blitz Tab Extension
extension AppStrings {
    public enum ReflexBlitz {
        // Hub
        public static var hubBadge: LocalizedStringKey { "app.reflex.hub.badge" }
        public static var hubBadgeText: String {
            String(localized: "app.reflex.hub.badge", defaultValue: "REFLEX BLITZ", bundle: .module)
        }
        public static var hubTitle: LocalizedStringKey { "app.reflex.hub.title" }
        public static var hubTitleText: String {
            String(localized: "app.reflex.hub.title", defaultValue: "Luyện phản xạ tốc độ", bundle: .module)
        }
        public static var hubSubtitle: LocalizedStringKey { "app.reflex.hub.subtitle" }
        public static var hubSubtitleText: String {
            String(localized: "app.reflex.hub.subtitle", defaultValue: "Chọn phương pháp phản xạ hôm nay", bundle: .module)
        }
        public static var hubStatsTitle: LocalizedStringKey { "app.reflex.hub.stats_title" }
        public static var hubStatsTitleText: String {
            String(localized: "app.reflex.hub.stats_title", defaultValue: "Thống kê phản xạ", bundle: .module)
        }
        public static func weeklyWords(_ count: Int) -> String {
            String(format: String(localized: "app.reflex.stats.weekly_words", defaultValue: "%lld từ đã luyện", bundle: .module), count)
        }
        public static func weakWords(_ count: Int) -> String {
            String(format: String(localized: "app.reflex.stats.weak_words", defaultValue: "%lld từ cần ôn", bundle: .module), count)
        }
        public static var avgSpeedLabel: LocalizedStringKey { "app.reflex.stats.avg_speed" }
        public static var avgSpeedLabelText: String {
            String(localized: "app.reflex.stats.avg_speed", defaultValue: "Tốc độ TB", bundle: .module)
        }
        public static var hubFooterHint: LocalizedStringKey { "app.reflex.hub.footer_hint" }
        public static var hubFooterHintText: String {
            String(localized: "app.reflex.hub.footer_hint", defaultValue: "Mỗi từ có giới hạn đếm ngược riêng biệt để tạo phản xạ vô điều kiện.", bundle: .module)
        }

        // Modalities
        public static var speakingTitle: LocalizedStringKey { "app.reflex.mode.speaking.title" }
        public static var speakingTitleText: String {
            String(localized: "app.reflex.mode.speaking.title", defaultValue: "Luyện nói", bundle: .module)
        }
        public static var speakingSubtitle: LocalizedStringKey { "app.reflex.mode.speaking.subtitle" }
        public static var speakingSubtitleText: String {
            String(localized: "app.reflex.mode.speaking.subtitle", defaultValue: "Phản xạ phát âm & nhận diện giọng nói", bundle: .module)
        }
        public static var speakingInstruction: LocalizedStringKey { "app.reflex.mode.speaking.instruction" }
        public static var speakingInstructionText: String {
            String(localized: "app.reflex.mode.speaking.instruction", defaultValue: "Sẵn sàng phát âm to & rõ ràng", bundle: .module)
        }

        public static var typingTitle: LocalizedStringKey { "app.reflex.mode.typing.title" }
        public static var typingTitleText: String {
            String(localized: "app.reflex.mode.typing.title", defaultValue: "Gõ từ", bundle: .module)
        }
        public static var typingSubtitle: LocalizedStringKey { "app.reflex.mode.typing.subtitle" }
        public static var typingSubtitleText: String {
            String(localized: "app.reflex.mode.typing.subtitle", defaultValue: "Phản xạ gõ phím & nhớ mặt chữ", bundle: .module)
        }
        public static var typingInstruction: LocalizedStringKey { "app.reflex.mode.typing.instruction" }
        public static var typingInstructionText: String {
            String(localized: "app.reflex.mode.typing.instruction", defaultValue: "Đặt tay lên phím & sẵn sàng gõ nhanh", bundle: .module)
        }

        public static var mcTitle: LocalizedStringKey { "app.reflex.mode.mc.title" }
        public static var mcTitleText: String {
            String(localized: "app.reflex.mode.mc.title", defaultValue: "Trắc nghiệm", bundle: .module)
        }
        public static var mcSubtitle: LocalizedStringKey { "app.reflex.mode.mc.subtitle" }
        public static var mcSubtitleText: String {
            String(localized: "app.reflex.mode.mc.subtitle", defaultValue: "Nhận diện từ vựng 1 trong 4", bundle: .module)
        }
        public static var mcInstruction: LocalizedStringKey { "app.reflex.mode.mc.instruction" }
        public static var mcInstructionText: String {
            String(localized: "app.reflex.mode.mc.instruction", defaultValue: "Quan sát nhanh & chọn đáp án chính xác", bundle: .module)
        }

        public static var listeningTitle: LocalizedStringKey { "app.reflex.mode.listening.title" }
        public static var listeningTitleText: String {
            String(localized: "app.reflex.mode.listening.title", defaultValue: "Phản xạ nghe", bundle: .module)
        }
        public static var listeningSubtitle: LocalizedStringKey { "app.reflex.mode.listening.subtitle" }
        public static var listeningSubtitleText: String {
            String(localized: "app.reflex.mode.listening.subtitle", defaultValue: "Bắt âm thanh & dịch nghĩa tức thì", bundle: .module)
        }
        public static var listeningModeInstruction: LocalizedStringKey { "app.reflex.mode.listening.instruction" }
        public static var listeningModeInstructionText: String {
            String(localized: "app.reflex.mode.listening.instruction", defaultValue: "Lắng nghe cẩn thận & chọn nghĩa chính xác", bundle: .module)
        }

        // Drill
        public static var skip: LocalizedStringKey { "app.reflex.drill.skip" }
        public static var skipText: String {
            String(localized: "app.reflex.drill.skip", defaultValue: "Bỏ qua", bundle: .module)
        }
        public static var typingPlaceholder: LocalizedStringKey { "app.reflex.drill.typing_placeholder" }
        public static var typingPlaceholderText: String {
            String(localized: "app.reflex.drill.typing_placeholder", defaultValue: "Gõ từ tiếng Anh...", bundle: .module)
        }
        public static var listeningInstruction: LocalizedStringKey { "app.reflex.drill.listening_instruction" }
        public static var listeningInstructionText: String {
            String(localized: "app.reflex.drill.listening_instruction", defaultValue: "Chọn nghĩa tiếng Việt của từ vừa nghe", bundle: .module)
        }
        public static var listeningReplay: LocalizedStringKey { "app.reflex.drill.listening_replay" }
        public static var listeningReplayText: String {
            String(localized: "app.reflex.drill.listening_replay", defaultValue: "Nghe lại phát âm", bundle: .module)
        }
        public static var speakingListening: LocalizedStringKey { "app.reflex.drill.speaking_listening" }
        public static var speakingListeningText: String {
            String(localized: "app.reflex.drill.speaking_listening", defaultValue: "Đang lắng nghe phát âm...", bundle: .module)
        }
        public static var switchToKeyboard: LocalizedStringKey { "app.reflex.drill.switch_to_keyboard" }
        public static var switchToKeyboardText: String {
            String(localized: "app.reflex.drill.switch_to_keyboard", defaultValue: "Chuyển sang gõ từ", bundle: .module)
        }
        public static var exitDialogTitle: LocalizedStringKey { "app.reflex.drill.exit_title" }
        public static var exitDialogTitleText: String {
            String(localized: "app.reflex.drill.exit_title", defaultValue: "Thoát bài luyện tập?", bundle: .module)
        }
        public static var exitDialogCancel: LocalizedStringKey { "app.reflex.drill.exit_cancel" }
        public static var exitDialogCancelText: String {
            String(localized: "app.reflex.drill.exit_cancel", defaultValue: "Tiếp tục luyện tập", bundle: .module)
        }
        public static var exitDialogConfirm: LocalizedStringKey { "app.reflex.drill.exit_confirm" }
        public static var exitDialogConfirmText: String {
            String(localized: "app.reflex.drill.exit_confirm", defaultValue: "Thoát", bundle: .module)
        }
        public static var exitDialogMessage: LocalizedStringKey { "app.reflex.drill.exit_message" }
        public static var exitDialogMessageText: String {
            String(localized: "app.reflex.drill.exit_message", defaultValue: "Tiến độ của các từ chưa hoàn thành sẽ không được lưu vào phiên này.", bundle: .module)
        }
        public static var exitA11y: LocalizedStringKey { "app.reflex.drill.exit_a11y" }
        public static var exitA11yText: String {
            String(localized: "app.reflex.drill.exit_a11y", defaultValue: "Thoát bài luyện tập", bundle: .module)
        }
        public static var continueCTA: LocalizedStringKey { "app.reflex.drill.continue_cta" }
        public static var continueCTAText: String {
            String(localized: "app.reflex.drill.continue_cta", defaultValue: "Tiếp tục", bundle: .module)
        }
        public static var correctTitle: LocalizedStringKey { "app.reflex.drill.correct_title" }
        public static var correctTitleText: String {
            String(localized: "app.reflex.drill.correct_title", defaultValue: "Chính xác!", bundle: .module)
        }
        public static var timeoutTitle: LocalizedStringKey { "app.reflex.drill.timeout_title" }
        public static var timeoutTitleText: String {
            String(localized: "app.reflex.drill.timeout_title", defaultValue: "Hết thời gian!", bundle: .module)
        }
        public static var incorrectTitle: LocalizedStringKey { "app.reflex.drill.incorrect_title" }
        public static var incorrectTitleText: String {
            String(localized: "app.reflex.drill.incorrect_title", defaultValue: "Chưa chính xác", bundle: .module)
        }
        public static func definitionA11y(_ definition: String) -> String {
            String(format: String(localized: "app.reflex.drill.definition_a11y", defaultValue: "Nghĩa tiếng Việt: %@", bundle: .module), definition)
        }
        public static func completedSentenceA11y(_ sentence: String) -> String {
            String(format: String(localized: "app.reflex.drill.completed_sentence_a11y", defaultValue: "Câu hoàn chỉnh: %@", bundle: .module), sentence)
        }
        public static func clozeSentenceA11y(_ sentence: String) -> String {
            String(format: String(localized: "app.reflex.drill.cloze_sentence_a11y", defaultValue: "Câu điền từ: %@", bundle: .module), sentence)
        }
        public static func ipaA11y(_ ipa: String) -> String {
            String(format: String(localized: "app.reflex.drill.ipa_a11y", defaultValue: "Phiên âm IPA: %@", bundle: .module), ipa)
        }
        public static func hintPrefix(_ hint: String) -> String {
            String(format: String(localized: "app.reflex.drill.hint_prefix", defaultValue: "Gợi ý: %@", bundle: .module), hint)
        }
        public static func hintA11y(_ hint: String) -> String {
            String(format: String(localized: "app.reflex.drill.hint_a11y", defaultValue: "Gợi ý ký tự đầu: %@", bundle: .module), hint)
        }
        public static func optionA11y(prefix: String, text: String) -> String {
            String(format: String(localized: "app.reflex.drill.option_a11y", defaultValue: "Lựa chọn %@: %@", bundle: .module), prefix, text)
        }
        public static var typingInputA11y: String {
            String(localized: "app.reflex.drill.typing_input_a11y", defaultValue: "Ô nhập từ tiếng Anh", bundle: .module)
        }
        public static var typingSubmitA11y: String {
            String(localized: "app.reflex.drill.typing_submit_a11y", defaultValue: "Gửi câu trả lời đã gõ", bundle: .module)
        }
        public static func selectedPrefix(_ text: String) -> String {
            String(format: String(localized: "app.reflex.drill.selected_prefix", defaultValue: "Đã chọn: %@", bundle: .module), text)
        }
        public static func spokenRecognized(_ text: String) -> String {
            String(format: String(localized: "app.reflex.drill.spoken_recognized", defaultValue: "Nhận diện: %@", bundle: .module), text)
        }
        public static func typedAnswer(_ text: String) -> String {
            String(format: String(localized: "app.reflex.drill.typed_answer", defaultValue: "Đã nhập: %@", bundle: .module), text)
        }
        public static var speechWaitingA11y: String {
            String(localized: "app.reflex.drill.speech_waiting_a11y", defaultValue: "Đang chờ phát âm...", bundle: .module)
        }
        public static func speechRecognizedA11y(_ transcript: String) -> String {
            String(format: String(localized: "app.reflex.drill.speech_recognized_a11y", defaultValue: "Nhận diện giọng nói: %@", bundle: .module), transcript)
        }
        public static var advanceTimeoutA11y: String {
            String(localized: "app.reflex.drill.advance_timeout_a11y", defaultValue: "Hết giờ. Nhấn để sang từ tiếp theo", bundle: .module)
        }
        public static func advanceCorrectA11y(_ time: String) -> String {
            String(format: String(localized: "app.reflex.drill.advance_correct_a11y", defaultValue: "Chính xác, phản xạ %@. Nhấn để sang từ tiếp theo", bundle: .module), time)
        }
        public static func advanceIncorrectA11y(_ time: String) -> String {
            String(format: String(localized: "app.reflex.drill.advance_incorrect_a11y", defaultValue: "Chưa chính xác, thời gian %@. Nhấn để sang từ tiếp theo", bundle: .module), time)
        }
        public static var advanceHintA11y: String {
            String(localized: "app.reflex.drill.advance_hint_a11y", defaultValue: "Nhấn để chuyển sang từ vựng tiếp theo", bundle: .module)
        }
        public static var advanceTimeoutButton: String {
            String(localized: "app.reflex.drill.advance_timeout_button", defaultValue: "⚠️ Hết giờ • Từ tiếp theo ➔", bundle: .module)
        }
        public static func advanceCorrectButton(_ time: String) -> String {
            String(format: String(localized: "app.reflex.drill.advance_correct_button", defaultValue: "⚡️ %@ • Từ tiếp theo ➔", bundle: .module), time)
        }
        public static func advanceIncorrectButton(_ time: String) -> String {
            String(format: String(localized: "app.reflex.drill.advance_incorrect_button", defaultValue: "%@ • Từ tiếp theo ➔", bundle: .module), time)
        }

        // Summary
        public static var summaryTitle: LocalizedStringKey { "app.reflex.summary.title" }
        public static var summaryTitleText: String {
            String(localized: "app.reflex.summary.title", defaultValue: "Hoàn thành phiên phản xạ Blitz", bundle: .module)
        }
        public static var redrillWeak: String {
            String(localized: "app.reflex.summary.redrill_weak", defaultValue: "Luyện lại từ yếu", bundle: .module)
        }
        public static func redrillWeak(_ count: Int) -> String {
            redrillWeak
        }
        public static var finishSave: LocalizedStringKey { "app.reflex.summary.finish_save" }
        public static var finishSaveText: String {
            String(localized: "app.reflex.summary.finish_save", defaultValue: "Hoàn tất", bundle: .module)
        }
        public static var perfectTitle: LocalizedStringKey { "app.reflex.summary.perfect_title" }
        public static var perfectTitleText: String {
            String(localized: "app.reflex.summary.perfect_title", defaultValue: "Phản xạ hoàn hảo!", bundle: .module)
        }
        public static var perfectDesc: LocalizedStringKey { "app.reflex.summary.perfect_desc" }
        public static var perfectDescText: String {
            String(localized: "app.reflex.summary.perfect_desc", defaultValue: "Bạn đã trả lời chính xác và nhanh chóng toàn bộ từ vựng.", bundle: .module)
        }
        public static var summaryAvgSpeed: LocalizedStringKey { "app.reflex.summary.avg_speed" }
        public static var summaryAvgSpeedText: String {
            String(localized: "app.reflex.summary.avg_speed", defaultValue: "Tốc độ TB", bundle: .module)
        }
        public static var summaryAccuracy: LocalizedStringKey { "app.reflex.summary.accuracy" }
        public static var summaryAccuracyText: String {
            String(localized: "app.reflex.summary.accuracy", defaultValue: "Độ chính xác", bundle: .module)
        }
        public static var summaryMaxCombo: LocalizedStringKey { "app.reflex.summary.max_combo" }
        public static var summaryMaxComboText: String {
            String(localized: "app.reflex.summary.max_combo", defaultValue: "Combo cao nhất", bundle: .module)
        }
        public static var weakWordsHeader: String {
            String(localized: "app.reflex.summary.weak_words_header", defaultValue: "Từ cần củng cố", bundle: .module)
        }
        public static func weakWordsHeader(_ count: Int) -> String {
            weakWordsHeader
        }
        public static var statusIncorrect: String {
            String(localized: "app.reflex.summary.status_incorrect", defaultValue: "Chưa chính xác", bundle: .module)
        }
        public static func statusSlow(_ time: String) -> String {
            String(format: String(localized: "app.reflex.summary.status_slow", defaultValue: "%@ • Quá chậm", bundle: .module), time)
        }
        public static func localizedRatingTitle(for speedRating: String) -> String {
            if speedRating.contains("Master") {
                return String(localized: "app.reflex.summary.rating_master", defaultValue: "Bậc thầy phản xạ", bundle: .module)
            } else if speedRating.contains("Swift") {
                return String(localized: "app.reflex.summary.rating_swift", defaultValue: "Phản xạ nhanh nhạy", bundle: .module)
            } else {
                return String(localized: "app.reflex.summary.rating_steady", defaultValue: "Người học kiên trì", bundle: .module)
            }
        }
    }
}
