import Foundation

@MainActor
protocol BrewLogRepository {
    func fetchBrewLogs() throws -> [BrewLog]
    func save(log: BrewLog) throws
    func delete(logID: UUID) throws
}
