#if canImport(SwiftDataMacros)
import Foundation
import SwiftData
@testable import VocabCraftApp
import XCTest

@MainActor
final class AppBootstrapperTests: XCTestCase {
    func test_bootstrapper_initial_state_transitions_to_ready_with_memory_container() {
        let sut = AppBootstrapper(inMemoryOnly: true)
        XCTAssertEqual(sut.state, .loading)
        sut.bootstrap()
        switch sut.state {
        case .ready:
            XCTAssertNotNil(sut.container)
            XCTAssertNotNil(sut.appContainer)
        default:
            XCTFail("Expected .ready, got \(sut.state)")
        }
    }

    func test_bootstrapper_transitions_to_error_when_container_fails() {
        let expectedError = DatabaseStoreError.storeInitializationFailed(description: "Mock Error", backupURL: nil)
        let sut = AppBootstrapper(containerProvider: {
            throw expectedError
        })
        sut.bootstrap()
        switch sut.state {
        case .error(let error):
            XCTAssertEqual(error, expectedError)
        default:
            XCTFail("Expected .error, got \(sut.state)")
        }
    }

    func test_bootstrapper_retry_reloads() {
        var callCount = 0
        let sut = AppBootstrapper(containerProvider: {
            callCount += 1
            if callCount == 1 {
                throw DatabaseStoreError.storeInitializationFailed(description: "First fail", backupURL: nil)
            }
            let schema = Schema(versionedSchema: SchemaV2.self)
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [config])
        })
        sut.bootstrap()
        XCTAssertEqual(callCount, 1)
        guard case .error = sut.state else {
            XCTFail("Expected error on first attempt")
            return
        }

        sut.retry()
        XCTAssertEqual(callCount, 2)
        guard case .ready = sut.state else {
            XCTFail("Expected ready on second attempt")
            return
        }
    }

    func test_bootstrapper_confirmReset_resets_store_and_transitions_to_ready() {
        var resetCalled = false
        let sut = AppBootstrapper(
            containerProvider: {
                throw DatabaseStoreError.storeInitializationFailed(description: "Initial failure", backupURL: nil)
            },
            resetProvider: {
                resetCalled = true
                let schema = Schema(versionedSchema: SchemaV2.self)
                let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                return try ModelContainer(for: schema, configurations: [config])
            }
        )
        sut.bootstrap()
        guard case .error = sut.state else {
            XCTFail("Expected error state initially")
            return
        }

        sut.confirmReset()
        XCTAssertTrue(resetCalled)
        guard case .ready = sut.state else {
            XCTFail("Expected ready state after confirmReset")
            return
        }
        XCTAssertNotNil(sut.container)
        XCTAssertNotNil(sut.appContainer)
    }

    func test_bootstrapper_confirmReset_transitions_to_error_on_reset_failure() {
        let expectedError = DatabaseStoreError.manualResetFailed(description: "Reset failed")
        let sut = AppBootstrapper(
            containerProvider: {
                throw DatabaseStoreError.storeInitializationFailed(description: "Initial failure", backupURL: nil)
            },
            resetProvider: {
                throw expectedError
            }
        )
        sut.bootstrap()
        guard case .error = sut.state else {
            XCTFail("Expected error state initially")
            return
        }

        sut.confirmReset()
        switch sut.state {
        case .error(let error):
            XCTAssertEqual(error, expectedError)
        default:
            XCTFail("Expected error state after failed confirmReset")
        }
    }
}
#endif
