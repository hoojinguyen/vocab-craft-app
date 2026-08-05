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
        light: Color(red: 0.12, green: 0.16, blue: 0.22), // #1F2937 Editorial Deep Slate
        dark: Color(red: 0.12, green: 0.16, blue: 0.23)   // #1E293B Dark Slate Container
    )

    static let vocabHeroAccent = dynamic(
        light: Color(red: 0.22, green: 0.26, blue: 0.32), // #374151 Slate Accent
        dark: Color(red: 0.90, green: 0.91, blue: 0.92)   // #E5E7EB Minimal Light Accent
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

    // Brand Accent Tokens (Streamlined for Minimalist UI)
    static let vocabCoral = dynamic(
        light: Color(red: 0.60, green: 0.11, blue: 0.11), // #991B1B Deep Muted Red Accent
        dark: Color(red: 0.97, green: 0.44, blue: 0.44)   // #F87171 Bright Coral
    )

    static let vocabMint = dynamic(
        light: Color(red: 0.22, green: 0.26, blue: 0.32), // #374151 Minimal Slate
        dark: Color(red: 0.82, green: 0.84, blue: 0.86)   // #D1D5DB Minimal Off-White Accent
    )

    static let vocabPeach = dynamic(
        light: Color(red: 0.29, green: 0.33, blue: 0.39), // #4B5563 Medium Slate
        dark: Color(red: 0.61, green: 0.64, blue: 0.69)   // #9CA3AF Light Slate
    )

    static let vocabLavender = dynamic(
        light: Color(red: 0.42, green: 0.45, blue: 0.50), // #6B7280 Soft Slate
        dark: Color(red: 0.42, green: 0.45, blue: 0.50)   // #6B7280 Dark Muted Slate
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
