import SwiftUI

enum AppColors {
    // We rely on standard Apple Materials for backgrounds:
    // .ultraThinMaterial, .thinMaterial, .regularMaterial, .thickMaterial
    // The below colors are accents or overrides where materials cannot be used.
    
    static let bgPrimary = Color(.systemBackground)
    static let bgSecondary = Color(.secondarySystemBackground)
    
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    
    static let accentGold = Color.blue // Aviation Blue instead of gold for a premium native look
    static let accentGoldHover = Color.blue.opacity(0.8)
    
    static let danger = Color.red
    static let warning = Color.orange
    static let safe = Color.green
    static let info = Color.blue
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
