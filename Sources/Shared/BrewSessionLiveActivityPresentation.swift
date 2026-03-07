import Foundation

struct BrewSessionLiveActivityPresentation: Equatable {
    let currentStepTitle: String
    let currentStepCompactText: String
    let nextStepText: String
    let nextAmountLabel: String
    let nextAmountValue: String
    let nextAmountCompactText: String
    let remainingClockText: String
    let statusLabel: String?

    init(
        attributes: BrewSessionActivityAttributes,
        state: BrewSessionActivityAttributes.ContentState
    ) {
        let safeTotalSteps = max(attributes.totalSteps, 0)
        let safeNextStepNumber = max(state.nextStepNumber, 0)
        let safeNextStepGrams = max(state.nextStepGrams, 0)
        let safeRemainingNext = max(state.remainingToNextStep, 0)
        let safeCurrentStepNumber = max(state.stepNumber, 0)

        currentStepTitle = safeCurrentStepNumber > 0 ? "第\(safeCurrentStepNumber)投" : "準備中"
        currentStepCompactText = safeCurrentStepNumber > 0 ? "\(safeCurrentStepNumber)" : "0"

        if safeNextStepNumber > 0 {
            nextStepText = "次は第\(safeNextStepNumber)投"
            nextAmountLabel = "次に注ぐ量"
            nextAmountValue = "\(safeNextStepGrams)g"
            nextAmountCompactText = "次 \(safeNextStepGrams)g"
        } else if safeCurrentStepNumber > 0, safeCurrentStepNumber >= safeTotalSteps, safeTotalSteps > 0 {
            nextStepText = "仕上がり"
            nextAmountLabel = "状態"
            nextAmountValue = "完了"
            nextAmountCompactText = "完了"
        } else {
            nextStepText = "次の注湯"
            nextAmountLabel = "次に注ぐ量"
            nextAmountValue = "\(safeNextStepGrams)g"
            nextAmountCompactText = "次 \(safeNextStepGrams)g"
        }

        remainingClockText = Self.clockText(from: safeRemainingNext)
        statusLabel = state.isRunning ? nil : "停止中"
    }

    private static func clockText(from seconds: Int) -> String {
        let safeSeconds = max(seconds, 0)
        let hours = safeSeconds / 3_600
        let minutes = (safeSeconds % 3_600) / 60
        let remainingSeconds = safeSeconds % 60

        if hours > 0 {
            return "\(hours):" + String(format: "%02d:%02d", minutes, remainingSeconds)
        }

        return "\(minutes):" + String(format: "%02d", remainingSeconds)
    }
}
