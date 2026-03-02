import Foundation
import SwiftData

@Model
final class BeanEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var shopName: String
    var purchasedAt: Date
    var origin: String
    var process: String
    var roastLevelRawValue: String
    var notes: String
    var roastDate: Date?
    var referenceURL: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        name: String,
        shopName: String,
        purchasedAt: Date,
        origin: String,
        process: String,
        roastLevelRawValue: String,
        notes: String,
        roastDate: Date?,
        referenceURL: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.shopName = shopName
        self.purchasedAt = purchasedAt
        self.origin = origin
        self.process = process
        self.roastLevelRawValue = roastLevelRawValue
        self.notes = notes
        self.roastDate = roastDate
        self.referenceURL = referenceURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
