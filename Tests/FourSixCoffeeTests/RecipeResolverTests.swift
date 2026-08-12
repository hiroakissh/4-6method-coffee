import XCTest
@testable import FourSixCoffee

final class RecipeResolverTests: XCTestCase {
    func testResolverFlattensFourSixRecipeIntoOrderedSessionActions() {
        let recipe = RecipePresetFactory.fourSix()
        let sessionPlan = RecipeResolver.resolve(recipe)

        XCTAssertEqual(sessionPlan.id, recipe.id)
        XCTAssertEqual(sessionPlan.recipeID, recipe.id)
        XCTAssertEqual(sessionPlan.recipeName, "4-6 Method")
        XCTAssertEqual(sessionPlan.actions.count, 6)
        XCTAssertEqual(sessionPlan.actions.map(\.sequenceNumber), [1, 2, 3, 4, 5, 6])
        XCTAssertEqual(sessionPlan.actions.map(\.startSecond), [0, 44, 88, 128, 168, 208])
        XCTAssertEqual(sessionPlan.actions.first?.waitSeconds, 44)
        XCTAssertEqual(sessionPlan.actions.last?.waitSeconds, 20)
        XCTAssertEqual(sessionPlan.estimatedTotalSeconds, 228)
        XCTAssertEqual(sessionPlan.actions.map(\.temperatureCelsius), Array(repeating: 91, count: 6))
    }

    func testResolverPreservesVariablePhasesTemperatureAndAgitation() {
        let recipe = BrewRecipe(
            metadata: RecipeMetadata(
                name: "Research sample",
                device: "v60",
                sourceType: .user
            ),
            defaults: RecipeDefaults(
                coffeeDoseGrams: 20,
                totalWaterGrams: 280,
                grindSize: .coarse,
                ratio: 14
            ),
            phases: [
                BrewPhase(
                    id: "bloom",
                    type: .bloom,
                    pours: [
                        PourAction(
                            id: "bloom-1",
                            startSecond: 0,
                            amountGrams: 50,
                            targetCumulativeGrams: 50,
                            flowRate: .low,
                            position: .center
                        )
                    ],
                    temperature: .fixed(celsius: 94),
                    agitation: [.swirl]
                ),
                BrewPhase(
                    id: "extraction",
                    type: .extraction,
                    pours: [
                        PourAction(
                            id: "main-1",
                            startSecond: 50,
                            amountGrams: 230,
                            targetCumulativeGrams: 280,
                            flowRate: .high,
                            position: .circle
                        )
                    ],
                    temperature: TemperatureProfile(
                        mode: .stepwise,
                        points: [
                            TemperaturePoint(time: 0, celsius: 92),
                            TemperaturePoint(time: 40, celsius: 88)
                        ]
                    ),
                    agitation: [.stir]
                )
            ]
        )

        let sessionPlan = RecipeResolver.resolve(recipe, drawdownSeconds: 30)

        XCTAssertEqual(sessionPlan.actions.map(\.id), ["bloom-1", "main-1"])
        XCTAssertEqual(sessionPlan.actions.map(\.phaseID), ["bloom", "extraction"])
        XCTAssertEqual(sessionPlan.actions.map(\.phaseType), [.bloom, .extraction])
        XCTAssertEqual(sessionPlan.actions.map(\.temperatureCelsius), [94, 88])
        XCTAssertEqual(sessionPlan.actions.map(\.agitation), [[.swirl], [.stir]])
        XCTAssertEqual(sessionPlan.actions.map(\.waitSeconds), [50, 30])
        XCTAssertEqual(sessionPlan.totalWaterGrams, 280)
        XCTAssertEqual(sessionPlan.estimatedTotalSeconds, 80)
    }

    func testResolverReturnsEmptyTimelineForRecipeWithoutPours() {
        let recipe = BrewRecipe(
            metadata: RecipeMetadata(
                name: "Empty",
                device: "v60",
                sourceType: .user
            ),
            defaults: RecipeDefaults(
                coffeeDoseGrams: 20,
                totalWaterGrams: 300,
                grindSize: .medium,
                ratio: 15
            ),
            phases: [
                BrewPhase(
                    id: "immersion",
                    type: .immersion,
                    pours: [],
                    temperature: .fixed(celsius: 90)
                )
            ]
        )

        let sessionPlan = RecipeResolver.resolve(recipe)

        XCTAssertTrue(sessionPlan.actions.isEmpty)
        XCTAssertEqual(sessionPlan.totalWaterGrams, 300)
        XCTAssertNil(sessionPlan.recommendedTemperature)
        XCTAssertEqual(sessionPlan.estimatedTotalSeconds, 0)
    }
}
