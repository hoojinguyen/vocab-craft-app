@testable import SpeechKit
import XCTest

private final class AtomicCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var _value = 0

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    func increment() {
        lock.lock()
        _value += 1
        lock.unlock()
    }
}

final class SilenceDetectorTests: XCTestCase {
    func testSilenceDetector_firesAfterDuration_whenNoActivity() async {
        let expectation = expectation(description: "Silence detected")
        let detector = SilenceDetector(silenceDuration: .milliseconds(100)) {
            expectation.fulfill()
        }

        detector.registerActivity()

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testSilenceDetector_debouncesActivity() async {
        let counter = AtomicCounter()
        let expectation = expectation(description: "Silence detected after debounce")

        let detector = SilenceDetector(silenceDuration: .milliseconds(200)) {
            counter.increment()
            expectation.fulfill()
        }

        // Register initial activity
        detector.registerActivity()

        // Wait 80ms and re-register
        try? await Task.sleep(for: .milliseconds(80))
        XCTAssertEqual(counter.value, 0)
        detector.registerActivity()

        // Wait another 80ms and re-register
        try? await Task.sleep(for: .milliseconds(80))
        XCTAssertEqual(counter.value, 0)
        detector.registerActivity()

        // Now wait for 250ms, allowing debounce timer to fire
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(counter.value, 1)
    }

    func testSilenceDetector_cancel_preventsFiring() async {
        let counter = AtomicCounter()
        let detector = SilenceDetector(silenceDuration: .milliseconds(100)) {
            counter.increment()
        }

        detector.registerActivity()
        try? await Task.sleep(for: .milliseconds(30))
        detector.cancel()

        // Wait past original timer duration
        try? await Task.sleep(for: .milliseconds(150))
        XCTAssertEqual(counter.value, 0)
    }

    func testSilenceDetector_rearmAfterCancel() async {
        let expectation = expectation(description: "Silence detected after rearm")
        let counter = AtomicCounter()

        let detector = SilenceDetector(silenceDuration: .milliseconds(100)) {
            counter.increment()
            expectation.fulfill()
        }

        detector.registerActivity()
        detector.cancel()

        // Re-arm
        detector.registerActivity()

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(counter.value, 1)
    }
}
