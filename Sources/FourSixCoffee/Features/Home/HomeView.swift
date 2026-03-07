import Foundation
import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        NavigationStack {
            ZStack {
                plannerBackground

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        basicSettingsCard
                        tasteAdjustmentCard
                        strengthAdjustmentCard
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
            Text("プランナー")
                .font(AppDesignTokens.Typography.font(.title2, weight: .bold))
                .foregroundStyle(AppDesignTokens.Colors.textPrimary)
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

    private var basicSettingsCard: some View {
        cardContainer {
            cardHeader(systemImage: "scalemass.fill", title: "基本設定")

            capsuleStepper(
                title: "豆の量 (G)",
                valueText: coffeeDoseLabel(store.currentInput.coffeeDose),
                isMinusEnabled: store.canDecreaseCoffeeDose,
                isPlusEnabled: store.canIncreaseCoffeeDose,
                onMinusTap: { store.decrementCoffeeDose() },
                onPlusTap: { store.incrementCoffeeDose() }
            )

            capsuleStepper(
                title: "比率 (豆 : 湯) · 焙煎 \(store.currentInput.roastLevel.displayName)",
                valueText: ratioLabel(store.currentPlan.ratio),
                isMinusEnabled: store.canDecreaseRatio,
                isPlusEnabled: store.canIncreaseRatio,
                onMinusTap: { store.decreaseRatio() },
                onPlusTap: { store.increaseRatio() }
            )

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("総湯量")
                    .font(AppDesignTokens.Typography.font(.title3, weight: .semibold))
                    .foregroundStyle(AppDesignTokens.Colors.coffee1)
                Spacer()
                Text("\(store.currentPlan.totalWater)")
                    .font(AppDesignTokens.Typography.font(.largeTitle, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                Text("g")
                    .font(AppDesignTokens.Typography.font(.title3, weight: .medium))
                    .foregroundStyle(AppDesignTokens.Colors.textSecondary)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            .background(AppDesignTokens.Colors.totalWaterBackground)
            .overlay {
                Capsule()
                    .stroke(AppDesignTokens.Colors.totalWaterBorder, lineWidth: 1)
            }
            .clipShape(Capsule())
        }
    }

    private var tasteAdjustmentCard: some View {
        cardContainer {
            cardHeader(systemImage: "slider.horizontal.3", title: "味わいの調整 (最初の40%)")

            HStack {
                Text("甘み")
                Spacer()
                Text(tasteLabel(for: store.currentInput.tasteProfile))
                    .foregroundStyle(AppDesignTokens.Colors.tasteAccent)
                Spacer()
                Text("酸味")
            }
            .font(AppDesignTokens.Typography.font(.title3, weight: .semibold))
            .foregroundStyle(AppDesignTokens.Colors.textSecondary)

            Slider(value: tasteProfileSliderBinding, in: 0...2, step: 1)
                .tint(AppDesignTokens.Colors.sliderAccent)

            HStack {
                pourAmountColumn(title: "第1投", amount: stepAmount(at: 0), alignment: .leading)
                Spacer()
                pourAmountColumn(title: "第2投", amount: stepAmount(at: 1), alignment: .trailing)
            }
        }
    }

    private var strengthAdjustmentCard: some View {
        cardContainer {
            cardHeader(systemImage: "drop.fill", title: "濃さの調整 (残りの60%)")

            HStack(spacing: 6) {
                ForEach(StrengthOption.options) { option in
                    let isSelected = store.currentInput.grindSize == option.grind
                    Button {
                        store.updateGrindSize(option.grind)
                    } label: {
                        Text(option.title)
                            .font(AppDesignTokens.Typography.font(.title3, weight: .bold))
                            .foregroundStyle(
                                isSelected
                                ? AppDesignTokens.Colors.textPrimary
                                : AppDesignTokens.Colors.textSecondary
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                Capsule().fill(
                                    isSelected
                                    ? AppDesignTokens.Colors.activeSegment
                                    : .clear
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(5)
            .background(AppDesignTokens.Colors.controlBackground)
            .overlay {
                Capsule()
                    .stroke(AppDesignTokens.Colors.controlBorder, lineWidth: 1)
            }
            .clipShape(Capsule())

            HStack(spacing: 0) {
                strengthPourColumn(title: "第3投", amount: stepAmount(at: 2))
                Divider().overlay(AppDesignTokens.Colors.controlBorder)
                strengthPourColumn(title: "第4投", amount: stepAmount(at: 3))
                Divider().overlay(AppDesignTokens.Colors.controlBorder)
                strengthPourColumn(title: "第5投", amount: stepAmount(at: 4))
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var timerCTA: some View {
        Button {
            store.selectedTab = .assistant
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "timer")
                Text("タイマーを開く")
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

    private func pourAmountColumn(title: String, amount: Int, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 6) {
            Text(title)
                .font(AppDesignTokens.Typography.font(.title3, weight: .medium))
                .foregroundStyle(AppDesignTokens.Colors.textSecondary)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(amount)")
                    .font(AppDesignTokens.Typography.font(.largeTitle, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                Text("g")
                    .font(AppDesignTokens.Typography.font(.title3, weight: .medium))
                    .foregroundStyle(AppDesignTokens.Colors.textSecondary)
            }
        }
    }

    private func strengthPourColumn(title: String, amount: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppDesignTokens.Typography.font(.title3, weight: .medium))
                .foregroundStyle(AppDesignTokens.Colors.textSecondary)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(amount)")
                    .font(AppDesignTokens.Typography.font(.largeTitle, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                Text("g")
                    .font(AppDesignTokens.Typography.font(.title3, weight: .medium))
                    .foregroundStyle(AppDesignTokens.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tasteProfileSliderBinding: Binding<Double> {
        Binding {
            Double(TasteProfile.allCases.firstIndex(of: store.currentInput.tasteProfile) ?? 1)
        } set: { newValue in
            let index = Int(newValue.rounded())
            guard TasteProfile.allCases.indices.contains(index) else { return }
            store.updateTasteProfile(TasteProfile.allCases[index])
        }
    }

    private func stepAmount(at index: Int) -> Int {
        guard store.currentPlan.steps.indices.contains(index) else { return 0 }
        return store.currentPlan.steps[index].amountGrams
    }

    private func coffeeDoseLabel(_ dose: Double) -> String {
        let rounded = (dose * 2).rounded() / 2
        if abs(rounded.rounded() - rounded) < 0.001 {
            return String(Int(rounded))
        }
        return String(format: "%.1f", rounded)
    }

    private func ratioLabel(_ ratio: Double) -> String {
        let rounded = (ratio * 10).rounded() / 10
        if abs(rounded.rounded() - rounded) < 0.001 {
            return "1 : \(Int(rounded))"
        }
        return String(format: "1 : %.1f", rounded)
    }

    private func tasteLabel(for profile: TasteProfile) -> String {
        switch profile {
        case .sweet:
            return "甘め"
        case .balanced:
            return "標準"
        case .light:
            return "酸味寄り"
        }
    }
}

private struct StrengthOption: Identifiable {
    let grind: GrindSize
    let title: String

    var id: GrindSize { grind }

    static let options: [StrengthOption] = [
        StrengthOption(grind: .coarse, title: "軽め (2回)"),
        StrengthOption(grind: .medium, title: "標準 (3回)"),
        StrengthOption(grind: .fine, title: "濃いめ (4回)")
    ]
}

#Preview {
    HomeView()
        .environment(AppStore.preview)
}
