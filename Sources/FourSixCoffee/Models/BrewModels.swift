import Foundation

enum AppTab: Hashable {
    case planner
    case assistant
    case beans
    case logs
    case settings
}

enum TasteProfile: String, CaseIterable, Identifiable, Hashable, Codable {
    case sweet
    case balanced
    case light

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sweet: return "甘め"
        case .balanced: return "普通"
        case .light: return "薄め"
        }
    }

    var shortNote: String {
        switch self {
        case .sweet: return "甘さ寄り"
        case .balanced: return "バランス"
        case .light: return "軽め"
        }
    }
}

enum RoastLevel: String, CaseIterable, Identifiable, Hashable, Codable {
    case light
    case medium
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "浅煎り"
        case .medium: return "中煎り"
        case .dark: return "深煎り"
        }
    }
}

enum GrindSize: String, CaseIterable, Identifiable, Hashable, Codable {
    case coarse
    case medium
    case fine

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .coarse: return "粗挽き"
        case .medium: return "中挽き"
        case .fine: return "細挽き"
        }
    }
}

struct Bean: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var roaster: String
    var origin: String
    var process: String
    var roastLevel: RoastLevel
    var notes: String
    var roastDate: Date?

    init(
        id: UUID = UUID(),
        name: String,
        roaster: String,
        origin: String,
        process: String,
        roastLevel: RoastLevel,
        notes: String = "",
        roastDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.roaster = roaster
        self.origin = origin
        self.process = process
        self.roastLevel = roastLevel
        self.notes = notes
        self.roastDate = roastDate
    }
}

struct BrewInput: Hashable, Codable {
    var coffeeDose: Double
    var tasteProfile: TasteProfile
    var roastLevel: RoastLevel
    var grindSize: GrindSize

    static let `default` = BrewInput(
        coffeeDose: 20,
        tasteProfile: .balanced,
        roastLevel: .medium,
        grindSize: .medium
    )
}

struct PourStep: Identifiable, Hashable, Codable {
    enum Phase: String, Hashable, Codable, CaseIterable {
        case balance
        case strength

        var displayName: String {
            switch self {
            case .balance: return "前半40%"
            case .strength: return "後半60%"
            }
        }
    }

    let id: Int
    var amountGrams: Int
    var cumulativeGrams: Int
    var startSecond: Int
    var waitSeconds: Int
    var phase: Phase

    var startLabel: String {
        Self.timeLabel(from: startSecond)
    }

    static func timeLabel(from seconds: Int) -> String {
        let minute = max(0, seconds) / 60
        let second = max(0, seconds) % 60
        return String(format: "%d:%02d", minute, second)
    }
}

struct BrewPlan: Identifiable, Hashable, Codable {
    let id: UUID
    var input: BrewInput
    var ratio: Double
    var totalWater: Int
    var recommendedTemperature: Int
    var steps: [PourStep]
    var estimatedTotalSeconds: Int
    var plannerMemo: String

    init(
        id: UUID = UUID(),
        input: BrewInput,
        ratio: Double,
        totalWater: Int,
        recommendedTemperature: Int,
        steps: [PourStep],
        estimatedTotalSeconds: Int,
        plannerMemo: String
    ) {
        self.id = id
        self.input = input
        self.ratio = ratio
        self.totalWater = totalWater
        self.recommendedTemperature = recommendedTemperature
        self.steps = steps
        self.estimatedTotalSeconds = estimatedTotalSeconds
        self.plannerMemo = plannerMemo
    }
}

struct TasteRatings: Hashable, Codable {
    var sweetness: Int
    var acidity: Int
    var bitterness: Int
    var body: Int
    var aftertaste: Int

    static let neutral = TasteRatings(
        sweetness: 3,
        acidity: 3,
        bitterness: 3,
        body: 3,
        aftertaste: 3
    )
}

struct BrewLog: Identifiable, Hashable, Codable {
    let id: UUID
    var date: Date
    var bean: Bean?
    var input: BrewInput
    var plan: BrewPlan
    var ratings: TasteRatings
    var memo: String
    var actualBrewSeconds: Int

    init(
        id: UUID = UUID(),
        date: Date = .now,
        bean: Bean?,
        input: BrewInput,
        plan: BrewPlan,
        ratings: TasteRatings = .neutral,
        memo: String = "",
        actualBrewSeconds: Int = 0
    ) {
        self.id = id
        self.date = date
        self.bean = bean
        self.input = input
        self.plan = plan
        self.ratings = ratings
        self.memo = memo
        self.actualBrewSeconds = actualBrewSeconds
    }
}
