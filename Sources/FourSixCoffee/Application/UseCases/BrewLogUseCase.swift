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
        recipeID: UUID? = nil,
        recipeName: String? = nil,
        entryMode: BrewEntryMode = .quick,
        input: BrewInput,
        plan: BrewPlan,
        sessionPlan: BrewSessionPlan? = nil,
        ratings: TasteRatings,
        memo: String,
        actualBrewSeconds: Int,
        date: Date = .now
    ) throws -> BrewLog {
        let log = BrewLog(
            date: date,
            bean: bean,
            recipeID: recipeID,
            recipeName: recipeName,
            entryMode: entryMode,
            input: input,
            plan: plan,
            sessionPlan: sessionPlan,
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
