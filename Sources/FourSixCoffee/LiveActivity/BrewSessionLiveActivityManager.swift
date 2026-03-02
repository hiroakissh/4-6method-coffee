import ActivityKit
import Foundation

enum BrewSessionLiveActivityResolution {
    enum SyncAction: Equatable {
        case updateCurrent
        case attachExisting(id: String)
        case requestNew
    }

    static func resolveSyncAction(
        currentActivityID: String?,
        existingActivityIDs: [String]
    ) -> SyncAction {
        let uniqueIDs = uniqueOrderedIDs(existingActivityIDs)

        if let currentActivityID, uniqueIDs.contains(currentActivityID) {
            return .updateCurrent
        }
        if let latestExistingID = uniqueIDs.last {
            return .attachExisting(id: latestExistingID)
        }
        return .requestNew
    }

    static func resolveEndTargetIDs(
        currentActivityID: String?,
        existingActivityIDs: [String]
    ) -> [String] {
        var targetIDs = uniqueOrderedIDs(existingActivityIDs)
        if let currentActivityID, !targetIDs.contains(currentActivityID) {
            targetIDs.append(currentActivityID)
        }
        return targetIDs
    }

    private static func uniqueOrderedIDs(_ ids: [String]) -> [String] {
        var seen: Set<String> = []
        var ordered: [String] = []
        for id in ids where !seen.contains(id) {
            seen.insert(id)
            ordered.append(id)
        }
        return ordered
    }
}

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
        let existingActivities = Activity<BrewSessionActivityAttributes>.activities
        let syncAction = BrewSessionLiveActivityResolution.resolveSyncAction(
            currentActivityID: currentActivity?.id,
            existingActivityIDs: existingActivities.map(\.id)
        )

        switch syncAction {
        case .updateCurrent:
            if let currentActivity {
                Task {
                    await currentActivity.update(content)
                }
                return
            }

            if let fallback = existingActivities.last {
                currentActivity = fallback
                Task {
                    await fallback.update(content)
                }
                return
            }

            requestNewActivity(attributes: payload.attributes, content: content)
        case let .attachExisting(id):
            guard let existing = existingActivities.first(where: { $0.id == id }) else {
                requestNewActivity(attributes: payload.attributes, content: content)
                return
            }
            currentActivity = existing
            Task {
                await existing.update(content)
            }
        case .requestNew:
            requestNewActivity(attributes: payload.attributes, content: content)
        }
    }

    func end(
        plan: BrewPlan,
        elapsedSeconds: Int,
        currentStepIndex: Int
    ) {
        let payload = BrewSessionLiveActivityPayloadBuilder.makePayload(
            plan: plan,
            elapsedSeconds: elapsedSeconds,
            currentStepIndex: currentStepIndex,
            isRunning: false
        )
        let content = ActivityContent(state: payload.state, staleDate: nil)

        let existingActivities = Activity<BrewSessionActivityAttributes>.activities
        var existingByID: [String: Activity<BrewSessionActivityAttributes>] = [:]
        for activity in existingActivities {
            existingByID[activity.id] = activity
        }

        let targetIDs = BrewSessionLiveActivityResolution.resolveEndTargetIDs(
            currentActivityID: currentActivity?.id,
            existingActivityIDs: existingActivities.map(\.id)
        )
        guard !targetIDs.isEmpty else {
            currentActivity = nil
            return
        }

        for targetID in targetIDs {
            if let existing = existingByID[targetID] {
                Task {
                    await existing.end(content, dismissalPolicy: .immediate)
                }
                continue
            }
            if let currentActivity, currentActivity.id == targetID {
                Task {
                    await currentActivity.end(content, dismissalPolicy: .immediate)
                }
            }
        }

        self.currentActivity = nil
    }

    private func requestNewActivity(
        attributes: BrewSessionActivityAttributes,
        content: ActivityContent<BrewSessionActivityAttributes.ContentState>
    ) {
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            currentActivity = nil
        }
    }
}
