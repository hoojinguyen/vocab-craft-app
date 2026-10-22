@preconcurrency import AVFoundation
import CraftUIKit
import Foundation
import Observation
import SpeechKit

public enum ShadowingRoundStage: String, Sendable, Equatable, CaseIterable, Identifiable {
    case round1Immersion
    case round2SpeedShadowing
    case round3EchoDrill
    case summaryReport

    public var id: String { rawValue }
}

@MainActor
@Observable
public final class ShadowingStudioViewModel: Identifiable {
    public nonisolated var id: String { video.id }
    public let video: ShadowingVideo
    public var activeRound: ShadowingRoundStage = .round1Immersion
    public var isPlaying: Bool = true
    public var playbackSpeed: Float = 1.0
    public var currentVideoTime: Double = 0.0
    public var isHeadphonesConnected: Bool = false {
        didSet {
            handleHeadphoneDisconnectionIfNeeded()
        }
    }
    public var playbackError: String?
    public var hasPlaybackError: Bool { playbackError != nil }
    public var currentSentenceIndex: Int = 0
    public var playbackPhase: ShadowingPlaybackPhase = .idle
    public var currentEvaluation: SpeechEvaluationResult?
    public var currentEvaluationTokens: [CraftSpeechWordToken]? {
        currentEvaluation?.tokens.map(\.asCraftSpeechWordToken)
    }
    public var sentenceAttempts: [String: SentenceAttemptRecord] = [:]
    public var bookmarkedWordIds: Set<String> = []
    public var selectedKeyWordForPopover: ShadowingKeyWord?
    public var round2AudioURL: URL?

    public var averageMasteryScore: Double {
        guard !sentenceAttempts.isEmpty else { return 0.0 }
        let total = sentenceAttempts.values.reduce(0.0) { $0 + $1.score }
        return total / Double(sentenceAttempts.count)
    }

    public var currentSentence: ShadowingSentence {
        guard !video.sentences.isEmpty else {
            return ShadowingSentence(
                id: "",
                orderIndex: 0,
                startTime: 0,
                endTime: 0,
                textEn: "",
                textVi: ""
            )
        }
        guard currentSentenceIndex < video.sentences.count else {
            return video.sentences.last ?? ShadowingSentence(
                id: "",
                orderIndex: 0,
                startTime: 0,
                endTime: 0,
                textEn: "",
                textVi: ""
            )
        }
        return video.sentences[currentSentenceIndex]
    }

    public var nextSentence: ShadowingSentence? {
        let nextIndex = currentSentenceIndex + 1
        guard nextIndex < video.sentences.count else { return nil }
        return video.sentences[nextIndex]
    }

    public var isLastSentence: Bool {
        video.sentences.isEmpty || currentSentenceIndex >= video.sentences.count - 1
    }

    public let bridgeHolder: YouTubeBridgeHolder
    fileprivate let assessmentService: any SpeechAssessmentProtocol
    public let sessionCoordinator: ShadowingSessionCoordinator
    fileprivate let toggleBookmarkUseCase: (any ToggleWordBookmarkUseCaseProtocol)?
    fileprivate let progressRepository: (any ShadowingProgressRepositoryProtocol)?

    private var routeChangeTask: Task<Void, Never>?

    public init(
        video: ShadowingVideo,
        assessmentService: any SpeechAssessmentProtocol = SpeechAssessmentService(),
        sessionCoordinator: ShadowingSessionCoordinator = ShadowingSessionCoordinator(),
        toggleBookmarkUseCase: (any ToggleWordBookmarkUseCaseProtocol)? = nil,
        progressRepository: (any ShadowingProgressRepositoryProtocol)? = nil,
        bridgeHolder: YouTubeBridgeHolder = YouTubeBridgeHolder()
    ) {
        self.video = video
        self.assessmentService = assessmentService
        self.sessionCoordinator = sessionCoordinator
        self.toggleBookmarkUseCase = toggleBookmarkUseCase
        self.progressRepository = progressRepository
        self.bridgeHolder = bridgeHolder

        checkHeadphoneStatus()
        observeAudioRouteChanges()
    }

    // MARK: - Round Navigation

    public func advanceToNextRound() {
        switch activeRound {
        case .round1Immersion:
            selectRound(.round2SpeedShadowing)
        case .round2SpeedShadowing:
            selectRound(.round3EchoDrill)
        case .round3EchoDrill:
            selectRound(.summaryReport)
        case .summaryReport:
            break
        }
    }

    public func startActiveRound() {
        switch activeRound {
        case .round1Immersion:
            startRound1Playback()
        case .round2SpeedShadowing:
            startRound2Playback()
        case .round3EchoDrill:
            startCurrentSentence()
        case .summaryReport:
            bridgeHolder.pauseVideo()
            isPlaying = false
        }
    }

    public func startRound1Playback() {
        isPlaying = true
        bridgeHolder.playSegment(start: 0, end: video.durationSeconds, rate: playbackSpeed)
    }

    public func selectRound(_ round: ShadowingRoundStage) {
        if activeRound == .round2SpeedShadowing && round != .round2SpeedShadowing {
            if sessionCoordinator.recorder.isRecording {
                sessionCoordinator.recorder.stopRecording()
            }
        }
        activeRound = round
        switch round {
        case .round1Immersion:
            currentSentenceIndex = 0
            currentVideoTime = 0.0
            isPlaying = true
        case .round2SpeedShadowing:
            currentSentenceIndex = 0
            currentVideoTime = 0.0
            checkHeadphoneStatus()
        case .round3EchoDrill:
            currentSentenceIndex = 0
            playbackPhase = .idle
            bridgeHolder.pauseVideo()
            isPlaying = false
        case .summaryReport:
            bridgeHolder.pauseVideo()
            isPlaying = false
            Task { [sessionCoordinator] in
                await sessionCoordinator.releaseAll()
            }
        }
    }

    // MARK: - Video & Playback Controls

    public func setPlaybackSpeed(_ speed: Float) {
        playbackSpeed = speed
        bridgeHolder.setPlaybackRate(speed)
    }

    public func rewind5Seconds() {
        let newTime = max(0.0, currentVideoTime - 5.0)
        currentVideoTime = newTime
        updateSentenceIndexForTime(newTime)
        bridgeHolder.seekTo(seconds: newTime)
    }

    public func togglePlayPause() {
        if isPlaying {
            isPlaying = false
            bridgeHolder.pauseVideo()
        } else {
            isPlaying = true
            bridgeHolder.playVideo()
        }
    }

    public func handleTimeUpdate(seconds: Double) {
        currentVideoTime = seconds
        updateSentenceIndexForTime(seconds)
    }

    public func handleSegmentFinished() {
        if case .evaluated = playbackPhase { return }
        if activeRound == .round3EchoDrill {
            playbackPhase = .readyToRecord
        }
    }

    private func updateSentenceIndexForTime(_ time: Double) {
        guard !video.sentences.isEmpty else { return }
        if time < video.sentences[0].startTime {
            currentSentenceIndex = 0
            return
        }
        for (index, sentence) in video.sentences.enumerated() {
            let isLast = index == video.sentences.count - 1
            let nextStartTime = isLast ? Double.infinity : video.sentences[index + 1].startTime
            if time >= sentence.startTime && time < nextStartTime {
                currentSentenceIndex = index
                return
            }
        }
        currentSentenceIndex = video.sentences.count - 1
    }

    // MARK: - Headphone Detection

    public func checkHeadphoneStatus() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        let hasHeadphones = session.currentRoute.outputs.contains { output in
            output.portType == .headphones ||
            output.portType == .bluetoothA2DP ||
            output.portType == .bluetoothHFP ||
            output.portType == .bluetoothLE ||
            output.portType == .airPlay
        }
        isHeadphonesConnected = hasHeadphones
        #endif
        handleHeadphoneDisconnectionIfNeeded()
    }

    public func handleHeadphoneDisconnectionIfNeeded() {
        if activeRound == .round2SpeedShadowing && !isHeadphonesConnected && sessionCoordinator.recorder.isRecording {
            sessionCoordinator.recorder.stopRecording()
            round2AudioURL = nil
            Task { [sessionCoordinator] in
                try? await sessionCoordinator.prepareForNativePlayback()
            }
        }
    }

    private func observeAudioRouteChanges() {
        #if os(iOS)
        routeChangeTask = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: AVAudioSession.routeChangeNotification) {
                guard !Task.isCancelled else { break }
                self?.checkHeadphoneStatus()
            }
        }
        #endif
    }

    // MARK: - Error Handling & Playback Recovery

    public func handlePlaybackError(code: Int) {
        playbackError = String(localized: "app.shadowing.error.playback_failed")
        isPlaying = false
    }

    public func retryPlayback() {
        playbackError = nil
        bridgeHolder.reload()
        startActiveRound()
    }

    public func cleanup() {
        routeChangeTask?.cancel()
        routeChangeTask = nil
        bridgeHolder.pauseVideo()
        assessmentService.stopAssessing()
        Task { [sessionCoordinator] in
            await sessionCoordinator.releaseAll()
        }
    }
}

// MARK: - Round Operations & Recording

extension ShadowingStudioViewModel {
    // MARK: - Round 2 Speed Shadowing

    public func startRound2Playback() {
        Task { [weak self] in
            await self?.startRound2PlaybackAsync()
        }
    }

    public func startRound2PlaybackAsync() async {
        if isHeadphonesConnected {
            do {
                try await sessionCoordinator.prepareForSpeechCapture()
                let audioURL = try sessionCoordinator.recorder.startRecording(sentenceId: "round2_\(video.id)")
                round2AudioURL = audioURL
                isPlaying = true
                bridgeHolder.playSegment(start: 0, end: video.durationSeconds, rate: playbackSpeed)
            } catch {
                await startRound2PlaybackWithoutCapture()
            }
        } else {
            await startRound2PlaybackWithoutCapture()
        }
    }

    private func startRound2PlaybackWithoutCapture() async {
        round2AudioURL = nil
        try? await sessionCoordinator.prepareForNativePlayback()
        isPlaying = true
        bridgeHolder.playSegment(start: 0, end: video.durationSeconds, rate: playbackSpeed)
    }

    // MARK: - Round 3 Echo Drilling

    public func startCurrentSentence() {
        Task { [weak self] in
            await self?.startCurrentSentenceAsync()
        }
    }

    public func startCurrentSentenceAsync() async {
        do {
            try await sessionCoordinator.prepareForNativePlayback()
            playbackPhase = .playingNative(currentTime: currentSentence.startTime)
            bridgeHolder.playSegment(
                start: currentSentence.startTime,
                end: currentSentence.endTime,
                rate: playbackSpeed
            )
        } catch {
            playbackPhase = .readyToRecord
        }
    }

    public func toggleRecording() {
        if case .listening = playbackPhase {
            stopRecording()
        } else {
            startRecording()
        }
    }

    public func startRecording() {
        Task { [weak self] in
            await self?.startRecordingAsync()
        }
    }

    public func startRecordingAsync() async {
        do {
            try await sessionCoordinator.prepareForSpeechCapture()
            let audioURL = try sessionCoordinator.recorder.startRecording(sentenceId: currentSentence.id)
            playbackPhase = .listening(levels: [])

            assessmentService.startAssessing(
                targetSentence: currentSentence.textEn,
                toleranceThreshold: 0.70,
                contextualPhrases: currentSentence.keyWords.map(\.lemma),
                onProgress: { [weak self] partial in
                    self?.currentEvaluation = partial
                },
                onCompletion: { [weak self] finalEval in
                    self?.finishEvaluation(finalEval, audioURL: audioURL)
                },
                onError: { [weak self] _ in
                    self?.playbackPhase = .readyToRecord
                }
            )
        } catch {
            playbackPhase = .readyToRecord
        }
    }

    public func stopRecording() {
        assessmentService.stopAssessing()
        sessionCoordinator.recorder.stopRecording()
        playbackPhase = .evaluating
    }

    private func finishEvaluation(_ evaluation: SpeechEvaluationResult, audioURL: URL) {
        currentEvaluation = evaluation
        let isPassed = evaluation.overallScore >= 70.0
        sentenceAttempts[currentSentence.id] = SentenceAttemptRecord(
            score: evaluation.overallScore,
            userAudioURL: audioURL,
            isPassed: isPassed
        )
        playbackPhase = .evaluated(score: evaluation.overallScore)
    }

    public func playNativeAudio() {
        Task {
            try? await sessionCoordinator.prepareForNativePlayback()
            bridgeHolder.playSegment(
                start: currentSentence.startTime,
                end: currentSentence.endTime,
                rate: playbackSpeed
            )
        }
    }

    public func playUserAudio() {
        guard let record = sentenceAttempts[currentSentence.id],
              let url = record.userAudioURL else { return }
        Task {
            try? await sessionCoordinator.prepareForNativePlayback()
            try? sessionCoordinator.recorder.playRecordedAudio(from: url)
        }
    }

    public func advanceToNextSentence() {
        guard currentSentenceIndex < video.sentences.count - 1 else { return }
        currentSentenceIndex += 1
        currentEvaluation = nil
        playbackPhase = .idle
        startCurrentSentence()
    }

    public func toggleBookmark(lemma: String, linkedWordId: Int64? = nil) {
        if bookmarkedWordIds.contains(lemma) {
            bookmarkedWordIds.remove(lemma)
        } else {
            bookmarkedWordIds.insert(lemma)
        }

        let effectiveId = linkedWordId ?? currentSentence.keyWords.first(where: { $0.lemma == lemma })?.linkedWordId
        if let effectiveId, let toggleBookmarkUseCase {
            Task {
                try? await toggleBookmarkUseCase.execute(wordId: effectiveId)
            }
        }
    }

    public func toggleBookmark(for keyWord: ShadowingKeyWord) {
        toggleBookmark(lemma: keyWord.lemma, linkedWordId: keyWord.linkedWordId)
    }

    // MARK: - Summary & Persistence

    public func finishSession() async throws {
        guard let progressRepository else { return }
        let scores = sentenceAttempts.mapValues(\.score)
        try await progressRepository.recordCompletion(
            videoId: video.id,
            score: averageMasteryScore,
            sentenceScores: scores
        )
    }

    public func playRound2Audio() {
        guard let url = round2AudioURL else { return }
        Task {
            try? await sessionCoordinator.prepareForNativePlayback()
            try? sessionCoordinator.recorder.playRecordedAudio(from: url)
        }
    }

    public func retryWeakSentences() {
        let weakIndices = video.sentences.indices.filter { idx in
            let sent = video.sentences[idx]
            guard let record = sentenceAttempts[sent.id] else { return true }
            return !record.isPassed || record.score < 70.0
        }
        selectRound(.round3EchoDrill)
        if let firstWeak = weakIndices.first {
            currentSentenceIndex = firstWeak
        } else {
            currentSentenceIndex = 0
        }
        for idx in weakIndices {
            sentenceAttempts.removeValue(forKey: video.sentences[idx].id)
        }
        currentEvaluation = nil
        playbackPhase = .idle
        startCurrentSentence()
    }
}
