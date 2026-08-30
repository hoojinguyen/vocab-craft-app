import Foundation
import SwiftUI
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

@MainActor
final class SubTopicPreviewSheetTests: XCTestCase {
    func testSheetInitialization() {
        let node = SubTopicNode(
            id: "n1",
            title: "Môi trường",
            iconName: "leaf.fill",
            totalWords: 25,
            learnedWords: 25,
            state: .completed,
            words: []
        )
        let sheet = SubTopicPreviewSheet(node: node, onStartDrill: {}, onToggleVault: { _ in })
        XCTAssertNotNil(sheet)
        XCTAssertEqual(sheet.node.id, "n1")
        XCTAssertEqual(sheet.node.title, "Môi trường")
    }

    func testStartDrillCallbackTriggered() {
        var drillTriggered = false
        let node = SubTopicNode(
            id: "n1",
            title: "Khí hậu",
            iconName: "cloud.sun.fill",
            totalWords: 10,
            learnedWords: 5,
            state: .active,
            words: []
        )
        let sheet = SubTopicPreviewSheet(node: node, onStartDrill: {
            drillTriggered = true
        }, onToggleVault: { _ in })

        sheet.onStartDrill()
        XCTAssertTrue(drillTriggered)
    }

    func testToggleVaultCallbackTriggered() {
        var toggledWord: TopicWord?
        let word = TopicWord(
            id: "w1",
            english: "Sustainability",
            phonetic: "/səˌsteɪ.nəˈbɪl.ə.ti/",
            vietnamese: "Sự bền vững",
            isMastered: true,
            isSavedToPersonalVault: false
        )
        let node = SubTopicNode(
            id: "n1",
            title: "Khí hậu",
            iconName: "cloud.sun.fill",
            totalWords: 1,
            learnedWords: 1,
            state: .completed,
            words: [word]
        )
        let sheet = SubTopicPreviewSheet(node: node, onStartDrill: {}, onToggleVault: { wordItem in
            toggledWord = wordItem
        })

        sheet.onToggleVault(word)
        XCTAssertEqual(toggledWord?.id, "w1")
        XCTAssertEqual(toggledWord?.english, "Sustainability")
    }
}
