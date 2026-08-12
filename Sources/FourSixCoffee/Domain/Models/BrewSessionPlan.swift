import Foundation

struct BrewSessionPlan: Codable, Hashable, Identifiable {
    let id: UUID
    let recipeID: UUID
    let recipeName: String
    let totalWaterGrams: Int
    let recommendedTemperature: Int?
    let actions: [BrewSessionAction]
    let estimatedTotalSeconds: Int

    init(
        id: UUID,
        recipeID: UUID,
        recipeName: String,
        totalWaterGrams: Int,
        recommendedTemperature: Int?,
        actions: [BrewSessionAction],
        estimatedTotalSeconds: Int
    ) {
        self.id = id
        self.recipeID = recipeID
        self.recipeName = recipeName
        self.totalWaterGrams = totalWaterGrams
        self.recommendedTemperature = recommendedTemperature
        self.actions = actions
        self.estimatedTotalSeconds = estimatedTotalSeconds
    }
}

struct BrewSessionAction: Codable, Hashable, Identifiable {
    let id: String
    let sequenceNumber: Int
    let phaseID: String
    let phaseType: PhaseType
    let startSecond: Int
    let amountGrams: Int
    let targetCumulativeGrams: Int
    let waitSeconds: Int
    let temperatureCelsius: Int?
    let agitation: [AgitationAction]

    init(
        id: String,
        sequenceNumber: Int,
        phaseID: String,
        phaseType: PhaseType,
        startSecond: Int,
        amountGrams: Int,
        targetCumulativeGrams: Int,
        waitSeconds: Int,
        temperatureCelsius: Int?,
        agitation: [AgitationAction]
    ) {
        self.id = id
        self.sequenceNumber = sequenceNumber
        self.phaseID = phaseID
        self.phaseType = phaseType
        self.startSecond = startSecond
        self.amountGrams = amountGrams
        self.targetCumulativeGrams = targetCumulativeGrams
        self.waitSeconds = waitSeconds
        self.temperatureCelsius = temperatureCelsius
        self.agitation = agitation
    }
}

extension PhaseType {
    var displayName: String {
        switch self {
        case .bloom:
            return "蒸らし"
        case .extraction:
            return "抽出"
        case .immersion:
            return "浸漬"
        case .bypass:
            return "バイパス"
        case .finish:
            return "仕上げ"
        }
    }
}
