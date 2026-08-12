import Foundation

struct RecipeRevision: Codable, Hashable, Identifiable {
    let id: UUID
    let recipeID: UUID
    let version: Int
    let recipe: BrewRecipe
    let createdAt: Date

    init(
        id: UUID = UUID(),
        recipeID: UUID,
        version: Int,
        recipe: BrewRecipe,
        createdAt: Date = .now
    ) {
        self.id = id
        self.recipeID = recipeID
        self.version = version
        self.recipe = recipe
        self.createdAt = createdAt
    }
}

struct RecipeRevisionDiff: Hashable {
    let fromVersion: Int
    let toVersion: Int
    let changes: [RecipeRevisionChange]

    var changedFields: [String] { changes.map(\.field) }
    var isEmpty: Bool { changes.isEmpty }
}

struct RecipeRevisionChange: Hashable, Identifiable {
    let field: String
    let before: String
    let after: String

    var id: String { field }
}
