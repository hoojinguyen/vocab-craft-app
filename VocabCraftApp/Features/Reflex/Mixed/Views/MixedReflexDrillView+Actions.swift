import CraftUIKit
import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Drill Actions & Lifecycle
public extension MixedReflexDrillView {
    func finalizeActiveEngineAndTimers() {
        speechStartTask?.cancel()
        speechStartTask = nil
        timerTask?.cancel()
        timerTask = nil
        speechEngine?.finalizeWordAudio()
        speechEngine?.endWord()
    }

    func recordResponseTime() -> Int {
        let elapsedMs = wordStartTime.map { Int(Date().timeIntervalSince($0) * 1000) } ?? 500
        let responseTimeMs = max(500, elapsedMs)
        let timeLimit = viewModel.currentItem?.assignedMode.timeLimitSeconds ?? 6.0
        fractionRemaining = max(0.0, min(1.0, 1.0 - (Double(elapsedMs) / 1000.0 / timeLimit)))
        viewModel.elapsedTimeMs = responseTimeMs
        return responseTimeMs
    }

    func startDrillItem(_ item: MixedReflexDrillItem) {
        finalizeActiveEngineAndTimers()
        wordStartTime = nil
        timerStage = .steady
        hintStage = 0
        fractionRemaining = 1.0
        elapsedTimeMs = 0
        cardPhase = .activeCountdown
        typingText = ""
        liveTranscript = ""

        if item.assignedMode == .multipleChoice || item.assignedMode == .listening {
            currentOptions = viewModel.generateOptions(for: item)
        } else {
            currentOptions = []
        }

        if item.assignedMode == .speaking {
            if isPermissionDenied {
                speechState = .unavailable
                if !viewModel.showPermissionAlert {
                    wordStartTime = Date()
                    startTimer(for: item)
                }
                return
            }

            speechState = .preparing
            if let engine = speechEngine, !engine.isSessionActive {
                let phrases = viewModel.queue.map(\.word.lemma)
                engine.startSession(contextualPhrases: phrases, lazy: true)
            }

            if let speechEngine {
                speechStartTask = Task { @MainActor in
                    do {
                        try await speechEngine.startListening(
                            targetLemma: item.word.lemma,
                            contextualPhrases: [item.word.exampleSentenceEn]
                        )
                        guard !Task.isCancelled else { return }
                        guard viewModel.currentItem?.id == item.id else { return }
                        speechState = .listening()
                        if !viewModel.showPermissionAlert {
                            wordStartTime = Date()
                            startTimer(for: item)
                        }
                    } catch let error as SpeechCaptureError where error == .speechRecognitionDenied || error == .microphoneDenied {
                        guard !Task.isCancelled, viewModel.currentItem?.id == item.id else { return }
                        handlePermissionDenied()
                    } catch {
                        guard !Task.isCancelled, viewModel.currentItem?.id == item.id else { return }
                        speechState = .unavailable
                        if !viewModel.showPermissionAlert {
                            wordStartTime = Date()
                            startTimer(for: item)
                        }
                    }
                }
            } else {
                speechState = .unavailable
                if !viewModel.showPermissionAlert {
                    wordStartTime = Date()
                    startTimer(for: item)
                }
            }
        } else {
            speechState = isPermissionDenied ? .unavailable : .idle
            speechEngine?.endWord()
            if item.assignedMode == .listening {
                viewModel.playAudioForCurrentWord()
            }
            if !viewModel.showPermissionAlert {
                wordStartTime = Date()
                startTimer(for: item)
            }
        }
    }

    func startTimer(for item: MixedReflexDrillItem) {
        timerTask?.cancel()
        if wordStartTime == nil {
            wordStartTime = Date()
        }
        timerStage = .steady
        hintStage = 0
        let timeLimit = item.assignedMode.timeLimitSeconds

        timerTask = Task { @MainActor in
            // Milestone 1: Hint 1 (40%)
            let hint1Delay = timeLimit * 0.40
            try? await Task.sleep(for: .seconds(hint1Delay))
            guard !Task.isCancelled else { return }
            self.hintStage = 1

            // Milestone 2: Warning (60%)
            let warningDelay = timeLimit * 0.20
            try? await Task.sleep(for: .seconds(warningDelay))
            guard !Task.isCancelled else { return }
            self.timerStage = .warning

            // Milestone 3: Hint 2 (70%)
            let hint2Delay = timeLimit * 0.10
            try? await Task.sleep(for: .seconds(hint2Delay))
            guard !Task.isCancelled else { return }
            self.hintStage = 2

            // Milestone 4: Urgent (80%)
            let urgentDelay = timeLimit * 0.10
            try? await Task.sleep(for: .seconds(urgentDelay))
            guard !Task.isCancelled else { return }
            self.timerStage = .urgent

            // Milestone 5: Timeout (100%)
            let timeoutDelay = timeLimit * 0.20
            try? await Task.sleep(for: .seconds(timeoutDelay))
            guard !Task.isCancelled else { return }
            self.handleTimeout()
        }
    }

    func selectOption(_ option: ReflexBlitzOption) {
        guard cardPhase == .activeCountdown else { return }
        finalizeActiveEngineAndTimers()
        let responseTimeMs = recordResponseTime()

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: option.isCorrect,
                responseTimeMs: responseTimeMs,
                isTimeout: false,
                selectedOption: option.text
            ))
        }

        Task {
            await viewModel.submitAnswer(isCorrect: option.isCorrect, responseTimeMs: responseTimeMs)
        }
    }

    func submitTypingAnswer(_ text: String) {
        guard cardPhase == .activeCountdown, let current = viewModel.currentItem else { return }
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }

        let isCorrect = cleanText.lowercased() == current.word.lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        finalizeActiveEngineAndTimers()
        let responseTimeMs = recordResponseTime()

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: isCorrect,
                responseTimeMs: responseTimeMs,
                isTimeout: false,
                typedText: cleanText
            ))
        }

        if isCorrect {
            SoundEffectService.shared.playSuccessChime()
        } else {
            SoundEffectService.shared.playIncorrectChime()
        }

        Task {
            await viewModel.submitAnswer(isCorrect: isCorrect, responseTimeMs: responseTimeMs)
        }
    }

    func handleTimeout() {
        guard cardPhase == .activeCountdown else { return }
        finalizeActiveEngineAndTimers()
        fractionRemaining = 0.0
        let elapsedMs = wordStartTime.map { Int(Date().timeIntervalSince($0) * 1000) } ?? 500
        let responseTimeMs = max(500, elapsedMs)
        viewModel.elapsedTimeMs = responseTimeMs

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: false,
                responseTimeMs: responseTimeMs,
                isTimeout: true
            ))
        }

        if viewModel.currentItem?.assignedMode != .listening {
            viewModel.playAudioForCurrentWord()
        }

        Task {
            await viewModel.submitAnswer(isCorrect: false, responseTimeMs: responseTimeMs)
        }
    }

    func advanceToNextItem() {
        viewModel.advanceToNextItem()
        if let nextItem = viewModel.currentItem {
            startDrillItem(nextItem)
        }
    }

    func setupSpeechEngineCallbacks() {
        if let speechEngine {
            let vm = viewModel
            speechEngine.onMatchDetected = { [weak vm] matched in
                Task { @MainActor [weak vm] in
                    guard self.cardPhase == .activeCountdown, let vm, let current = vm.currentItem else { return }
                    let isCorrect = ReflexSpeechMatcher.isReflexMatch(spokenText: matched, targetLemma: current.word.lemma)
                    if isCorrect {
                        self.finalizeActiveEngineAndTimers()
                        let responseTimeMs = self.recordResponseTime()

                        SoundEffectService.shared.playSuccessChime()
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                            self.cardPhase = .reviewed(result: ReflexCardResult(
                                isCorrect: true,
                                responseTimeMs: responseTimeMs,
                                isTimeout: false,
                                recognizedSpoken: matched
                            ))
                        }
                        await vm.submitAnswer(isCorrect: true, responseTimeMs: responseTimeMs)
                    }
                }
            }

            speechEngine.onTranscriptUpdate = { transcript in
                Task { @MainActor in
                    self.liveTranscript = transcript
                }
            }

            speechEngine.onError = { error in
                print("[MixedReflexDrillView] Speech engine error: \(error.localizedDescription)")
            }
        }
    }

    func stopDrillSession() {
        finalizeActiveEngineAndTimers()
        speechEngine?.stopSession()
    }

    func dismissPermissionAlert() {
        permissionNotice = nil
        viewModel.showPermissionAlert = false
        if case .activeCountdown = cardPhase, let current = viewModel.currentItem {
            wordStartTime = Date()
            startTimer(for: current)
        }
    }

    func handlePermissionDenied() {
        finalizeActiveEngineAndTimers()
        speechEngine?.stopSession()
        isPermissionDenied = true
        speechState = .unavailable
        permissionNotice = ReflexPermissionNotice()
        showPermissionAlert = true
        viewModel.fallbackSpeakingItemsToTyping()
        if let current = viewModel.currentItem {
            startDrillItem(current)
        }
    }

    func openSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
}
