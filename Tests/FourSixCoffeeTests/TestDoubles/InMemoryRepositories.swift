import Foundation
@testable import FourSixCoffee

@MainActor
final class InMemoryBeanRepository: BeanRepository {
    private var storage: [UUID: Bean] = [:]

    func fetchBeans() throws -> [Bean] {
        storage.values.sorted { $0.name < $1.name }
    }

    func save(bean: Bean) throws {
        storage[bean.id] = bean
    }

    func delete(beanID: UUID) throws {
        storage.removeValue(forKey: beanID)
    }
}

@MainActor
final class InMemoryBrewLogRepository: BrewLogRepository {
    private var storage: [UUID: BrewLog] = [:]

    func fetchBrewLogs() throws -> [BrewLog] {
        storage.values.sorted { $0.date > $1.date }
    }

    func save(log: BrewLog) throws {
        storage[log.id] = log
    }

    func delete(logID: UUID) throws {
        storage.removeValue(forKey: logID)
    }
}

enum TestFailure: LocalizedError {
    case forced

    var errorDescription: String? {
        "forced failure"
    }
}

@MainActor
final class FailingBeanRepository: BeanRepository {
    func fetchBeans() throws -> [Bean] {
        throw TestFailure.forced
    }

    func save(bean: Bean) throws {
        throw TestFailure.forced
    }

    func delete(beanID: UUID) throws {
        throw TestFailure.forced
    }
}

@MainActor
final class FailingBrewLogRepository: BrewLogRepository {
    func fetchBrewLogs() throws -> [BrewLog] {
        throw TestFailure.forced
    }

    func save(log: BrewLog) throws {
        throw TestFailure.forced
    }

    func delete(logID: UUID) throws {
        throw TestFailure.forced
    }
}
