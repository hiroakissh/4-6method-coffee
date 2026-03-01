import Foundation

@MainActor
protocol BeanRepository {
    func fetchBeans() throws -> [Bean]
    func save(bean: Bean) throws
    func delete(beanID: UUID) throws
}
