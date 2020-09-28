import Vapor
import Fluent

/// Restful style api defination.
/// by default it provide `CRUD` method if `T.IDValue` is `LosslessStringConvertible`
protocol RestfulApi: RouteCollection {
    associatedtype T: Model, Serializing, Mergeable
    var restfulPath: String { get }

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

    /// Basic get query builder. by default change will be apply to `read` `update` and `delete` opertation.
    func queryBuilder(on req: Request) throws -> QueryBuilder<T>

    /// Final query builder  by default change apply to `update` and `delete`.
    /// if you will changed this function impl please make sure call `queryBuilder(on:)` first.
    func topLevelQueryBuilder(on req: Request) throws -> QueryBuilder<T>

    /// Common update function.
    func performUpdate(_ upgrade: T, on req: Request) -> EventLoopFuture<T.SerializedObject>
}

extension RestfulApi {
    var restfulPath: String { T.schema }
    var restfulIDKey: String { "id" }
}

/// Default `CRUD` implementation.
extension RestfulApi where T.IDValue: LosslessStringConvertible {

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(.constant(restfulPath))

        let path  = PathComponent.parameter(restfulIDKey)

        routes.on(.POST, use: create)
        routes.on(.GET, path, use: read)
        routes.on(.PUT, path, use: update)
        routes.on(.DELETE, path, use: delete)
    }

    func create(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        let coding = try req.content.decode(T.SerializedObject.self)

        let model = try T.init(content: coding)

        return performUpdate(model, on: req)
    }

    func read(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        try queryBuilder(on: req)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing({ try $0.reverted() })
    }

    func readAll(_ req: Request) throws -> EventLoopFuture<[T.SerializedObject]> {
        T.query(on: req.db)
            .all()
            .flatMapEachThrowing({ try $0.reverted() })
    }

    func update(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        let coding = try req.content.decode(T.SerializedObject.self)

        let upgrade = try T.init(content: coding)

        return try topLevelQueryBuilder(on: req)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap({
                $0.merge(upgrade)
                return self.performUpdate($0, on: req)
            })
    }

    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try topLevelQueryBuilder(on: req)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap({
                $0.delete(on: req.db)
            })
            .transform(to: .ok)
    }

    func queryBuilder(on req: Request) throws -> QueryBuilder<T> {
        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort.init(.notFound)
        }
        return T.query(on: req.db)
            .filter(\._$id == id)
    }

    func topLevelQueryBuilder(on req: Request) throws -> QueryBuilder<T> {
        try queryBuilder(on: req)
    }

    func performUpdate(_ upgrade: T, on req: Request) -> EventLoopFuture<T.SerializedObject> {
        upgrade.save(on: req.db)
            .flatMapThrowing({
                try upgrade.reverted()
            })
    }
}

extension RestfulApi where T: UserOwnable, T.IDValue: LosslessStringConvertible {

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(.constant(restfulPath))

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

    func create(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        let coding = try req.content.decode(T.SerializedObject.self)

        let model = try T.init(content: coding)
        model._$user.id = try req.auth.require(User.self).requireID()

        return performUpdate(model, on: req)
    }

    func topLevelQueryBuilder(on req: Request) throws -> QueryBuilder<T> {
        let userId = try req.auth.require(User.self).requireID()
        return try queryBuilder(on: req)
            .filter(T.uidFieldKey, .equal, userId)
    }
}
