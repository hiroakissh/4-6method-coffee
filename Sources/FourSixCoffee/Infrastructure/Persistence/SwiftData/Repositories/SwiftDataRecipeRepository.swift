import Foundation
import SwiftData

@MainActor
struct SwiftDataRecipeRepository: RecipeRepository {
    enum RepositoryError: LocalizedError {
        case decodeFailed(recipeID: UUID)

        var errorDescription: String? {
            switch self {
            case let .decodeFailed(recipeID):
                return "Failed to decode recipe payload: \(recipeID.uuidString)"
            }
        }
    }

    private let context: ModelContext
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        context: ModelContext,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.context = context
        self.encoder = encoder
        self.decoder = decoder
    }

    func fetchRecipes() throws -> [BrewRecipe] {
        let descriptor = FetchDescriptor<RecipeEntity>(
            sortBy: [SortDescriptor(\RecipeEntity.updatedAt, order: .reverse)]
        )

        return try context.fetch(descriptor).map { entity in
            do {
                return try decoder.decode(BrewRecipe.self, from: entity.payloadJSON)
            } catch {
                throw RepositoryError.decodeFailed(recipeID: entity.id)
            }
        }
    }

    func save(recipe: BrewRecipe) throws {
        let payloadJSON = try encoder.encode(recipe)

        if let existing = try fetchEntity(id: recipe.id) {
            existing.name = recipe.metadata.name
            existing.device = recipe.metadata.device
            existing.schemaVersion = recipe.schemaVersion
            existing.isPreset = recipe.metadata.sourceType == .preset
            existing.sourceSummary = recipe.metadata.sourceSummary
            existing.payloadJSON = payloadJSON
            existing.updatedAt = .now
        } else {
            let now = Date.now
            context.insert(
                RecipeEntity(
                    id: recipe.id,
                    name: recipe.metadata.name,
                    device: recipe.metadata.device,
                    schemaVersion: recipe.schemaVersion,
                    isPreset: recipe.metadata.sourceType == .preset,
                    sourceSummary: recipe.metadata.sourceSummary,
                    payloadJSON: payloadJSON,
                    createdAt: now,
                    updatedAt: now
                )
            )
        }

        try context.save()
    }

    func delete(recipeID: UUID) throws {
        guard let entity = try fetchEntity(id: recipeID) else { return }
        context.delete(entity)
        try context.save()
    }

    private func fetchEntity(id: UUID) throws -> RecipeEntity? {
        var descriptor = FetchDescriptor<RecipeEntity>(
            predicate: #Predicate<RecipeEntity> { entity in
                entity.id == id
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
