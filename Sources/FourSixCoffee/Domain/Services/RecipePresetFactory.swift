import Foundation

enum RecipePresetFactory {
    static func fourSix(from input: BrewInput = .default) -> BrewRecipe {
        let plan = BrewPlanner.makePlan(from: input)
        let pours = plan.steps.map { step in
            PourAction(
                id: "pour-\(step.id)",
                startSecond: step.startSecond,
                amountGrams: step.amountGrams,
                targetCumulativeGrams: step.cumulativeGrams,
                flowRate: .medium,
                position: .center
            )
        }

        let balancePours = Array(pours.prefix(2))
        let strengthPours = Array(pours.dropFirst(2))

        return BrewRecipe(
            metadata: RecipeMetadata(
                name: "4-6 Method",
                device: "v60",
                sourceType: .preset,
                sourceSummary: "4-6メソッドの標準プリセット",
                tags: ["4-6", "pulse", "flavor-control"]
            ),
            defaults: RecipeDefaults(
                coffeeDoseGrams: input.coffeeDose,
                totalWaterGrams: plan.totalWater,
                grindSize: input.grindSize,
                ratio: plan.ratio
            ),
            phases: [
                BrewPhase(
                    id: "flavor-control",
                    type: .extraction,
                    pours: balancePours,
                    temperature: .fixed(celsius: plan.recommendedTemperature)
                ),
                BrewPhase(
                    id: "strength-control",
                    type: .extraction,
                    pours: strengthPours,
                    temperature: .fixed(celsius: plan.recommendedTemperature)
                )
            ]
        )
    }
}
