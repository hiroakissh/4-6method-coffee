import SwiftUI

@main
struct FourSixCoffeeApp: App {
    @State private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(store)
        }
    }
}
