import SwiftData
import XCTest
@testable import FourSixCoffee

@MainActor
final class SwiftDataRepositoriesTests: XCTestCase {
    func testBeanRepositoryCRUD() throws {
        let container = PersistenceStack.makeModelContainer(inMemory: true)
        let repository = SwiftDataBeanRepository(context: container.mainContext)

        let bean = Bean(
            name: "Kenya",
            roaster: "Roaster",
            origin: "Kenya",
            process: "Washed",
            roastLevel: .light,
            notes: "floral"
        )

        try repository.save(bean: bean)

        var fetched = try repository.fetchBeans()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].name, "Kenya")

        var updated = fetched[0]
        updated.name = "Kenya AA"
        updated.roastLevel = .medium
        try repository.save(bean: updated)

        fetched = try repository.fetchBeans()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].name, "Kenya AA")
        XCTAssertEqual(fetched[0].roastLevel, .medium)

        try repository.delete(beanID: updated.id)
        fetched = try repository.fetchBeans()
        XCTAssertTrue(fetched.isEmpty)
    }

    func testBrewLogRepositoryCRUD() throws {
        let container = PersistenceStack.makeModelContainer(inMemory: true)
        let repository = SwiftDataBrewLogRepository(context: container.mainContext)

        let bean = Bean(
            name: "Ethiopia",
            roaster: "R",
            origin: "Guji",
            process: "Natural",
            roastLevel: .light
        )

        let input = BrewInput.default
        let plan = BrewPlanner.makePlan(from: input)
        let log = BrewLog(
            bean: bean,
            input: input,
            plan: plan,
            ratings: TasteRatings(
                sweetness: 4,
                acidity: 3,
                bitterness: 2,
                body: 3,
                aftertaste: 4
            ),
            memo: "test",
            actualBrewSeconds: 210
        )

        try repository.save(log: log)

        var fetched = try repository.fetchBrewLogs()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].memo, "test")
        XCTAssertEqual(fetched[0].bean?.id, bean.id)
        XCTAssertEqual(fetched[0].plan.totalWater, plan.totalWater)

        try repository.delete(logID: log.id)
        fetched = try repository.fetchBrewLogs()
        XCTAssertTrue(fetched.isEmpty)
    }

    func testBrewLogRepositoryThrowsOnCorruptedPayload() throws {
        let container = PersistenceStack.makeModelContainer(inMemory: true)
        let context = container.mainContext

        let entity = BrewLogEntity(
            id: UUID(),
            date: .now,
            beanID: nil,
            beanSnapshotName: nil,
            inputData: Data(),
            planData: Data(),
            ratingsData: Data(),
            memo: "broken",
            actualBrewSeconds: 100
        )
        context.insert(entity)
        try context.save()

        let repository = SwiftDataBrewLogRepository(context: context)

        XCTAssertThrowsError(try repository.fetchBrewLogs())
    }
}
