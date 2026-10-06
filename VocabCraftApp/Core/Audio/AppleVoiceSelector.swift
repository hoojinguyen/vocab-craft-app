import AVFoundation
import Foundation

public enum AppleVoiceSelector: Sendable {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var cachedBestVoice: [String: AVSpeechSynthesisVoice] = [:]

    public static let blacklistedVoices: Set<String> = [
        "albert", "bad news", "bahh", "bells", "boing", "bubbles",
        "cellos", "deranged", "fred", "eddy", "grandpa", "grandma",
        "organ", "trinoids", "whisper", "zarvox", "rocko", "sandy", "reed"
    ]

    public static let curatedWhitelist: [String] = [
        "ava", "zoe", "allison", "samantha", "nathan", "tom",
        "oliver", "serena", "karen", "daniel", "rishi", "moira"
    ]

    public static let maleCuratedWhitelist: [String] = [
        "daniel", "nathan", "tom", "oliver", "rishi"
    ]

    public static let femaleCuratedWhitelist: [String] = [
        "ava", "zoe", "allison", "samantha", "serena", "karen", "moira"
    ]

    public static func isBlacklisted(voiceName: String) -> Bool {
        blacklistedVoices.contains(voiceName.lowercased())
    }

    public static func resolveBestVoice(for locale: String, persona: VoicePersona? = nil) -> AVSpeechSynthesisVoice? {
        lock.lock()
        defer { lock.unlock() }

        let cacheKey = "\(locale)::\(persona?.rawValue ?? "default")"
        if let cached = cachedBestVoice[cacheKey] {
            return cached
        }

        let voices = AVSpeechSynthesisVoice.speechVoices()
        let resolved = resolveBestVoice(for: locale, persona: persona, availableVoices: voices)
        if let resolved {
            cachedBestVoice[cacheKey] = resolved
        }
        return resolved
    }

    public static func resolveBestVoice(
        for locale: String,
        availableVoices: [AVSpeechSynthesisVoice]
    ) -> AVSpeechSynthesisVoice? {
        resolveBestVoice(for: locale, persona: nil, availableVoices: availableVoices)
    }

    public static func resolveBestVoice(
        for locale: String,
        persona: VoicePersona?,
        availableVoices: [AVSpeechSynthesisVoice]
    ) -> AVSpeechSynthesisVoice? {
        let matchingVoices = availableVoices.filter { voice in
            (voice.language == locale || voice.language.hasPrefix("en")) &&
            !isBlacklisted(voiceName: voice.name)
        }

        guard !matchingVoices.isEmpty else {
            return AVSpeechSynthesisVoice(language: locale) ?? AVSpeechSynthesisVoice(language: "en-US")
        }

        // Apply persona-based gender filtering if requested
        let candidatePool: [AVSpeechSynthesisVoice]
        if let persona {
            let wantsMale = (persona == .friendlyMale || persona == .authoritativeMale)
            let personaFiltered = matchingVoices.filter { voice in
                if wantsMale {
                    return voice.gender == .male || maleCuratedWhitelist.contains(voice.name.lowercased())
                } else {
                    return voice.gender == .female || femaleCuratedWhitelist.contains(voice.name.lowercased())
                }
            }
            candidatePool = personaFiltered.isEmpty ? matchingVoices : personaFiltered
        } else {
            candidatePool = matchingVoices
        }

        // Rank 1: Premium quality voices
        if let premiumExact = candidatePool.first(where: {
            $0.quality == .premium && $0.language == locale
        }) {
            return premiumExact
        }
        if let premiumFallback = candidatePool.first(where: {
            $0.quality == .premium && $0.language.hasPrefix("en-US")
        }) {
            return premiumFallback
        }

        // Rank 2: Enhanced quality voices
        if let enhancedExact = candidatePool.first(where: {
            $0.quality == .enhanced && $0.language == locale
        }) {
            return enhancedExact
        }
        if let enhancedFallback = candidatePool.first(where: {
            $0.quality == .enhanced && $0.language.hasPrefix("en-US")
        }) {
            return enhancedFallback
        }

        // Rank 3: Curated whitelist compact voices
        let preferredList = persona == nil ? curatedWhitelist :
            (persona == .friendlyMale || persona == .authoritativeMale ? maleCuratedWhitelist : femaleCuratedWhitelist)
        for preferredName in preferredList {
            if let matched = candidatePool.first(where: {
                $0.name.lowercased() == preferredName &&
                ($0.language == locale || $0.language.hasPrefix(locale))
            }) {
                return matched
            }
        }

        // Rank 4: Exact locale match with quality default
        if let exactLocale = candidatePool.first(where: { $0.language == locale }) {
            return exactLocale
        }

        // Fallback: First non-blacklisted English voice from candidate pool
        return candidatePool.first ?? matchingVoices.first ?? AVSpeechSynthesisVoice(language: "en-US")
    }

    public static func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        cachedBestVoice.removeAll()
    }
}
