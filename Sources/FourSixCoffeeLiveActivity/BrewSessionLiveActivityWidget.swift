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
            BrewSessionLockScreenLiveActivityView(
                attributes: context.attributes,
                state: context.state
            )
            .activityBackgroundTint(LiveActivityDesignTokens.Colors.activityBackgroundTint)
            .activitySystemActionForegroundColor(LiveActivityDesignTokens.Colors.textPrimary)
        } dynamicIsland: { context in
            let presentation = BrewSessionLiveActivityPresentation(
                attributes: context.attributes,
                state: context.state
            )

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading, priority: 1) {
                    VStack(alignment: .leading, spacing: 4) {
                        LiveActivityStepBadge(text: presentation.currentStepTitle)
                        Text("現在")
                            .font(CoffeeDesignPrimitives.Typography.font(.caption2, weight: .bold))
                            .foregroundStyle(LiveActivityDesignTokens.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .dynamicIsland(verticalPlacement: .belowIfTooWide)
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text(countdownLabel(for: presentation))
                            .font(CoffeeDesignPrimitives.Typography.font(.caption2, weight: .bold))
                            .foregroundStyle(LiveActivityDesignTokens.Colors.textSecondary)

                        remainingClockText(for: context.state, fallback: presentation.remainingClockText)
                            .font(.system(size: 24, weight: .black, design: CoffeeDesignPrimitives.Typography.design))
                            .monospacedDigit()
                            .foregroundStyle(LiveActivityDesignTokens.Colors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        if let statusLabel = presentation.statusLabel {
                            Text(statusLabel)
                                .font(CoffeeDesignPrimitives.Typography.font(.caption2, weight: .bold))
                                .foregroundStyle(LiveActivityDesignTokens.Colors.textPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(LiveActivityDesignTokens.Colors.secondaryButtonBackground)
                                .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                DynamicIslandExpandedRegion(.trailing, priority: 1) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(presentation.targetCumulativeLabel)
                            .font(CoffeeDesignPrimitives.Typography.font(.caption2, weight: .bold))
                            .foregroundStyle(LiveActivityDesignTokens.Colors.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Text(presentation.targetCumulativeValue)
                            .font(CoffeeDesignPrimitives.Typography.font(.caption, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(LiveActivityDesignTokens.Colors.timerRingProgress)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .dynamicIsland(verticalPlacement: .belowIfTooWide)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(presentation.nextStepText)
                            .font(CoffeeDesignPrimitives.Typography.font(.caption, weight: .semibold))
                            .foregroundStyle(LiveActivityDesignTokens.Colors.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Spacer()

                        Text("\(presentation.additionalAmountLabel) \(presentation.additionalAmountValue)")
                            .font(CoffeeDesignPrimitives.Typography.font(.caption, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(LiveActivityDesignTokens.Colors.timerAmountAccent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
            } compactLeading: {
                Text(presentation.compactLeadingText)
                .font(CoffeeDesignPrimitives.Typography.font(.caption, weight: .bold))
                .foregroundStyle(LiveActivityDesignTokens.Colors.textPrimary)
            } compactTrailing: {
                remainingClockText(for: context.state, fallback: presentation.remainingClockText)
                    .font(CoffeeDesignPrimitives.Typography.font(.caption2, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(LiveActivityDesignTokens.Colors.textPrimary)
            } minimal: {
                Text(presentation.minimalText)
                    .font(CoffeeDesignPrimitives.Typography.font(.caption2, weight: .bold))
                    .foregroundStyle(LiveActivityDesignTokens.Colors.textPrimary)
            }
            .contentMargins([.leading, .trailing], 14, for: .expanded)
            .contentMargins([.top, .bottom], 10, for: .expanded)
            .keylineTint(LiveActivityDesignTokens.Colors.timerRingProgress)
        }
    }

    @ViewBuilder
    private func remainingClockText(
        for state: BrewSessionActivityAttributes.ContentState,
        fallback: String
    ) -> some View {
        if state.isRunning,
           let nextStepDate = state.nextStepDate,
           nextStepDate > Date.now {
            Text(timerInterval: Date.now ... nextStepDate, countsDown: true)
        } else {
            Text(fallback)
        }
    }

    private func countdownLabel(for presentation: BrewSessionLiveActivityPresentation) -> String {
        presentation.nextStepText == "抽出完了" ? "状態" : "次まで"
    }

}

private struct BrewSessionLockScreenLiveActivityView: View {
    let attributes: BrewSessionActivityAttributes
    let state: BrewSessionActivityAttributes.ContentState

    var body: some View {
        let presentation = BrewSessionLiveActivityPresentation(attributes: attributes, state: state)

        ZStack {
            LiveActivityBackground()

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center) {
                    LiveActivityStepBadge(text: presentation.currentStepTitle)
                    Spacer()
                    if let statusLabel = presentation.statusLabel {
                        statusPill(text: statusLabel)
                    }
                    Spacer(minLength: 20)
                }

                Text(presentation.nextStepText == "抽出完了" ? "状態" : "次まで")
                    .font(CoffeeDesignPrimitives.Typography.font(.caption, weight: .bold))
                    .foregroundStyle(LiveActivityDesignTokens.Colors.textSecondary)

                remainingView(fallback: presentation.remainingClockText)
                    .font(.system(size: 42, weight: .black, design: CoffeeDesignPrimitives.Typography.design))
                    .monospacedDigit()
                    .foregroundStyle(LiveActivityDesignTokens.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(presentation.nextStepText)
                    .font(CoffeeDesignPrimitives.Typography.font(.caption, weight: .semibold))
                    .foregroundStyle(LiveActivityDesignTokens.Colors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                HStack(spacing: 10) {
                    LiveActivityMetricPill(
                        title: presentation.targetCumulativeLabel,
                        value: presentation.targetCumulativeValue,
                        accent: LiveActivityDesignTokens.Colors.timerRingProgress
                    )
                    LiveActivityMetricPill(
                        title: presentation.additionalAmountLabel,
                        value: presentation.additionalAmountValue,
                        accent: LiveActivityDesignTokens.Colors.timerAmountAccent
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 46)
            .padding(.bottom, 46)
        }
        .clipShape(RoundedRectangle(cornerRadius: CoffeeDesignPrimitives.Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CoffeeDesignPrimitives.Radius.card, style: .continuous)
                .stroke(LiveActivityDesignTokens.Colors.cardBorder, lineWidth: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func remainingView(fallback: String) -> some View {
        if state.isRunning,
           let nextStepDate = state.nextStepDate,
           nextStepDate > Date.now {
            Text(timerInterval: Date.now ... nextStepDate, countsDown: true)
        } else {
            Text(fallback)
        }
    }

    private func statusPill(text: String) -> some View {
        Text(text)
            .font(CoffeeDesignPrimitives.Typography.font(.caption, weight: .bold))
            .foregroundStyle(LiveActivityDesignTokens.Colors.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(LiveActivityDesignTokens.Colors.secondaryButtonBackground)
            .clipShape(Capsule())
    }
}

private struct LiveActivityBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                LiveActivityDesignTokens.Colors.backgroundTop,
                LiveActivityDesignTokens.Colors.backgroundBottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            RadialGradient(
                colors: [
                    LiveActivityDesignTokens.Colors.coffee1.opacity(0.18),
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 18,
                endRadius: 180
            )
        }
        .overlay {
            RadialGradient(
                colors: [
                    LiveActivityDesignTokens.Colors.coffee4.opacity(0.18),
                    .clear
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 180
            )
        }
    }
}

private struct LiveActivityStepBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(CoffeeDesignPrimitives.Typography.font(.caption, weight: .bold))
            .foregroundStyle(LiveActivityDesignTokens.Colors.timerRingProgress)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(LiveActivityDesignTokens.Colors.timerStepBadgeBackground)
            .overlay {
                Capsule()
                    .stroke(LiveActivityDesignTokens.Colors.timerStepBadgeBorder, lineWidth: 1)
            }
            .clipShape(Capsule())
    }
}

private struct LiveActivityMetricPill: View {
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(CoffeeDesignPrimitives.Typography.font(.caption, weight: .bold))
                .foregroundStyle(LiveActivityDesignTokens.Colors.textSecondary)
                .lineLimit(1)
            Text(value)
                .font(CoffeeDesignPrimitives.Typography.font(.headline, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LiveActivityDesignTokens.Colors.cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LiveActivityDesignTokens.Colors.cardBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) \(value)")
    }
}

private enum LiveActivityDesignTokens {
    enum Colors {
        static let coffee1 = CoffeeDesignPrimitives.Palette.coffee1
        static let coffee2 = CoffeeDesignPrimitives.Palette.coffee2
        static let coffee3 = CoffeeDesignPrimitives.Palette.coffee3
        static let coffee4 = CoffeeDesignPrimitives.Palette.coffee4
        static let coffee5 = CoffeeDesignPrimitives.Palette.coffee5

        static let backgroundTop = coffee2
        static let backgroundBottom = Color.black
        static let activityBackgroundTint = coffee2.opacity(0.94)
        static let cardBackground = coffee2.opacity(0.52)
        static let cardBorder = coffee3.opacity(0.24)
        static let textPrimary = Color.white.opacity(0.96)
        static let textSecondary = Color.white.opacity(0.62)
        static let secondaryButtonBackground = Color.white.opacity(0.12)
        static let timerRingProgress = coffee5
        static let timerStepBadgeBackground = coffee4.opacity(0.2)
        static let timerStepBadgeBorder = coffee5.opacity(0.45)
        static let timerAmountAccent = coffee3
    }
}
#if DEBUG
@MainActor
private enum LiveActivityPreviewData {
    static let attributes = BrewSessionActivityAttributes(
        totalWaterGrams: 300,
        totalSteps: 6
    )

    static let previewStateStart = runningState(
        stepNumber: 1,
        stepGrams: 40,
        cumulativeGrams: 40,
        nextStepNumber: 2,
        nextStepGrams: 60,
        nextCumulativeGrams: 100,
        remainingToNextStep: 25,
        remainingTotalSeconds: 180
    )
    static let previewStateNext = runningState(
        stepNumber: 2,
        stepGrams: 60,
        cumulativeGrams: 100,
        nextStepNumber: 3,
        nextStepGrams: 60,
        nextCumulativeGrams: 160,
        remainingToNextStep: 30,
        remainingTotalSeconds: 150
    )
    static let previewStatePaused = pausedState(
        stepNumber: 2,
        stepGrams: 60,
        cumulativeGrams: 100,
        nextStepNumber: 3,
        nextStepGrams: 60,
        nextCumulativeGrams: 160,
        remainingToNextStep: 30,
        remainingTotalSeconds: 150
    )

    private static func runningState(
        stepNumber: Int,
        stepGrams: Int,
        cumulativeGrams: Int,
        nextStepNumber: Int,
        nextStepGrams: Int,
        nextCumulativeGrams: Int,
        remainingToNextStep: Int,
        remainingTotalSeconds: Int
    ) -> BrewSessionActivityAttributes.ContentState {
        BrewSessionActivityAttributes.ContentState(
            stepNumber: stepNumber,
            stepGrams: stepGrams,
            cumulativeGrams: cumulativeGrams,
            nextStepNumber: nextStepNumber,
            nextStepGrams: nextStepGrams,
            nextCumulativeGrams: nextCumulativeGrams,
            remainingToNextStep: remainingToNextStep,
            remainingTotalSeconds: remainingTotalSeconds,
            nextStepDate: Date.now.addingTimeInterval(TimeInterval(remainingToNextStep)),
            isRunning: true
        )
    }

    private static func pausedState(
        stepNumber: Int,
        stepGrams: Int,
        cumulativeGrams: Int,
        nextStepNumber: Int,
        nextStepGrams: Int,
        nextCumulativeGrams: Int,
        remainingToNextStep: Int,
        remainingTotalSeconds: Int
    ) -> BrewSessionActivityAttributes.ContentState {
        BrewSessionActivityAttributes.ContentState(
            stepNumber: stepNumber,
            stepGrams: stepGrams,
            cumulativeGrams: cumulativeGrams,
            nextStepNumber: nextStepNumber,
            nextStepGrams: nextStepGrams,
            nextCumulativeGrams: nextCumulativeGrams,
            remainingToNextStep: remainingToNextStep,
            remainingTotalSeconds: remainingTotalSeconds,
            nextStepDate: nil,
            isRunning: false
        )
    }
}

#Preview(
    "Lock Screen",
    as: .content,
    using: LiveActivityPreviewData.attributes,
    widget: { BrewSessionLiveActivityWidget() },
    contentStates: {
        LiveActivityPreviewData.previewStateStart
        LiveActivityPreviewData.previewStateNext
        LiveActivityPreviewData.previewStatePaused
    }
)

#Preview(
    "Dynamic Island Expanded",
    as: .dynamicIsland(.expanded),
    using: LiveActivityPreviewData.attributes,
    widget: { BrewSessionLiveActivityWidget() },
    contentStates: {
        LiveActivityPreviewData.previewStateStart
        LiveActivityPreviewData.previewStateNext
        LiveActivityPreviewData.previewStatePaused
    }
)

#Preview(
    "Dynamic Island Compact",
    as: .dynamicIsland(.compact),
    using: LiveActivityPreviewData.attributes,
    widget: { BrewSessionLiveActivityWidget() },
    contentStates: {
        LiveActivityPreviewData.previewStateStart
        LiveActivityPreviewData.previewStateNext
        LiveActivityPreviewData.previewStatePaused
    }
)
#endif
