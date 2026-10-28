import Foundation
@testable import VocabCraftApp

extension SpeakingSessionPlan {
    static func fixture(level: SpeakingLevel = .a2, words: [String] = []) -> Self {
        Self(
            blueprint: SpeakingBlueprint(
                id: "cafe", kind: .scenario,
                titleKey: "app.speaking.blueprint.cafe.title", briefKey: "app.speaking.blueprint.cafe.brief",
                aiRole: "a friendly barista", setting: "a quiet cafe", objective: "Order a coffee"
            ),
            level: level,
            targetWords: words.enumerated().map {
                SpeakingTargetWord(wordId: Int64($0.offset), lemma: $0.element, definitionVi: "nghĩa")
            }
        )
    }
}

private final class SpeakingFixtureBundleToken {}

enum SpeakingFixtures {
    static func data(_ name: String) throws -> Data {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: SpeakingFixtureBundleToken.self)
        #endif
        guard let url = bundle.url(forResource: name, withExtension: nil, subdirectory: "Fixtures") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try Data(contentsOf: url)
    }
}
