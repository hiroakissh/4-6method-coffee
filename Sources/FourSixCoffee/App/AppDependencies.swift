import SwiftData

@MainActor
struct AppDependencies {
    let modelContainer: ModelContainer
    let beanUseCase: BeanUseCase
    let brewLogUseCase: BrewLogUseCase

    static func live() -> AppDependencies {
        let container = PersistenceStack.makeModelContainer()
        let context = container.mainContext

        let beanRepository = SwiftDataBeanRepository(context: context)
        let logRepository = SwiftDataBrewLogRepository(context: context)

        return AppDependencies(
            modelContainer: container,
            beanUseCase: BeanUseCase(repository: beanRepository),
            brewLogUseCase: BrewLogUseCase(repository: logRepository)
        )
    }

    static func preview() -> AppDependencies {
        let container = PersistenceStack.makeModelContainer(inMemory: true)
        let context = container.mainContext

        let beanRepository = SwiftDataBeanRepository(context: context)
        let logRepository = SwiftDataBrewLogRepository(context: context)

        return AppDependencies(
            modelContainer: container,
            beanUseCase: BeanUseCase(repository: beanRepository),
            brewLogUseCase: BrewLogUseCase(repository: logRepository)
        )
    }
}
