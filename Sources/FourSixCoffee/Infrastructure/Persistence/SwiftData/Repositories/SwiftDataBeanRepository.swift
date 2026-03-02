import Foundation
import SwiftData

@MainActor
struct SwiftDataBeanRepository: BeanRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchBeans() throws -> [Bean] {
        let descriptor = FetchDescriptor<BeanEntity>(
            sortBy: [SortDescriptor(\BeanEntity.updatedAt, order: .reverse)]
        )
        let entities = try context.fetch(descriptor)
        return entities.map { entity in
            Bean(
                id: entity.id,
                name: entity.name,
                shopName: entity.shopName,
                purchasedAt: entity.purchasedAt,
                origin: entity.origin,
                process: entity.process,
                roastLevel: RoastLevel(rawValue: entity.roastLevelRawValue) ?? .medium,
                notes: entity.notes,
                roastDate: entity.roastDate,
                referenceURL: entity.referenceURL
            )
        }
    }

    func save(bean: Bean) throws {
        if let existing = try fetchEntity(id: bean.id) {
            existing.name = bean.name
            existing.shopName = bean.shopName
            existing.purchasedAt = bean.purchasedAt
            existing.origin = bean.origin
            existing.process = bean.process
            existing.roastLevelRawValue = bean.roastLevel.rawValue
            existing.notes = bean.notes
            existing.roastDate = bean.roastDate
            existing.referenceURL = bean.referenceURL
            existing.updatedAt = .now
        } else {
            let now = Date.now
            let entity = BeanEntity(
                id: bean.id,
                name: bean.name,
                shopName: bean.shopName,
                purchasedAt: bean.purchasedAt,
                origin: bean.origin,
                process: bean.process,
                roastLevelRawValue: bean.roastLevel.rawValue,
                notes: bean.notes,
                roastDate: bean.roastDate,
                referenceURL: bean.referenceURL,
                createdAt: now,
                updatedAt: now
            )
            context.insert(entity)
        }

        try context.save()
    }

    func delete(beanID: UUID) throws {
        guard let entity = try fetchEntity(id: beanID) else { return }
        context.delete(entity)
        try context.save()
    }

    private func fetchEntity(id: UUID) throws -> BeanEntity? {
        var descriptor = FetchDescriptor<BeanEntity>(
            predicate: #Predicate<BeanEntity> { entity in
                entity.id == id
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
