import SwiftData

@MainActor
struct AppDependencies {
    let modelContainer: ModelContainer
    let beanUseCase: BeanUseCase
    let brewLogUseCase: BrewLogUseCase
    let recipeUseCase: RecipeUseCase

    init(
        modelContainer: ModelContainer,
        beanUseCase: BeanUseCase,
        brewLogUseCase: BrewLogUseCase,
        recipeUseCase: RecipeUseCase
    ) {
        self.modelContainer = modelContainer
        self.beanUseCase = beanUseCase
        self.brewLogUseCase = brewLogUseCase
        self.recipeUseCase = recipeUseCase
    }

    static func live() -> AppDependencies {
        let container = PersistenceStack.makeModelContainer()
        let context = container.mainContext

        let beanRepository = SwiftDataBeanRepository(context: context)
        let logRepository = SwiftDataBrewLogRepository(context: context)
        let recipeRepository = SwiftDataRecipeRepository(context: context)

        return AppDependencies(
            modelContainer: container,
            beanUseCase: BeanUseCase(repository: beanRepository),
            brewLogUseCase: BrewLogUseCase(repository: logRepository),
            recipeUseCase: RecipeUseCase(repository: recipeRepository)
        )
    }

    static func preview() -> AppDependencies {
        let container = PersistenceStack.makeModelContainer(inMemory: true)
        let context = container.mainContext

        let beanRepository = SwiftDataBeanRepository(context: context)
        let logRepository = SwiftDataBrewLogRepository(context: context)
        let recipeRepository = SwiftDataRecipeRepository(context: context)

        return AppDependencies(
            modelContainer: container,
            beanUseCase: BeanUseCase(repository: beanRepository),
            brewLogUseCase: BrewLogUseCase(repository: logRepository),
            recipeUseCase: RecipeUseCase(repository: recipeRepository)
        )
    }
}
