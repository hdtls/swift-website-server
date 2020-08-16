import Vapor
import Fluent

protocol UserChildren: Model, Serializing, Mergeable where Self.IDValue: LosslessStringConvertible {
    var _$user: Parent<User> { get }
}

/// This protocol define user children restful route collection.
/// because all `CRUD` request require data owned by userself so those operation all require authorized.
protocol UserChildrenRestfulApi: RestfulApi where T: UserChildren {
    var pidFieldKey: FieldKey { get }
}

extension UserChildrenRestfulApi {
    func create(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        let user = try req.auth.require(User.self)
        let coding = try req.content.decode(T.SerializedObject.self)
        let exp = try T.init(content: coding)
        exp._$user.id = try user.requireID()
        return exp.save(on: req.db)
            .flatMapThrowing({
                try exp.reverted()
            })
    }

    func update(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        let userID = try req.auth.require(User.self).requireID()
        let coding = try req.content.decode(T.SerializedObject.self)
        let upgrade = try T.init(content: coding)

        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort(.notFound)
        }

        return T.query(on: req.db)
            .filter(pidFieldKey, .equal, userID)
            .filter(\._$id == id)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap({ saved -> EventLoopFuture<T> in
                saved.merge(upgrade)
                let newValue = saved
                return saved.update(on: req.db).map({ newValue })
            })
            .flatMapThrowing({
                try $0.reverted()
            })
    }

    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        guard let expID = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort.init(.notFound)
        }
        return T.query(on: req.db)
            .filter(pidFieldKey, .equal, userID)
            .filter(.id, .equal, expID)
            .first()
            .unwrap(or: Abort.init(.notFound))
            .flatMap({
                $0.delete(on: req.db)
            })
            .map({ .ok })
    }
}

/// User children collection
class UserChildrenCollection<T: UserChildren>: RouteCollection, UserChildrenRestfulApi {

    var path: [PathComponent]
    let pidFieldKey: FieldKey

    init(path: PathComponent..., pidFieldKey: FieldKey = "user_id") {
        self.path = path
        self.pidFieldKey = pidFieldKey
    }

    func boot(routes: RoutesBuilder) throws {
        var routes = routes
        path.forEach({
            routes = routes.grouped($0)
        })

        let path = PathComponent.init(stringLiteral: ":" + restfulIDKey)

        routes.on(.GET, path, use: read)

        let trusted = routes.grouped([
            User.authenticator(),
            Token.authenticator(),
            User.guardMiddleware(),
            Token.guardMiddleware()
        ])

        trusted.on(.POST, use: create)
        trusted.on(.PUT, path, use: update)
        trusted.on(.DELETE, path, use: delete)
    }
}
