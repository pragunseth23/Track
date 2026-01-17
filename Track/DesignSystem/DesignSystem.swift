import SwiftUI

// MARK: - Color System
extension Color {
    // Deep black backgrounds
    static let backgroundPrimary = Color(hex: "000000")
    static let backgroundSecondary = Color(hex: "0A0A0A")
    static let backgroundTertiary = Color(hex: "141414")
    static let surface = Color(hex: "1A1A1A")
    static let surfaceElevated = Color(hex: "242424")
    
    // High contrast text
    static let textPrimary = Color(hex: "FFFFFF")
    static let textSecondary = Color(hex: "B0B0B0")
    static let textTertiary = Color(hex: "707070")
    
    // Accent colors (analytical, data-focused)
    static let accent = Color(hex: "00D9FF") // Cyan
    static let accentSecondary = Color(hex: "00FF88") // Green
    static let accentWarning = Color(hex: "FFAA00") // Amber
    static let accentError = Color(hex: "FF4444") // Red
    
    // Status colors
    static let statusOnTrack = Color(hex: "00FF88")
    static let statusTrendingHigh = Color(hex: "FFAA00")
    static let statusOverBudget = Color(hex: "FF4444")
    static let statusNeutral = Color(hex: "B0B0B0")
    
    // Borders and dividers
    static let borderPrimary = Color.white.opacity(0.1)
    static let borderSecondary = Color.white.opacity(0.05)
    static let divider = Color.white.opacity(0.08)
    
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

// MARK: - Typography (Data-focused, monospaced for numbers)
extension Font {
    // Headers
    static let headerLarge = Font.system(size: 32, weight: .semibold, design: .default)
    static let headerMedium = Font.system(size: 24, weight: .semibold, design: .default)
    static let headerSmall = Font.system(size: 20, weight: .semibold, design: .default)
    
    // Body
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    static let body = Font.system(size: 15, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)
    static let bodyEmphasized = Font.system(size: 17, weight: .medium, design: .default)
    
    // Monospaced (for numbers/data)
    static let numericXLarge = Font.system(size: 36, weight: .medium, design: .monospaced)
    static let numericLarge = Font.system(size: 28, weight: .medium, design: .monospaced)
    static let numeric = Font.system(size: 17, weight: .medium, design: .monospaced)
    static let numericSmall = Font.system(size: 15, weight: .medium, design: .monospaced)
    static let numericTiny = Font.system(size: 13, weight: .medium, design: .monospaced)
    
    // Labels
    static let label = Font.system(size: 12, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let captionSmall = Font.system(size: 11, weight: .regular, design: .default)
}

// MARK: - Spacing (Tight, data-dense)
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    static let xxxxl: CGFloat = 48
}

// MARK: - Corner Radius (Minimal, sharp)
enum CornerRadius {
    static let none: CGFloat = 0
    static let small: CGFloat = 4
    static let medium: CGFloat = 6
    static let large: CGFloat = 8
}

// MARK: - Card Dimensions (Consistent sizing)
enum CardDimensions {
    static let padding: CGFloat = Spacing.lg
    static let minHeight: CGFloat = 120
    static let standardHeight: CGFloat = 200
    static let largeHeight: CGFloat = 280
}

// MARK: - View Modifiers (Cards and surfaces)
extension View {
    /// Data card with subtle border and consistent sizing
    func dataCard() -> some View {
        self
            .frame(minHeight: CardDimensions.minHeight)
            .padding(CardDimensions.padding)
            .background(Color.surface)
            .cornerRadius(CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(Color.borderPrimary, lineWidth: 1)
            )
    }
    
    /// Compact data card for smaller content
    func compactCard() -> some View {
        self
            .padding(CardDimensions.padding)
            .background(Color.surface)
            .cornerRadius(CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(Color.borderPrimary, lineWidth: 1)
            )
    }
    
    /// Elevated surface for important content
    func elevatedSurface() -> some View {
        self
            .padding(CardDimensions.padding)
            .background(Color.surfaceElevated)
            .cornerRadius(CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(Color.borderPrimary, lineWidth: 1)
            )
    }
    
    /// Subtle divider line
    func divider() -> some View {
        self
            .overlay(
                Rectangle()
                    .fill(Color.divider)
                    .frame(height: 1),
                alignment: .top
            )
    }
}

// MARK: - Liquid Glass Effect
struct LiquidGlass: ViewModifier {
    let opacity: Double
    
    init(opacity: Double = 0.3) {
        self.opacity = opacity
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
    }
}

extension View {
    func liquidGlass(opacity: Double = 0.3) -> some View {
        modifier(LiquidGlass(opacity: opacity))
    }
}
