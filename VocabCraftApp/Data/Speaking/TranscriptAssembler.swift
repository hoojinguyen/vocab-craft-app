import Foundation

struct TranscriptAssembler: Sendable {
    private(set) var turns: [SpeakingTurn] = []

    mutating func ingest(_ event: LiveServerEvent, at offset: TimeInterval) {
        switch event {
        case let .outputTranscript(fragment):
            append(fragment, from: .ai, at: offset)
        case let .inputTranscript(fragment):
            append(fragment, from: .learner, at: offset)
        case .turnComplete, .interrupted:
            closeActiveTurn(speaker: .ai, at: offset)
        case .setupComplete, .audio, .toolCall, .goAway, .resumptionUpdate:
            break
        }
    }

    private mutating func append(_ fragment: String, from speaker: SpeakingSpeaker, at offset: TimeInterval) {
        let text = fragment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        if speaker == .ai {
            closeActiveTurn(speaker: .learner, at: offset)
        } else {
            closeActiveTurn(speaker: .ai, at: offset)
        }

        if let activeIndex = activeTurnIndex(for: speaker) {
            turns[activeIndex].text += " \(text)"
        } else {
            turns.append(SpeakingTurn(
                index: turns.count,
                speaker: speaker,
                text: text,
                startOffset: offset,
                endOffset: nil
            ))
        }
    }

    private mutating func closeActiveTurn(speaker: SpeakingSpeaker, at offset: TimeInterval) {
        guard let activeIndex = activeTurnIndex(for: speaker) else { return }
        turns[activeIndex].endOffset = offset
    }

    private func activeTurnIndex(for speaker: SpeakingSpeaker) -> Int? {
        guard let lastTurn = turns.last,
              lastTurn.speaker == speaker,
              lastTurn.endOffset == nil else {
            return nil
        }
        return turns.count - 1
    }
}
