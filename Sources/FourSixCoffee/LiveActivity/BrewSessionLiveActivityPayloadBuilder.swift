import Foundation

struct BrewSessionLiveActivityPayload {
    var attributes: BrewSessionActivityAttributes
    var state: BrewSessionActivityAttributes.ContentState
    var staleDate: Date?
}

enum BrewSessionLiveActivityPayloadBuilder {
    static func makePayload(
        plan: BrewSessionPlan,
        elapsedSeconds: Int,
        currentStepIndex: Int,
        isRunning: Bool,
        now: Date = .now
    ) -> BrewSessionLiveActivityPayload {
        let safeElapsed = max(0, elapsedSeconds)
        let totalRemaining = max(plan.estimatedTotalSeconds - safeElapsed, 0)

        guard !plan.actions.isEmpty else {
            let state = BrewSessionActivityAttributes.ContentState(
                stepNumber: 0,
                stepGrams: 0,
                cumulativeGrams: 0,
                nextStepNumber: 0,
                nextStepGrams: 0,
                nextCumulativeGrams: 0,
                remainingToNextStep: totalRemaining,
                remainingTotalSeconds: totalRemaining,
                nextStepDate: isRunning ? now.addingTimeInterval(TimeInterval(totalRemaining)) : nil,
                isRunning: isRunning
            )
            return BrewSessionLiveActivityPayload(
                attributes: BrewSessionActivityAttributes(
                    totalWaterGrams: plan.totalWaterGrams,
                    totalSteps: 0
                ),
                state: state,
                staleDate: state.nextStepDate
            )
        }

        let stepIndex = max(0, min(currentStepIndex, plan.actions.count - 1))
        let step = plan.actions[stepIndex]

        let nextIndex = stepIndex + 1
        let remainingToNext: Int
        let nextStepNumber: Int
        let nextStepGrams: Int
        let nextCumulativeGrams: Int
        if plan.actions.indices.contains(nextIndex) {
            remainingToNext = max(plan.actions[nextIndex].startSecond - safeElapsed, 0)
            nextStepNumber = plan.actions[nextIndex].sequenceNumber
            nextStepGrams = plan.actions[nextIndex].amountGrams
            nextCumulativeGrams = max(plan.actions[nextIndex].targetCumulativeGrams, 0)
        } else {
            remainingToNext = totalRemaining
            nextStepNumber = 0
            nextStepGrams = 0
            nextCumulativeGrams = max(max(step.targetCumulativeGrams, 0), max(plan.totalWaterGrams, 0))
        }

        let nextStepDate = isRunning
            ? now.addingTimeInterval(TimeInterval(remainingToNext))
            : nil

        let state = BrewSessionActivityAttributes.ContentState(
            stepNumber: step.sequenceNumber,
            stepGrams: step.amountGrams,
            cumulativeGrams: step.targetCumulativeGrams,
            nextStepNumber: nextStepNumber,
            nextStepGrams: nextStepGrams,
            nextCumulativeGrams: nextCumulativeGrams,
            remainingToNextStep: remainingToNext,
            remainingTotalSeconds: totalRemaining,
            nextStepDate: nextStepDate,
            isRunning: isRunning
        )

        return BrewSessionLiveActivityPayload(
            attributes: BrewSessionActivityAttributes(
                totalWaterGrams: plan.totalWaterGrams,
                totalSteps: plan.actions.count
            ),
            state: state,
            staleDate: nextStepDate
        )
    }
}
