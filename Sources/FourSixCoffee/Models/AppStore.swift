import Foundation
import Observation

@MainActor
@Observable
final class AppStore {
    @ObservationIgnored
    private let beanUseCase: BeanUseCase
    @ObservationIgnored
    private let brewLogUseCase: BrewLogUseCase

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

    var lastErrorMessage: String?

    init(
        dependencies: AppDependencies = .live(),
        seedSampleDataIfEmpty: Bool = false,
        enableStepHaptics: Bool = true,
        preferredUnit: String = "g"
    ) {
        self.beanUseCase = dependencies.beanUseCase
        self.brewLogUseCase = dependencies.brewLogUseCase

        self.beans = []
        self.selectedBeanID = nil
        self.currentInput = .default
        self.currentPlan = BrewPlanner.makePlan(from: .default)
        self.brewLogs = []
        self.enableStepHaptics = enableStepHaptics
        self.preferredUnit = preferredUnit
        self.lastErrorMessage = nil

        loadInitialState(seedSampleDataIfEmpty: seedSampleDataIfEmpty)
    }

    static var preview: AppStore {
        AppStore(
            dependencies: .preview(),
            seedSampleDataIfEmpty: true
        )
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
        do {
            let bean = try beanUseCase.createBean(
                name: name,
                roaster: roaster,
                origin: origin,
                process: process,
                roastLevel: roastLevel
            )
            beans.insert(bean, at: 0)
            selectedBeanID = bean.id
            currentInput.roastLevel = bean.roastLevel
            lastErrorMessage = nil
        } catch {
            store(error: error)
        }
    }

    func addBrewLog(
        memo: String,
        ratings: TasteRatings,
        actualBrewSeconds: Int
    ) {
        do {
            let log = try brewLogUseCase.createLog(
                bean: selectedBean,
                input: currentInput,
                plan: currentPlan,
                ratings: ratings,
                memo: memo,
                actualBrewSeconds: actualBrewSeconds
            )
            brewLogs.insert(log, at: 0)
            lastErrorMessage = nil
        } catch {
            store(error: error)
        }
    }

    func apply(log: BrewLog) {
        currentInput = log.input
        if let beanID = log.bean?.id,
           beans.contains(where: { $0.id == beanID }) {
            selectedBeanID = beanID
        } else {
            selectedBeanID = nil
        }
        selectedTab = .planner
    }

    func deleteLogs(at offsets: IndexSet) {
        let ids = offsets.map { brewLogs[$0].id }

        do {
            try brewLogUseCase.deleteLogs(ids: ids)
            brewLogs.remove(atOffsets: offsets)
            lastErrorMessage = nil
        } catch {
            store(error: error)
        }
    }

    func deleteBeans(at offsets: IndexSet) {
        let ids = offsets.map { beans[$0].id }

        do {
            try beanUseCase.deleteBeans(ids: ids)
            beans.remove(atOffsets: offsets)

            if let selectedBeanID,
               !beans.contains(where: { $0.id == selectedBeanID }) {
                self.selectedBean = beans.first
            }

            for index in brewLogs.indices {
                if let beanID = brewLogs[index].bean?.id,
                   ids.contains(beanID) {
                    brewLogs[index].bean = nil
                    try brewLogUseCase.save(log: brewLogs[index])
                }
            }

            lastErrorMessage = nil
        } catch {
            store(error: error)
        }
    }

    private func loadInitialState(seedSampleDataIfEmpty: Bool) {
        do {
            beans = try beanUseCase.fetchBeans()
            brewLogs = try brewLogUseCase.fetchBrewLogs()

            if seedSampleDataIfEmpty,
               beans.isEmpty,
               brewLogs.isEmpty {
                try seedSampleData()
                beans = try beanUseCase.fetchBeans()
                brewLogs = try brewLogUseCase.fetchBrewLogs()
            }

            selectedBeanID = beans.first?.id
            if let selectedBean {
                currentInput.roastLevel = selectedBean.roastLevel
            }
            recalculatePlan()
            lastErrorMessage = nil
        } catch {
            store(error: error)
        }
    }

    private func seedSampleData() throws {
        for bean in SampleData.beans {
            try beanUseCase.save(bean: bean)
        }

        for log in SampleData.brewLogs {
            try brewLogUseCase.save(log: log)
        }
    }

    private func store(error: Error) {
        if let localized = error as? LocalizedError,
           let description = localized.errorDescription {
            lastErrorMessage = description
            return
        }
        lastErrorMessage = error.localizedDescription
    }
}
