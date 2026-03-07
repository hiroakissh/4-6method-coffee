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
        case .sweet: return "甘い"
        case .balanced: return "バランス"
        case .light: return "酸味"
        }
    }

    var shortNote: String {
        switch self {
        case .sweet: return "甘さ寄り"
        case .balanced: return "バランス"
        case .light: return "酸味寄り"
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

enum BrewStrengthFeedback: String, CaseIterable, Identifiable, Hashable, Codable {
    case light
    case balanced
    case rich

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "薄い"
        case .balanced: return "ちょうどいい"
        case .rich: return "濃い"
        }
    }
}

enum BrewOverallFeedback: String, CaseIterable, Identifiable, Hashable, Codable {
    case needsAdjustment
    case good
    case excellent

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .needsAdjustment: return "微調整必要"
        case .good: return "良い"
        case .excellent: return "かなり良い"
        }
    }
}

struct Bean: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var shopName: String
    var purchasedAt: Date
    var origin: String
    var process: String
    var roastLevel: RoastLevel
    var notes: String
    var roastDate: Date?
    var referenceURL: String

    init(
        id: UUID = UUID(),
        name: String,
        shopName: String = "",
        purchasedAt: Date = .now,
        origin: String = "",
        process: String = "",
        roastLevel: RoastLevel,
        notes: String = "",
        roastDate: Date? = nil,
        referenceURL: String = ""
    ) {
        self.id = id
        self.name = name
        self.shopName = shopName
        self.purchasedAt = purchasedAt
        self.origin = origin
        self.process = process
        self.roastLevel = roastLevel
        self.notes = notes
        self.roastDate = roastDate
        self.referenceURL = referenceURL
    }
}

struct BrewInput: Hashable, Codable {
    static let minimumBrewRatio = 10.0
    static let maximumBrewRatio = 20.0
    static let defaultBrewRatio = 15.0

    var coffeeDose: Double
    var brewRatio: Double
    var tasteProfile: TasteProfile
    var roastLevel: RoastLevel
    var grindSize: GrindSize

    init(
        coffeeDose: Double,
        brewRatio: Double = BrewInput.defaultBrewRatio,
        tasteProfile: TasteProfile,
        roastLevel: RoastLevel,
        grindSize: GrindSize
    ) {
        self.coffeeDose = coffeeDose
        self.brewRatio = Self.normalizedBrewRatio(brewRatio)
        self.tasteProfile = tasteProfile
        self.roastLevel = roastLevel
        self.grindSize = grindSize
    }

    static let `default` = BrewInput(
        coffeeDose: 20,
        brewRatio: defaultBrewRatio,
        tasteProfile: .balanced,
        roastLevel: .medium,
        grindSize: .medium
    )

    enum CodingKeys: String, CodingKey {
        case coffeeDose
        case brewRatio
        case tasteProfile
        case roastLevel
        case grindSize
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.coffeeDose = try container.decode(Double.self, forKey: .coffeeDose)
        self.brewRatio = Self.normalizedBrewRatio(
            try container.decodeIfPresent(Double.self, forKey: .brewRatio) ?? Self.defaultBrewRatio
        )
        self.tasteProfile = try container.decode(TasteProfile.self, forKey: .tasteProfile)
        self.roastLevel = try container.decode(RoastLevel.self, forKey: .roastLevel)
        self.grindSize = try container.decode(GrindSize.self, forKey: .grindSize)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coffeeDose, forKey: .coffeeDose)
        try container.encode(Self.normalizedBrewRatio(brewRatio), forKey: .brewRatio)
        try container.encode(tasteProfile, forKey: .tasteProfile)
        try container.encode(roastLevel, forKey: .roastLevel)
        try container.encode(grindSize, forKey: .grindSize)
    }

    static func normalizedBrewRatio(_ value: Double) -> Double {
        min(max(value, minimumBrewRatio), maximumBrewRatio)
    }
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

    init(
        sweetness: Int,
        acidity: Int,
        bitterness: Int,
        body: Int,
        aftertaste: Int
    ) {
        self.sweetness = sweetness
        self.acidity = acidity
        self.bitterness = bitterness
        self.body = body
        self.aftertaste = aftertaste
    }

    init(
        tasteFeedback: TasteProfile,
        strengthFeedback: BrewStrengthFeedback,
        overallFeedback: BrewOverallFeedback
    ) {
        let sweetness: Int
        let acidity: Int

        switch tasteFeedback {
        case .sweet:
            sweetness = 5
            acidity = 2
        case .balanced:
            sweetness = 3
            acidity = 3
        case .light:
            sweetness = 2
            acidity = 5
        }

        let bitterness: Int
        let body: Int

        switch strengthFeedback {
        case .light:
            bitterness = 2
            body = 2
        case .balanced:
            bitterness = 3
            body = 3
        case .rich:
            bitterness = 4
            body = 5
        }

        let aftertaste: Int

        switch overallFeedback {
        case .needsAdjustment:
            aftertaste = 2
        case .good:
            aftertaste = 4
        case .excellent:
            aftertaste = 5
        }

        self.init(
            sweetness: sweetness,
            acidity: acidity,
            bitterness: bitterness,
            body: body,
            aftertaste: aftertaste
        )
    }

    static let neutral = TasteRatings(
        sweetness: 3,
        acidity: 3,
        bitterness: 3,
        body: 3,
        aftertaste: 3
    )

    var tasteFeedbackSummary: TasteProfile {
        let gap = sweetness - acidity

        if gap >= 2 {
            return .sweet
        }

        if gap <= -2 {
            return .light
        }

        return .balanced
    }

    var strengthFeedbackSummary: BrewStrengthFeedback {
        if body >= 5 || bitterness >= 4 {
            return .rich
        }

        if body <= 2 && bitterness <= 2 {
            return .light
        }

        return .balanced
    }

    var overallFeedbackSummary: BrewOverallFeedback {
        switch aftertaste {
        case ...2:
            return .needsAdjustment
        case 5...:
            return .excellent
        default:
            return .good
        }
    }
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
