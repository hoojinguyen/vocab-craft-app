import Foundation

public enum CraftTextMatchEngine {
    public static func normalizeWord(_ word: String) -> String {
        let punctuation = CharacterSet.punctuationCharacters.union(.symbols)
        return word.trimmingCharacters(in: punctuation).lowercased()
    }

    public static func match(
        originText: String,
        actualText: String?,
        isFinal: Bool = false
    ) -> [CraftSpeechWordToken] {
        let originWords = originText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard let actualText = actualText?.trimmingCharacters(in: .whitespacesAndNewlines), !actualText.isEmpty else {
            return originWords.enumerated().map { index, word in
                CraftSpeechWordToken(id: "\(index)_\(word)", targetWord: word, status: .pending)
            }
        }

        let actualWords = actualText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        var tokens: [CraftSpeechWordToken] = []

        var actualIndex = 0
        for (originIdx, originWord) in originWords.enumerated() {
            let normalizedOrigin = normalizeWord(originWord)

            if actualIndex < actualWords.count {
                let actualWord = actualWords[actualIndex]
                let normalizedActual = normalizeWord(actualWord)

                if normalizedOrigin == normalizedActual {
                    tokens.append(CraftSpeechWordToken(
                        id: "\(originIdx)_\(originWord)",
                        targetWord: originWord,
                        status: .matched,
                        spokenWord: actualWord,
                        confidence: 1.0
                    ))
                    actualIndex += 1
                } else if normalizedActual.hasPrefix(normalizedOrigin) || normalizedOrigin.hasPrefix(normalizedActual) {
                    tokens.append(CraftSpeechWordToken(
                        id: "\(originIdx)_\(originWord)",
                        targetWord: originWord,
                        status: .fuzzy,
                        spokenWord: actualWord,
                        confidence: 0.75
                    ))
                    actualIndex += 1
                } else {
                    let nextOriginMatches = (actualIndex + 1 < actualWords.count) &&
                        (normalizeWord(actualWords[actualIndex + 1]) == normalizedOrigin)
                    
                    if nextOriginMatches {
                        actualIndex += 1
                        tokens.append(CraftSpeechWordToken(
                            id: "\(originIdx)_\(originWord)",
                            targetWord: originWord,
                            status: .matched,
                            spokenWord: actualWords[actualIndex],
                            confidence: 1.0
                        ))
                        actualIndex += 1
                    } else {
                        tokens.append(CraftSpeechWordToken(
                            id: "\(originIdx)_\(originWord)",
                            targetWord: originWord,
                            status: isFinal ? .mismatched : .pending,
                            spokenWord: actualWord,
                            confidence: 0.0
                        ))
                        actualIndex += 1
                    }
                }
            } else {
                tokens.append(CraftSpeechWordToken(
                    id: "\(originIdx)_\(originWord)",
                    targetWord: originWord,
                    status: .pending
                ))
            }
        }

        return tokens
    }
}
