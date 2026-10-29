import Foundation

enum SpeakingRoute: Hashable, Identifiable {
    case prepare(blueprintId: String)
    case call(SpeakingSessionPlan)
    case result(UUID)
    case phrasebook

    var id: String {
        switch self {
        case let .prepare(blueprintId): "prepare-\(blueprintId)"
        case let .call(plan): "call-\(plan.blueprint.id)"
        case let .result(sessionId): "result-\(sessionId.uuidString)"
        case .phrasebook: "phrasebook"
        }
    }
}
