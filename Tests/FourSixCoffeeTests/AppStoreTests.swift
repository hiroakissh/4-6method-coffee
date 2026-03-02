import SwiftData
import XCTest
@testable import FourSixCoffee

@MainActor
final class AppStoreTests: XCTestCase {
    func testAddBeanAndLogPersistAcrossStoreReload() {
        let dependencies = makeInMemoryDependencies()
        let firstStore = AppStore(dependencies: dependencies)

        firstStore.addBean(
            name: "Colombia",
            shopName: "R",
            purchasedAt: .now,
            origin: "Huila",
            process: "Washed",
            roastLevel: .medium
        )
        firstStore.addBrewLog(
            memo: "good",
            ratings: .neutral,
            actualBrewSeconds: 205
        )

        XCTAssertEqual(firstStore.beans.count, 1)
        XCTAssertEqual(firstStore.brewLogs.count, 1)

        let secondStore = AppStore(dependencies: dependencies)

        XCTAssertEqual(secondStore.beans.count, 1)
        XCTAssertEqual(secondStore.brewLogs.count, 1)
        XCTAssertEqual(secondStore.brewLogs[0].bean?.id, secondStore.beans[0].id)
    }

    func testDeleteBeanNullifiesPersistedLogBeanReference() {
        let dependencies = makeInMemoryDependencies()
        let store = AppStore(dependencies: dependencies)

        store.addBean(
            name: "Brazil",
            shopName: "R",
            purchasedAt: .now,
            origin: "Cerrado",
            process: "Natural",
            roastLevel: .dark
        )
        store.addBrewLog(
            memo: "body",
            ratings: .neutral,
            actualBrewSeconds: 230
        )

        store.deleteBeans(at: IndexSet(integer: 0))

        let reloaded = AppStore(dependencies: dependencies)
        XCTAssertTrue(reloaded.beans.isEmpty)
        XCTAssertEqual(reloaded.brewLogs.count, 1)
        XCTAssertNil(reloaded.brewLogs[0].bean)
    }

    func testDeleteSelectedBeanUpdatesRoastLevelToRemainingBean() {
        let dependencies = makeInMemoryDependencies()
        let store = AppStore(dependencies: dependencies)

        store.addBean(
            name: "Light Bean",
            shopName: "R",
            purchasedAt: .now,
            origin: "O",
            process: "P",
            roastLevel: .light
        )
        store.addBean(
            name: "Dark Bean",
            shopName: "R",
            purchasedAt: .now,
            origin: "O",
            process: "P",
            roastLevel: .dark
        )

        XCTAssertEqual(store.currentInput.roastLevel, .dark)
        store.deleteBeans(at: IndexSet(integer: 0))

        XCTAssertEqual(store.beans.count, 1)
        XCTAssertEqual(store.selectedBean?.name, "Light Bean")
        XCTAssertEqual(store.currentInput.roastLevel, .light)
    }

    func testInputUpdateHelpersAndSelectedBeanSetter() {
        let dependencies = makeInMemoryDependencies()
        let store = AppStore(dependencies: dependencies)

        store.addBean(
            name: "A",
            shopName: "R",
            purchasedAt: .now,
            origin: "O",
            process: "P",
            roastLevel: .light
        )
        store.addBean(
            name: "B",
            shopName: "R",
            purchasedAt: .now,
            origin: "O",
            process: "P",
            roastLevel: .dark
        )

        let target = store.beans[1]
        store.selectedBean = target
        XCTAssertEqual(store.selectedBeanID, target.id)
        XCTAssertEqual(store.currentInput.roastLevel, .light)

        store.updateCoffeeDose(100)
        XCTAssertEqual(store.currentInput.coffeeDose, 40)
        store.updateCoffeeDose(1)
        XCTAssertEqual(store.currentInput.coffeeDose, 10)

        store.updateTasteProfile(.sweet)
        XCTAssertEqual(store.currentInput.tasteProfile, .sweet)

        store.updateRoastLevel(.dark)
        XCTAssertEqual(store.currentInput.roastLevel, .dark)

        store.updateGrindSize(.fine)
        XCTAssertEqual(store.currentInput.grindSize, .fine)
    }

    func testApplyAndDeleteLogsFlows() {
        let dependencies = makeInMemoryDependencies()
        let store = AppStore(dependencies: dependencies)

        store.addBean(
            name: "Kenya",
            shopName: "R",
            purchasedAt: .now,
            origin: "O",
            process: "P",
            roastLevel: .medium
        )
        store.currentInput.tasteProfile = .light
        store.addBrewLog(
            memo: "one",
            ratings: .neutral,
            actualBrewSeconds: 120
        )

        let log = store.brewLogs[0]
        store.selectedTab = .settings
        store.currentInput = .default
        store.apply(log: log)

        XCTAssertEqual(store.selectedTab, .planner)
        XCTAssertEqual(store.currentInput, log.input)
        XCTAssertEqual(store.selectedBeanID, log.bean?.id)

        store.deleteLogs(at: IndexSet(integer: 0))
        XCTAssertTrue(store.brewLogs.isEmpty)

        let reloaded = AppStore(dependencies: dependencies)
        XCTAssertTrue(reloaded.brewLogs.isEmpty)
    }

    func testSeedSampleDataWhenStoreIsEmpty() {
        let dependencies = makeInMemoryDependencies()

        let seededStore = AppStore(
            dependencies: dependencies,
            seedSampleDataIfEmpty: true
        )

        XCTAssertEqual(seededStore.beans.count, SampleData.beans.count)
        XCTAssertEqual(seededStore.brewLogs.count, SampleData.brewLogs.count)
    }

    func testErrorsAreStoredWhenRepositoriesFail() {
        let dependencies = makeFailingDependencies()
        let store = AppStore(dependencies: dependencies)

        XCTAssertEqual(store.lastErrorMessage, "forced failure")

        store.addBean(
            name: "X",
            shopName: "R",
            purchasedAt: .now,
            origin: "O",
            process: "P",
            roastLevel: .medium
        )
        XCTAssertEqual(store.lastErrorMessage, "forced failure")

        store.addBrewLog(
            memo: "memo",
            ratings: .neutral,
            actualBrewSeconds: 1
        )
        XCTAssertEqual(store.lastErrorMessage, "forced failure")
    }

    func testPreviewFactoriesAreConstructible() {
        let dependencies = AppDependencies.preview()
        let previewStore = AppStore.preview

        XCTAssertNotNil(dependencies.modelContainer)
        XCTAssertFalse(previewStore.beans.isEmpty)
    }

    private func makeInMemoryDependencies() -> AppDependencies {
        let container = PersistenceStack.makeModelContainer(inMemory: true)
        let context = container.mainContext

        return AppDependencies(
            modelContainer: container,
            beanUseCase: BeanUseCase(repository: SwiftDataBeanRepository(context: context)),
            brewLogUseCase: BrewLogUseCase(repository: SwiftDataBrewLogRepository(context: context))
        )
    }

    private func makeFailingDependencies() -> AppDependencies {
        let container = PersistenceStack.makeModelContainer(inMemory: true)
        let beanUseCase = BeanUseCase(repository: FailingBeanRepository())
        let logUseCase = BrewLogUseCase(repository: FailingBrewLogRepository())

        return AppDependencies(
            modelContainer: container,
            beanUseCase: beanUseCase,
            brewLogUseCase: logUseCase
        )
    }
}
