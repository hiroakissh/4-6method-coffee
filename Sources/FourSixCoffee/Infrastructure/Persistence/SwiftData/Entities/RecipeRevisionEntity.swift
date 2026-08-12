import Foundation
import SwiftData

@Model
final class RecipeRevisionEntity {
    @Attribute(.unique) var id: UUID
    var recipeID: UUID
    var version: Int
    var payloadJSON: Data
    var createdAt: Date

    init(
        id: UUID,
        recipeID: UUID,
        version: Int,
        payloadJSON: Data,
        createdAt: Date
    ) {
        self.id = id
        self.recipeID = recipeID
        self.version = version
        self.payloadJSON = payloadJSON
        self.createdAt = createdAt
    }
}
