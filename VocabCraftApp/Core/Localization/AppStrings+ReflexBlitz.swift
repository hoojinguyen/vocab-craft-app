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
            String(localized: "app.reflex.hub.title", defaultValue: "Speed Reflex Practice", bundle: .module)
        }
        public static var hubSubtitle: LocalizedStringKey { "app.reflex.hub.subtitle" }
        public static var hubSubtitleText: String {
            String(localized: "app.reflex.hub.subtitle", defaultValue: "Choose your reflex method today", bundle: .module)
        }
        public static var hubStatsTitle: LocalizedStringKey { "app.reflex.hub.stats_title" }
        public static var hubStatsTitleText: String {
            String(localized: "app.reflex.hub.stats_title", defaultValue: "Reflex Statistics", bundle: .module)
        }
        public static func weeklyWords(_ count: Int) -> String {
            String(format: String(localized: "app.reflex.stats.weekly_words", defaultValue: "%lld words practiced", bundle: .module), count)
        }
        public static func weakWords(_ count: Int) -> String {
            String(format: String(localized: "app.reflex.stats.weak_words", defaultValue: "%lld words to review", bundle: .module), count)
        }
        public static var avgSpeedLabel: LocalizedStringKey { "app.reflex.stats.avg_speed" }
        public static var avgSpeedLabelText: String {
            String(localized: "app.reflex.stats.avg_speed", defaultValue: "Avg Speed", bundle: .module)
        }
        public static var hubFooterHint: LocalizedStringKey { "app.reflex.hub.footer_hint" }
        public static var hubFooterHintText: String {
            String(localized: "app.reflex.hub.footer_hint", defaultValue: "Each word has an individual countdown limit to build unconditional reflex.", bundle: .module)
        }

        // Modalities
        public static var speakingTitle: LocalizedStringKey { "app.reflex.mode.speaking.title" }
        public static var speakingTitleText: String {
            String(localized: "app.reflex.mode.speaking.title", defaultValue: "Speaking Practice", bundle: .module)
        }
        public static var speakingSubtitle: LocalizedStringKey { "app.reflex.mode.speaking.subtitle" }
        public static var speakingSubtitleText: String {
            String(localized: "app.reflex.mode.speaking.subtitle", defaultValue: "Pronunciation & speech recognition reflex", bundle: .module)
        }
        public static var speakingInstruction: LocalizedStringKey { "app.reflex.mode.speaking.instruction" }
        public static var speakingInstructionText: String {
            String(localized: "app.reflex.mode.speaking.instruction", defaultValue: "Ready to speak loudly & clearly", bundle: .module)
        }

        public static var typingTitle: LocalizedStringKey { "app.reflex.mode.typing.title" }
        public static var typingTitleText: String {
            String(localized: "app.reflex.mode.typing.title", defaultValue: "Typing", bundle: .module)
        }
        public static var typingSubtitle: LocalizedStringKey { "app.reflex.mode.typing.subtitle" }
        public static var typingSubtitleText: String {
            String(localized: "app.reflex.mode.typing.subtitle", defaultValue: "Keying & spelling reflex", bundle: .module)
        }
        public static var typingInstruction: LocalizedStringKey { "app.reflex.mode.typing.instruction" }
        public static var typingInstructionText: String {
            String(localized: "app.reflex.mode.typing.instruction", defaultValue: "Place fingers & prepare to type quickly", bundle: .module)
        }

        public static var mcTitle: LocalizedStringKey { "app.reflex.mode.mc.title" }
        public static var mcTitleText: String {
            String(localized: "app.reflex.mode.mc.title", defaultValue: "Multiple Choice", bundle: .module)
        }
        public static var mcSubtitle: LocalizedStringKey { "app.reflex.mode.mc.subtitle" }
        public static var mcSubtitleText: String {
            String(localized: "app.reflex.mode.mc.subtitle", defaultValue: "Recognize 1 out of 4 options", bundle: .module)
        }
        public static var mcInstruction: LocalizedStringKey { "app.reflex.mode.mc.instruction" }
        public static var mcInstructionText: String {
            String(localized: "app.reflex.mode.mc.instruction", defaultValue: "Observe quickly & select the correct answer", bundle: .module)
        }

        public static var listeningTitle: LocalizedStringKey { "app.reflex.mode.listening.title" }
        public static var listeningTitleText: String {
            String(localized: "app.reflex.mode.listening.title", defaultValue: "Listening Reflex", bundle: .module)
        }
        public static var listeningSubtitle: LocalizedStringKey { "app.reflex.mode.listening.subtitle" }
        public static var listeningSubtitleText: String {
            String(localized: "app.reflex.mode.listening.subtitle", defaultValue: "Catch audio & translate instantly", bundle: .module)
        }
        public static var listeningModeInstruction: LocalizedStringKey { "app.reflex.mode.listening.instruction" }
        public static var listeningModeInstructionText: String {
            String(localized: "app.reflex.mode.listening.instruction", defaultValue: "Listen carefully & pick the correct meaning", bundle: .module)
        }

        // Drill
        public static var skip: LocalizedStringKey { "app.reflex.drill.skip" }
        public static var skipText: String {
            String(localized: "app.reflex.drill.skip", defaultValue: "Skip", bundle: .module)
        }
        public static var typingPlaceholder: LocalizedStringKey { "app.reflex.drill.typing_placeholder" }
        public static var typingPlaceholderText: String {
            String(localized: "app.reflex.drill.typing_placeholder", defaultValue: "Type your answer...", bundle: .module)
        }
        public static func typingEnteredPrefix(_ text: String) -> String {
            String(format: String(localized: "app.reflex.drill.typing_entered", defaultValue: "Entered: \"%@\"", bundle: .module), text)
        }
        public static func typingYouTypedPrefix(_ text: String) -> String {
            String(format: String(localized: "app.reflex.drill.typing_you_typed", defaultValue: "You entered: \"%@\"", bundle: .module), text)
        }
        public static var listeningInstruction: LocalizedStringKey { "app.reflex.listening.instruction" }
        public static var listeningInstructionText: String {
            String(localized: "app.reflex.listening.instruction", defaultValue: "Listen and choose the correct meaning", bundle: .module)
        }
        public static var listeningReplay: LocalizedStringKey { "app.reflex.drill.listening_replay" }
        public static var listeningReplayText: String {
            String(localized: "app.reflex.drill.listening_replay", defaultValue: "Replay Audio", bundle: .module)
        }
        public static var listeningReplayA11y: String {
            String(localized: "app.reflex.listening.replay_a11y", defaultValue: "Replay word pronunciation", bundle: .module)
        }
        public static var listeningWaveformA11y: String {
            String(localized: "app.reflex.listening.waveform_a11y", defaultValue: "Pronunciation waveform visualizer", bundle: .module)
        }
        public static var speakingListening: LocalizedStringKey { "app.reflex.drill.speaking_listening" }
        public static var speakingListeningText: String {
            String(localized: "app.reflex.drill.speaking_listening", defaultValue: "Listening to pronunciation...", bundle: .module)
        }

        public static var exitDialogTitle: LocalizedStringKey { "app.reflex.drill.exit_title" }
        public static var exitDialogTitleText: String {
            String(localized: "app.reflex.drill.exit_title", defaultValue: "Exit drill session?", bundle: .module)
        }
        public static var exitDialogCancel: LocalizedStringKey { "app.reflex.drill.exit_cancel" }
        public static var exitDialogCancelText: String {
            String(localized: "app.reflex.drill.exit_cancel", defaultValue: "Continue Practice", bundle: .module)
        }
        public static var exitDialogConfirm: LocalizedStringKey { "app.reflex.drill.exit_confirm" }
        public static var exitDialogConfirmText: String {
            String(localized: "app.reflex.drill.exit_confirm", defaultValue: "Exit", bundle: .module)
        }
        public static var exitDialogMessage: LocalizedStringKey { "app.reflex.drill.exit_message" }
        public static var exitDialogMessageText: String {
            String(localized: "app.reflex.drill.exit_message", defaultValue: "Progress for uncompleted words will not be saved in this session.", bundle: .module)
        }
        public static var exitA11y: LocalizedStringKey { "app.reflex.drill.exit_a11y" }
        public static var exitA11yText: String {
            String(localized: "app.reflex.drill.exit_a11y", defaultValue: "Exit practice session", bundle: .module)
        }
        public static var continueCTA: LocalizedStringKey { "app.reflex.drill.continue_cta" }
        public static var continueCTAText: String {
            String(localized: "app.reflex.drill.continue_cta", defaultValue: "Continue", bundle: .module)
        }
        public static var correctTitle: LocalizedStringKey { "app.reflex.drill.correct_title" }
        public static var correctTitleText: String {
            String(localized: "app.reflex.drill.correct_title", defaultValue: "Correct!", bundle: .module)
        }
        public static var timeoutTitle: LocalizedStringKey { "app.reflex.drill.timeout_title" }
        public static var timeoutTitleText: String {
            String(localized: "app.reflex.drill.timeout_title", defaultValue: "Time's up!", bundle: .module)
        }
        public static var incorrectTitle: LocalizedStringKey { "app.reflex.drill.incorrect_title" }
        public static var incorrectTitleText: String {
            String(localized: "app.reflex.drill.incorrect_title", defaultValue: "Incorrect", bundle: .module)
        }
        public static func definitionA11y(_ definition: String) -> String {
            String(format: String(localized: "app.reflex.drill.definition_a11y", defaultValue: "Definition: %@", bundle: .module), definition)
        }
        public static func completedSentenceA11y(_ sentence: String) -> String {
            String(format: String(localized: "app.reflex.drill.completed_sentence_a11y", defaultValue: "Completed sentence: %@", bundle: .module), sentence)
        }
        public static func clozeSentenceA11y(_ sentence: String) -> String {
            String(format: String(localized: "app.reflex.drill.cloze_sentence_a11y", defaultValue: "Fill-in sentence: %@", bundle: .module), sentence)
        }
        public static func ipaA11y(_ ipa: String) -> String {
            String(format: String(localized: "app.reflex.drill.ipa_a11y", defaultValue: "IPA phonetic: %@", bundle: .module), ipa)
        }
        public static func hintPrefix(_ hint: String) -> String {
            String(format: String(localized: "app.reflex.drill.hint_prefix", defaultValue: "Hint: %@", bundle: .module), hint)
        }
        public static func hintA11y(_ hint: String) -> String {
            String(format: String(localized: "app.reflex.drill.hint_a11y", defaultValue: "First letter hint: %@", bundle: .module), hint)
        }
        public static func optionA11y(prefix: String, text: String) -> String {
            String(format: String(localized: "app.reflex.drill.option_a11y", defaultValue: "Option %@: %@", bundle: .module), prefix, text)
        }
        public static var typingInputA11y: String {
            String(localized: "app.reflex.drill.typing_input_a11y", defaultValue: "English text field", bundle: .module)
        }
        public static var typingSubmitA11y: String {
            String(localized: "app.reflex.drill.typing_submit_a11y", defaultValue: "Submit typed answer", bundle: .module)
        }
        public static func selectedPrefix(_ text: String) -> String {
            String(format: String(localized: "app.reflex.drill.selected_prefix", defaultValue: "Selected: %@", bundle: .module), text)
        }
        public static func spokenRecognized(_ text: String) -> String {
            String(format: String(localized: "app.reflex.drill.spoken_recognized", defaultValue: "Recognized: %@", bundle: .module), text)
        }
        public static func typedAnswer(_ text: String) -> String {
            String(format: String(localized: "app.reflex.drill.typed_answer", defaultValue: "Entered: %@", bundle: .module), text)
        }
        public static var speechWaitingA11y: String {
            String(localized: "app.reflex.drill.speech_waiting_a11y", defaultValue: "Waiting for speech...", bundle: .module)
        }
        public static func speechRecognizedA11y(_ transcript: String) -> String {
            String(format: String(localized: "app.reflex.drill.speech_recognized_a11y", defaultValue: "Speech recognized: %@", bundle: .module), transcript)
        }
        public static var advanceTimeoutA11y: String {
            String(localized: "app.reflex.drill.advance_timeout_a11y", defaultValue: "Time's up. Tap to advance", bundle: .module)
        }
        public static func advanceCorrectA11y(_ time: String) -> String {
            String(format: String(localized: "app.reflex.drill.advance_correct_a11y", defaultValue: "Correct, reflex %@. Tap to advance", bundle: .module), time)
        }
        public static func advanceIncorrectA11y(_ time: String) -> String {
            String(format: String(localized: "app.reflex.drill.advance_incorrect_a11y", defaultValue: "Incorrect, time %@. Tap to advance", bundle: .module), time)
        }
        public static var advanceHintA11y: String {
            String(localized: "app.reflex.drill.advance_hint_a11y", defaultValue: "Tap to advance to next word", bundle: .module)
        }
        public static var advanceTimeoutButton: String {
            String(localized: "app.reflex.drill.advance_timeout_button", defaultValue: "⚠️ Time's up • Next ➔", bundle: .module)
        }
        public static func advanceCorrectButton(_ time: String) -> String {
            String(format: String(localized: "app.reflex.drill.advance_correct_button", defaultValue: "⚡️ %@ • Next ➔", bundle: .module), time)
        }
        public static func advanceIncorrectButton(_ time: String) -> String {
            String(format: String(localized: "app.reflex.drill.advance_incorrect_button", defaultValue: "%@ • Next ➔", bundle: .module), time)
        }

        // Summary
        public static var summaryTitle: LocalizedStringKey { "app.reflex.summary.title" }
        public static var summaryTitleText: String {
            String(localized: "app.reflex.summary.title", defaultValue: "Reflex Blitz Complete", bundle: .module)
        }
        public static var redrillWeak: LocalizedStringKey { "app.reflex.summary.redrill_weak" }
        public static var redrillWeakText: String {
            String(localized: "app.reflex.summary.redrill_weak", defaultValue: "Drill Weak Words", bundle: .module)
        }
        public static func redrillWeak(_ count: Int) -> String {
            redrillWeakText
        }
        public static var finishSave: LocalizedStringKey { "app.reflex.summary.finish_save" }
        public static var finishSaveText: String {
            String(localized: "app.reflex.summary.finish_save", defaultValue: "Done", bundle: .module)
        }
        public static var perfectTitle: LocalizedStringKey { "app.reflex.summary.perfect_title" }
        public static var perfectTitleText: String {
            String(localized: "app.reflex.summary.perfect_title", defaultValue: "Flawless Reflex!", bundle: .module)
        }
        public static var perfectDesc: LocalizedStringKey { "app.reflex.summary.perfect_desc" }
        public static var perfectDescText: String {
            String(localized: "app.reflex.summary.perfect_desc", defaultValue: "You responded accurately and swiftly across all words.", bundle: .module)
        }
        public static var summaryAvgSpeed: LocalizedStringKey { "app.reflex.summary.avg_speed" }
        public static var summaryAvgSpeedText: String {
            String(localized: "app.reflex.summary.avg_speed", defaultValue: "Avg Speed", bundle: .module)
        }
        public static var summaryAccuracy: LocalizedStringKey { "app.reflex.summary.accuracy" }
        public static var summaryAccuracyText: String {
            String(localized: "app.reflex.summary.accuracy", defaultValue: "Accuracy", bundle: .module)
        }
        public static var summaryMaxCombo: LocalizedStringKey { "app.reflex.summary.max_combo" }
        public static var summaryMaxComboText: String {
            String(localized: "app.reflex.summary.max_combo", defaultValue: "Max Combo", bundle: .module)
        }
        public static var weakWordsHeader: LocalizedStringKey { "app.reflex.summary.weak_words_header" }
        public static var weakWordsHeaderText: String {
            String(localized: "app.reflex.summary.weak_words_header", defaultValue: "Words to Reinforce", bundle: .module)
        }
        public static func weakWordsHeader(_ count: Int) -> String {
            weakWordsHeaderText
        }
        public static var statusIncorrect: String {
            String(localized: "app.reflex.summary.status_incorrect", defaultValue: "Incorrect", bundle: .module)
        }
        public static func statusSlow(_ time: String) -> String {
            String(format: String(localized: "app.reflex.summary.status_slow", defaultValue: "%@ • Too slow", bundle: .module), time)
        }
        public static func wordPosA11y(lemma: String, pos: String) -> String {
            String(format: String(localized: "app.reflex.summary.word_pos_a11y", defaultValue: "%@, %@", bundle: .module), lemma, pos)
        }
        public static func localizedRatingTitle(for speedRating: String) -> String {
            if speedRating.contains("Master") {
                return String(localized: "app.reflex.summary.rating_master", defaultValue: "Reflex Master", bundle: .module)
            } else if speedRating.contains("Swift") {
                return String(localized: "app.reflex.summary.rating_swift", defaultValue: "Swift Reflex", bundle: .module)
            } else {
                return String(localized: "app.reflex.summary.rating_steady", defaultValue: "Steady Learner", bundle: .module)
            }
        }
    }
}
