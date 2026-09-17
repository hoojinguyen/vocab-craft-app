import CraftUIKit
import Foundation
import SwiftUI

// MARK: - Step Navigation & Exercise Interaction
extension LessonLearningViewModel {
    public func advanceStep() {
        guard !isSummaryStep else { return }
        LessonPerformanceDiagnostics.event(
            "LessonStepAdvance",
            detail: "fromIndex=\(currentStepIndex) stepCount=\(steps.count)"
        )
        maxProgress = max(maxProgress, progress)
        autoPronounceTask?.cancel()
        autoPronounceTask = nil
        ttsService.stop()
        if speechEngine.isWordActive || speechState != .idle {
            stopListeningForSpeaking()
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isFeedbackPresented = false
            typingText = ""
            liveTranscript = ""
            speechState = .idle
            hintStage = 0
            eliminatedOptionId = nil
            if steps.isEmpty || currentStepIndex + 1 >= steps.count {
                finishLesson()
                currentStepIndex = max(0, steps.count - 1)
            } else {
                currentStepIndex += 1
            }
        }
    }

    public func submitAnswer(isCorrect: Bool, for item: LessonExerciseItem) {
        guard !isFeedbackPresented else { return }
        guard currentExerciseItem?.id == item.id else { return }
        maxProgress = max(maxProgress, progress)
        stopListeningForSpeaking()
        totalAnswered += 1
        lastAttemptCorrect = isCorrect

        let currentWordAttempts = attemptCountPerWord[item.word.id, default: 0] + 1
        attemptCountPerWord[item.word.id] = currentWordAttempts

        if isCorrect {
            correctAnswers += 1
            soundEffectService.playSuccessChime()
            CraftHaptics.shared.success()
        } else {
            mistakeCount += 1
            weakWordIds.insert(item.word.id)
            soundEffectService.playIncorrectChime()
            CraftHaptics.shared.error()

            // Smart Requeue (Option A): Max 1 retry per word with mode downgrading
            if currentWordAttempts == 1 {
                let fallbackMode: ReflexBlitzMode = .multipleChoice
                let fallbackOptions = ReflexDistractorGenerator.generateOptions(
                    mode: .multipleChoice,
                    target: ReflexBlitzWordItem(from: item.word),
                    pool: words.map { ReflexBlitzWordItem(from: $0) }
                )

                let clozeStages = item.clozeStages

                let retryItem = LessonExerciseItem(
                    id: "\(fallbackMode.rawValue)-\(item.word.id)-retry-\(UUID().uuidString.prefix(4))",
                    word: item.word,
                    assignedMode: fallbackMode,
                    options: fallbackOptions,
                    clozeStages: clozeStages,
                    attemptCount: currentWordAttempts + 1,
                    isRequeued: true
                )
                steps.append(.exercise(item: retryItem))
            }
        }

        // Auto-pronounce vocabulary word for non-listening modes after feedback sound
        autoPronounceTask?.cancel()
        if item.assignedMode != .listening {
            autoPronounceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }
                self.ttsService.speak(text: item.word.lemma)
            }
        }

        isFeedbackPresented = true
    }

    public func requestHint(for item: LessonExerciseItem) {
        guard !isFeedbackPresented else { return }
        guard currentExerciseItem?.id == item.id else { return }
        let maxHintStage = (item.assignedMode == .speaking) ? 3 : 2
        guard hintStage < maxHintStage else { return }
        CraftHaptics.shared.selection()
        hintStage += 1

        if hintStage >= 2 && (item.assignedMode == .multipleChoice || item.assignedMode == .listening) {
            if eliminatedOptionId == nil {
                let wrongOptions = item.options.filter { !$0.isCorrect }
                eliminatedOptionId = wrongOptions.first?.id
            }
        }
    }

    public func skipExercise(for item: LessonExerciseItem) {
        submitAnswer(isCorrect: false, for: item)
    }

    public func playAudio(for text: String) {
        ttsService.speak(text: text)
    }

    public func stopAudio() {
        ttsService.stop()
    }
}
