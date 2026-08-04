import SwiftUI

public extension Color {
    static let vocabCanvas = Color(hex: "#FFFAF0")
    static let vocabSurfaceSoft = Color(hex: "#FAF5E8")
    static let vocabHeroTeal = Color(hex: "#1A3A3A")
    static let vocabMint = Color(hex: "#A4D4C5")
    static let vocabPeach = Color(hex: "#FFB084")
    static let vocabLavender = Color(hex: "#B8A4ED")
    static let vocabCoral = Color(hex: "#FF6B5A")
    static let vocabInk = Color(hex: "#0A0A0A")

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
