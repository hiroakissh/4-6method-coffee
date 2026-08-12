import XCTest
@testable import FourSixCoffee

@MainActor
final class QuickBrewTests: XCTestCase {
    func testQuickBrewGeneratesRecipeFromThreeInputs() {
        let request = QuickBrewRequest(
            coffeeDoseGrams: 22,
            roastLevel: .light,
            tasteProfile: .sweet
        )

        let recipe = QuickBrewGenerator.generate(from: request)
        let pours = recipe.phases.flatMap(\.pours)

        XCTAssertEqual(recipe.metadata.name, "Quick Brew")
        XCTAssertEqual(recipe.metadata.sourceType, .preset)
        XCTAssertEqual(recipe.defaults.coffeeDoseGrams, 22, accuracy: 0.0001)
        XCTAssertEqual(recipe.defaults.totalWaterGrams, 330)
        XCTAssertEqual(recipe.defaults.grindSize, .medium)
        XCTAssertEqual(recipe.phases.first?.temperature.points.first?.celsius, 93)
        XCTAssertEqual(pours.count, 6)
        XCTAssertEqual(pours.first?.amountGrams, 59)
    }

    func testQuickBrewRequestNormalizesDoseToHalfGramWithinRange() {
        let request = QuickBrewRequest(
            coffeeDoseGrams: 100,
            roastLevel: .dark,
            tasteProfile: .light
        )

        XCTAssertEqual(request.coffeeDoseGrams, 40)
        XCTAssertEqual(
            QuickBrewRequest.normalizedCoffeeDose(19.24),
            19.0,
            accuracy: 0.0001
        )
    }

    func testApplyingQuickBrewUpdatesPlannerInput() {
        let store = AppStore(
            dependencies: .preview(),
            seedSampleDataIfEmpty: false
        )
        store.updateQuickBrewDose(24)
        store.updateQuickBrewRoast(.dark)
        store.updateQuickBrewTaste(.light)

        store.applyQuickBrew()

        XCTAssertEqual(store.currentInput.coffeeDose, 24)
        XCTAssertEqual(store.currentInput.roastLevel, .dark)
        XCTAssertEqual(store.currentInput.tasteProfile, .light)
        XCTAssertEqual(store.currentInput.grindSize, .medium)
        XCTAssertEqual(store.selectedTab, .planner)
        XCTAssertEqual(store.activeRecipe?.metadata.name, "Quick Brew")
        XCTAssertEqual(store.activeEntryMode, .quick)
    }
}
