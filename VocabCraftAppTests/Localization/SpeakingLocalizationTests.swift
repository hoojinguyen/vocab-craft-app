import Foundation
import SwiftUI
import Testing
@testable import VocabCraftApp

@Suite("Speaking localization parity")
struct SpeakingLocalizationTests {
    private let requiredKeys = [
        "app.speaking.hub.title",
        "app.speaking.hub.subtitle",
        "app.speaking.hub.scenarios",
        "app.speaking.hub.topics",
        "app.speaking.hub.progress",
        "app.speaking.hub.phrasebook",
        "app.speaking.hub.history",
        "app.speaking.hub.empty",
        "app.speaking.prepare.level",
        "app.speaking.prepare.vocab_toggle",
        "app.speaking.prepare.words",
        "app.speaking.prepare.goal",
        "app.speaking.prepare.start",
        "app.speaking.prepare.check_key",
        "app.speaking.prepare.check_mic",
        "app.speaking.prepare.check_network",
        "app.speaking.call.connecting",
        "app.speaking.call.reconnecting",
        "app.speaking.call.hint",
        "app.speaking.call.end",
        "app.speaking.call.subtitles_show",
        "app.speaking.call.subtitles_hide",
        "app.speaking.call.time_left",
        "app.speaking.result.analyzing",
        "app.speaking.result.failed",
        "app.speaking.result.pending_analysis_failed",
        "app.speaking.result.retry",
        "app.speaking.result.too_short",
        "app.speaking.result.audio_missing",
        "app.speaking.result.scores",
        "app.speaking.result.fluency",
        "app.speaking.result.grammar",
        "app.speaking.result.vocabulary",
        "app.speaking.result.pronunciation",
        "app.speaking.result.corrections",
        "app.speaking.result.natural",
        "app.speaking.result.pronunciation_notes",
        "app.speaking.result.target_words",
        "app.speaking.result.objective_met",
        "app.speaking.result.objective_not_met",
        "app.speaking.result.strengths",
        "app.speaking.result.focus_next",
        "app.speaking.result.save_phrase",
        "app.speaking.result.saved",
        "app.speaking.phrasebook.title",
        "app.speaking.phrasebook.empty",
        "app.speaking.phrasebook.delete",
        "app.speaking.error.missing_key",
        "app.speaking.error.unauthorized",
        "app.speaking.error.quota",
        "app.speaking.error.offline",
        "app.speaking.error.network",
        "app.speaking.error.microphone_denied",
        "app.speaking.error.unknown",
        "app.speaking.error.open_settings",
        "app.speaking.error.try_again",
        "app.speaking.error.exit",
        "app.speaking.tab"
    ]

    private func loadCatalog() throws -> [String: [String: Any]] {
        let catalogURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("VocabCraftApp/Resources/Localizable.xcstrings")
        let data = try Data(contentsOf: catalogURL)
        let root = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try #require(root["strings"] as? [String: [String: Any]])
    }

    private func value(for key: String, language: String, in catalog: [String: [String: Any]]) -> String? {
        guard let entry = catalog[key],
              let localizations = entry["localizations"] as? [String: [String: Any]],
              let unit = localizations[language]?["stringUnit"] as? [String: Any] else {
            return nil
        }
        return unit["value"] as? String
    }

    private func formatSpecifiers(in value: String) -> [String] {
        guard let expression = try? NSRegularExpression(pattern: "%lld|%@|%%|%ld|%d") else { return [] }
        let range = NSRange(value.startIndex..., in: value)
        return expression.matches(in: value, range: range).compactMap {
            Range($0.range, in: value).map { String(value[$0]) }
        }
    }

    private func sourceReferences(for keyPrefix: String) throws -> [String] {
        let sourceRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("VocabCraftApp")
        let enumerator = try #require(FileManager.default.enumerator(at: sourceRoot, includingPropertiesForKeys: nil))
        var references: [String] = []
        for case let url as URL in enumerator where url.pathExtension == "swift" {
            let source = try String(contentsOf: url, encoding: .utf8)
            if source.contains(keyPrefix) {
                references.append(url.path)
            }
        }
        return references
    }

    @Test("Retired AI localization namespaces have no source or catalog references")
    func retiredAILocalizationKeysHaveNoSourceOrCatalogReferences() throws {
        let catalog = try loadCatalog()
        let retiredPrefixes = ["app." + "ai_assistant.", "app." + "ai_pack."]

        for prefix in retiredPrefixes {
            #expect(try sourceReferences(for: prefix).isEmpty, "Source still references retired keys under \(prefix)")
            #expect(!catalog.keys.contains { $0.hasPrefix(prefix) }, "Catalog still contains retired keys under \(prefix)")
        }
    }

    @Test("All speaking strings have complete English and Vietnamese translations")
    func everySpeakingKeyHasEnglishAndVietnamese() throws {
        let catalog = try loadCatalog()
        let speakingKeys = catalog.keys.filter { $0.hasPrefix("app.speaking.") }.sorted()
        #expect(Set(requiredKeys).isSubset(of: Set(speakingKeys)))

        for key in speakingKeys {
            let entry = try #require(catalog[key], "Missing catalog entry for \(key)")
            #expect(entry["extractionState"] as? String == "manual", "\(key) must be manually extracted")
            let localizations = try #require(entry["localizations"] as? [String: [String: Any]])
            let english = try #require(value(for: key, language: "en", in: catalog), "Missing English translation for \(key)")
            let vietnamese = try #require(value(for: key, language: "vi", in: catalog), "Missing Vietnamese translation for \(key)")
            #expect((localizations["en"]?["stringUnit"] as? [String: Any])?["state"] as? String == "translated")
            #expect((localizations["vi"]?["stringUnit"] as? [String: Any])?["state"] as? String == "translated")
            #expect(!english.isEmpty)
            #expect(!vietnamese.isEmpty)
            #expect(formatSpecifiers(in: english) == formatSpecifiers(in: vietnamese), "Format specifiers differ for \(key)")
        }
    }

    @Test("Speaking typed accessors expose localized keys and localized text")
    func typedAccessorsExistForAllRequestedStrings() {
        let keys: [LocalizedStringKey] = [
            AppStrings.Speaking.hubTitle, AppStrings.Speaking.hubSubtitle, AppStrings.Speaking.hubScenarios,
            AppStrings.Speaking.hubTopics, AppStrings.Speaking.hubProgress, AppStrings.Speaking.hubPhrasebook,
            AppStrings.Speaking.hubHistory, AppStrings.Speaking.hubEmpty, AppStrings.Speaking.prepareLevel,
            AppStrings.Speaking.prepareVocabToggle, AppStrings.Speaking.prepareWords, AppStrings.Speaking.prepareGoal,
            AppStrings.Speaking.prepareStart, AppStrings.Speaking.prepareCheckKey, AppStrings.Speaking.prepareCheckMic,
            AppStrings.Speaking.prepareCheckNetwork, AppStrings.Speaking.callConnecting, AppStrings.Speaking.callReconnecting,
            AppStrings.Speaking.callHint, AppStrings.Speaking.callEnd, AppStrings.Speaking.callSubtitlesShow,
            AppStrings.Speaking.callSubtitlesHide, AppStrings.Speaking.callTimeLeft, AppStrings.Speaking.resultAnalyzing,
            AppStrings.Speaking.resultFailed, AppStrings.Speaking.resultPendingAnalysisFailed,
            AppStrings.Speaking.resultRetry, AppStrings.Speaking.resultTooShort,
            AppStrings.Speaking.resultAudioMissing, AppStrings.Speaking.resultScores, AppStrings.Speaking.resultFluency,
            AppStrings.Speaking.resultGrammar, AppStrings.Speaking.resultVocabulary, AppStrings.Speaking.resultPronunciation,
            AppStrings.Speaking.resultCorrections, AppStrings.Speaking.resultNatural, AppStrings.Speaking.resultPronunciationNotes,
            AppStrings.Speaking.resultTargetWords, AppStrings.Speaking.resultObjectiveMet,
            AppStrings.Speaking.resultObjectiveNotMet, AppStrings.Speaking.resultStrengths,
            AppStrings.Speaking.resultFocusNext, AppStrings.Speaking.resultSavePhrase, AppStrings.Speaking.resultSaved,
            AppStrings.Speaking.phrasebookTitle, AppStrings.Speaking.phrasebookEmpty, AppStrings.Speaking.phrasebookDelete,
            AppStrings.Speaking.errorMissingKey, AppStrings.Speaking.errorUnauthorized, AppStrings.Speaking.errorQuota,
            AppStrings.Speaking.errorOffline, AppStrings.Speaking.errorNetwork, AppStrings.Speaking.errorMicrophoneDenied,
            AppStrings.Speaking.errorUnknown, AppStrings.Speaking.errorOpenSettings, AppStrings.Speaking.errorTryAgain,
            AppStrings.Speaking.errorExit, AppStrings.Speaking.tab
        ]
        let texts = [
            AppStrings.Speaking.hubTitleText, AppStrings.Speaking.hubSubtitleText, AppStrings.Speaking.hubScenariosText,
            AppStrings.Speaking.hubTopicsText, AppStrings.Speaking.hubProgressText, AppStrings.Speaking.hubPhrasebookText,
            AppStrings.Speaking.hubHistoryText, AppStrings.Speaking.hubEmptyText, AppStrings.Speaking.prepareLevelText,
            AppStrings.Speaking.prepareVocabToggleText, AppStrings.Speaking.prepareWordsText, AppStrings.Speaking.prepareGoalText,
            AppStrings.Speaking.prepareStartText, AppStrings.Speaking.prepareCheckKeyText, AppStrings.Speaking.prepareCheckMicText,
            AppStrings.Speaking.prepareCheckNetworkText, AppStrings.Speaking.callConnectingText,
            AppStrings.Speaking.callReconnectingText, AppStrings.Speaking.callHintText, AppStrings.Speaking.callEndText,
            AppStrings.Speaking.callSubtitlesShowText, AppStrings.Speaking.callSubtitlesHideText,
            AppStrings.Speaking.callTimeLeftText(remainingSeconds: 42),
            AppStrings.Speaking.resultAnalyzingText, AppStrings.Speaking.resultFailedText,
            AppStrings.Speaking.resultPendingAnalysisFailedText, AppStrings.Speaking.resultRetryText,
            AppStrings.Speaking.resultTooShortText, AppStrings.Speaking.resultAudioMissingText,
            AppStrings.Speaking.resultScoresText, AppStrings.Speaking.resultFluencyText, AppStrings.Speaking.resultGrammarText,
            AppStrings.Speaking.resultVocabularyText, AppStrings.Speaking.resultPronunciationText,
            AppStrings.Speaking.resultCorrectionsText, AppStrings.Speaking.resultNaturalText,
            AppStrings.Speaking.resultPronunciationNotesText, AppStrings.Speaking.resultTargetWordsText,
            AppStrings.Speaking.resultObjectiveMetText, AppStrings.Speaking.resultObjectiveNotMetText,
            AppStrings.Speaking.resultStrengthsText, AppStrings.Speaking.resultFocusNextText,
            AppStrings.Speaking.resultSavePhraseText, AppStrings.Speaking.resultSavedText,
            AppStrings.Speaking.phrasebookTitleText, AppStrings.Speaking.phrasebookEmptyText,
            AppStrings.Speaking.phrasebookDeleteText, AppStrings.Speaking.errorMissingKeyText,
            AppStrings.Speaking.errorUnauthorizedText, AppStrings.Speaking.errorQuotaText,
            AppStrings.Speaking.errorOfflineText, AppStrings.Speaking.errorNetworkText,
            AppStrings.Speaking.errorMicrophoneDeniedText, AppStrings.Speaking.errorUnknownText,
            AppStrings.Speaking.errorOpenSettingsText, AppStrings.Speaking.errorTryAgainText,
            AppStrings.Speaking.errorExitText, AppStrings.Speaking.tabText
        ]
        #expect(keys.count == requiredKeys.count)
        #expect(texts.count == requiredKeys.count)
        #expect(AppStrings.Speaking.callTimeLeftText(remainingSeconds: 42).contains("42"))
    }
}
