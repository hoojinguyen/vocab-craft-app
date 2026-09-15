import Foundation
@testable import SpeechKit
import XCTest

final class AudioSessionCoordinatingTests: XCTestCase {
    func testLeaseInitializationAndEquality() {
        let id = UUID()
        let lease1 = AudioSessionLease(id: id, generation: 1, intent: .speechCapture)
        let lease2 = AudioSessionLease(id: id, generation: 1, intent: .speechCapture)
        let lease3 = AudioSessionLease(id: id, generation: 2, intent: .speechCapture)

        XCTAssertEqual(lease1, lease2)
        XCTAssertNotEqual(lease1, lease3)
        XCTAssertEqual(lease1.intent, .speechCapture)
        XCTAssertEqual(lease1.generation, 1)
    }

    func testNoOpAudioSessionCoordinatorAcquireAndRelease() async throws {
        let coordinator = NoOpAudioSessionCoordinator()
        let lease = try await coordinator.acquire(.playback)

        XCTAssertEqual(lease.intent, .playback)
        XCTAssertEqual(lease.generation, 1)

        await coordinator.release(lease)
    }

    func testNoOpAudioSessionCoordinatorEventsStream() async {
        let coordinator = NoOpAudioSessionCoordinator()
        var iterator = coordinator.events.makeAsyncIterator()
        // Ensure stream is valid and can yield without hanging
        let event = await iterator.next()
        XCTAssertNil(event)
    }
}
