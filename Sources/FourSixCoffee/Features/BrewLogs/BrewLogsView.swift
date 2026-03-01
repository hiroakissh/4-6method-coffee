import SwiftUI

struct BrewLogsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        NavigationStack {
            List {
                if store.brewLogs.isEmpty {
                    ContentUnavailableView(
                        "履歴がありません",
                        systemImage: "book.closed",
                        description: Text("タイマー画面で抽出を保存するとここに表示されます。")
                    )
                } else {
                    ForEach(store.brewLogs) { log in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(log.bean?.name ?? "Bean Unknown")
                                    .font(.headline)
                                Spacer()
                                Text(log.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Text("豆量 \(log.input.coffeeDose, specifier: "%.1f")g · \(log.input.tasteProfile.displayName) · \(log.input.roastLevel.displayName)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("総湯量 \(log.plan.totalWater)g / 湯温 \(log.plan.recommendedTemperature)℃ / 実測 \(PourStep.timeLabel(from: log.actualBrewSeconds))")
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(.secondary)

                            if !log.memo.isEmpty {
                                Text(log.memo)
                                    .font(.footnote)
                            }

                            ratingRow(log.ratings)
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button("再利用") {
                                store.apply(log: log)
                                store.selectedTab = .planner
                            }
                            .tint(.blue)
                        }
                    }
                    .onDelete(perform: store.deleteLogs)
                }
            }
            .navigationTitle("抽出履歴")
            .toolbar {
                EditButton()
            }
        }
    }

    private func ratingRow(_ ratings: TasteRatings) -> some View {
        HStack(spacing: 8) {
            metric(label: "甘", value: ratings.sweetness)
            metric(label: "酸", value: ratings.acidity)
            metric(label: "苦", value: ratings.bitterness)
            metric(label: "コク", value: ratings.body)
            metric(label: "余韻", value: ratings.aftertaste)
        }
    }

    private func metric(label: String, value: Int) -> some View {
        Text("\(label) \(value)")
            .font(.caption.monospacedDigit())
            .padding(.vertical, 3)
            .padding(.horizontal, 8)
            .background(Color.secondary.opacity(0.12))
            .clipShape(Capsule())
    }
}

#Preview {
    BrewLogsView()
        .environment(AppStore())
}
