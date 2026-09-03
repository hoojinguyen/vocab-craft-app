import Foundation

public enum OnboardingStep: Int, CaseIterable, Sendable, Comparable, Equatable {
    case goal = 0
    case proficiency = 1
    case habit = 2
    case roadmapReveal = 3

    public static func < (lhs: OnboardingStep, rhs: OnboardingStep) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
