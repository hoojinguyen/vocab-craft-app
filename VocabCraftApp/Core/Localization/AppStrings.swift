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
        public static var delete: LocalizedStringKey { "common.delete" }
        public static var `continue`: LocalizedStringKey { "common.continue" }
        public static var skip: LocalizedStringKey { "common.skip" }
        public static var understand: LocalizedStringKey { "common.understand" }
    }

    // MARK: - Tab Bar Titles
    public enum Tabs {
        public static var home: LocalizedStringKey { "tabs.home" }
        public static var vocabulary: LocalizedStringKey { "tabs.vocabulary" }
        public static var search: LocalizedStringKey { "tabs.search" }
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
        public static var searchPlaceholder: LocalizedStringKey { "homepage.searchPlaceholder" }
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
        public static var sectionLearningSRS: LocalizedStringKey { "settings.sectionLearningSRS" }
        public static var sectionAudioTTS: LocalizedStringKey { "settings.sectionAudioTTS" }
        public static var sectionAppearance: LocalizedStringKey { "settings.sectionAppearance" }
        public static var sectionLanguage: LocalizedStringKey { "settings.sectionLanguage" }
        public static var sectionAppData: LocalizedStringKey { "settings.sectionAppData" }
        public static var dailyGoal: LocalizedStringKey { "settings.dailyGoal" }
        public static var reminderNotification: LocalizedStringKey { "settings.reminderNotification" }
        public static var reminderTime: LocalizedStringKey { "settings.reminderTime" }
        public static var resetSRS: LocalizedStringKey { "settings.resetSRS" }
        public static var resetSRSSubtitle: LocalizedStringKey { "settings.resetSRSSubtitle" }
        public static var englishVoice: LocalizedStringKey { "settings.englishVoice" }
        public static var speechSpeed: LocalizedStringKey { "settings.speechSpeed" }
        public static var testTTS: LocalizedStringKey { "settings.testTTS" }
        public static var playingAudio: LocalizedStringKey { "settings.playingAudio" }
        public static var appTheme: LocalizedStringKey { "settings.appTheme" }
        public static var themeDark: LocalizedStringKey { "settings.themeDark" }
        public static var themeLight: LocalizedStringKey { "settings.themeLight" }
        public static var themeSystem: LocalizedStringKey { "settings.themeSystem" }
        public static var haptics: LocalizedStringKey { "settings.haptics" }
        public static var soundEffects: LocalizedStringKey { "settings.soundEffects" }
        public static var appLanguage: LocalizedStringKey { "settings.appLanguage" }
        public static var langSystem: LocalizedStringKey { "settings.langSystem" }
        public static var langVietnamese: LocalizedStringKey { "settings.langVietnamese" }
        public static var langEnglish: LocalizedStringKey { "settings.langEnglish" }
        public static var icloudSync: LocalizedStringKey { "settings.icloudSync" }
        public static var synced: LocalizedStringKey { "settings.synced" }
        public static var clearCache: LocalizedStringKey { "settings.clearCache" }
        public static var appVersion: LocalizedStringKey { "settings.appVersion" }
        public static var inputGoalTitle: LocalizedStringKey { "settings.inputGoalTitle" }
        public static var inputGoalMessage: LocalizedStringKey { "settings.inputGoalMessage" }
        public static var resetConfirmTitle: LocalizedStringKey { "settings.resetConfirmTitle" }
        public static var resetConfirmMessage: LocalizedStringKey { "settings.resetConfirmMessage" }
        public static var profileBadge: LocalizedStringKey { "settings.profileBadge" }
        public static var voiceUS: LocalizedStringKey { "settings.voiceUS" }
        public static var voiceUK: LocalizedStringKey { "settings.voiceUK" }
        public static var sectionDeveloper: LocalizedStringKey { "settings.sectionDeveloper" }
        public static var craftCatalog: LocalizedStringKey { "settings.craftCatalog" }
        public static var craftCatalogSubtitle: LocalizedStringKey { "settings.craftCatalogSubtitle" }
    }

    // MARK: - Search View
    public enum Search {
        public static var upcomingFeatureTitle: LocalizedStringKey { "search.upcomingFeatureTitle" }
        public static var smartLookupTitle: LocalizedStringKey { "search.smartLookupTitle" }
        public static var smartLookupDescription: LocalizedStringKey { "search.smartLookupDescription" }
        public static var recentSearchesTitle: LocalizedStringKey { "search.recentSearchesTitle" }
        public static var suggestedTopicsTitle: LocalizedStringKey { "search.suggestedTopicsTitle" }
        public static var placeholder: LocalizedStringKey { "search.placeholder" }
    }

    // MARK: - Home Learning Path
    public enum Home {
        // Header
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
        public static var checkpointTitle: LocalizedStringKey { "app.home.section.checkpoint_title" }
        public static var checkpointTitleText: String {
            String(localized: "app.home.section.checkpoint_title", defaultValue: "Unit Review Exam", bundle: .module)
        }
        public static var checkpointSubtitle: LocalizedStringKey { "app.home.section.checkpoint_subtitle" }
        public static var checkpointSubtitleText: String {
            String(localized: "app.home.section.checkpoint_subtitle", defaultValue: "Comprehensive exam covering all unit words", bundle: .module)
        }

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
}

// MARK: - Vocabulary Vault Extension
extension AppStrings {
    public enum Vault {
        public static var title: LocalizedStringKey { "app.vault.title" }
        public static var titleText: String {
            String(localized: "app.vault.title", defaultValue: "Kho Từ", bundle: .module)
        }
        public static var searchPlaceholder: LocalizedStringKey { "app.vault.search_placeholder" }
        public static var searchPlaceholderText: String {
            String(localized: "app.vault.search_placeholder", defaultValue: "Tìm kiếm từ vựng...", bundle: .module)
        }
        public static var filterNotMasteredTitle: String {
            String(localized: "app.vault.filter.not_mastered_title", defaultValue: "Chưa thuộc", bundle: .module)
        }
        public static var filterMasteredTitle: String {
            String(localized: "app.vault.filter.mastered_title", defaultValue: "Đã thuộc", bundle: .module)
        }
        public static var filterBookmarkedTitle: String {
            String(localized: "app.vault.filter.bookmarked_title", defaultValue: "Đã lưu", bundle: .module)
        }
        public static func filterNotMastered(_ count: Int) -> String {
            String(format: String(localized: "app.vault.filter.not_mastered", defaultValue: "Chưa thuộc (%lld)", bundle: .module), count)
        }
        public static func filterMastered(_ count: Int) -> String {
            String(format: String(localized: "app.vault.filter.mastered", defaultValue: "Đã thuộc (%lld)", bundle: .module), count)
        }
        public static func filterBookmarked(_ count: Int) -> String {
            String(format: String(localized: "app.vault.filter.bookmarked", defaultValue: "Đã lưu (%lld)", bundle: .module), count)
        }
        public static var actionPractice: LocalizedStringKey { "app.vault.action.review_words" }
        public static var actionPracticeText: String {
            String(localized: "app.vault.action.review_words", defaultValue: "LUYỆN TẬP", bundle: .module)
        }
        public static func actionReviewWords(_ count: Int = 0) -> String {
            actionPracticeText
        }
        public static func actionPracticeWords(_ count: Int = 0) -> String {
            actionPracticeText
        }
        public static var emptyNotMastered: LocalizedStringKey { "app.vault.empty.not_mastered" }
        public static var emptyNotMasteredText: String {
            String(localized: "app.vault.empty.not_mastered", defaultValue: "Bạn không có từ nào chưa thuộc", bundle: .module)
        }
        public static var emptyMastered: LocalizedStringKey { "app.vault.empty.mastered" }
        public static var emptyMasteredText: String {
            String(localized: "app.vault.empty.mastered", defaultValue: "Chưa có từ nào đạt mức thành thạo", bundle: .module)
        }
        public static var emptyBookmarked: LocalizedStringKey { "app.vault.empty.bookmarked" }
        public static var emptyBookmarkedText: String {
            String(localized: "app.vault.empty.bookmarked", defaultValue: "Chưa có từ nào được lưu", bundle: .module)
        }
        public static var emptySearchNoResults: LocalizedStringKey { "app.vault.empty.search_no_results" }
        public static var emptySearchNoResultsText: String {
            String(localized: "app.vault.empty.search_no_results", defaultValue: "Không tìm thấy từ nào phù hợp", bundle: .module)
        }
        public static var detailDefinitionsTitle: LocalizedStringKey { "app.vault.detail.definitions_title" }
        public static var detailDefinitionsTitleText: String {
            String(localized: "app.vault.detail.definitions_title", defaultValue: "Định nghĩa", bundle: .module)
        }
        public static var detailExamplesTitle: LocalizedStringKey { "app.vault.detail.examples_title" }
        public static var detailExamplesTitleText: String {
            String(localized: "app.vault.detail.examples_title", defaultValue: "Ví dụ thực tế", bundle: .module)
        }
        public static var detailProgressTitle: LocalizedStringKey { "app.vault.detail.progress_title" }
        public static var detailProgressTitleText: String {
            String(localized: "app.vault.detail.progress_title", defaultValue: "Tiến độ phản xạ", bundle: .module)
        }
        public static func detailStreakCount(_ count: Int) -> String {
            String(format: String(localized: "app.vault.detail.streak_count", defaultValue: "Chuỗi đúng %lld", bundle: .module), count)
        }
        public static var detailPracticedModes: LocalizedStringKey { "app.vault.detail.practiced_modes" }
        public static var detailPracticedModesText: String {
            String(localized: "app.vault.detail.practiced_modes", defaultValue: "Chế độ đã luyện", bundle: .module)
        }
    }
}

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
            String(format: String(localized: "app.reflex.stats.weak_words", defaultValue: "%lld từ cần củng cố", bundle: .module), count)
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

        public static var typingTitle: LocalizedStringKey { "app.reflex.mode.typing.title" }
        public static var typingTitleText: String {
            String(localized: "app.reflex.mode.typing.title", defaultValue: "Gõ từ", bundle: .module)
        }
        public static var typingSubtitle: LocalizedStringKey { "app.reflex.mode.typing.subtitle" }
        public static var typingSubtitleText: String {
            String(localized: "app.reflex.mode.typing.subtitle", defaultValue: "Phản xạ gõ phím & nhớ mặt chữ", bundle: .module)
        }

        public static var mcTitle: LocalizedStringKey { "app.reflex.mode.mc.title" }
        public static var mcTitleText: String {
            String(localized: "app.reflex.mode.mc.title", defaultValue: "Trắc nghiệm", bundle: .module)
        }
        public static var mcSubtitle: LocalizedStringKey { "app.reflex.mode.mc.subtitle" }
        public static var mcSubtitleText: String {
            String(localized: "app.reflex.mode.mc.subtitle", defaultValue: "Nhận diện từ vựng 1 trong 4", bundle: .module)
        }

        public static var listeningTitle: LocalizedStringKey { "app.reflex.mode.listening.title" }
        public static var listeningTitleText: String {
            String(localized: "app.reflex.mode.listening.title", defaultValue: "Phản xạ nghe", bundle: .module)
        }
        public static var listeningSubtitle: LocalizedStringKey { "app.reflex.mode.listening.subtitle" }
        public static var listeningSubtitleText: String {
            String(localized: "app.reflex.mode.listening.subtitle", defaultValue: "Bắt âm thanh & dịch nghĩa tức thì", bundle: .module)
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
        public static var continueCTA: LocalizedStringKey { "app.reflex.drill.continue_cta" }
        public static var continueCTAText: String {
            String(localized: "app.reflex.drill.continue_cta", defaultValue: "Tiếp tục", bundle: .module)
        }

        // Summary
        public static var summaryTitle: LocalizedStringKey { "app.reflex.summary.title" }
        public static var summaryTitleText: String {
            String(localized: "app.reflex.summary.title", defaultValue: "Hoàn thành phiên phản xạ Blitz", bundle: .module)
        }
        public static func redrillWeak(_ count: Int) -> String {
            String(format: String(localized: "app.reflex.summary.redrill_weak", defaultValue: "Luyện lại %lld từ chưa thuộc", bundle: .module), count)
        }
        public static var finishSave: LocalizedStringKey { "app.reflex.summary.finish_save" }
        public static var finishSaveText: String {
            String(localized: "app.reflex.summary.finish_save", defaultValue: "Hoàn thành & Lưu tiến độ", bundle: .module)
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
    }
}
