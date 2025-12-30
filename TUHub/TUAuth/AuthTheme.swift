// AuthTheme.swift
import SwiftUI

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var i: UInt64 = 0
        Scanner(string: s).scanHexInt64(&i)
        let r, g, b, a: UInt64
        switch s.count {
        case 8:
            (a, r, g, b) = (
                (i & 0xFF000000) >> 24,
                (i & 0x00FF0000) >> 16,
                (i & 0x0000FF00) >> 8,
                i & 0x000000FF
            )
        default:
            (a, r, g, b) = (
                255,
                (i & 0xFF0000) >> 16,
                (i & 0x00FF00) >> 8,
                i & 0x0000FF
            )
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

// MARK: - Towson Theme
struct TUHubAuthTheme {
    static let gold = Color(hex: "#FFBB00")
    static let oldGold = Color(hex: "#CC9900")
    static let graphite = Color(hex: "#3C3C3C")
    static let black = Color(hex: "#151500")
    static let mist = Color(hex: "#DDDDDD")
    static let white = Color(hex: "#FFFFFF")

    static let primary = gold
    static let background = Color(.systemBackground)
    static let surface = Color(.secondarySystemBackground)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let outline = graphite.opacity(0.25)
    static let destructive = Color.red
}
