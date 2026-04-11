import SwiftUI

enum Theme {
    enum Colors {
        static let accentPrimary = Color.accentColor
        static let accentSecondary = Color(hex: "5AC8FA")
        
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color.gray
        
        static let surface = Color(hex: "1c1c1e")
        static let surfaceElevated = Color(hex: "2c2c2e")
        
        static let destructive = Color(hex: "FF453A")
        static let success = Color(hex: "30D158")
        static let warning = Color(hex: "FF9F0A")
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let xl: CGFloat = 16
        // 9999 is used instead of .greatestFiniteMagnitude because Capsule shape
        // uses this as a minimum radius — 9999 is visually indistinguishable from
        // infinite at any realistic view size, while remaining a valid CGFloat.
        static let capsule: CGFloat = 9999
    }

    enum Typography {
        static let sectionHeader = Font.system(size: 11, weight: .semibold, design: .default)
        static let body = Font.system(size: 13, weight: .medium, design: .default)
        static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
        static let caption = Font.system(size: 11, weight: .regular, design: .default)
        static let captionBold = Font.system(size: 11, weight: .semibold, design: .default)
        static let shortcut = Font.system(size: 12, weight: .medium, design: .monospaced)
        static let largeTitle = Font.system(size: 22, weight: .bold, design: .default)
        static let title = Font.system(size: 16, weight: .semibold, design: .default)
        static let titleSmall = Font.system(size: 14, weight: .semibold, design: .default)
    }

    enum Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let normal = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.35)
        static let spring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.7)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&int) else {
            // Invalid hex string — log warning and fall back to black
            print("Warning: Color(hex:) received invalid hex string '\(hex)', defaulting to black")
            self.init(red: 0, green: 0, blue: 0, opacity: 1)
            return
        }
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            print("Warning: Color(hex:) invalid length \(hex.count) for '\(hex)', defaulting to black")
            self.init(red: 0, green: 0, blue: 0, opacity: 1)
            return
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

struct GlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(height: 1)
    }
}

struct LiquidGlassBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.15 : 0.25), lineWidth: 1)
            )
    }
}

struct LiquidGlassCard: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2), lineWidth: 1)
            )
    }
}

struct GlassIcon: ViewModifier {
    let iconColor: Color
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(
                LinearGradient(
                    colors: [iconColor, iconColor.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}

extension View {
    func liquidGlassBackground() -> some View {
        modifier(LiquidGlassBackground())
    }
    
    func liquidGlassCard() -> some View {
        modifier(LiquidGlassCard())
    }
    
    func glassIcon(_ color: Color = Theme.Colors.accentPrimary) -> some View {
        modifier(GlassIcon(iconColor: color))
    }
}
