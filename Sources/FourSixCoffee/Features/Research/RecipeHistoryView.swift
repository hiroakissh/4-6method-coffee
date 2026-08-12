import SwiftUI

struct RecipeHistoryView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var model: RecipeHistoryModel

    init(recipe: BrewRecipe) {
        _model = State(initialValue: RecipeHistoryModel(recipe: recipe))
    }

    var body: some View {
        NavigationStack {
            List {
                if model.revisions.isEmpty {
                    ContentUnavailableView(
                        "履歴がありません",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("レシピを保存すると変更履歴が残ります。")
                    )
                } else {
                    Section("保存済みの版") {
                        ForEach(model.revisions) { revision in
                            revisionRow(revision)
                        }
                    }

                    if let selectedRevision = model.selectedRevision {
                        Section("版の内容") {
                            revisionSummary(selectedRevision)
                            if let diff = model.diff(for: selectedRevision), !diff.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("直前の版からの変更")
                                        .appTextStyle(.itemTitle)
                                        .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                                    ForEach(diff.changes) { change in
                                        VStack(alignment: .leading, spacing: 2) {
                                            Label(change.field, systemImage: "checkmark.circle")
                                                .appTextStyle(.supportingStrong)
                                                .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                                            Text("v\(diff.fromVersion): \(change.before)")
                                                .appTextStyle(.supporting)
                                                .foregroundStyle(AppDesignTokens.Colors.textSecondary)
                                            Text("v\(diff.toVersion): \(change.after)")
                                                .appTextStyle(.supporting)
                                                .foregroundStyle(AppDesignTokens.Colors.headingAccent)
                                        }
                                    }
                                }
                            } else if selectedRevision.version == 1 {
                                Text("初回保存の版です")
                                    .appTextStyle(.supporting)
                                    .foregroundStyle(AppDesignTokens.Colors.textSecondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("履歴: \(model.recipeName)")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .onAppear { model.load(using: store) }
        }
    }

    private func revisionRow(_ revision: RecipeRevision) -> some View {
        Button {
            model.selectedRevisionID = revision.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("v\(revision.version)")
                        .appTextStyle(.itemTitle)
                        .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                    Text(revision.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .appTextStyle(.supporting)
                        .foregroundStyle(AppDesignTokens.Colors.textSecondary)
                    Text("\(revision.recipe.phases.count)フェーズ · \(revision.recipe.phases.flatMap(\.pours).count)アクション · \(revision.recipe.defaults.totalWaterGrams)g")
                        .appTextStyle(.supporting)
                        .foregroundStyle(AppDesignTokens.Colors.textSecondary)
                }
                Spacer()
                if model.selectedRevisionID == revision.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func revisionSummary(_ revision: RecipeRevision) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            summaryRow(label: "レシピ名", value: revision.recipe.metadata.name)
            summaryRow(label: "器具", value: revision.recipe.metadata.device)
            summaryRow(label: "豆量", value: String(format: "%.1fg", revision.recipe.defaults.coffeeDoseGrams))
            summaryRow(label: "総湯量", value: "\(revision.recipe.defaults.totalWaterGrams)g")
            summaryRow(label: "タグ", value: revision.recipe.metadata.tags.joined(separator: "・").isEmpty ? "なし" : revision.recipe.metadata.tags.joined(separator: "・"))
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .appTextStyle(.supporting)
                .foregroundStyle(AppDesignTokens.Colors.textSecondary)
            Spacer()
            Text(value)
                .appTextStyle(.supportingStrong)
                .foregroundStyle(AppDesignTokens.Colors.textPrimary)
        }
    }
}

#Preview {
    RecipeHistoryView(recipe: AppStore.preview.recipes[0])
        .environment(AppStore.preview)
}
