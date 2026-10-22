import CraftUIKit
import Foundation
import SpeechKit
import Testing
@testable import VocabCraftApp

@Suite("Shadowing Studio ViewModel Tests")
struct ShadowingStudioViewModelTests {
    private func makeSampleVideo() -> ShadowingVideo {
        ShadowingVideo(
            id: "v-test-1",
            youtubeVideoId: "testYT123",
            title: "Test Studio Video",
            topic: .dailyLife,
            level: "B1",
            durationSeconds: 15.0,
            sentences: [
                ShadowingSentence(
                    id: "s1",
                    orderIndex: 0,
                    startTime: 0.0,
                    endTime: 3.5,
                    textEn: "Good morning, everyone.",
                    textVi: "Chào buổi sáng mọi người.",
                    keyWords: [
                        ShadowingKeyWord(
                            lemma: "morning",
                            phonetic: "/ˈmɔːrnɪŋ/",
                            definitionVi: "buổi sáng",
                            linkedWordId: 101
                        )
                    ]
                ),
                ShadowingSentence(
                    id: "s2",
                    orderIndex: 1,
                    startTime: 4.0,
                    endTime: 8.0,
                    textEn: "Welcome back to our English class.",
                    textVi: "Chào mừng các bạn quay lại lớp học tiếng Anh.",
                    keyWords: [
                        ShadowingKeyWord(
                            lemma: "welcome",
                            phonetic: "/ˈwɛlkəm/",
                            definitionVi: "chào mừng",
                            linkedWordId: 102
                        )
                    ]
                ),
                ShadowingSentence(
                    id: "s3",
                    orderIndex: 2,
                    startTime: 8.5,
                    endTime: 14.0,
                    textEn: "Let us start with sentence shadowing.",
                    textVi: "Hãy cùng bắt đầu với bài luyện tập nhại câu.",
                    keyWords: []
                )
            ]
        )
    }

    // MARK: - Initial State & Properties

    @Test("Verifies initial state conforms to specifications")
    @MainActor
    func testInitialState() {
        let sampleVideo = makeSampleVideo()
        let viewModel = ShadowingStudioViewModel(video: sampleVideo)

        #expect(viewModel.id == "v-test-1")
        #expect(viewModel.activeRound == .round1Immersion)
        #expect(viewModel.isPlaying == true)
        #expect(viewModel.playbackSpeed == 1.0)
        #expect(viewModel.currentVideoTime == 0.0)
        #expect(viewModel.currentSentenceIndex == 0)
        #expect(viewModel.playbackPhase == .idle)
        #expect(viewModel.currentEvaluation == nil)
        #expect(viewModel.currentEvaluationTokens == nil)
        #expect(viewModel.sentenceAttempts.isEmpty)
        #expect(viewModel.bookmarkedWordIds.isEmpty)
        #expect(viewModel.selectedKeyWordForPopover == nil)
        #expect(viewModel.round2AudioURL == nil)
        #expect(viewModel.averageMasteryScore == 0.0)

        #expect(viewModel.currentSentence.id == "s1")
        #expect(viewModel.nextSentence?.id == "s2")
        #expect(!viewModel.isLastSentence)
    }

    // MARK: - Round Progression

    @Test("Verifies round progression advances through all 3 rounds and summary report")
    @MainActor
    func testRoundProgression() {
        let sampleVideo = makeSampleVideo()
        let viewModel = ShadowingStudioViewModel(video: sampleVideo)

        #expect(viewModel.activeRound == .round1Immersion)

        viewModel.advanceToNextRound()
        #expect(viewModel.activeRound == .round2SpeedShadowing)

        viewModel.advanceToNextRound()
        #expect(viewModel.activeRound == .round3EchoDrill)

        viewModel.advanceToNextRound()
        #expect(viewModel.activeRound == .summaryReport)

        // Advancing past summary remains on summaryReport
        viewModel.advanceToNextRound()
        #expect(viewModel.activeRound == .summaryReport)
    }

    @Test("Verifies selectRound switches active round directly")
    @MainActor
    func testSelectRound() {
        let sampleVideo = makeSampleVideo()
        let viewModel = ShadowingStudioViewModel(video: sampleVideo)

        viewModel.selectRound(.round3EchoDrill)
        #expect(viewModel.activeRound == .round3EchoDrill)

        viewModel.selectRound(.round1Immersion)
        #expect(viewModel.activeRound == .round1Immersion)
    }

    // MARK: - Playback Speed Controls

    @Test("Verifies setting playback speed updates both view model and bridgeHolder rate")
    @MainActor
    func testPlaybackSpeedControls() {
        let sampleVideo = makeSampleVideo()
        let viewModel = ShadowingStudioViewModel(video: sampleVideo)

        #expect(viewModel.playbackSpeed == 1.0)
        #expect(viewModel.bridgeHolder.playbackRate == 1.0)

        viewModel.setPlaybackSpeed(0.85)
        #expect(viewModel.playbackSpeed == 0.85)
        #expect(viewModel.bridgeHolder.playbackRate == 0.85)

        viewModel.setPlaybackSpeed(1.0)
        #expect(viewModel.playbackSpeed == 1.0)
        #expect(viewModel.bridgeHolder.playbackRate == 1.0)
    }

    // MARK: - Rewind 5 Seconds

    @Test("Verifies rewind 5 seconds clamps to zero when near beginning and seeks bridgeHolder")
    @MainActor
    func testRewind5SecondsClampsToZero() {
        let sampleVideo = makeSampleVideo()
        let viewModel = ShadowingStudioViewModel(video: sampleVideo)

        viewModel.handleTimeUpdate(seconds: 3.0)
        #expect(viewModel.currentVideoTime == 3.0)

        viewModel.rewind5Seconds()
        #expect(viewModel.currentVideoTime == 0.0)
        #expect(viewModel.bridgeHolder.lastSeekTime == 0.0)
    }

    @Test("Verifies rewind 5 seconds subtracts 5 seconds when past 5 seconds and seeks bridgeHolder")
    @MainActor
    func testRewind5SecondsNonZero() {
        let sampleVideo = makeSampleVideo()
        let viewModel = ShadowingStudioViewModel(video: sampleVideo)

        viewModel.handleTimeUpdate(seconds: 12.0)
        #expect(viewModel.currentVideoTime == 12.0)

        viewModel.rewind5Seconds()
        #expect(viewModel.currentVideoTime == 7.0)
        #expect(viewModel.bridgeHolder.lastSeekTime == 7.0)
    }

    // MARK: - Active & Next Sentence Tracking

    @Test("Verifies active sentence and next sentence tracking based on currentVideoTime")
    @MainActor
    func testActiveSentenceAndNextSentenceTracking() {
        let sampleVideo = makeSampleVideo()
        let viewModel = ShadowingStudioViewModel(video: sampleVideo)

        // Time at sentence 1 (0.0 .. 3.5)
        viewModel.handleTimeUpdate(seconds: 1.5)
        #expect(viewModel.currentSentence.id == "s1")
        #expect(viewModel.nextSentence?.id == "s2")
        #expect(!viewModel.isLastSentence)

        // Time at sentence 2 (4.0 .. 8.0)
        viewModel.handleTimeUpdate(seconds: 5.0)
        #expect(viewModel.currentSentence.id == "s2")
        #expect(viewModel.nextSentence?.id == "s3")
        #expect(!viewModel.isLastSentence)

        // Time at sentence 3 (8.5 .. 14.0)
        viewModel.handleTimeUpdate(seconds: 10.0)
        #expect(viewModel.currentSentence.id == "s3")
        #expect(viewModel.nextSentence == nil)
        #expect(viewModel.isLastSentence)
    }

    // MARK: - Play / Pause Toggle

    @Test("Verifies togglePlayPause toggles isPlaying and delegates to bridgeHolder")
    @MainActor
    func testTogglePlayPause() {
        let sampleVideo = makeSampleVideo()
        let viewModel = ShadowingStudioViewModel(video: sampleVideo)

        #expect(viewModel.isPlaying == true)

        viewModel.togglePlayPause()
        #expect(viewModel.isPlaying == false)
        #expect(viewModel.bridgeHolder.isPlaying == false)

        viewModel.togglePlayPause()
        #expect(viewModel.isPlaying == true)
        #expect(viewModel.bridgeHolder.isPlaying == true)
    }

    // MARK: - Round 2 Speed Shadowing & Headphone Detection

    @Test("Verifies Round 2 starts recording when headphones are connected")
    @MainActor
    func testRound2PlaybackWithHeadphonesStartsRecording() async {
        let sampleVideo = makeSampleVideo()
        let sessionCoordinator = ShadowingSessionCoordinator()
        let viewModel = ShadowingStudioViewModel(
            video: sampleVideo,
            sessionCoordinator: sessionCoordinator
        )

        viewModel.selectRound(.round2SpeedShadowing)
        viewModel.isHeadphonesConnected = true
        await viewModel.startRound2PlaybackAsync()

        #expect(viewModel.round2AudioURL != nil)
        #expect(sessionCoordinator.currentIntent == .speechCapture)

        viewModel.playRound2Audio()
    }

    @Test("Verifies Round 2 skips recording when headphones are NOT connected")
    @MainActor
    func testRound2PlaybackWithoutHeadphonesSkipsRecording() async {
        let sampleVideo = makeSampleVideo()
        let sessionCoordinator = ShadowingSessionCoordinator()
        let viewModel = ShadowingStudioViewModel(
            video: sampleVideo,
            sessionCoordinator: sessionCoordinator
        )

        viewModel.selectRound(.round2SpeedShadowing)
        viewModel.isHeadphonesConnected = false
        await viewModel.startRound2PlaybackAsync()

        #expect(viewModel.round2AudioURL == nil)
        #expect(sessionCoordinator.currentIntent != .speechCapture)
    }

    @Test("Verifies headphone disconnection during Round 2 stops active recording")
    @MainActor
    func testHeadphoneDisconnectionDuringRound2StopsRecording() throws {
        let sampleVideo = makeSampleVideo()
        let sessionCoordinator = ShadowingSessionCoordinator()
        let viewModel = ShadowingStudioViewModel(
            video: sampleVideo,
            sessionCoordinator: sessionCoordinator
        )

        viewModel.selectRound(.round2SpeedShadowing)
        viewModel.isHeadphonesConnected = true

        let url = try sessionCoordinator.recorder.startRecording(sentenceId: "round2_\(sampleVideo.id)")
        viewModel.round2AudioURL = url
        #expect(sessionCoordinator.recorder.isRecording)
        #expect(viewModel.round2AudioURL != nil)

        // Simulate headphone disconnection
        viewModel.isHeadphonesConnected = false

        #expect(!sessionCoordinator.recorder.isRecording)
        #expect(viewModel.round2AudioURL == nil)
    }

    // MARK: - Playback Error Handling & Recovery

    @Test("Verifies playback error sets error state and retry clears error and restarts playback")
    @MainActor
    func testPlaybackErrorHandlingAndRetry() {
        let sampleVideo = makeSampleVideo()
        let viewModel = ShadowingStudioViewModel(video: sampleVideo)

        #expect(viewModel.playbackError == nil)
        #expect(!viewModel.hasPlaybackError)
        #expect(viewModel.isPlaying == true)

        // Handle error from player
        viewModel.handlePlaybackError(code: 150)

        #expect(viewModel.playbackError != nil)
        #expect(viewModel.hasPlaybackError)
        #expect(viewModel.isPlaying == false)

        // Retry playback
        viewModel.retryPlayback()

        #expect(viewModel.playbackError == nil)
        #expect(!viewModel.hasPlaybackError)
        #expect(viewModel.isPlaying == true)
        #expect(viewModel.bridgeHolder.isPlaying == true)
    }

    // MARK: - Round 3 Echo Drill Recording & Scoring

    @Test("Verifies Round 3 echo drilling records, evaluates with SpeechKit, and updates average mastery score")
    @MainActor
    func testRound3EchoDrillFullRecordingAndAssessmentFlow() async {
        let sampleVideo = makeSampleVideo()
        let mockAssessment = MockSpeechAssessmentService()
        let sessionCoordinator = ShadowingSessionCoordinator()
        let viewModel = ShadowingStudioViewModel(
            video: sampleVideo,
            assessmentService: mockAssessment,
            sessionCoordinator: sessionCoordinator
        )

        viewModel.selectRound(.round3EchoDrill)
        #expect(viewModel.currentSentence.id == "s1")

        // Start sentence playback then finish segment
        await viewModel.startCurrentSentenceAsync()
        #expect(viewModel.playbackPhase == .playingNative(currentTime: 0.0))

        viewModel.handleSegmentFinished()
        #expect(viewModel.playbackPhase == .readyToRecord)

        // Start recording
        await viewModel.startRecordingAsync()
        #expect(viewModel.playbackPhase == .listening(levels: []))
        #expect(mockAssessment.isListening)

        // Partial progress
        let partialResult = SpeechEvaluationResult(
            targetSentence: "Good morning, everyone.",
            spokenText: "Good morning",
            tokens: [
                WordTokenResult(targetWord: "Good", spokenWord: "Good", status: .exactMatch, confidence: 0.95),
                WordTokenResult(targetWord: "morning", spokenWord: "morning", status: .exactMatch, confidence: 0.90),
                WordTokenResult(targetWord: "everyone", status: .missing, confidence: 0.0)
            ],
            overallScore: 66.0,
            isPassed: false,
            durationMs: 700
        )
        mockAssessment.simulateProgress(partialResult)
        #expect(viewModel.currentEvaluation?.spokenText == "Good morning")

        // Final completion for sentence 1: 80%
        let finalResult1 = SpeechEvaluationResult(
            targetSentence: "Good morning, everyone.",
            spokenText: "Good morning, everyone.",
            tokens: [
                WordTokenResult(targetWord: "Good", spokenWord: "Good", status: .exactMatch, confidence: 0.95),
                WordTokenResult(targetWord: "morning", spokenWord: "morning", status: .exactMatch, confidence: 0.90),
                WordTokenResult(targetWord: "everyone", spokenWord: "everyone", status: .exactMatch, confidence: 0.88)
            ],
            overallScore: 80.0,
            isPassed: true,
            durationMs: 1200
        )
        mockAssessment.simulateCompletion(finalResult1)

        #expect(viewModel.playbackPhase == .evaluated(score: 80.0))
        #expect(viewModel.sentenceAttempts["s1"]?.score == 80.0)
        #expect(viewModel.sentenceAttempts["s1"]?.isPassed == true)
        #expect(viewModel.averageMasteryScore == 80.0)

        // Advance to sentence 2
        viewModel.advanceToNextSentence()
        #expect(viewModel.currentSentence.id == "s2")
        #expect(viewModel.currentEvaluation == nil)

        // Record sentence 2
        await viewModel.startRecordingAsync()
        let finalResult2 = SpeechEvaluationResult(
            targetSentence: "Welcome back to our English class.",
            spokenText: "Welcome back to our English class.",
            tokens: [
                WordTokenResult(targetWord: "Welcome", spokenWord: "Welcome", status: .exactMatch, confidence: 0.94),
                WordTokenResult(targetWord: "back", spokenWord: "back", status: .exactMatch, confidence: 0.91)
            ],
            overallScore: 90.0,
            isPassed: true,
            durationMs: 1500
        )
        mockAssessment.simulateCompletion(finalResult2)

        #expect(viewModel.sentenceAttempts["s2"]?.score == 90.0)
        // Average mastery score of 80 and 90 is 85.0
        #expect(viewModel.averageMasteryScore == 85.0)
    }

    @Test("Verifies toggleRecording transitions between listening and evaluating")
    @MainActor
    func testToggleRecording() {
        let sampleVideo = makeSampleVideo()
        let mockAssessment = MockSpeechAssessmentService()
        let viewModel = ShadowingStudioViewModel(
            video: sampleVideo,
            assessmentService: mockAssessment
        )

        viewModel.playbackPhase = .listening(levels: [])
        viewModel.toggleRecording()
        #expect(viewModel.playbackPhase == .evaluating)
    }

    // MARK: - Local Progress Persistence via ShadowingProgressRepository

    @Test("Verifies finishSession persists overall score and sentence scores to repository")
    @MainActor
    func testFinishSessionPersistsToProgressRepository() async throws {
        let sampleVideo = makeSampleVideo()
        let mockAssessment = MockSpeechAssessmentService()
        let mockRepository = MockShadowingProgressRepository()
        let viewModel = ShadowingStudioViewModel(
            video: sampleVideo,
            assessmentService: mockAssessment,
            progressRepository: mockRepository
        )

        // Add 2 sentence attempts directly
        viewModel.sentenceAttempts["s1"] = SentenceAttemptRecord(score: 80.0, isPassed: true)
        viewModel.sentenceAttempts["s2"] = SentenceAttemptRecord(score: 90.0, isPassed: true)
        #expect(viewModel.averageMasteryScore == 85.0)

        try await viewModel.finishSession()

        #expect(mockRepository.recordedVideoId == "v-test-1")
        #expect(mockRepository.recordedScore == 85.0)
        #expect(mockRepository.recordedSentenceScores["s1"] == 80.0)
        #expect(mockRepository.recordedSentenceScores["s2"] == 90.0)
    }

    @Test("Verifies finishSession succeeds gracefully when progressRepository is nil")
    @MainActor
    func testFinishSessionWithoutRepositoryDoesNotThrow() async throws {
        let sampleVideo = makeSampleVideo()
        let viewModel = ShadowingStudioViewModel(
            video: sampleVideo,
            progressRepository: nil
        )

        try await viewModel.finishSession()
    }

    // MARK: - Bookmarks & Key Words

    @Test("Verifies bookmark toggle and key word popover selection")
    @MainActor
    func testBookmarkToggleAndPopover() async {
        let sampleVideo = makeSampleVideo()
        let mockBookmarkUseCase = MockToggleBookmarkUseCase()
        let viewModel = ShadowingStudioViewModel(
            video: sampleVideo,
            toggleBookmarkUseCase: mockBookmarkUseCase
        )

        guard let keyWord = sampleVideo.sentences[0].keyWords.first else {
            Issue.record("Expected keyWord on sentence 0")
            return
        }

        viewModel.selectedKeyWordForPopover = keyWord
        #expect(viewModel.selectedKeyWordForPopover?.lemma == "morning")

        // Toggle ON
        viewModel.toggleBookmark(for: keyWord)
        #expect(viewModel.bookmarkedWordIds.contains("morning"))

        try? await Task.sleep(nanoseconds: 15_000_000)
        #expect(mockBookmarkUseCase.executedWordIds.contains(101))

        // Toggle OFF
        viewModel.toggleBookmark(for: keyWord)
        #expect(!viewModel.bookmarkedWordIds.contains("morning"))
    }

    // MARK: - Native and User Audio Playback

    @Test("Verifies playNativeAudio prepares playback intent and delegates to bridgeHolder")
    @MainActor
    func testPlayNativeAudioPreparesPlayback() async {
        let sampleVideo = makeSampleVideo()
        let sessionCoordinator = ShadowingSessionCoordinator()
        let viewModel = ShadowingStudioViewModel(
            video: sampleVideo,
            sessionCoordinator: sessionCoordinator
        )

        viewModel.playNativeAudio()

        for _ in 0..<50 {
            if sessionCoordinator.currentIntent == .playback { break }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        #expect(sessionCoordinator.currentIntent == .playback)
    }

    @Test("Verifies playUserAudio does not crash when attempt record is missing or present")
    @MainActor
    func testPlayUserAudioWhenAvailable() {
        let sampleVideo = makeSampleVideo()
        let viewModel = ShadowingStudioViewModel(video: sampleVideo)

        // No record yet
        viewModel.playUserAudio()

        // With mock url
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_user_audio.m4a")
        viewModel.sentenceAttempts["s1"] = SentenceAttemptRecord(score: 80.0, userAudioURL: tempURL, isPassed: true)
        viewModel.playUserAudio()
    }

    // MARK: - Cleanup and Edge Cases

    @Test("Verifies cleanup pauses video, releases coordinator and stops assessment")
    @MainActor
    func testCleanupStopsAssessmentAndReleasesSession() {
        let sampleVideo = makeSampleVideo()
        let mockAssessment = MockSpeechAssessmentService()
        let viewModel = ShadowingStudioViewModel(
            video: sampleVideo,
            assessmentService: mockAssessment
        )

        viewModel.playbackPhase = .listening(levels: [])
        viewModel.cleanup()
        #expect(!mockAssessment.isListening)
    }

    @Test("Verifies empty video edge case falls back safely")
    @MainActor
    func testEmptyVideoEdgeCase() {
        let emptyVideo = ShadowingVideo(
            id: "empty",
            youtubeVideoId: "none",
            title: "Empty Video",
            topic: .businessEnglish,
            level: "A1",
            durationSeconds: 0,
            sentences: []
        )
        let viewModel = ShadowingStudioViewModel(video: emptyVideo)

        #expect(viewModel.currentSentence.id.isEmpty)
        #expect(viewModel.nextSentence == nil)
        #expect(viewModel.isLastSentence)
    }
}

// MARK: - Test Mocks

private final class MockShadowingProgressRepository: ShadowingProgressRepositoryProtocol, @unchecked Sendable {
    var recordedVideoId: String?
    var recordedScore: Double?
    var recordedSentenceScores: [String: Double] = [:]
    var progressMap: [String: ShadowingProgressRecord] = [:]

    func getProgress(videoId: String) async -> ShadowingProgressRecord? {
        progressMap[videoId]
    }

    func recordCompletion(videoId: String, score: Double, sentenceScores: [String: Double]) async throws {
        recordedVideoId = videoId
        recordedScore = score
        recordedSentenceScores = sentenceScores
        let record = ShadowingProgressRecord(
            videoId: videoId,
            bestScore: score,
            lastCompletedAt: Date(),
            timesCompleted: 1,
            sentenceScores: sentenceScores
        )
        progressMap[videoId] = record
    }

    func getAllProgress() async -> [String: ShadowingProgressRecord] {
        progressMap
    }
}

private final class MockToggleBookmarkUseCase: ToggleWordBookmarkUseCaseProtocol, @unchecked Sendable {
    var executedWordIds: [Int64] = []

    func execute(wordId: Int64) async throws -> Bool {
        executedWordIds.append(wordId)
        return true
    }
}
