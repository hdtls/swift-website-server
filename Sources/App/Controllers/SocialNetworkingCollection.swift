import Vapor
import Fluent

class SocialNetworkingCollection: RouteCollection, UserChildrenRestfulApi {
    typealias T = SocialNetworking

    let pidFieldKey: FieldKey = T.FieldKeys.user.rawValue

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped("social")

        routes.on(.GET, .parameter(restfulIDKey), use: read)

        let trusted = routes.grouped([
            User.authenticator(),
            Token.authenticator(),
            User.guardMiddleware(),
            Token.guardMiddleware()
        ])

        trusted.on(.POST, use: create)
        trusted.on(.PUT, .parameter(restfulIDKey), use: update)
        trusted.on(.DELETE, .parameter(restfulIDKey), use: delete)
    }

    func create(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        let user = try req.auth.require(User.self)
        let coding = try req.content.decode(T.SerializedObject.self)
        let model = try T.init(content: coding)
        model.$user.id = try user.requireID()

        return model.save(on: req.db)
            .flatMap({
                // Make sure `$socialNetworkingService` has been eager loaded
                // before try `model.reverted()`.
                model.$service.get(on: req.db)
            })
            .flatMapThrowing({ _ in
                try model.reverted()
            })
    }

    func read(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {

        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort.init(.notFound)
        }

        return T.query(on: req.db)
            .filter(\._$id == id)
            .with(\.$service)
            .first()
            .unwrap(or: Abort.init(.notFound))
            .flatMapThrowing({
                try $0.reverted()
            })
    }

    func update(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        let coding = try req.content.decode(T.SerializedObject.self)
        let upgrade = try T.init(content: coding)

        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort(.notFound)
        }

        return T.query(on: req.db)
            .filter(\._$id == id)
            .filter(pidFieldKey, .equal, userID)
            .with(\.$service)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap({ saved -> EventLoopFuture<T> in
                saved.merge(upgrade)
                let newValue = saved
                return newValue.update(on: req.db)
                    .map({ newValue })
            })
            .flatMapThrowing({
                try $0.reverted()
            })
    }
}
