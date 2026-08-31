import Foundation

/// Codec to encode and decode `ModeSuccessStats` to/from a compact serialized string.
public enum ModeSuccessStatsCodec {
    /// Encodes `ModeSuccessStats` into a compact comma-delimited string format (e.g. `"s:2,t:1,m:4,l:3"`).
    public static func encode(_ stats: ModeSuccessStats) -> String {
        "s:\(stats.speaking),t:\(stats.typing),m:\(stats.multipleChoice),l:\(stats.listening)"
    }

    /// Decodes a serialized string into a `ModeSuccessStats` instance.
    public static func decode(_ raw: String) -> ModeSuccessStats {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ModeSuccessStats()
        }

        var speaking = 0
        var typing = 0
        var multipleChoice = 0
        var listening = 0

        let pairs = trimmed.split(separator: ",")
        for pair in pairs {
            let parts = pair.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2, let count = Int(parts[1]) else { continue }
            let key = parts[0].lowercased()

            switch key {
            case "s", "speaking":
                speaking = max(0, count)
            case "t", "typing":
                typing = max(0, count)
            case "m", "mc", "multiplechoice", "multiple_choice":
                multipleChoice = max(0, count)
            case "l", "listening":
                listening = max(0, count)
            default:
                break
            }
        }

        return ModeSuccessStats(
            speaking: speaking,
            typing: typing,
            multipleChoice: multipleChoice,
            listening: listening
        )
    }
}
