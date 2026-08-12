import Foundation
import SwiftData

@Model
final class RecipeEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var device: String
    var schemaVersion: Int
    var isPreset: Bool
    var sourceSummary: String
    var payloadJSON: Data
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        name: String,
        device: String,
        schemaVersion: Int,
        isPreset: Bool,
        sourceSummary: String,
        payloadJSON: Data,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.device = device
        self.schemaVersion = schemaVersion
        self.isPreset = isPreset
        self.sourceSummary = sourceSummary
        self.payloadJSON = payloadJSON
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
