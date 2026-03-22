import ActivityKit
import Foundation

struct BrewSessionActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var stepNumber: Int
        var stepGrams: Int
        var cumulativeGrams: Int
        var nextStepNumber: Int
        var nextStepGrams: Int
        var nextCumulativeGrams: Int
        var remainingToNextStep: Int
        var remainingTotalSeconds: Int
        var nextStepDate: Date?
        var isRunning: Bool
    }

    var totalWaterGrams: Int
    var totalSteps: Int
}

extension BrewSessionActivityAttributes.ContentState {
    enum CodingKeys: String, CodingKey {
        case stepNumber
        case stepGrams
        case cumulativeGrams
        case nextStepNumber
        case nextStepGrams
        case nextCumulativeGrams
        case remainingToNextStep
        case remainingTotalSeconds
        case nextStepDate
        case isRunning
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        stepNumber = try container.decode(Int.self, forKey: .stepNumber)
        stepGrams = try container.decode(Int.self, forKey: .stepGrams)
        cumulativeGrams = try container.decode(Int.self, forKey: .cumulativeGrams)
        nextStepNumber = try container.decodeIfPresent(Int.self, forKey: .nextStepNumber) ?? 0
        nextStepGrams = try container.decodeIfPresent(Int.self, forKey: .nextStepGrams) ?? 0
        nextCumulativeGrams = try container.decodeIfPresent(Int.self, forKey: .nextCumulativeGrams)
            ?? max(cumulativeGrams + nextStepGrams, cumulativeGrams)
        remainingToNextStep = try container.decode(Int.self, forKey: .remainingToNextStep)
        remainingTotalSeconds = try container.decode(Int.self, forKey: .remainingTotalSeconds)
        nextStepDate = try container.decodeIfPresent(Date.self, forKey: .nextStepDate)
        isRunning = try container.decode(Bool.self, forKey: .isRunning)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stepNumber, forKey: .stepNumber)
        try container.encode(stepGrams, forKey: .stepGrams)
        try container.encode(cumulativeGrams, forKey: .cumulativeGrams)
        try container.encode(nextStepNumber, forKey: .nextStepNumber)
        try container.encode(nextStepGrams, forKey: .nextStepGrams)
        try container.encode(nextCumulativeGrams, forKey: .nextCumulativeGrams)
        try container.encode(remainingToNextStep, forKey: .remainingToNextStep)
        try container.encode(remainingTotalSeconds, forKey: .remainingTotalSeconds)
        try container.encode(nextStepDate, forKey: .nextStepDate)
        try container.encode(isRunning, forKey: .isRunning)
    }
}
