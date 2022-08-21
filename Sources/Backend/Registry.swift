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

struct Registry {

    private let app: Application

    fileprivate init(application: Application) {
        self.app = application
        self.storage = [:]
    }

    #if compiler(>=5.7)
    private var storage: [RepositoryFactoryKey: ((Request) -> any Repository)]

    func repository(_ id: RepositoryFactoryKey, _ req: Request) -> any Repository {
        guard let factory = storage[id] else {
            fatalError("Repository for id `\(id)` is not configured.")
        }
        return factory(req)
    }

    mutating func use(_ factory: @escaping (Request) -> any Repository, as id: RepositoryFactoryKey)
    {
        storage[id] = factory
    }

    #else
    private var storage: [RepositoryFactoryKey: ((Request) -> Any)]

    func repository(_ id: RepositoryFactoryKey, _ req: Request) -> Any {
        guard let factory = storage[id] else {
            fatalError("Repository for id `\(id)` is not configured.")
        }
        return factory(req)
    }

    mutating func use(_ factory: @escaping (Request) -> Any, as id: RepositoryFactoryKey) {
        storage[id] = factory
    }
    #endif
}

extension Application {

    private struct RegistryKey: StorageKey {
        typealias Value = Registry
    }

    var registry: Registry {
        set {
            storage[RegistryKey.self] = newValue
        }
        get {
            guard storage[RegistryKey.self] == nil else {
                return storage[RegistryKey.self]!
            }
            let registry = Registry(application: self)
            storage[RegistryKey.self] = registry
            return registry
        }
    }
}

extension Request {

    var registry: Registry {
        application.registry
    }
}
