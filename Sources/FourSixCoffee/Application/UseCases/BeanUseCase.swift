import Foundation

@MainActor
struct BeanUseCase {
    private let repository: any BeanRepository

    init(repository: any BeanRepository) {
        self.repository = repository
    }

    func fetchBeans() throws -> [Bean] {
        try repository.fetchBeans()
    }

    func createBean(
        name: String,
        roaster: String,
        origin: String,
        process: String,
        roastLevel: RoastLevel,
        notes: String = "",
        roastDate: Date? = nil
    ) throws -> Bean {
        let bean = Bean(
            name: name,
            roaster: roaster,
            origin: origin,
            process: process,
            roastLevel: roastLevel,
            notes: notes,
            roastDate: roastDate
        )
        try repository.save(bean: bean)
        return bean
    }

    func save(bean: Bean) throws {
        try repository.save(bean: bean)
    }

    func deleteBeans(ids: [UUID]) throws {
        for id in ids {
            try repository.delete(beanID: id)
        }
    }
}
