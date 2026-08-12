import Foundation

enum RecipeResolver {
    static let defaultDrawdownSeconds = 20

    static func resolve(
        _ recipe: BrewRecipe,
        drawdownSeconds: Int = defaultDrawdownSeconds
    ) -> BrewSessionPlan {
        struct UnresolvedAction {
            let phaseIndex: Int
            let pourIndex: Int
            let phase: BrewPhase
            let pour: PourAction
        }

        let unresolvedActions = recipe.phases.enumerated().flatMap { phaseIndex, phase in
            phase.pours.enumerated().map { pourIndex, pour in
                UnresolvedAction(
                    phaseIndex: phaseIndex,
                    pourIndex: pourIndex,
                    phase: phase,
                    pour: pour
                )
            }
        }
        .sorted {
            if $0.pour.startSecond != $1.pour.startSecond {
                return $0.pour.startSecond < $1.pour.startSecond
            }
            if $0.phaseIndex != $1.phaseIndex {
                return $0.phaseIndex < $1.phaseIndex
            }
            return $0.pourIndex < $1.pourIndex
        }

        let actions = unresolvedActions.enumerated().map { index, unresolved in
            let currentStart = max(unresolved.pour.startSecond, 0)
            let nextStart = unresolvedActions.indices.contains(index + 1)
                ? max(unresolvedActions[index + 1].pour.startSecond, currentStart)
                : currentStart + max(drawdownSeconds, 0)

            return BrewSessionAction(
                id: unresolved.pour.id,
                sequenceNumber: index + 1,
                phaseID: unresolved.phase.id,
                phaseType: unresolved.phase.type,
                startSecond: currentStart,
                amountGrams: max(unresolved.pour.amountGrams, 0),
                targetCumulativeGrams: max(unresolved.pour.targetCumulativeGrams, 0),
                waitSeconds: max(nextStart - currentStart, 0),
                temperatureCelsius: temperature(at: currentStart, in: unresolved.phase.temperature),
                agitation: unresolved.phase.agitation
            )
        }

        return BrewSessionPlan(
            id: recipe.id,
            recipeID: recipe.id,
            recipeName: recipe.metadata.name,
            totalWaterGrams: max(recipe.defaults.totalWaterGrams, actions.map(\.targetCumulativeGrams).max() ?? 0),
            recommendedTemperature: actions.first?.temperatureCelsius,
            actions: actions,
            estimatedTotalSeconds: actions.last.map { $0.startSecond + $0.waitSeconds } ?? 0
        )
    }

    private static func temperature(at time: Int, in profile: TemperatureProfile) -> Int? {
        profile.points
            .filter { $0.time <= time }
            .max(by: { $0.time < $1.time })?
            .celsius ?? profile.points.first?.celsius
    }
}
