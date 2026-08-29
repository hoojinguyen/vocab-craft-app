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
}

public typealias ReflexBlitzMode = ReflexMode
