import Foundation
import Observation

@MainActor
@Observable
final class RecipeEditorModel {
    var recipe: BrewRecipe
    var tagsText: String

    init(recipe: BrewRecipe? = nil) {
        let initialRecipe = recipe ?? Self.newRecipe()
        self.recipe = initialRecipe
        self.tagsText = initialRecipe.metadata.tags.joined(separator: ", ")
    }

    func prepareForSave() {
        var seen: Set<String> = []
        recipe.metadata.tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
    }

    func addPhase() {
        let phaseNumber = recipe.phases.count + 1
        recipe.phases.append(
            BrewPhase(
                id: "phase-\(UUID().uuidString.lowercased())",
                type: .extraction,
                pours: [
                    PourAction(
                        id: "pour-\(UUID().uuidString.lowercased())",
                        startSecond: recipe.phases.last?.pours.last.map { $0.startSecond + 30 } ?? 0,
                        amountGrams: 30,
                        targetCumulativeGrams: (recipe.phases.flatMap(\.pours).last?.targetCumulativeGrams ?? 0) + 30,
                        flowRate: .medium,
                        position: .center
                    )
                ],
                temperature: .fixed(celsius: 92),
                agitation: [.none]
            )
        )
        recipe.metadata.tags = Array(Set(recipe.metadata.tags + ["phase-\(phaseNumber)"])).sorted()
    }

    func removePhase(id: String) {
        guard recipe.phases.count > 1 else { return }
        recipe.phases.removeAll { $0.id == id }
    }

    func addPour(to phaseID: String) {
        guard let phaseIndex = recipe.phases.firstIndex(where: { $0.id == phaseID }) else { return }
        let previousPour = recipe.phases[phaseIndex].pours.last
        let previousCumulative = previousPour?.targetCumulativeGrams ?? recipe.phases[..<phaseIndex]
            .flatMap(\.pours)
            .last?
            .targetCumulativeGrams ?? 0
        let startSecond = previousPour.map { $0.startSecond + 30 } ?? 0

        recipe.phases[phaseIndex].pours.append(
            PourAction(
                id: "pour-\(UUID().uuidString.lowercased())",
                startSecond: startSecond,
                amountGrams: 30,
                targetCumulativeGrams: previousCumulative + 30,
                flowRate: .medium,
                position: .center
            )
        )
    }

    func removePour(phaseID: String, pourID: String) {
        guard let phaseIndex = recipe.phases.firstIndex(where: { $0.id == phaseID }) else { return }
        guard recipe.phases[phaseIndex].pours.count > 1 else { return }
        recipe.phases[phaseIndex].pours.removeAll { $0.id == pourID }
    }

    func adjustTemperature(phaseID: String, by delta: Int) {
        guard let phaseIndex = recipe.phases.firstIndex(where: { $0.id == phaseID }) else { return }
        let current = recipe.phases[phaseIndex].temperature.points.first?.celsius ?? 92
        let temperature = min(max(current + delta, 80), 100)
        recipe.phases[phaseIndex].temperature = .fixed(celsius: temperature)
    }

    func temperature(for phaseID: String) -> Int {
        recipe.phases.first(where: { $0.id == phaseID })?.temperature.points.first?.celsius ?? 92
    }

    func agitation(for phaseID: String) -> AgitationAction {
        recipe.phases.first(where: { $0.id == phaseID })?.agitation.first ?? .none
    }

    func setAgitation(_ action: AgitationAction, phaseID: String) {
        guard let phaseIndex = recipe.phases.firstIndex(where: { $0.id == phaseID }) else { return }
        recipe.phases[phaseIndex].agitation = [action]
    }

    private static func newRecipe() -> BrewRecipe {
        BrewRecipe(
            metadata: RecipeMetadata(
                name: "Research Recipe",
                device: "v60",
                sourceType: .user,
                sourceSummary: "Researchで作成"
            ),
            defaults: RecipeDefaults(
                coffeeDoseGrams: 20,
                totalWaterGrams: 300,
                grindSize: .medium,
                ratio: 15
            ),
            phases: [
                BrewPhase(
                    id: "bloom",
                    type: .bloom,
                    pours: [
                        PourAction(
                            id: "bloom-1",
                            startSecond: 0,
                            amountGrams: 60,
                            targetCumulativeGrams: 60,
                            flowRate: .medium,
                            position: .center
                        )
                    ],
                    temperature: .fixed(celsius: 92),
                    agitation: [.swirl]
                )
            ]
        )
    }
}

extension AgitationAction {
    var displayName: String {
        switch self {
        case .none: return "なし"
        case .swirl: return "スワール"
        case .stir: return "撹拌"
        case .tap: return "タップ"
        }
    }
}

extension FlowRate {
    var displayName: String {
        switch self {
        case .low: return "ゆっくり"
        case .medium: return "標準"
        case .high: return "速い"
        }
    }
}

extension PourPosition {
    var displayName: String {
        switch self {
        case .center: return "中心"
        case .circle: return "円"
        case .edge: return "外周"
        }
    }
}
