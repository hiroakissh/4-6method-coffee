import ActivityKit
import Foundation

struct BrewSessionActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var stepNumber: Int
        var stepGrams: Int
        var cumulativeGrams: Int
        var nextStepNumber: Int
        var nextStepGrams: Int
        var remainingToNextStep: Int
        var remainingTotalSeconds: Int
        var nextStepDate: Date?
        var isRunning: Bool
    }

    var totalWaterGrams: Int
    var totalSteps: Int
}
