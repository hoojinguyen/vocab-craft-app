import CraftUIKit
import Foundation
import SpeechKit

extension WordTokenResult {
    public var asCraftSpeechWordToken: CraftSpeechWordToken {
        let craftStatus: CraftSpeechWordStatus
        switch status {
        case .exactMatch:
            craftStatus = .matched
        case .fuzzyMatch:
            craftStatus = .fuzzy
        case .missing:
            craftStatus = .mismatched
        }
        return CraftSpeechWordToken(
            id: String(id),
            targetWord: targetWord,
            status: craftStatus,
            spokenWord: spokenWord,
            confidence: confidence
        )
    }
}
