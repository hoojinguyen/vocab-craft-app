import Foundation
import SpeechKit
import Testing
@testable import VocabCraftApp

@Suite("Shadowing Practice ViewModel Tests")
struct ShadowingPracticeViewModelTests {
    private func makeSampleVideo() -> ShadowingVideo {
        ShadowingVideo(
            id: "v1",
            youtubeVideoId: "test",
            title: "Test Video",
            topic: .dailyLife,
            level: "A2",
            durationSeconds: 10.0,
            sentences: [
                ShadowingSentence(
                    id: "s1",
                    orderIndex: 0,
                    startTime: 0,
                    endTime: 3,
                    textEn: "Hello world",
                    textVi: "Chào thế giới",
                    keyWords: [
                        ShadowingKeyWord(
                            lemma: "hello",
                            phonetic: "/həˈloʊ/",
                            definitionVi: "Xin chào",
                            linkedWordId: 42
                        )
                    ]
                ),
                ShadowingSentence(
                    id: "s2",
                    orderIndex: 1,
                    startTime: 4,
                    endTime: 7,
                    textEn: "How are you",
                    textVi: "Bạn khoẻ không",
                    keyWords: []
                )
            ]
        )
    }

    @Test("Verifies flow from video playback to ready to record, and advancing sentence")
    @MainActor
    func testViewModelFlow() async throws {
        let sampleVideo = makeSampleVideo()
        let mockAssessment = MockSpeechAssessmentService()
        let viewModel = ShadowingPracticeViewModel(
            video: sampleVideo,
            assessmentService: mockAssessment,
            sessionCoordinator: ShadowingSessionCoordinator()
        )

        #expect(viewModel.currentSentence.id == "s1")
        #expect(viewModel.playbackPhase == .idle)
        #expect(!viewModel.isLastSentence)

        viewModel.handleSegmentFinished()
        #expect(viewModel.playbackPhase == .readyToRecord)

        viewModel.advanceToNextSentence()
        #expect(viewModel.currentSentence.id == "s2")
        #expect(viewModel.isLastSentence)

        // Advancing when at last sentence does not out-of-bounds
        viewModel.advanceToNextSentence()
        #expect(viewModel.currentSentence.id == "s2")
        #expect(viewModel.isLastSentence)
    }

    @Test("Verifies playback speed changes")
    @MainActor
    func testSpeedControl() {
        let sampleVideo = makeSampleVideo()
        let mockAssessment = MockSpeechAssessmentService()
        let viewModel = ShadowingPracticeViewModel(
            video: sampleVideo,
            assessmentService: mockAssessment,
            sessionCoordinator: ShadowingSessionCoordinator()
        )

        #expect(viewModel.playbackSpeed == 1.0)
        viewModel.setSpeed(0.75)
        #expect(viewModel.playbackSpeed == 0.75)
        viewModel.setSpeed(0.9)
        #expect(viewModel.playbackSpeed == 0.9)
    }

    @Test("Verifies starting current sentence playback")
    @MainActor
    func testStartCurrentSentencePlayback() async {
        let sampleVideo = makeSampleVideo()
        let mockAssessment = MockSpeechAssessmentService()
        let viewModel = ShadowingPracticeViewModel(
            video: sampleVideo,
            assessmentService: mockAssessment,
            sessionCoordinator: ShadowingSessionCoordinator()
        )

        await viewModel.startCurrentSentenceAsync()
        #expect(viewModel.playbackPhase == .playingNative(currentTime: 0.0))
    }

    @Test("Verifies recording flow with live assessment and passing score")
    @MainActor
    func testRecordingFlowPassing() async {
        let sampleVideo = makeSampleVideo()
        let mockAssessment = MockSpeechAssessmentService()
        let viewModel = ShadowingPracticeViewModel(
            video: sampleVideo,
            assessmentService: mockAssessment,
            sessionCoordinator: ShadowingSessionCoordinator()
        )

        await viewModel.startRecordingAsync()
        #expect(viewModel.playbackPhase == .listening(levels: []))
        #expect(mockAssessment.isListening)

        // Progress update
        let progressResult = SpeechEvaluationResult(
            targetSentence: "Hello world",
            spokenText: "Hello",
            tokens: [
                WordTokenResult(targetWord: "Hello", spokenWord: "Hello", status: .exactMatch, confidence: 0.95),
                WordTokenResult(targetWord: "world", status: .missing, confidence: 0.0)
            ],
            overallScore: 50.0,
            isPassed: false,
            durationMs: 800
        )
        mockAssessment.simulateProgress(progressResult)
        #expect(viewModel.currentEvaluation?.spokenText == "Hello")

        // Final completion with passing score (>= 70%)
        let completionResult = SpeechEvaluationResult(
            targetSentence: "Hello world",
            spokenText: "Hello world",
            tokens: [
                WordTokenResult(targetWord: "Hello", spokenWord: "Hello", status: .exactMatch, confidence: 0.95),
                WordTokenResult(targetWord: "world", spokenWord: "world", status: .exactMatch, confidence: 0.92)
            ],
            overallScore: 93.5,
            isPassed: true,
            durationMs: 1400
        )
        mockAssessment.simulateCompletion(completionResult)

        #expect(viewModel.playbackPhase == .evaluated(score: 93.5))
        #expect(viewModel.currentEvaluation?.overallScore == 93.5)

        let attempt = viewModel.sentenceAttempts["s1"]
        #expect(attempt != nil)
        #expect(attempt?.score == 93.5)
        #expect(attempt?.isPassed == true)
        #expect(attempt?.userAudioURL != nil)
    }

    @Test("Verifies recording flow with evaluation below threshold (< 70%)")
    @MainActor
    func testRecordingFlowFailing() async {
        let sampleVideo = makeSampleVideo()
        let mockAssessment = MockSpeechAssessmentService()
        let viewModel = ShadowingPracticeViewModel(
            video: sampleVideo,
            assessmentService: mockAssessment,
            sessionCoordinator: ShadowingSessionCoordinator()
        )

        await viewModel.startRecordingAsync()

        let completionResult = SpeechEvaluationResult(
            targetSentence: "Hello world",
            spokenText: "Hi",
            tokens: [
                WordTokenResult(targetWord: "Hello", spokenWord: "Hi", status: .fuzzyMatch, confidence: 0.5),
                WordTokenResult(targetWord: "world", status: .missing, confidence: 0.0)
            ],
            overallScore: 40.0,
            isPassed: false,
            durationMs: 900
        )
        mockAssessment.simulateCompletion(completionResult)

        #expect(viewModel.playbackPhase == .evaluated(score: 40.0))
        let attempt = viewModel.sentenceAttempts["s1"]
        #expect(attempt != nil)
        #expect(attempt?.isPassed == false)
    }

    @Test("Verifies recording error resets to readyToRecord")
    @MainActor
    func testRecordingErrorResetsPhase() async {
        let sampleVideo = makeSampleVideo()
        let mockAssessment = MockSpeechAssessmentService()
        let viewModel = ShadowingPracticeViewModel(
            video: sampleVideo,
            assessmentService: mockAssessment,
            sessionCoordinator: ShadowingSessionCoordinator()
        )

        await viewModel.startRecordingAsync()
        struct TestAudioError: Error {}
        mockAssessment.simulateError(TestAudioError())

        #expect(viewModel.playbackPhase == .readyToRecord)
    }

    @Test("Verifies toggleRecording transitions between listening and evaluating")
    @MainActor
    func testToggleRecording() {
        let sampleVideo = makeSampleVideo()
        let mockAssessment = MockSpeechAssessmentService()
        let viewModel = ShadowingPracticeViewModel(
            video: sampleVideo,
            assessmentService: mockAssessment,
            sessionCoordinator: ShadowingSessionCoordinator()
        )

        viewModel.playbackPhase = .listening(levels: [])
        viewModel.toggleRecording()
        #expect(viewModel.playbackPhase == .evaluating)
    }

    @Test("Verifies word bookmarking and popover selection")
    @MainActor
    func testWordBookmarking() async {
        let sampleVideo = makeSampleVideo()
        let mockAssessment = MockSpeechAssessmentService()
        let mockBookmarkUseCase = MockToggleBookmarkUseCase()
        let viewModel = ShadowingPracticeViewModel(
            video: sampleVideo,
            assessmentService: mockAssessment,
            sessionCoordinator: ShadowingSessionCoordinator(),
            toggleBookmarkUseCase: mockBookmarkUseCase
        )

        let keyword = sampleVideo.sentences[0].keyWords[0]
        viewModel.selectedKeyWordForPopover = keyword
        #expect(viewModel.selectedKeyWordForPopover?.lemma == "hello")

        // Toggle bookmark ON
        viewModel.toggleBookmark(for: keyword)
        #expect(viewModel.bookmarkedWordIds.contains("hello"))

        // Give async task brief execution window
        try? await Task.sleep(nanoseconds: 10_000_000)
        #expect(mockBookmarkUseCase.executedWordIds.contains(42))

        // Toggle bookmark OFF
        viewModel.toggleBookmark(lemma: "hello")
        #expect(!viewModel.bookmarkedWordIds.contains("hello"))
    }

    @Test("Verifies calling handleSegmentFinished while in evaluated phase retains evaluated")
    @MainActor
    func testHandleSegmentFinishedInEvaluatedPhase() {
        let sampleVideo = makeSampleVideo()
        let viewModel = ShadowingPracticeViewModel(
            video: sampleVideo,
            assessmentService: MockSpeechAssessmentService(),
            sessionCoordinator: ShadowingSessionCoordinator()
        )

        viewModel.playbackPhase = .evaluated(score: 85.0)
        viewModel.handleSegmentFinished()
        #expect(viewModel.playbackPhase == .evaluated(score: 85.0))
    }

    @Test("Verifies currentEvaluationTokens maps speech evaluation tokens to CraftSpeechWordTokens")
    @MainActor
    func testCurrentEvaluationTokensMapping() async {
        let sampleVideo = makeSampleVideo()
        let mockAssessment = MockSpeechAssessmentService()
        let viewModel = ShadowingPracticeViewModel(
            video: sampleVideo,
            assessmentService: mockAssessment,
            sessionCoordinator: ShadowingSessionCoordinator()
        )

        #expect(viewModel.currentEvaluationTokens == nil)

        await viewModel.startRecordingAsync()
        let result = SpeechEvaluationResult(
            targetSentence: "Hello world",
            spokenText: "Hello world",
            tokens: [
                WordTokenResult(targetWord: "Hello", spokenWord: "Hello", status: .exactMatch, confidence: 0.95),
                WordTokenResult(targetWord: "world", spokenWord: "world", status: .fuzzyMatch, confidence: 0.6)
            ],
            overallScore: 85.0,
            isPassed: true,
            durationMs: 1200
        )
        mockAssessment.simulateCompletion(result)

        let tokens = viewModel.currentEvaluationTokens
        #expect(tokens?.count == 2)
        #expect(tokens?[0].targetWord == "Hello")
        #expect(tokens?[0].status == .matched)
        #expect(tokens?[1].targetWord == "world")
        #expect(tokens?[1].status == .fuzzy)
    }

    @Test("Verifies playNativeAudio prepares session coordinator for playback")
    @MainActor
    func testPlayNativeAudioPreparesPlayback() async {
        let sampleVideo = makeSampleVideo()
        let sessionCoordinator = ShadowingSessionCoordinator()
        let viewModel = ShadowingPracticeViewModel(
            video: sampleVideo,
            assessmentService: MockSpeechAssessmentService(),
            sessionCoordinator: sessionCoordinator
        )

        viewModel.playNativeAudio()
        for _ in 0..<50 {
            if sessionCoordinator.currentIntent == .playback { break }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        #expect(sessionCoordinator.currentIntent == .playback)
    }

    @Test("Verifies cleanup releases session and stops assessment")
    @MainActor
    func testCleanup() {
        let sampleVideo = makeSampleVideo()
        let mockAssessment = MockSpeechAssessmentService()
        let viewModel = ShadowingPracticeViewModel(
            video: sampleVideo,
            assessmentService: mockAssessment,
            sessionCoordinator: ShadowingSessionCoordinator()
        )

        viewModel.playbackPhase = .listening(levels: [])
        viewModel.cleanup()
        #expect(!mockAssessment.isListening)
    }

    @Test("Verifies empty video edge case fallback")
    @MainActor
    func testEmptyVideoEdgeCase() {
        let emptyVideo = ShadowingVideo(
            id: "empty",
            youtubeVideoId: "test",
            title: "Empty",
            topic: .businessEnglish,
            level: "B1",
            durationSeconds: 0,
            sentences: []
        )
        let viewModel = ShadowingPracticeViewModel(
            video: emptyVideo,
            assessmentService: MockSpeechAssessmentService(),
            sessionCoordinator: ShadowingSessionCoordinator()
        )

        #expect(viewModel.currentSentence.id.isEmpty)
        #expect(viewModel.isLastSentence)
    }
}

private final class MockToggleBookmarkUseCase: ToggleWordBookmarkUseCaseProtocol, @unchecked Sendable {
    var executedWordIds: [Int64] = []

    func execute(wordId: Int64) async throws -> Bool {
        executedWordIds.append(wordId)
        return true
    }
}
