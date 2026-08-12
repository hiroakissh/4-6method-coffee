import SwiftUI

struct ResearchView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showingNewEditor = false
    @State private var editingRecipe: BrewRecipe?

    var body: some View {
        NavigationStack {
            ZStack {
                researchBackground

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if store.recipes.isEmpty {
                            emptyState
                        } else {
                            ForEach(store.recipes) { recipe in
                                recipeCard(recipe)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Research")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("レシピを追加")
                }
            }
            .sheet(isPresented: $showingNewEditor) {
                RecipeEditorView()
            }
            .sheet(item: $editingRecipe) { recipe in
                RecipeEditorView(recipe: recipe)
            }
        }
        .presentationDetents([.large])
    }

    private var researchBackground: some View {
        LinearGradient(
            colors: [
                AppDesignTokens.Colors.backgroundTop,
                AppDesignTokens.Colors.backgroundBottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("レシピがありません")
                .appTextStyle(.sectionTitle)
                .foregroundStyle(AppDesignTokens.Colors.textPrimary)
            Text("右上の＋からResearchレシピを作成できます。")
                .appTextStyle(.supporting)
                .foregroundStyle(AppDesignTokens.Colors.textSecondary)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppDesignTokens.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppDesignTokens.Radius.card, style: .continuous))
    }

    private func recipeCard(_ recipe: BrewRecipe) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.metadata.name)
                        .appTextStyle(.sectionTitle)
                        .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                    Text("\(recipe.phases.count)フェーズ · \(recipe.phases.flatMap(\.pours).count)アクション · \(recipe.defaults.totalWaterGrams)g")
                        .appTextStyle(.supporting)
                        .foregroundStyle(AppDesignTokens.Colors.textSecondary)
                }
                Spacer()
                Text(recipe.metadata.sourceType == .preset ? "Preset" : "User")
                    .appTextStyle(.supportingStrong)
                    .foregroundStyle(AppDesignTokens.Colors.headingAccent)
            }

            HStack(spacing: 8) {
                Button("このレシピで抽出") {
                    store.startResearch(with: recipe)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)

                Button("編集") {
                    editingRecipe = recipe
                }
                .buttonStyle(.bordered)

                Menu {
                    Button("複製") {
                        _ = store.duplicateRecipe(recipe)
                    }
                    Button("削除", role: .destructive) {
                        store.deleteRecipe(recipe)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 32, height: 32)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppDesignTokens.Colors.cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: AppDesignTokens.Radius.card, style: .continuous)
                .stroke(AppDesignTokens.Colors.cardBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppDesignTokens.Radius.card, style: .continuous))
    }
}

struct RecipeEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var model: RecipeEditorModel

    init(recipe: BrewRecipe? = nil) {
        _model = State(initialValue: RecipeEditorModel(recipe: recipe))
    }

    var body: some View {
        @Bindable var bindableModel = model

        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("レシピ名", text: $bindableModel.recipe.metadata.name)
                    TextField("器具", text: $bindableModel.recipe.metadata.device)
                    Stepper(
                        "豆量 \(model.recipe.defaults.coffeeDoseGrams, specifier: "%.1f")g",
                        value: $bindableModel.recipe.defaults.coffeeDoseGrams,
                        in: 5...100,
                        step: 0.5
                    )
                    Stepper(
                        "総湯量 \(model.recipe.defaults.totalWaterGrams)g",
                        value: $bindableModel.recipe.defaults.totalWaterGrams,
                        in: 30...2000,
                        step: 5
                    )
                    Picker("挽き目", selection: $bindableModel.recipe.defaults.grindSize) {
                        ForEach(GrindSize.allCases) { grind in
                            Text(grind.displayName).tag(grind)
                        }
                    }
                }

                ForEach(Array(model.recipe.phases.indices), id: \.self) { phaseIndex in
                    Section("フェーズ: \(model.recipe.phases[phaseIndex].type.displayName)") {
                        Picker(
                            "種別",
                            selection: Binding(
                                get: { model.recipe.phases[phaseIndex].type },
                                set: { model.recipe.phases[phaseIndex].type = $0 }
                            )
                        ) {
                            ForEach([PhaseType.bloom, .extraction, .immersion, .bypass, .finish], id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }

                        Stepper(
                            "湯温 \(model.temperature(for: model.recipe.phases[phaseIndex].id))℃",
                            onIncrement: { model.adjustTemperature(phaseID: model.recipe.phases[phaseIndex].id, by: 1) },
                            onDecrement: { model.adjustTemperature(phaseID: model.recipe.phases[phaseIndex].id, by: -1) }
                        )

                        Picker(
                            "攪拌",
                            selection: Binding(
                                get: { model.agitation(for: model.recipe.phases[phaseIndex].id) },
                                set: { model.setAgitation($0, phaseID: model.recipe.phases[phaseIndex].id) }
                            )
                        ) {
                            ForEach([AgitationAction.none, .swirl, .stir, .tap], id: \.self) { action in
                                Text(action.displayName).tag(action)
                            }
                        }

                        ForEach(Array(model.recipe.phases[phaseIndex].pours.indices), id: \.self) { pourIndex in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("注湯")
                                        .appTextStyle(.itemTitle)
                                    Spacer()
                                    Button(role: .destructive) {
                                        model.removePour(
                                            phaseID: model.recipe.phases[phaseIndex].id,
                                            pourID: model.recipe.phases[phaseIndex].pours[pourIndex].id
                                        )
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                                Stepper(
                                    "開始 \(PourStep.timeLabel(from: model.recipe.phases[phaseIndex].pours[pourIndex].startSecond))",
                                    value: Binding(
                                        get: { model.recipe.phases[phaseIndex].pours[pourIndex].startSecond },
                                        set: { model.recipe.phases[phaseIndex].pours[pourIndex].startSecond = $0 }
                                    ),
                                    in: 0...3600,
                                    step: 5
                                )
                                Stepper(
                                    "注湯量 \(model.recipe.phases[phaseIndex].pours[pourIndex].amountGrams)g",
                                    value: Binding(
                                        get: { model.recipe.phases[phaseIndex].pours[pourIndex].amountGrams },
                                        set: { model.recipe.phases[phaseIndex].pours[pourIndex].amountGrams = $0 }
                                    ),
                                    in: 0...2000,
                                    step: 5
                                )
                                Stepper(
                                    "累計目標 \(model.recipe.phases[phaseIndex].pours[pourIndex].targetCumulativeGrams)g",
                                    value: Binding(
                                        get: { model.recipe.phases[phaseIndex].pours[pourIndex].targetCumulativeGrams },
                                        set: { model.recipe.phases[phaseIndex].pours[pourIndex].targetCumulativeGrams = $0 }
                                    ),
                                    in: 0...3000,
                                    step: 5
                                )
                                Picker(
                                    "流量",
                                    selection: Binding(
                                        get: { model.recipe.phases[phaseIndex].pours[pourIndex].flowRate },
                                        set: { model.recipe.phases[phaseIndex].pours[pourIndex].flowRate = $0 }
                                    )
                                ) {
                                    ForEach([FlowRate.low, .medium, .high], id: \.self) { rate in
                                        Text(rate.displayName).tag(rate)
                                    }
                                }
                                Picker(
                                    "注湯位置",
                                    selection: Binding(
                                        get: { model.recipe.phases[phaseIndex].pours[pourIndex].position },
                                        set: { model.recipe.phases[phaseIndex].pours[pourIndex].position = $0 }
                                    )
                                ) {
                                    ForEach([PourPosition.center, .circle, .edge], id: \.self) { position in
                                        Text(position.displayName).tag(position)
                                    }
                                }
                            }
                            .padding(.vertical, 6)
                        }

                        Button {
                            model.addPour(to: model.recipe.phases[phaseIndex].id)
                        } label: {
                            Label("注湯を追加", systemImage: "plus.circle")
                        }

                        if model.recipe.phases.count > 1 {
                            Button("このフェーズを削除", role: .destructive) {
                                model.removePhase(id: model.recipe.phases[phaseIndex].id)
                            }
                        }
                    }
                }

                Section {
                    Button {
                        model.addPhase()
                    } label: {
                        Label("フェーズを追加", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("レシピを編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if store.saveRecipe(model.recipe) {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ResearchView()
        .environment(AppStore.preview)
}
