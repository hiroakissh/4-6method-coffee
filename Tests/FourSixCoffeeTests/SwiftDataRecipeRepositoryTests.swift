import SwiftData
import XCTest
@testable import FourSixCoffee

@MainActor
final class SwiftDataRecipeRepositoryTests: XCTestCase {
    func testRecipeRepositoryCRUDAndMetadataMapping() throws {
        let container = PersistenceStack.makeModelContainer(inMemory: true)
        let repository = SwiftDataRecipeRepository(context: container.mainContext)
        let recipe = RecipePresetFactory.fourSix()

        try repository.save(recipe: recipe)
        var fetched = try repository.fetchRecipes()

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0], recipe)

        var updated = recipe
        updated.metadata.name = "My 4-6"
        updated.metadata.sourceType = .user
        try repository.save(recipe: updated)
        fetched = try repository.fetchRecipes()

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].metadata.name, "My 4-6")
        XCTAssertEqual(fetched[0].metadata.sourceType, .user)

        try repository.delete(recipeID: recipe.id)
        XCTAssertTrue(try repository.fetchRecipes().isEmpty)
    }

    func testRecipeUseCaseSeedsOnlyWhenRepositoryIsEmpty() throws {
        let container = PersistenceStack.makeModelContainer(inMemory: true)
        let repository = SwiftDataRecipeRepository(context: container.mainContext)
        let useCase = RecipeUseCase(repository: repository)

        let first = try useCase.seedFourSixIfNeeded()
        let second = try useCase.seedFourSixIfNeeded()

        XCTAssertEqual(first.count, 1)
        XCTAssertEqual(second.count, 1)
        XCTAssertEqual(second[0].id, first[0].id)
    }

    func testRecipeRepositoryThrowsWhenPayloadIsCorrupted() throws {
        let container = PersistenceStack.makeModelContainer(inMemory: true)
        let context = container.mainContext
        let recipe = RecipePresetFactory.fourSix()

        context.insert(
            RecipeEntity(
                id: recipe.id,
                name: recipe.metadata.name,
                device: recipe.metadata.device,
                schemaVersion: recipe.schemaVersion,
                isPreset: true,
                sourceSummary: recipe.metadata.sourceSummary,
                payloadJSON: Data("not-json".utf8),
                createdAt: .now,
                updatedAt: .now
            )
        )
        try context.save()

        XCTAssertThrowsError(try SwiftDataRecipeRepository(context: context).fetchRecipes()) { error in
            guard case SwiftDataRecipeRepository.RepositoryError.decodeFailed(recipeID: recipe.id) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }
}
