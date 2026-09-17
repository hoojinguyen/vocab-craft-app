import CraftUIKit
import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Speech Recognition & Accessibility Fallbacks
extension LessonLearningViewModel {
    public func startSpeechSession() {
        guard !isSpeakingDisabledForLesson else { return }
        let contextualPhrases = words.map(\.lemma)
        speechEngine.startSession(contextualPhrases: contextualPhrases, lazy: true)
    }

    public func stopSpeechSession() {
        ttsService.stop()
        cleanup()
    }

    public func startListeningForSpeaking(targetLemma: String, item: LessonExerciseItem) {
        guard !isSpeakingDisabledForLesson else { return }
        guard !isFeedbackPresented && speechState == .idle else { return }
        LessonPerformanceDiagnostics.event(
            "LessonSpeakingStart",
            detail: "engineSessionActive=\(speechEngine.isSessionActive)"
        )
        speechState = .preparing
        liveTranscript = ""

        speechEngine.onTranscriptUpdate = { [weak self] transcript in
            guard let self, self.currentExerciseItem?.id == item.id else { return }
            self.liveTranscript = transcript
        }

        speechEngine.onMatchDetected = { [weak self] _ in
            guard let self, !self.isFeedbackPresented, self.currentExerciseItem?.id == item.id else { return }
            self.speechState = .evaluated(overallScore: 1.0)
            self.submitAnswer(isCorrect: true, for: item)
        }

        speechEngine.onError = { [weak self] error in
            guard let self, self.currentExerciseItem?.id == item.id else { return }
            LessonPerformanceDiagnostics.error("lesson.speaking", error: error)
            self.speechState = .idle
        }

        if !speechEngine.isSessionActive {
            startSpeechSession()
        }

        speakingRequestGeneration &+= 1
        let requestGeneration = speakingRequestGeneration

        speechStartTask?.cancel()
        speechStartTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await self.speechEngine.startListening(
                    targetLemma: targetLemma,
                    contextualPhrases: [targetLemma, item.word.exampleEn]
                )
                try Task.checkCancellation()
                guard self.currentExerciseItem?.id == item.id,
                      !self.isFeedbackPresented,
                      requestGeneration == self.speakingRequestGeneration else {
                    if self.speechState == .preparing && requestGeneration == self.speakingRequestGeneration {
                        self.speechState = .idle
                    }
                    return
                }
                self.speechState = .listening()
            } catch is CancellationError {
                if self.speechState == .preparing && requestGeneration == self.speakingRequestGeneration && self.currentExerciseItem?.id == item.id {
                    self.speechState = .idle
                }
                return
            } catch let error as SpeechCaptureError where error == .speechRecognitionDenied || error == .microphoneDenied {
                LessonPerformanceDiagnostics.error("lesson.speaking.permission", error: error)
                guard requestGeneration == self.speakingRequestGeneration else { return }
                self.handlePermissionDenied(for: item)
            } catch {
                LessonPerformanceDiagnostics.error("lesson.speaking.start", error: error)
                if requestGeneration == self.speakingRequestGeneration {
                    self.speechState = .idle
                }
            }
        }
    }

    public func stopListeningForSpeaking() {
        speakingRequestGeneration &+= 1
        speechStartTask?.cancel()
        speechStartTask = nil
        speechEngine.pauseListening()
        speechEngine.onMatchDetected = nil
        speechEngine.onTranscriptUpdate = nil
        speechEngine.onError = nil
        if speechState != .unavailable {
            speechState = .idle
        }
    }

    public func handleCantSpeakNow(for item: LessonExerciseItem) {
        guard currentExerciseItem?.id == item.id, !isFeedbackPresented else { return }
        stopListeningForSpeaking()
        speechEngine.stopSession()
        isSpeakingDisabledForLesson = true
        hintStage = 0
        eliminatedOptionId = nil

        // Convert current exercise item to multiple choice
        let fallbackOptions = ReflexDistractorGenerator.generateOptions(
            mode: .multipleChoice,
            target: ReflexBlitzWordItem(from: item.word),
            pool: words.map { ReflexBlitzWordItem(from: $0) }
        )
        let convertedCurrentItem = LessonExerciseItem(
            id: "mc-\(item.word.id)-fallback-\(UUID().uuidString.prefix(4))",
            word: item.word,
            assignedMode: .multipleChoice,
            options: fallbackOptions,
            clozeStages: item.clozeStages,
            attemptCount: item.attemptCount,
            isRequeued: item.isRequeued
        )
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            steps[currentStepIndex] = .exercise(item: convertedCurrentItem)
        }

        // Convert any remaining speaking exercises in subsequent steps to multiple choice
        for index in (currentStepIndex + 1)..<steps.count {
            if case .exercise(let stepItem) = steps[index], stepItem.assignedMode == .speaking {
                let options = ReflexDistractorGenerator.generateOptions(
                    mode: .multipleChoice,
                    target: ReflexBlitzWordItem(from: stepItem.word),
                    pool: words.map { ReflexBlitzWordItem(from: $0) }
                )
                let convertedItem = LessonExerciseItem(
                    id: "mc-\(stepItem.word.id)-fallback-\(UUID().uuidString.prefix(4))",
                    word: stepItem.word,
                    assignedMode: .multipleChoice,
                    options: options,
                    clozeStages: stepItem.clozeStages,
                    attemptCount: stepItem.attemptCount,
                    isRequeued: stepItem.isRequeued
                )
                steps[index] = .exercise(item: convertedItem)
            }
        }
    }

    public func handlePermissionDenied(for item: LessonExerciseItem) {
        guard !isFeedbackPresented else { return }
        stopListeningForSpeaking()
        speechEngine.stopSession()
        isSpeakingDisabledForLesson = true
        speechState = .unavailable
        hintStage = 0
        eliminatedOptionId = nil

        // Convert current exercise item to typing fallback
        if currentExerciseItem?.id == item.id {
            let convertedCurrentItem = convertToTypingFallback(item: item)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                steps[currentStepIndex] = .exercise(item: convertedCurrentItem)
            }
        }

        // Convert any remaining speaking exercises in subsequent steps to typing fallback
        for index in (currentStepIndex + 1)..<steps.count {
            if case .exercise(let stepItem) = steps[index], stepItem.assignedMode == .speaking {
                steps[index] = .exercise(item: convertToTypingFallback(item: stepItem))
            }
        }

        if !hasPresentedPermissionNotice {
            hasPresentedPermissionNotice = true
            permissionNotice = LessonPermissionNotice()
        }
    }

    private func convertToTypingFallback(item: LessonExerciseItem) -> LessonExerciseItem {
        LessonExerciseItem(
            id: "typing-\(item.word.id)-fallback-\(UUID().uuidString.prefix(4))",
            word: item.word,
            assignedMode: .typing,
            options: [],
            clozeStages: item.clozeStages,
            attemptCount: item.attemptCount,
            isRequeued: item.isRequeued
        )
    }

    public func openSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }

    public func cleanup() {
        speechStartTask?.cancel()
        speechStartTask = nil
        autoPronounceTask?.cancel()
        autoPronounceTask = nil
        stopListeningForSpeaking()
        speechEngine.stopSession()
    }

    public func retrySpeaking(for item: LessonExerciseItem) {
        guard currentExerciseItem?.id == item.id, !isFeedbackPresented else { return }
        stopListeningForSpeaking()
        startListeningForSpeaking(targetLemma: item.word.lemma, item: item)
    }
}
