import SwiftUI

struct BrewAssistantView: View {
    @Environment(AppStore.self) private var store
    @State private var session = BrewSessionModel()
    @State private var didSaveLog = false

    var body: some View {
        let plan = store.currentPlan
        let progress = min(Double(session.elapsedSeconds) / Double(max(plan.estimatedTotalSeconds, 1)), 1)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    currentStepCard(plan: plan, progress: progress)
                    controls
                    schedule(plan: plan)
                    logComposer(plan: plan)
                }
                .padding()
            }
            .navigationTitle("6投タイマー")
            .onAppear {
                session.load(plan: plan)
            }
            .onChange(of: plan.id) { _, _ in
                session.load(plan: plan)
            }
            .alert("抽出ログを保存しました", isPresented: $didSaveLog) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func currentStepCard(plan: BrewPlan, progress: Double) -> some View {
        let step = session.currentStep(in: plan)
        let remaining = session.secondsToNextStep(in: plan)

        return VStack(alignment: .leading, spacing: 12) {
            Text("現在の進行")
                .font(.headline)

            HStack(alignment: .firstTextBaseline) {
                Text("第\(step.id)投")
                    .font(.title.bold())
                Spacer()
                Text(PourStep.timeLabel(from: session.elapsedSeconds))
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Text("\(step.amountGrams)g 注湯 / 次まで \(remaining)s")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ProgressView(value: progress)

            HStack {
                Text("目安終了")
                Spacer()
                Text(PourStep.timeLabel(from: plan.estimatedTotalSeconds))
                    .font(.body.monospacedDigit())
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Button {
                if session.isRunning {
                    session.pause()
                } else {
                    session.start()
                }
            } label: {
                Label(
                    session.isRunning ? "一時停止" : "開始 / 再開",
                    systemImage: session.isRunning ? "pause.fill" : "play.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button("リセット") {
                session.resetTimer()
            }
            .buttonStyle(.bordered)
        }
    }

    private func schedule(plan: BrewPlan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("スケジュール")
                .font(.headline)

            ForEach(plan.steps) { step in
                HStack {
                    Image(systemName: icon(for: session.stepStatus(for: step)))
                        .foregroundStyle(color(for: session.stepStatus(for: step)))
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("第\(step.id)投 · \(step.amountGrams)g")
                            .font(.subheadline.bold())
                        Text("開始 \(step.startLabel) / 待ち \(step.waitSeconds)s / 累計 \(step.cumulativeGrams)g")
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                if step.id != plan.steps.count {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func logComposer(plan: BrewPlan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("抽出メモ")
                .font(.headline)

            TextEditor(text: $session.note)
                .frame(minHeight: 80)
                .padding(6)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

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
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func ratingControl(title: String, value: Binding<Int>) -> some View {
        HStack {
            Text(title)
            Spacer()
            Stepper(value: value, in: 1...5) {
                Text("\(value.wrappedValue)")
                    .font(.body.monospacedDigit())
            }
            .fixedSize()
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
            return .green
        case .active:
            return .orange
        case .upcoming:
            return .secondary
        }
    }
}

#Preview {
    BrewAssistantView()
        .environment(AppStore())
}
