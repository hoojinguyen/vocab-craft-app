import CraftUIKit
import Foundation
import Testing
@testable import VocabCraftApp

private final class MockFastTrackUnitUseCase: FastTrackUnitUseCaseProtocol, @unchecked Sendable {
    var stubbedResult = FastTrackResult(deckId: "deck_1", isSuccess: true, scorePercentage: 0.90)
    var executeCallCount = 0
    var lastRequestedDeckId: String?
    var lastRequestedScore: Double?

    func execute(deckId: String, scorePercentage: Double) async throws -> FastTrackResult {
        executeCallCount += 1
        lastRequestedDeckId = deckId
        lastRequestedScore = scorePercentage
        return stubbedResult
    }
}

@MainActor
@Suite("HomepageViewModel FastTrack Tests")
struct HomepageViewModelFastTrackTests {
    @Test("Fast-track unit with use case passes and refreshes learning path")
    func testFastTrackUnitWithUseCaseSuccess() async throws {
        let mockUseCase = MockFastTrackUnitUseCase()
        mockUseCase.stubbedResult = FastTrackResult(deckId: "deck_1", isSuccess: true, scorePercentage: 0.92)

        let vm = HomepageViewModel(fastTrackUnitUseCase: mockUseCase)
        let result = try await vm.fastTrackUnit(deckId: "deck_1", score: 0.92)

        #expect(result.isSuccess == true)
        #expect(mockUseCase.executeCallCount == 1)
        #expect(mockUseCase.lastRequestedDeckId == "deck_1")
        #expect(mockUseCase.lastRequestedScore == 0.92)
    }

    @Test("Fast-track unit with use case failure returns failed result")
    func testFastTrackUnitWithUseCaseFailure() async throws {
        let mockUseCase = MockFastTrackUnitUseCase()
        mockUseCase.stubbedResult = FastTrackResult(deckId: "deck_1", isSuccess: false, scorePercentage: 0.75)

        let vm = HomepageViewModel(fastTrackUnitUseCase: mockUseCase)
        let result = try await vm.fastTrackUnit(deckId: "deck_1", score: 0.75)

        #expect(result.isSuccess == false)
        #expect(mockUseCase.executeCallCount == 1)
    }

    @Test("Fast-track unit fallback marks checkpoint complete when use case is nil")
    func testFastTrackUnitFallbackWhenUseCaseNil() async throws {
        let cpNode = LessonNodeModel(id: "checkpoint_deck_1", title: "Checkpoint", state: .locked, kind: .checkpoint)
        let section = LessonSection(id: "deck_1", title: "Unit 1", nodes: [cpNode])
        let vm = HomepageViewModel(fastTrackUnitUseCase: nil, sections: [section])

        let successResult = try await vm.fastTrackUnit(deckId: "deck_1", score: 0.88)
        #expect(successResult.isSuccess == true)
        let updatedNode = vm.sections[0].nodes.first(where: { $0.id == "checkpoint_deck_1" })
        #expect(updatedNode?.state == .completed)

        let failResult = try await vm.fastTrackUnit(deckId: "deck_1", score: 0.60)
        #expect(failResult.isSuccess == false)
    }
}
