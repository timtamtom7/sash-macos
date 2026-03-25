import SwiftUI

enum Theme {
    enum Colors {
        static let background = Color(hex: "0d0d0d")
        static let surface = Color(hex: "1a1a1a")
        static let surfaceElevated = Color(hex: "252525")
        static let accent = Color(hex: "3b82f6")
        static let accentSecondary = Color(hex: "60a5fa")
        static let textPrimary = Color(hex: "f5f5f5")
        static let textSecondary = Color(hex: "a0a0a0")
        static let textTertiary = Color(hex: "666666")
        static let border = Color(hex: "2a2a2a")
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    enum CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
    }

    enum Typography {
        static let sectionHeader = Font.system(size: 11, weight: .semibold)
        static let body = Font.system(size: 13, weight: .medium)
        static let caption = Font.system(size: 11, weight: .regular)
        static let shortcut = Font.system(size: 12, weight: .medium, design: .monospaced)
    }
}

// MARK: - Color Extension

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
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


