import Vapor
import Fluent

class ProjCollection: RouteCollection, RestfulApi {
    typealias T = Project

    var pidFieldKey: FieldKey = T.FieldKeys.user.rawValue

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped("projects")

        routes.on(.GET, .parameter(restfulIDKey), use: read)

        let trusted = routes.grouped([
            User.authenticator(),
            Token.authenticator(),
            User.guardMiddleware()
        ])

        trusted.on(.POST, use: create)
        trusted.on(.PUT, .parameter(restfulIDKey), use: update)
        trusted.on(.POST, .parameter(restfulIDKey), "artwork", use: uploadArtworkImage)
        trusted.on(.POST, .parameter(restfulIDKey), "screenshots", use: uploadScreenshotImages)
        trusted.on(.DELETE, .parameter(restfulIDKey), use: delete)
    }

    func create(_ req: Request) throws -> EventLoopFuture<T.Coding> {
        let user = try req.auth.require(User.self)
        let coding = try req.content.decode(T.Coding.self)
        let exp = try T.__converted(coding)

        exp.$user.id = try user.requireID()

        return exp.save(on: req.db)
            .flatMapThrowing({ _ in
                try exp.__reverted()
            })
    }

    func read(_ req: Request) throws -> EventLoopFuture<T.Coding> {
        
        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort.init(.notFound)
        }

        return T.find(id, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing({ try $0.__reverted() })
    }

    func readAll(_ req: Request) throws -> EventLoopFuture<[T.Coding]> {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        return T.query(on: req.db)
            .filter(pidFieldKey, .equal, userID)
            .all()
            .flatMapEachThrowing({ try $0.__reverted() })
    }

    func update(_ req: Request) throws -> EventLoopFuture<T.Coding> {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        let coding = try req.content.decode(T.Coding.self)
        let upgrade = try T.__converted(coding)

        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort(.notFound)
        }

        return T.query(on: req.db)
            .filter(pidFieldKey, .equal, userID)
            .filter(\._$id == id)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap({ saved -> EventLoopFuture<T> in
                saved.__merge(upgrade)
                return saved.update(on: req.db).map({ saved })
            })
            .flatMapThrowing({
                try $0.__reverted()
            })
    }

    func uploadFiles(_ req: Request, execute: @escaping (T, [String]) -> Void) throws -> EventLoopFuture<T.Coding> {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()

        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort(.notFound)
        }

        return T.query(on: req.db)
            .filter(pidFieldKey, .equal, userID)
            .filter(\._$id == id)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap({ saved -> EventLoopFuture<T> in
                do {
                    return try uploadMultipleFiles(req)
                        .flatMap({
                            execute(saved, $0)
                            return saved.update(on: req.db).map({ saved })
                        })
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
            })
            .flatMapThrowing({
                try $0.__reverted()
            })
    }

    func uploadArtworkImage(_ req: Request) throws -> EventLoopFuture<T.Coding> {
        try uploadFiles(req) { (saved, urls) in
            saved.artworkUrl = urls.first!
        }
    }

    func uploadScreenshotImages(_ req: Request) throws -> EventLoopFuture<T.Coding> {
        try uploadFiles(req) { (saved, urls) in
            saved.screenshotUrls = urls
        }
    }

    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort.init(.notFound)
        }
        return T.query(on: req.db)
            .filter(pidFieldKey, .equal, userID)
            .filter(.id, .equal, id)
            .first()
            .unwrap(or: Abort.init(.notFound))
            .flatMap({
                $0.delete(on: req.db)
            })
            .map({ .ok })
    }
}
