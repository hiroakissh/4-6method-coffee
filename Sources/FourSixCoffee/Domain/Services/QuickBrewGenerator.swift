import Foundation

enum QuickBrewGenerator {
    static func generate(from request: QuickBrewRequest = .default) -> BrewRecipe {
        var recipe = RecipePresetFactory.fourSix(from: request.brewInput)
        recipe.metadata.name = "Quick Brew"
        recipe.metadata.sourceSummary = "豆量・焙煎度・味方向から生成した4-6提案"
        recipe.metadata.tags = ["quick-brew", request.roastLevel.rawValue, request.tasteProfile.rawValue]
        return recipe
    }
}
