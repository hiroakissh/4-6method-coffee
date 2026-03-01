import Foundation

enum BrewPlanner {
    static func makePlan(from input: BrewInput) -> BrewPlan {
        let ratio = recommendedRatio(for: input)
        let totalWater = Int((input.coffeeDose * ratio).rounded())
        let temperature = recommendedTemperature(for: input)
        let percentages = pourPercentages(for: input.tasteProfile)
        let stepAmounts = allocate(total: totalWater, percentages: percentages)

        let baseWait = baseWaitSeconds(for: input)
        var startSecond = 0
        var cumulative = 0
        var steps: [PourStep] = []

        for index in 0..<6 {
            let amount = stepAmounts[index]
            cumulative += amount

            let isBalancePhase = index < 2
            let wait = index == 5 ? 0 : adjustedWait(
                base: baseWait,
                isBalancePhase: isBalancePhase
            )

            steps.append(
                PourStep(
                    id: index + 1,
                    amountGrams: amount,
                    cumulativeGrams: cumulative,
                    startSecond: startSecond,
                    waitSeconds: wait,
                    phase: isBalancePhase ? .balance : .strength
                )
            )
            startSecond += wait
        }

        let drawdownSeconds = max(20, baseWait / 2 + 12)
        let estimated = startSecond + drawdownSeconds

        return BrewPlan(
            input: input,
            ratio: ratio,
            totalWater: totalWater,
            recommendedTemperature: temperature,
            steps: steps,
            estimatedTotalSeconds: estimated,
            plannerMemo: memo(for: input, temperature: temperature)
        )
    }

    static func recommendedRatio(for input: BrewInput) -> Double {
        var ratio: Double

        switch input.tasteProfile {
        case .sweet:
            ratio = 14.6
        case .balanced:
            ratio = 15.5
        case .light:
            ratio = 16.4
        }

        switch input.roastLevel {
        case .light:
            ratio += 0.3
        case .medium:
            break
        case .dark:
            ratio -= 0.3
        }

        switch input.grindSize {
        case .coarse:
            ratio += 0.3
        case .medium:
            break
        case .fine:
            ratio -= 0.3
        }

        return min(max(ratio, 13.5), 17.5)
    }

    static func recommendedTemperature(for input: BrewInput) -> Int {
        var celsius: Int

        switch input.roastLevel {
        case .light:
            celsius = 93
        case .medium:
            celsius = 91
        case .dark:
            celsius = 89
        }

        switch input.grindSize {
        case .coarse:
            celsius += 1
        case .medium:
            break
        case .fine:
            celsius -= 1
        }

        if input.tasteProfile == .light {
            celsius += 1
        }

        return min(max(celsius, 86), 96)
    }

    private static func pourPercentages(for tasteProfile: TasteProfile) -> [Double] {
        let firstHalf: [Double]
        let secondHalf: [Double]

        switch tasteProfile {
        case .sweet:
            firstHalf = [0.18, 0.22]
            secondHalf = [0.16, 0.15, 0.15, 0.14]
        case .balanced:
            firstHalf = [0.20, 0.20]
            secondHalf = [0.15, 0.15, 0.15, 0.15]
        case .light:
            firstHalf = [0.22, 0.18]
            secondHalf = [0.14, 0.15, 0.15, 0.16]
        }

        return firstHalf + secondHalf
    }

    private static func allocate(total: Int, percentages: [Double]) -> [Int] {
        guard percentages.count == 6 else { return Array(repeating: 0, count: 6) }

        var allocated = percentages.map { Int((Double(total) * $0).rounded()) }
        let gap = total - allocated.reduce(0, +)
        allocated[allocated.count - 1] += gap
        return allocated
    }

    private static func baseWaitSeconds(for input: BrewInput) -> Int {
        var seconds: Int

        switch input.roastLevel {
        case .light:
            seconds = 44
        case .medium:
            seconds = 40
        case .dark:
            seconds = 36
        }

        switch input.grindSize {
        case .coarse:
            seconds += 5
        case .medium:
            break
        case .fine:
            seconds -= 4
        }

        switch input.tasteProfile {
        case .sweet:
            seconds += 2
        case .balanced:
            break
        case .light:
            seconds -= 2
        }

        return min(max(seconds, 28), 60)
    }

    private static func adjustedWait(base: Int, isBalancePhase: Bool) -> Int {
        let adjusted = isBalancePhase ? base + 4 : base
        return min(max(adjusted, 25), 65)
    }

    private static func memo(for input: BrewInput, temperature: Int) -> String {
        switch input.tasteProfile {
        case .sweet:
            return "前半2投はゆっくり注ぎ、甘さ重視で抽出。湯温は\(temperature)℃。"
        case .balanced:
            return "前半40%と後半60%を均等に進める標準設計。湯温は\(temperature)℃。"
        case .light:
            return "軽めの質感を狙う設計。後半の注湯は短めのテンポで進行。湯温は\(temperature)℃。"
        }
    }
}
