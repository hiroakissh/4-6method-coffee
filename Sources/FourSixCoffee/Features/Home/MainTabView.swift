import SwiftUI

struct MainTabView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var bindableStore = store

        TabView(selection: $bindableStore.selectedTab) {
            HomeView()
                .tabItem { Label("プラン", systemImage: "slider.horizontal.3") }
                .tag(AppTab.planner)

            BrewAssistantView()
                .tabItem { Label("タイマー", systemImage: "timer") }
                .tag(AppTab.assistant)

            BeansView()
                .tabItem { Label("豆", systemImage: "leaf.fill") }
                .tag(AppTab.beans)

            BrewLogsView()
                .tabItem { Label("履歴", systemImage: "book.pages") }
                .tag(AppTab.logs)

            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppStore())
}
