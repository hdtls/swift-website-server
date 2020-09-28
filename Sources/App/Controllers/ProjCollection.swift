import Vapor
import Fluent

class ProjCollection: RouteCollection, RestfulApi {
    typealias T = Project

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
        trusted.on(.PATCH, .parameter(restfulIDKey), "artwork", use: uploadArtworkImage)
        trusted.on(.PATCH, .parameter(restfulIDKey), "screenshots", use: uploadScreenshots)
        trusted.on(.PATCH, .parameter(restfulIDKey), "screenshots", "pad", use: uploadPadScreenshots)
        trusted.on(.DELETE, .parameter(restfulIDKey), use: delete)
    }

    func uploadFiles(_ req: Request, execute: @escaping (T, [String]) -> Void) throws -> EventLoopFuture<T.SerializedObject> {
        return try topLevelQueryBuilder(on: req)
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
                try $0.reverted()
            })
    }

    func uploadArtworkImage(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        try uploadFiles(req) { (saved, urls) in
            saved.artworkUrl = urls.first!
        }
    }

    func uploadScreenshots(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        try uploadFiles(req) { (saved, urls) in
            saved.screenshotUrls = urls
        }
    }

    func uploadPadScreenshots(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        try uploadFiles(req) { (saved, urls) in
            saved.padScreenshotUrls = urls
        }
    }
}
