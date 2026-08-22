import SwiftUI

// MARK: - Typography Styles

/// Enumeration of standardized typography scale styles in CraftUIKit.
public enum CraftTypographyStyle: String, Sendable, CaseIterable {
    case displayLarge
    case displayHero
    case titleLarge
    case titleMedium
    case headline
    case bodyLarge
    case bodyMedium
    case label
    case caption
}

// MARK: - Typography Token Protocol

/// Typography scale tokens defining fonts for titles, body, and labels.
public protocol CraftTypographyTokens: Sendable {
    var displayLarge: Font { get }
    var displayHero: Font { get }
    var titleLarge: Font { get }
    var titleMedium: Font { get }
    var headline: Font { get }
    var bodyLarge: Font { get }
    var bodyMedium: Font { get }
    var label: Font { get }
    var caption: Font { get }

    func font(for style: CraftTypographyStyle) -> Font
}

public extension CraftTypographyTokens {
    func font(for style: CraftTypographyStyle) -> Font {
        switch style {
        case .displayLarge: return displayLarge
        case .displayHero: return displayHero
        case .titleLarge: return titleLarge
        case .titleMedium: return titleMedium
        case .headline: return headline
        case .bodyLarge: return bodyLarge
        case .bodyMedium: return bodyMedium
        case .label: return label
        case .caption: return caption
        }
    }
}

// MARK: - Default Implementation

/// Default typography tokens using Apple System Font scale.
public struct CraftDefaultTypographyTokens: CraftTypographyTokens {
    public var displayLarge: Font
    public var displayHero: Font
    public var titleLarge: Font
    public var titleMedium: Font
    public var headline: Font
    public var bodyLarge: Font
    public var bodyMedium: Font
    public var label: Font
    public var caption: Font

    public init(
        displayLarge: Font = .system(.largeTitle, design: .rounded, weight: .bold),
        displayHero: Font = .system(size: 72, weight: .black, design: .rounded),
        titleLarge: Font = .system(.title, design: .default, weight: .bold),
        titleMedium: Font = .system(.title2, design: .default, weight: .semibold),
        headline: Font = .system(.headline, design: .default, weight: .semibold),
        bodyLarge: Font = .system(.body, design: .default, weight: .regular),
        bodyMedium: Font = .system(.callout, design: .default, weight: .regular),
        label: Font = .system(.subheadline, design: .default, weight: .medium),
        caption: Font = .system(.caption, design: .default, weight: .regular)
    ) {
        self.displayLarge = displayLarge
        self.displayHero = displayHero
        self.titleLarge = titleLarge
        self.titleMedium = titleMedium
        self.headline = headline
        self.bodyLarge = bodyLarge
        self.bodyMedium = bodyMedium
        self.label = label
        self.caption = caption
    }
}
