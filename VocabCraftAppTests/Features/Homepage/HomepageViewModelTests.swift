import CraftUIKit
import SwiftUI
#if canImport(Testing)
import Testing
#endif
#if canImport(XCTest)
import XCTest
#endif
@testable import VocabCraftApp

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

#if canImport(Testing)
@Suite("HomepageViewModel Tests")
struct HomepageViewModelTestingTests {
    @Test("Daily goal calculation derived from learned count and goal")
    @MainActor
    func testViewModelDailyGoalCalculation() {
        let vm = HomepageViewModel(
            userName: "Hooji N.",
            streakDays: 14,
            dailyWordsLearned: 8,
            dailyWordsGoal: 10
        )
        #expect(vm.dailyWordsLearned == 8)
        #expect(vm.dailyWordsGoal == 10)
        #expect(abs(vm.dailyGoalProgress - 0.8) < 0.001)
    }

    @Test("Daily goal progress with zero goal returns zero without dividing by zero")
    @MainActor
    func testViewModelDailyGoalProgressWithZeroGoal() {
        let vm = HomepageViewModel(
            dailyWordsLearned: 5,
            dailyWordsGoal: 0
        )
        #expect(vm.dailyGoalProgress == 0.0)
    }

    @Test("Daily goal progress when words learned exceeds goal")
    @MainActor
    func testViewModelDailyGoalProgressExceedingGoal() {
        let vm = HomepageViewModel(
            dailyWordsLearned: 15,
            dailyWordsGoal: 10
        )
        #expect(abs(vm.dailyGoalProgress - 1.5) < 0.001)
    }

    @Test("Initialization with default parameters")
    @MainActor
    func testInitializationDefaults() {
        let vm = HomepageViewModel()
        #expect(vm.userName == "Hooji N.")
        #expect(vm.streakDays == 14)
        #expect(vm.dailyWordsLearned == 8)
        #expect(vm.dailyWordsGoal == 10)
        #expect(abs(vm.dailyGoalProgress - 0.8) < 0.001)
        #expect(!vm.unreadNotifications)
        #expect(vm.sections.isEmpty)
        #expect(vm.selectedNode == nil)
        #expect(!vm.isDetailSheetPresented)
        #expect(!vm.isLoading)
        #expect(vm.errorMessage == nil)
    }

    @Test("Initialization with custom values")
    @MainActor
    func testInitializationCustomValues() {
        let section = makeSampleSection()
        let mockUseCase = MockFetchLearningPathUseCase()
        let mockTTS = MockTTS()

        let vm = HomepageViewModel(
            fetchLearningPathUseCase: mockUseCase,
            ttsService: mockTTS,
            userName: "Alex Swift",
            streakDays: 30,
            dailyWordsLearned: 10,
            dailyWordsGoal: 10,
            unreadNotifications: true,
            sections: [section]
        )

        #expect(vm.userName == "Alex Swift")
        #expect(vm.streakDays == 30)
        #expect(vm.dailyWordsLearned == 10)
        #expect(vm.dailyWordsGoal == 10)
        #expect(abs(vm.dailyGoalProgress - 1.0) < 0.001)
        #expect(vm.unreadNotifications)
        #expect(vm.sections.count == 1)
        #expect(vm.sections.first?.id == "deck_1")
    }

    @Test("Load learning path success populates sections")
    @MainActor
    func testLoadLearningPathSuccess() async {
        let mockUseCase = MockFetchLearningPathUseCase()
        let sampleSection = makeSampleSection()
        mockUseCase.stubbedSections = [sampleSection]

        let vm = HomepageViewModel(fetchLearningPathUseCase: mockUseCase)

        #expect(!vm.isLoading)
        #expect(vm.sections.isEmpty)

        await vm.loadLearningPath()

        #expect(mockUseCase.executeCallCount == 1)
        #expect(!vm.isLoading)
        #expect(vm.errorMessage == nil)
        #expect(vm.sections.count == 1)
        #expect(vm.sections.first?.title == "Unit 1: Basics")
        #expect(vm.sections.first?.nodes.count == 3)
    }

    @Test("Load learning path failure sets error message")
    @MainActor
    func testLoadLearningPathFailure() async {
        let mockUseCase = MockFetchLearningPathUseCase()
        mockUseCase.shouldThrowError = MockError.networkFailure

        let vm = HomepageViewModel(fetchLearningPathUseCase: mockUseCase)

        await vm.loadLearningPath()

        #expect(mockUseCase.executeCallCount == 1)
        #expect(!vm.isLoading)
        #expect(vm.errorMessage == "Failed to load learning path")
        #expect(vm.sections.isEmpty)
    }

    @Test("Load learning path with nil use case returns cleanly")
    @MainActor
    func testLoadLearningPathNilUseCase() async {
        let vm = HomepageViewModel(fetchLearningPathUseCase: nil)
        await vm.loadLearningPath()

        #expect(!vm.isLoading)
        #expect(vm.errorMessage == nil)
        #expect(vm.sections.isEmpty)
    }

    @Test("Handle node tap for unlocked active node presents detail sheet")
    @MainActor
    func testHandleNodeTapUnlockedActiveNode() {
        let vm = HomepageViewModel()
        let node = LessonNodeModel(
            id: "node_active",
            title: "Active Node",
            state: .active
        )

        #expect(vm.selectedNode == nil)
        #expect(!vm.isDetailSheetPresented)

        vm.handleNodeTap(node)

        #expect(vm.selectedNode?.id == "node_active")
        #expect(vm.isDetailSheetPresented)
    }

    @Test("Handle node tap for unlocked completed node presents detail sheet")
    @MainActor
    func testHandleNodeTapUnlockedCompletedNode() {
        let vm = HomepageViewModel()
        let node = LessonNodeModel(
            id: "node_completed",
            title: "Completed Node",
            state: .completed
        )

        vm.handleNodeTap(node)

        #expect(vm.selectedNode?.id == "node_completed")
        #expect(vm.isDetailSheetPresented)
    }

    @Test("Handle node tap for unlocked bonus node presents detail sheet")
    @MainActor
    func testHandleNodeTapUnlockedBonusNode() {
        let vm = HomepageViewModel()
        let node = LessonNodeModel(
            id: "node_bonus",
            title: "Bonus Node",
            state: .bonus
        )

        vm.handleNodeTap(node)

        #expect(vm.selectedNode?.id == "node_bonus")
        #expect(vm.isDetailSheetPresented)
    }

    @Test("Handle node tap for locked node is ignored")
    @MainActor
    func testHandleNodeTapLockedNodeIgnored() {
        let vm = HomepageViewModel()
        let lockedNode = LessonNodeModel(
            id: "node_locked",
            title: "Locked Node",
            state: .locked
        )

        vm.handleNodeTap(lockedNode)

        #expect(vm.selectedNode == nil)
        #expect(!vm.isDetailSheetPresented)
    }

    @Test("Dismiss detail sheet resets selected node and presentation state")
    @MainActor
    func testDismissDetailSheet() {
        let vm = HomepageViewModel()
        let node = LessonNodeModel(
            id: "node_active",
            title: "Active Node",
            state: .active
        )

        vm.handleNodeTap(node)
        #expect(vm.selectedNode != nil)
        #expect(vm.isDetailSheetPresented)

        vm.dismissDetailSheet()
        #expect(vm.selectedNode == nil)
        #expect(!vm.isDetailSheetPresented)
    }
}
#endif

#if !canImport(Testing) && !canImport(XCTest)
public func XCTAssertEqual<T: Equatable>(_ a: T, _ b: T, file: StaticString = #file, line: UInt = #line) {
    assert(a == b, "Assertion failed: \(a) != \(b)", file: file, line: line)
}
public func XCTAssertEqual(_ a: Double, _ b: Double, accuracy: Double, file: StaticString = #file, line: UInt = #line) {
    assert(abs(a - b) <= accuracy, "Assertion failed: |\(a) - \(b)| > \(accuracy)", file: file, line: line)
}
public func XCTAssertTrue(_ condition: Bool, file: StaticString = #file, line: UInt = #line) {
    assert(condition, "Assertion failed: condition is false", file: file, line: line)
}
public func XCTAssertFalse(_ condition: Bool, file: StaticString = #file, line: UInt = #line) {
    assert(!condition, "Assertion failed: condition is true", file: file, line: line)
}
public func XCTAssertNil(_ value: Any?, file: StaticString = #file, line: UInt = #line) {
    assert(value == nil, "Assertion failed: \(String(describing: value)) is not nil", file: file, line: line)
}
public func XCTAssertNotNil(_ value: Any?, file: StaticString = #file, line: UInt = #line) {
    assert(value != nil, "Assertion failed: value is nil", file: file, line: line)
}
open class XCTestCase {
    public init() {}
}
#endif

#if canImport(XCTest) || (!canImport(Testing) && !canImport(XCTest))
@MainActor
final class HomepageViewModelTests: XCTestCase {
    func testViewModelDailyGoalCalculation() {
        let vm = HomepageViewModel(
            userName: "Hooji N.",
            streakDays: 14,
            dailyWordsLearned: 8,
            dailyWordsGoal: 10
        )
        XCTAssertEqual(vm.dailyWordsLearned, 8)
        XCTAssertEqual(vm.dailyWordsGoal, 10)
        XCTAssertEqual(vm.dailyGoalProgress, 0.8, accuracy: 0.001)
    }

    func testViewModelDailyGoalProgressWithZeroGoal() {
        let vm = HomepageViewModel(
            dailyWordsLearned: 5,
            dailyWordsGoal: 0
        )
        XCTAssertEqual(vm.dailyGoalProgress, 0.0)
    }

    func testViewModelDailyGoalProgressExceedingGoal() {
        let vm = HomepageViewModel(
            dailyWordsLearned: 15,
            dailyWordsGoal: 10
        )
        XCTAssertEqual(vm.dailyGoalProgress, 1.5, accuracy: 0.001)
    }

    func testInitializationDefaults() {
        let vm = HomepageViewModel()
        XCTAssertEqual(vm.userName, "Hooji N.")
        XCTAssertEqual(vm.streakDays, 14)
        XCTAssertEqual(vm.dailyWordsLearned, 8)
        XCTAssertEqual(vm.dailyWordsGoal, 10)
        XCTAssertEqual(vm.dailyGoalProgress, 0.8, accuracy: 0.001)
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
            dailyWordsLearned: 10,
            dailyWordsGoal: 10,
            unreadNotifications: true,
            sections: [section]
        )

        XCTAssertEqual(vm.userName, "Alex Swift")
        XCTAssertEqual(vm.streakDays, 30)
        XCTAssertEqual(vm.dailyWordsLearned, 10)
        XCTAssertEqual(vm.dailyWordsGoal, 10)
        XCTAssertEqual(vm.dailyGoalProgress, 1.0, accuracy: 0.001)
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
}
#endif
