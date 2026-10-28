// swiftlint:disable:next file_length
// swiftlint:disable file_length
import Foundation
import SwiftUI

#if !SWIFT_PACKAGE
extension Bundle {
    static var module: Bundle {
        Bundle.main
    }
}
#endif

/// Centralized localization namespace for VocabCraftApp strings using SwiftUI LocalizedStringKey.
public enum AppStrings {
    // MARK: - Common Strings
    public enum Common {
        public static var ok: LocalizedStringKey { "common.ok" }
        public static var cancel: LocalizedStringKey { "common.cancel" }
        public static var confirm: LocalizedStringKey { "common.confirm" }
        public static var confirmText: String { String(localized: "common.confirm", defaultValue: "Confirm", bundle: .module) }
        public static var save: LocalizedStringKey { "common.save" }
        public static var reset: LocalizedStringKey { "common.reset" }
        public static var search: LocalizedStringKey { "common.search" }
        public static var done: LocalizedStringKey { "common.done" }
        public static var back: LocalizedStringKey { "common.back" }
        public static var viewDetails: LocalizedStringKey { "common.viewDetails" }
        public static var congratulations: LocalizedStringKey { "common.congratulations" }
        public static var retry: LocalizedStringKey { "common.retry" }
        public static var close: LocalizedStringKey { "common.close" }
        public static var wordUnit: LocalizedStringKey { "common.wordUnit" }
        public static var wordUnitText: String {
            String(localized: "common.wordUnit", defaultValue: "words", bundle: .module)
        }
        public static var error: LocalizedStringKey { "common.error" }
        public static var errorText: String {
            String(localized: "common.error", defaultValue: "Error", bundle: .module)
        }
        public static var delete: LocalizedStringKey { "common.delete" }
        public static var `continue`: LocalizedStringKey { "common.continue" }
        public static var skip: LocalizedStringKey { "common.skip" }
        public static var understand: LocalizedStringKey { "common.understand" }
    }

    // MARK: - Tab Bar Titles
    public enum Tabs {
        public static var home: LocalizedStringKey { "tabs.home" }
        public static var vocabulary: LocalizedStringKey { "tabs.vocabulary" }
        public static var aiAssistant: LocalizedStringKey { "tabs.ai_assistant" }
        public static var reflex: LocalizedStringKey { "tabs.reflex" }
        public static var settings: LocalizedStringKey { "tabs.settings" }
    }

    // MARK: - Homepage View
    public enum Homepage {
        public static var greeting: LocalizedStringKey { "homepage.greeting" }
        public static func greetingUser(_ name: String) -> LocalizedStringKey {
            LocalizedStringKey("homepage.greetingUser \(name)")
        }
        public static var streakDays: LocalizedStringKey { "homepage.streakDays" }
        public static var dailyGoal: LocalizedStringKey { "homepage.dailyGoal" }
        public static var suggestedWordsTitle: LocalizedStringKey { "homepage.suggestedWordsTitle" }
        public static var srsHeader: LocalizedStringKey { "homepage.srsHeader" }
        public static func srsRetentionMessage(_ percent: Int) -> LocalizedStringKey {
            LocalizedStringKey("homepage.srsRetentionMessage \(percent)")
        }
        public static var reflexTitle: LocalizedStringKey { "homepage.reflexTitle" }
        public static var reflexBadge: LocalizedStringKey { "homepage.reflexBadge" }
        public static func dueCardsSubtitle(_ count: Int) -> LocalizedStringKey {
            LocalizedStringKey("homepage.dueCardsSubtitle \(count)")
        }
        public static var practiceNow: LocalizedStringKey { "homepage.practiceNow" }
        public static var vocabLibraryTitle: LocalizedStringKey { "homepage.vocabLibraryTitle" }
        public static var vocabLibrarySubtitle: LocalizedStringKey { "homepage.vocabLibrarySubtitle" }
        public static var explore: LocalizedStringKey { "homepage.explore" }
        public static var cefrTitle: LocalizedStringKey { "homepage.cefrTitle" }
        public static var newWordBadge: LocalizedStringKey { "homepage.newWordBadge" }
        public static var saved: LocalizedStringKey { "homepage.saved" }
        public static var saveWord: LocalizedStringKey { "homepage.saveWord" }
    }

    // MARK: - Vocabulary View
    public enum Vocabulary {
        public static var personalBank: LocalizedStringKey { "vocabulary.personalBank" }
        public static var topicDecks: LocalizedStringKey { "vocabulary.topicDecks" }
        public static var searchPlaceholder: LocalizedStringKey { "vocabulary.searchPlaceholder" }
        public static var filterAll: LocalizedStringKey { "vocabulary.filterAll" }
        public static var filterReviewNeeded: LocalizedStringKey { "vocabulary.filterReviewNeeded" }
        public static var filterMastered: LocalizedStringKey { "vocabulary.filterMastered" }
        public static var filterSaved: LocalizedStringKey { "vocabulary.filterSaved" }
        public static var previewTopic: LocalizedStringKey { "vocabulary.previewTopic" }
        public static var startLearning: LocalizedStringKey { "vocabulary.startLearning" }
        public static var wordCount: LocalizedStringKey { "vocabulary.wordCount" }
        public static var level: LocalizedStringKey { "vocabulary.level" }
        public static var lessonCompleted: LocalizedStringKey { "vocabulary.lessonCompleted" }
        public static var wordsMasteredCount: LocalizedStringKey { "vocabulary.wordsMasteredCount" }
        public static var studyAgain: LocalizedStringKey { "vocabulary.studyAgain" }
        public static var backToHome: LocalizedStringKey { "vocabulary.backToHome" }
        public static var definition: LocalizedStringKey { "vocabulary.definition" }
        public static var example: LocalizedStringKey { "vocabulary.example" }
        public static var masteredBadge: LocalizedStringKey { "vocabulary.masteredBadge" }
        public static var reviewBadge: LocalizedStringKey { "vocabulary.reviewBadge" }
        public static var deleteWord: LocalizedStringKey { "vocabulary.deleteWord" }
        public static func completionPercent(_ percent: Int) -> LocalizedStringKey {
            LocalizedStringKey("vocabulary.completionPercent \(percent)")
        }
        public static var summaryPassedTitle: LocalizedStringKey { "vocabulary.summaryPassedTitle" }
        public static var summaryFailedTitle: LocalizedStringKey { "vocabulary.summaryFailedTitle" }
        public static var summaryPassedSubtitle: LocalizedStringKey { "vocabulary.summaryPassedSubtitle" }
        public static var summaryFailedSubtitle: LocalizedStringKey { "vocabulary.summaryFailedSubtitle" }
        public static var summaryTotalReward: LocalizedStringKey { "vocabulary.summaryTotalReward" }
        public static var summaryAccuracy: LocalizedStringKey { "vocabulary.summaryAccuracy" }
        public static var summaryNextStage: LocalizedStringKey { "vocabulary.summaryNextStage" }
        public static var summaryTotalWords: LocalizedStringKey { "vocabulary.summaryTotalWords" }
        public static var summarySrsMemory: LocalizedStringKey { "vocabulary.summarySrsMemory" }
        public static var summaryNeedsReview: LocalizedStringKey { "vocabulary.summaryNeedsReview" }
        public static var quizSelectOptionTitle: LocalizedStringKey { "vocabulary.quizSelectOptionTitle" }
        public static func attemptsLabel(current: Int, total: Int) -> LocalizedStringKey {
            LocalizedStringKey("vocabulary.attemptsLabel \(current) \(total)")
        }
        public static func quizCorrectXP(xp: Int) -> LocalizedStringKey {
            LocalizedStringKey("vocabulary.quizCorrectXP \(xp)")
        }
        public static var quizIncorrectXP: LocalizedStringKey { "vocabulary.quizIncorrectXP" }
        public static var progressTitle: LocalizedStringKey { "vocabulary.progressTitle" }
        public static func progressWordsCount(current: Int, total: Int) -> LocalizedStringKey {
            LocalizedStringKey("vocabulary.progressWordsCount \(current) \(total)")
        }
        public static var startNodeDefaultTitle: LocalizedStringKey { "vocabulary.startNodeDefaultTitle" }
        public static func startLearningNode(_ nodeTitle: String) -> LocalizedStringKey {
            LocalizedStringKey("vocabulary.startLearningNode \(nodeTitle)")
        }
        public static var emptyStageData: LocalizedStringKey { "vocabulary.emptyStageData" }
        public static func wordsMasteredCountLabel(current: Int, total: Int) -> LocalizedStringKey {
            LocalizedStringKey("vocabulary.wordsMasteredCountLabel \(current) \(total)")
        }
        public static func wordsMasteredCountText(current: Int, total: Int) -> String {
            String(format: String(localized: "vocabulary.wordsMasteredCountLabel %lld %lld", defaultValue: "%lld/%lld words mastered", bundle: .module), current, total)
        }
    }
}

// MARK: - Reflex Strings Extension

extension AppStrings {
    // MARK: - Reflex Drill View
    public enum Reflex {
        public static var title: LocalizedStringKey { "reflex.title" }
        public static var subtitle: LocalizedStringKey { "reflex.subtitle" }
        public static var startNow: LocalizedStringKey { "reflex.startNow" }
        public static var holdToSpeak: LocalizedStringKey { "reflex.holdToSpeak" }
        public static var listening: LocalizedStringKey { "reflex.listening" }
        public static var spokenAnswer: LocalizedStringKey { "reflex.spokenAnswer" }
        public static var correct: LocalizedStringKey { "reflex.correct" }
        public static var incorrect: LocalizedStringKey { "reflex.incorrect" }
        public static var tapToFlip: LocalizedStringKey { "reflex.tapToFlip" }
        public static var listenPronunciation: LocalizedStringKey { "reflex.listenPronunciation" }
        public static var reflexStreakCompleted: LocalizedStringKey { "reflex.reflexStreakCompleted" }
        public static var reflexAccuracy: LocalizedStringKey { "reflex.reflexAccuracy" }
        public static var continueNext: LocalizedStringKey { "reflex.continueNext" }
        public static var quickPracticeTitle: LocalizedStringKey { "reflex.quickPracticeTitle" }
        public static var quickStageProgress: LocalizedStringKey { "reflex.quickStageProgress" }
        public static func quickProgressSegment(_ stage: Int) -> String {
            String(format: String(localized: "reflex.quickProgressSegment %lld", defaultValue: "Stage %lld/3", bundle: .module), stage)
        }
        public static var quickStage1Title: LocalizedStringKey { "reflex.quickStage1Title" }
        public static var quickStage2Title: LocalizedStringKey { "reflex.quickStage2Title" }
        public static var quickStage3Title: LocalizedStringKey { "reflex.quickStage3Title" }
        public static var quickShadowButton: LocalizedStringKey { "reflex.quickShadowButton" }
        public static func quickShadowScoreLabel(_ score: Int) -> String {
            String(format: String(localized: "reflex.quickShadowScoreLabel %lld", defaultValue: "Pronunciation Score: %lld%%", bundle: .module), score)
        }
        public static var quickListenModelAgain: LocalizedStringKey { "reflex.quickListenModelAgain" }
        public static var quickContinue: LocalizedStringKey { "reflex.quickContinue" }
        public static var quickShadowCardTitle: LocalizedStringKey { "reflex.quickShadowCardTitle" }
        public static var quickModelSentence: LocalizedStringKey { "reflex.quickModelSentence" }
        public static var quickCollocationBadge: LocalizedStringKey { "reflex.quickCollocationBadge" }
        public static var quickRetrieveTitle: LocalizedStringKey { "reflex.quickRetrieveTitle" }
        public static var quickUseTitle: LocalizedStringKey { "reflex.quickUseTitle" }
        public static var quickVoiceMode: LocalizedStringKey { "reflex.quickVoiceMode" }
        public static var quickTypingMode: LocalizedStringKey { "reflex.quickTypingMode" }
        public static var quickListenExample: LocalizedStringKey { "reflex.quickListenExample" }
        public static var quickHints: LocalizedStringKey { "reflex.quickHints" }
        public static var quickShowHint: LocalizedStringKey { "reflex.quickShowHint" }
        public static var quickHintAvailableText: String { String(localized: "reflex.quickHintAvailable", defaultValue: "Hint available", bundle: .module) }
        public static var quickTypeAnswer: LocalizedStringKey { "reflex.quickTypeAnswer" }
        public static var quickSubmit: LocalizedStringKey { "reflex.quickSubmit" }
        public static var quickTypingFallback: LocalizedStringKey { "reflex.quickTypingFallback" }
        public static var quickTranscriptFeedback: LocalizedStringKey { "reflex.quickTranscriptFeedback" }
        public static var quickReveal: LocalizedStringKey { "reflex.quickReveal" }
        public static var quickSkip: LocalizedStringKey { "reflex.quickSkip" }
        public static var quickResultsTitle: LocalizedStringKey { "reflex.quickResultsTitle" }
        public static var quickSucceeded: LocalizedStringKey { "reflex.quickSucceeded" }
        public static var quickNeedsPractice: LocalizedStringKey { "reflex.quickNeedsPractice" }
        public static var quickPreviousAttempt: LocalizedStringKey { "reflex.quickPreviousAttempt" }
        public static var quickCurrentAttempt: LocalizedStringKey { "reflex.quickCurrentAttempt" }
        public static var quickConfidenceQuestion: LocalizedStringKey { "reflex.quickConfidenceQuestion" }
        public static var quickComfortable: LocalizedStringKey { "reflex.quickComfortable" }
        public static var quickUncertain: LocalizedStringKey { "reflex.quickUncertain" }
        public static var quickSaving: LocalizedStringKey { "reflex.quickSaving" }
        public static var quickRevealedAnswer: LocalizedStringKey { "reflex.quickRevealedAnswer" }
        public static func quickStageProgressValue(stage: Int, total: Int) -> String {
            String(format: String(localized: "reflex.quickStageProgressValue %lld %lld", defaultValue: "Stage %lld of %lld", bundle: .module), stage, total)
        }
        public static var quickNounSentenceFrame: String { String(localized: "reflex.quickNounSentenceFrame", defaultValue: "Create a sentence using the noun '%@' with '%@'", bundle: .module) }
        public static var quickVerbSentenceFrame: String { String(localized: "reflex.quickVerbSentenceFrame", defaultValue: "Create a sentence using the verb '%@' with '%@'", bundle: .module) }
        public static var quickAdjectiveSentenceFrame: String { String(localized: "reflex.quickAdjectiveSentenceFrame", defaultValue: "Create a sentence using the adjective '%@' with '%@'", bundle: .module) }
        public static var quickAdverbSentenceFrame: String { String(localized: "reflex.quickAdverbSentenceFrame", defaultValue: "Create a sentence using the adverb '%@' with '%@'", bundle: .module) }
        public static var quickPhraseSentenceFrame: String { String(localized: "reflex.quickPhraseSentenceFrame", defaultValue: "Create a sentence using the phrase '%@' with '%@'", bundle: .module) }
        public static func quickTimeSaved(_ time: String) -> String {
            String(format: String(localized: "reflex.quickTimeSaved %@", defaultValue: "-%@ saved", bundle: .module), time)
        }
        public static func quickTimeSlower(_ time: String) -> String {
            String(format: String(localized: "reflex.quickTimeSlower %@", defaultValue: "+%@ slower", bundle: .module), time)
        }
        public static var quickTimeUnchanged: LocalizedStringKey { "reflex.quickTimeUnchanged" }
        public static var quickMicDefaultIdleText: String { String(localized: "reflex.quickMicDefaultIdle", defaultValue: "Tap to Speak", bundle: .module) }
        public static var quickMicDefaultListeningText: String { String(localized: "reflex.quickMicDefaultListening", defaultValue: "Listening...", bundle: .module) }
        public static var quickMicStartAccessibility: LocalizedStringKey { "reflex.quickMicStartAccessibility" }
        public static var quickMicStopAccessibility: LocalizedStringKey { "reflex.quickMicStopAccessibility" }
        public static var quickVisualizerPlaceholderText: String { String(localized: "reflex.quickVisualizerPlaceholder", defaultValue: "Speak the word or collocation aloud", bundle: .module) }
        public static var quickVisualizerListeningText: String { String(localized: "reflex.quickVisualizerListening", defaultValue: "Listening to your pronunciation...", bundle: .module) }
        public static func quickRecordingError(_ description: String) -> String {
            String(format: String(localized: "reflex.quickRecordingError %@", defaultValue: "Recording error: %@", bundle: .module), description)
        }
        public static var quickSpeechRetryText: String { String(localized: "reflex.quickSpeechRetry", defaultValue: "Try speaking again or switch to typing", bundle: .module) }
        public static var quickSpeechTypingText: String { String(localized: "reflex.quickSpeechTyping", defaultValue: "Type your answer below", bundle: .module) }
        public static func quickUsePrompt(_ lemma: String) -> String {
            String(format: String(localized: "reflex.quickUsePrompt %@", defaultValue: "Make a sentence using '%@'", bundle: .module), lemma)
        }
        public static func quickUsePromptFromExample(_ lemma: String, _ example: String) -> String {
            String(format: String(localized: "reflex.quickUsePromptFromExample %@ %@", defaultValue: "Make a complete sentence with '%@' based on: \"%@\"", bundle: .module), lemma, example)
        }
        public static var speedBonus: LocalizedStringKey { "reflex.speedBonus" }
        public static var listenExample: LocalizedStringKey { "reflex.listenExample" }
        public static var micPlaceholder: LocalizedStringKey { "reflex.micPlaceholder" }
        public static var micIdle: LocalizedStringKey { "reflex.micIdle" }
        public static var micListening: LocalizedStringKey { "reflex.micListening" }
        public static var masteredFeedback: LocalizedStringKey { "reflex.masteredFeedback" }
        public static var completedFeedback: LocalizedStringKey { "reflex.completedFeedback" }
        public static var reactionTimeTitle: LocalizedStringKey { "reflex.reactionTimeTitle" }
        public static var reactionTimeLabel: LocalizedStringKey { "reflex.reactionTimeLabel" }
        public static func speedBonusCountLabel(count: Int, total: Int) -> LocalizedStringKey {
            LocalizedStringKey("reflex.speedBonusCountLabel \(count) \(total)")
        }
        public static var srsLevelHeader: LocalizedStringKey { "reflex.srsLevelHeader" }
        public static func levelLabel(level: Int) -> LocalizedStringKey {
            LocalizedStringKey("reflex.levelLabel \(level)")
        }
        public static var nextReviewHeader: LocalizedStringKey { "reflex.nextReviewHeader" }
        public static func daysLater(days: Int) -> LocalizedStringKey {
            LocalizedStringKey("reflex.daysLater \(days)")
        }
        public static var nextDrill: LocalizedStringKey { "reflex.nextDrill" }
        public static var loadingDrills: LocalizedStringKey { "reflex.loadingDrills" }
        public static var audioAlertTitle: LocalizedStringKey { "reflex.audioAlertTitle" }
        public static func lessonProgressLabel(current: Int, total: Int) -> LocalizedStringKey {
            LocalizedStringKey("reflex.lessonProgressLabel \(current) \(total)")
        }
        public static var promptHeader: LocalizedStringKey { "reflex.promptHeader" }
        public static var viewHint: LocalizedStringKey { "reflex.viewHint" }
        public static var speakingState: LocalizedStringKey { "reflex.speakingState" }
        public static var listenStandardPronunciation: LocalizedStringKey { "reflex.listenStandardPronunciation" }
        public static var feedbackCorrect: LocalizedStringKey { "reflex.feedbackCorrect" }
        public static var feedbackIncorrect: LocalizedStringKey { "reflex.feedbackIncorrect" }
        public static var excellentSpeech: LocalizedStringKey { "reflex.excellentSpeech" }
        public static var correctSpeech: LocalizedStringKey { "reflex.correctSpeech" }
        public static var needsPractice: LocalizedStringKey { "reflex.needsPractice" }
        public static var speechEvaluation: LocalizedStringKey { "reflex.speechEvaluation" }
        public static func incorrectFeedback(_ answer: String) -> LocalizedStringKey {
            LocalizedStringKey("reflex.incorrectFeedback \(answer)")
        }
        public static func modeA11yLabel(mode: String, duration: String) -> String {
            String(format: String(localized: "app.reflex.mode_a11y_format", defaultValue: "Mode: %@, time limit %@", bundle: .module), mode, duration)
        }
        public static func modeAccessibilityLabel(mode: String, duration: String) -> String {
            modeA11yLabel(mode: mode, duration: duration)
        }
    }

    // MARK: - Settings View
    public enum Settings {
        public static var title: LocalizedStringKey { "app.settings.title" }
        public static var titleText: String { String(localized: "app.settings.title", defaultValue: "Settings", bundle: .module) }

        // Profile
        public static var membershipActive: LocalizedStringKey { "app.settings.profile.membership_active" }
        public static var membershipActiveText: String { String(localized: "app.settings.profile.membership_active", defaultValue: "PRO ACTIVE", bundle: .module) }
        public static var profilePerks: LocalizedStringKey { "app.settings.profile.perks" }
        public static var profilePerksText: String { String(localized: "app.settings.profile.perks", defaultValue: "Pro Member · Unlocked all 3,000+ Oxford words & Reflex Blitz", bundle: .module) }
        public static var profileTagline: LocalizedStringKey { "app.settings.profile.tagline" }
        public static var profileTaglineText: String { String(localized: "app.settings.profile.tagline", defaultValue: "Master 3,000+ Oxford words with Reflex Blitz", bundle: .module) }
        public static var profileActionView: LocalizedStringKey { "app.settings.profile.action_view" }
        public static var profileActionViewText: String { String(localized: "app.settings.profile.action_view", defaultValue: "View Profile & Achievements", bundle: .module) }

        // Learning Section
        public static var sectionLearning: LocalizedStringKey { "app.settings.section.learning" }
        public static var targetLevel: LocalizedStringKey { "app.settings.learning.target_level" }
        public static var targetLevelText: String { String(localized: "app.settings.learning.target_level", defaultValue: "Target Level", bundle: .module) }
        public static var appLanguage: LocalizedStringKey { "app.settings.learning.app_language" }
        public static var appLanguageText: String { String(localized: "app.settings.learning.app_language", defaultValue: "App Language", bundle: .module) }
        public static var langSystem: LocalizedStringKey { "app.settings.learning.lang_system" }
        public static var langVietnamese: LocalizedStringKey { "app.settings.learning.lang_vi" }
        public static var langEnglish: LocalizedStringKey { "app.settings.learning.lang_en" }
        public static var dailyGoal: LocalizedStringKey { "app.settings.learning.daily_goal" }
        public static var dailyGoalText: String { String(localized: "app.settings.learning.daily_goal", defaultValue: "Daily Goal", bundle: .module) }
        public static var dailyGoalPlaceholder: LocalizedStringKey { "app.settings.learning.daily_goal_placeholder" }
        public static var dailyGoalPlaceholderText: String { String(localized: "app.settings.learning.daily_goal_placeholder", defaultValue: "5 - 100 words", bundle: .module) }
        public static var reminders: LocalizedStringKey { "app.settings.learning.reminders" }
        public static var reminderTime: LocalizedStringKey { "app.settings.learning.reminder_time" }
        public static var resetSRS: LocalizedStringKey { "app.settings.learning.reset_srs" }
        public static var resetSRSSubtitle: LocalizedStringKey { "app.settings.learning.reset_srs_subtitle" }
        public static var resetConfirmTitle: LocalizedStringKey { "app.settings.learning.reset_confirm_title" }
        public static var resetConfirmMessage: LocalizedStringKey { "app.settings.learning.reset_confirm_message" }

        // Audio Section
        public static var sectionAudio: LocalizedStringKey { "app.settings.section.audio" }
        public static var audioAccent: LocalizedStringKey { "app.settings.audio.accent" }
        public static var accentUS: LocalizedStringKey { "app.settings.audio.accent_us" }
        public static var accentUSText: String { String(localized: "app.settings.audio.accent_us", defaultValue: "US (American)", bundle: .module) }
        public static var accentUK: LocalizedStringKey { "app.settings.audio.accent_uk" }
        public static var accentUKText: String { String(localized: "app.settings.audio.accent_uk", defaultValue: "UK (British)", bundle: .module) }
        public static var speechSpeed: LocalizedStringKey { "app.settings.audio.speed" }
        public static var testTTS: LocalizedStringKey { "app.settings.audio.test_tts" }
        public static var playingPreview: LocalizedStringKey { "app.settings.audio.playing_preview" }

        // Roleplay Voice
        public static var voiceSectionTitle: LocalizedStringKey { "app.settings.voice.section_title" }
        public static var voiceSectionTitleText: String { String(localized: "app.settings.voice.section_title", defaultValue: "Role Play Voice", bundle: .module) }
        public static var voiceCurrentProfile: LocalizedStringKey { "app.settings.voice.current_profile" }
        public static var voiceCurrentProfileText: String { String(localized: "app.settings.voice.current_profile", defaultValue: "Active Voice", bundle: .module) }
        public static var voiceAutoPersona: LocalizedStringKey { "app.settings.voice.auto_persona" }
        public static var voiceAutoPersonaText: String { String(localized: "app.settings.voice.auto_persona", defaultValue: "Automatic (Character Persona)", bundle: .module) }
        public static var voicePreviewButton: LocalizedStringKey { "app.settings.voice.preview_button" }
        public static var voicePreviewButtonText: String { String(localized: "app.settings.voice.preview_button", defaultValue: "Play Preview", bundle: .module) }
        public static var voicePreviewing: LocalizedStringKey { "app.settings.voice.previewing" }
        public static var voicePreviewingText: String { String(localized: "app.settings.voice.previewing", defaultValue: "Playing...", bundle: .module) }
        public static var voicePreviewNeedsDownload: LocalizedStringKey { "app.settings.voice.preview_needs_download" }
        public static var voicePreviewNeedsDownloadText: String { String(localized: "app.settings.voice.preview_needs_download", defaultValue: "Model download is required to preview this voice.", bundle: .module) }
        public static var voicePreviewDownloadAction: LocalizedStringKey { "app.settings.voice.preview_download_action" }
        public static var voicePreviewDownloadActionText: String { String(localized: "app.settings.voice.preview_download_action", defaultValue: "Download Model", bundle: .module) }
        public static var voiceSpeed: LocalizedStringKey { "app.settings.voice.speed" }
        public static var voiceSpeedText: String { String(localized: "app.settings.voice.speed", defaultValue: "Voice Speed", bundle: .module) }
        public static var voicePitch: LocalizedStringKey { "app.settings.voice.pitch" }
        public static var voicePitchText: String { String(localized: "app.settings.voice.pitch", defaultValue: "Voice Pitch", bundle: .module) }
        public static var voiceQualityApple: LocalizedStringKey { "app.settings.voice.quality_apple" }
        public static var voiceQualityAppleText: String { String(localized: "app.settings.voice.quality_apple", defaultValue: "Device Enhanced", bundle: .module) }
        public static var voiceQualityGemini: LocalizedStringKey { "app.settings.voice.quality_gemini" }
        public static var voiceQualityGeminiText: String { String(localized: "app.settings.voice.quality_gemini", defaultValue: "Cloud Studio Neural", bundle: .module) }
        public static var voiceQualityKokoro: LocalizedStringKey { "app.settings.voice.quality_kokoro" }
        public static var voiceQualityKokoroText: String { String(localized: "app.settings.voice.quality_kokoro", defaultValue: "On-Device Neural", bundle: .module) }

        // Appearance Section
        public static var sectionAppearance: LocalizedStringKey { "app.settings.section.appearance" }
        public static var appearanceMode: LocalizedStringKey { "app.settings.appearance.theme_mode" }
        public static var themeDark: LocalizedStringKey { "app.settings.appearance.theme_dark" }
        public static var themeDarkText: String { String(localized: "app.settings.appearance.theme_dark", defaultValue: "Dark", bundle: .module) }
        public static var themeLight: LocalizedStringKey { "app.settings.appearance.theme_light" }
        public static var themeLightText: String { String(localized: "app.settings.appearance.theme_light", defaultValue: "Light", bundle: .module) }
        public static var themeSystem: LocalizedStringKey { "app.settings.appearance.theme_system" }
        public static var themeSystemText: String { String(localized: "app.settings.appearance.theme_system", defaultValue: "System", bundle: .module) }
        public static var haptics: LocalizedStringKey { "app.settings.appearance.haptics" }
        public static var soundEffects: LocalizedStringKey { "app.settings.appearance.sound_effects" }

        // Developer Tools Section
        public static var sectionDevTools: LocalizedStringKey { "app.settings.section.dev_tools" }
        public static var themePreset: LocalizedStringKey { "app.settings.dev.theme_preset" }
        public static var craftCatalog: LocalizedStringKey { "app.settings.dev.catalog_title" }
        public static var craftCatalogSubtitle: LocalizedStringKey { "app.settings.dev.catalog_subtitle" }

        // About Section
        public static var sectionAbout: LocalizedStringKey { "app.settings.section.about" }
        public static var icloudSync: LocalizedStringKey { "app.settings.about.icloud_sync" }
        public static var synced: LocalizedStringKey { "app.settings.about.synced" }
        public static var clearCache: LocalizedStringKey { "app.settings.about.clear_cache" }
        public static var appVersion: LocalizedStringKey { "app.settings.about.app_version" }
        public static var levelBadge: LocalizedStringKey { "app.settings.profile.level_badge" }
        public static var levelBadgeText: String { String(localized: "app.settings.profile.level_badge", defaultValue: "B2 Intermediate", bundle: .module) }

        // Data & Storage Section
        public static var sectionDataStorage: LocalizedStringKey { "app.settings.section.data_storage" }
        public static var sectionDataStorageText: String {
            String(localized: "app.settings.section.data_storage", defaultValue: "Data & Storage", bundle: .module)
        }

        // AI Configuration Section
        public static var sectionAI: LocalizedStringKey { "app.settings.section.ai" }
        public static var sectionAIText: String { String(localized: "app.settings.section.ai", defaultValue: "AI CONFIGURATION", bundle: .module) }
        public static var aiGeminiKeyTitle: LocalizedStringKey { "app.settings.ai.gemini_key_title" }
        public static var aiGeminiKeyTitleText: String { String(localized: "app.settings.ai.gemini_key_title", defaultValue: "Gemini API Key", bundle: .module) }
        public static var aiGeminiKeyPlaceholder: LocalizedStringKey { "app.settings.ai.gemini_key_placeholder" }
        public static var aiGeminiKeyPlaceholderText: String { String(localized: "app.settings.ai.gemini_key_placeholder", defaultValue: "Enter Gemini API Key...", bundle: .module) }
        public static var aiGeminiStatusConnected: LocalizedStringKey { "app.settings.ai.gemini_status_connected" }
        public static var aiGeminiStatusConnectedText: String { String(localized: "app.settings.ai.gemini_status_connected", defaultValue: "Active (Gemini 1.5 Flash)", bundle: .module) }
        public static var aiGeminiStatusMock: LocalizedStringKey { "app.settings.ai.gemini_status_mock" }
        public static var aiGeminiStatusMockText: String { String(localized: "app.settings.ai.gemini_status_mock", defaultValue: "Mock Mode (Demo)", bundle: .module) }
        public static var aiGeminiActive: LocalizedStringKey { "app.settings.ai.gemini_active" }
        public static var aiGeminiActiveText: String { String(localized: "app.settings.ai.gemini_active", defaultValue: "Active", bundle: .module) }
        public static var aiGeminiMock: LocalizedStringKey { "app.settings.ai.gemini_mock" }
        public static var aiGeminiMockText: String { String(localized: "app.settings.ai.gemini_mock", defaultValue: "Mock Mode", bundle: .module) }
        public static var aiGeminiHelpText: LocalizedStringKey { "app.settings.ai.gemini_help_text" }
        public static var aiGeminiHelpTextString: String {
            String(
                localized: "app.settings.ai.gemini_help_text",
                defaultValue: "Get a free Gemini API key at Google AI Studio to unlock natural roleplay dialogues.",
                bundle: .module
            )
        }
        public static var aiGroqKeyTitle: LocalizedStringKey { "app.settings.ai.groq_key_title" }
        public static var aiGroqKeyTitleText: String { String(localized: "app.settings.ai.groq_key_title", defaultValue: "Groq API Key", bundle: .module) }
        public static var aiGroqKeyPlaceholder: LocalizedStringKey { "app.settings.ai.groq_key_placeholder" }
        public static var aiGroqKeyPlaceholderText: String { String(localized: "app.settings.ai.groq_key_placeholder", defaultValue: "Enter Groq API Key (gsk_...)", bundle: .module) }
        public static var aiGroqStatusActive: LocalizedStringKey { "app.settings.ai.groq_status_active" }
        public static var aiGroqStatusActiveText: String { String(localized: "app.settings.ai.groq_status_active", defaultValue: "Active (Groq Llama 3.3)", bundle: .module) }
        public static var aiGroqHelpText: LocalizedStringKey { "app.settings.ai.groq_help_text" }
        public static var aiGroqHelpTextString: String {
            String(
                localized: "app.settings.ai.groq_help_text",
                defaultValue: "Get a free ultra-fast Groq key at console.groq.com",
                bundle: .module
            )
        }
        public static var aiShowKey: LocalizedStringKey { "app.settings.ai.show_key" }
        public static var aiShowKeyText: String { String(localized: "app.settings.ai.show_key", defaultValue: "Show API Key", bundle: .module) }
        public static var aiHideKey: LocalizedStringKey { "app.settings.ai.hide_key" }
        public static var aiHideKeyText: String { String(localized: "app.settings.ai.hide_key", defaultValue: "Hide API Key", bundle: .module) }
        public static var aiClearKey: LocalizedStringKey { "app.settings.ai.clear_key" }
        public static var aiClearKeyText: String { String(localized: "app.settings.ai.clear_key", defaultValue: "Clear API Key", bundle: .module) }
    }

    // MARK: - Temporary voice picker compatibility
    public enum AIAssistant {
        public static var selectVoiceTitle: LocalizedStringKey { "app.ai_assistant.room.voice_picker_title" }
    }

    // MARK: - Home Learning Path
    public enum Home {
        // Header
        public static var title: LocalizedStringKey { "app.home.title" }
        public static var titleText: String {
            String(localized: "app.home.title", defaultValue: "Home", bundle: .module)
        }
        public static var learningPathBadge: LocalizedStringKey { "app.home.learning_path.badge" }
        public static var learningPathBadgeText: String {
            String(localized: "app.home.learning_path.badge", defaultValue: "Active Journey", bundle: .module)
        }
        public static func learningPathLevel(_ level: String) -> String {
            String(format: String(localized: "app.home.learning_path.level_format", defaultValue: "Level %@", bundle: .module), level)
        }
        public static func dailyGoalCount(completed: Int, goal: Int) -> String {
            String(format: String(localized: "app.home.header.daily_goal_count_format", defaultValue: "%lld/%lld", bundle: .module), completed, goal)
        }
        public static func dailyGoalA11y(completed: Int, goal: Int) -> String {
            String(format: String(localized: "app.home.header.daily_goal_a11y_format", defaultValue: "Daily Goal: %lld of %lld words completed", bundle: .module), completed, goal)
        }
        public static func greeting(_ name: String) -> String {
            String(format: String(localized: "app.home.header.greeting_format", defaultValue: "Hello, %@", bundle: .module), name)
        }
        public static func greeting(name: String) -> String {
            greeting(name)
        }
        public static func greetingKey(_ name: String) -> LocalizedStringKey {
            LocalizedStringKey("app.home.header.greeting_format \(name)")
        }
        public static func dailyGoal(percent: Int) -> String {
            String(format: String(localized: "app.home.header.daily_goal_format", defaultValue: "Daily Goal: %lld%%", bundle: .module), percent)
        }
        public static func streak(days: Int) -> String {
            String(format: String(localized: "app.home.header.streak_format", defaultValue: "%lld days", bundle: .module), days)
        }

        // Section & Checkpoint Header
        public static func unitTitle(number: Int, title: String) -> String {
            String(format: String(localized: "app.home.section.unit_title_format", defaultValue: "Unit %lld: %@", bundle: .module), number, title)
        }
        public static func sectionProgress(completed: Int, total: Int) -> String {
            String(format: String(localized: "app.home.section.progress_format", defaultValue: "%lld/%lld lessons", bundle: .module), completed, total)
        }
        public static func deckSummary(lessons: Int, words: Int) -> String {
            String(format: String(localized: "app.home.section.deck_summary_format", defaultValue: "%lld lessons • %lld words", bundle: .module), lessons, words)
        }
        public static var todayLabelText: String { String(localized: "app.home.header.today_label", defaultValue: "today", bundle: .module) }
        public static var todayLabel: LocalizedStringKey { "app.home.header.today_label" }
        public static var checkpointTitle: LocalizedStringKey { "app.home.section.checkpoint_title" }
        public static var checkpointTitleText: String { String(localized: "app.home.section.checkpoint_title", defaultValue: "Unit Review Exam", bundle: .module) }
        public static var checkpointSubtitle: LocalizedStringKey { "app.home.section.checkpoint_subtitle" }
        public static var checkpointSubtitleText: String { String(localized: "app.home.section.checkpoint_subtitle", defaultValue: "Comprehensive exam covering all unit words", bundle: .module) }
        public static var treasureTitle: LocalizedStringKey { "app.home.section.treasure_title" }
        public static var treasureTitleText: String { String(localized: "app.home.section.treasure_title", defaultValue: "Treasure Chest", bundle: .module) }
        public static var treasureSubtitle: LocalizedStringKey { "app.home.section.treasure_subtitle" }
        public static var treasureSubtitleText: String { String(localized: "app.home.section.treasure_subtitle", defaultValue: "150 XP Bonus", bundle: .module) }

        // Node Metadata & Objectives
        public static func wordsDuration(words: Int, minutes: Int) -> String {
            String(format: String(localized: "app.home.node.words_duration_format", defaultValue: "%lld words • %lld min", bundle: .module), words, minutes)
        }
        public static func objective1(words: Int) -> String {
            String(format: String(localized: "app.home.node.objective_1_format", defaultValue: "Master %lld core vocabulary words", bundle: .module), words)
        }
        public static var objective2: LocalizedStringKey { "app.home.node.objective_2" }
        public static var objective2Text: String {
            String(localized: "app.home.node.objective_2", defaultValue: "Practice 2-way Receptive & Productive recall", bundle: .module)
        }
        public static var objective3: LocalizedStringKey { "app.home.node.objective_3" }
        public static var objective3Text: String {
            String(localized: "app.home.node.objective_3", defaultValue: "Achieve ≥ 80% accuracy to pass", bundle: .module)
        }
        public static func checkpointObjective1(words: Int) -> String {
            String(format: String(localized: "app.home.node.checkpoint_objective_1_format", defaultValue: "Review all %lld words in this unit", bundle: .module), words)
        }
        public static var checkpointObjective2: LocalizedStringKey { "app.home.node.checkpoint_objective_2" }
        public static var checkpointObjective2Text: String {
            String(localized: "app.home.node.checkpoint_objective_2", defaultValue: "Score ≥ 80% accuracy to unlock the next Unit", bundle: .module)
        }

        // Spiral Review Node
        public static var spiralReviewTitle: LocalizedStringKey { "app.home.node.spiral_review_title" }
        public static var spiralReviewTitleText: String {
            String(localized: "app.home.node.spiral_review_title", defaultValue: "Spaced Spiral Review", bundle: .module)
        }
        public static var spiralReviewSubtitle: LocalizedStringKey { "app.home.node.spiral_review_subtitle" }
        public static var spiralReviewSubtitleText: String {
            String(localized: "app.home.node.spiral_review_subtitle", defaultValue: "Reinforce past unit vocabulary", bundle: .module)
        }
        public static func spiralReviewObjective1(words: Int) -> String {
            String(format: String(localized: "app.home.node.spiral_review_objective_1_format", defaultValue: "Review %lld words needing consolidation", bundle: .module), words)
        }
        public static var spiralReviewObjective2: LocalizedStringKey { "app.home.node.spiral_review_objective_2" }
        public static var spiralReviewObjective2Text: String {
            String(localized: "app.home.node.spiral_review_objective_2", defaultValue: "Combat the forgetting curve across units", bundle: .module)
        }

        // Fast-Track Jump-Ahead
        public static var fastTrackTitle: LocalizedStringKey { "app.home.checkpoint.fast_track_title" }
        public static var fastTrackTitleText: String {
            String(localized: "app.home.checkpoint.fast_track_title", defaultValue: "Fast-Track Challenge", bundle: .module)
        }
        public static var fastTrackCTA: LocalizedStringKey { "app.home.checkpoint.fast_track_cta" }
        public static var fastTrackCTAText: String {
            String(localized: "app.home.checkpoint.fast_track_cta", defaultValue: "Fast-Track Challenge", bundle: .module)
        }
        public static var fastTrackDescriptionText: String {
            String(localized: "app.home.checkpoint.fast_track_description", defaultValue: "Score ≥ 85% on this checkpoint to test out of this unit and unlock the next one immediately.", bundle: .module)
        }
        public static var fastTrackSuccessText: String {
            String(localized: "app.home.checkpoint.fast_track_success", defaultValue: "Fast-Track Success! Unit unlocked.", bundle: .module)
        }
        public static var fastTrackFailedText: String {
            String(localized: "app.home.checkpoint.fast_track_failed", defaultValue: "Need ≥ 85% to fast-track. Review unit lessons and try again!", bundle: .module)
        }

        // Call-to-Actions & Hints
        public static var ctaStart: LocalizedStringKey { "app.home.node.cta_start" }
        public static var ctaStartText: String {
            String(localized: "app.home.node.cta_start", defaultValue: "Start Lesson", bundle: .module)
        }
        public static func ctaContinue(percent: Int) -> String {
            String(format: String(localized: "app.home.node.cta_continue_format", defaultValue: "Continue (%lld%%)", bundle: .module), percent)
        }
        public static func ctaReview(xp: Int) -> String {
            String(format: String(localized: "app.home.node.cta_review_format", defaultValue: "Review Lesson (+%lld XP)", bundle: .module), xp)
        }
        public static var ctaSpiralReview: LocalizedStringKey { "app.home.node.cta_spiral_review" }
        public static var ctaSpiralReviewText: String {
            String(localized: "app.home.node.cta_spiral_review", defaultValue: "Start Spiral Review", bundle: .module)
        }
        public static var ctaCheckpoint: LocalizedStringKey { "app.home.node.cta_checkpoint" }
        public static var ctaCheckpointText: String {
            String(localized: "app.home.node.cta_checkpoint", defaultValue: "Start Boss Exam", bundle: .module)
        }
        public static var lockedHint: LocalizedStringKey { "app.home.node.locked_hint" }
        public static var lockedHintText: String {
            String(localized: "app.home.node.locked_hint", defaultValue: "Complete previous lessons to unlock", bundle: .module)
        }

        // Toast
        public static var completedTitle: LocalizedStringKey { "app.home.toast.completed_title" }
        public static var completedTitleText: String {
            String(localized: "app.home.toast.completed_title", defaultValue: "Completed!", bundle: .module)
        }
        public static var starsSuffix: LocalizedStringKey { "app.home.toast.stars_suffix" }
        public static var starsSuffixText: String {
            String(localized: "app.home.toast.stars_suffix", defaultValue: " • Amazing!", bundle: .module)
        }
    }

    // MARK: - Widget
    public enum Widget {
        public static var displayName: LocalizedStringKey { "app.widget.display_name" }
        public static var displayNameText: String { String(localized: "app.widget.display_name", defaultValue: "VocabCraft Reflex Widget", bundle: .module) }
        public static var description: LocalizedStringKey { "app.widget.description" }
        public static var descriptionText: String { String(localized: "app.widget.description", defaultValue: "Learn words from your path right on your Home Screen.", bundle: .module) }
    }

    // MARK: - Audio
    public enum Audio {
        public static var voiceQualityPremium: LocalizedStringKey { "app.audio.voice_quality_premium" }
        public static var voiceQualityPremiumText: String { String(localized: "app.audio.voice_quality_premium", defaultValue: "Studio Quality Voice", bundle: .module) }
        public static var voiceQualityEnhanced: LocalizedStringKey { "app.audio.voice_quality_enhanced" }
        public static var voiceQualityEnhancedText: String { String(localized: "app.audio.voice_quality_enhanced", defaultValue: "Enhanced Natural Voice", bundle: .module) }
        public static var voiceQualityStandard: LocalizedStringKey { "app.audio.voice_quality_standard" }
        public static var voiceQualityStandardText: String { String(localized: "app.audio.voice_quality_standard", defaultValue: "Standard Voice", bundle: .module) }
        public static var fallbackNotice: LocalizedStringKey { "app.audio.fallback_notice" }
        public static var fallbackNoticeText: String { String(localized: "app.audio.fallback_notice", defaultValue: "Switched to offline voice", bundle: .module) }
    }

    // MARK: - AI Models
    public enum AIModelDownload {
        public static var bannerTitle: LocalizedStringKey { "app.ai.model_download.banner_title" }
        public static var bannerTitleText: String { String(localized: "app.ai.model_download.banner_title", defaultValue: "Natural Voice & Speech Upgrade", bundle: .module) }
        public static var bannerDesc: LocalizedStringKey { "app.ai.model_download.banner_desc" }
        public static var bannerDescText: String {
            String(
                localized: "app.ai.model_download.banner_desc",
                defaultValue: "Download on-device neural voice and speech models (~190MB) for ultra-realistic conversation without rate limits.",
                bundle: .module
            )
        }
        public static var actionDownload: LocalizedStringKey { "app.ai.model_download.action_download" }
        public static var actionDownloadText: String { String(localized: "app.ai.model_download.action_download", defaultValue: "Download", bundle: .module) }
        public static var btnDownload: LocalizedStringKey { "app.ai.model_download.btn_download" }
        public static var btnDownloadText: String { String(localized: "app.ai.model_download.btn_download", defaultValue: "Download AI Pack (~190MB)", bundle: .module) }
        public static var btnLater: LocalizedStringKey { "app.ai.model_download.btn_later" }
        public static var btnLaterText: String { String(localized: "app.ai.model_download.btn_later", defaultValue: "Maybe Later", bundle: .module) }

        public static func statusReady(_ sizeMB: Int) -> String { String(format: String(localized: "app.ai.model_download.status_ready", defaultValue: "~%lldMB (Downloaded)", bundle: .module), sizeMB) }
        public static var statusDownloading: LocalizedStringKey { "app.ai.model_download.status_downloading" }
        public static var statusDownloadingText: String { String(localized: "app.ai.model_download.status_downloading", defaultValue: "Downloading...", bundle: .module) }
        public static var statusError: LocalizedStringKey { "app.ai.model_download.status_error" }
        public static var statusErrorText: String { String(localized: "app.ai.model_download.status_error", defaultValue: "Download Failed", bundle: .module) }
        public static var actionRetry: LocalizedStringKey { "app.ai.model_download.action_retry" }
        public static var actionRetryText: String { String(localized: "app.ai.model_download.action_retry", defaultValue: "Retry", bundle: .module) }
        public static func statusSize(_ sizeMB: Int) -> String { String(format: String(localized: "app.ai.model_download.status_size", defaultValue: "~%lldMB", bundle: .module), sizeMB) }
        public static var kokoroTitle: LocalizedStringKey { "app.ai.model.kokoro_title" }
        public static var kokoroTitleText: String { String(localized: "app.ai.model.kokoro_title", defaultValue: "Kokoro Neural Voice", bundle: .module) }
        public static var kokoroDesc: LocalizedStringKey { "app.ai.model.kokoro_desc" }
        public static var kokoroDescText: String { String(localized: "app.ai.model.kokoro_desc", defaultValue: "Studio-quality on-device neural voice (85MB)", bundle: .module) }
        public static var llamaTitle: LocalizedStringKey { "app.ai.model.llama_title" }
        public static var llamaTitleText: String { String(localized: "app.ai.model.llama_title", defaultValue: "Llama 3.2 1B Reasoning Model", bundle: .module) }
        public static var llamaDesc: LocalizedStringKey { "app.ai.model.llama_desc" }
        public static var llamaDescText: String { String(localized: "app.ai.model.llama_desc", defaultValue: "On-device 4-bit neural language model (~740MB)", bundle: .module) }
    }

}

extension AppStrings.Settings {
    public static var modelsTitle: LocalizedStringKey { "app.settings.models.title" }
    public static var modelsTitleText: String { String(localized: "app.settings.models.title", defaultValue: "On-Device AI Models", bundle: .module) }
    public static var modelsFreeSpace: LocalizedStringKey { "app.settings.models.free_space" }
    public static var modelsFreeSpaceText: String { String(localized: "app.settings.models.free_space", defaultValue: "Free up storage", bundle: .module) }
}

extension AppStrings {
    public static var kokoroTitle: LocalizedStringKey { AIModelDownload.kokoroTitle }
    public static var kokoroTitleText: String { AIModelDownload.kokoroTitleText }
    public static var kokoroDesc: LocalizedStringKey { AIModelDownload.kokoroDesc }
    public static var kokoroDescText: String { AIModelDownload.kokoroDescText }
    public static var llamaTitle: LocalizedStringKey { AIModelDownload.llamaTitle }
    public static var llamaTitleText: String { AIModelDownload.llamaTitleText }
    public static var llamaDesc: LocalizedStringKey { AIModelDownload.llamaDesc }
    public static var llamaDescText: String { AIModelDownload.llamaDescText }
}

// MARK: - Treasure & Learning Path Strings

extension AppStrings {
    // MARK: - Treasure
    public enum Treasure {
        public static var congratsTitle: LocalizedStringKey { "app.treasure.congrats_title" }
        public static var congratsTitleText: String {
            String(localized: "app.treasure.congrats_title", defaultValue: "Unit Mastered!", bundle: .module)
        }

        public static var congratsSubtitle: LocalizedStringKey { "app.treasure.congrats_subtitle" }
        public static var congratsSubtitleText: String {
            String(
                localized: "app.treasure.congrats_subtitle",
                defaultValue: "You have completed all lessons and the checkpoint quiz. Open the chest to claim your milestone reward!",
                bundle: .module
            )
        }

        public static var claimButton: LocalizedStringKey { "app.treasure.claim_button" }
        public static var claimButtonText: String {
            String(localized: "app.treasure.claim_button", defaultValue: "Claim +150 XP", bundle: .module)
        }
        public static var claimReward: LocalizedStringKey { claimButton }
        public static var claimRewardText: String { claimButtonText }

        public static var alreadyClaimed: LocalizedStringKey { "app.treasure.already_claimed" }
        public static var alreadyClaimedText: String {
            String(localized: "app.treasure.already_claimed", defaultValue: "Reward Claimed", bundle: .module)
        }

        public static var checkpointIncompleteError: LocalizedStringKey { "app.treasure.error.checkpoint_incomplete" }
        public static var checkpointIncompleteErrorText: String {
            String(
                localized: "app.treasure.error.checkpoint_incomplete",
                defaultValue: "Checkpoint must be completed before claiming treasure reward.",
                bundle: .module
            )
        }
    }

    // MARK: - Learning Path
    public enum LearningPath {
        public static var switcherTitle: LocalizedStringKey { "app.learning_path.switcher_title" }
        public static var switcherTitleText: String {
            String(localized: "app.learning_path.switcher_title", defaultValue: "Learning Paths", bundle: .module)
        }

        public static var switcherSubtitle: LocalizedStringKey { "app.learning_path.switcher_subtitle" }
        public static var switcherSubtitleText: String {
            String(
                localized: "app.learning_path.switcher_subtitle",
                defaultValue: "Switch paths anytime. All progress is safely preserved.",
                bundle: .module
            )
        }

        public static var activeBadge: LocalizedStringKey { "app.learning_path.active_badge" }
        public static var activeBadgeText: String {
            String(localized: "app.learning_path.active_badge", defaultValue: "Active", bundle: .module)
        }

        public static func progressFormat(completed: Int, total: Int, percent: Int) -> String {
            String(
                format: String(
                    localized: "app.learning_path.progress_format",
                    defaultValue: "%lld of %lld Units completed (%lld%%)",
                    bundle: .module
                ),
                completed,
                total,
                percent
            )
        }

        public static func progressFormatKey(completed: Int, total: Int, percent: Int) -> LocalizedStringKey {
            LocalizedStringKey(progressFormat(completed: completed, total: total, percent: percent))
        }

        public static func progress(completed: Int, total: Int, percent: Int) -> String {
            progressFormat(completed: completed, total: total, percent: percent)
        }

        public static var switchAction: LocalizedStringKey { "app.learning_path.switch_action" }
        public static var switchActionText: String {
            String(localized: "app.learning_path.switch_action", defaultValue: "Switch to this Path", bundle: .module)
        }
    }

    // MARK: - Onboarding
    public enum Onboarding {
        public static var goalTitle: LocalizedStringKey { "app.onboarding.goal.title" }
        public static var goalSubtitle: LocalizedStringKey { "app.onboarding.goal.subtitle" }
        public static var `continue`: LocalizedStringKey { "app.onboarding.common.continue" }
    }

    // MARK: - Milestone Report
    public enum MilestoneReport {
        public static var celebrationTitle: LocalizedStringKey { "app.milestone_report.celebration_title" }
        public static var celebrationTitleText: String {
            String(localized: "app.milestone_report.celebration_title", defaultValue: "Unit Milestone Achieved!", bundle: .module)
        }
        public static func wordsAdded(count: Int) -> String {
            String(format: String(localized: "app.milestone_report.words_added_format", defaultValue: "+%lld Words Added", bundle: .module), count)
        }
        public static func wordsAddedKey(count: Int) -> LocalizedStringKey {
            LocalizedStringKey(wordsAdded(count: count))
        }
        public static var wordsAddedSubtitle: LocalizedStringKey { "app.milestone_report.words_added_subtitle" }
        public static var acquiredWordsTitle: LocalizedStringKey { "app.milestone_report.acquired_words_title" }
        public static var telemetryTitle: LocalizedStringKey { "app.milestone_report.telemetry_title" }
        public static var latencyLabel: LocalizedStringKey { "app.milestone_report.latency_label" }
        public static func latencyValue(seconds: Double) -> String {
            String(format: String(localized: "app.milestone_report.latency_value_format", defaultValue: "%.1fs / word", bundle: .module), seconds)
        }
        public static var retentionLabel: LocalizedStringKey { "app.milestone_report.retention_label" }
        public static func retentionValue(percent: Int) -> String {
            String(format: String(localized: "app.milestone_report.retention_value_format", defaultValue: "%lld%%", bundle: .module), percent)
        }
        public static var wordsMasteredLabel: LocalizedStringKey { "app.milestone_report.words_mastered_label" }
        public static func wordsMasteredValue(count: Int) -> String {
            String(format: String(localized: "app.milestone_report.words_mastered_format", defaultValue: "%lld words", bundle: .module), count)
        }
        public static func cefrProgressTitle(level: String) -> String {
            String(format: String(localized: "app.milestone_report.cefr_progress_title_format", defaultValue: "%@ Competence Progress", bundle: .module), level)
        }
        public static func cefrProgressDetail(current: Int, target: Int, percent: Int) -> String {
            String(format: String(localized: "app.milestone_report.cefr_progress_detail_format", defaultValue: "%lld/%lld Words (%lld%%)", bundle: .module), current, target, percent)
        }
        public static var continueCta: LocalizedStringKey { "app.milestone_report.continue_cta" }
        public static var continueCtaText: String {
            String(localized: "app.milestone_report.continue_cta", defaultValue: "Continue Journey", bundle: .module)
        }
        public static var viewVaultCta: LocalizedStringKey { "app.milestone_report.view_vault_cta" }
        public static var viewVaultCtaText: String {
            String(localized: "app.milestone_report.view_vault_cta", defaultValue: "View in Personal Vault", bundle: .module)
        }
        public static var closeA11y: LocalizedStringKey { "app.milestone_report.close_a11y" }
        public static var listenPronunciationA11y: LocalizedStringKey { "app.milestone_report.listen_pronunciation_a11y" }
    }

    // MARK: - Vocab Growth Dashboard
    public enum VocabGrowth {
        public static var dashboardTitle: LocalizedStringKey { "app.vocab_growth.dashboard_title" }
        public static var dashboardTitleText: String {
            String(localized: "app.vocab_growth.dashboard_title", defaultValue: "Vocabulary Growth", bundle: .module)
        }
        public static var dashboardSubtitle: LocalizedStringKey { "app.vocab_growth.dashboard_subtitle" }
        public static var dashboardSubtitleText: String {
            String(localized: "app.vocab_growth.dashboard_subtitle", defaultValue: "Personal Lexical Expansion & Retention", bundle: .module)
        }
        public static var totalWordsLabel: LocalizedStringKey { "app.vocab_growth.total_words_label" }
        public static var estimatedCompetenceLabel: LocalizedStringKey { "app.vocab_growth.estimated_competence_label" }
        public static var retentionHealthLabel: LocalizedStringKey { "app.vocab_growth.retention_health_label" }
        public static func retentionHealthValue(percent: Int) -> String {
            String(format: String(localized: "app.vocab_growth.retention_health_format", defaultValue: "%lld%% Healthy", bundle: .module), percent)
        }
        public static var cefrLadderTitle: LocalizedStringKey { "app.vocab_growth.cefr_ladder_title" }
        public static var cefrLadderSubtitle: LocalizedStringKey { "app.vocab_growth.cefr_ladder_subtitle" }
        public static func cefrStatRatio(acquired: Int, target: Int, percent: Int) -> String {
            String(format: String(localized: "app.vocab_growth.cefr_stat_ratio_format", defaultValue: "%lld/%lld Words (%lld%%)", bundle: .module), acquired, target, percent)
        }
        public static var depthFunnelTitle: LocalizedStringKey { "app.vocab_growth.depth_funnel_title" }
        public static var depthFunnelSubtitle: LocalizedStringKey { "app.vocab_growth.depth_funnel_subtitle" }
        public static var tierEncounteredTitle: LocalizedStringKey { "app.vocab_growth.tier_encountered_title" }
        public static var tierEncounteredDesc: LocalizedStringKey { "app.vocab_growth.tier_encountered_desc" }
        public static var tierConsolidatingTitle: LocalizedStringKey { "app.vocab_growth.tier_consolidating_title" }
        public static var tierConsolidatingDesc: LocalizedStringKey { "app.vocab_growth.tier_consolidating_desc" }
        public static var tierMasteredTitle: LocalizedStringKey { "app.vocab_growth.tier_mastered_title" }
        public static var tierMasteredDesc: LocalizedStringKey { "app.vocab_growth.tier_mastered_desc" }
        public static var pacingTitle: LocalizedStringKey { "app.vocab_growth.pacing_title" }
        public static var pacingSubtitle: LocalizedStringKey { "app.vocab_growth.pacing_subtitle" }
        public static func pacingPredictionText(pace: Int, level: String, date: String) -> String {
            String(format: String(localized: "app.vocab_growth.pacing_prediction_format", defaultValue: "At %lld words/day, you will complete %@ on %@.", bundle: .module), pace, level, date)
        }
        public static var pacingAllCompletedText: String {
            String(localized: "app.vocab_growth.pacing_all_completed", defaultValue: "You have reached all standard CEFR vocabulary milestones!", bundle: .module)
        }
        public static func wordsCount(count: Int) -> String {
            String(format: String(localized: "app.vocab_growth.words_count_format", defaultValue: "%lld words", bundle: .module), count)
        }
        public static func headerPill(words: Int, level: String) -> String {
            String(format: String(localized: "app.vocab_growth.header_pill_format", defaultValue: "%lld words • %@", bundle: .module), words, level)
        }
        public static func headerPillA11y(words: Int, level: String) -> String {
            String(format: String(localized: "app.vocab_growth.header_pill_a11y_format", defaultValue: "Vocabulary: %lld words acquired, CEFR level %@", bundle: .module), words, level)
        }
        public static var headerPillHint: LocalizedStringKey { "app.vocab_growth.header_pill_hint" }
        public static var headerPillHintText: String {
            String(localized: "app.vocab_growth.header_pill_hint", defaultValue: "Tap to view vocabulary growth dashboard", bundle: .module)
        }
    }
}
