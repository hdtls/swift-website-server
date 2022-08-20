import Vapor

struct RepositoryID: Equatable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
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
    private var builders: [RepositoryID: ((Request) -> Repository)]

    fileprivate init(application: Application) {
        self.app = application
        self.builders = [:]
    }

    func repository(_ id: RepositoryID, _ req: Request) -> Repository {
        guard let builder = builders[id] else {
            fatalError("Repository for id `\(id)` is not configured.")
        }
        return builder(req)
    }

    public func use(_ builder: @escaping (Request) -> Repository, as id: RepositoryID) {
        builders[id] = builder
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
