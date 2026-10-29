import SwiftUI

extension AppStrings {
    public enum Speaking {
        public static var hubTitle: LocalizedStringKey { "app.speaking.hub.title" }
        public static var hubTitleText: String { String(localized: "app.speaking.hub.title", defaultValue: "Speaking", bundle: .module) }
        public static var hubSubtitle: LocalizedStringKey { "app.speaking.hub.subtitle" }
        public static var hubSubtitleText: String { String(localized: "app.speaking.hub.subtitle", defaultValue: "Practice real conversations with AI.", bundle: .module) }
        public static var hubScenarios: LocalizedStringKey { "app.speaking.hub.scenarios" }
        public static var hubScenariosText: String { String(localized: "app.speaking.hub.scenarios", defaultValue: "Everyday situations", bundle: .module) }
        public static var hubTopics: LocalizedStringKey { "app.speaking.hub.topics" }
        public static var hubTopicsText: String { String(localized: "app.speaking.hub.topics", defaultValue: "Open topics", bundle: .module) }
        public static var hubProgress: LocalizedStringKey { "app.speaking.hub.progress" }
        public static var hubProgressText: String { String(localized: "app.speaking.hub.progress", defaultValue: "Your progress", bundle: .module) }
        public static var hubPhrasebook: LocalizedStringKey { "app.speaking.hub.phrasebook" }
        public static var hubPhrasebookText: String { String(localized: "app.speaking.hub.phrasebook", defaultValue: "Phrasebook", bundle: .module) }
        public static var hubHistory: LocalizedStringKey { "app.speaking.hub.history" }
        public static var hubHistoryText: String { String(localized: "app.speaking.hub.history", defaultValue: "Recent sessions", bundle: .module) }
        public static var hubEmpty: LocalizedStringKey { "app.speaking.hub.empty" }
        public static var hubEmptyText: String { String(localized: "app.speaking.hub.empty", defaultValue: "Choose a topic to start speaking practice.", bundle: .module) }

        public static var prepareLevel: LocalizedStringKey { "app.speaking.prepare.level" }
        public static var prepareLevelText: String { String(localized: "app.speaking.prepare.level", defaultValue: "Choose your level", bundle: .module) }
        public static var prepareVocabToggle: LocalizedStringKey { "app.speaking.prepare.vocab_toggle" }
        public static var prepareVocabToggleText: String { String(localized: "app.speaking.prepare.vocab_toggle", defaultValue: "Practice with learned words", bundle: .module) }
        public static var prepareWords: LocalizedStringKey { "app.speaking.prepare.words" }
        public static var prepareWordsText: String { String(localized: "app.speaking.prepare.words", defaultValue: "Words to practice", bundle: .module) }
        public static var prepareGoal: LocalizedStringKey { "app.speaking.prepare.goal" }
        public static var prepareGoalText: String { String(localized: "app.speaking.prepare.goal", defaultValue: "Conversation goal", bundle: .module) }
        public static var prepareStart: LocalizedStringKey { "app.speaking.prepare.start" }
        public static var prepareStartText: String { String(localized: "app.speaking.prepare.start", defaultValue: "Start speaking", bundle: .module) }
        public static var prepareCheckKey: LocalizedStringKey { "app.speaking.prepare.check_key" }
        public static var prepareCheckKeyText: String { String(localized: "app.speaking.prepare.check_key", defaultValue: "Add your Gemini API key in Settings.", bundle: .module) }
        public static var prepareCheckMic: LocalizedStringKey { "app.speaking.prepare.check_mic" }
        public static var prepareCheckMicText: String { String(localized: "app.speaking.prepare.check_mic", defaultValue: "Allow microphone access to practice speaking.", bundle: .module) }
        public static var prepareCheckNetwork: LocalizedStringKey { "app.speaking.prepare.check_network" }
        public static var prepareCheckNetworkText: String { String(localized: "app.speaking.prepare.check_network", defaultValue: "Connect to the internet to start a session.", bundle: .module) }

        public static var callConnecting: LocalizedStringKey { "app.speaking.call.connecting" }
        public static var callConnectingText: String { String(localized: "app.speaking.call.connecting", defaultValue: "Connecting…", bundle: .module) }
        public static var callReconnecting: LocalizedStringKey { "app.speaking.call.reconnecting" }
        public static var callReconnectingText: String { String(localized: "app.speaking.call.reconnecting", defaultValue: "Reconnecting…", bundle: .module) }
        public static var callHint: LocalizedStringKey { "app.speaking.call.hint" }
        public static var callHintText: String { String(localized: "app.speaking.call.hint", defaultValue: "Show me a hint", bundle: .module) }
        public static var callEnd: LocalizedStringKey { "app.speaking.call.end" }
        public static var callEndText: String { String(localized: "app.speaking.call.end", defaultValue: "End session", bundle: .module) }
        public static var callSubtitlesShow: LocalizedStringKey { "app.speaking.call.subtitles_show" }
        public static var callSubtitlesShowText: String { String(localized: "app.speaking.call.subtitles_show", defaultValue: "Show subtitles", bundle: .module) }
        public static var callSubtitlesHide: LocalizedStringKey { "app.speaking.call.subtitles_hide" }
        public static var callSubtitlesHideText: String { String(localized: "app.speaking.call.subtitles_hide", defaultValue: "Hide subtitles", bundle: .module) }
        public static var callTimeLeft: LocalizedStringKey { "app.speaking.call.time_left" }
        public static func callTimeLeftText(remainingSeconds: Int) -> String {
            String(
                format: String(
                    localized: "app.speaking.call.time_left",
                    defaultValue: "%lld sec left",
                    bundle: .module
                ),
                remainingSeconds
            )
        }

        public static var resultAnalyzing: LocalizedStringKey { "app.speaking.result.analyzing" }
        public static var resultAnalyzingText: String { String(localized: "app.speaking.result.analyzing", defaultValue: "Reviewing your conversation…", bundle: .module) }
        public static var resultFailed: LocalizedStringKey { "app.speaking.result.failed" }
        public static var resultFailedText: String { String(localized: "app.speaking.result.failed", defaultValue: "We couldn't analyze this session.", bundle: .module) }
        public static var resultPendingAnalysisFailed: LocalizedStringKey { "app.speaking.result.pending_analysis_failed" }
        public static var resultPendingAnalysisFailedText: String {
            String(
                localized: "app.speaking.result.pending_analysis_failed",
                defaultValue: "Analysis could not be completed. Try again.",
                bundle: .module
            )
        }
        public static func resultScoreValueText(value: Int) -> String {
            String(
                format: String(localized: "app.speaking.result.score_value", defaultValue: "%lld/5", bundle: .module),
                value
            )
        }
        public static var resultRetry: LocalizedStringKey { "app.speaking.result.retry" }
        public static var resultRetryText: String { String(localized: "app.speaking.result.retry", defaultValue: "Try again", bundle: .module) }
        public static var resultTooShort: LocalizedStringKey { "app.speaking.result.too_short" }
        public static var resultTooShortText: String { String(localized: "app.speaking.result.too_short", defaultValue: "Speak for a little longer to get feedback.", bundle: .module) }
        public static var resultAudioMissing: LocalizedStringKey { "app.speaking.result.audio_missing" }
        public static var resultAudioMissingText: String { String(localized: "app.speaking.result.audio_missing", defaultValue: "The recording is no longer available.", bundle: .module) }
        public static var resultScores: LocalizedStringKey { "app.speaking.result.scores" }
        public static var resultScoresText: String { String(localized: "app.speaking.result.scores", defaultValue: "Your speaking scores", bundle: .module) }
        public static var resultFluency: LocalizedStringKey { "app.speaking.result.fluency" }
        public static var resultFluencyText: String { String(localized: "app.speaking.result.fluency", defaultValue: "Fluency", bundle: .module) }
        public static var resultGrammar: LocalizedStringKey { "app.speaking.result.grammar" }
        public static var resultGrammarText: String { String(localized: "app.speaking.result.grammar", defaultValue: "Grammar", bundle: .module) }
        public static var resultVocabulary: LocalizedStringKey { "app.speaking.result.vocabulary" }
        public static var resultVocabularyText: String { String(localized: "app.speaking.result.vocabulary", defaultValue: "Vocabulary", bundle: .module) }
        public static var resultPronunciation: LocalizedStringKey { "app.speaking.result.pronunciation" }
        public static var resultPronunciationText: String { String(localized: "app.speaking.result.pronunciation", defaultValue: "Pronunciation", bundle: .module) }
        public static var resultCorrections: LocalizedStringKey { "app.speaking.result.corrections" }
        public static var resultCorrectionsText: String { String(localized: "app.speaking.result.corrections", defaultValue: "Corrections", bundle: .module) }
        public static var resultNatural: LocalizedStringKey { "app.speaking.result.natural" }
        public static var resultNaturalText: String { String(localized: "app.speaking.result.natural", defaultValue: "A more natural way to say it", bundle: .module) }
        public static var resultPronunciationNotes: LocalizedStringKey { "app.speaking.result.pronunciation_notes" }
        public static var resultPronunciationNotesText: String { String(localized: "app.speaking.result.pronunciation_notes", defaultValue: "Pronunciation notes", bundle: .module) }
        public static var resultTargetWords: LocalizedStringKey { "app.speaking.result.target_words" }
        public static var resultTargetWordsText: String { String(localized: "app.speaking.result.target_words", defaultValue: "Practice words used", bundle: .module) }
        public static var resultTargetUsedCorrectly: LocalizedStringKey { "app.speaking.result.target_used_correctly" }
        public static var resultTargetUsedIncorrectly: LocalizedStringKey { "app.speaking.result.target_used_incorrectly" }
        public static var resultTargetUnused: LocalizedStringKey { "app.speaking.result.target_unused" }
        public static var resultObjectiveMet: LocalizedStringKey { "app.speaking.result.objective_met" }
        public static var resultObjectiveMetText: String { String(localized: "app.speaking.result.objective_met", defaultValue: "Goal reached", bundle: .module) }
        public static var resultObjectiveNotMet: LocalizedStringKey { "app.speaking.result.objective_not_met" }
        public static var resultObjectiveNotMetText: String { String(localized: "app.speaking.result.objective_not_met", defaultValue: "Keep practicing toward your goal", bundle: .module) }
        public static var resultStrengths: LocalizedStringKey { "app.speaking.result.strengths" }
        public static var resultStrengthsText: String { String(localized: "app.speaking.result.strengths", defaultValue: "What you did well", bundle: .module) }
        public static var resultFocusNext: LocalizedStringKey { "app.speaking.result.focus_next" }
        public static var resultFocusNextText: String { String(localized: "app.speaking.result.focus_next", defaultValue: "What to focus on next", bundle: .module) }
        public static var resultSavePhrase: LocalizedStringKey { "app.speaking.result.save_phrase" }
        public static var resultSavePhraseText: String { String(localized: "app.speaking.result.save_phrase", defaultValue: "Save phrase", bundle: .module) }
        public static var resultSaved: LocalizedStringKey { "app.speaking.result.saved" }
        public static var resultSavedText: String { String(localized: "app.speaking.result.saved", defaultValue: "Phrase saved", bundle: .module) }

        public static var phrasebookTitle: LocalizedStringKey { "app.speaking.phrasebook.title" }
        public static var phrasebookTitleText: String { String(localized: "app.speaking.phrasebook.title", defaultValue: "My phrasebook", bundle: .module) }
        public static var phrasebookEmpty: LocalizedStringKey { "app.speaking.phrasebook.empty" }
        public static var phrasebookEmptyText: String { String(localized: "app.speaking.phrasebook.empty", defaultValue: "Phrases you save will appear here.", bundle: .module) }
        public static var phrasebookDelete: LocalizedStringKey { "app.speaking.phrasebook.delete" }
        public static var phrasebookDeleteText: String { String(localized: "app.speaking.phrasebook.delete", defaultValue: "Delete phrase", bundle: .module) }

        public static var errorMissingKey: LocalizedStringKey { "app.speaking.error.missing_key" }
        public static var errorMissingKeyText: String { String(localized: "app.speaking.error.missing_key", defaultValue: "Gemini API key is missing.", bundle: .module) }
        public static var errorUnauthorized: LocalizedStringKey { "app.speaking.error.unauthorized" }
        public static var errorUnauthorizedText: String { String(localized: "app.speaking.error.unauthorized", defaultValue: "Your API key was rejected.", bundle: .module) }
        public static var errorQuota: LocalizedStringKey { "app.speaking.error.quota" }
        public static var errorQuotaText: String { String(localized: "app.speaking.error.quota", defaultValue: "The API quota has been reached.", bundle: .module) }
        public static var errorOffline: LocalizedStringKey { "app.speaking.error.offline" }
        public static var errorOfflineText: String { String(localized: "app.speaking.error.offline", defaultValue: "You're offline.", bundle: .module) }
        public static var errorNetwork: LocalizedStringKey { "app.speaking.error.network" }
        public static var errorNetworkText: String { String(localized: "app.speaking.error.network", defaultValue: "A network error interrupted the session.", bundle: .module) }
        public static var errorSaveFailed: LocalizedStringKey { "app.speaking.error.save_failed" }
        public static var errorSaveFailedText: String { String(localized: "app.speaking.error.save_failed", defaultValue: "This session could not be saved. Try again to keep your progress.", bundle: .module) }
        public static var errorMicrophoneDenied: LocalizedStringKey { "app.speaking.error.microphone_denied" }
        public static var errorMicrophoneDeniedText: String { String(localized: "app.speaking.error.microphone_denied", defaultValue: "Microphone access is turned off.", bundle: .module) }
        public static var errorUnknown: LocalizedStringKey { "app.speaking.error.unknown" }
        public static var errorUnknownText: String { String(localized: "app.speaking.error.unknown", defaultValue: "Something went wrong.", bundle: .module) }
        public static var errorOpenSettings: LocalizedStringKey { "app.speaking.error.open_settings" }
        public static var errorOpenSettingsText: String { String(localized: "app.speaking.error.open_settings", defaultValue: "Open Settings", bundle: .module) }
        public static var errorTryAgain: LocalizedStringKey { "app.speaking.error.try_again" }
        public static var errorTryAgainText: String { String(localized: "app.speaking.error.try_again", defaultValue: "Try again", bundle: .module) }
        public static var errorExit: LocalizedStringKey { "app.speaking.error.exit" }
        public static var errorExitText: String { String(localized: "app.speaking.error.exit", defaultValue: "Exit", bundle: .module) }

        public static var tab: LocalizedStringKey { "app.speaking.tab" }
        public static var tabText: String { String(localized: "app.speaking.tab", defaultValue: "Speaking", bundle: .module) }

    }
}
