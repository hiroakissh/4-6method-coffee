import Foundation
import SwiftData

@MainActor
struct SwiftDataBrewLogRepository: BrewLogRepository {
    enum RepositoryError: LocalizedError {
        case decodeFailed(logID: UUID)

        var errorDescription: String? {
            switch self {
            case let .decodeFailed(logID):
                return "Failed to decode brew log payload: \(logID.uuidString)"
            }
        }
    }

    private let context: ModelContext
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        context: ModelContext,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.context = context
        self.encoder = encoder
        self.decoder = decoder
    }

    func fetchBrewLogs() throws -> [BrewLog] {
        let descriptor = FetchDescriptor<BrewLogEntity>(
            sortBy: [SortDescriptor(\BrewLogEntity.date, order: .reverse)]
        )

        return try context.fetch(descriptor).map { entity in
            do {
                let input = try decoder.decode(BrewInput.self, from: entity.inputData)
                let plan = try decoder.decode(BrewPlan.self, from: entity.planData)
                let ratings = try decoder.decode(TasteRatings.self, from: entity.ratingsData)

                let bean: Bean?
                if let beanID = entity.beanID {
                    bean = Bean(
                        id: beanID,
                        name: entity.beanSnapshotName ?? "Bean",
                        roaster: "",
                        origin: "",
                        process: "",
                        roastLevel: input.roastLevel
                    )
                } else {
                    bean = nil
                }

                return BrewLog(
                    id: entity.id,
                    date: entity.date,
                    bean: bean,
                    input: input,
                    plan: plan,
                    ratings: ratings,
                    memo: entity.memo,
                    actualBrewSeconds: entity.actualBrewSeconds
                )
            } catch {
                throw RepositoryError.decodeFailed(logID: entity.id)
            }
        }
    }

    func save(log: BrewLog) throws {
        let inputData = try encoder.encode(log.input)
        let planData = try encoder.encode(log.plan)
        let ratingsData = try encoder.encode(log.ratings)

        if let existing = try fetchEntity(id: log.id) {
            existing.date = log.date
            existing.beanID = log.bean?.id
            existing.beanSnapshotName = log.bean?.name
            existing.inputData = inputData
            existing.planData = planData
            existing.ratingsData = ratingsData
            existing.memo = log.memo
            existing.actualBrewSeconds = log.actualBrewSeconds
        } else {
            let entity = BrewLogEntity(
                id: log.id,
                date: log.date,
                beanID: log.bean?.id,
                beanSnapshotName: log.bean?.name,
                inputData: inputData,
                planData: planData,
                ratingsData: ratingsData,
                memo: log.memo,
                actualBrewSeconds: log.actualBrewSeconds
            )
            context.insert(entity)
        }

        try context.save()
    }

    func delete(logID: UUID) throws {
        guard let entity = try fetchEntity(id: logID) else { return }
        context.delete(entity)
        try context.save()
    }

    private func fetchEntity(id: UUID) throws -> BrewLogEntity? {
        var descriptor = FetchDescriptor<BrewLogEntity>(
            predicate: #Predicate<BrewLogEntity> { entity in
                entity.id == id
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
