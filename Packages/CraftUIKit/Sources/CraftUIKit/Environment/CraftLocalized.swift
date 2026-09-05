import Foundation

/// Utility for accessing localized strings and formatted messages from the `CraftUIKit` resource bundle.
public enum CraftLocalized {
    // MARK: - Internal String Catalog Decodable Structures
    
    private struct StringCatalog: Decodable {
        struct Entry: Decodable {
            struct Localization: Decodable {
                struct StringUnit: Decodable {
                    let state: String?
                    let value: String?
                }
                let stringUnit: StringUnit?
            }
            let localizations: [String: Localization]?
        }
        let sourceLanguage: String
        let strings: [String: Entry]
    }

    private static let catalog: StringCatalog? = {
        guard let url = Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(StringCatalog.self, from: data)
    }()

    // MARK: - Public String Retrieval APIs

    /// Returns the localized string for the specified key from the CraftUIKit bundle.
    ///
    /// - Parameters:
    ///   - key: The key for a string in the localization table.
    ///   - comment: An optional comment describing the context of the string.
    /// - Returns: A localized version of the string designated by `key`.
    public static func string(_ key: String, comment: String = "") -> String {
        localizedString(forKey: key, language: nil)
    }

    /// Returns the localized string for the specified key and explicit language code.
    ///
    /// - Parameters:
    ///   - key: The key for a string in the localization table.
    ///   - language: The ISO language code (e.g., "en", "vi").
    ///   - comment: An optional comment describing the context of the string.
    /// - Returns: A localized version of the string designated by `key` in the requested language.
    public static func string(_ key: String, language: String, comment: String = "") -> String {
        localizedString(forKey: key, language: language)
    }

    /// Returns the localized string for the specified key and explicit locale.
    ///
    /// - Parameters:
    ///   - key: The key for a string in the localization table.
    ///   - locale: The locale to use for localization.
    ///   - comment: An optional comment describing the context of the string.
    /// - Returns: A localized version of the string designated by `key` in the requested locale.
    public static func string(_ key: String, locale: Locale, comment: String = "") -> String {
        let rawCode = locale.language.languageCode?.identifier ?? locale.identifier
        let languageCode = rawCode.split(whereSeparator: { $0 == "_" || $0 == "-" }).first.map(String.init) ?? rawCode
        return localizedString(forKey: key, language: languageCode.isEmpty ? nil : languageCode)
    }

    // MARK: - Public Formatting APIs

    /// Returns a formatted localized string using the localized template for `key` and the provided arguments.
    ///
    /// - Parameters:
    ///   - key: The key for a format string in the localization table.
    ///   - arguments: The arguments to substitute into the format string.
    /// - Returns: A formatted string using the localized format string designated by `key`.
    public static func format(_ key: String, _ arguments: CVarArg...) -> String {
        format(key, arguments)
    }

    /// Returns a formatted localized string using the localized template for `key` and an array of arguments.
    ///
    /// - Parameters:
    ///   - key: The key for a format string in the localization table.
    ///   - arguments: An array of arguments to substitute into the format string.
    /// - Returns: A formatted string using the localized format string designated by `key`.
    public static func format(_ key: String, _ arguments: [CVarArg]) -> String {
        let processedArgs = sanitizeArguments(for: key, arguments: arguments)
        let formatString = string(key)
        return String(format: formatString, arguments: processedArgs)
    }

    /// Returns a formatted localized string for an explicit language code.
    ///
    /// - Parameters:
    ///   - key: The key for a format string in the localization table.
    ///   - language: The ISO language code (e.g., "en", "vi").
    ///   - arguments: The arguments to substitute into the format string.
    /// - Returns: A formatted string using the localized format string designated by `key`.
    public static func format(_ key: String, language: String, _ arguments: CVarArg...) -> String {
        format(key, language: language, arguments)
    }

    /// Returns a formatted localized string for an explicit language code and argument array.
    ///
    /// - Parameters:
    ///   - key: The key for a format string in the localization table.
    ///   - language: The ISO language code (e.g., "en", "vi").
    ///   - arguments: An array of arguments to substitute into the format string.
    /// - Returns: A formatted string using the localized format string designated by `key`.
    public static func format(_ key: String, language: String, _ arguments: [CVarArg]) -> String {
        let processedArgs = sanitizeArguments(for: key, arguments: arguments)
        let formatString = string(key, language: language)
        return String(format: formatString, arguments: processedArgs)
    }

    private static func sanitizeArguments(for key: String, arguments: [CVarArg]) -> [CVarArg] {
        switch key {
        case "craft.common.unit.percent_format",
             "craft.speech.score_format",
             "craft.learning_path.continue_lesson_format":
            if let firstInt = arguments.first as? Int {
                return ["\(firstInt)%"]
            }
        case "craft.learning_path.node_current_format_a11y",
             "craft.learning_path.node_in_progress_format_a11y":
            if arguments.count >= 2, let percent = arguments[1] as? Int {
                return [arguments[0], "\(percent)%"]
            }
        default:
            break
        }
        return arguments
    }

    // MARK: - Private Helpers

    private static func localizedString(forKey key: String, language: String?) -> String {
        // 1. Try standard Bundle localization (if compiled into .lproj / .strings by Xcode)
        if let language = language {
            if let path = Bundle.module.path(forResource: language, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                let localized = bundle.localizedString(forKey: key, value: "__CRAFT_NOT_FOUND__", table: nil)
                if localized != "__CRAFT_NOT_FOUND__" {
                    return localized
                }
            }
        } else {
            let localized = Bundle.module.localizedString(forKey: key, value: "__CRAFT_NOT_FOUND__", table: nil)
            if localized != "__CRAFT_NOT_FOUND__" {
                return localized
            }
        }

        // 2. Lookup in Localizable.xcstrings catalog directly (SPM CLI runtime)
        if let catalog = catalog, let entry = catalog.strings[key] {
            if let lang = language, !lang.isEmpty {
                if let value = entry.localizations?[lang]?.stringUnit?.value {
                    return value
                }
                let shortLang = String(lang.prefix(2))
                if let value = entry.localizations?[shortLang]?.stringUnit?.value {
                    return value
                }
                if let fallback = entry.localizations?[catalog.sourceLanguage]?.stringUnit?.value {
                    return fallback
                }
                if let enFallback = entry.localizations?["en"]?.stringUnit?.value {
                    return enFallback
                }
            } else {
                let preferredCode = Locale.current.language.languageCode?.identifier ?? catalog.sourceLanguage
                if let value = entry.localizations?[preferredCode]?.stringUnit?.value {
                    return value
                }
                let shortPreferred = String(preferredCode.prefix(2))
                if let value = entry.localizations?[shortPreferred]?.stringUnit?.value {
                    return value
                }
                if let fallback = entry.localizations?[catalog.sourceLanguage]?.stringUnit?.value {
                    return fallback
                }
                if let enFallback = entry.localizations?["en"]?.stringUnit?.value {
                    return enFallback
                }
            }
        }

        return key
    }
}
