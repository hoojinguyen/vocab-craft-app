import Foundation

public typealias RoleplayTopic = ScenarioTopic

public enum ScenarioDialogueState: Sendable, Equatable {
    case dining(DiningState)
    case travel(TravelState)
    case interview(InterviewState)
    case dailyLife(DailyLifeState)

    public var isCompleted: Bool {
        switch self {
        case .dining(let state): return state == .completed
        case .travel(let state): return state == .completed
        case .interview(let state): return state == .completed
        case .dailyLife(let state): return state == .completed
        }
    }
}

public enum DiningState: String, Sendable, Equatable, CaseIterable {
    case greeting
    case inquiry
    case ordering
    case customizing
    case payment
    case completed
}

public enum TravelState: String, Sendable, Equatable, CaseIterable {
    case greeting
    case inquiry
    case reservationCheck
    case idVerification
    case keyHandover
    case completed
}

public enum InterviewState: String, Sendable, Equatable, CaseIterable {
    case greeting
    case experienceDiscussion
    case behavioralChallenge
    case candidateQuestions
    case completed
}

public enum DailyLifeState: String, Sendable, Equatable, CaseIterable {
    case greeting
    case sharing
    case followUp
    case closing
    case completed
}
