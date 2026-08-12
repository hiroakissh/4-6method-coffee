import Foundation

@MainActor
protocol RecipeRepository {
    func fetchRecipes() throws -> [BrewRecipe]
    func save(recipe: BrewRecipe) throws
    func delete(recipeID: UUID) throws
}
