import Foundation

/// High-performance string normalization engine for speech recognition evaluation.
///
/// Provides deterministic text normalization including lowercasing, English contraction expansion
/// (supporting standard and curly apostrophes), digit-to-word conversions, punctuation stripping,
/// and word tokenization.
public enum StringNormalizer {

    // MARK: - Contraction Mappings

    private static let contractionMappings: [(regex: NSRegularExpression, replacement: String)] = {
        let pairs: [(String, String)] = [
            // Negative Contractions
            ("can't", "cannot"),
            ("won't", "will not"),
            ("don't", "do not"),
            ("doesn't", "does not"),
            ("didn't", "did not"),
            ("isn't", "is not"),
            ("aren't", "are not"),
            ("wasn't", "was not"),
            ("weren't", "were not"),
            ("haven't", "have not"),
            ("hasn't", "has not"),
            ("hadn't", "had not"),
            ("wouldn't", "would not"),
            ("shouldn't", "should not"),
            ("couldn't", "could not"),
            ("mustn't", "must not"),
            ("ain't", "is not"),

            // Pronoun + 'm / 're / 's
            ("i'm", "i am"),
            ("you're", "you are"),
            ("he's", "he is"),
            ("she's", "she is"),
            ("it's", "it is"),
            ("we're", "we are"),
            ("they're", "they are"),
            ("that's", "that is"),
            ("there's", "there is"),
            ("what's", "what is"),
            ("who's", "who is"),
            ("where's", "where is"),
            ("how's", "how is"),
            ("let's", "let us"),

            // Pronoun + 've
            ("i've", "i have"),
            ("you've", "you have"),
            ("we've", "we have"),
            ("they've", "they have"),
            ("who've", "who have"),
            ("what've", "what have"),
            ("would've", "would have"),
            ("should've", "should have"),
            ("could've", "could have"),
            ("must've", "must have"),

            // Pronoun + 'll
            ("i'll", "i will"),
            ("you'll", "you will"),
            ("he'll", "he will"),
            ("she'll", "she will"),
            ("it'll", "it will"),
            ("we'll", "we will"),
            ("they'll", "they will"),
            ("that'll", "that will"),
            ("there'll", "there will"),

            // Pronoun + 'd
            ("i'd", "i would"),
            ("you'd", "you would"),
            ("he'd", "he would"),
            ("she'd", "she would"),
            ("we'd", "we would"),
            ("they'd", "they would")
        ]

        return pairs.compactMap { contraction, replacement in
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: contraction) + "\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                return nil
            }
            return (regex, replacement)
        }
    }()

    private static let plainNumberRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "\\b(?:\\d{1,3}(?:,\\d{3})+|\\d+)(?:\\.\\d+)?\\b")
    }()

    private static let ordinalMappings: [(regex: NSRegularExpression, replacement: String)] = {
        let ordinals: [(String, String)] = [
            ("1st", "first"),
            ("2nd", "second"),
            ("3rd", "third"),
            ("4th", "fourth"),
            ("5th", "fifth"),
            ("6th", "sixth"),
            ("7th", "seventh"),
            ("8th", "eighth"),
            ("9th", "ninth"),
            ("10th", "tenth")
        ]

        return ordinals.compactMap { ordinal, word in
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: ordinal) + "\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                return nil
            }
            return (regex, word)
        }
    }()

    private static let digitMap: [String: String] = [
        "0": "zero",
        "1": "one",
        "2": "two",
        "3": "three",
        "4": "four",
        "5": "five",
        "6": "six",
        "7": "seven",
        "8": "eight",
        "9": "nine",
        "10": "ten",
        "11": "eleven",
        "12": "twelve",
        "13": "thirteen",
        "14": "fourteen",
        "15": "fifteen",
        "16": "sixteen",
        "17": "seventeen",
        "18": "eighteen",
        "19": "nineteen",
        "20": "twenty",
        "30": "thirty",
        "40": "forty",
        "50": "fifty",
        "60": "sixty",
        "70": "seventy",
        "80": "eighty",
        "90": "ninety",
        "100": "one hundred"
    ]

    private static let spellOutFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    // MARK: - Public API

    /// Normalizes the input text by lowercasing, expanding contractions, converting digits to words,
    /// stripping punctuation, and collapsing multiple spaces.
    ///
    /// - Parameter text: Raw input string.
    /// - Returns: Fully normalized string.
    public static func normalize(_ text: String) -> String {
        guard !text.isEmpty else { return "" }

        let lowercased = text.lowercased()
        let expanded = expandContractions(lowercased)
        let digitsConverted = convertDigitsToWords(expanded)
        let stripped = stripPunctuation(digitsConverted)
        let tokens = stripped.split(whereSeparator: \.isWhitespace)
        return tokens.joined(separator: " ")
    }

    /// Tokenizes the input text into an array of normalized words.
    ///
    /// - Parameter text: Raw input string.
    /// - Returns: Array of normalized word tokens.
    public static func tokenize(_ text: String) -> [String] {
        let normalized = normalize(text)
        guard !normalized.isEmpty else { return [] }
        return normalized.split(separator: " ").map(String.init)
    }

    /// Expands standard and curly-apostrophe English contractions (e.g. "i'm" -> "i am", "don't" -> "do not").
    ///
    /// - Parameter text: Input string.
    /// - Returns: String with contractions expanded.
    public static func expandContractions(_ text: String) -> String {
        guard !text.isEmpty else { return "" }

        // Normalize unicode apostrophe variants to ASCII single quote
        var result = text
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "‘", with: "'")
            .replacingOccurrences(of: "ʼ", with: "'")
            .replacingOccurrences(of: "`", with: "'")

        for mapping in contractionMappings {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = mapping.regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: mapping.replacement)
        }

        return result
    }

    /// Converts standalone digits and basic ordinals to words (e.g. "0" -> "zero", "10" -> "ten", "1st" -> "first").
    ///
    /// - Parameter text: Input string.
    /// - Returns: String with numbers replaced with words.
    public static func convertDigitsToWords(_ text: String) -> String {
        guard !text.isEmpty else { return "" }

        var result = text

        // Convert ordinals first (1st -> first, etc.)
        for mapping in ordinalMappings {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = mapping.regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: mapping.replacement)
        }

        // Convert standalone numeric digits
        guard let regex = plainNumberRegex else { return result }
        let nsString = result as NSString
        let matches = regex.matches(in: result, options: [], range: NSRange(location: 0, length: nsString.length))

        for match in matches.reversed() {
            let matchString = nsString.substring(with: match.range)
            let cleanString = matchString.replacingOccurrences(of: ",", with: "")
            let replacement: String

            if let mapped = digitMap[cleanString] {
                replacement = mapped
            } else if cleanString.contains(".") {
                if let num = Double(cleanString), let spelled = spellOutFormatter.string(from: NSNumber(value: num)) {
                    replacement = spelled.replacingOccurrences(of: "-", with: " ")
                } else {
                    replacement = matchString
                }
            } else if let num = Int(cleanString), let spelled = spellOutFormatter.string(from: NSNumber(value: num)) {
                replacement = spelled.replacingOccurrences(of: "-", with: " ")
            } else if let num = Double(cleanString), let spelled = spellOutFormatter.string(from: NSNumber(value: num)) {
                replacement = spelled.replacingOccurrences(of: "-", with: " ")
            } else {
                replacement = matchString
            }

            guard let matchRange = Range(match.range, in: result) else { continue }
            result.replaceSubrange(matchRange, with: replacement)
        }

        return result
    }

    /// Strips punctuation marks and replaces them with spaces to prevent merging words, while dropping standalone single quotes.
    ///
    /// - Parameter text: Input string.
    /// - Returns: String with punctuation removed.
    public static func stripPunctuation(_ text: String) -> String {
        var result = ""
        result.reserveCapacity(text.count)

        for char in text {
            if char.isLetter || char.isNumber || char.isWhitespace {
                result.append(char)
            } else if char == "'" {
                // Drop apostrophes so words like "cat's" become "cats" and "'quote'" becomes "quote"
                continue
            } else {
                // Replace punctuation with space to prevent concatenating adjacent tokens (e.g. "hello,world")
                result.append(" ")
            }
        }

        return result
    }
}
