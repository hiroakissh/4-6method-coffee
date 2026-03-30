import SwiftUI

enum AppDesignTokens {
    enum Colors {
        // User-provided palette
        static let coffee1 = CoffeeDesignPrimitives.Palette.coffee1
        static let coffee2 = CoffeeDesignPrimitives.Palette.coffee2
        static let coffee3 = CoffeeDesignPrimitives.Palette.coffee3
        static let coffee4 = CoffeeDesignPrimitives.Palette.coffee4
        static let coffee5 = CoffeeDesignPrimitives.Palette.coffee5

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
        static let timerRingTrack = Color.white.opacity(0.16)
        static let timerRingProgress = coffee5
        static let timerRingKnob = coffee1
        static let timerMainValue = Color.white.opacity(0.96)
        static let timerStepBadgeBackground = coffee4.opacity(0.2)
        static let timerStepBadgeBorder = coffee5.opacity(0.45)
        static let timerAmountAccent = coffee3
        static let meterTrack = coffee2.opacity(0.72)
        static let meterFill = coffee1.opacity(0.8)
        static let secondaryButtonBackground = Color.white.opacity(0.12)
        static let memoFieldBackground = Color.black.opacity(0.24)
    }

    enum Typography {
        enum TextStyleToken: CaseIterable {
            case screenTitle
            case sectionTitle
            case sectionLabel
            case itemTitle
            case body
            case supporting
            case supportingStrong
            case metricValue
            case heroValue
        }

        struct Token: Equatable {
            enum Sizing: Equatable {
                case textStyle(Font.TextStyle)
                case fixed(CGFloat)
            }

            enum Weight: Equatable {
                case regular
                case medium
                case semibold
                case bold
                case black

                var fontWeight: Font.Weight {
                    switch self {
                    case .regular:
                        return .regular
                    case .medium:
                        return .medium
                    case .semibold:
                        return .semibold
                    case .bold:
                        return .bold
                    case .black:
                        return .black
                    }
                }
            }

            let sizing: Sizing
            let weight: Weight
            let monospacedDigits: Bool
        }

        static let design = CoffeeDesignPrimitives.Typography.design

        static func configuration(for token: TextStyleToken) -> Token {
            switch token {
            case .screenTitle:
                return Token(sizing: .textStyle(.largeTitle), weight: .bold, monospacedDigits: false)
            case .sectionTitle:
                return Token(sizing: .textStyle(.title2), weight: .bold, monospacedDigits: false)
            case .sectionLabel:
                return Token(sizing: .textStyle(.title3), weight: .semibold, monospacedDigits: false)
            case .itemTitle:
                return Token(sizing: .textStyle(.title3), weight: .bold, monospacedDigits: false)
            case .body:
                return Token(sizing: .textStyle(.body), weight: .medium, monospacedDigits: false)
            case .supporting:
                return Token(sizing: .textStyle(.caption), weight: .medium, monospacedDigits: false)
            case .supportingStrong:
                return Token(sizing: .textStyle(.caption), weight: .bold, monospacedDigits: false)
            case .metricValue:
                return Token(sizing: .textStyle(.title2), weight: .bold, monospacedDigits: true)
            case .heroValue:
                return Token(sizing: .fixed(54), weight: .black, monospacedDigits: true)
            }
        }

        static func font(_ token: TextStyleToken) -> Font {
            let configuration = configuration(for: token)

            switch configuration.sizing {
            case .textStyle(let textStyle):
                return CoffeeDesignPrimitives.Typography.font(textStyle, weight: configuration.weight.fontWeight)
            case .fixed(let size):
                return .system(size: size, weight: configuration.weight.fontWeight, design: design)
            }
        }

        static func font(_ textStyle: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
            CoffeeDesignPrimitives.Typography.font(textStyle, weight: weight)
        }
    }

    enum Radius {
        static let card = CoffeeDesignPrimitives.Radius.card
        static let capsule = CoffeeDesignPrimitives.Radius.capsule
    }
}

private struct AppTextStyleModifier: ViewModifier {
    let token: AppDesignTokens.Typography.TextStyleToken

    @ViewBuilder
    func body(content: Content) -> some View {
        let configuration = AppDesignTokens.Typography.configuration(for: token)

        if configuration.monospacedDigits {
            content
                .font(AppDesignTokens.Typography.font(token))
                .monospacedDigit()
        } else {
            content
                .font(AppDesignTokens.Typography.font(token))
        }
    }
}

extension View {
    func appTextStyle(_ token: AppDesignTokens.Typography.TextStyleToken) -> some View {
        modifier(AppTextStyleModifier(token: token))
    }
}
