import Fluent
import Vapor

protocol Repository {

    associatedtype Model: Fluent.Model

    var request: Request { get }

    init(request: Request)

    func query(owned: Bool) throws -> QueryBuilder<Model>

    func query(_ id: Model.IDValue, owned: Bool) throws -> QueryBuilder<Model>

    func queryAll(owned: Bool) throws -> QueryBuilder<Model>

    func create(_ model: Model) async throws

    func identified(by id: Model.IDValue, owned: Bool) async throws -> Model

    func readAll(owned: Bool) async throws -> [Model]

    func update(_ model: Model) async throws

    func delete(_ id: Model.IDValue) async throws
}

extension Repository {

    func query(_ id: Model.IDValue, owned: Bool = false) throws -> QueryBuilder<Model> {
        try query(owned: owned).filter(\._$id == id)
    }

    func queryAll(owned: Bool = false) throws -> QueryBuilder<Model> {
        try query(owned: owned)
    }

    func create(_ model: Model) async throws {
        try await model.save(on: request.db)
    }

    func identified(by id: Model.IDValue, owned: Bool = false) async throws -> Model {
        guard let result = try await query(id, owned: owned).first() else {
            throw Abort(.notFound)
        }
        return result
    }

    func readAll(owned: Bool = false) async throws -> [Model] {
        try await queryAll(owned: owned).all()
    }

    func update(_ model: Model) async throws {
        try await model.update(on: request.db)
    }

    func delete(_ id: Model.IDValue) async throws {
        try await query(id, owned: true).delete()
    }
}
