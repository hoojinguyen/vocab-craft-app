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

    public static func isBlacklisted(voiceName: String) -> Bool {
        blacklistedVoices.contains(voiceName.lowercased())
    }

    public static func resolveBestVoice(for locale: String) -> AVSpeechSynthesisVoice? {
        lock.lock()
        defer { lock.unlock() }

        if let cached = cachedBestVoice[locale] {
            return cached
        }

        let voices = AVSpeechSynthesisVoice.speechVoices()
        let resolved = resolveBestVoice(for: locale, availableVoices: voices)
        if let resolved {
            cachedBestVoice[locale] = resolved
        }
        return resolved
    }

    public static func resolveBestVoice(
        for locale: String,
        availableVoices: [AVSpeechSynthesisVoice]
    ) -> AVSpeechSynthesisVoice? {
        let matchingVoices = availableVoices.filter { voice in
            (voice.language == locale || voice.language.hasPrefix("en")) &&
            !isBlacklisted(voiceName: voice.name)
        }

        guard !matchingVoices.isEmpty else {
            return AVSpeechSynthesisVoice(language: locale) ?? AVSpeechSynthesisVoice(language: "en-US")
        }

        // Rank 1: Premium quality voices
        if let premiumExact = matchingVoices.first(where: {
            $0.quality == .premium && $0.language == locale
        }) {
            return premiumExact
        }
        if let premiumFallback = matchingVoices.first(where: {
            $0.quality == .premium && $0.language.hasPrefix("en-US")
        }) {
            return premiumFallback
        }

        // Rank 2: Enhanced quality voices
        if let enhancedExact = matchingVoices.first(where: {
            $0.quality == .enhanced && $0.language == locale
        }) {
            return enhancedExact
        }
        if let enhancedFallback = matchingVoices.first(where: {
            $0.quality == .enhanced && $0.language.hasPrefix("en-US")
        }) {
            return enhancedFallback
        }

        // Rank 3: Curated whitelist compact voices
        for preferredName in curatedWhitelist {
            if let matched = matchingVoices.first(where: {
                $0.name.lowercased() == preferredName &&
                ($0.language == locale || $0.language.hasPrefix(locale))
            }) {
                return matched
            }
        }

        // Rank 4: Exact locale match with quality default
        if let exactLocale = matchingVoices.first(where: { $0.language == locale }) {
            return exactLocale
        }

        // Fallback: First non-blacklisted English voice
        return matchingVoices.first ?? AVSpeechSynthesisVoice(language: "en-US")
    }

    public static func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        cachedBestVoice.removeAll()
    }
}
