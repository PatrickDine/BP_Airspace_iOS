import SwiftUI

enum AppColors {
    static let bgPrimary = Color(hex: "F9F6F0")
    static let bgSecondary = Color(hex: "F1EBE0")
    static let bgCard = Color.white
    static let bgDark = Color(hex: "1C1917")
    
    static let textPrimary = Color(hex: "1C1917")
    static let textSecondary = Color(hex: "57534E")
    static let textLight = Color(hex: "A8A29E")
    static let textOnDark = Color(hex: "F9F6F0")
    
    static let accentGold = Color(hex: "C29F5D")
    static let accentGoldHover = Color(hex: "A6874B")
    
    static let danger = Color(hex: "991B1B")
    static let warning = Color(hex: "B45309")
    static let safe = Color(hex: "166534")
    static let info = Color(hex: "1E40AF")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
