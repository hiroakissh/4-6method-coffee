import SwiftUI

enum AppDesignTokens {
    enum Colors {
        // User-provided palette
        static let coffee1 = Color(hex: 0xAB5024)
        static let coffee2 = Color(hex: 0x5E260A)
        static let coffee3 = Color(hex: 0xF7844D)
        static let coffee4 = Color(hex: 0x015E57)
        static let coffee5 = Color(hex: 0x24ABA0)

        // Semantic aliases
        static let backgroundTop = coffee2
        static let backgroundBottom = Color.black
        static let cardBackground = coffee2.opacity(0.58)
        static let cardBorder = coffee3.opacity(0.2)
        static let cardShadow = coffee2.opacity(0.45)
        static let controlBackground = Color.black.opacity(0.34)
        static let controlBorder = coffee3.opacity(0.22)
        static let textPrimary = Color.white.opacity(0.94)
        static let textSecondary = Color.white.opacity(0.56)
        static let headingAccent = coffee5
        static let tasteAccent = coffee5
        static let sliderAccent = coffee1
        static let activeSegment = coffee1
        static let totalWaterBackground = coffee1.opacity(0.2)
        static let totalWaterBorder = coffee1.opacity(0.55)
        static let ctaBackground = coffee5
        static let ctaText = Color.white.opacity(0.95)
    }

    enum Typography {
        static let design: Font.Design = .rounded

        static func font(_ textStyle: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
            .system(textStyle, design: design).weight(weight)
        }
    }

    enum Radius {
        static let card: CGFloat = 30
        static let capsule: CGFloat = 24
    }
}

private extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xff) / 255
        let green = Double((hex >> 8) & 0xff) / 255
        let blue = Double(hex & 0xff) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
