import SwiftData

@MainActor
struct AppDependencies {
    let modelContainer: ModelContainer
    let beanUseCase: BeanUseCase
    let brewLogUseCase: BrewLogUseCase
    let recipeUseCase: RecipeUseCase
    let recipeRevisionUseCase: RecipeRevisionUseCase

    init(
        modelContainer: ModelContainer,
        beanUseCase: BeanUseCase,
        brewLogUseCase: BrewLogUseCase,
        recipeUseCase: RecipeUseCase,
        recipeRevisionUseCase: RecipeRevisionUseCase
    ) {
        self.modelContainer = modelContainer
        self.beanUseCase = beanUseCase
        self.brewLogUseCase = brewLogUseCase
        self.recipeUseCase = recipeUseCase
        self.recipeRevisionUseCase = recipeRevisionUseCase
    }

    static func live() -> AppDependencies {
        let container = PersistenceStack.makeModelContainer()
        let context = container.mainContext

        let beanRepository = SwiftDataBeanRepository(context: context)
        let logRepository = SwiftDataBrewLogRepository(context: context)
        let recipeRepository = SwiftDataRecipeRepository(context: context)
        let revisionRepository = SwiftDataRecipeRevisionRepository(context: context)

        return AppDependencies(
            modelContainer: container,
            beanUseCase: BeanUseCase(repository: beanRepository),
            brewLogUseCase: BrewLogUseCase(repository: logRepository),
            recipeUseCase: RecipeUseCase(repository: recipeRepository),
            recipeRevisionUseCase: RecipeRevisionUseCase(repository: revisionRepository)
        )
    }

    static func preview() -> AppDependencies {
        let container = PersistenceStack.makeModelContainer(inMemory: true)
        let context = container.mainContext

        let beanRepository = SwiftDataBeanRepository(context: context)
        let logRepository = SwiftDataBrewLogRepository(context: context)
        let recipeRepository = SwiftDataRecipeRepository(context: context)
        let revisionRepository = SwiftDataRecipeRevisionRepository(context: context)

        return AppDependencies(
            modelContainer: container,
            beanUseCase: BeanUseCase(repository: beanRepository),
            brewLogUseCase: BrewLogUseCase(repository: logRepository),
            recipeUseCase: RecipeUseCase(repository: recipeRepository),
            recipeRevisionUseCase: RecipeRevisionUseCase(repository: revisionRepository)
        )
    }
}
