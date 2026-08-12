import Foundation

@MainActor
struct RecipeRevisionUseCase {
    private let repository: any RecipeRevisionRepository

    init(repository: any RecipeRevisionRepository) {
        self.repository = repository
    }

    func fetchRevisions(recipeID: UUID) throws -> [RecipeRevision] {
        try repository.fetchRevisions(recipeID: recipeID)
    }

    func recordSave(recipe: BrewRecipe, previousRecipe: BrewRecipe? = nil) throws {
        var revisions = try repository.fetchRevisions(recipeID: recipe.id)
        revisions.sort { $0.version < $1.version }

        if revisions.isEmpty {
            if let previousRecipe, previousRecipe != recipe {
                try repository.save(
                    revision: RecipeRevision(
                        recipeID: recipe.id,
                        version: 1,
                        recipe: previousRecipe
                    )
                )
                try repository.save(
                    revision: RecipeRevision(
                        recipeID: recipe.id,
                        version: 2,
                        recipe: recipe
                    )
                )
            } else {
                try repository.save(
                    revision: RecipeRevision(
                        recipeID: recipe.id,
                        version: 1,
                        recipe: recipe
                    )
                )
            }
            return
        }

        guard revisions.last?.recipe != recipe else { return }

        try repository.save(
            revision: RecipeRevision(
                recipeID: recipe.id,
                version: (revisions.last?.version ?? 0) + 1,
                recipe: recipe
            )
        )
    }

    func ensureInitialRevisions(for recipes: [BrewRecipe]) throws {
        for recipe in recipes {
            let revisions = try repository.fetchRevisions(recipeID: recipe.id)
            guard revisions.isEmpty else { continue }
            try repository.save(
                revision: RecipeRevision(
                    recipeID: recipe.id,
                    version: 1,
                    recipe: recipe
                )
            )
        }
    }

    func deleteRevisions(recipeID: UUID) throws {
        try repository.deleteRevisions(recipeID: recipeID)
    }
}
