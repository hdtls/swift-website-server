import Vapor
import FluentMySQLDriver

/// Restful style api defination.
/// by default it provide `CRUD` method if `T.IDValue` is `LosslessStringConvertible`
protocol RestfulApiCollection: RouteCollection {
    associatedtype T: Model, Serializing, Mergeable
    var path: String { get }

    /// ID path for uri
    var restfulIDKey: String { get }

    /// Create new model
    /// This operation will decode request content with `T.SerializedObject` and transfer it to type `T`
    /// then save to db after that a saved model reverted object will be return for user.
    func create(_ req: Request) throws -> EventLoopFuture<T.SerializedObject>

    /// Read model by given `id`.
    /// This operation will request model id as parameter, if db don't have a model type with `T`
    /// and id equal to `id` a `404 notFound` will be send to user, otherwise return model's
    /// reverted object to user.
    func read(_ req: Request) throws -> EventLoopFuture<T.SerializedObject>

    /// Read all model type with `T`.
    /// Query all models and return all model reverted object to user.
    func readAll(_ req: Request) throws -> EventLoopFuture<[T.SerializedObject]>

    /// Update a model with given `id`
    /// This operation will query model with `id` first, if there is no model return `404` error
    /// otherwise update that model with transfered new model, final return new model's reverted
    /// object to user.
    /// - warning: This operation will change db model value, be careful if you want do this.
    func update(_ req: Request) throws -> EventLoopFuture<T.SerializedObject>

    /// Delete a model with given `id`
    /// First this operation will query model with `id`, if there is no model with `id` `404`
    /// error will be return otherwise delete model from db.
    /// - warning: This operation is dangerous it will delete mdoel from db and can't be
    /// reverted.
    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus>

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
    func performUpdate(_ original: T?, on req: Request) throws -> EventLoopFuture<T.SerializedObject>
}

extension RestfulApiCollection {
    var path: String { T.schema }
    var restfulIDKey: String { "id" }

    func performUpdate(on req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        try performUpdate(nil, on: req)
    }
}

/// Default `CRUD` implementation.
extension RestfulApiCollection where T.IDValue: LosslessStringConvertible {

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(path.components(separatedBy: "/").map(PathComponent.constant))

        let path  = PathComponent.parameter(restfulIDKey)

        routes.on(.POST, use: create)
        routes.on(.GET, path, use: read)
        routes.on(.GET, use: readAll)
        routes.on(.PUT, path, use: update)
        routes.on(.DELETE, path, use: delete)
    }

    func create(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        try performUpdate(on: req)
    }

    func read(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        var builder = try specifiedIDQueryBuilder(on: req)
        builder = applyingFields(builder)
        builder = applyingEagerLoaders(builder)

        return builder
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing({ try $0.reverted() })
    }

    func readAll(_ req: Request) throws -> EventLoopFuture<[T.SerializedObject]> {
        var builder = T.query(on: req.db)
        builder = applyingFieldsForQueryAll(builder)
        builder = applyingEagerLoadersForQueryAll(builder)

        return builder
            .all()
            .flatMapEachThrowing({ try $0.reverted() })
    }

    func update(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        try specifiedIDQueryBuilder(on: req)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap({
                do {
                    return try self.performUpdate($0, on: req)
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
            })
    }

    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try specifiedIDQueryBuilder(on: req)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap({
                $0.delete(on: req.db)
            })
            .transform(to: .ok)
    }

    func specifiedIDQueryBuilder(on req: Request) throws -> QueryBuilder<T> {
        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort.init(.notFound)
        }
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

    func performUpdate(_ original: T?, on req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        let coding = try req.content.decode(T.SerializedObject.self)

        var upgrade = try T.init(content: coding)

        if let original = original {
            original.merge(upgrade)
            upgrade = original
        }

        return upgrade.save(on: req.db)
            .flatMapErrorThrowing({
                if case MySQLError.duplicateEntry(let localizedErrorDescription) = $0 {
                    throw Abort.init(.unprocessableEntity, reason: localizedErrorDescription)
                }
                throw $0
            })
            .flatMapThrowing({
                try upgrade.reverted()
            })
    }
}

extension RestfulApiCollection where T: UserOwnable, T.IDValue: LosslessStringConvertible {

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(path.components(separatedBy: "/").map(PathComponent.constant))

        routes.on(.GET, use: readAll)

        let path  = PathComponent.parameter(restfulIDKey)

        routes.on(.GET, path, use: read)

        let trusted = routes.grouped([
            User.authenticator(),
            Token.authenticator(),
            User.guardMiddleware()
        ])

        trusted.on(.POST, use: create)
        trusted.on(.PUT, path, use: update)
        trusted.on(.DELETE, path, use: delete)
    }

    func update(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        let userId = try req.auth.require(User.self).requireID()

        return try specifiedIDQueryBuilder(on: req)
            .filter(T.uidFieldKey, .equal, userId)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap({
                do {
                    return try self.performUpdate($0, on: req)
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
            })
    }

    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let userId = try req.auth.require(User.self).requireID()

        return try specifiedIDQueryBuilder(on: req)
            .filter(T.uidFieldKey, .equal, userId)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap({
                $0.delete(on: req.db)
            })
            .transform(to: .ok)
    }

    func performUpdate(_ original: T?, on req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        let coding = try req.content.decode(T.SerializedObject.self)

        var upgrade = try T.init(content: coding)
        upgrade._$user.id = try req.auth.require(User.self).requireID()

        if let original = original {
            original.merge(upgrade)
            upgrade = original
        }

        return upgrade.save(on: req.db)
            .flatMapThrowing({
                try upgrade.reverted()
            })
    }
}
