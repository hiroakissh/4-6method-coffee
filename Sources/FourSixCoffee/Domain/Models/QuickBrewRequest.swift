import Foundation

struct QuickBrewRequest: Codable, Hashable {
    static let minimumCoffeeDose = 10.0
    static let maximumCoffeeDose = 40.0

    var coffeeDoseGrams: Double
    var roastLevel: RoastLevel
    var tasteProfile: TasteProfile

    init(
        coffeeDoseGrams: Double,
        roastLevel: RoastLevel,
        tasteProfile: TasteProfile
    ) {
        self.coffeeDoseGrams = Self.normalizedCoffeeDose(coffeeDoseGrams)
        self.roastLevel = roastLevel
        self.tasteProfile = tasteProfile
    }

    static let `default` = QuickBrewRequest(
        coffeeDoseGrams: 20,
        roastLevel: .medium,
        tasteProfile: .balanced
    )

    var brewInput: BrewInput {
        BrewInput(
            coffeeDose: coffeeDoseGrams,
            brewRatio: BrewInput.defaultBrewRatio,
            tasteProfile: tasteProfile,
            roastLevel: roastLevel,
            grindSize: .medium
        )
    }

    static func normalizedCoffeeDose(_ value: Double) -> Double {
        let stepped = (value * 2).rounded() / 2
        return min(max(stepped, minimumCoffeeDose), maximumCoffeeDose)
    }
}
