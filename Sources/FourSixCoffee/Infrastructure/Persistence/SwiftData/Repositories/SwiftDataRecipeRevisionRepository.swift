import Foundation
import SwiftData

@MainActor
struct SwiftDataRecipeRevisionRepository: RecipeRevisionRepository {
    enum RepositoryError: LocalizedError {
        case decodeFailed(revisionID: UUID)

        var errorDescription: String? {
            switch self {
            case let .decodeFailed(revisionID):
                return "Failed to decode recipe revision payload: \(revisionID.uuidString)"
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

    func fetchRevisions(recipeID: UUID) throws -> [RecipeRevision] {
        let descriptor = FetchDescriptor<RecipeRevisionEntity>(
            predicate: #Predicate<RecipeRevisionEntity> { entity in
                entity.recipeID == recipeID
            },
            sortBy: [SortDescriptor(\RecipeRevisionEntity.version, order: .forward)]
        )

        return try context.fetch(descriptor).map { entity in
            do {
                let recipe = try decoder.decode(BrewRecipe.self, from: entity.payloadJSON)
                return RecipeRevision(
                    id: entity.id,
                    recipeID: entity.recipeID,
                    version: entity.version,
                    recipe: recipe,
                    createdAt: entity.createdAt
                )
            } catch {
                throw RepositoryError.decodeFailed(revisionID: entity.id)
            }
        }
    }

    func save(revision: RecipeRevision) throws {
        let payloadJSON = try encoder.encode(revision.recipe)

        if let existing = try fetchEntity(id: revision.id) {
            existing.recipeID = revision.recipeID
            existing.version = revision.version
            existing.payloadJSON = payloadJSON
            existing.createdAt = revision.createdAt
        } else {
            context.insert(
                RecipeRevisionEntity(
                    id: revision.id,
                    recipeID: revision.recipeID,
                    version: revision.version,
                    payloadJSON: payloadJSON,
                    createdAt: revision.createdAt
                )
            )
        }

        try context.save()
    }

    func deleteRevisions(recipeID: UUID) throws {
        let revisions = try fetchEntities(recipeID: recipeID)
        revisions.forEach(context.delete)
        try context.save()
    }

    private func fetchEntities(recipeID: UUID) throws -> [RecipeRevisionEntity] {
        let descriptor = FetchDescriptor<RecipeRevisionEntity>(
            predicate: #Predicate<RecipeRevisionEntity> { entity in
                entity.recipeID == recipeID
            }
        )
        return try context.fetch(descriptor)
    }

    private func fetchEntity(id: UUID) throws -> RecipeRevisionEntity? {
        var descriptor = FetchDescriptor<RecipeRevisionEntity>(
            predicate: #Predicate<RecipeRevisionEntity> { entity in
                entity.id == id
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
