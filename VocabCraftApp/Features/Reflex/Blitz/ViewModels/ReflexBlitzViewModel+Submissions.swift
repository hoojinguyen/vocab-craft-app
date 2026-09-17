import CraftUIKit
import Foundation
import SwiftUI

// MARK: - Answer Submission & Response Handling
extension ReflexBlitzViewModel {
    public func selectOption(_ option: ReflexBlitzOption) {
        guard phase == .drilling, cardPhase == .activeCountdown, let word = currentWord else { return }
        cancelActiveTimers()

        let isCorrect = currentHandler.validateOption(option)
        currentAttemptIsCorrect = isCorrect
        let responseMs = calculateResponseTimeMs()

        recordAttempt(
            word: word,
            isCorrect: isCorrect,
            responseTimeMs: responseMs,
            selectedOption: option.text,
            typedText: nil,
            recognizedSpoken: nil,
            isTimeout: false
        )

        if currentHandler.shouldSpeakOnReviewFlip {
            ttsService.speak(text: word.lemma, rate: currentHandler.reviewSpeechRate, locale: "en-US")
        }
    }

    public func submitTypingAnswer(_ text: String) {
        guard phase == .drilling, cardPhase == .activeCountdown, let word = currentWord else { return }
        let validation = currentHandler.validateTyping(input: text, targetLemma: word.lemma)
        guard case .evaluated(let isCorrect, let cleanInput) = validation else { return }

        cancelActiveTimers()
        currentAttemptIsCorrect = isCorrect
        let responseMs = calculateResponseTimeMs()

        recordAttempt(
            word: word,
            isCorrect: isCorrect,
            responseTimeMs: responseMs,
            selectedOption: nil,
            typedText: cleanInput,
            recognizedSpoken: nil,
            isTimeout: false
        )

        if currentHandler.shouldSpeakOnReviewFlip {
            scheduleReviewSpeech(for: word.lemma, delayMs: currentHandler.reviewSpeechDelayMs, rate: currentHandler.reviewSpeechRate)
        }
    }

    public func handleSpokenMatch(_ matchedLemma: String) {
        guard phase == .drilling, cardPhase == .activeCountdown, !currentAttemptIsCorrect, let word = currentWord else { return }
        guard currentHandler.validateSpokenMatch(spokenText: matchedLemma, targetLemma: word.lemma) else { return }

        cancelActiveTimers()
        currentAttemptIsCorrect = true
        let responseMs = calculateResponseTimeMs()

        currentHandler.onWordCompleted(speechEngine: speechEngine)

        recordAttempt(
            word: word,
            isCorrect: true,
            responseTimeMs: responseMs,
            selectedOption: nil,
            typedText: nil,
            recognizedSpoken: matchedLemma,
            isTimeout: false
        )

        if currentHandler.shouldSpeakOnReviewFlip {
            scheduleReviewSpeech(for: word.lemma, delayMs: currentHandler.reviewSpeechDelayMs, rate: currentHandler.reviewSpeechRate)
        }
    }

    func calculateResponseTimeMs() -> Int {
        if elapsedTimeMs > 0 {
            return elapsedTimeMs
        } else if let start = wordStartTime {
            let responseMs = max(0, Int(Date().timeIntervalSince(start) * 1000))
            self.elapsedTimeMs = responseMs
            return responseMs
        } else {
            return 0
        }
    }

    // swiftlint:disable:next function_parameter_count
    func recordAttempt(
        word: ReflexBlitzWordItem,
        isCorrect: Bool,
        responseTimeMs: Int,
        selectedOption: String?,
        typedText: String?,
        recognizedSpoken: String?,
        isTimeout: Bool
    ) {
        if isCorrect {
            soundEffectService.playSuccessChime()
            comboStreak += 1
            if comboStreak > maxComboStreak {
                maxComboStreak = comboStreak
            }
        } else {
            soundEffectService.playIncorrectChime()
            triggerIncorrectHaptic()
            comboStreak = 0
        }

        let attempt = ReflexBlitzAttempt(
            wordId: word.id,
            lemma: word.lemma,
            pos: word.pos,
            ipa: word.ipa,
            definitionVi: word.definitionVi,
            responseTimeMs: responseTimeMs,
            usedHint: showHint,
            isCorrect: isCorrect
        )
        attempts.append(attempt)

        Task {
            _ = try? await self.evaluateSRSUseCase.recordReview(
                wordId: Int64(word.id),
                isCorrect: isCorrect,
                responseTimeMs: responseTimeMs
            )
        }

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            self.cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: isCorrect,
                responseTimeMs: responseTimeMs,
                isTimeout: isTimeout,
                selectedOption: selectedOption,
                typedText: typedText,
                recognizedSpoken: recognizedSpoken
            ))
        }
    }

    func scheduleReviewSpeech(for text: String, delayMs: Int, rate: Float) {
        reviewAudioTask?.cancel()
        reviewAudioTask = Task { @MainActor [weak self] in
            if delayMs > 0 {
                try? await Task.sleep(for: .milliseconds(delayMs))
            }
            guard let self, self.cardPhase != .activeCountdown else { return }
            self.ttsService.speak(text: text, rate: rate, locale: "en-US")
        }
    }
}
