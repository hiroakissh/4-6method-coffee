import SwiftUI

struct BrewAssistantView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var session = BrewSessionModel()
    @State private var didSaveLog = false

    var body: some View {
        let plan = store.currentPlan
        let progress = progressRatio(for: plan)
        let step = session.currentStep(in: plan)
        let remaining = session.secondsToNextStep(in: plan)

        NavigationStack {
            ZStack {
                assistantBackground

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        header
                        timerRing(step: step, progress: progress)
                        statusCard(plan: plan, step: step, progress: progress, remaining: remaining)
                        controls
                        schedule(plan: plan)
                        logComposer(plan: plan)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                session.load(plan: plan)
            }
            .onChange(of: plan.id) { _, _ in
                session.load(plan: plan)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    session.syncElapsedTime()
                }
            }
            .alert("抽出ログを保存しました", isPresented: $didSaveLog) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private var assistantBackground: some View {
        LinearGradient(
            colors: [
                AppDesignTokens.Colors.backgroundTop,
                AppDesignTokens.Colors.backgroundBottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            RadialGradient(
                colors: [
                    AppDesignTokens.Colors.coffee1.opacity(0.18),
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 300
            )
        }
        .overlay {
            RadialGradient(
                colors: [
                    AppDesignTokens.Colors.coffee4.opacity(0.2),
                    .clear
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 340
            )
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack {
            Button {
                store.selectedTab = .planner
            } label: {
                Image(systemName: "xmark")
                    .font(AppDesignTokens.Typography.font(.title3, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(AppDesignTokens.Colors.secondaryButtonBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()
            Text("抽出ガイド")
                .font(AppDesignTokens.Typography.font(.title2, weight: .bold))
                .foregroundStyle(AppDesignTokens.Colors.textPrimary)
            Spacer()

            Menu {
                Button("タイマーをリセット", role: .destructive) {
                    session.resetTimer()
                }
                Button("プラン画面へ戻る") {
                    store.selectedTab = .planner
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(AppDesignTokens.Typography.font(.title3, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(AppDesignTokens.Colors.secondaryButtonBackground)
                    .clipShape(Circle())
            }
        }
    }

    private func timerRing(step: PourStep, progress: Double) -> some View {
        let size: CGFloat = 286
        let clampedProgress = min(max(progress, 0), 1)

        return ZStack {
            Circle()
                .stroke(AppDesignTokens.Colors.timerRingTrack, lineWidth: 12)

            Circle()
                .trim(from: 0, to: max(clampedProgress, 0.015))
                .stroke(
                    AppDesignTokens.Colors.timerRingProgress,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Circle()
                .fill(AppDesignTokens.Colors.timerRingKnob)
                .frame(width: 10, height: 10)
                .offset(y: -(size / 2))
                .rotationEffect(.degrees(-90 + (clampedProgress * 360)))

            VStack(spacing: 8) {
                Text("第\(step.id)投 (\(phaseRatioLabel(for: step.phase)))")
                    .font(AppDesignTokens.Typography.font(.title3, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.timerRingProgress)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(AppDesignTokens.Colors.timerStepBadgeBackground)
                    .overlay {
                        Capsule()
                            .stroke(AppDesignTokens.Colors.timerStepBadgeBorder, lineWidth: 1)
                    }
                    .clipShape(Capsule())

                Text(PourStep.timeLabel(from: session.elapsedSeconds))
                    .font(.system(size: 58, weight: .black, design: AppDesignTokens.Typography.design))
                    .monospacedDigit()
                    .foregroundStyle(AppDesignTokens.Colors.timerMainValue)
                    .shadow(color: Color.black.opacity(0.28), radius: 1, x: 0, y: 2)

                Text("注ぐ量")
                    .font(AppDesignTokens.Typography.font(.title3, weight: .medium))
                    .foregroundStyle(AppDesignTokens.Colors.textSecondary)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(step.amountGrams)")
                        .font(AppDesignTokens.Typography.font(.largeTitle, weight: .bold))
                        .foregroundStyle(AppDesignTokens.Colors.timerAmountAccent)
                    Text("g")
                        .font(AppDesignTokens.Typography.font(.title3, weight: .semibold))
                        .foregroundStyle(AppDesignTokens.Colors.timerAmountAccent)
                }
            }
            .padding(.top, 10)
        }
        .frame(width: size, height: size)
        .frame(maxWidth: .infinity)
    }

    private var controls: some View {
        HStack(spacing: 24) {
            Button {
                session.resetTimer()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(AppDesignTokens.Typography.font(.title2, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                    .frame(width: 64, height: 64)
                    .background(AppDesignTokens.Colors.secondaryButtonBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Button {
                if session.isRunning {
                    session.pause()
                } else {
                    session.start()
                }
            } label: {
                Image(systemName: session.isRunning ? "pause.fill" : "play.fill")
                    .font(AppDesignTokens.Typography.font(.largeTitle, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                    .frame(width: 92, height: 92)
                    .background(AppDesignTokens.Colors.activeSegment)
                    .clipShape(Circle())
                    .shadow(color: AppDesignTokens.Colors.coffee1.opacity(0.45), radius: 14, x: 0, y: 8)
            }
            .buttonStyle(.plain)

            Button {
                session.syncElapsedTime()
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(AppDesignTokens.Typography.font(.title2, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                    .frame(width: 64, height: 64)
                    .background(AppDesignTokens.Colors.secondaryButtonBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private func statusCard(plan: BrewPlan, step: PourStep, progress: Double, remaining: Int) -> some View {
        cardContainer(spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("NEXT STEP")
                        .font(AppDesignTokens.Typography.font(.caption, weight: .bold))
                        .foregroundStyle(AppDesignTokens.Colors.textSecondary)
                    Text("\(PourStep.timeLabel(from: remaining)) 残り")
                        .font(AppDesignTokens.Typography.font(.title3, weight: .bold))
                        .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text("TOTAL WATER")
                        .font(AppDesignTokens.Typography.font(.caption, weight: .bold))
                        .foregroundStyle(AppDesignTokens.Colors.textSecondary)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(min(step.cumulativeGrams, plan.totalWater))")
                            .font(AppDesignTokens.Typography.font(.title2, weight: .bold))
                            .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                        Text("/ \(plan.totalWater)g")
                            .font(AppDesignTokens.Typography.font(.caption, weight: .medium))
                            .foregroundStyle(AppDesignTokens.Colors.textSecondary)
                    }
                }
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppDesignTokens.Colors.meterTrack)

                    Capsule()
                        .fill(AppDesignTokens.Colors.meterFill)
                        .frame(width: max(16, proxy.size.width * progress))
                }
            }
            .frame(height: 12)
        }
    }

    private func schedule(plan: BrewPlan) -> some View {
        cardContainer(spacing: 12) {
            Text("スケジュール")
                .font(AppDesignTokens.Typography.font(.title2, weight: .bold))
                .foregroundStyle(AppDesignTokens.Colors.textPrimary)

            ForEach(plan.steps) { step in
                HStack(alignment: .top, spacing: 12) {
                    statusDot(for: session.stepStatus(for: step))
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("第\(step.id)投 · \(step.amountGrams)g")
                            .font(AppDesignTokens.Typography.font(.title3, weight: .bold))
                            .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                        Text("開始 \(step.startLabel) / 待ち \(step.waitSeconds)s / 累計 \(step.cumulativeGrams)g")
                            .font(AppDesignTokens.Typography.font(.caption, weight: .medium))
                            .foregroundStyle(AppDesignTokens.Colors.textSecondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)

                if step.id != plan.steps.count {
                    Divider().overlay(AppDesignTokens.Colors.controlBorder)
                }
            }
        }
    }

    private func logComposer(plan: BrewPlan) -> some View {
        cardContainer(spacing: 14) {
            Text("抽出メモ")
                .font(AppDesignTokens.Typography.font(.title2, weight: .bold))
                .foregroundStyle(AppDesignTokens.Colors.textPrimary)

            TextEditor(text: $session.note)
                .font(AppDesignTokens.Typography.font(.body))
                .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 92)
                .padding(8)
                .background(AppDesignTokens.Colors.memoFieldBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AppDesignTokens.Colors.controlBorder, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            ratingControl(title: "甘み", value: $session.sweetness)
            ratingControl(title: "酸味", value: $session.acidity)
            ratingControl(title: "苦味", value: $session.bitterness)
            ratingControl(title: "ボディ", value: $session.body)
            ratingControl(title: "余韻", value: $session.aftertaste)

            Button {
                session.pause()
                session.saveLogIfPossible(plan: plan, store: store)
                didSaveLog = true
            } label: {
                Label("この抽出を保存", systemImage: "square.and.arrow.down")
                    .font(AppDesignTokens.Typography.font(.title3, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.ctaText)
                    .frame(height: 52)
                    .frame(maxWidth: .infinity)
                    .background(AppDesignTokens.Colors.ctaBackground)
                    .clipShape(Capsule())
                    .shadow(color: AppDesignTokens.Colors.coffee5.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
        }
    }

    private func ratingControl(title: String, value: Binding<Int>) -> some View {
        HStack {
            Text(title)
                .font(AppDesignTokens.Typography.font(.title3, weight: .bold))
                .foregroundStyle(AppDesignTokens.Colors.textPrimary)
            Spacer()
            HStack(spacing: 14) {
                ratingStepperButton(symbol: "minus") {
                    value.wrappedValue = max(1, value.wrappedValue - 1)
                }
                Text("\(value.wrappedValue)")
                    .font(AppDesignTokens.Typography.font(.title3, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                    .frame(minWidth: 16)
                ratingStepperButton(symbol: "plus") {
                    value.wrappedValue = min(5, value.wrappedValue + 1)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(AppDesignTokens.Colors.controlBackground)
            .overlay {
                Capsule()
                    .stroke(AppDesignTokens.Colors.controlBorder, lineWidth: 1)
            }
            .clipShape(Capsule())
        }
    }

    private func ratingStepperButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(AppDesignTokens.Typography.font(.title3, weight: .bold))
                .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                .frame(width: 14)
        }
        .buttonStyle(.plain)
    }

    private func statusDot(for status: BrewSessionModel.StepStatus) -> some View {
        let color = color(for: status)
        let systemName = icon(for: status)

        return Image(systemName: systemName)
            .font(AppDesignTokens.Typography.font(.body, weight: .bold))
            .foregroundStyle(color)
            .frame(width: 16, height: 16)
    }

    private func cardContainer<Content: View>(spacing: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppDesignTokens.Colors.cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: AppDesignTokens.Radius.card, style: .continuous)
                .stroke(AppDesignTokens.Colors.cardBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppDesignTokens.Radius.card, style: .continuous))
        .shadow(color: AppDesignTokens.Colors.cardShadow, radius: 22, x: 0, y: 12)
    }

    private func progressRatio(for plan: BrewPlan) -> Double {
        min(Double(session.elapsedSeconds) / Double(max(plan.estimatedTotalSeconds, 1)), 1)
    }

    private func phaseRatioLabel(for phase: PourStep.Phase) -> String {
        switch phase {
        case .balance:
            return "40%"
        case .strength:
            return "60%"
        }
    }

    private func icon(for status: BrewSessionModel.StepStatus) -> String {
        switch status {
        case .done:
            return "checkmark.circle.fill"
        case .active:
            return "circle.fill"
        case .upcoming:
            return "circle"
        }
    }

    private func color(for status: BrewSessionModel.StepStatus) -> Color {
        switch status {
        case .done:
            return AppDesignTokens.Colors.timerRingProgress
        case .active:
            return AppDesignTokens.Colors.timerAmountAccent
        case .upcoming:
            return AppDesignTokens.Colors.textSecondary
        }
    }
}

#Preview {
    BrewAssistantView()
        .environment(AppStore.preview)
}
