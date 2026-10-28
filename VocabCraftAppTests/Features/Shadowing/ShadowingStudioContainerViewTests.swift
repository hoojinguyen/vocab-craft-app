import CraftUIKit
import Foundation
import SwiftUI
import Testing
@testable import VocabCraftApp

@Suite("Shadowing Studio Container & Round Views Tests")
struct ShadowingStudioContainerViewTests {
    private func makeSampleVideo() -> ShadowingVideo {
        ShadowingVideo(
            id: "vid-studio-test",
            youtubeVideoId: "testYT999",
            title: "Ordering at a London Café",
            topic: .dailyLife,
            level: "A2",
            durationSeconds: 25.0,
            sentences: [
                ShadowingSentence(
                    id: "s1",
                    orderIndex: 0,
                    startTime: 0.0,
                    endTime: 4.0,
                    textEn: "Hello! What can I get started for you today?",
                    textVi: "Xin chào! Hôm nay tôi có thể lấy gì cho bạn?",
                    keyWords: [
                        ShadowingKeyWord(
                            lemma: "started",
                            phonetic: "/ˈstɑːrtɪd/",
                            definitionVi: "bắt đầu",
                            linkedWordId: 201
                        )
                    ]
                ),
                ShadowingSentence(
                    id: "s2",
                    orderIndex: 1,
                    startTime: 4.5,
                    endTime: 9.0,
                    textEn: "I'd like an oat milk latte to take away.",
                    textVi: "Cho tôi một ly latte sữa yến mạch mang đi.",
                    keyWords: [
                        ShadowingKeyWord(
                            lemma: "oat milk",
                            phonetic: "/oʊt mɪlk/",
                            definitionVi: "sữa yến mạch",
                            linkedWordId: 202
                        )
                    ]
                )
            ]
        )
    }

    @Test("Verifies ShadowingStudioContainerView instantiates successfully across all round stages")
    @MainActor
    func testContainerInstantiationForAllRoundStages() {
        let video = makeSampleVideo()
        let viewModel = ShadowingStudioViewModel(video: video)

        for stage in ShadowingRoundStage.allCases {
            viewModel.selectRound(stage)
            #expect(viewModel.activeRound == stage)
            _ = ShadowingStudioContainerView(viewModel: viewModel)

        }
    }

    @Test("Verifies ShadowingImmersionView instantiates and starts playback")
    @MainActor
    func testImmersionViewInstantiation() {
        let video = makeSampleVideo()
        let viewModel = ShadowingStudioViewModel(video: video)
        viewModel.selectRound(.round1Immersion)

        _ = ShadowingImmersionView(viewModel: viewModel)

        #expect(viewModel.activeRound == .round1Immersion)
    }

    @Test("Verifies ShadowingSpeedView instantiates and reflects headphone status")
    @MainActor
    func testSpeedViewInstantiation() {
        let video = makeSampleVideo()
        let viewModel = ShadowingStudioViewModel(video: video)
        viewModel.selectRound(.round2SpeedShadowing)

        _ = ShadowingSpeedView(viewModel: viewModel)

        #expect(viewModel.activeRound == .round2SpeedShadowing)
    }

    @Test("Verifies ShadowingEchoView instantiates and controls sentence progression")
    @MainActor
    func testEchoViewInstantiation() {
        let video = makeSampleVideo()
        let viewModel = ShadowingStudioViewModel(video: video)
        viewModel.selectRound(.round3EchoDrill)

        _ = ShadowingEchoView(viewModel: viewModel)

        #expect(viewModel.activeRound == .round3EchoDrill)
    }

    @Test("Verifies ShadowingSummaryReportView instantiates with score and actions")
    @MainActor
    func testSummaryReportViewInstantiation() {
        let video = makeSampleVideo()
        let viewModel = ShadowingStudioViewModel(video: video)
        viewModel.selectRound(.summaryReport)

        var finished = false
        _ = ShadowingSummaryReportView(viewModel: viewModel, onFinish: {
            finished = true
        })

        #expect(viewModel.activeRound == .summaryReport)
        #expect(!finished)
    }

    @Test("Verifies AppContainer factory methods create Shadowing view models")
    @MainActor
    func testAppContainerFactoryMethods() {
        let container = AppContainer(useMockData: true, useSampleData: true)
        let video = makeSampleVideo()

        let studioVM = container.makeShadowingStudioViewModel(for: video)
        #expect(studioVM.video.id == video.id)
        #expect(studioVM.activeRound == .round1Immersion)

        let hubVM = container.makeShadowingHubViewModel()
        #expect(hubVM.selectedLevelFilter == nil)
    }

    @Test("Verifies round progression advances step-by-step to summary")
    @MainActor
    func testRoundProgressionStepByStep() {
        let video = makeSampleVideo()
        let viewModel = ShadowingStudioViewModel(video: video)

        #expect(viewModel.activeRound == .round1Immersion)
        viewModel.advanceToNextRound()
        #expect(viewModel.activeRound == .round2SpeedShadowing)
        viewModel.advanceToNextRound()
        #expect(viewModel.activeRound == .round3EchoDrill)
        viewModel.advanceToNextRound()
        #expect(viewModel.activeRound == .summaryReport)
    }

    @Test("Verifies retryWeakSentences resets weak attempts and re-enters Round 3")
    @MainActor
    func testRetryWeakSentences() {
        let video = makeSampleVideo()
        let viewModel = ShadowingStudioViewModel(video: video)

        viewModel.sentenceAttempts["s1"] = SentenceAttemptRecord(score: 85.0, userAudioURL: nil, isPassed: true)
        viewModel.sentenceAttempts["s2"] = SentenceAttemptRecord(score: 45.0, userAudioURL: nil, isPassed: false)
        viewModel.selectRound(.summaryReport)

        viewModel.retryWeakSentences()

        #expect(viewModel.activeRound == .round3EchoDrill)
        #expect(viewModel.currentSentenceIndex == 1) // "s2" is weak
        #expect(viewModel.sentenceAttempts["s2"] == nil)
        #expect(viewModel.sentenceAttempts["s1"] != nil)
    }
}
