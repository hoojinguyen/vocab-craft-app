import CraftUIKit
import Foundation
import Observation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@MainActor
@Observable
public final class ReflexBlitzViewModel {
    public var phase: ReflexBlitzPhase = .modeSelection
    public var selectedMode: ReflexBlitzMode = .speaking
    public var cardPhase: ReflexCardPhase = .activeCountdown
    public var sessionPlan: ReflexDrillSessionPlan?
    public var currentPlanItem: ReflexDrillPlanItem?
    public var currentClozeStages: ReflexClozeStageSet?
    public var currentEliminatedOptionId: String?
    public var currentHintBadgeText: String = ""
    public var currentOptions: [ReflexBlitzOption] = []
    public var typingInput: String = ""
    public var countdownCount: Int = 3
    public var words: [ReflexBlitzWordItem] = []
    public var currentWordIndex: Int = 0
    public var elapsedTimeMs: Int = 0
    public var hintStage: Int = 0
    public var showHint: Bool { hintStage >= 1 }
    public var comboStreak: Int = 0
    public var maxComboStreak: Int = 0
    public var currentAttemptIsCorrect: Bool = false
    public var liveTranscript: String = ""
    public var speechState: CraftSpeechState = .idle
    public var permissionNotice: ReflexPermissionNotice?
    public internal(set) var hasPresentedPermissionNotice: Bool = false
    public var isPermissionNoticePresented: Bool {
        get { permissionNotice != nil }
        set {
            if !newValue && permissionNotice != nil {
                dismissPermissionNotice()
            }
        }
    }

    public func dismissPermissionNotice() {
        permissionNotice = nil
        if phase == .drilling && cardPhase == .activeCountdown {
            wordStartTime = Date()
            startStopwatch()
        }
    }

    public var sessionSummary: ReflexBlitzSessionSummary?
    public var attempts: [ReflexBlitzAttempt] = []
    public var weeklyPracticedCount: Int = 0
    public var weakWordsCount: Int = 0
    public var averageSpeedSeconds: Double = 0.0

    public var isFeedbackPresented: Bool {
        get {
            if case .reviewed = cardPhase {
                return true
            }
            return false
        }
        set {
            if !newValue && isFeedbackPresented {
                advanceToNextWord()
            }
        }
    }

    public var currentHandler: ReflexModeHandlerProtocol {
        ReflexModeHandlerFactory.handler(for: selectedMode)
    }

    let speechEngine: ReflexSpeechEngineProtocol
    let ttsService: TextToSpeechProtocol
    let evaluateSRSUseCase: EvaluateSRSUseCaseProtocol
    let soundEffectService: SoundEffectServiceProtocol

    var countdownTask: Task<Void, Never>?
    var hintTasks: [Task<Void, Never>] = []
    var timeoutTimerTask: Task<Void, Never>?
    var advanceTask: Task<Void, Never>?
    var reviewAudioTask: Task<Void, Never>?
    var speechStartTask: Task<Void, Never>?
    var wordGeneration: UInt = 0
    public var wordStartTime: Date?

    public var currentWord: ReflexBlitzWordItem? {
        guard currentWordIndex >= 0 && currentWordIndex < words.count else { return nil }
        return words[currentWordIndex]
    }

    public var progressFraction: Double {
        guard !words.isEmpty else { return 0 }
        return Double(currentWordIndex) / Double(words.count)
    }

    public var fractionRemaining: Double {
        let limit = currentHandler.timeLimitSeconds * 1000.0
        guard limit > 0 else { return 0 }
        return max(0.0, min(1.0, 1.0 - Double(elapsedTimeMs) / limit))
    }

    public var timerStage: ReflexBlitzTimerStage {
        let limit = currentHandler.timeLimitSeconds * 1000.0
        let warningThreshold = limit * (3.5 / 6.0)
        let urgentThreshold = limit * (5.0 / 6.0)
        if Double(elapsedTimeMs) < warningThreshold {
            return .steady
        } else if Double(elapsedTimeMs) < urgentThreshold {
            return .warning
        } else {
            return .urgent
        }
    }

    public convenience init(
        words: [ReflexBlitzWordItem] = ReflexBlitzWordItem.defaultStarterWords,
        weeklyPracticedCount: Int = 0,
        weakWordsCount: Int = 0,
        averageSpeedSeconds: Double = 0.0
    ) {
        self.init(
            words: words,
            weeklyPracticedCount: weeklyPracticedCount,
            weakWordsCount: weakWordsCount,
            averageSpeedSeconds: averageSpeedSeconds,
            ttsService: TextToSpeechService(),
            evaluateSRSUseCase: EvaluateSRSUseCase(srsRepository: SRSRepositoryImpl()),
            soundEffectService: SoundEffectService.shared,
            speechEngine: ResilientReflexSpeechEngine()
        )
    }

    public init(
        words: [ReflexBlitzWordItem] = ReflexBlitzWordItem.defaultStarterWords,
        weeklyPracticedCount: Int = 0,
        weakWordsCount: Int = 0,
        averageSpeedSeconds: Double = 0.0,
        ttsService: TextToSpeechProtocol,
        evaluateSRSUseCase: EvaluateSRSUseCaseProtocol,
        soundEffectService: SoundEffectServiceProtocol = SoundEffectService.shared,
        speechEngine: ReflexSpeechEngineProtocol? = nil
    ) {
        self.words = words
        self.weeklyPracticedCount = weeklyPracticedCount
        self.weakWordsCount = weakWordsCount
        self.averageSpeedSeconds = averageSpeedSeconds
        self.ttsService = ttsService
        self.evaluateSRSUseCase = evaluateSRSUseCase
        self.soundEffectService = soundEffectService
        self.speechEngine = speechEngine ?? ResilientReflexSpeechEngine()
        setupSpeechEngineBindings()
    }

    private func setupSpeechEngineBindings() {
        speechEngine.onMatchDetected = { [weak self] matched in
            self?.handleSpokenMatch(matched)
        }
        speechEngine.onTranscriptUpdate = { [weak self] transcript in
            self?.liveTranscript = transcript
        }
        speechEngine.onError = { error in
            print("[ReflexBlitzViewModel] Speech engine error: \(error.localizedDescription)")
        }
    }

    func cancelActiveTimers() {
        speechStartTask?.cancel()
        speechStartTask = nil
        wordGeneration &+= 1
        for task in hintTasks {
            task.cancel()
        }
        hintTasks.removeAll()
        timeoutTimerTask?.cancel()
        reviewAudioTask?.cancel()
    }

    func cancelAllTasks() {
        countdownTask?.cancel()
        advanceTask?.cancel()
        cancelActiveTimers()
    }
}
