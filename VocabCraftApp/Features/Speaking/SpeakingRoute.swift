import Foundation

enum SpeakingRoute: Hashable {
    case prepare(blueprintId: String)
    case call(SpeakingSessionPlan)
    case result(UUID)
    case phrasebook
}
