import XCTest
@testable import FourSixCoffee

@MainActor
final class BeanUseCaseTests: XCTestCase {
    func testCreateBeanPersistsAndReturnsCreatedValue() throws {
        let repository = InMemoryBeanRepository()
        let useCase = BeanUseCase(repository: repository)

        let created = try useCase.createBean(
            name: "Ethiopia",
            roaster: "Roastery",
            origin: "Guji",
            process: "Washed",
            roastLevel: .light
        )

        let beans = try useCase.fetchBeans()
        XCTAssertEqual(beans.count, 1)
        XCTAssertEqual(beans.first?.id, created.id)
        XCTAssertEqual(beans.first?.name, "Ethiopia")
    }

    func testDeleteBeansRemovesAllMatchingIDs() throws {
        let repository = InMemoryBeanRepository()
        let useCase = BeanUseCase(repository: repository)

        let first = try useCase.createBean(
            name: "A",
            roaster: "R",
            origin: "O",
            process: "P",
            roastLevel: .medium
        )
        _ = try useCase.createBean(
            name: "B",
            roaster: "R",
            origin: "O",
            process: "P",
            roastLevel: .dark
        )

        try useCase.deleteBeans(ids: [first.id])

        let beans = try useCase.fetchBeans()
        XCTAssertEqual(beans.count, 1)
        XCTAssertEqual(beans.first?.name, "B")
    }

    func testSaveUpdatesExistingBean() throws {
        let repository = InMemoryBeanRepository()
        let useCase = BeanUseCase(repository: repository)

        var bean = try useCase.createBean(
            name: "Initial",
            roaster: "R",
            origin: "O",
            process: "P",
            roastLevel: .medium
        )
        bean.name = "Updated"
        bean.notes = "Changed"

        try useCase.save(bean: bean)

        let beans = try useCase.fetchBeans()
        XCTAssertEqual(beans.first?.name, "Updated")
        XCTAssertEqual(beans.first?.notes, "Changed")
    }
}
