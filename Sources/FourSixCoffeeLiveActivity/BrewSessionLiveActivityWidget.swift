import ActivityKit
import SwiftUI
import WidgetKit

@main
struct FourSixCoffeeLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        BrewSessionLiveActivityWidget()
    }
}

struct BrewSessionLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BrewSessionActivityAttributes.self) { context in
            BrewSessionLockScreenLiveActivityView(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.88))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stepLabel(for: context.state))
                            .font(.headline)
                        Text(runStateLabel(for: context.state))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("注湯 \(context.state.stepGrams)g")
                            .font(.headline.monospacedDigit())
                        Text("累計 \(context.state.cumulativeGrams)g")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("次まで")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                        remainingText(for: context.state)
                            .font(.title3.monospacedDigit().bold())
                    }
                }
            } compactLeading: {
                Text("\(context.state.stepNumber)")
                    .font(.caption2.bold())
            } compactTrailing: {
                compactRemainingText(for: context.state)
                    .font(.caption2.monospacedDigit())
            } minimal: {
                Text("\(context.state.stepNumber)")
                    .font(.caption2.bold())
            }
        }
    }

    @ViewBuilder
    private func remainingText(for state: BrewSessionActivityAttributes.ContentState) -> some View {
        if state.isRunning,
           let nextStepDate = state.nextStepDate,
           nextStepDate > Date.now {
            Text(timerInterval: Date.now ... nextStepDate, countsDown: true)
        } else {
            Text("\(state.remainingToNextStep)s")
        }
    }

    @ViewBuilder
    private func compactRemainingText(for state: BrewSessionActivityAttributes.ContentState) -> some View {
        if state.isRunning,
           let nextStepDate = state.nextStepDate,
           nextStepDate > Date.now {
            Text(timerInterval: Date.now ... nextStepDate, countsDown: true)
        } else {
            Text("\(state.remainingToNextStep)")
        }
    }

    private func stepLabel(for state: BrewSessionActivityAttributes.ContentState) -> String {
        guard state.stepNumber > 0 else { return "準備中" }
        return "第\(state.stepNumber)投"
    }

    private func runStateLabel(for state: BrewSessionActivityAttributes.ContentState) -> String {
        state.isRunning ? "抽出中" : "停止中"
    }
}

private struct BrewSessionLockScreenLiveActivityView: View {
    let state: BrewSessionActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(stepTitle)
                    .font(.title2.bold())
                Spacer()
                Text(state.isRunning ? "抽出中" : "停止中")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("注湯 \(state.stepGrams)g / 累計 \(state.cumulativeGrams)g")
                .font(.headline.monospacedDigit())

            HStack {
                Text("次の注湯まで")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                remainingView
                    .font(.title3.monospacedDigit().bold())
            }
        }
        .padding(.horizontal, 4)
    }

    private var stepTitle: String {
        guard state.stepNumber > 0 else { return "準備中" }
        return "第\(state.stepNumber)投"
    }

    @ViewBuilder
    private var remainingView: some View {
        if state.isRunning,
           let nextStepDate = state.nextStepDate,
           nextStepDate > Date.now {
            Text(timerInterval: Date.now ... nextStepDate, countsDown: true)
        } else {
            Text("\(state.remainingToNextStep)s")
        }
    }
}
