import SwiftUI

// MARK: - Colors
extension Color {
    static let backgroundPrimary = Color(hex: "000000")
    static let backgroundSecondary = Color(hex: "0A0A0A")
    static let surface = Color(hex: "141414")
    static let textPrimary = Color(hex: "E5E5E5")
    static let textSecondary = Color(hex: "8A8A8A")
    static let accent = Color(hex: "00D9FF")
    static let destructive = Color(hex: "FF4444")
    
    // Status colors
    static let statusOnTrack = Color(hex: "00FF88")
    static let statusTrendingHigh = Color(hex: "FFAA00")
    static let statusOverBudget = Color(hex: "FF4444")
    
    // Hex initializer
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

// MARK: - Typography
extension Font {
    static let numericXLarge = Font.system(size: 34, weight: .medium, design: .monospaced)
    static let numericLarge = Font.system(size: 28, weight: .medium, design: .monospaced)
    static let numeric = Font.system(size: 17, weight: .medium, design: .monospaced)
    static let numericSmall = Font.system(size: 15, weight: .medium, design: .monospaced)
    
    static let bodyEmphasized = Font.system(size: 17, weight: .medium)
}

// MARK: - Spacing
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

// MARK: - Corner Radius
enum CornerRadius {
    static let small: CGFloat = 2
    static let medium: CGFloat = 4
    static let large: CGFloat = 6
}

// MARK: - View Modifiers
extension View {
    func darkCard() -> some View {
        self
            .background(Color.surface)
            .cornerRadius(CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
    }
}
