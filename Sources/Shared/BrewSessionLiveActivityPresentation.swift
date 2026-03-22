import Foundation

struct BrewSessionLiveActivityPresentation: Equatable {
    let currentStepTitle: String
    let currentStepCompactText: String
    let compactLeadingText: String
    let nextStepText: String
    let targetCumulativeLabel: String
    let targetCumulativeValue: String
    let targetCumulativeCompactText: String
    let additionalAmountLabel: String
    let additionalAmountValue: String
    let remainingClockText: String
    let minimalText: String
    let statusLabel: String?

    init(
        attributes: BrewSessionActivityAttributes,
        state: BrewSessionActivityAttributes.ContentState
    ) {
        let safeTotalSteps = max(attributes.totalSteps, 0)
        let safeTotalWater = max(attributes.totalWaterGrams, 0)
        let safeNextStepNumber = max(state.nextStepNumber, 0)
        let safeNextStepGrams = max(state.nextStepGrams, 0)
        let safeCurrentCumulative = max(state.cumulativeGrams, 0)
        let safeNextCumulative = max(state.nextCumulativeGrams, 0)
        let safeRemainingNext = max(state.remainingToNextStep, 0)
        let safeCurrentStepNumber = max(state.stepNumber, 0)

        currentStepTitle = safeCurrentStepNumber > 0 ? "第\(safeCurrentStepNumber)投" : "準備中"
        currentStepCompactText = safeCurrentStepNumber > 0 ? "\(safeCurrentStepNumber)" : "0"

        if safeNextStepNumber > 0 {
            nextStepText = "次は第\(safeNextStepNumber)投"
            targetCumulativeLabel = "次の累計"
            targetCumulativeValue = "\(safeNextCumulative)g"
            targetCumulativeCompactText = "\(safeNextCumulative)g"
            additionalAmountLabel = "今回足す量"
            additionalAmountValue = "+\(safeNextStepGrams)g"
        } else if safeCurrentStepNumber > 0, safeCurrentStepNumber >= safeTotalSteps, safeTotalSteps > 0 {
            let finishedCumulative = max(safeNextCumulative, max(safeCurrentCumulative, safeTotalWater))
            nextStepText = safeRemainingNext > 0 ? "仕上がりまで" : "抽出完了"
            targetCumulativeLabel = safeRemainingNext > 0 ? "仕上がり目標" : "仕上がり"
            targetCumulativeValue = "\(finishedCumulative)g"
            targetCumulativeCompactText = safeRemainingNext > 0 ? "\(finishedCumulative)g" : "完了"
            additionalAmountLabel = "追加注湯"
            additionalAmountValue = "なし"
        } else {
            nextStepText = "次の注湯"
            targetCumulativeLabel = "次の累計"
            targetCumulativeValue = "\(safeNextCumulative)g"
            targetCumulativeCompactText = "\(safeNextCumulative)g"
            additionalAmountLabel = "今回足す量"
            additionalAmountValue = "+\(safeNextStepGrams)g"
        }

        if currentStepCompactText == "0" {
            compactLeadingText = targetCumulativeCompactText
        } else {
            compactLeadingText = "\(currentStepCompactText)·\(targetCumulativeCompactText)"
        }

        remainingClockText = Self.clockText(from: safeRemainingNext)
        minimalText = targetCumulativeCompactText
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
