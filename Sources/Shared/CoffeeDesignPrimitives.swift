import SwiftUI

enum CoffeeDesignPrimitives {
    enum Palette {
        static let coffee1 = Color(hex: 0xAB5024)
        static let coffee2 = Color(hex: 0x5E260A)
        static let coffee3 = Color(hex: 0xF7844D)
        static let coffee4 = Color(hex: 0x015E57)
        static let coffee5 = Color(hex: 0x24ABA0)
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
