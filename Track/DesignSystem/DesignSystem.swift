import SwiftUI

// MARK: - Color System
extension Color {
    // Technical framework backgrounds - structured grays
    static let backgroundPrimary = Color(hex: "0F0F0F")
    static let backgroundSecondary = Color(hex: "141414")
    static let backgroundTertiary = Color(hex: "1A1A1A")
    static let surface = Color(hex: "1E1E1E")
    static let surfaceElevated = Color(hex: "252525")
    static let surfaceHover = Color(hex: "2A2A2A")
    
    // High contrast text - technical precision
    static let textPrimary = Color(hex: "F5F5F5")
    static let textSecondary = Color(hex: "A0A0A0")
    static let textTertiary = Color(hex: "6B6B6B")
    static let textMuted = Color(hex: "4A4A4A")
    
    // Technical accent colors - structured and professional
    static let accent = Color(hex: "3B82F6") // Technical blue
    static let accentSecondary = Color(hex: "10B981") // Success green
    static let accentWarning = Color(hex: "F59E0B") // Warning amber
    static let accentError = Color(hex: "EF4444") // Error red
    static let accentInfo = Color(hex: "6366F1") // Info indigo
    
    // Status colors - data indicators
    static let statusOnTrack = Color(hex: "10B981")
    static let statusTrendingHigh = Color(hex: "F59E0B")
    static let statusOverBudget = Color(hex: "EF4444")
    static let statusNeutral = Color(hex: "6B7280")
    
    // Borders and dividers - structured separation
    static let borderPrimary = Color.white.opacity(0.12)
    static let borderSecondary = Color.white.opacity(0.08)
    static let divider = Color.white.opacity(0.1)
    static let dividerStrong = Color.white.opacity(0.15)
    
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

// MARK: - Typography (Technical, structured hierarchy)
extension Font {
    // Headers - structured hierarchy
    static let headerLarge = Font.system(size: 28, weight: .semibold, design: .default)
    static let headerMedium = Font.system(size: 22, weight: .semibold, design: .default)
    static let headerSmall = Font.system(size: 18, weight: .semibold, design: .default)
    static let headerTiny = Font.system(size: 14, weight: .semibold, design: .default)
    
    // Body - readable technical text
    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    static let body = Font.system(size: 14, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)
    static let bodyEmphasized = Font.system(size: 14, weight: .semibold, design: .default)
    
    // Monospaced (for numbers/data/metrics)
    static let numericXLarge = Font.system(size: 32, weight: .semibold, design: .monospaced)
    static let numericLarge = Font.system(size: 24, weight: .semibold, design: .monospaced)
    static let numeric = Font.system(size: 16, weight: .semibold, design: .monospaced)
    static let numericSmall = Font.system(size: 14, weight: .semibold, design: .monospaced)
    static let numericTiny = Font.system(size: 12, weight: .semibold, design: .monospaced)
    
    // Labels - technical metadata
    static let label = Font.system(size: 11, weight: .semibold, design: .default)
    static let labelSmall = Font.system(size: 10, weight: .semibold, design: .default)
    static let labelUppercase = Font.system(size: 11, weight: .semibold, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let captionSmall = Font.system(size: 11, weight: .regular, design: .default)
    static let code = Font.system(size: 13, weight: .regular, design: .monospaced)
}

// MARK: - Spacing (Structured grid system)
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    static let xxxxl: CGFloat = 48
    
    // Technical spacing - structured grid
    static let gridUnit: CGFloat = 4
    static let grid2: CGFloat = 8
    static let grid3: CGFloat = 12
    static let grid4: CGFloat = 16
    static let grid6: CGFloat = 24
    static let grid8: CGFloat = 32
}

// MARK: - Corner Radius (Minimal, technical)
enum CornerRadius {
    static let none: CGFloat = 0
    static let small: CGFloat = 3
    static let medium: CGFloat = 4
    static let large: CGFloat = 6
    static let xlarge: CGFloat = 8
}

// MARK: - Card Dimensions (Consistent sizing)
enum CardDimensions {
    static let padding: CGFloat = Spacing.lg
    static let minHeight: CGFloat = 120
    static let standardHeight: CGFloat = 200
    static let largeHeight: CGFloat = 280
}

// MARK: - View Modifiers (Technical framework components)
extension View {
    /// Technical data panel - structured container
    func dataCard() -> some View {
        self
            .frame(minHeight: CardDimensions.minHeight)
            .padding(CardDimensions.padding)
            .background(Color.surface)
            .cornerRadius(CornerRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .stroke(Color.borderPrimary, lineWidth: 1)
            )
    }
    
    /// Compact technical panel
    func compactCard() -> some View {
        self
            .padding(CardDimensions.padding)
            .background(Color.surface)
            .cornerRadius(CornerRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .stroke(Color.borderPrimary, lineWidth: 1)
            )
    }
    
    /// Elevated technical surface
    func elevatedSurface() -> some View {
        self
            .padding(CardDimensions.padding)
            .background(Color.surfaceElevated)
            .cornerRadius(CornerRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .stroke(Color.borderPrimary, lineWidth: 1)
            )
    }
    
    /// Technical table row container
    func tableRow() -> some View {
        self
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(Color.surface)
            .overlay(
                Rectangle()
                    .fill(Color.divider)
                    .frame(height: 1),
                alignment: .bottom
            )
    }
    
    /// Structured divider line
    func divider() -> some View {
        self
            .overlay(
                Rectangle()
                    .fill(Color.divider)
                    .frame(height: 1),
                alignment: .top
            )
    }
    
    /// Technical section header
    func sectionHeader() -> some View {
        self
            .font(.labelUppercase)
            .foregroundColor(.textTertiary)
            .tracking(0.5)
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
