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
        public static var voiceSpeed: LocalizedStringKey { "app.settings.voice.speed" }
        public static var voiceSpeedText: String { String(localized: "app.settings.voice.speed", defaultValue: "Voice Speed", bundle: .module) }
        public static var voicePitch: LocalizedStringKey { "app.settings.voice.pitch" }
        public static var voicePitchText: String { String(localized: "app.settings.voice.pitch", defaultValue: "Voice Pitch", bundle: .module) }
        public static var voiceQualityApple: LocalizedStringKey { "app.settings.voice.quality_apple" }
        public static var voiceQualityAppleText: String { String(localized: "app.settings.voice.quality_apple", defaultValue: "Device Enhanced", bundle: .module) }
        public static var voiceQualityGemini: LocalizedStringKey { "app.settings.voice.quality_gemini" }
        public static var voiceQualityGeminiText: String { String(localized: "app.settings.voice.quality_gemini", defaultValue: "Cloud Studio Neural", bundle: .module) }

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

    // MARK: - AI Assistant View
    public enum AIAssistant {
        public static var title: LocalizedStringKey { "app.ai_assistant.title" }
        public static var titleText: String { String(localized: "app.ai_assistant.title", defaultValue: "AI Assistant", bundle: .module) }
        public static var badgeComingSoon: LocalizedStringKey { "app.ai_assistant.badge_coming_soon" }
        public static var badgeComingSoonText: String { String(localized: "app.ai_assistant.badge_coming_soon", defaultValue: "COMING SOON", bundle: .module) }
        public static var heroTitle: LocalizedStringKey { "app.ai_assistant.hero_title" }
        public static var heroTitleText: String { String(localized: "app.ai_assistant.hero_title", defaultValue: "VocabCraft AI Copilot", bundle: .module) }
        public static var heroDescription: LocalizedStringKey { "app.ai_assistant.hero_desc" }
        public static var heroDescriptionText: String {
            let defaultText = "Your personalized AI language tutor. Conversational drills, contextual feedback, and instant pronunciation analysis powered by next-gen on-device models."
            return String(localized: "app.ai_assistant.hero_desc", defaultValue: String.LocalizationValue(defaultText), bundle: .module)
        }
        public static var upcomingFeaturesTitle: LocalizedStringKey { "app.ai_assistant.upcoming_features_title" }
        public static var upcomingFeaturesTitleText: String { String(localized: "app.ai_assistant.upcoming_features_title", defaultValue: "Upcoming Capabilities", bundle: .module) }
        public static var featureConversationTitle: LocalizedStringKey { "app.ai_assistant.feature_conversation_title" }
        public static var featureConversationDescription: LocalizedStringKey { "app.ai_assistant.feature_conversation_desc" }
        public static var featureContextTitle: LocalizedStringKey { "app.ai_assistant.feature_context_title" }
        public static var featureContextDescription: LocalizedStringKey { "app.ai_assistant.feature_context_desc" }
        public static var featurePronunciationTitle: LocalizedStringKey { "app.ai_assistant.feature_pronunciation_title" }
        public static var featurePronunciationDescription: LocalizedStringKey { "app.ai_assistant.feature_pronunciation_desc" }

        // Roleplay Hub & Room
        public static var hubTitle: LocalizedStringKey { "app.ai_assistant.hub.title" }
        public static var hubTitleText: String { String(localized: "app.ai_assistant.hub.title", defaultValue: "AI Assistant", bundle: .module) }
        public static var hubSubtitle: LocalizedStringKey { "app.ai_assistant.hub.subtitle" }
        public static var hubSubtitleText: String { String(localized: "app.ai_assistant.hub.subtitle", defaultValue: "Master active speaking through interactive roleplay", bundle: .module) }
        public static var dailyMissionBadge: LocalizedStringKey { "app.ai_assistant.hub.daily_mission_badge" }
        public static var dailyMissionBadgeText: String { String(localized: "app.ai_assistant.hub.daily_mission_badge", defaultValue: "Daily Recommended Scenario", bundle: .module) }
        public static var actionStartRoleplay: LocalizedStringKey { "app.ai_assistant.hub.action_start_roleplay" }
        public static var actionStartRoleplayText: String { String(localized: "app.ai_assistant.hub.action_start_roleplay", defaultValue: "Start Roleplay", bundle: .module) }
        public static var configureApiKey: LocalizedStringKey { "app.ai_assistant.hub.configure_api_key" }
        public static var configureApiKeyText: String { String(localized: "app.ai_assistant.hub.configure_api_key", defaultValue: "Configure API Key", bundle: .module) }
        public static var apiKeySheetTitle: LocalizedStringKey { "app.ai_assistant.hub.api_key_sheet_title" }
        public static var apiKeySheetTitleText: String { String(localized: "app.ai_assistant.hub.api_key_sheet_title", defaultValue: "Gemini API Setup", bundle: .module) }
        public static var apiKeyBannerDesc: LocalizedStringKey { "app.ai_assistant.hub.api_key_banner_desc" }
        public static var apiKeyBannerDescText: String {
            String(localized: "app.ai_assistant.hub.api_key_banner_desc", defaultValue: "Add your Gemini API key to unlock natural AI roleplay conversations and feedback.", bundle: .module)
        }
        public static var targetWordsTitle: LocalizedStringKey { "app.ai_assistant.room.target_words_title" }
        public static var targetWordsTitleText: String { String(localized: "app.ai_assistant.room.target_words_title", defaultValue: "Target Words", bundle: .module) }
        public static var refineSuggestionButton: LocalizedStringKey { "app.ai_assistant.room.refine_button" }
        public static var refineSuggestionButtonText: String { String(localized: "app.ai_assistant.room.refine_button", defaultValue: "💡 See natural phrasing", bundle: .module) }
        public static var actionFinishSession: LocalizedStringKey { "app.ai_assistant.room.action_finish" }
        public static var actionFinishSessionText: String { String(localized: "app.ai_assistant.room.action_finish", defaultValue: "Finish", bundle: .module) }
        public static var discardConfirmTitle: LocalizedStringKey { "app.ai_assistant.room.discard_title" }
        public static var discardConfirmTitleText: String { String(localized: "app.ai_assistant.room.discard_title", defaultValue: "Leave Roleplay?", bundle: .module) }
        public static var discardConfirmMessage: LocalizedStringKey { "app.ai_assistant.room.discard_message" }
        public static var discardConfirmMessageText: String { String(localized: "app.ai_assistant.room.discard_message", defaultValue: "Your current conversation progress will not be saved.", bundle: .module) }
        public static var summaryCongratulations: LocalizedStringKey { "app.ai_assistant.summary.congratulations" }
        public static var summaryCongratulationsText: String { String(localized: "app.ai_assistant.summary.congratulations", defaultValue: "Roleplay Completed!", bundle: .module) }
        public static var summaryFluencyScore: LocalizedStringKey { "app.ai_assistant.summary.fluency_score" }
        public static var summaryFluencyScoreText: String { String(localized: "app.ai_assistant.summary.fluency_score", defaultValue: "Fluency Score", bundle: .module) }
        public static var summaryMasteredWords: LocalizedStringKey { "app.ai.summary.mastered_words" }
        public static var summaryMasteredWordsText: String { String(localized: "app.ai.summary.mastered_words", defaultValue: "Mastered in conversation", bundle: .module) }
        public static var summaryUnmasteredWords: LocalizedStringKey { "app.ai.summary.unmastered_words" }
        public static var summaryUnmasteredWordsText: String { String(localized: "app.ai.summary.unmastered_words", defaultValue: "Needs more practice", bundle: .module) }
        public static var summarySaveToVault: LocalizedStringKey { "app.ai.summary.save_to_vault" }
        public static var summarySaveToVaultText: String { String(localized: "app.ai.summary.save_to_vault", defaultValue: "Save to Personal Vault", bundle: .module) }
        public static var summaryActionReflex: LocalizedStringKey { "app.ai.summary.action_reflex" }
        public static var summaryActionReflexText: String { String(localized: "app.ai.summary.action_reflex", defaultValue: "Drill weak words in Reflex (60s)", bundle: .module) }

        // MARK: - Warm Companion & Hybrid Engine (Layer 2: app.ai.*)
        public static var engineOnDevice: LocalizedStringKey { "app.ai.hub.engine.on_device" }
        public static var engineOnDeviceText: String { String(localized: "app.ai.hub.engine.on_device", defaultValue: "On-Device (Local)", bundle: .module) }
        public static var engineCloud: LocalizedStringKey { "app.ai.hub.engine.cloud" }
        public static var engineCloudText: String { String(localized: "app.ai.hub.engine.cloud", defaultValue: "Cloud Active", bundle: .module) }
        public static var companionBadge: LocalizedStringKey { "app.ai.hub.companion.badge" }
        public static var companionBadgeText: String { String(localized: "app.ai.hub.companion.badge", defaultValue: "Daily Companion", bundle: .module) }
        public static var companionStartCall: LocalizedStringKey { "app.ai.hub.companion.start_call" }
        public static var companionStartCallText: String { String(localized: "app.ai.hub.companion.start_call", defaultValue: "Quick Voice Practice (2m)", bundle: .module) }
        public static var companionStartChat: LocalizedStringKey { "app.ai.hub.companion.start_chat" }
        public static var companionStartChatText: String { String(localized: "app.ai.hub.companion.start_chat", defaultValue: "Text Roleplay", bundle: .module) }
        public static var companionGreetingFormat: String {
            String(localized: "app.ai.hub.companion.greeting_format", defaultValue: "Hi there! You've learned %lld new words today. Let's practice for 2 minutes to turn vocabulary into reflex!", bundle: .module)
        }
        public static func companionGreeting(wordsCount: Int) -> String { String(format: companionGreetingFormat, wordsCount) }
        public static func companionGreetingKey(wordsCount: Int) -> LocalizedStringKey {
            LocalizedStringKey("app.ai.hub.companion.greeting_format \(wordsCount)")
        }
        public static var scenarioSectionTitle: LocalizedStringKey { "app.ai.hub.scenarios.title" }
        public static var scenarioSectionTitleText: String { String(localized: "app.ai.hub.scenarios.title", defaultValue: "Topic Scenarios", bundle: .module) }
        public static var starterChipsTitle: LocalizedStringKey { "app.ai.chat.starter_chips_title" }
        public static var starterChipsTitleText: String { String(localized: "app.ai.chat.starter_chips_title", defaultValue: "Sentence Starters", bundle: .module) }
        public static var callLiveBadge: LocalizedStringKey { "app.ai.call.live_badge" }
        public static var callLiveBadgeText: String { String(localized: "app.ai.call.live_badge", defaultValue: "Live Call", bundle: .module) }
        public static var callMicMute: LocalizedStringKey { "app.ai.call.mic_mute" }
        public static var callMicMuteText: String { String(localized: "app.ai.call.mic_mute", defaultValue: "Mute microphone", bundle: .module) }
        public static var callMicUnmute: LocalizedStringKey { "app.ai.call.mic_unmute" }
        public static var callMicUnmuteText: String { String(localized: "app.ai.call.mic_unmute", defaultValue: "Unmute microphone", bundle: .module) }
        public static var callSuggestedPreview: LocalizedStringKey { "app.ai.call.suggested_preview" }
        public static var callSuggestedPreviewText: String { String(localized: "app.ai.call.suggested_preview", defaultValue: "Listen example", bundle: .module) }
        public static var chatRefinePrefix: LocalizedStringKey { "app.ai.chat.refine_prefix" }
        public static var chatRefinePrefixText: String { String(localized: "app.ai.chat.refine_prefix", defaultValue: "Natural way to say:", bundle: .module) }
        public static var summaryTakeawaysTitle: LocalizedStringKey { "app.ai_assistant.summary.takeaways_title" }
        public static var summaryTakeawaysTitleText: String { String(localized: "app.ai_assistant.summary.takeaways_title", defaultValue: "Refined Phrasing Takeaways", bundle: .module) }
        public static var actionDone: LocalizedStringKey { "app.ai_assistant.summary.action_done" }
        public static var actionDoneText: String { String(localized: "app.ai_assistant.summary.action_done", defaultValue: "Back to Hub", bundle: .module) }
        public static var fallbackReply: LocalizedStringKey { "app.ai_assistant.room.fallback_reply" }
        public static var fallbackReplyText: String { String(localized: "app.ai_assistant.room.fallback_reply", defaultValue: "I see! Please go on.", bundle: .module) }
        public static var inputPlaceholder: LocalizedStringKey { LocalizedStringKey("app.ai_assistant.room.input_placeholder") }
        public static var inputPlaceholderText: String { String(localized: "app.ai_assistant.room.input_placeholder", defaultValue: "Type a message...", bundle: .module) }
        public static var audioPlayButton: LocalizedStringKey { "app.ai_assistant.room.play_audio" }
        public static var audioPlayButtonText: String { String(localized: "app.ai_assistant.room.play_audio", defaultValue: "Play dialogue audio", bundle: .module) }
        public static var suggestionsHeader: LocalizedStringKey { "app.ai_assistant.room.suggestions_header" }
        public static var suggestionsHeaderText: String { String(localized: "app.ai_assistant.room.suggestions_header", defaultValue: "Suggested Responses", bundle: .module) }
        public static var voicePickerTitle: LocalizedStringKey { "app.ai_assistant.room.voice_picker_title" }
        public static var voicePickerTitleText: String { String(localized: "app.ai_assistant.room.voice_picker_title", defaultValue: "Select AI Voice", bundle: .module) }
        public static var selectVoiceTitle: LocalizedStringKey { voicePickerTitle }
        public static var selectVoiceTitleText: String { voicePickerTitleText }

        // Topics
        public static var topicAll: LocalizedStringKey { "app.ai_assistant.topic.all" }
        public static var topicDailyLife: LocalizedStringKey { "app.ai_assistant.topic.daily_life" }
        public static var topicDining: LocalizedStringKey { "app.ai_assistant.topic.dining" }
        public static var topicInterview: LocalizedStringKey { "app.ai_assistant.topic.interview" }
        public static var topicTravel: LocalizedStringKey { "app.ai_assistant.topic.travel" }
        public static var topicWorkplace: LocalizedStringKey { "app.ai_assistant.topic.workplace" }

        // Voice Call Screen
        public static var startVoiceCall: LocalizedStringKey { "app.ai_assistant.call.start_call" }
        public static var startVoiceCallText: String { String(localized: "app.ai_assistant.call.start_call", defaultValue: "Start Voice Call", bundle: .module) }
        public static var callActiveBadge: LocalizedStringKey { "app.ai_assistant.call.active_badge" }
        public static var callActiveBadgeText: String { String(localized: "app.ai_assistant.call.active_badge", defaultValue: "Live Call", bundle: .module) }
        public static var stateIdle: LocalizedStringKey { "app.ai_assistant.call.state_idle" }
        public static var stateIdleText: String { String(localized: "app.ai_assistant.call.state_idle", defaultValue: "Connecting...", bundle: .module) }
        public static var stateSpeaking: LocalizedStringKey { "app.ai_assistant.call.state_speaking" }
        public static var stateSpeakingText: String { String(localized: "app.ai_assistant.call.state_speaking", defaultValue: "Speaking...", bundle: .module) }
        public static var stateListening: LocalizedStringKey { "app.ai_assistant.call.state_listening" }
        public static var stateListeningText: String { String(localized: "app.ai_assistant.call.state_listening", defaultValue: "Listening...", bundle: .module) }
        public static var stateThinking: LocalizedStringKey { "app.ai_assistant.call.state_thinking" }
        public static var stateThinkingText: String { String(localized: "app.ai_assistant.call.state_thinking", defaultValue: "Thinking...", bundle: .module) }
        public static var stateEnded: LocalizedStringKey { "app.ai_assistant.call.state_ended" }
        public static var stateEndedText: String { String(localized: "app.ai_assistant.call.state_ended", defaultValue: "Call Ended", bundle: .module) }
        public static var toggleCaptions: LocalizedStringKey { "app.ai_assistant.call.toggle_captions" }
        public static var toggleCaptionsText: String { String(localized: "app.ai_assistant.call.toggle_captions", defaultValue: "Toggle captions", bundle: .module) }
        public static var muteMicrophone: LocalizedStringKey { "app.ai_assistant.call.mute_microphone" }
        public static var muteMicrophoneText: String { String(localized: "app.ai_assistant.call.mute_microphone", defaultValue: "Mute microphone", bundle: .module) }
        public static var unmuteMicrophone: LocalizedStringKey { "app.ai_assistant.call.unmute_microphone" }
        public static var unmuteMicrophoneText: String { String(localized: "app.ai_assistant.call.unmute_microphone", defaultValue: "Unmute microphone", bundle: .module) }
        public static var endCall: LocalizedStringKey { "app.ai_assistant.call.end_call" }
        public static var endCallText: String { String(localized: "app.ai_assistant.call.end_call", defaultValue: "End call", bundle: .module) }
        public static var finishTurn: LocalizedStringKey { "app.ai_assistant.call.finish_turn" }
        public static var finishTurnText: String { String(localized: "app.ai_assistant.call.finish_turn", defaultValue: "Tap when finished speaking", bundle: .module) }
        public static var permissionTitle: LocalizedStringKey { "app.ai_assistant.call.permission_title" }
        public static var permissionTitleText: String { String(localized: "app.ai_assistant.call.permission_title", defaultValue: "Microphone & Speech Permission", bundle: .module) }
        public static var permissionMessage: LocalizedStringKey { "app.ai_assistant.call.permission_message" }
        public static var permissionMessageText: String {
            String(localized: "app.ai_assistant.call.permission_message",
                   defaultValue: "VocabCraft needs microphone access for interactive voice roleplay.", bundle: .module)
        }
        public static var openSettings: LocalizedStringKey { "app.ai_assistant.call.open_settings" }
        public static var openSettingsText: String { String(localized: "app.ai_assistant.call.open_settings", defaultValue: "Open Settings", bundle: .module) }
        public static var retry: LocalizedStringKey { "app.ai_assistant.call.retry" }
        public static var retryText: String { String(localized: "app.ai_assistant.call.retry", defaultValue: "Retry", bundle: .module) }
        public static var speakPrompt: LocalizedStringKey { "app.ai_assistant.call.speak_prompt" }
        public static var speakPromptText: String { String(localized: "app.ai_assistant.call.speak_prompt", defaultValue: "Speak into the microphone...", bundle: .module) }

        // Conversational Scaffolding Hints
        public static var speakingHintsButton: LocalizedStringKey { "app.ai_assistant.speaking_hints_button" }
        public static var speakingHintsButtonText: String { String(localized: "app.ai_assistant.speaking_hints_button", defaultValue: "💡 Suggested responses", bundle: .module) }
        public static var speakingHintsTitle: LocalizedStringKey { "app.ai_assistant.speaking_hints_title" }
        public static var speakingHintsTitleText: String { String(localized: "app.ai_assistant.speaking_hints_title", defaultValue: "Suggested responses", bundle: .module) }
        public static var listenSample: LocalizedStringKey { "app.ai_assistant.listen_sample" }
        public static var listenSampleText: String { String(localized: "app.ai_assistant.listen_sample", defaultValue: "Listen to sample", bundle: .module) }
    }

    // MARK: - Speaking AI Call Strings
    public enum AICall {
        public static var activeBadge: LocalizedStringKey { "app.ai_call.active_badge" }
        public static var activeBadgeText: String { String(localized: "app.ai_call.active_badge", defaultValue: "Live Call", bundle: .module) }
        public static var suggestedTitle: LocalizedStringKey { "app.ai_call.suggested_title" }
        public static var suggestedTitleText: String { String(localized: "app.ai_call.suggested_title", defaultValue: "Suggested Responses", bundle: .module) }
        public static var suggestedToggle: LocalizedStringKey { "app.ai_call.suggested_toggle" }
        public static var suggestedToggleText: String { String(localized: "app.ai_call.suggested_toggle", defaultValue: "Suggested responses (%lld)", bundle: .module) }
        public static func suggestedToggle(_ count: Int) -> LocalizedStringKey { LocalizedStringKey("app.ai_call.suggested_toggle \(count)") }
        public static func suggestedToggleText(_ count: Int) -> String {
            String(format: String(localized: "app.ai_call.suggested_toggle", defaultValue: "Suggested responses (%lld)", bundle: .module), count)
        }
        public static var listenSample: LocalizedStringKey { "app.ai_call.listen_sample" }
        public static var listenSampleText: String { String(localized: "app.ai_call.listen_sample", defaultValue: "Listen to sample pronunciation", bundle: .module) }
        public static var finishSpeaking: LocalizedStringKey { "app.ai_call.finish_speaking" }
        public static var finishSpeakingText: String { String(localized: "app.ai_call.finish_speaking", defaultValue: "Tap when finished speaking", bundle: .module) }
        public static var micMuted: LocalizedStringKey { "app.ai_call.mic_muted" }
        public static var micMutedText: String { String(localized: "app.ai_call.mic_muted", defaultValue: "Microphone muted", bundle: .module) }
        public static var listeningPrompt: LocalizedStringKey { "app.ai_call.listening_prompt" }
        public static var listeningPromptText: String { String(localized: "app.ai_call.listening_prompt", defaultValue: "Speak into the microphone...", bundle: .module) }
        public static var retryListening: LocalizedStringKey { "app.ai_call.retry_listening" }
        public static var retryListeningText: String { String(localized: "app.ai_call.retry_listening", defaultValue: "Tap to retry microphone", bundle: .module) }
    }

    // MARK: - Home Learning Path
    public enum Home {
        // Header
        public static var title: LocalizedStringKey { "app.home.title" }
        public static var titleText: String {
            String(localized: "app.home.title", defaultValue: "Home", bundle: .module)
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
        public static var ctaCheckpoint: LocalizedStringKey { "app.home.node.cta_checkpoint" }
        public static var ctaCheckpointText: String {
            String(localized: "app.home.node.cta_checkpoint", defaultValue: "Start Boss Exam", bundle: .module)
        }
        public static var lockedHint: LocalizedStringKey { "app.home.node.locked_hint" }
        public static var lockedHintText: String {
            String(localized: "app.home.node.locked_hint", defaultValue: "Complete previous lessons to unlock", bundle: .module)
        }
    }

    // MARK: - Widget
    public enum Widget {
        public static var displayName: LocalizedStringKey { "app.widget.display_name" }
        public static var displayNameText: String { String(localized: "app.widget.display_name", defaultValue: "VocabCraft Reflex Widget", bundle: .module) }
        public static var description: LocalizedStringKey { "app.widget.description" }
        public static var descriptionText: String { String(localized: "app.widget.description", defaultValue: "Learn vocabulary and reflex patterns continuously on your Home Screen.", bundle: .module) }
        public static var next: LocalizedStringKey { "app.widget.next" }
        public static var nextText: String { String(localized: "app.widget.next", defaultValue: "Next", bundle: .module) }
        public static var mastered: LocalizedStringKey { "app.widget.mastered" }
        public static var masteredText: String { String(localized: "app.widget.mastered", defaultValue: "Mastered", bundle: .module) }
        public static func level(_ level: Int) -> LocalizedStringKey {
            LocalizedStringKey(levelText(level))
        }
        public static func levelText(_ level: Int) -> String {
            String(format: String(localized: "app.widget.level_format", defaultValue: "Level %lld", bundle: .module), level)
        }
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
        public static var btnDownload: LocalizedStringKey { "app.ai.model_download.btn_download" }
        public static var btnDownloadText: String { String(localized: "app.ai.model_download.btn_download", defaultValue: "Download AI Pack (~190MB)", bundle: .module) }
        public static var btnLater: LocalizedStringKey { "app.ai.model_download.btn_later" }
        public static var btnLaterText: String { String(localized: "app.ai.model_download.btn_later", defaultValue: "Maybe Later", bundle: .module) }

        public static func statusReady(_ sizeMB: Int) -> String { String(format: String(localized: "app.ai.model_download.status_ready", defaultValue: "~%lldMB (Downloaded)", bundle: .module), sizeMB) }
        public static var statusDownloading: LocalizedStringKey { "app.ai.model_download.status_downloading" }
        public static var statusDownloadingText: String { String(localized: "app.ai.model_download.status_downloading", defaultValue: "Downloading...", bundle: .module) }
        public static func statusSize(_ sizeMB: Int) -> String { String(format: String(localized: "app.ai.model_download.status_size", defaultValue: "~%lldMB", bundle: .module), sizeMB) }
    }
}

extension AppStrings.Settings {
    public static var modelsTitle: LocalizedStringKey { "app.settings.models.title" }
    public static var modelsTitleText: String { String(localized: "app.settings.models.title", defaultValue: "On-Device AI Models", bundle: .module) }
    public static var modelsFreeSpace: LocalizedStringKey { "app.settings.models.free_space" }
    public static var modelsFreeSpaceText: String { String(localized: "app.settings.models.free_space", defaultValue: "Free up storage", bundle: .module) }
}
