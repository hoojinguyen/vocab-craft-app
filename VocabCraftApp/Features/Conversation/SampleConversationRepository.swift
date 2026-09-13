import Foundation

public struct SampleConversationRepository: ConversationRepository {
    public let simulatesFailure: Bool

    public init(simulatesFailure: Bool = false) {
        self.simulatesFailure = simulatesFailure
    }

    public func nextConversation(after currentID: String) async throws -> ConversationScript {
        if simulatesFailure { throw ConversationRepositoryError.simulatedFailure }
        let scripts = try Self.loadScripts()
        guard let currentIndex = scripts.firstIndex(where: { $0.id == currentID }) else {
            return scripts[0]
        }
        return scripts[(currentIndex + 1) % scripts.count]
    }

    public static func loadScripts() throws -> [ConversationScript] {
        #if DEBUG
        guard let scripts = try? JSONDecoder().decode([ConversationScript].self, from: ConversationSampleFixture.data),
              !scripts.isEmpty else { throw ConversationRepositoryError.missingFixture }
        return scripts
        #else
        throw ConversationRepositoryError.missingFixture
        #endif
    }
}
