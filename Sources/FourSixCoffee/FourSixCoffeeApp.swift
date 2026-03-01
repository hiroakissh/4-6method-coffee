import SwiftUI
import SwiftData

@main
struct FourSixCoffeeApp: App {
    private let dependencies: AppDependencies
    @State private var store: AppStore

    init() {
        let dependencies = AppDependencies.live()
        self.dependencies = dependencies
        _store = State(initialValue: AppStore(dependencies: dependencies))
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(store)
                .modelContainer(dependencies.modelContainer)
        }
    }
}
