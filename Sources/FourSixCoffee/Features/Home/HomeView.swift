import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var bindableStore = store

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    beanSection

                    VStack(alignment: .leading, spacing: 12) {
                        Text("入力")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("豆量")
                                Spacer()
                                Text("\(bindableStore.currentInput.coffeeDose, specifier: "%.1f") g")
                                    .font(.title3.bold())
                            }
                            Slider(
                                value: $bindableStore.currentInput.coffeeDose,
                                in: 10...40,
                                step: 0.5
                            )
                        }

                        Picker("味方向", selection: $bindableStore.currentInput.tasteProfile) {
                            ForEach(TasteProfile.allCases) { profile in
                                Text(profile.displayName).tag(profile)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("焙煎度", selection: $bindableStore.currentInput.roastLevel) {
                            ForEach(RoastLevel.allCases) { roast in
                                Text(roast.displayName).tag(roast)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("挽き目", selection: $bindableStore.currentInput.grindSize) {
                            ForEach(GrindSize.allCases) { grind in
                                Text(grind.displayName).tag(grind)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    planSummary(plan: bindableStore.currentPlan)
                    stepsSection(plan: bindableStore.currentPlan)

                    Button {
                        bindableStore.selectedTab = .assistant
                    } label: {
                        Label("このプランでタイマーを開く", systemImage: "timer")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding()
            }
            .navigationTitle("4:6 プランナー")
        }
    }

    private var beanSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("豆")
                    .font(.headline)
                Spacer()
                Menu {
                    ForEach(store.beans) { bean in
                        Button(bean.name) {
                            store.selectedBean = bean
                        }
                    }
                } label: {
                    Label("選択", systemImage: "line.3.horizontal.decrease.circle")
                }
            }

            if let bean = store.selectedBean {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bean.name)
                        .font(.title3.bold())
                    Text("\(bean.roaster) · \(bean.origin) · \(bean.process)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("焙煎: \(bean.roastLevel.displayName)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("豆が未選択です")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func planSummary(plan: BrewPlan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("算出結果")
                .font(.headline)
            HStack(spacing: 10) {
                summaryChip(title: "総湯量", value: "\(plan.totalWater) g")
                summaryChip(title: "比率", value: "1:\(String(format: "%.1f", plan.ratio))")
                summaryChip(title: "湯温", value: "\(plan.recommendedTemperature)℃")
            }
            Text("目安時間: \(PourStep.timeLabel(from: plan.estimatedTotalSeconds))")
                .font(.subheadline.monospacedDigit())
            Text(plan.plannerMemo)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func stepsSection(plan: BrewPlan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("6投スケジュール")
                .font(.headline)
            ForEach(plan.steps) { step in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("第\(step.id)投 (\(step.phase.displayName))")
                            .font(.subheadline.bold())
                        Text("\(step.amountGrams)g · 開始 \(step.startLabel) · 累計 \(step.cumulativeGrams)g")
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 6)
                if step.id != plan.steps.count {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func summaryChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.bold())
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

#Preview {
    HomeView()
        .environment(AppStore())
}
