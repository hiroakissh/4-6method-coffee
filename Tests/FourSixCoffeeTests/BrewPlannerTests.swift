import XCTest
@testable import FourSixCoffee

final class BrewPlannerTests: XCTestCase {
    func testMakePlanHasSixStepsAndTotalWaterMatchesSum() {
        let input = BrewInput(
            coffeeDose: 20,
            brewRatio: 15,
            tasteProfile: .balanced,
            roastLevel: .medium,
            grindSize: .medium
        )

        let plan = BrewPlanner.makePlan(from: input)

        XCTAssertEqual(plan.steps.count, 6)
        XCTAssertEqual(plan.steps.map(\.amountGrams).reduce(0, +), plan.totalWater)
        XCTAssertGreaterThan(plan.estimatedTotalSeconds, 0)
    }

    func testMakePlanUsesSelectedRatioForTotalWater() {
        let lowRatioInput = BrewInput(
            coffeeDose: 20,
            brewRatio: 10,
            tasteProfile: .balanced,
            roastLevel: .medium,
            grindSize: .medium
        )
        let highRatioInput = BrewInput(
            coffeeDose: 20,
            brewRatio: 20,
            tasteProfile: .balanced,
            roastLevel: .medium,
            grindSize: .medium
        )

        let lowRatioPlan = BrewPlanner.makePlan(from: lowRatioInput)
        let highRatioPlan = BrewPlanner.makePlan(from: highRatioInput)

        XCTAssertEqual(lowRatioPlan.ratio, 10, accuracy: 0.0001)
        XCTAssertEqual(lowRatioPlan.totalWater, 200)
        XCTAssertEqual(highRatioPlan.ratio, 20, accuracy: 0.0001)
        XCTAssertEqual(highRatioPlan.totalWater, 400)
    }

    func testRecommendedTemperatureRespectsRoastAndGrindBounds() {
        let highInput = BrewInput(
            coffeeDose: 20,
            brewRatio: 15,
            tasteProfile: .light,
            roastLevel: .light,
            grindSize: .coarse
        )
        let lowInput = BrewInput(
            coffeeDose: 20,
            brewRatio: 15,
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
