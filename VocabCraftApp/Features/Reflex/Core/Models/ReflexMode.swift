import Foundation

/// Modality types for Reflex Drills (Speaking, Typing, Multiple Choice, Listening).
public enum ReflexMode: String, CaseIterable, Identifiable, Sendable, Codable {
    case speaking
    case typing
    case multipleChoice
    case listening

    public var id: String { rawValue }

    public var timeLimitSeconds: Double {
        switch self {
        case .multipleChoice: return 4.5
        case .listening:      return 5.5
        case .speaking:       return 6.0
        case .typing:         return 7.5
        }
    }

    public var title: String {
        switch self {
        case .speaking:       return AppStrings.ReflexBlitz.speakingTitleText
        case .typing:         return AppStrings.ReflexBlitz.typingTitleText
        case .multipleChoice: return AppStrings.ReflexBlitz.mcTitleText
        case .listening:      return AppStrings.ReflexBlitz.listeningTitleText
        }
    }

    public var iconName: String {
        switch self {
        case .speaking:       return "waveform.and.mic"
        case .typing:         return "keyboard"
        case .multipleChoice: return "square.grid.2x2.fill"
        case .listening:      return "headphones"
        }
    }

    public var instructionPrompt: String {
        switch self {
        case .speaking:       return AppStrings.ReflexBlitz.speakingInstructionText
        case .typing:         return AppStrings.ReflexBlitz.typingInstructionText
        case .multipleChoice: return AppStrings.ReflexBlitz.mcInstructionText
        case .listening:      return AppStrings.ReflexBlitz.listeningModeInstructionText
        }
    }

    /// Computes the progressive hint stage (0, 1, 2, 3) based on elapsed time.
    public func hintStage(forElapsedTimeMs elapsed: Int) -> Int {
        switch self {
        case .multipleChoice:
            if elapsed >= 3400 { return 3 }
            if elapsed >= 2500 { return 2 }
            if elapsed >= 1600 { return 1 }
            return 0
        case .listening:
            if elapsed >= 5500 { return 3 }
            if elapsed >= 3000 { return 2 }
            if elapsed >= 1800 { return 1 }
            return 0
        case .speaking:
            if elapsed >= 4500 { return 2 }
            if elapsed >= 2500 { return 1 }
            return 0
        case .typing:
            if elapsed >= 5000 { return 2 }
            if elapsed >= 3000 { return 1 }
            return 0
        }
    }
}

public typealias ReflexBlitzMode = ReflexMode
