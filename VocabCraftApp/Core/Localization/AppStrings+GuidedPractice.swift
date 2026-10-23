import SwiftUI

// MARK: - Guided Communication Practice Localization Extension
extension AppStrings {
    public enum GuidedPractice {
        // MARK: - Hub Strings

        public static var hubTitle: LocalizedStringKey { "app.ai_assistant.guided.hub.title" }
        public static var hubTitleText: String {
            String(localized: "app.ai_assistant.guided.hub.title", defaultValue: "Guided Communication", bundle: .module)
        }

        public static var hubSubtitle: LocalizedStringKey { "app.ai_assistant.guided.hub.subtitle" }
        public static var hubSubtitleText: String {
            String(localized: "app.ai_assistant.guided.hub.subtitle", defaultValue: "Practice conversational reflexes with an AI assistant in realistic scenarios", bundle: .module)
        }

        public static var hubResumeTitle: LocalizedStringKey { "app.ai_assistant.guided.hub.resume_title" }
        public static var hubResumeTitleText: String {
            String(localized: "app.ai_assistant.guided.hub.resume_title", defaultValue: "Continue Practice Session", bundle: .module)
        }

        public static var hubResumeSubtitle: LocalizedStringKey { "app.ai_assistant.guided.hub.resume_subtitle" }
        public static var hubResumeSubtitleText: String {
            String(localized: "app.ai_assistant.guided.hub.resume_subtitle", defaultValue: "You have an unfinished practice session", bundle: .module)
        }

        public static var hubResumeBadge: LocalizedStringKey { "app.ai_assistant.guided.hub.resume_badge" }
        public static var hubResumeBadgeText: String {
            String(localized: "app.ai_assistant.guided.hub.resume_badge", defaultValue: "In Progress", bundle: .module)
        }

        public static var hubRecommendedBadge: LocalizedStringKey { "app.ai_assistant.guided.hub.recommended_badge" }
        public static var hubRecommendedBadgeText: String {
            String(localized: "app.ai_assistant.guided.hub.recommended_badge", defaultValue: "Recommended", bundle: .module)
        }

        public static var hubOtherScenarios: LocalizedStringKey { "app.ai_assistant.guided.hub.other_scenarios" }
        public static var hubOtherScenariosText: String {
            String(localized: "app.ai_assistant.guided.hub.other_scenarios", defaultValue: "Other Scenarios", bundle: .module)
        }

        // MARK: - Empty States

        public static var emptyNeedsVocabTitle: LocalizedStringKey { "app.ai_assistant.guided.empty.needs_vocab_title" }
        public static var emptyNeedsVocabTitleText: String {
            String(localized: "app.ai_assistant.guided.empty.needs_vocab_title", defaultValue: "More Vocabulary Needed", bundle: .module)
        }

        public static var emptyNeedsVocabDesc: LocalizedStringKey { "app.ai_assistant.guided.empty.needs_vocab_desc" }
        public static var emptyNeedsVocabDescText: String {
            String(localized: "app.ai_assistant.guided.empty.needs_vocab_desc", defaultValue: "Learn at least 2 vocabulary words to unlock guided communication practice.", bundle: .module)
        }

        public static var emptyNeedsVocabCTA: LocalizedStringKey { "app.ai_assistant.guided.empty.needs_vocab_cta" }
        public static var emptyNeedsVocabCTAText: String {
            String(localized: "app.ai_assistant.guided.empty.needs_vocab_cta", defaultValue: "Go to Lessons", bundle: .module)
        }

        public static var emptyNoTemplateTitle: LocalizedStringKey { "app.ai_assistant.guided.empty.no_template_title" }
        public static var emptyNoTemplateTitleText: String {
            String(localized: "app.ai_assistant.guided.empty.no_template_title", defaultValue: "No Compatible Scenarios", bundle: .module)
        }

        public static var emptyNoTemplateDesc: LocalizedStringKey { "app.ai_assistant.guided.empty.no_template_desc" }
        public static var emptyNoTemplateDescText: String {
            String(localized: "app.ai_assistant.guided.empty.no_template_desc", defaultValue: "The words you have learned do not match any available scenario. Keep learning new words!", bundle: .module)
        }

        public static var emptyNoTemplateCTA: LocalizedStringKey { "app.ai_assistant.guided.empty.no_template_cta" }
        public static var emptyNoTemplateCTAText: String {
            String(localized: "app.ai_assistant.guided.empty.no_template_cta", defaultValue: "Explore Vocabulary", bundle: .module)
        }

        // MARK: - Errors

        public static var errorTitle: LocalizedStringKey { "app.ai_assistant.guided.error.title" }
        public static var errorTitleText: String {
            String(localized: "app.ai_assistant.guided.error.title", defaultValue: "Unable to Load Practice", bundle: .module)
        }

        public static var errorDesc: LocalizedStringKey { "app.ai_assistant.guided.error.desc" }
        public static var errorDescText: String {
            String(localized: "app.ai_assistant.guided.error.desc", defaultValue: "An error occurred while loading practice data. Please try again.", bundle: .module)
        }

        public static var errorRetry: LocalizedStringKey { "app.ai_assistant.guided.error.retry" }
        public static var errorRetryText: String {
            String(localized: "app.ai_assistant.guided.error.retry", defaultValue: "Try Again", bundle: .module)
        }

        // MARK: - Preparation Strings

        public static var preparationTitle: LocalizedStringKey { "app.ai_assistant.guided.preparation.title" }
        public static var preparationTitleText: String {
            String(localized: "app.ai_assistant.guided.preparation.title", defaultValue: "Practice Brief", bundle: .module)
        }

        public static func preparationYourRole(_ role: String) -> String {
            String(format: String(localized: "app.ai_assistant.guided.preparation.your_role", defaultValue: "Your role: %@", bundle: .module), role)
        }

        public static func preparationPartnerRole(_ role: String) -> String {
            String(format: String(localized: "app.ai_assistant.guided.preparation.partner_role", defaultValue: "Conversation partner: %@", bundle: .module), role)
        }

        public static var preparationObjectivesTitle: LocalizedStringKey { "app.ai_assistant.guided.preparation.objectives_title" }
        public static var preparationObjectivesTitleText: String {
            String(localized: "app.ai_assistant.guided.preparation.objectives_title", defaultValue: "Communication Objectives", bundle: .module)
        }

        // MARK: - Modes

        public static var modeVoiceTitle: LocalizedStringKey { "app.ai_assistant.guided.preparation.mode_voice_title" }
        public static var modeVoiceTitleText: String {
            String(localized: "app.ai_assistant.guided.preparation.mode_voice_title", defaultValue: "Voice Mode", bundle: .module)
        }

        public static var modeVoiceDesc: LocalizedStringKey { "app.ai_assistant.guided.preparation.mode_voice_desc" }
        public static var modeVoiceDescText: String {
            String(localized: "app.ai_assistant.guided.preparation.mode_voice_desc", defaultValue: "Practice pronunciation and immediate reflexes with speech", bundle: .module)
        }

        public static var modeTextTitle: LocalizedStringKey { "app.ai_assistant.guided.preparation.mode_text_title" }
        public static var modeTextTitleText: String {
            String(localized: "app.ai_assistant.guided.preparation.mode_text_title", defaultValue: "Text Mode", bundle: .module)
        }

        public static var modeTextDesc: LocalizedStringKey { "app.ai_assistant.guided.preparation.mode_text_desc" }
        public static var modeTextDescText: String {
            String(localized: "app.ai_assistant.guided.preparation.mode_text_desc", defaultValue: "Practice conversation by typing, ideal for quiet environments", bundle: .module)
        }

        // MARK: - Pre-lesson Word Review

        public static var reviewWordsFirst: LocalizedStringKey { "app.ai_assistant.guided.preparation.review_words_first" }
        public static var reviewWordsFirstText: String {
            String(localized: "app.ai_assistant.guided.preparation.review_words_first", defaultValue: "Review words first", bundle: .module)
        }

        public static var reviewWordsSheetTitle: LocalizedStringKey { "app.ai_assistant.guided.preparation.review_words_title" }
        public static var reviewWordsSheetTitleText: String {
            String(localized: "app.ai_assistant.guided.preparation.review_words_title", defaultValue: "Target Vocabulary", bundle: .module)
        }

        public static var reviewWordsDone: LocalizedStringKey { "app.ai_assistant.guided.preparation.review_words_done" }
        public static var reviewWordsDoneText: String {
            String(localized: "app.ai_assistant.guided.preparation.review_words_done", defaultValue: "Done", bundle: .module)
        }

        // MARK: - Start & Preflight

        public static var startPractice: LocalizedStringKey { "app.ai_assistant.guided.preparation.start_practice" }
        public static var startPracticeText: String {
            String(localized: "app.ai_assistant.guided.preparation.start_practice", defaultValue: "Start Practice", bundle: .module)
        }

        public static var voicePermissionRequired: LocalizedStringKey { "app.ai_assistant.guided.preparation.voice_permission_required" }
        public static var voicePermissionRequiredText: String {
            String(
                localized: "app.ai_assistant.guided.preparation.voice_permission_required",
                defaultValue: "Microphone permission is required for voice mode. You can enable it in Settings or switch to text mode.",
                bundle: .module
            )
        }

        public static var llmUnavailable: LocalizedStringKey { "app.ai_assistant.guided.preparation.llm_unavailable" }
        public static var llmUnavailableText: String {
            String(
                localized: "app.ai_assistant.guided.preparation.llm_unavailable",
                defaultValue: "The AI assistant is currently unavailable to generate dialogue. Please check your network connection and try again.",
                bundle: .module
            )
        }

        public static var switchToText: LocalizedStringKey { "app.ai_assistant.guided.preparation.switch_to_text" }
        public static var switchToTextText: String {
            String(localized: "app.ai_assistant.guided.preparation.switch_to_text", defaultValue: "Switch to Text", bundle: .module)
        }

        // MARK: - Objectives

        public static func objectiveTitle(for id: String) -> LocalizedStringKey {
            LocalizedStringKey("app.ai_assistant.guided.objective.\(id)")
        }

        public static func objectiveTitleText(for id: String) -> String {
            let key = "app.ai_assistant.guided.objective.\(id)"
            let fallback = id.replacingOccurrences(of: "_", with: " ").capitalized
            return Bundle.module.localizedString(forKey: key, value: fallback, table: nil)
        }
    }
}
