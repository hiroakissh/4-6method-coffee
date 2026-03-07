import Foundation
import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store

    private let tasteOptions: [TasteProfile] = [.light, .balanced, .sweet]
    private let concentrationOptions: [ConcentrationOption] = ConcentrationOption.options
    private let roastOptions: [RoastLevel] = RoastLevel.allCases

    private var currentPlan: BrewPlan { store.currentPlan }

    var body: some View {
        NavigationStack {
            ZStack {
                plannerBackground

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        beanCard
                        plannerInputCard
                        calculatedPlanCard
                        scheduleCard
                        recommendationPlaceholderCard
                        timerCTA
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var plannerBackground: some View {
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
                    AppDesignTokens.Colors.coffee1.opacity(0.2),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 30,
                endRadius: 360
            )
        }
        .overlay {
            RadialGradient(
                colors: [
                    AppDesignTokens.Colors.coffee4.opacity(0.22),
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 300
            )
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("プランナー")
                    .font(AppDesignTokens.Typography.font(.title2, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                Text("入力を先に決めて、すぐ下で結果を確認")
                    .font(AppDesignTokens.Typography.font(.caption, weight: .medium))
                    .foregroundStyle(AppDesignTokens.Colors.textSecondary)
            }
            Spacer()
            Menu {
                if store.beans.isEmpty {
                    Text("保存済みの豆がありません")
                } else {
                    ForEach(store.beans) { bean in
                        Button {
                            store.selectedBean = bean
                        } label: {
                            if store.selectedBeanID == bean.id {
                                Label(bean.name, systemImage: "checkmark")
                            } else {
                                Text(bean.name)
                            }
                        }
                    }
                }
                Divider()
                Button("豆一覧を開く") {
                    store.selectedTab = .beans
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(AppDesignTokens.Colors.controlBackground)
                    Image(systemName: "ellipsis")
                        .font(AppDesignTokens.Typography.font(.title3, weight: .bold))
                        .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                }
                .frame(width: 56, height: 56)
            }
        }
    }

    private var beanCard: some View {
        cardContainer {
            cardHeader(systemImage: "leaf.fill", title: "豆")

            if let bean = store.selectedBean {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(bean.name)
                            .font(AppDesignTokens.Typography.font(.title3, weight: .bold))
                            .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                        Spacer()
                        beanBadge(text: bean.roastLevel.displayName)
                    }
                    Text(bean.shopName)
                        .font(AppDesignTokens.Typography.font(.body, weight: .medium))
                        .foregroundStyle(AppDesignTokens.Colors.textSecondary)
                    if !bean.origin.isEmpty || !bean.process.isEmpty {
                        Text([bean.origin, bean.process].filter { !$0.isEmpty }.joined(separator: " · "))
                            .font(AppDesignTokens.Typography.font(.caption, weight: .medium))
                            .foregroundStyle(AppDesignTokens.Colors.textSecondary)
                    }
                }
            } else {
                Text("未選択でもプランは作れます。豆を選ぶと焙煎度の初期値に反映されます。")
                    .font(AppDesignTokens.Typography.font(.body, weight: .medium))
                    .foregroundStyle(AppDesignTokens.Colors.textSecondary)
            }
        }
    }

    private var plannerInputCard: some View {
        cardContainer {
            cardHeader(systemImage: "slider.horizontal.below.rectangle", title: "入力")

            capsuleStepper(
                title: "豆量",
                valueText: "\(coffeeDoseLabel(store.currentInput.coffeeDose)) g",
                isMinusEnabled: store.canDecreaseCoffeeDose,
                isPlusEnabled: store.canIncreaseCoffeeDose,
                onMinusTap: { store.decrementCoffeeDose() },
                onPlusTap: { store.incrementCoffeeDose() }
            )

            plannerChoiceGroup(
                title: "味わい",
                note: "前半40%の注ぎ方を調整"
            ) {
                ForEach(tasteOptions, id: \.self) { profile in
                    choiceButton(
                        title: profile.displayName,
                        caption: profile.shortNote,
                        isSelected: store.currentInput.tasteProfile == profile
                    ) {
                        store.updateTasteProfile(profile)
                    }
                }
            }

            plannerChoiceGroup(
                title: "濃度",
                note: "比率と推奨挽き目をまとめて調整"
            ) {
                ForEach(concentrationOptions) { option in
                    choiceButton(
                        title: option.title,
                        caption: option.caption,
                        isSelected: store.currentInput.grindSize == option.grind
                    ) {
                        store.updateGrindSize(option.grind)
                    }
                }
            }

            plannerChoiceGroup(
                title: "焙煎度",
                note: "湯温と時間目安の基準に使用"
            ) {
                ForEach(roastOptions, id: \.self) { roast in
                    choiceButton(
                        title: roast.displayName,
                        isSelected: store.currentInput.roastLevel == roast
                    ) {
                        store.updateRoastLevel(roast)
                    }
                }
            }
        }
    }

    private var calculatedPlanCard: some View {
        cardContainer {
            cardHeader(systemImage: "wand.and.stars.inverse", title: "算出結果")

            Text("入力を変えると総湯量・比率・挽き目・時間目安が即時更新されます。")
                .font(AppDesignTokens.Typography.font(.caption, weight: .medium))
                .foregroundStyle(AppDesignTokens.Colors.textSecondary)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                alignment: .leading,
                spacing: 12
            ) {
                resultMetric(title: "総湯量", value: "\(currentPlan.totalWater) g")
                resultMetric(title: "比率", value: ratioLabel(currentPlan.ratio))
                resultMetric(title: "推奨挽き目", value: store.currentInput.grindSize.displayName)
                resultMetric(title: "時間目安", value: PourStep.timeLabel(from: currentPlan.estimatedTotalSeconds))
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("湯温")
                    .font(AppDesignTokens.Typography.font(.title3, weight: .semibold))
                    .foregroundStyle(AppDesignTokens.Colors.headingAccent)
                Text("\(currentPlan.recommendedTemperature)℃")
                    .font(AppDesignTokens.Typography.font(.title2, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(AppDesignTokens.Colors.totalWaterBackground)
            .overlay {
                Capsule()
                    .stroke(AppDesignTokens.Colors.totalWaterBorder, lineWidth: 1)
            }
            .clipShape(Capsule())

            Text(currentPlan.plannerMemo)
                .font(AppDesignTokens.Typography.font(.body, weight: .medium))
                .foregroundStyle(AppDesignTokens.Colors.textSecondary)
        }
    }

    private var scheduleCard: some View {
        cardContainer {
            cardHeader(systemImage: "drop.circle.fill", title: "6投レシピ")

            ForEach(currentPlan.steps) { step in
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(AppDesignTokens.Colors.timerStepBadgeBackground)
                        Circle()
                            .stroke(AppDesignTokens.Colors.timerStepBadgeBorder, lineWidth: 1)
                        Text("\(step.id)")
                            .font(AppDesignTokens.Typography.font(.title3, weight: .bold))
                            .foregroundStyle(AppDesignTokens.Colors.headingAccent)
                    }
                    .frame(width: 42, height: 42)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(step.phase.displayName) · \(step.amountGrams)g")
                            .font(AppDesignTokens.Typography.font(.title3, weight: .bold))
                            .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                        Text("開始 \(step.startLabel) / 待ち \(step.waitSeconds)s / 累計 \(step.cumulativeGrams)g")
                            .font(AppDesignTokens.Typography.font(.caption, weight: .medium))
                            .foregroundStyle(AppDesignTokens.Colors.textSecondary)
                    }

                    Spacer()
                }

                if step.id != currentPlan.steps.count {
                    Divider().overlay(AppDesignTokens.Colors.controlBorder)
                }
            }
        }
    }

    private var recommendationPlaceholderCard: some View {
        cardContainer {
            HStack {
                cardHeader(systemImage: "sparkles", title: "おすすめ")
                Spacer()
                beanBadge(text: "Coming Soon")
            }

            Text("抽出ログが蓄積したら、この豆に合う比率・挽き目・時間を後続フェーズで提案します。")
                .font(AppDesignTokens.Typography.font(.body, weight: .medium))
                .foregroundStyle(AppDesignTokens.Colors.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("将来の提案例")
                    .font(AppDesignTokens.Typography.font(.caption, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textSecondary)
                Text("甘さ寄り / 1:16 / 粗挽き / 3:00")
                    .font(AppDesignTokens.Typography.font(.title3, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppDesignTokens.Colors.controlBackground)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppDesignTokens.Colors.controlBorder, style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var timerCTA: some View {
        Button {
            store.selectedTab = .assistant
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "timer")
                Text("このレシピでタイマーを開く")
            }
            .font(AppDesignTokens.Typography.font(.title2, weight: .bold))
            .foregroundStyle(AppDesignTokens.Colors.ctaText)
            .frame(maxWidth: .infinity)
            .frame(height: 82)
            .background(AppDesignTokens.Colors.ctaBackground)
            .clipShape(Capsule())
            .shadow(color: AppDesignTokens.Colors.coffee5.opacity(0.35), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }

    private func cardContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            content()
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppDesignTokens.Colors.cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: AppDesignTokens.Radius.card, style: .continuous)
                .stroke(AppDesignTokens.Colors.cardBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppDesignTokens.Radius.card, style: .continuous))
        .shadow(color: AppDesignTokens.Colors.cardShadow, radius: 22, x: 0, y: 14)
    }

    private func cardHeader(systemImage: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(AppDesignTokens.Typography.font(.title3, weight: .bold))
                .foregroundStyle(AppDesignTokens.Colors.headingAccent)
            Text(title)
                .font(AppDesignTokens.Typography.font(.title2, weight: .bold))
                .foregroundStyle(AppDesignTokens.Colors.textPrimary)
        }
    }

    private func capsuleStepper(
        title: String,
        valueText: String,
        isMinusEnabled: Bool,
        isPlusEnabled: Bool,
        onMinusTap: @escaping () -> Void,
        onPlusTap: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppDesignTokens.Typography.font(.title3, weight: .semibold))
                .foregroundStyle(AppDesignTokens.Colors.textSecondary)

            HStack {
                stepperButton(symbol: "minus", isEnabled: isMinusEnabled, action: onMinusTap)
                Spacer()
                Text(valueText)
                    .font(AppDesignTokens.Typography.font(.largeTitle, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                Spacer()
                stepperButton(symbol: "plus", isEnabled: isPlusEnabled, action: onPlusTap)
            }
            .padding(.horizontal, 16)
            .frame(height: 76)
            .background(AppDesignTokens.Colors.controlBackground)
            .overlay {
                Capsule()
                    .stroke(AppDesignTokens.Colors.controlBorder, lineWidth: 1)
            }
            .clipShape(Capsule())
        }
    }

    private func stepperButton(symbol: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(AppDesignTokens.Colors.secondaryButtonBackground)
                Circle()
                    .stroke(AppDesignTokens.Colors.controlBorder, lineWidth: 1)
                Image(systemName: symbol)
                    .font(AppDesignTokens.Typography.font(.title2, weight: .medium))
                    .foregroundStyle(
                        isEnabled
                        ? AppDesignTokens.Colors.textPrimary
                        : AppDesignTokens.Colors.textSecondary
                    )
            }
            .frame(width: 52, height: 52)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
    }

    private func plannerChoiceGroup<Content: View>(
        title: String,
        note: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppDesignTokens.Typography.font(.title3, weight: .semibold))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                Text(note)
                    .font(AppDesignTokens.Typography.font(.caption, weight: .medium))
                    .foregroundStyle(AppDesignTokens.Colors.textSecondary)
            }

            HStack(spacing: 8) {
                content()
            }
        }
    }

    private func choiceButton(
        title: String,
        caption: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(AppDesignTokens.Typography.font(.title3, weight: .bold))
                if let caption {
                    Text(caption)
                        .font(AppDesignTokens.Typography.font(.caption, weight: .medium))
                }
            }
            .foregroundStyle(
                isSelected
                ? AppDesignTokens.Colors.textPrimary
                : AppDesignTokens.Colors.textSecondary
            )
            .frame(maxWidth: .infinity)
            .frame(minHeight: 66)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        isSelected
                        ? AppDesignTokens.Colors.activeSegment
                        : AppDesignTokens.Colors.controlBackground
                    )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppDesignTokens.Colors.controlBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func resultMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppDesignTokens.Typography.font(.caption, weight: .bold))
                .foregroundStyle(AppDesignTokens.Colors.textSecondary)
            Text(value)
                .font(AppDesignTokens.Typography.font(.title2, weight: .bold))
                .foregroundStyle(AppDesignTokens.Colors.textPrimary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppDesignTokens.Colors.controlBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppDesignTokens.Colors.controlBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func beanBadge(text: String) -> some View {
        Text(text)
            .font(AppDesignTokens.Typography.font(.caption, weight: .bold))
            .foregroundStyle(AppDesignTokens.Colors.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppDesignTokens.Colors.controlBackground)
            .overlay {
                Capsule()
                    .stroke(AppDesignTokens.Colors.controlBorder, lineWidth: 1)
            }
            .clipShape(Capsule())
    }

    private func coffeeDoseLabel(_ dose: Double) -> String {
        let rounded = (dose * 2).rounded() / 2
        if abs(rounded.rounded() - rounded) < 0.001 {
            return String(Int(rounded))
        }
        return String(format: "%.1f", rounded)
    }

    private func ratioLabel(_ ratio: Double) -> String {
        if abs(ratio.rounded() - ratio) < 0.001 {
            return "1 : \(Int(ratio.rounded()))"
        }
        return String(format: "1 : %.1f", ratio)
    }
}

private struct ConcentrationOption: Identifiable {
    let grind: GrindSize
    let title: String
    let caption: String

    var id: GrindSize { grind }

    static let options: [ConcentrationOption] = [
        ConcentrationOption(grind: .coarse, title: "薄め", caption: "さらっと軽い"),
        ConcentrationOption(grind: .medium, title: "普通", caption: "基準のバランス"),
        ConcentrationOption(grind: .fine, title: "濃い", caption: "厚みを出す")
    ]
}

#Preview {
    HomeView()
        .environment(AppStore.preview)
}
