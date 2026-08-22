import SwiftUI

// MARK: - Typography Styles

/// Enumeration of standardized typography scale styles in CraftUIKit.
public enum CraftTypographyStyle: String, Sendable, CaseIterable {
    case displayLarge
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
    public var titleLarge: Font
    public var titleMedium: Font
    public var headline: Font
    public var bodyLarge: Font
    public var bodyMedium: Font
    public var label: Font
    public var caption: Font

    public init(
        displayLarge: Font = .system(size: 32, weight: .bold, design: .default),
        titleLarge: Font = .system(size: 24, weight: .bold, design: .default),
        titleMedium: Font = .system(size: 18, weight: .semibold, design: .default),
        headline: Font = .system(size: 16, weight: .semibold, design: .default),
        bodyLarge: Font = .system(size: 16, weight: .regular, design: .default),
        bodyMedium: Font = .system(size: 14, weight: .regular, design: .default),
        label: Font = .system(size: 12, weight: .medium, design: .default),
        caption: Font = .system(size: 11, weight: .regular, design: .default)
    ) {
        self.displayLarge = displayLarge
        self.titleLarge = titleLarge
        self.titleMedium = titleMedium
        self.headline = headline
        self.bodyLarge = bodyLarge
        self.bodyMedium = bodyMedium
        self.label = label
        self.caption = caption
    }
}
