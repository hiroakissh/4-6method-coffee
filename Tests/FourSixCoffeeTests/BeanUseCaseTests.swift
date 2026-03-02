import XCTest
@testable import FourSixCoffee

@MainActor
final class BeanUseCaseTests: XCTestCase {
    func testCreateBeanPersistsAndReturnsCreatedValue() throws {
        let repository = InMemoryBeanRepository()
        let useCase = BeanUseCase(repository: repository)

        let created = try useCase.createBean(
            name: "Ethiopia",
            shopName: "PHILO COFFEA",
            purchasedAt: .now,
            origin: "Guji",
            process: "Washed",
            roastLevel: .light
        )

        let beans = try useCase.fetchBeans()
        XCTAssertEqual(beans.count, 1)
        XCTAssertEqual(beans.first?.id, created.id)
        XCTAssertEqual(beans.first?.shopName, "PHILO COFFEA")
    }

    func testDeleteBeansRemovesAllMatchingIDs() throws {
        let repository = InMemoryBeanRepository()
        let useCase = BeanUseCase(repository: repository)

        let first = try useCase.createBean(
            name: "A",
            shopName: "S",
            purchasedAt: .now,
            origin: "O",
            process: "P",
            roastLevel: .medium
        )
        _ = try useCase.createBean(
            name: "B",
            shopName: "S",
            purchasedAt: .now,
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
            shopName: "S",
            purchasedAt: .now,
            origin: "O",
            process: "P",
            roastLevel: .medium
        )
        bean.referenceURL = "https://example.com"

        try useCase.save(bean: bean)

        let beans = try useCase.fetchBeans()
        XCTAssertEqual(beans.first?.referenceURL, "https://example.com")
    }

    func testCreateBeanThrowsWhenReferenceURLIsInvalid() {
        let repository = InMemoryBeanRepository()
        let useCase = BeanUseCase(repository: repository)

        XCTAssertThrowsError(
            try useCase.createBean(
                name: "Initial",
                shopName: "S",
                purchasedAt: .now,
                roastLevel: .medium,
                referenceURL: "invalid-url"
            )
        )
    }
}
