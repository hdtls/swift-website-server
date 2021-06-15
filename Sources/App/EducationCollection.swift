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
    
    func update(_ request: Request) throws -> EventLoopFuture<T.DTO> {
        let user = try request.auth.require(User.self)
        let id = try request.parameters.require(restfulIDKey, as: T.IDValue.self)
        return user.$education.query(on: request.db)
            .filter(\.$id == id)
            .first()
            .unwrap(orError: Abort(.notFound))
            .flatMap({
                do {
                    return try self.performUpdate($0, on: request)
                } catch {
                    return request.eventLoop.makeFailedFuture(error)
                }
            })
    }
    
    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        let id = try req.parameters.require(restfulIDKey, as: T.IDValue.self)
        return user.$education.query(on: req.db)
            .filter(\.$id == id)
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
            upgrade.id = nil
        }
        
        return upgrade.save(on: req.db)
            .flatMapThrowing({
                try upgrade.dataTransferObject()
            })
    }
}
