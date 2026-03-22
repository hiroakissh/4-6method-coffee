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

    var tasteFeedback: TasteProfile = .balanced
    var strengthFeedback: BrewStrengthFeedback = .balanced
    var overallFeedback: BrewOverallFeedback = .good

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
            tasteFeedback: tasteFeedback,
            strengthFeedback: strengthFeedback,
            overallFeedback: overallFeedback
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

    func nextActionSummary(in plan: BrewPlan) -> NextActionSummary {
        let currentStep = currentStep(in: plan)
        let nextIndex = currentStepIndex + 1
        let nextStep = plan.steps.indices.contains(nextIndex) ? plan.steps[nextIndex] : nil
        let remainingSeconds = secondsToNextStep(in: plan)
        let safeTotalWater = max(plan.totalWater, 0)
        let currentSegmentStart = max(currentStep.startSecond, 0)
        let currentSegmentEnd = max(nextStep?.startSecond ?? plan.estimatedTotalSeconds, currentSegmentStart)
        let segmentDurationSeconds = max(currentSegmentEnd - currentSegmentStart, 0)
        let elapsedInSegment = min(max(elapsedSeconds - currentSegmentStart, 0), segmentDurationSeconds)

        let targetCumulativeGrams: Int
        let additionalGrams: Int

        if let nextStep {
            targetCumulativeGrams = min(max(nextStep.cumulativeGrams, 0), safeTotalWater)
            additionalGrams = max(nextStep.amountGrams, 0)
        } else {
            targetCumulativeGrams = max(max(currentStep.cumulativeGrams, 0), safeTotalWater)
            additionalGrams = 0
        }

        return NextActionSummary(
            currentStep: currentStep,
            nextStep: nextStep,
            remainingSeconds: remainingSeconds,
            elapsedSeconds: elapsedSeconds,
            isRunning: isRunning,
            targetCumulativeGrams: targetCumulativeGrams,
            additionalGrams: additionalGrams,
            totalWaterGrams: safeTotalWater,
            segmentDurationSeconds: segmentDurationSeconds,
            countdownProgress: segmentDurationSeconds > 0
                ? Double(max(segmentDurationSeconds - elapsedInSegment, 0)) / Double(segmentDurationSeconds)
                : 0
        )
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
        tasteFeedback = .balanced
        strengthFeedback = .balanced
        overallFeedback = .good
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
    struct NextActionSummary: Equatable {
        let currentStep: PourStep
        let nextStep: PourStep?
        let remainingSeconds: Int
        let elapsedSeconds: Int
        let isRunning: Bool
        let targetCumulativeGrams: Int
        let additionalGrams: Int
        let totalWaterGrams: Int
        let segmentDurationSeconds: Int
        let countdownProgress: Double

        var isFinalPhase: Bool { nextStep == nil }
        var isComplete: Bool { isFinalPhase && remainingSeconds == 0 }
        var isAwaitingFinish: Bool { isFinalPhase && remainingSeconds > 0 }
    }

    enum StepStatus {
        case done
        case active
        case upcoming
    }
}
