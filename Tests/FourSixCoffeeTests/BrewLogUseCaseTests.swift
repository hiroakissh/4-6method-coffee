import XCTest
@testable import FourSixCoffee

@MainActor
final class BrewLogUseCaseTests: XCTestCase {
    func testCreateLogTrimsMemoAndClampsElapsedSeconds() throws {
        let repository = InMemoryBrewLogRepository()
        let useCase = BrewLogUseCase(repository: repository)
        let input = BrewInput.default
        let plan = BrewPlanner.makePlan(from: input)

        let log = try useCase.createLog(
            bean: nil,
            input: input,
            plan: plan,
            ratings: .neutral,
            memo: "  note  ",
            actualBrewSeconds: -10
        )

        XCTAssertEqual(log.memo, "note")
        XCTAssertEqual(log.actualBrewSeconds, 0)

        let stored = try useCase.fetchBrewLogs()
        XCTAssertEqual(stored.count, 1)
        XCTAssertEqual(stored.first?.id, log.id)
    }

    func testDeleteLogsRemovesOnlyRequestedIDs() throws {
        let repository = InMemoryBrewLogRepository()
        let useCase = BrewLogUseCase(repository: repository)
        let input = BrewInput.default
        let plan = BrewPlanner.makePlan(from: input)

        let first = try useCase.createLog(
            bean: nil,
            input: input,
            plan: plan,
            ratings: .neutral,
            memo: "first",
            actualBrewSeconds: 100,
            date: .now
        )

        _ = try useCase.createLog(
            bean: nil,
            input: input,
            plan: plan,
            ratings: .neutral,
            memo: "second",
            actualBrewSeconds: 120,
            date: .now.addingTimeInterval(-100)
        )

        try useCase.deleteLogs(ids: [first.id])

        let logs = try useCase.fetchBrewLogs()
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.memo, "second")
    }
}
