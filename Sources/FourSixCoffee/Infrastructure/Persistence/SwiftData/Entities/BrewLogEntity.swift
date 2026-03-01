import Foundation
import SwiftData

@Model
final class BrewLogEntity {
    @Attribute(.unique) var id: UUID
    var date: Date
    var beanID: UUID?
    var beanSnapshotName: String?
    var inputData: Data
    var planData: Data
    var ratingsData: Data
    var memo: String
    var actualBrewSeconds: Int

    init(
        id: UUID,
        date: Date,
        beanID: UUID?,
        beanSnapshotName: String?,
        inputData: Data,
        planData: Data,
        ratingsData: Data,
        memo: String,
        actualBrewSeconds: Int
    ) {
        self.id = id
        self.date = date
        self.beanID = beanID
        self.beanSnapshotName = beanSnapshotName
        self.inputData = inputData
        self.planData = planData
        self.ratingsData = ratingsData
        self.memo = memo
        self.actualBrewSeconds = actualBrewSeconds
    }
}
