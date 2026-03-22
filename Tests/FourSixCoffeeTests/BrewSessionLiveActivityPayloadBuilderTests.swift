import XCTest
@testable import FourSixCoffee

final class BrewSessionLiveActivityPayloadBuilderTests: XCTestCase {
    func testContentStateDecodeDefaultsMissingNextStepFieldsForBackwardCompatibility() throws {
        let legacyPayload = """
        {
          "stepNumber": 2,
          "stepGrams": 40,
          "cumulativeGrams": 80,
          "remainingToNextStep": 40,
          "remainingTotalSeconds": 130,
          "nextStepDate": null,
          "isRunning": true
        }
        """.data(using: .utf8)!

        let state = try JSONDecoder().decode(
            BrewSessionActivityAttributes.ContentState.self,
            from: legacyPayload
        )

        XCTAssertEqual(state.stepNumber, 2)
        XCTAssertEqual(state.stepGrams, 40)
        XCTAssertEqual(state.cumulativeGrams, 80)
        XCTAssertEqual(state.nextStepNumber, 0)
        XCTAssertEqual(state.nextStepGrams, 0)
        XCTAssertEqual(state.remainingToNextStep, 40)
        XCTAssertEqual(state.remainingTotalSeconds, 130)
        XCTAssertNil(state.nextStepDate)
        XCTAssertTrue(state.isRunning)
    }

    func testMakePayloadForRunningMiddleStepBuildsExpectedState() {
        let plan = makePlan()
        let now = Date(timeIntervalSince1970: 1_000)

        let payload = BrewSessionLiveActivityPayloadBuilder.makePayload(
            plan: plan,
            elapsedSeconds: 50,
            currentStepIndex: 1,
            isRunning: true,
            now: now
        )

        XCTAssertEqual(payload.attributes.totalWaterGrams, 240)
        XCTAssertEqual(payload.attributes.totalSteps, 6)
        XCTAssertEqual(payload.state.stepNumber, 2)
        XCTAssertEqual(payload.state.stepGrams, 40)
        XCTAssertEqual(payload.state.cumulativeGrams, 80)
        XCTAssertEqual(payload.state.nextStepNumber, 3)
        XCTAssertEqual(payload.state.nextStepGrams, 40)
        XCTAssertEqual(payload.state.remainingToNextStep, 40)
        XCTAssertEqual(payload.state.remainingTotalSeconds, 130)
        XCTAssertEqual(payload.state.nextStepDate, now.addingTimeInterval(40))
        XCTAssertEqual(payload.staleDate, now.addingTimeInterval(40))
        XCTAssertTrue(payload.state.isRunning)
    }

    func testMakePayloadForPausedSessionHasNoCountdownDate() {
        let plan = makePlan()
        let now = Date(timeIntervalSince1970: 1_000)

        let payload = BrewSessionLiveActivityPayloadBuilder.makePayload(
            plan: plan,
            elapsedSeconds: 95,
            currentStepIndex: 2,
            isRunning: false,
            now: now
        )

        XCTAssertEqual(payload.state.stepNumber, 3)
        XCTAssertEqual(payload.state.nextStepNumber, 4)
        XCTAssertEqual(payload.state.remainingToNextStep, 40)
        XCTAssertNil(payload.state.nextStepDate)
        XCTAssertNil(payload.staleDate)
        XCTAssertFalse(payload.state.isRunning)
    }

    func testMakePayloadWithEmptyStepsFallsBackToSafeValues() {
        let emptyPlan = BrewPlan(
            input: .default,
            ratio: 15,
            totalWater: 0,
            recommendedTemperature: 92,
            steps: [],
            estimatedTotalSeconds: 0,
            plannerMemo: ""
        )

        let payload = BrewSessionLiveActivityPayloadBuilder.makePayload(
            plan: emptyPlan,
            elapsedSeconds: 200,
            currentStepIndex: 99,
            isRunning: true,
            now: Date(timeIntervalSince1970: 1_000)
        )

        XCTAssertEqual(payload.attributes.totalSteps, 0)
        XCTAssertEqual(payload.state.stepNumber, 0)
        XCTAssertEqual(payload.state.stepGrams, 0)
        XCTAssertEqual(payload.state.cumulativeGrams, 0)
        XCTAssertEqual(payload.state.nextStepNumber, 0)
        XCTAssertEqual(payload.state.nextStepGrams, 0)
        XCTAssertEqual(payload.state.remainingToNextStep, 0)
        XCTAssertEqual(payload.state.remainingTotalSeconds, 0)
    }

    private func makePlan() -> BrewPlan {
        BrewPlan(
            input: .default,
            ratio: 15,
            totalWater: 240,
            recommendedTemperature: 92,
            steps: [
                PourStep(id: 1, amountGrams: 40, cumulativeGrams: 40, startSecond: 0, waitSeconds: 45, phase: .balance),
                PourStep(id: 2, amountGrams: 40, cumulativeGrams: 80, startSecond: 45, waitSeconds: 45, phase: .balance),
                PourStep(id: 3, amountGrams: 40, cumulativeGrams: 120, startSecond: 90, waitSeconds: 45, phase: .strength),
                PourStep(id: 4, amountGrams: 40, cumulativeGrams: 160, startSecond: 135, waitSeconds: 30, phase: .strength),
                PourStep(id: 5, amountGrams: 40, cumulativeGrams: 200, startSecond: 165, waitSeconds: 15, phase: .strength),
                PourStep(id: 6, amountGrams: 40, cumulativeGrams: 240, startSecond: 180, waitSeconds: 0, phase: .strength)
            ],
            estimatedTotalSeconds: 180,
            plannerMemo: ""
        )
    }
}
