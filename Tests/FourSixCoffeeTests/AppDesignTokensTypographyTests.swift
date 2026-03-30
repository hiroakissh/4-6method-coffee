import XCTest
@testable import FourSixCoffee

final class AppDesignTokensTypographyTests: XCTestCase {
    func testSemanticTypographyTokensMapToExpectedConfigurations() {
        XCTAssertEqual(
            AppDesignTokens.Typography.configuration(for: .screenTitle),
            .init(sizing: .textStyle(.largeTitle), weight: .bold, monospacedDigits: false)
        )
        XCTAssertEqual(
            AppDesignTokens.Typography.configuration(for: .sectionTitle),
            .init(sizing: .textStyle(.title2), weight: .bold, monospacedDigits: false)
        )
        XCTAssertEqual(
            AppDesignTokens.Typography.configuration(for: .sectionLabel),
            .init(sizing: .textStyle(.title3), weight: .semibold, monospacedDigits: false)
        )
        XCTAssertEqual(
            AppDesignTokens.Typography.configuration(for: .itemTitle),
            .init(sizing: .textStyle(.title3), weight: .bold, monospacedDigits: false)
        )
        XCTAssertEqual(
            AppDesignTokens.Typography.configuration(for: .body),
            .init(sizing: .textStyle(.body), weight: .medium, monospacedDigits: false)
        )
        XCTAssertEqual(
            AppDesignTokens.Typography.configuration(for: .supporting),
            .init(sizing: .textStyle(.caption), weight: .medium, monospacedDigits: false)
        )
        XCTAssertEqual(
            AppDesignTokens.Typography.configuration(for: .supportingStrong),
            .init(sizing: .textStyle(.caption), weight: .bold, monospacedDigits: false)
        )
        XCTAssertEqual(
            AppDesignTokens.Typography.configuration(for: .metricValue),
            .init(sizing: .textStyle(.title2), weight: .bold, monospacedDigits: true)
        )
    }

    func testHeroValueUsesFixedDisplaySizing() {
        XCTAssertEqual(
            AppDesignTokens.Typography.configuration(for: .heroValue),
            .init(sizing: .fixed(54), weight: .black, monospacedDigits: true)
        )
    }

    func testTypographyTokenSetRemainsIntentional() {
        XCTAssertEqual(AppDesignTokens.Typography.TextStyleToken.allCases.count, 9)
    }
}
