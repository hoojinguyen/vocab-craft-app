import Foundation
import Testing
@testable import VocabCraftApp

private final class SpyRefreshWidgetDeckUseCase: RefreshWidgetDeckUseCaseProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _count = 0
    let stream: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation

    init() {
        var captured: AsyncStream<Void>.Continuation!
        stream = AsyncStream { captured = $0 }
        continuation = captured
    }

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return _count
    }

    func execute() async {
        lock.lock()
        _count += 1
        lock.unlock()
        continuation.yield()
    }
}

@Suite("WidgetRefreshingCompleteLessonUseCase")
struct WidgetRefreshingCompleteLessonUseCaseTests {
    @Test("refreshes after successful lesson")
    func refreshesAfterSuccessfulLesson() async throws {
        let wrapped = MockCompleteLessonUseCase()
        let spy = SpyRefreshWidgetDeckUseCase()
        let sut = WidgetRefreshingCompleteLessonUseCase(wrapped: wrapped, refresh: spy)

        let result = try await sut.execute(
            stageId: "s1", deckId: "d1", stars: 3, practicedWordIds: [1, 2],
            weakWordIds: [2], progressFraction: 1.0, cefrLevel: "A1"
        )

        #expect(result.stageId == "s1")
        #expect(result.score == 3)
        #expect(wrapped.executedCefrLevel == "A1")

        let fired = await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                var iterator = spy.stream.makeAsyncIterator()
                return await iterator.next() != nil
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(1))
                return false
            }
            let first = await group.next() ?? false
            group.cancelAll()
            return first
        }
        #expect(fired)
        #expect(spy.count == 1)
    }

    @Test("forwards the short overload")
    func forwardsShortOverload() async throws {
        let wrapped = MockCompleteLessonUseCase()
        let spy = SpyRefreshWidgetDeckUseCase()
        let sut = WidgetRefreshingCompleteLessonUseCase(wrapped: wrapped, refresh: spy)

        _ = try await sut.execute(
            stageId: "s1", deckId: "d1", stars: 2, practicedWordIds: [1],
            weakWordIds: [], progressFraction: 1.0
        )
        #expect(wrapped.executeCallCount == 1)
    }

    @Test("does not refresh when lesson fails")
    func doesNotRefreshWhenLessonFails() async throws {
        let wrapped = MockCompleteLessonUseCase()
        wrapped.shouldFail = true
        let spy = SpyRefreshWidgetDeckUseCase()
        let sut = WidgetRefreshingCompleteLessonUseCase(wrapped: wrapped, refresh: spy)

        await #expect(throws: URLError.self) {
            _ = try await sut.execute(
                stageId: "s1", deckId: "d1", stars: 3, practicedWordIds: [],
                weakWordIds: [], progressFraction: 1.0, cefrLevel: nil
            )
        }
        try await Task.sleep(for: .milliseconds(200))
        #expect(spy.count == 0)
    }
}
