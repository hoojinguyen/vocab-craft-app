import Foundation
#if canImport(SwiftDataMacros)
import AppIntents
import SwiftData
import SwiftUI
@testable import VocabCraftApp
#if SWIFT_PACKAGE
@testable import VocabCraftWidgetExtension
#endif
import WidgetKit
#if canImport(XCTest)
import XCTest
#endif

@MainActor
final class WidgetIntentsTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        try super.setUpWithError()
        container = try SharedAppGroupContainer.createContainer(inMemory: true)
        context = container.mainContext
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
        try super.tearDownWithError()
    }

    func testNextWordIntentRotatesWidgetState() async throws {
        // Initial state
        let initialState = WidgetCurrentState(
            currentWordId: 101,
            lemma: "Abandon",
            ipaUs: "/əˈbæn.dən/",
            definitionVi: "Từ bỏ",
            exampleEn: "Never abandon your dreams.",
            lastUpdated: Date(timeIntervalSince1970: 1000)
        )
        context.insert(initialState)
        try context.save()

        let intent = NextWordIntent()
        let result = try await intent.perform(in: context)
        XCTAssertNotNil(result)

        let states = try context.fetch(FetchDescriptor<WidgetCurrentState>())
        XCTAssertEqual(states.count, 1)
        let updatedState = states.first!
        XCTAssertGreaterThan(updatedState.lastUpdated.timeIntervalSince1970, 1000)
    }

    func testMarkLearnedIntentUpdatesSRSAndRotatesState() async throws {
        let initialState = WidgetCurrentState(
            currentWordId: 202,
            lemma: "Brilliant",
            ipaUs: "/ˈbrɪl.jənt/",
            definitionVi: "Rực rỡ, thông minh",
            exampleEn: "A brilliant idea.",
            lastUpdated: Date(timeIntervalSince1970: 1000)
        )
        context.insert(initialState)
        try context.save()

        let intent = MarkLearnedIntent()
        let result = try await intent.perform(in: context)
        XCTAssertNotNil(result)

        // Verify UserWordProgress was updated/created
        let progressList = try context.fetch(FetchDescriptor<UserWordProgress>())
        XCTAssertFalse(progressList.isEmpty)
        let progress = progressList.first(where: { $0.wordId == 202 })
        XCTAssertNotNil(progress)
        XCTAssertGreaterThanOrEqual(progress?.masteryLevel ?? 0, 5)

        // Verify state rotated
        let states = try context.fetch(FetchDescriptor<WidgetCurrentState>())
        XCTAssertEqual(states.count, 1)
        XCTAssertGreaterThan(states.first!.lastUpdated.timeIntervalSince1970, 1000)
    }

    func testVocabWidgetProviderPlaceholderAndFetch() throws {
        let provider = VocabWidgetProvider()
        let placeholder = provider.makePlaceholder()
        XCTAssertEqual(placeholder.lemma, "Abandon")
        XCTAssertFalse(placeholder.definitionVi.isEmpty)

        // Populate SwiftData container state
        let state = WidgetCurrentState(
            currentWordId: 303,
            lemma: "Resilient",
            ipaUs: "/rɪˈzɪl.jənt/",
            definitionVi: "Kiên cường",
            exampleEn: "Be resilient under pressure.",
            lastUpdated: Date()
        )
        context.insert(state)
        let progress = UserWordProgress(wordId: 303, masteryLevel: 4)
        context.insert(progress)
        try context.save()

        let fetchedEntry = provider.fetchCurrentEntry(in: container)
        XCTAssertNotNil(fetchedEntry)
        XCTAssertEqual(fetchedEntry?.lemma, "Resilient")
        XCTAssertEqual(fetchedEntry?.definitionVi, "Kiên cường")
        XCTAssertEqual(fetchedEntry?.masteryLevel, 4)
    }

    func testVocabWidgetViewInstantiation() {
        let entry = VocabWidgetEntry(
            date: Date(),
            lemma: "Eloquent",
            ipaUs: "/ˈel.ə.kwənt/",
            definitionVi: "Hùng hồn",
            exampleEn: "An eloquent speaker.",
            masteryLevel: 3
        )
        let view = VocabWidgetView(entry: entry)
        XCTAssertNotNil(view.body)
    }

    func testWidgetContainerHolderSharedContainer() {
        let container = WidgetContainerHolder.sharedContainer
        XCTAssertNotNil(container)
    }

    func testVocabWidgetProviderFetchCurrentEntryWithDefaultContainer() throws {
        guard let shared = WidgetContainerHolder.sharedContainer else {
            XCTFail("Shared container should not be nil")
            return
        }
        let sharedContext = ModelContext(shared)
        let state = WidgetCurrentState(
            currentWordId: 404,
            lemma: "Persistent",
            ipaUs: "/pəˈsɪs.tənt/",
            definitionVi: "Bền bỉ",
            exampleEn: "Success comes with persistent effort.",
            lastUpdated: Date()
        )
        sharedContext.insert(state)
        let progress = UserWordProgress(wordId: 404, masteryLevel: 2)
        sharedContext.insert(progress)
        try sharedContext.save()

        let provider = VocabWidgetProvider()
        let fetched = provider.fetchCurrentEntry()
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.lemma, "Persistent")
        XCTAssertEqual(fetched?.definitionVi, "Bền bỉ")
        XCTAssertEqual(fetched?.masteryLevel, 2)
    }
}

#endif
