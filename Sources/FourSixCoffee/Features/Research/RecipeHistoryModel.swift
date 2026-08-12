import Foundation
import Observation

@MainActor
@Observable
final class RecipeHistoryModel {
    let recipeID: UUID
    let recipeName: String
    private(set) var revisions: [RecipeRevision] = []
    var selectedRevisionID: UUID?

    init(recipe: BrewRecipe) {
        self.recipeID = recipe.id
        self.recipeName = recipe.metadata.name
    }

    func load(using store: AppStore) {
        revisions = store.revisions(for: recipeID)
        if selectedRevisionID == nil {
            selectedRevisionID = revisions.last?.id
        }
    }

    var selectedRevision: RecipeRevision? {
        guard let selectedRevisionID else { return revisions.last }
        return revisions.first(where: { $0.id == selectedRevisionID }) ?? revisions.last
    }

    func diff(for revision: RecipeRevision) -> RecipeRevisionDiff? {
        guard let index = revisions.firstIndex(where: { $0.id == revision.id }), index > 0 else {
            return nil
        }
        return RecipeRevisionDiffer.diff(from: revisions[index - 1], to: revision)
    }
}
