import ActivityKit
import Foundation

@MainActor
protocol BrewSessionLiveActivityManaging: AnyObject {
    func sync(
        plan: BrewPlan,
        elapsedSeconds: Int,
        currentStepIndex: Int,
        isRunning: Bool
    )

    func end(
        plan: BrewPlan,
        elapsedSeconds: Int,
        currentStepIndex: Int
    )
}

@MainActor
final class BrewSessionLiveActivityManager: BrewSessionLiveActivityManaging {
    private var currentActivity: Activity<BrewSessionActivityAttributes>?
    private let activitiesEnabled: () -> Bool

    init(
        activitiesEnabled: @escaping () -> Bool = { ActivityAuthorizationInfo().areActivitiesEnabled }
    ) {
        self.activitiesEnabled = activitiesEnabled
    }

    func sync(
        plan: BrewPlan,
        elapsedSeconds: Int,
        currentStepIndex: Int,
        isRunning: Bool
    ) {
        guard activitiesEnabled() else { return }

        let payload = BrewSessionLiveActivityPayloadBuilder.makePayload(
            plan: plan,
            elapsedSeconds: elapsedSeconds,
            currentStepIndex: currentStepIndex,
            isRunning: isRunning
        )
        let content = ActivityContent(
            state: payload.state,
            staleDate: payload.staleDate
        )

        if let currentActivity {
            Task {
                await currentActivity.update(content)
            }
            return
        }

        do {
            currentActivity = try Activity.request(
                attributes: payload.attributes,
                content: content,
                pushType: nil
            )
        } catch {
            currentActivity = nil
        }
    }

    func end(
        plan: BrewPlan,
        elapsedSeconds: Int,
        currentStepIndex: Int
    ) {
        guard let currentActivity else { return }

        let payload = BrewSessionLiveActivityPayloadBuilder.makePayload(
            plan: plan,
            elapsedSeconds: elapsedSeconds,
            currentStepIndex: currentStepIndex,
            isRunning: false
        )

        Task {
            await currentActivity.end(
                ActivityContent(state: payload.state, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }

        self.currentActivity = nil
    }
}
