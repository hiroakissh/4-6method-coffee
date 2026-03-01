import SwiftData

@MainActor
enum PersistenceStack {
    static func makeModelContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([
            BeanEntity.self,
            BrewLogEntity.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }
}
