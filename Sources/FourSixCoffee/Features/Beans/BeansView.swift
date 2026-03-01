import SwiftUI

struct BeansView: View {
    @Environment(AppStore.self) private var store
    @State private var showingAddSheet = false

    var body: some View {
        @Bindable var bindableStore = store

        NavigationStack {
            List {
                ForEach($bindableStore.beans) { bean in
                    Button {
                        store.selectedBean = bean.wrappedValue
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(bean.wrappedValue.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("\(bean.wrappedValue.roaster) · \(bean.wrappedValue.origin) · \(bean.wrappedValue.process)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Text("焙煎: \(bean.wrappedValue.roastLevel.displayName)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if store.selectedBeanID == bean.wrappedValue.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
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

private struct AddBeanSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var roaster = ""
    @State private var origin = ""
    @State private var process = "Washed"
    @State private var roastLevel: RoastLevel = .medium

    var body: some View {
        NavigationStack {
            Form {
                TextField("豆名", text: $name)
                TextField("ロースター", text: $roaster)
                TextField("産地", text: $origin)
                TextField("プロセス", text: $process)

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
                            roaster: roaster.isEmpty ? "Unknown Roaster" : roaster,
                            origin: origin.isEmpty ? "Unknown Origin" : origin,
                            process: process.isEmpty ? "Unknown" : process,
                            roastLevel: roastLevel
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    BeansView()
        .environment(AppStore.preview)
}
