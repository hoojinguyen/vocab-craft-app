import Foundation
import SwiftUI

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
}
