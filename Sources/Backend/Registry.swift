import Vapor

struct RepositoryFactoryKey: Equatable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
    typealias StringLiteralType = String

    var rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(stringLiteral value: String) {
        self.rawValue = value
    }
}

final class Registry {

    private let app: Application
    private var storage: [RepositoryFactoryKey: ((Request) -> any Repository)]

    fileprivate init(application: Application) {
        self.app = application
        self.storage = [:]
    }

    func repository(_ id: RepositoryFactoryKey, _ req: Request) -> any Repository {
        guard let factory = storage[id] else {
            fatalError("Repository for id `\(id)` is not configured.")
        }
        return factory(req)
    }

    public func use(_ factory: @escaping (Request) -> any Repository, as id: RepositoryFactoryKey) {
        storage[id] = factory
    }
}

extension Application {

    private struct Key: StorageKey {
        typealias Value = Registry
    }

    var registry: Registry {
        if storage[Key.self] == nil {
            storage[Key.self] = .init(application: self)
        }
        return storage[Key.self]!
    }
}

extension Request {

    var registry: Registry {
        application.registry
    }
}
