import Foundation
import SwiftData

@Model
final class BeanEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var roaster: String
    var origin: String
    var process: String
    var roastLevelRawValue: String
    var notes: String
    var roastDate: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        name: String,
        roaster: String,
        origin: String,
        process: String,
        roastLevelRawValue: String,
        notes: String,
        roastDate: Date?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.roaster = roaster
        self.origin = origin
        self.process = process
        self.roastLevelRawValue = roastLevelRawValue
        self.notes = notes
        self.roastDate = roastDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
