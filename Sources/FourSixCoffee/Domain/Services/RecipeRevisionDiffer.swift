import Foundation

enum RecipeRevisionDiffer {
    static func diff(from: RecipeRevision, to: RecipeRevision) -> RecipeRevisionDiff {
        var changes: [RecipeRevisionChange] = []
        let before = from.recipe
        let after = to.recipe

        if before.metadata != after.metadata {
            changes.append(
                RecipeRevisionChange(
                    field: "基本情報",
                    before: metadataSummary(before),
                    after: metadataSummary(after)
                )
            )
        }
        if before.defaults != after.defaults {
            changes.append(
                RecipeRevisionChange(
                    field: "デフォルト設定",
                    before: defaultsSummary(before),
                    after: defaultsSummary(after)
                )
            )
        }
        if before.phases.map(\.id) != after.phases.map(\.id) {
            changes.append(
                RecipeRevisionChange(
                    field: "フェーズ構成",
                    before: phaseStructureSummary(before),
                    after: phaseStructureSummary(after)
                )
            )
        } else {
            if before.phases.map(\.type) != after.phases.map(\.type) {
                changes.append(
                    RecipeRevisionChange(
                        field: "フェーズ種別",
                        before: phaseTypeSummary(before),
                        after: phaseTypeSummary(after)
                    )
                )
            }
            if before.phases.map(\.temperature) != after.phases.map(\.temperature) {
                changes.append(
                    RecipeRevisionChange(
                        field: "湯温",
                        before: temperatureSummary(before),
                        after: temperatureSummary(after)
                    )
                )
            }
            if before.phases.map(\.agitation) != after.phases.map(\.agitation) {
                changes.append(
                    RecipeRevisionChange(
                        field: "攪拌",
                        before: agitationSummary(before),
                        after: agitationSummary(after)
                    )
                )
            }
            if before.phases.flatMap(\.pours) != after.phases.flatMap(\.pours) {
                changes.append(
                    RecipeRevisionChange(
                        field: "注湯",
                        before: pourSummary(before),
                        after: pourSummary(after)
                    )
                )
            }
        }

        return RecipeRevisionDiff(
            fromVersion: from.version,
            toVersion: to.version,
            changes: changes
        )
    }

    private static func metadataSummary(_ recipe: BrewRecipe) -> String {
        "\(recipe.metadata.name) / \(recipe.metadata.device) / \(recipe.metadata.tags.joined(separator: ", "))"
    }

    private static func defaultsSummary(_ recipe: BrewRecipe) -> String {
        String(
            format: "%.1fg / %dg / %@ / %.1f",
            recipe.defaults.coffeeDoseGrams,
            recipe.defaults.totalWaterGrams,
            grindSizeLabel(recipe.defaults.grindSize),
            recipe.defaults.ratio
        )
    }

    private static func phaseStructureSummary(_ recipe: BrewRecipe) -> String {
        recipe.phases.map { "\($0.id)(\($0.pours.count))" }.joined(separator: " → ")
    }

    private static func phaseTypeSummary(_ recipe: BrewRecipe) -> String {
        recipe.phases.map(\.type.displayName).joined(separator: " / ")
    }

    private static func temperatureSummary(_ recipe: BrewRecipe) -> String {
        recipe.phases.map { phase in
            "\(phase.id):\(phase.temperature.points.first?.celsius ?? 0)℃"
        }.joined(separator: " / ")
    }

    private static func agitationSummary(_ recipe: BrewRecipe) -> String {
        recipe.phases.map { phase in
            "\(phase.id):\(phase.agitation.map(agitationLabel).joined(separator: ","))"
        }.joined(separator: " / ")
    }

    private static func pourSummary(_ recipe: BrewRecipe) -> String {
        recipe.phases.flatMap(\.pours).map { pour in
            "\(pour.id):\(pour.startSecond)s/\(pour.amountGrams)g→\(pour.targetCumulativeGrams)g"
        }.joined(separator: " / ")
    }

    private static func grindSizeLabel(_ grindSize: GrindSize) -> String {
        switch grindSize {
        case .coarse:
            return "粗挽き"
        case .medium:
            return "中挽き"
        case .fine:
            return "細挽き"
        }
    }

    private static func agitationLabel(_ agitation: AgitationAction) -> String {
        switch agitation {
        case .none:
            return "なし"
        case .swirl:
            return "スワール"
        case .stir:
            return "撹拌"
        case .tap:
            return "タップ"
        }
    }
}
