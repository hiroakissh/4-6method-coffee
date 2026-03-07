import Foundation

enum SampleData {
    static let beans: [Bean] = [
        Bean(
            name: "Ethiopia Guji",
            shopName: "Sample Roasters",
            origin: "Ethiopia",
            process: "Washed",
            roastLevel: .light,
            notes: "ベリー系の甘み"
        ),
        Bean(
            name: "Colombia Huila",
            shopName: "City Roast",
            origin: "Colombia",
            process: "Honey",
            roastLevel: .medium,
            notes: "柑橘感とバランス"
        ),
        Bean(
            name: "Brazil Cerrado",
            shopName: "Daily Beans",
            origin: "Brazil",
            process: "Natural",
            roastLevel: .dark,
            notes: "ナッツ系でボディ強め"
        )
    ]

    static let brewLogs: [BrewLog] = {
        var input = BrewInput(
            coffeeDose: 20,
            tasteProfile: .sweet,
            roastLevel: .light,
            grindSize: .medium
        )
        input.brewRatio = BrewPlanner.recommendedRatio(for: input)
        let plan = BrewPlanner.makePlan(from: input)

        let log = BrewLog(
            date: .now.addingTimeInterval(-86_400),
            bean: beans.first,
            input: input,
            plan: plan,
            ratings: TasteRatings(
                sweetness: 4,
                acidity: 3,
                bitterness: 2,
                body: 3,
                aftertaste: 4
            ),
            memo: "甘さは良好。5投目をやや細く注ぐとさらに整いそう。",
            actualBrewSeconds: 228
        )
        return [log]
    }()
}
