import FluentMySQLDriver
import Vapor

/// Restful style api defination.
/// by default it provide `CRUD` method if `T.IDValue` is `LosslessStringConvertible`
protocol ApiCollection: RouteCollection {
    associatedtype T: Model, Serializing, Updatable
    var path: String { get }

    /// ID path for uri
    var restfulIDKey: String { get }

    /// Create new model
    /// This operation will decode request content with `T.DTO` and transfer it to type `T`
    /// then save to db after that a saved model reverted object will be return for user.
    func create(_ req: Request) async throws -> T.DTO

    /// Read model by given `id`.
    /// This operation will request model id as parameter, if db don't have a model type with `T`
    /// and id equal to `id` a `404 notFound` will be send to user, otherwise return model's
    /// reverted object to user.
    func read(_ req: Request) async throws -> T.DTO

    /// Read all model type with `T`.
    /// Query all models and return all model reverted object to user.
    func readAll(_ req: Request) async throws -> [T.DTO]

    /// Update a model with given `id`
    /// This operation will query model with `id` first, if there is no model return `404` error
    /// otherwise update that model with transfered new model, final return new model's reverted
    /// object to user.
    /// - warning: This operation will change db model value, be careful if you want do this.
    func update(_ req: Request) async throws -> T.DTO

    /// Delete a model with given `id`
    /// First this operation will query model with `id`, if there is no model with `id` `404`
    /// error will be return otherwise delete model from db.
    /// - warning: This operation is dangerous it will delete mdoel from db and can't be
    /// reverted.
    func delete(_ req: Request) async throws -> HTTPStatus

    /// Query builder with specified id required.
    /// This will be apply to `read(_:)` `update(_:)` and `delete(_:)` opertation.
    func specifiedIDQueryBuilder(on req: Request) throws -> QueryBuilder<T>

    /// Applying fields that will query in request. By default this effect `read(_:)`.
    /// - seealso `applyingFieldsForQueryAll(_:)` for query all items..
    /// - Parameter builder: receiver
    func applyingFields(_ builder: QueryBuilder<T>) -> QueryBuilder<T>

    /// Applying fields that will query in request. By default this effect `readAll(_:)`.
    /// - seealso `applyingFields(_:)` for single item query.
    /// - Parameter builder: receiver
    func applyingFieldsForQueryAll(_ builder: QueryBuilder<T>) -> QueryBuilder<T>

    /// Applying eager loaders to query request. By default this will effect default impl of `read(_:)`
    /// - seealso `applyingEagerLoadersForQueryAll(_:)` for query all items.
    /// - Parameter builder: receiver
    func applyingEagerLoaders(_ builder: QueryBuilder<T>) -> QueryBuilder<T>

    /// Applying eager loaders to query request. By default this will effect default impl of `readAll(_:)`
    /// By default return `applyingEagerLoaders(_:)`
    /// - seealso `applyingEagerLoaders(_:)` for single item query.
    /// - Parameter builder: receiver
    func applyingEagerLoadersForQueryAll(_ builder: QueryBuilder<T>) -> QueryBuilder<T>

    /// Common update function.
    func performUpdate(_ original: T?, on req: Request) async throws -> T.DTO
}

extension ApiCollection {
    var path: String { T.schema }
    var restfulIDKey: String { "id" }

    func performUpdate(on req: Request) async throws -> T.DTO {
        try await performUpdate(nil, on: req)
    }
}

/// Default `CRUD` implementation.
extension ApiCollection where T.IDValue: LosslessStringConvertible {

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(path.components(separatedBy: "/").map(PathComponent.constant))

        let path = PathComponent.parameter(restfulIDKey)

        routes.on(.POST, use: create)
        routes.on(.GET, path, use: read)
        routes.on(.GET, use: readAll)
        routes.on(.PUT, path, use: update)
        routes.on(.DELETE, path, use: delete)
    }

    func create(_ req: Request) async throws -> T.DTO {
        try await performUpdate(on: req)
    }

    func read(_ req: Request) async throws -> T.DTO {
        var builder = try specifiedIDQueryBuilder(on: req)
        builder = applyingFields(builder)
        builder = applyingEagerLoaders(builder)

        guard let model = try await builder.first() else {
            throw Abort(.notFound)
        }

        return try model.dataTransferObject()
    }

    func readAll(_ req: Request) async throws -> [T.DTO] {
        var builder = T.query(on: req.db)
        builder = applyingFieldsForQueryAll(builder)
        builder = applyingEagerLoadersForQueryAll(builder)

        return try await builder.all().map { try $0.dataTransferObject() }
    }

    func update(_ req: Request) async throws -> T.DTO {
        guard let model = try await specifiedIDQueryBuilder(on: req).first() else {
            throw Abort(.notFound)
        }

        return try await performUpdate(model, on: req)
    }

    func delete(_ req: Request) async throws -> HTTPStatus {
        guard let model = try await specifiedIDQueryBuilder(on: req).first() else {
            throw Abort(.notFound)
        }
        try await model.delete(on: req.db)
        return .ok
    }

    func specifiedIDQueryBuilder(on req: Request) throws -> QueryBuilder<T> {
        let id = try req.parameters.require(restfulIDKey, as: T.IDValue.self)
        return T.query(on: req.db)
            .filter(\._$id == id)
    }

    func applyingFields(_ builder: QueryBuilder<T>) -> QueryBuilder<T> {
        builder
    }

    func applyingFieldsForQueryAll(_ builder: QueryBuilder<T>) -> QueryBuilder<T> {
        builder
    }

    func applyingEagerLoaders(_ builder: QueryBuilder<T>) -> QueryBuilder<T> {
        builder
    }

    func applyingEagerLoadersForQueryAll(_ builder: QueryBuilder<T>) -> QueryBuilder<T> {
        applyingEagerLoaders(builder)
    }

    func performUpdate(_ original: T?, on req: Request) async throws -> T.DTO {
        let coding = try req.content.decode(T.DTO.self)

        var upgrade = T.init()

        if let original = original {
            upgrade = try original.update(with: coding)
        } else {
            upgrade = try T.init(from: coding)
            upgrade.id = nil
        }

        do {
            try await upgrade.save(on: req.db)
        } catch {
            if case MySQLError.duplicateEntry(let localizedErrorDescription) = error {
                throw Abort.init(.unprocessableEntity, reason: localizedErrorDescription)
            }
            throw error
        }

        return try upgrade.dataTransferObject()
    }
}
