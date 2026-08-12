import XCTest
@testable import FourSixCoffee

final class RecipeRevisionTests: XCTestCase {
    func testDifferReportsMetadataDefaultsAndTimelineChanges() {
        let firstRecipe = RecipePresetFactory.fourSix()
        var secondRecipe = firstRecipe
        secondRecipe.metadata.name = "Updated 4-6"
        secondRecipe.defaults.totalWaterGrams = 320
        secondRecipe.phases[0].pours[0].amountGrams = 70
        secondRecipe.phases[0].temperature = .fixed(celsius: 93)
        secondRecipe.phases[0].agitation = [.tap]

        let diff = RecipeRevisionDiffer.diff(
            from: RecipeRevision(recipeID: firstRecipe.id, version: 1, recipe: firstRecipe),
            to: RecipeRevision(recipeID: secondRecipe.id, version: 2, recipe: secondRecipe)
        )

        XCTAssertEqual(diff.fromVersion, 1)
        XCTAssertEqual(diff.toVersion, 2)
        XCTAssertEqual(diff.changedFields, ["基本情報", "デフォルト設定", "湯温", "攪拌", "注湯"])
    }

    func testDifferReturnsEmptyForIdenticalRecipes() {
        let recipe = RecipePresetFactory.fourSix()
        let diff = RecipeRevisionDiffer.diff(
            from: RecipeRevision(recipeID: recipe.id, version: 1, recipe: recipe),
            to: RecipeRevision(recipeID: recipe.id, version: 2, recipe: recipe)
        )

        XCTAssertTrue(diff.isEmpty)
        XCTAssertTrue(diff.changedFields.isEmpty)
    }
}

@MainActor
final class RecipeRevisionUseCaseTests: XCTestCase {
    func testRecordSaveCreatesInitialAndChangedRevisionsWithoutDuplicates() throws {
        let repository = InMemoryRecipeRevisionRepository()
        let useCase = RecipeRevisionUseCase(repository: repository)
        let first = RecipePresetFactory.fourSix()
        var second = first
        second.metadata.name = "Changed"

        try useCase.recordSave(recipe: first)
        try useCase.recordSave(recipe: first)
        try useCase.recordSave(recipe: second)
        try useCase.recordSave(recipe: second)

        let revisions = try useCase.fetchRevisions(recipeID: first.id)
        XCTAssertEqual(revisions.map(\.version), [1, 2])
        XCTAssertEqual(revisions[0].recipe.metadata.name, "4-6 Method")
        XCTAssertEqual(revisions[1].recipe.metadata.name, "Changed")
    }

    func testRecordSaveBackfillsLegacyPreviousRecipeAsVersionOne() throws {
        let repository = InMemoryRecipeRevisionRepository()
        let useCase = RecipeRevisionUseCase(repository: repository)
        let previous = RecipePresetFactory.fourSix()
        var current = previous
        current.metadata.name = "Migrated"

        try useCase.recordSave(recipe: current, previousRecipe: previous)

        let revisions = try useCase.fetchRevisions(recipeID: current.id)
        XCTAssertEqual(revisions.map(\.version), [1, 2])
        XCTAssertEqual(revisions[0].recipe.metadata.name, "4-6 Method")
        XCTAssertEqual(revisions[1].recipe.metadata.name, "Migrated")
    }
}
