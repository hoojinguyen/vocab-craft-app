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

        // MARK: - Session Controls & Interaction

        public static var sessionPause: LocalizedStringKey { "app.ai_assistant.guided.session.pause" }
        public static var sessionResume: LocalizedStringKey { "app.ai_assistant.guided.session.resume" }
        public static var sessionPausedBadge: LocalizedStringKey { "app.ai_assistant.guided.session.paused_badge" }
        public static var sessionPausedBadgeText: String {
            String(localized: "app.ai_assistant.guided.session.paused_badge", defaultValue: "Paused", bundle: .module)
        }
        public static var sessionPausedMessage: LocalizedStringKey { "app.ai_assistant.guided.session.paused_message" }
        public static var sessionCloseTitle: LocalizedStringKey { "app.ai_assistant.guided.session.close_title" }
        public static var sessionCloseMessage: LocalizedStringKey { "app.ai_assistant.guided.session.close_message" }
        public static var sessionCloseConfirm: LocalizedStringKey { "app.ai_assistant.guided.session.close_confirm" }
        public static var sessionCloseCancel: LocalizedStringKey { "app.ai_assistant.guided.session.close_cancel" }
        public static var sessionListening: LocalizedStringKey { "app.ai_assistant.guided.session.listening" }
        public static var sessionProcessing: LocalizedStringKey { "app.ai_assistant.guided.session.processing" }
        public static var sessionProcessingText: String {
            String(localized: "app.ai_assistant.guided.session.processing", defaultValue: "Processing response...", bundle: .module)
        }
        public static var sessionTapToSpeak: LocalizedStringKey { "app.ai_assistant.guided.session.tap_to_speak" }
        public static var sessionTapToSpeakText: String {
            String(localized: "app.ai_assistant.guided.session.tap_to_speak", defaultValue: "Tap to speak", bundle: .module)
        }
        public static var sessionTapToFinish: LocalizedStringKey { "app.ai_assistant.guided.session.tap_to_finish" }
        public static var sessionTapToFinishText: String {
            String(localized: "app.ai_assistant.guided.session.tap_to_finish", defaultValue: "Tap to finish", bundle: .module)
        }
        public static var sessionInputPlaceholder: LocalizedStringKey { "app.ai_assistant.guided.session.input_placeholder" }
        public static var sessionSend: LocalizedStringKey { "app.ai_assistant.guided.session.send" }
        public static var sessionReplayAudio: LocalizedStringKey { "app.ai_assistant.guided.session.replay_audio" }
        public static var sessionEditTranscript: LocalizedStringKey { "app.ai_assistant.guided.session.edit_transcript" }
        public static var sessionEditTranscriptTitle: LocalizedStringKey { "app.ai_assistant.guided.session.edit_transcript_title" }
        public static var sessionEditTranscriptSave: LocalizedStringKey { "app.ai_assistant.guided.session.edit_transcript_save" }
        public static var sessionEditTranscriptCancel: LocalizedStringKey { "app.ai_assistant.guided.session.edit_transcript_cancel" }
        public static var sessionCoachNote: LocalizedStringKey { "app.ai_assistant.guided.session.coach_feedback_title" }

        // MARK: - Scaffolding & Assistance

        public static var scaffoldingDrawerTitle: LocalizedStringKey { "app.ai_assistant.guided.scaffolding.drawer_title" }
        public static var helpButton: LocalizedStringKey { "app.ai_assistant.guided.scaffolding.help_button" }
        public static var fullModelButton: LocalizedStringKey { "app.ai_assistant.guided.scaffolding.full_model_button" }
        public static var retryLessSupport: LocalizedStringKey { "app.ai_assistant.guided.scaffolding.retry_less_support" }
        public static var supportNone: LocalizedStringKey { "app.ai_assistant.guided.scaffolding.level_none" }
        public static var supportIntent: LocalizedStringKey { "app.ai_assistant.guided.scaffolding.level_intent" }
        public static var supportLexical: LocalizedStringKey { "app.ai_assistant.guided.scaffolding.level_lexical" }
        public static var supportFrame: LocalizedStringKey { "app.ai_assistant.guided.scaffolding.level_frame" }
        public static var supportModel: LocalizedStringKey { "app.ai_assistant.guided.scaffolding.level_model" }

        // MARK: - Summary & Retrospective

        public static var summaryTitle: LocalizedStringKey { "app.ai_assistant.guided.summary.title" }
        public static var summarySubtitle: LocalizedStringKey { "app.ai_assistant.guided.summary.subtitle" }
        public static var summaryUnsavedBadge: LocalizedStringKey { "app.ai_assistant.guided.summary.unsaved_badge" }
        public static var summaryUnsavedMessage: LocalizedStringKey { "app.ai_assistant.guided.summary.unsaved_message" }
        public static var summaryObjectivesTitle: LocalizedStringKey { "app.ai_assistant.guided.summary.objectives_title" }
        public static var summaryEvidenceTitle: LocalizedStringKey { "app.ai_assistant.guided.summary.evidence_title" }
        public static var summaryEmptyEvidence: LocalizedStringKey { "app.ai_assistant.guided.summary.empty_evidence" }
        public static var summaryContinue: LocalizedStringKey { "app.ai_assistant.guided.summary.continue" }
        public static var summaryDeleteSession: LocalizedStringKey { "app.ai_assistant.guided.summary.delete_session" }
        public static var summaryDeleteConfirmTitle: LocalizedStringKey { "app.ai_assistant.guided.summary.delete_confirm_title" }
        public static var summaryDeleteConfirmMessage: LocalizedStringKey { "app.ai_assistant.guided.summary.delete_confirm_message" }
        public static var summaryDeleteConfirmAction: LocalizedStringKey { "app.ai_assistant.guided.summary.delete_confirm_action" }
        public static var summaryStatusCompleted: LocalizedStringKey { "app.ai_assistant.guided.summary.status_completed" }
        public static var summaryStatusPartial: LocalizedStringKey { "app.ai_assistant.guided.summary.status_partial" }

        // MARK: - Verdicts & Badges

        public static var statusAchieved: LocalizedStringKey { "app.ai_assistant.guided.status.achieved" }
        public static var statusNotYet: LocalizedStringKey { "app.ai_assistant.guided.status.not_yet" }
        public static var statusNotObserved: LocalizedStringKey { "app.ai_assistant.guided.status.not_observed" }

        // MARK: - Input Modes

        public static var modeVoice: LocalizedStringKey { "app.ai_assistant.guided.mode.voice" }
        public static var modeTyped: LocalizedStringKey { "app.ai_assistant.guided.mode.typed" }
        public static var modeEdited: LocalizedStringKey { "app.ai_assistant.guided.mode.edited" }

        // MARK: - Support Status

        public static var supportPrimed: LocalizedStringKey { "app.ai_assistant.guided.support.primed" }
        public static var supportIndependent: LocalizedStringKey { "app.ai_assistant.guided.support.independent" }

        // MARK: - Context Family

        public static var contextDining: LocalizedStringKey { "app.ai_assistant.guided.context.dining" }
        public static var contextShopping: LocalizedStringKey { "app.ai_assistant.guided.context.shopping" }
        public static var contextPlanning: LocalizedStringKey { "app.ai_assistant.guided.context.planning" }
        public static var contextSocial: LocalizedStringKey { "app.ai_assistant.guided.context.social" }
        public static var contextTravel: LocalizedStringKey { "app.ai_assistant.guided.context.travel" }
        public static var contextWork: LocalizedStringKey { "app.ai_assistant.guided.context.work" }

        // MARK: - Word Label Helper

        public static func wordLabel(for wordId: Int64) -> LocalizedStringKey {
            LocalizedStringKey("app.ai_assistant.guided.word.format \(wordId)")
        }
    }
}
