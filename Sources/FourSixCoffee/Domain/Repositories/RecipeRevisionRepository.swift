import Foundation

@MainActor
protocol RecipeRevisionRepository {
    func fetchRevisions(recipeID: UUID) throws -> [RecipeRevision]
    func save(revision: RecipeRevision) throws
    func deleteRevisions(recipeID: UUID) throws
}
