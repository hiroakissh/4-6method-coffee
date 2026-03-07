import SwiftUI

struct BeansView: View {
    @Environment(AppStore.self) private var store
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                beansBackground

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        header

                        if store.beans.isEmpty {
                            emptyCard
                        } else {
                            ForEach(store.beans) { bean in
                                NavigationLink {
                                    BeanProfileView(beanID: bean.id)
                                } label: {
                                    beanCard(bean)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        delete(beanID: bean.id)
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddSheet) {
                AddBeanSheet()
            }
        }
    }

    private var beansBackground: some View {
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
                center: .bottomLeading,
                startRadius: 30,
                endRadius: 360
            )
        }
        .overlay {
            RadialGradient(
                colors: [
                    AppDesignTokens.Colors.coffee4.opacity(0.2),
                    .clear
                ],
                center: .topTrailing,
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
                    .frame(width: 60, height: 60)
                    .background(AppDesignTokens.Colors.secondaryButtonBackground)
                    .overlay {
                        Circle()
                            .stroke(AppDesignTokens.Colors.controlBorder, lineWidth: 1)
                    }
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()
            Text("コーヒー豆")
                .font(AppDesignTokens.Typography.font(.largeTitle, weight: .bold))
                .foregroundStyle(AppDesignTokens.Colors.textPrimary)
            Spacer()

            Button {
                showingAddSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(AppDesignTokens.Typography.font(.largeTitle, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.headingAccent)
                    .frame(width: 60, height: 60)
                    .background(AppDesignTokens.Colors.timerStepBadgeBackground)
                    .overlay {
                        Circle()
                            .stroke(AppDesignTokens.Colors.timerStepBadgeBorder, lineWidth: 1)
                    }
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private func beanCard(_ bean: Bean) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(bean.name)
                    .font(AppDesignTokens.Typography.font(.largeTitle, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                beanBadge(text: bean.roastLevel.displayName)
            }

            Divider()
                .overlay(AppDesignTokens.Colors.controlBorder)
                .padding(.vertical, 2)

            if !beanMetadata(for: bean).isEmpty {
                Text(beanMetadata(for: bean))
                    .font(AppDesignTokens.Typography.font(.title3, weight: .medium))
                    .foregroundStyle(AppDesignTokens.Colors.textSecondary)
            }

            HStack(spacing: 8) {
                Text("登録日")
                    .font(AppDesignTokens.Typography.font(.caption, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textSecondary)
                Text(bean.purchasedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(AppDesignTokens.Typography.font(.title3, weight: .semibold))
                    .foregroundStyle(AppDesignTokens.Colors.headingAccent)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppDesignTokens.Colors.cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: AppDesignTokens.Radius.card, style: .continuous)
                .stroke(AppDesignTokens.Colors.cardBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppDesignTokens.Radius.card, style: .continuous))
        .shadow(color: AppDesignTokens.Colors.cardShadow, radius: 22, x: 0, y: 12)
    }

    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("豆がまだ登録されていません")
                .font(AppDesignTokens.Typography.font(.title2, weight: .bold))
                .foregroundStyle(AppDesignTokens.Colors.textPrimary)
            Text("右上の + から豆を追加できます")
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

    private func delete(beanID: UUID) {
        guard let index = store.beans.firstIndex(where: { $0.id == beanID }) else { return }
        store.deleteBeans(at: IndexSet(integer: index))
    }

    private func beanMetadata(for bean: Bean) -> String {
        [bean.shopName, bean.origin, bean.process]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
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
}

private struct BeanProfileView: View {
    @Environment(AppStore.self) private var store

    let beanID: UUID

    var body: some View {
        if let bean = store.beans.first(where: { $0.id == beanID }) {
            List {
                Section("豆情報") {
                    LabeledContent("豆名", value: bean.name)
                    LabeledContent("店名", value: bean.shopName.isEmpty ? "未設定" : bean.shopName)
                    LabeledContent("購入日", value: bean.purchasedAt.formatted(date: .abbreviated, time: .omitted))
                    LabeledContent("産地", value: bean.origin.isEmpty ? "未設定" : bean.origin)
                    LabeledContent("プロセス", value: bean.process.isEmpty ? "未設定" : bean.process)
                    LabeledContent("焙煎度", value: bean.roastLevel.displayName)
                    LabeledContent("焙煎日", value: bean.roastDate?.formatted(date: .abbreviated, time: .omitted) ?? "未設定")
                    LabeledContent("URL", value: bean.referenceURL.isEmpty ? "未設定" : bean.referenceURL)
                    LabeledContent("メモ", value: bean.notes.isEmpty ? "未設定" : bean.notes)
                }

                Section("抽出メモ") {
                    let logs = store.logs(for: bean.id)
                    if logs.isEmpty {
                        Text("この豆の抽出ログはまだありません")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(logs) { log in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(log.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Text("豆量 \(log.input.coffeeDose, specifier: "%.1f")g · \(log.input.tasteProfile.displayName)")
                                    .font(.subheadline)
                                Text(
                                    "\(log.ratings.tasteFeedbackSummary.displayName) / \(log.ratings.strengthFeedbackSummary.displayName) / \(log.ratings.overallFeedbackSummary.displayName)"
                                )
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                if !log.memo.isEmpty {
                                    Text(log.memo)
                                        .font(.footnote)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle("豆プロファイル")
            .fontDesign(AppDesignTokens.Typography.design)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(store.selectedBeanID == bean.id ? "選択中" : "この豆を使う") {
                        store.selectedBean = bean
                    }
                    .disabled(store.selectedBeanID == bean.id)
                }
            }
        } else {
            ContentUnavailableView("豆が見つかりません", systemImage: "exclamationmark.triangle")
        }
    }
}

private struct AddBeanSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var showingOptionalDetails = false
    @State private var shopName = ""
    @State private var purchasedAt = Date.now
    @State private var origin = ""
    @State private var process = ""
    @State private var roastLevel: RoastLevel = .medium
    @State private var roastDate: Date?
    @State private var referenceURL = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("まずは豆名と焙煎度だけで追加できます。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    TextField("豆名", text: $name)

                    Picker("焙煎度", selection: $roastLevel) {
                        ForEach(RoastLevel.allCases) { roast in
                            Text(roast.displayName).tag(roast)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    DisclosureGroup("詳細も記録する", isExpanded: $showingOptionalDetails) {
                        TextField("店名（任意）", text: $shopName)
                        DatePicker("購入日（任意）", selection: $purchasedAt, displayedComponents: .date)
                        TextField("産地（任意）", text: $origin)
                        TextField("プロセス（任意）", text: $process)
                        DatePicker("焙煎日（任意）", selection: roastDateBinding, displayedComponents: .date)
                        TextField("URL（任意）", text: $referenceURL)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                        TextField("メモ（任意）", text: $notes, axis: .vertical)
                    }
                }
            }
            .navigationTitle("豆を追加")
            .fontDesign(AppDesignTokens.Typography.design)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        store.addBean(
                            name: trimmedName,
                            shopName: shopName,
                            purchasedAt: purchasedAt,
                            origin: origin,
                            process: process,
                            roastLevel: roastLevel,
                            notes: notes,
                            roastDate: roastDate,
                            referenceURL: referenceURL.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var roastDateBinding: Binding<Date> {
        Binding(
            get: { roastDate ?? purchasedAt },
            set: { roastDate = $0 }
        )
    }
}

#Preview {
    BeansView()
        .environment(AppStore.preview)
}
