import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Speaking precheck")
@MainActor
struct SpeakingPrecheckTests {
    private func settings(with apiKey: String) throws -> UserSettingsStore {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        defaults.set(apiKey, forKey: "gemini_api_key")
        return UserSettingsStore(defaults: defaults)
    }

    @Test("Reports all missing requirements in stable order")
    func reportsAllMissingRequirements() async throws {
        let precheck = SpeakingPrecheck(
            settings: try settings(with: ""),
            microphone: { false },
            isOnline: { false }
        )
        #expect(await precheck.run() == [.missingKey, .microphoneDenied, .offline])
    }

    @Test("Treats a whitespace-only API key as missing")
    func treatsWhitespaceKeyAsMissing() async throws {
        let precheck = SpeakingPrecheck(
            settings: try settings(with: " \n\t "),
            microphone: { true },
            isOnline: { true }
        )
        #expect(await precheck.run() == [.missingKey])
    }

    @Test("Returns no issues when all requirements are available")
    func returnsNoIssuesWhenReady() async throws {
        let precheck = SpeakingPrecheck(
            settings: try settings(with: "valid-key"),
            microphone: { true },
            isOnline: { true }
        )
        #expect(await precheck.run().isEmpty)
    }

    @Test("Does not report offline until the network path has been observed")
    func unobservedPathIsNotReportedAsOffline() async throws {
        var pathIsOnline: Bool?
        let precheck = SpeakingPrecheck(
            settings: try settings(with: "valid-key"),
            microphone: { true },
            isOnline: { pathIsOnline }
        )

        #expect(await precheck.run().isEmpty)

        pathIsOnline = false
        #expect(await precheck.run() == [.offline])

        pathIsOnline = true
        #expect(await precheck.run().isEmpty)
    }
}
