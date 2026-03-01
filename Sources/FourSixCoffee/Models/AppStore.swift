import Foundation
import Observation

@Observable
final class AppStore {
    var selectedTab: AppTab = .planner

    var beans: [Bean]
    var selectedBeanID: UUID?

    var currentInput: BrewInput {
        didSet { recalculatePlan() }
    }
    var currentPlan: BrewPlan

    var brewLogs: [BrewLog]

    var enableStepHaptics: Bool
    var preferredUnit: String

    init(
        beans: [Bean] = SampleData.beans,
        selectedBeanID: UUID? = nil,
        currentInput: BrewInput = .default,
        brewLogs: [BrewLog] = SampleData.brewLogs,
        enableStepHaptics: Bool = true,
        preferredUnit: String = "g"
    ) {
        self.beans = beans
        let resolvedSelectedBeanID = selectedBeanID ?? beans.first?.id
        self.selectedBeanID = resolvedSelectedBeanID

        var resolvedInput = currentInput
        if let resolvedSelectedBeanID,
           let selectedBean = beans.first(where: { $0.id == resolvedSelectedBeanID }) {
            // Keep initial calculation aligned with the initially selected bean.
            resolvedInput.roastLevel = selectedBean.roastLevel
        }

        self.currentInput = resolvedInput
        self.currentPlan = BrewPlanner.makePlan(from: resolvedInput)
        self.brewLogs = brewLogs
        self.enableStepHaptics = enableStepHaptics
        self.preferredUnit = preferredUnit
        recalculatePlan()
    }

    var selectedBean: Bean? {
        get { beans.first(where: { $0.id == selectedBeanID }) }
        set {
            selectedBeanID = newValue?.id
            if let roast = newValue?.roastLevel {
                currentInput.roastLevel = roast
            }
        }
    }

    func recalculatePlan() {
        currentPlan = BrewPlanner.makePlan(from: currentInput)
    }

    func updateCoffeeDose(_ value: Double) {
        currentInput.coffeeDose = min(max(value, 10), 40)
    }

    func updateTasteProfile(_ profile: TasteProfile) {
        currentInput.tasteProfile = profile
    }

    func updateRoastLevel(_ roast: RoastLevel) {
        currentInput.roastLevel = roast
    }

    func updateGrindSize(_ grind: GrindSize) {
        currentInput.grindSize = grind
    }

    func addBean(name: String, roaster: String, origin: String, process: String, roastLevel: RoastLevel) {
        let bean = Bean(
            name: name,
            roaster: roaster,
            origin: origin,
            process: process,
            roastLevel: roastLevel
        )
        beans.insert(bean, at: 0)
        selectedBeanID = bean.id
        currentInput.roastLevel = bean.roastLevel
    }

    func addBrewLog(
        memo: String,
        ratings: TasteRatings,
        actualBrewSeconds: Int
    ) {
        let log = BrewLog(
            bean: selectedBean,
            input: currentInput,
            plan: currentPlan,
            ratings: ratings,
            memo: memo.trimmingCharacters(in: .whitespacesAndNewlines),
            actualBrewSeconds: actualBrewSeconds
        )
        brewLogs.insert(log, at: 0)
    }

    func apply(log: BrewLog) {
        currentInput = log.input
        if let beanID = log.bean?.id, beans.contains(where: { $0.id == beanID }) {
            selectedBeanID = beanID
        }
        selectedTab = .planner
    }

    func deleteLogs(at offsets: IndexSet) {
        brewLogs.remove(atOffsets: offsets)
    }
}
