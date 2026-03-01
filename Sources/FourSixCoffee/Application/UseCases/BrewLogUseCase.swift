import Foundation

@MainActor
struct BrewLogUseCase {
    private let repository: any BrewLogRepository

    init(repository: any BrewLogRepository) {
        self.repository = repository
    }

    func fetchBrewLogs() throws -> [BrewLog] {
        try repository.fetchBrewLogs()
    }

    func createLog(
        bean: Bean?,
        input: BrewInput,
        plan: BrewPlan,
        ratings: TasteRatings,
        memo: String,
        actualBrewSeconds: Int,
        date: Date = .now
    ) throws -> BrewLog {
        let log = BrewLog(
            date: date,
            bean: bean,
            input: input,
            plan: plan,
            ratings: ratings,
            memo: memo.trimmingCharacters(in: .whitespacesAndNewlines),
            actualBrewSeconds: max(actualBrewSeconds, 0)
        )
        try repository.save(log: log)
        return log
    }

    func save(log: BrewLog) throws {
        try repository.save(log: log)
    }

    func deleteLogs(ids: [UUID]) throws {
        for id in ids {
            try repository.delete(logID: id)
        }
    }
}
