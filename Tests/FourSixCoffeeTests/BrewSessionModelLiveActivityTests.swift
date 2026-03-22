import XCTest
@testable import FourSixCoffee

@MainActor
final class BrewSessionModelLiveActivityTests: XCTestCase {
    func testStartPauseAndResetTimerEmitLiveActivityEvents() {
        let manager = SpyBrewSessionLiveActivityManager()
        let model = BrewSessionModel(liveActivityManager: manager)
        let plan = makePlan(stepStartOffset: 0)

        model.load(plan: plan)
        model.start()

        XCTAssertEqual(manager.syncCalls.count, 1)
        XCTAssertEqual(manager.syncCalls[0].planID, plan.id)
        XCTAssertEqual(manager.syncCalls[0].elapsedSeconds, 0)
        XCTAssertTrue(manager.syncCalls[0].isRunning)

        model.pause()

        XCTAssertEqual(manager.syncCalls.count, 2)
        XCTAssertFalse(manager.syncCalls[1].isRunning)

        model.resetTimer()

        XCTAssertEqual(manager.endCalls.count, 1)
        XCTAssertEqual(manager.endCalls[0].planID, plan.id)
    }

    func testStartWithoutLoadingPlanDoesNotEmitLiveActivityEvent() {
        let manager = SpyBrewSessionLiveActivityManager()
        let model = BrewSessionModel(liveActivityManager: manager)

        model.start()

        XCTAssertFalse(model.isRunning)
        XCTAssertTrue(manager.syncCalls.isEmpty)
        XCTAssertTrue(manager.endCalls.isEmpty)
    }

    func testLoadingNewPlanEndsPreviousLiveActivity() {
        let manager = SpyBrewSessionLiveActivityManager()
        let model = BrewSessionModel(liveActivityManager: manager)
        let firstPlan = makePlan(stepStartOffset: 0)
        let secondPlan = makePlan(stepStartOffset: 10)

        model.load(plan: firstPlan)
        model.start()

        model.load(plan: secondPlan)

        XCTAssertEqual(manager.endCalls.count, 1)
        XCTAssertEqual(manager.endCalls[0].planID, firstPlan.id)
        XCTAssertEqual(model.loadedPlanID, secondPlan.id)
        XCTAssertFalse(model.isRunning)
    }

    func testSyncElapsedTimeCatchesUpAfterBackground() {
        let manager = SpyBrewSessionLiveActivityManager()
        var now = Date(timeIntervalSince1970: 1_700_000_000)
        let model = BrewSessionModel(
            liveActivityManager: manager,
            now: { now }
        )
        let plan = makePlan(stepStartOffset: 0)

        model.load(plan: plan)
        model.start()

        now = now.addingTimeInterval(46)
        model.syncElapsedTime()

        XCTAssertEqual(model.elapsedSeconds, 46)
        XCTAssertEqual(model.currentStepIndex, 1)
        XCTAssertEqual(manager.syncCalls.last?.elapsedSeconds, 46)
        XCTAssertEqual(manager.syncCalls.last?.currentStepIndex, 1)
    }

    func testSyncElapsedTimeEndsSessionWhenCatchUpReachesTotalSeconds() {
        let manager = SpyBrewSessionLiveActivityManager()
        var now = Date(timeIntervalSince1970: 1_700_000_000)
        let model = BrewSessionModel(
            liveActivityManager: manager,
            now: { now }
        )
        let plan = makePlan(stepStartOffset: 0)

        model.load(plan: plan)
        model.start()

        now = now.addingTimeInterval(TimeInterval(plan.estimatedTotalSeconds))
        model.syncElapsedTime()

        XCTAssertFalse(model.isRunning)
        XCTAssertEqual(model.elapsedSeconds, plan.estimatedTotalSeconds)
        XCTAssertEqual(model.currentStepIndex, plan.steps.count - 1)
        XCTAssertEqual(manager.syncCalls.count, 2)
        XCTAssertFalse(manager.syncCalls.last?.isRunning ?? true)
        XCTAssertEqual(manager.endCalls.count, 1)
        XCTAssertEqual(manager.endCalls[0].elapsedSeconds, plan.estimatedTotalSeconds)
        XCTAssertEqual(manager.endCalls[0].currentStepIndex, plan.steps.count - 1)
    }

    func testNextActionSummaryUsesUpcomingStepCumulativeTarget() {
        let model = BrewSessionModel(liveActivityManager: SpyBrewSessionLiveActivityManager())
        let plan = makePlan(stepStartOffset: 0)

        model.load(plan: plan)

        let summary = model.nextActionSummary(in: plan)

        XCTAssertEqual(summary.currentStep.id, 1)
        XCTAssertEqual(summary.nextStep?.id, 2)
        XCTAssertEqual(summary.remainingSeconds, 45)
        XCTAssertEqual(summary.targetCumulativeGrams, 80)
        XCTAssertEqual(summary.additionalGrams, 40)
        XCTAssertEqual(summary.segmentDurationSeconds, 45)
        XCTAssertEqual(summary.countdownProgress, 1, accuracy: 0.0001)
        XCTAssertFalse(summary.isFinalPhase)
        XCTAssertFalse(summary.isComplete)
    }

    func testNextActionSummaryBuildsCountdownProgressWithinCurrentSegment() {
        let model = BrewSessionModel(liveActivityManager: SpyBrewSessionLiveActivityManager())
        let plan = makePlan(stepStartOffset: 0)

        model.load(plan: plan)
        model.currentStepIndex = 1
        model.elapsedSeconds = 50

        let summary = model.nextActionSummary(in: plan)

        XCTAssertEqual(summary.currentStep.id, 2)
        XCTAssertEqual(summary.nextStep?.id, 3)
        XCTAssertEqual(summary.remainingSeconds, 40)
        XCTAssertEqual(summary.segmentDurationSeconds, 45)
        XCTAssertEqual(summary.countdownProgress, 40.0 / 45.0, accuracy: 0.0001)
    }

    func testNextActionSummaryMarksCompletionAfterFinalPour() {
        let model = BrewSessionModel(liveActivityManager: SpyBrewSessionLiveActivityManager())
        let plan = makePlan(stepStartOffset: 0)

        model.load(plan: plan)
        model.currentStepIndex = plan.steps.count - 1
        model.elapsedSeconds = plan.estimatedTotalSeconds

        let summary = model.nextActionSummary(in: plan)

        XCTAssertEqual(summary.currentStep.id, 6)
        XCTAssertNil(summary.nextStep)
        XCTAssertEqual(summary.remainingSeconds, 0)
        XCTAssertEqual(summary.targetCumulativeGrams, 240)
        XCTAssertEqual(summary.additionalGrams, 0)
        XCTAssertEqual(summary.segmentDurationSeconds, 0)
        XCTAssertEqual(summary.countdownProgress, 0, accuracy: 0.0001)
        XCTAssertTrue(summary.isFinalPhase)
        XCTAssertTrue(summary.isComplete)
    }

    private func makePlan(stepStartOffset: Int) -> BrewPlan {
        BrewPlan(
            input: .default,
            ratio: 15,
            totalWater: 240,
            recommendedTemperature: 92,
            steps: [
                PourStep(id: 1, amountGrams: 40, cumulativeGrams: 40, startSecond: stepStartOffset + 0, waitSeconds: 45, phase: .balance),
                PourStep(id: 2, amountGrams: 40, cumulativeGrams: 80, startSecond: stepStartOffset + 45, waitSeconds: 45, phase: .balance),
                PourStep(id: 3, amountGrams: 40, cumulativeGrams: 120, startSecond: stepStartOffset + 90, waitSeconds: 45, phase: .strength),
                PourStep(id: 4, amountGrams: 40, cumulativeGrams: 160, startSecond: stepStartOffset + 135, waitSeconds: 30, phase: .strength),
                PourStep(id: 5, amountGrams: 40, cumulativeGrams: 200, startSecond: stepStartOffset + 165, waitSeconds: 15, phase: .strength),
                PourStep(id: 6, amountGrams: 40, cumulativeGrams: 240, startSecond: stepStartOffset + 180, waitSeconds: 0, phase: .strength)
            ],
            estimatedTotalSeconds: 180,
            plannerMemo: ""
        )
    }
}

@MainActor
private final class SpyBrewSessionLiveActivityManager: BrewSessionLiveActivityManaging {
    struct Call: Equatable {
        let planID: UUID
        let elapsedSeconds: Int
        let currentStepIndex: Int
        let isRunning: Bool
    }

    private(set) var syncCalls: [Call] = []
    private(set) var endCalls: [Call] = []

    func sync(
        plan: BrewPlan,
        elapsedSeconds: Int,
        currentStepIndex: Int,
        isRunning: Bool
    ) {
        syncCalls.append(
            Call(
                planID: plan.id,
                elapsedSeconds: elapsedSeconds,
                currentStepIndex: currentStepIndex,
                isRunning: isRunning
            )
        )
    }

    func end(
        plan: BrewPlan,
        elapsedSeconds: Int,
        currentStepIndex: Int
    ) {
        endCalls.append(
            Call(
                planID: plan.id,
                elapsedSeconds: elapsedSeconds,
                currentStepIndex: currentStepIndex,
                isRunning: false
            )
        )
    }
}
