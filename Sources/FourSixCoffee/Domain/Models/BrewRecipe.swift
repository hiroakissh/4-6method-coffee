import Foundation

struct BrewRecipe: Codable, Hashable, Identifiable {
    static let currentSchemaVersion = 1

    let id: UUID
    var schemaVersion: Int
    var metadata: RecipeMetadata
    var defaults: RecipeDefaults
    var phases: [BrewPhase]

    init(
        id: UUID = UUID(),
        schemaVersion: Int = BrewRecipe.currentSchemaVersion,
        metadata: RecipeMetadata,
        defaults: RecipeDefaults,
        phases: [BrewPhase]
    ) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.metadata = metadata
        self.defaults = defaults
        self.phases = phases
    }
}

struct RecipeMetadata: Codable, Hashable {
    var name: String
    var device: String
    var sourceType: RecipeSourceType
    var sourceSummary: String
    var tags: [String]

    init(
        name: String,
        device: String,
        sourceType: RecipeSourceType,
        sourceSummary: String = "",
        tags: [String] = []
    ) {
        self.name = name
        self.device = device
        self.sourceType = sourceType
        self.sourceSummary = sourceSummary
        self.tags = tags
    }
}

enum RecipeSourceType: String, Codable, Hashable {
    case preset
    case user
    case imported
}

struct RecipeDefaults: Codable, Hashable {
    var coffeeDoseGrams: Double
    var totalWaterGrams: Int
    var grindSize: GrindSize
    var ratio: Double

    init(
        coffeeDoseGrams: Double,
        totalWaterGrams: Int,
        grindSize: GrindSize,
        ratio: Double
    ) {
        self.coffeeDoseGrams = coffeeDoseGrams
        self.totalWaterGrams = totalWaterGrams
        self.grindSize = grindSize
        self.ratio = ratio
    }
}

struct BrewPhase: Codable, Hashable, Identifiable {
    let id: String
    var type: PhaseType
    var pours: [PourAction]
    var temperature: TemperatureProfile
    var agitation: [AgitationAction]

    init(
        id: String,
        type: PhaseType,
        pours: [PourAction],
        temperature: TemperatureProfile,
        agitation: [AgitationAction] = []
    ) {
        self.id = id
        self.type = type
        self.pours = pours
        self.temperature = temperature
        self.agitation = agitation
    }
}

enum PhaseType: String, Codable, Hashable {
    case bloom
    case extraction
    case immersion
    case bypass
    case finish
}

struct PourAction: Codable, Hashable, Identifiable {
    let id: String
    var startSecond: Int
    var amountGrams: Int
    var targetCumulativeGrams: Int
    var flowRate: FlowRate
    var position: PourPosition

    init(
        id: String,
        startSecond: Int,
        amountGrams: Int,
        targetCumulativeGrams: Int,
        flowRate: FlowRate,
        position: PourPosition
    ) {
        self.id = id
        self.startSecond = startSecond
        self.amountGrams = amountGrams
        self.targetCumulativeGrams = targetCumulativeGrams
        self.flowRate = flowRate
        self.position = position
    }
}

enum FlowRate: String, Codable, Hashable {
    case low
    case medium
    case high
}

enum PourPosition: String, Codable, Hashable {
    case center
    case circle
    case edge
}

struct TemperatureProfile: Codable, Hashable {
    var mode: TemperatureMode
    var points: [TemperaturePoint]

    init(mode: TemperatureMode, points: [TemperaturePoint]) {
        self.mode = mode
        self.points = points
    }

    static func fixed(celsius: Int) -> TemperatureProfile {
        TemperatureProfile(
            mode: .fixed,
            points: [TemperaturePoint(time: 0, celsius: celsius)]
        )
    }
}

enum TemperatureMode: String, Codable, Hashable {
    case fixed
    case stepwise
}

struct TemperaturePoint: Codable, Hashable {
    var time: Int
    var celsius: Int
}

enum AgitationAction: String, Codable, Hashable {
    case none
    case swirl
    case stir
    case tap
}
