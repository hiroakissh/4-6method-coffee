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
    @ObservationIgnored
    private let liveActivityManager: BrewSessionLiveActivityManaging
    @ObservationIgnored
    private var loadedPlan: BrewPlan?
    @ObservationIgnored
    private var timerReferenceDate: Date?
    @ObservationIgnored
    private let now: () -> Date

    init(
        liveActivityManager: BrewSessionLiveActivityManaging = BrewSessionLiveActivityManager(),
        now: @escaping () -> Date = Date.init
    ) {
        self.liveActivityManager = liveActivityManager
        self.now = now
    }

    func load(plan: BrewPlan) {
        guard loadedPlanID != plan.id else {
            loadedPlan = plan
            return
        }

        let previousPlan = loadedPlan
        let previousElapsed = elapsedSeconds
        let previousStepIndex = currentStepIndex
        pause()

        if let previousPlan {
            liveActivityManager.end(
                plan: previousPlan,
                elapsedSeconds: previousElapsed,
                currentStepIndex: previousStepIndex
            )
        }

        resetRuntime()
        loadedPlan = plan
        loadedPlanID = plan.id
        stepStartSeconds = plan.steps.map(\.startSecond)
        estimatedTotalSeconds = plan.estimatedTotalSeconds
    }

    func start() {
        guard !isRunning else { return }
        guard loadedPlan != nil else { return }
        timerReferenceDate = now().addingTimeInterval(TimeInterval(-elapsedSeconds))
        isRunning = true
        runTicker()
        syncLiveActivityIfPossible()
    }

    func pause() {
        let wasRunning = isRunning
        isRunning = false
        tickerTask?.cancel()
        tickerTask = nil
        if wasRunning {
            syncLiveActivityIfPossible()
        }
    }

    func resetAll() {
        pause()
        resetRuntime()
        resetFeedback()
        endLiveActivityIfPossible()
    }

    func resetRuntime() {
        elapsedSeconds = 0
        currentStepIndex = 0
        timerReferenceDate = nil
    }

    func resetTimer() {
        pause()
        resetRuntime()
        endLiveActivityIfPossible()
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
        liveActivityManager.end(
            plan: plan,
            elapsedSeconds: elapsedSeconds,
            currentStepIndex: currentStepIndex
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
        refreshElapsedFromClock()
        guard isRunning else { return }
        if estimatedTotalSeconds > 0, elapsedSeconds >= estimatedTotalSeconds {
            pause()
            endLiveActivityIfPossible()
            return
        }
        syncLiveActivityIfPossible()
    }

    func syncElapsedTime() {
        refreshElapsedFromClock()
        guard isRunning else { return }
        if estimatedTotalSeconds > 0, elapsedSeconds >= estimatedTotalSeconds {
            pause()
            endLiveActivityIfPossible()
            return
        }
        syncLiveActivityIfPossible()
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

    private func refreshElapsedFromClock() {
        guard isRunning, let timerReferenceDate else { return }

        let resolvedElapsed = max(Int(now().timeIntervalSince(timerReferenceDate)), 0)
        let clampedElapsed: Int
        if estimatedTotalSeconds > 0 {
            clampedElapsed = min(resolvedElapsed, estimatedTotalSeconds)
        } else {
            clampedElapsed = resolvedElapsed
        }

        elapsedSeconds = clampedElapsed
        currentStepIndex = latestStepIndex(for: clampedElapsed)
    }

    private func syncLiveActivityIfPossible() {
        guard let plan = loadedPlan else { return }
        liveActivityManager.sync(
            plan: plan,
            elapsedSeconds: elapsedSeconds,
            currentStepIndex: currentStepIndex,
            isRunning: isRunning
        )
    }

    private func endLiveActivityIfPossible() {
        guard let plan = loadedPlan else { return }
        liveActivityManager.end(
            plan: plan,
            elapsedSeconds: elapsedSeconds,
            currentStepIndex: currentStepIndex
        )
    }
}

extension BrewSessionModel {
    enum StepStatus {
        case done
        case active
        case upcoming
    }
}
