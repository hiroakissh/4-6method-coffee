import SwiftUI

struct BrewLogsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        NavigationStack {
            ZStack {
                logsBackground

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        header

                        if store.brewLogs.isEmpty {
                            emptyCard
                        } else {
                            ForEach(store.brewLogs) { log in
                                logCard(log)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var logsBackground: some View {
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
                endRadius: 320
            )
        }
        .overlay {
            RadialGradient(
                colors: [
                    AppDesignTokens.Colors.coffee4.opacity(0.18),
                    .clear
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 320
            )
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack {
            Button {
                store.selectedTab = .planner
            } label: {
                Image(systemName: "arrow.left")
                    .font(AppDesignTokens.Typography.font(.title2, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                    .frame(width: 56, height: 56)
                    .background(AppDesignTokens.Colors.secondaryButtonBackground)
                    .overlay {
                        Circle()
                            .stroke(AppDesignTokens.Colors.controlBorder, lineWidth: 1)
                    }
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()
            Text("抽出履歴")
                .font(AppDesignTokens.Typography.font(.largeTitle, weight: .bold))
                .foregroundStyle(AppDesignTokens.Colors.textPrimary)
            Spacer()

            Circle()
                .fill(.clear)
                .frame(width: 56, height: 56)
        }
    }

    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("履歴がありません")
                .font(AppDesignTokens.Typography.font(.title2, weight: .bold))
                .foregroundStyle(AppDesignTokens.Colors.textPrimary)
            Text("タイマー画面で抽出を保存するとここに表示されます。")
                .font(AppDesignTokens.Typography.font(.title3, weight: .medium))
                .foregroundStyle(AppDesignTokens.Colors.textSecondary)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppDesignTokens.Colors.cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: AppDesignTokens.Radius.card, style: .continuous)
                .stroke(AppDesignTokens.Colors.cardBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppDesignTokens.Radius.card, style: .continuous))
    }

    private func logCard(_ log: BrewLog) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(log.bean?.name ?? "Bean Unknown")
                    .font(AppDesignTokens.Typography.font(.title2, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                Spacer()
                Text(log.date.formatted(date: .abbreviated, time: .shortened))
                    .font(AppDesignTokens.Typography.font(.caption, weight: .semibold))
                    .foregroundStyle(AppDesignTokens.Colors.textSecondary)
            }

            Text("豆量 \(log.input.coffeeDose, specifier: "%.1f")g · \(log.input.tasteProfile.displayName) · \(log.input.roastLevel.displayName)")
                .font(AppDesignTokens.Typography.font(.title3, weight: .medium))
                .foregroundStyle(AppDesignTokens.Colors.textSecondary)

            Text("総湯量 \(log.plan.totalWater)g / 湯温 \(log.plan.recommendedTemperature)℃ / 実測 \(PourStep.timeLabel(from: log.actualBrewSeconds))")
                .font(AppDesignTokens.Typography.font(.caption, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(AppDesignTokens.Colors.textSecondary)

            if !log.memo.isEmpty {
                Text(log.memo)
                    .font(AppDesignTokens.Typography.font(.title3, weight: .medium))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
            }

            feedbackSummaryRow(log.ratings)

            HStack(spacing: 10) {
                Button {
                    store.apply(log: log)
                    store.selectedTab = .planner
                } label: {
                    Text("再利用")
                        .font(AppDesignTokens.Typography.font(.title3, weight: .bold))
                        .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(AppDesignTokens.Colors.controlBackground)
                        .overlay {
                            Capsule().stroke(AppDesignTokens.Colors.controlBorder, lineWidth: 1)
                        }
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button(role: .destructive) {
                    delete(logID: log.id)
                } label: {
                    Text("削除")
                        .font(AppDesignTokens.Typography.font(.title3, weight: .bold))
                        .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(AppDesignTokens.Colors.coffee1.opacity(0.76))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
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

    private func delete(logID: UUID) {
        guard let index = store.brewLogs.firstIndex(where: { $0.id == logID }) else { return }
        store.deleteLogs(at: IndexSet(integer: index))
    }

    private func feedbackSummaryRow(_ ratings: TasteRatings) -> some View {
        HStack(spacing: 8) {
            metric(label: "味", value: ratings.tasteFeedbackSummary.displayName)
            metric(label: "濃度", value: ratings.strengthFeedbackSummary.displayName)
            metric(label: "評価", value: ratings.overallFeedbackSummary.displayName)
        }
    }

    private func metric(label: String, value: String) -> some View {
        Text("\(label) \(value)")
            .font(AppDesignTokens.Typography.font(.caption, weight: .bold))
            .foregroundStyle(AppDesignTokens.Colors.textPrimary)
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(AppDesignTokens.Colors.controlBackground)
            .overlay {
                Capsule().stroke(AppDesignTokens.Colors.controlBorder, lineWidth: 1)
            }
            .clipShape(Capsule())
    }
}

#Preview {
    BrewLogsView()
        .environment(AppStore.preview)
}
