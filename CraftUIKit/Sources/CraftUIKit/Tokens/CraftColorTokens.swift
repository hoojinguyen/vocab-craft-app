import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Color Token Protocol

/// Semantic color tokens for backgrounds, brand, text, borders, and feedback states.
public protocol CraftColorTokens: Sendable {
    // Canvas & Backgrounds
    var canvasBackground: Color { get }
    var surfaceCard: Color { get }
    var surfaceElevated: Color { get }
    var surfaceSubtle: Color { get }

    // Brand & Action
    var brandPrimary: Color { get }
    var brandSecondary: Color { get }
    var accent: Color { get }

    // Text & Ink
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var textMuted: Color { get }
    var textInverse: Color { get }

    // Borders & Lines
    var borderDefault: Color { get }
    var borderFocus: Color { get }
    var hairline: Color { get }

    // Status & Feedback
    var statusSuccess: Color { get }
    var statusWarning: Color { get }
    var statusDanger: Color { get }
    var statusInfo: Color { get }

    // Streak System
    var streakFreeze: Color { get }
    var streakPending: Color { get }
    var streakGlow: Color { get }
}

public extension CraftColorTokens {
    var streakFreeze: Color { Color(hex: 0x38BDF8) }
    var streakPending: Color { Color(hex: 0x94A3B8) }
    var streakGlow: Color { Color(hex: 0xF59E0B).opacity(0.35) }
}

// MARK: - Default Implementation

/// Default modern slate & indigo color tokens.
public struct CraftDefaultColorTokens: CraftColorTokens {
    // Canvas & Backgrounds
    public var canvasBackground: Color
    public var surfaceCard: Color
    public var surfaceElevated: Color
    public var surfaceSubtle: Color

    // Brand & Action
    public var brandPrimary: Color
    public var brandSecondary: Color
    public var accent: Color

    // Text & Ink
    public var textPrimary: Color
    public var textSecondary: Color
    public var textMuted: Color
    public var textInverse: Color

    // Borders & Lines
    public var borderDefault: Color
    public var borderFocus: Color
    public var hairline: Color

    // Status & Feedback
    public var statusSuccess: Color
    public var statusWarning: Color
    public var statusDanger: Color
    public var statusInfo: Color

    // Streak System
    public var streakFreeze: Color
    public var streakPending: Color
    public var streakGlow: Color

    public init(
        canvasBackground: Color = .craftDynamic(light: Color(hex: 0xFAFAF8), dark: Color(hex: 0x121214)),
        surfaceCard: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x1C1C1E)),
        surfaceElevated: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x2C2C2E)),
        surfaceSubtle: Color = .craftDynamic(light: Color(hex: 0xF4F4F0), dark: Color(hex: 0x242426)),
        brandPrimary: Color = Color(hex: 0xE06D3B),
        brandSecondary: Color = Color(hex: 0xD97706),
        accent: Color = Color(hex: 0xF59E0B),
        textPrimary: Color = .craftDynamic(light: Color(hex: 0x18181B), dark: Color(hex: 0xF4F4F5)),
        textSecondary: Color = .craftDynamic(light: Color(hex: 0x52525B), dark: Color(hex: 0xA1A1AA)),
        textMuted: Color = .craftDynamic(light: Color(hex: 0x71717A), dark: Color(hex: 0x71717A)),
        textInverse: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x121214)),
        borderDefault: Color = .craftDynamic(light: Color(hex: 0xE4E4E7), dark: Color(hex: 0x27272A)),
        borderFocus: Color = Color(hex: 0xE06D3B),
        hairline: Color = .craftDynamic(light: Color(hex: 0xE4E4E7).opacity(0.8), dark: Color(hex: 0x27272A).opacity(0.8)),
        statusSuccess: Color = Color(hex: 0x10B981),
        statusWarning: Color = Color(hex: 0xF59E0B),
        statusDanger: Color = Color(hex: 0xEF4444),
        statusInfo: Color = Color(hex: 0x0284C7),
        streakFreeze: Color = Color(hex: 0x38BDF8),
        streakPending: Color = Color(hex: 0x94A3B8),
        streakGlow: Color = Color(hex: 0xF59E0B).opacity(0.35)
    ) {
        self.canvasBackground = canvasBackground
        self.surfaceCard = surfaceCard
        self.surfaceElevated = surfaceElevated
        self.surfaceSubtle = surfaceSubtle
        self.brandPrimary = brandPrimary
        self.brandSecondary = brandSecondary
        self.accent = accent
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.textMuted = textMuted
        self.textInverse = textInverse
        self.borderDefault = borderDefault
        self.borderFocus = borderFocus
        self.hairline = hairline
        self.statusSuccess = statusSuccess
        self.statusWarning = statusWarning
        self.statusDanger = statusDanger
        self.statusInfo = statusInfo
        self.streakFreeze = streakFreeze
        self.streakPending = streakPending
        self.streakGlow = streakGlow
    }
}

// MARK: - Color Helpers

public extension Color {
    /// Returns a dynamic Color adapting between light and dark modes.
    static func craftDynamic(light: Color, dark: Color) -> Color {
        #if os(iOS)
        return Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #elseif os(macOS)
        return Color(NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(dark) : NSColor(light)
        }))
        #else
        return light
        #endif
    }

    /// Initializes a Color from a 24-bit hexadecimal integer (e.g. `0x6366F1`).
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: opacity
        )
    }
}
