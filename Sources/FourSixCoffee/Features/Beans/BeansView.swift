import SwiftUI

struct BeansView: View {
    @Environment(AppStore.self) private var store
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.beans) { bean in
                    NavigationLink {
                        BeanProfileView(beanID: bean.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(bean.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("購入店: \(bean.shopName)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text("購入日: \(bean.purchasedAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: store.deleteBeans)
            }
            .navigationTitle("豆")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddBeanSheet()
            }
        }
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
                    LabeledContent("店名", value: bean.shopName)
                    LabeledContent("購入日", value: bean.purchasedAt.formatted(date: .abbreviated, time: .omitted))
                    LabeledContent("産地/銘柄", value: bean.origin.isEmpty ? "未設定" : bean.origin)
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
    @State private var shopName = ""
    @State private var purchasedAt = Date.now
    @State private var origin = ""
    @State private var process = "Washed"
    @State private var roastLevel: RoastLevel = .medium
    @State private var roastDate: Date?
    @State private var referenceURL = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("豆名", text: $name)
                TextField("店名", text: $shopName)
                DatePicker("購入日", selection: $purchasedAt, displayedComponents: .date)

                TextField("産地/銘柄（任意）", text: $origin)
                TextField("プロセス（任意）", text: $process)
                DatePicker("焙煎日（任意）", selection: roastDateBinding, displayedComponents: .date)
                TextField("URL（任意）", text: $referenceURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                TextField("メモ（任意）", text: $notes, axis: .vertical)

                Picker("焙煎度", selection: $roastLevel) {
                    ForEach(RoastLevel.allCases) { roast in
                        Text(roast.displayName).tag(roast)
                    }
                }
            }
            .navigationTitle("豆を追加")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        store.addBean(
                            name: name.isEmpty ? "New Bean" : name,
                            shopName: shopName.isEmpty ? "Unknown Shop" : shopName,
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
                }
            }
        }
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
