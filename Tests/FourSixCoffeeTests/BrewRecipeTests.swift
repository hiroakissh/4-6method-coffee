import XCTest
@testable import FourSixCoffee

final class BrewRecipeTests: XCTestCase {
    func testFourSixPresetUsesExistingPlanAsRecipeTimeline() {
        let input = BrewInput(
            coffeeDose: 20,
            brewRatio: 15,
            tasteProfile: .balanced,
            roastLevel: .medium,
            grindSize: .medium
        )

        let plan = BrewPlanner.makePlan(from: input)
        let recipe = RecipePresetFactory.fourSix(from: input)
        let pours = recipe.phases.flatMap(\.pours)

        XCTAssertEqual(recipe.schemaVersion, BrewRecipe.currentSchemaVersion)
        XCTAssertEqual(recipe.metadata.sourceType, .preset)
        XCTAssertEqual(recipe.defaults.totalWaterGrams, plan.totalWater)
        XCTAssertEqual(recipe.defaults.ratio, plan.ratio, accuracy: 0.0001)
        XCTAssertEqual(pours.count, plan.steps.count)
        XCTAssertEqual(pours.map(\.amountGrams), plan.steps.map(\.amountGrams))
        XCTAssertEqual(pours.map(\.startSecond), plan.steps.map(\.startSecond))
        XCTAssertEqual(pours.last?.targetCumulativeGrams, plan.totalWater)
    }

    func testRecipeJSONRoundTripPreservesPhasesAndActions() throws {
        let recipe = RecipePresetFactory.fourSix()

        let data = try JSONEncoder().encode(recipe)
        let decoded = try JSONDecoder().decode(BrewRecipe.self, from: data)

        XCTAssertEqual(decoded, recipe)
        XCTAssertEqual(decoded.phases.count, 2)
        XCTAssertEqual(decoded.phases[0].temperature.mode, .fixed)
        XCTAssertEqual(decoded.phases[0].temperature.points.first?.celsius, 91)
    }

    func testTemperatureProfileCanRepresentStepwiseChanges() throws {
        let profile = TemperatureProfile(
            mode: .stepwise,
            points: [
                TemperaturePoint(time: 0, celsius: 94),
                TemperaturePoint(time: 90, celsius: 90)
            ]
        )

        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(TemperatureProfile.self, from: data)

        XCTAssertEqual(decoded.mode, .stepwise)
        XCTAssertEqual(decoded.points.map(\.time), [0, 90])
        XCTAssertEqual(decoded.points.map(\.celsius), [94, 90])
    }
}
