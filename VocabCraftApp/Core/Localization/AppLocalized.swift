import Foundation

// MARK: - Internal String Catalog Decodable Structures

private struct AppStringCatalogStringUnit: Decodable, Sendable {
    let state: String?
    let value: String?
}

private struct AppStringCatalogLocalization: Decodable, Sendable {
    let stringUnit: AppStringCatalogStringUnit?
}

private struct AppStringCatalogEntry: Decodable, Sendable {
    let localizations: [String: AppStringCatalogLocalization]?
}

private struct AppStringCatalog: Decodable, Sendable {
    let sourceLanguage: String
    let strings: [String: AppStringCatalogEntry]
}

/// Utility for accessing localized strings and formatted messages from `VocabCraftApp`'s resource bundle or xcstrings catalog.
public enum AppLocalized: Sendable {
    private static var resourceBundle: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle.main
        #endif
    }

    private static let catalog: AppStringCatalog? = {
        var potentialURLs: [URL?] = [
            resourceBundle.url(forResource: "Localizable", withExtension: "xcstrings"),
            Bundle.main.url(forResource: "Localizable", withExtension: "xcstrings")
        ]
        let containingAppURL = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
        if let containingAppBundle = Bundle(url: containingAppURL) {
            potentialURLs.append(containingAppBundle.url(forResource: "Localizable", withExtension: "xcstrings"))
        }
        for case let url? in potentialURLs {
            if let data = try? Data(contentsOf: url),
               let decoded = try? JSONDecoder().decode(AppStringCatalog.self, from: data) {
                return decoded
            }
        }
        return nil
    }()

    // MARK: - Public String Retrieval APIs

    public static func string(_ key: String, comment: String = "") -> String {
        localizedString(forKey: key, language: nil)
    }

    public static func string(_ key: String, language: String, comment: String = "") -> String {
        localizedString(forKey: key, language: language)
    }

    public static func format(_ key: String, _ arguments: CVarArg...) -> String {
        format(key, arguments)
    }

    public static func format(_ key: String, _ arguments: [CVarArg]) -> String {
        let formatString = string(key)
        return String(format: formatString, arguments: arguments)
    }

    // MARK: - Private Helpers

    private static func localizedString(forKey key: String, language: String?) -> String {
        // 1. Try standard Bundle localization (if compiled into .lproj / .strings by Xcode)
        let candidateBundles: [Bundle] = {
            var bundles = [resourceBundle, Bundle.main]
            let containingAppURL = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
            if let containingAppBundle = Bundle(url: containingAppURL) {
                bundles.append(containingAppBundle)
            }
            return bundles
        }()

        for bundle in candidateBundles {
            if let language = language {
                if let path = bundle.path(forResource: language, ofType: "lproj"),
                   let langBundle = Bundle(path: path) {
                    let localized = langBundle.localizedString(forKey: key, value: "__APP_NOT_FOUND__", table: nil)
                    if localized != "__APP_NOT_FOUND__" {
                        return localized
                    }
                }
            } else {
                let localized = bundle.localizedString(forKey: key, value: "__APP_NOT_FOUND__", table: nil)
                if localized != "__APP_NOT_FOUND__" {
                    return localized
                }
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
