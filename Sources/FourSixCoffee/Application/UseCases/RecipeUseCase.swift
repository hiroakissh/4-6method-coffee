import Foundation

@MainActor
struct RecipeUseCase {
    private let repository: any RecipeRepository

    init(repository: any RecipeRepository) {
        self.repository = repository
    }

    func fetchRecipes() throws -> [BrewRecipe] {
        try repository.fetchRecipes()
    }

    func save(recipe: BrewRecipe) throws {
        try repository.save(recipe: recipe)
    }

    func deleteRecipes(ids: [UUID]) throws {
        for id in ids {
            try repository.delete(recipeID: id)
        }
    }

    func seedFourSixIfNeeded() throws -> [BrewRecipe] {
        let existingRecipes = try repository.fetchRecipes()
        guard existingRecipes.isEmpty else { return existingRecipes }

        try repository.save(recipe: RecipePresetFactory.fourSix())
        return try repository.fetchRecipes()
    }
}
