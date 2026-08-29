import Foundation
import SwiftUI

// MARK: - Deep Link Configuration & Previews

extension ReflexBlitzViewModel {
    public func applyReviewConfig(_ config: ReflexBlitzDeepLinkConfig) {
        cancelAllTasks()

        self.selectedMode = config.mode
        self.phase = config.phase
        self.comboStreak = config.combo
        self.maxComboStreak = max(config.combo, 4)
        self.hintStage = config.showHint ? 1 : 0
        self.currentWordIndex = 0

        if config.phase == .summary {
            let mockAttempts = [
                ReflexBlitzAttempt(wordId: 1, lemma: "habit", pos: "n.", ipa: "/ˈhæb.ɪt/", definitionVi: "Thói quen", responseTimeMs: 1400, usedHint: false, isCorrect: true),
                ReflexBlitzAttempt(wordId: 2, lemma: "improve", pos: "v.", ipa: "/ɪmˈpruːv/", definitionVi: "Cải thiện, nâng cao", responseTimeMs: 2100, usedHint: false, isCorrect: true),
                ReflexBlitzAttempt(wordId: 3, lemma: "focus", pos: "v.", ipa: "/ˈfoʊ.kəs/", definitionVi: "Tập trung", responseTimeMs: 4200, usedHint: true, isCorrect: true),
                ReflexBlitzAttempt(wordId: 7, lemma: "challenge", pos: "n.", ipa: "/ˈtʃæl.ɪndʒ/", definitionVi: "Thử thách", responseTimeMs: 6000, usedHint: true, isCorrect: false)
            ]
            self.sessionSummary = ReflexBlitzSessionSummary.create(from: mockAttempts, maxCombo: config.combo)
            return
        }

        guard let word = currentWord else { return }

        if config.mode == .multipleChoice || config.mode == .listening {
            currentOptions = word.generateOptions(mode: config.mode, allPool: words)
        } else {
            currentOptions = []
        }

        if config.state == "reviewedCorrect" {
            currentAttemptIsCorrect = true
            let correctOpt = currentOptions.first(where: { $0.isCorrect })?.text ?? word.lemma
            cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: true,
                responseTimeMs: 1400,
                isTimeout: false,
                selectedOption: correctOpt,
                typedText: word.lemma,
                recognizedSpoken: word.lemma
            ))
        } else if config.state == "reviewedIncorrect" {
            currentAttemptIsCorrect = false
            let wrongOpt = currentOptions.first(where: { !$0.isCorrect })?.text ?? "other"
            cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: false,
                responseTimeMs: 3500,
                isTimeout: false,
                selectedOption: wrongOpt,
                typedText: "habbit",
                recognizedSpoken: "rabbit"
            ))
        } else if config.state == "timeout" {
            currentAttemptIsCorrect = false
            cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: false,
                responseTimeMs: Int(config.mode.timeLimitSeconds * 1000),
                isTimeout: true,
                selectedOption: nil,
                typedText: nil,
                recognizedSpoken: nil
            ))
        } else {
            cardPhase = .activeCountdown
            elapsedTimeMs = 1200
        }
    }
}
