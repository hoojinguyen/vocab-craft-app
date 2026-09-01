import SwiftUI

@available(*, deprecated, message: "Use CraftTheme via CraftUIKit")
public extension Color {
    // Dynamic Light / Dark mode helper
    static func dynamic(light: Color, dark: Color) -> Color {
        #if os(iOS)
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #elseif os(macOS)
        return Color(NSColor(name: nil, dynamicProvider: { appearance in
            let match = appearance.bestMatch(from: [.darkAqua, .aqua])
            return match == .darkAqua ? NSColor(dark) : NSColor(light)
        }))
        #else
        return light
        #endif
    }

    // Semantic Canvas & Surface Tokens
    static let vocabCanvas = dynamic(
        light: Color(red: 0.98, green: 0.98, blue: 0.96), // #FAF9F6 Minimal Off-White
        dark: Color(red: 0.07, green: 0.07, blue: 0.07)   // #121212 Minimal Dark Slate
    )

    static let vocabSurfaceSoft = dynamic(
        light: Color(red: 0.95, green: 0.95, blue: 0.93), // #F3F2EE Soft Slate
        dark: Color(red: 0.10, green: 0.10, blue: 0.10)   // #1A1A1A Dark Surface
    )

    static let vocabSurfaceCard = dynamic(
        light: Color.white,                              // #FFFFFF Pure White
        dark: Color(red: 0.12, green: 0.12, blue: 0.12)   // #1E1E1E Slate Card
    )

    static let vocabHeroTeal = dynamic(
        light: Color(red: 0.10, green: 0.23, blue: 0.23), // #1A3A3A Deep Forest Teal Container
        dark: Color(red: 0.06, green: 0.17, blue: 0.17)   // #0F2B2B Dark Teal Container
    )

    static let vocabHeroAccent = dynamic(
        light: Color(red: 0.04, green: 0.62, blue: 0.45), // #0A9E73 Vibrant Emerald Accent
        dark: Color(red: 0.71, green: 0.90, blue: 0.84)   // #B5E5D6 Bright Mint Accent
    )

    static let vocabInk = dynamic(
        light: Color(red: 0.07, green: 0.09, blue: 0.15), // #111827 Deep Ink
        dark: Color(red: 0.98, green: 0.98, blue: 0.98)   // #F9FAFB Off-White Ink
    )

    static let vocabMuted = dynamic(
        light: Color(red: 0.42, green: 0.45, blue: 0.50), // #6B7280 Muted Gray
        dark: Color(red: 0.61, green: 0.64, blue: 0.69)   // #9CA3AF Light Muted Gray
    )

    static let vocabHairline = dynamic(
        light: Color(red: 0.90, green: 0.91, blue: 0.92), // #E5E7EB Soft Hairline
        dark: Color.white.opacity(0.12)
    )

    // Functional Semantic Accent Tokens
    static let vocabCoral = dynamic(
        light: Color(red: 0.88, green: 0.22, blue: 0.28), // #E13847 Crimson Coral (Streak / Error / Alert)
        dark: Color(red: 0.97, green: 0.44, blue: 0.44)   // #F87171 Bright Coral
    )

    static let vocabMint = dynamic(
        light: Color(red: 0.04, green: 0.62, blue: 0.45), // #0A9E73 Emerald Mint (Success / Retention / A1-A2)
        dark: Color(red: 0.20, green: 0.83, blue: 0.60)   // #34D399 Bright Mint
    )

    static let vocabPeach = dynamic(
        light: Color(red: 0.90, green: 0.43, blue: 0.10), // #E66E1A Warm Amber Orange (Reflex Challenge / B1-B2)
        dark: Color(red: 0.98, green: 0.60, blue: 0.22)   // #FA9938 Bright Amber
    )

    static let vocabLavender = dynamic(
        light: Color(red: 0.55, green: 0.36, blue: 0.96), // #8B5CF6 Vibrant Purple (SRS Queue / C1-C2)
        dark: Color(red: 0.78, green: 0.72, blue: 0.95)   // #C8B8F2 Bright Lavender
    )

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8 * 17), (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
