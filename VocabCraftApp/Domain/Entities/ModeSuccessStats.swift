import Foundation

/// Modality-specific success counts for a vocabulary item across Speaking, Typing, Multiple Choice, and Listening.
public struct ModeSuccessStats: Codable, Equatable, Sendable {
    public var speaking: Int
    public var typing: Int
    public var multipleChoice: Int
    public var listening: Int

    public init(
        speaking: Int = 0,
        typing: Int = 0,
        multipleChoice: Int = 0,
        listening: Int = 0
    ) {
        self.speaking = speaking
        self.typing = typing
        self.multipleChoice = multipleChoice
        self.listening = listening
    }

    public func count(for mode: ReflexBlitzMode) -> Int {
        switch mode {
        case .speaking: return speaking
        case .typing: return typing
        case .multipleChoice: return multipleChoice
        case .listening: return listening
        }
    }

    public mutating func increment(for mode: ReflexBlitzMode) {
        switch mode {
        case .speaking: speaking += 1
        case .typing: typing += 1
        case .multipleChoice: multipleChoice += 1
        case .listening: listening += 1
        }
    }

    public var totalSuccesses: Int {
        speaking + typing + multipleChoice + listening
    }

    public var completedModes: Set<ReflexBlitzMode> {
        var set = Set<ReflexBlitzMode>()
        if speaking > 0 { set.insert(.speaking) }
        if typing > 0 { set.insert(.typing) }
        if multipleChoice > 0 { set.insert(.multipleChoice) }
        if listening > 0 { set.insert(.listening) }
        return set
    }

    public var isFullyMasteredAllModes: Bool {
        completedModes.count == 4
    }

    public var lowestSuccessModes: [ReflexBlitzMode] {
        let all: [(ReflexBlitzMode, Int)] = [
            (.speaking, speaking),
            (.typing, typing),
            (.multipleChoice, multipleChoice),
            (.listening, listening)
        ]
        let minVal = all.map(\.1).min() ?? 0
        return all.filter { $0.1 == minVal }.map(\.0)
    }
}
