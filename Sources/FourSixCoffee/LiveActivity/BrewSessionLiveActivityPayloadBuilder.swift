import Foundation

struct BrewSessionLiveActivityPayload {
    var attributes: BrewSessionActivityAttributes
    var state: BrewSessionActivityAttributes.ContentState
    var staleDate: Date?
}

enum BrewSessionLiveActivityPayloadBuilder {
    static func makePayload(
        plan: BrewPlan,
        elapsedSeconds: Int,
        currentStepIndex: Int,
        isRunning: Bool,
        now: Date = .now
    ) -> BrewSessionLiveActivityPayload {
        let safeElapsed = max(0, elapsedSeconds)
        let totalRemaining = max(plan.estimatedTotalSeconds - safeElapsed, 0)

        guard !plan.steps.isEmpty else {
            let state = BrewSessionActivityAttributes.ContentState(
                stepNumber: 0,
                stepGrams: 0,
                cumulativeGrams: 0,
                remainingToNextStep: totalRemaining,
                remainingTotalSeconds: totalRemaining,
                nextStepDate: isRunning ? now.addingTimeInterval(TimeInterval(totalRemaining)) : nil,
                isRunning: isRunning
            )
            return BrewSessionLiveActivityPayload(
                attributes: BrewSessionActivityAttributes(
                    totalWaterGrams: plan.totalWater,
                    totalSteps: 0
                ),
                state: state,
                staleDate: state.nextStepDate
            )
        }

        let stepIndex = max(0, min(currentStepIndex, plan.steps.count - 1))
        let step = plan.steps[stepIndex]

        let nextIndex = stepIndex + 1
        let remainingToNext: Int
        if plan.steps.indices.contains(nextIndex) {
            remainingToNext = max(plan.steps[nextIndex].startSecond - safeElapsed, 0)
        } else {
            remainingToNext = totalRemaining
        }

        let nextStepDate = isRunning
            ? now.addingTimeInterval(TimeInterval(remainingToNext))
            : nil

        let state = BrewSessionActivityAttributes.ContentState(
            stepNumber: step.id,
            stepGrams: step.amountGrams,
            cumulativeGrams: step.cumulativeGrams,
            remainingToNextStep: remainingToNext,
            remainingTotalSeconds: totalRemaining,
            nextStepDate: nextStepDate,
            isRunning: isRunning
        )

        return BrewSessionLiveActivityPayload(
            attributes: BrewSessionActivityAttributes(
                totalWaterGrams: plan.totalWater,
                totalSteps: plan.steps.count
            ),
            state: state,
            staleDate: nextStepDate
        )
    }
}
