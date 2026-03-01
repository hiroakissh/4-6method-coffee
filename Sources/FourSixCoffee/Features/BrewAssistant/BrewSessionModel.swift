import Foundation
import Observation

@MainActor
@Observable
final class BrewSessionModel {
    private(set) var loadedPlanID: UUID?
    var elapsedSeconds: Int = 0
    var currentStepIndex: Int = 0
    var isRunning: Bool = false
    var note: String = ""

    var sweetness: Int = 3
    var acidity: Int = 3
    var bitterness: Int = 3
    var body: Int = 3
    var aftertaste: Int = 3

    @ObservationIgnored
    private var tickerTask: Task<Void, Never>?
    @ObservationIgnored
    private var stepStartSeconds: [Int] = []
    @ObservationIgnored
    private var estimatedTotalSeconds: Int = 0

    func load(plan: BrewPlan) {
        guard loadedPlanID != plan.id else { return }
        resetRuntime()
        loadedPlanID = plan.id
        stepStartSeconds = plan.steps.map(\.startSecond)
        estimatedTotalSeconds = plan.estimatedTotalSeconds
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        runTicker()
    }

    func pause() {
        isRunning = false
        tickerTask?.cancel()
        tickerTask = nil
    }

    func resetAll() {
        pause()
        resetRuntime()
        resetFeedback()
    }

    func resetRuntime() {
        elapsedSeconds = 0
        currentStepIndex = 0
    }

    func saveLogIfPossible(plan: BrewPlan, store: AppStore) {
        let ratings = TasteRatings(
            sweetness: sweetness,
            acidity: acidity,
            bitterness: bitterness,
            body: body,
            aftertaste: aftertaste
        )
        store.addBrewLog(
            memo: note,
            ratings: ratings,
            actualBrewSeconds: elapsedSeconds
        )
    }

    func stepStatus(for step: PourStep) -> StepStatus {
        if step.id - 1 < currentStepIndex { return .done }
        if step.id - 1 == currentStepIndex { return .active }
        return .upcoming
    }

    func secondsToNextStep(in plan: BrewPlan) -> Int {
        let nextIndex = currentStepIndex + 1
        guard plan.steps.indices.contains(nextIndex) else {
            return max(plan.estimatedTotalSeconds - elapsedSeconds, 0)
        }
        return max(plan.steps[nextIndex].startSecond - elapsedSeconds, 0)
    }

    func currentStep(in plan: BrewPlan) -> PourStep {
        let safeIndex = max(0, min(currentStepIndex, plan.steps.count - 1))
        return plan.steps[safeIndex]
    }

    deinit {
        tickerTask?.cancel()
    }

    private func runTicker() {
        tickerTask?.cancel()
        tickerTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                tick()
            }
        }
    }

    private func tick() {
        guard isRunning else { return }
        if estimatedTotalSeconds > 0, elapsedSeconds >= estimatedTotalSeconds {
            pause()
            return
        }
        elapsedSeconds += 1
        currentStepIndex = latestStepIndex(for: elapsedSeconds)
    }

    private func resetFeedback() {
        note = ""
        sweetness = 3
        acidity = 3
        bitterness = 3
        body = 3
        aftertaste = 3
    }

    private func latestStepIndex(for seconds: Int) -> Int {
        guard !stepStartSeconds.isEmpty else { return 0 }

        var resolved = 0
        for (index, start) in stepStartSeconds.enumerated() where seconds >= start {
            resolved = index
        }
        return resolved
    }
}

extension BrewSessionModel {
    enum StepStatus {
        case done
        case active
        case upcoming
    }
}
