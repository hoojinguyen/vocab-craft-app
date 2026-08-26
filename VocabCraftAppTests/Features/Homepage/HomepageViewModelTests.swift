import CraftUIKit
import SwiftUI
@testable import VocabCraftApp
import XCTest

private final class MockFetchLearningPathUseCase: FetchLearningPathUseCaseProtocol, @unchecked Sendable {
    var stubbedSections: [LessonSection] = []
    var shouldThrowError: Error?
    var executeCallCount = 0

    func execute() async throws -> [LessonSection] {
        executeCallCount += 1
        if let error = shouldThrowError {
            throw error
        }
        return stubbedSections
    }
}

private final class MockTTS: TextToSpeechProtocol {
    var isSpeaking: Bool = false
    var lastSpokenText: String?

    func speak(text: String, rate: Float, locale: String) {
        lastSpokenText = text
    }

    func stop() {
        isSpeaking = false
    }
}

private enum MockError: LocalizedError {
    case networkFailure

    var errorDescription: String? {
        "Failed to load learning path"
    }
}

@MainActor
final class HomepageViewModelTests: XCTestCase {

    private func makeSampleSection() -> LessonSection {
        LessonSection(
            id: "deck_1",
            title: "Unit 1: Basics",
            subtitle: "Essential words",
            level: "A1",
            progress: "1/2",
            nodes: [
                LessonNodeModel(
                    id: "node_1",
                    title: "Greetings",
                    subtitle: "10 words • 5 min",
                    iconName: "hand.wave.fill",
                    state: .completed,
                    kind: .standard,
                    xpReward: 20
                ),
                LessonNodeModel(
                    id: "node_2",
                    title: "Introductions",
                    subtitle: "12 words • 6 min",
                    iconName: "person.fill",
                    state: .active,
                    kind: .standard,
                    xpReward: 25
                ),
                LessonNodeModel(
                    id: "node_3",
                    title: "Review Exam",
                    subtitle: "22 words • 10 min",
                    iconName: "crown.fill",
                    state: .locked,
                    kind: .checkpoint,
                    xpReward: 50
                )
            ]
        )
    }

    func testInitializationDefaults() {
        let vm = HomepageViewModel()
        XCTAssertEqual(vm.userName, "Hooji N.")
        XCTAssertEqual(vm.streakDays, 14)
        XCTAssertEqual(vm.dailyGoalProgress, 0.75)
        XCTAssertFalse(vm.unreadNotifications)
        XCTAssertTrue(vm.sections.isEmpty)
        XCTAssertNil(vm.selectedNode)
        XCTAssertFalse(vm.isDetailSheetPresented)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    func testInitializationCustomValues() {
        let section = makeSampleSection()
        let mockUseCase = MockFetchLearningPathUseCase()
        let mockTTS = MockTTS()

        let vm = HomepageViewModel(
            fetchLearningPathUseCase: mockUseCase,
            ttsService: mockTTS,
            userName: "Alex Swift",
            streakDays: 30,
            dailyGoalProgress: 1.0,
            unreadNotifications: true,
            sections: [section]
        )

        XCTAssertEqual(vm.userName, "Alex Swift")
        XCTAssertEqual(vm.streakDays, 30)
        XCTAssertEqual(vm.dailyGoalProgress, 1.0)
        XCTAssertTrue(vm.unreadNotifications)
        XCTAssertEqual(vm.sections.count, 1)
        XCTAssertEqual(vm.sections.first?.id, "deck_1")
    }

    func testLoadLearningPathSuccess() async {
        let mockUseCase = MockFetchLearningPathUseCase()
        let sampleSection = makeSampleSection()
        mockUseCase.stubbedSections = [sampleSection]

        let vm = HomepageViewModel(fetchLearningPathUseCase: mockUseCase)

        XCTAssertFalse(vm.isLoading)
        XCTAssertTrue(vm.sections.isEmpty)

        await vm.loadLearningPath()

        XCTAssertEqual(mockUseCase.executeCallCount, 1)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(vm.sections.count, 1)
        XCTAssertEqual(vm.sections.first?.title, "Unit 1: Basics")
        XCTAssertEqual(vm.sections.first?.nodes.count, 3)
    }

    func testLoadLearningPathFailure() async {
        let mockUseCase = MockFetchLearningPathUseCase()
        mockUseCase.shouldThrowError = MockError.networkFailure

        let vm = HomepageViewModel(fetchLearningPathUseCase: mockUseCase)

        await vm.loadLearningPath()

        XCTAssertEqual(mockUseCase.executeCallCount, 1)
        XCTAssertFalse(vm.isLoading)
        XCTAssertEqual(vm.errorMessage, "Failed to load learning path")
        XCTAssertTrue(vm.sections.isEmpty)
    }

    func testLoadLearningPathNilUseCase() async {
        let vm = HomepageViewModel(fetchLearningPathUseCase: nil)
        await vm.loadLearningPath()

        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
        XCTAssertTrue(vm.sections.isEmpty)
    }

    func testHandleNodeTapUnlockedActiveNode() {
        let vm = HomepageViewModel()
        let node = LessonNodeModel(
            id: "node_active",
            title: "Active Node",
            state: .active
        )

        XCTAssertNil(vm.selectedNode)
        XCTAssertFalse(vm.isDetailSheetPresented)

        vm.handleNodeTap(node)

        XCTAssertEqual(vm.selectedNode?.id, "node_active")
        XCTAssertTrue(vm.isDetailSheetPresented)
    }

    func testHandleNodeTapUnlockedCompletedNode() {
        let vm = HomepageViewModel()
        let node = LessonNodeModel(
            id: "node_completed",
            title: "Completed Node",
            state: .completed
        )

        vm.handleNodeTap(node)

        XCTAssertEqual(vm.selectedNode?.id, "node_completed")
        XCTAssertTrue(vm.isDetailSheetPresented)
    }

    func testHandleNodeTapUnlockedBonusNode() {
        let vm = HomepageViewModel()
        let node = LessonNodeModel(
            id: "node_bonus",
            title: "Bonus Node",
            state: .bonus
        )

        vm.handleNodeTap(node)

        XCTAssertEqual(vm.selectedNode?.id, "node_bonus")
        XCTAssertTrue(vm.isDetailSheetPresented)
    }

    func testHandleNodeTapLockedNodeIgnored() {
        let vm = HomepageViewModel()
        let lockedNode = LessonNodeModel(
            id: "node_locked",
            title: "Locked Node",
            state: .locked
        )

        vm.handleNodeTap(lockedNode)

        XCTAssertNil(vm.selectedNode)
        XCTAssertFalse(vm.isDetailSheetPresented)
    }

    func testDismissDetailSheet() {
        let vm = HomepageViewModel()
        let node = LessonNodeModel(
            id: "node_active",
            title: "Active Node",
            state: .active
        )

        vm.handleNodeTap(node)
        XCTAssertNotNil(vm.selectedNode)
        XCTAssertTrue(vm.isDetailSheetPresented)

        vm.dismissDetailSheet()
        XCTAssertNil(vm.selectedNode)
        XCTAssertFalse(vm.isDetailSheetPresented)
    }

    func testLegacyTransitionSupport() async {
        let mockTTS = MockTTS()
        let vm = HomepageViewModel(ttsService: mockTTS)

        // State bridge
        let state = vm.state
        XCTAssertEqual(state.userName, "Hooji N.")
        XCTAssertEqual(state.streakDays, 14)
        XCTAssertEqual(state.dailyGoalProgress, 0.75)
        XCTAssertFalse(state.unreadNotifications)
        XCTAssertEqual(state.dueCardsCount, 24)
        XCTAssertEqual(state.totalWords, 1420)
        XCTAssertEqual(state.retentionPercentage, 0.85)

        // Suggested words bookmarking
        let word = SuggestedWord(
            id: "word_1",
            lemma: "Hello",
            pos: "noun",
            ipaUs: "/həˈloʊ/",
            cefrLevel: "A1",
            definitionVi: "Xin chào",
            definitionEn: "A greeting",
            example: "Hello world",
            isBookmarked: false
        )
        vm.suggestedWords = [word]
        XCTAssertFalse(vm.suggestedWords[0].isBookmarked)

        vm.toggleBookmarkSuggestedWord(id: "word_1")
        XCTAssertTrue(vm.suggestedWords[0].isBookmarked)

        vm.toggleBookmarkSuggestedWord(id: "nonexistent")
        XCTAssertTrue(vm.suggestedWords[0].isBookmarked)

        // Speech
        vm.speakSuggestedWord(word)
        XCTAssertEqual(mockTTS.lastSpokenText, "Hello")

        // loadData delegates to loadLearningPath
        await vm.loadData()
    }
}
