import Vapor
import Fluent

class EducationCollection: ApiCollection {
    
    typealias T = Education
    
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
        
        return try specifiedIDQueryBuilder(on: req)
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
        try specifiedIDQueryBuilder(on: req)
            .first()
            .unwrap(or: Abort.init(.notFound))
            .flatMap({
                $0.delete(on: req.db)
            })
            .map({ .ok })
    }
    
    func performUpdate(_ original: T?, on req: Request) throws -> EventLoopFuture<T.DTO> {
        var serializedObject = try req.content.decode(T.DTO.self)
        serializedObject.userId = try req.auth.require(User.self).requireID()
        
        var upgrade = T.init()
        
        if let original = original {
            upgrade = try original.update(with: serializedObject)
        } else {
            upgrade = try T.init(from: serializedObject)
        }
        
        return upgrade.save(on: req.db)
            .flatMapThrowing({
                try upgrade.dataTransferObject()
            })
    }
}
