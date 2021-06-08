import Vapor
import Fluent

class SocialNetworkingCollection: ApiCollection {

    typealias T = SocialNetworking

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(path.components(separatedBy: "/").map(PathComponent.constant))
        
        routes.on(.GET, use: readAll)
                
        routes.on(.GET, .parameter(restfulIDKey), use: read)
        
        let trusted = routes.grouped([
            User.authenticator(),
            Token.authenticator(),
            User.guardMiddleware()
        ])
        
        trusted.on(.POST, use: create)
        trusted.on(.PUT, .parameter(restfulIDKey), use: update)
        trusted.on(.DELETE, .parameter(restfulIDKey), use: delete)
    }
    
    func update(_ req: Request) throws -> EventLoopFuture<T.DTO> {
        let userId = try req.auth.require(User.self).requireID()
        
        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort(.badRequest, reason: "Invalid id key \(restfulIDKey).")
        }
        
        return T.query(on: req.db)
            .filter(\.$id == id)
            .filter(\.$user.$id == userId)
            .first()
            .unwrap(orError: Abort(.notFound))
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
        
        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort(.badRequest, reason: "Invalid id key \(restfulIDKey).")
        }
        
        return T.query(on: req.db)
            .filter(\.$id == id)
            .filter(\.$user.$id == userId)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap({
                $0.delete(on: req.db)
            })
            .transform(to: .ok)
    }
    
    func applyingFields(_ builder: QueryBuilder<SocialNetworking>) -> QueryBuilder<SocialNetworking> {
        builder.with(\.$service)
    }

    func performUpdate(_ original: T?, on req: Request) throws -> EventLoopFuture<SocialNetworking.Coding> {
        var serializedObject = try req.content.decode(T.DTO.self)
        serializedObject.userId = try req.auth.require(User.self).requireID()
        
        var upgrade = T.init()
 
        if let original = original {
            upgrade = try original.update(with: serializedObject)
        } else {
            upgrade = try T.init(from: serializedObject)
            upgrade.id = nil
        }

        return upgrade.save(on: req.db)
            .flatMap({
                // Make sure `$socialNetworkingService` has been eager loaded
                // before try `model.dataTransferObject()`.
                upgrade.$service.get(reload: true, on: req.db)
            })
            .flatMapThrowing({ _ in
                try upgrade.dataTransferObject()
            })
    }
}
