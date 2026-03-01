import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var bindableStore = store

        NavigationStack {
            Form {
                Section("単位") {
                    Picker("重量単位", selection: $bindableStore.preferredUnit) {
                        Text("グラム(g)").tag("g")
                    }
                }

                Section("アシスタント") {
                    Toggle("ステップ時の通知ヒント", isOn: $bindableStore.enableStepHaptics)
                }

                Section("情報") {
                    LabeledContent("バージョン", value: "1.0.0")
                    LabeledContent("プラン計算", value: "4:6 Method / 6 pours")
                }
            }
            .navigationTitle("設定")
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppStore.preview)
}
