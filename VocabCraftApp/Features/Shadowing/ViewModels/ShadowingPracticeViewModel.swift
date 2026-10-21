import Foundation
import Observation
import SpeechKit

@MainActor
@Observable
public final class ShadowingPracticeViewModel {
    public let video: ShadowingVideo
    public private(set) var currentSentenceIndex: Int = 0
    public var playbackPhase: ShadowingPlaybackPhase = .idle
    public var playbackSpeed: Float = 1.0

    public var currentEvaluation: SpeechEvaluationResult?
    public var sentenceAttempts: [String: SentenceAttemptRecord] = [:]
    public var bookmarkedWordIds: Set<String> = []
    public var selectedKeyWordForPopover: ShadowingKeyWord?

    public let bridgeHolder: YouTubeBridgeHolder
    private let assessmentService: any SpeechAssessmentProtocol
    public let sessionCoordinator: ShadowingSessionCoordinator
    private let toggleBookmarkUseCase: (any ToggleWordBookmarkUseCaseProtocol)?

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

    public var isLastSentence: Bool {
        video.sentences.isEmpty || currentSentenceIndex >= video.sentences.count - 1
    }

    public init(
        video: ShadowingVideo,
        assessmentService: any SpeechAssessmentProtocol = SpeechAssessmentService(),
        sessionCoordinator: ShadowingSessionCoordinator = ShadowingSessionCoordinator(),
        toggleBookmarkUseCase: (any ToggleWordBookmarkUseCaseProtocol)? = nil,
        bridgeHolder: YouTubeBridgeHolder = YouTubeBridgeHolder()
    ) {
        self.video = video
        self.assessmentService = assessmentService
        self.sessionCoordinator = sessionCoordinator
        self.toggleBookmarkUseCase = toggleBookmarkUseCase
        self.bridgeHolder = bridgeHolder
    }

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

    public func handleSegmentFinished() {
        playbackPhase = .readyToRecord
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
        bridgeHolder.playSegment(
            start: currentSentence.startTime,
            end: currentSentence.endTime,
            rate: playbackSpeed
        )
    }

    public func playUserAudio() {
        guard let record = sentenceAttempts[currentSentence.id],
              let url = record.userAudioURL else { return }
        try? sessionCoordinator.recorder.playRecordedAudio(from: url)
    }

    public func advanceToNextSentence() {
        guard currentSentenceIndex < video.sentences.count - 1 else { return }
        currentSentenceIndex += 1
        currentEvaluation = nil
        playbackPhase = .idle
        startCurrentSentence()
    }

    public func setSpeed(_ speed: Float) {
        self.playbackSpeed = speed
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

    public func cleanup() {
        assessmentService.stopAssessing()
        Task { [sessionCoordinator] in
            await sessionCoordinator.releaseAll()
        }
    }
}
