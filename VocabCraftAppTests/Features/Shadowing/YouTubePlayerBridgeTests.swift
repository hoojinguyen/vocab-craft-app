import Foundation
import Testing
@testable import VocabCraftApp

@Suite("YouTube Player Bridge Tests")
struct YouTubePlayerBridgeTests {
    @Test("Verifies parsing of segmentFinished message from JavaScript")
    func testSegmentFinishedParsing() throws {
        let payload: [String: Any] = [
            "type": "segmentFinished",
            "endTime": 12.4
        ]
        let message = YouTubePlayerBridgeMessage(dictionary: payload)
        #expect(message == .segmentFinished(endTime: 12.4))
    }

    @Test("Verifies parsing of ready and stateChange messages")
    func testOtherMessagesParsing() throws {
        let readyPayload: [String: Any] = ["type": "ready"]
        #expect(YouTubePlayerBridgeMessage(dictionary: readyPayload) == .ready)

        let statePayload: [String: Any] = ["type": "state", "state": 1]
        #expect(YouTubePlayerBridgeMessage(dictionary: statePayload) == .stateChange(state: 1))
    }

    @Test("Verifies parsing of timeUpdate message")
    func testTimeUpdateParsing() throws {
        let timePayload: [String: Any] = ["type": "timeUpdate", "currentTime": 5.2]
        #expect(YouTubePlayerBridgeMessage(dictionary: timePayload) == .timeUpdate(currentTime: 5.2))
    }

    @Test("Verifies parsing of unknown or invalid payload")
    func testUnknownPayloadParsing() throws {
        let emptyPayload: [String: Any] = [:]
        #expect(YouTubePlayerBridgeMessage(dictionary: emptyPayload) == .unknown)

        let invalidTypePayload: [String: Any] = ["type": "unknown_event"]
        #expect(YouTubePlayerBridgeMessage(dictionary: invalidTypePayload) == .unknown)
    }

    @Test("Verifies HTML template generation contains videoId, seek-latch, and bridge hooks")
    func testHtmlTemplateGeneration() throws {
        let videoId = "dQw4w9WgXcQ"
        let html = YouTubePlayerBridgeScript.htmlTemplate(videoId: videoId)
        #expect(html.contains(videoId))
        #expect(html.contains("window.webkit.messageHandlers.shadowingBridge.postMessage"))
        #expect(html.contains("hasSeeked = false"))
        #expect(html.contains("if (!hasSeeked)"))
        #expect(html.contains("hasSeeked = true"))
        #expect(html.contains("if (hasSeeked && current >= targetEndTime)"))
        #expect(html.contains("function playSegment"))
        #expect(html.contains("function pauseVideo"))
        #expect(html.contains("function replaySegment"))
        #expect(html.contains("function checkTime"))
    }

    @MainActor
    @Test("Verifies YouTubeBridgeHolder initialization and methods do not crash when unattached")
    func testBridgeHolderSafeCalls() throws {
        let holder = YouTubeBridgeHolder()
        holder.playSegment(start: 1.0, end: 4.5, rate: 0.9)
        holder.replaySegment(start: 1.0, end: 4.5, rate: 0.9)
        holder.pauseVideo()
        #expect(true)
    }
}
