import SwiftUI

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
        light: Color(red: 1.0, green: 0.98, blue: 0.94), // #FFFAF0 Warm Cream
        dark: Color(red: 0.04, green: 0.10, blue: 0.10)   // #0A1A1A Deep Forest Night
    )
    
    static let vocabSurfaceSoft = dynamic(
        light: Color(red: 0.98, green: 0.96, blue: 0.91), // #FAF5E8
        dark: Color(red: 0.08, green: 0.14, blue: 0.14)   // #142424
    )

    static let vocabSurfaceCard = dynamic(
        light: Color.white,                              // #FFFFFF Pure White
        dark: Color(red: 0.10, green: 0.16, blue: 0.16)   // #1A2A2A Slate Card
    )

    static let vocabHeroTeal = dynamic(
        light: Color(red: 0.10, green: 0.23, blue: 0.23), // #1A3A3A Deep Forest Teal
        dark: Color(red: 0.06, green: 0.17, blue: 0.17)   // #0F2B2B Dark Teal
    )

    static let vocabHeroAccent = dynamic(
        light: Color(red: 0.10, green: 0.23, blue: 0.23), // #1A3A3A Deep Forest Teal
        dark: Color(red: 0.71, green: 0.90, blue: 0.84)   // #B5E5D6 Bright Mint Accent
    )

    static let vocabInk = dynamic(
        light: Color(red: 0.04, green: 0.04, blue: 0.04), // #0A0A0A Off-Black
        dark: Color(red: 0.94, green: 0.96, blue: 0.99)   // #F0F6FC Soft Off-White
    )

    static let vocabMuted = dynamic(
        light: Color(red: 0.41, green: 0.41, blue: 0.41), // #6A6A6A Neutral Gray
        dark: Color(red: 0.63, green: 0.68, blue: 0.75)   // #A0AEC0 Light Slate Gray
    )

    static let vocabHairline = dynamic(
        light: Color(red: 0.90, green: 0.90, blue: 0.90), // #E5E5E5
        dark: Color.white.opacity(0.12)
    )

    // Brand Accent Tokens
    static let vocabCoral = dynamic(
        light: Color(red: 0.88, green: 0.22, blue: 0.28), // #E13847 High-Contrast Crimson Coral
        dark: Color(red: 0.97, green: 0.44, blue: 0.44)   // #F87171 Bright Coral
    )

    static let vocabMint = dynamic(
        light: Color(red: 0.04, green: 0.62, blue: 0.45), // #0A9E73 High-Contrast Emerald Green
        dark: Color(red: 0.20, green: 0.83, blue: 0.60)   // #34D399 Bright Mint Accent
    )


    static let vocabPeach = dynamic(
        light: Color(red: 0.90, green: 0.43, blue: 0.10), // #E66E1A High-Contrast Warm Amber Orange (Light)
        dark: Color(red: 0.98, green: 0.60, blue: 0.22)   // #FA9938 Vibrant Solar Orange (Dark)
    )


    static let vocabLavender = dynamic(
        light: Color(red: 0.72, green: 0.64, blue: 0.93), // #B8A4ED Lavender
        dark: Color(red: 0.78, green: 0.72, blue: 0.95)  // #C8B8F2 (+Luminance)
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
