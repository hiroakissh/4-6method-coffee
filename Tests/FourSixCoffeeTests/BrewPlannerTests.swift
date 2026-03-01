import XCTest
@testable import FourSixCoffee

final class BrewPlannerTests: XCTestCase {
    func testMakePlanHasSixStepsAndTotalWaterMatchesSum() {
        let input = BrewInput(
            coffeeDose: 20,
            tasteProfile: .balanced,
            roastLevel: .medium,
            grindSize: .medium
        )

        let plan = BrewPlanner.makePlan(from: input)

        XCTAssertEqual(plan.steps.count, 6)
        XCTAssertEqual(plan.steps.map(\.amountGrams).reduce(0, +), plan.totalWater)
        XCTAssertGreaterThan(plan.estimatedTotalSeconds, 0)
    }

    func testRecommendedRatioMovesByTasteRoastAndGrind() {
        let sweetInput = BrewInput(
            coffeeDose: 20,
            tasteProfile: .sweet,
            roastLevel: .dark,
            grindSize: .fine
        )
        let lightInput = BrewInput(
            coffeeDose: 20,
            tasteProfile: .light,
            roastLevel: .light,
            grindSize: .coarse
        )

        let sweetRatio = BrewPlanner.recommendedRatio(for: sweetInput)
        let lightRatio = BrewPlanner.recommendedRatio(for: lightInput)

        XCTAssertLessThan(sweetRatio, lightRatio)
        XCTAssertGreaterThanOrEqual(sweetRatio, 13.5)
        XCTAssertLessThanOrEqual(lightRatio, 17.5)
    }

    func testRecommendedTemperatureRespectsRoastAndGrindBounds() {
        let highInput = BrewInput(
            coffeeDose: 20,
            tasteProfile: .light,
            roastLevel: .light,
            grindSize: .coarse
        )
        let lowInput = BrewInput(
            coffeeDose: 20,
            tasteProfile: .sweet,
            roastLevel: .dark,
            grindSize: .fine
        )

        let high = BrewPlanner.recommendedTemperature(for: highInput)
        let low = BrewPlanner.recommendedTemperature(for: lowInput)

        XCTAssertGreaterThanOrEqual(high, low)
        XCTAssertLessThanOrEqual(high, 96)
        XCTAssertGreaterThanOrEqual(low, 86)
    }

    func testStepStartSecondsAreMonotonic() {
        let plan = BrewPlanner.makePlan(from: .default)
        let starts = plan.steps.map(\.startSecond)

        XCTAssertEqual(starts.first, 0)
        XCTAssertEqual(starts, starts.sorted())
    }
}
