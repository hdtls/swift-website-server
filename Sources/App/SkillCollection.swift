import Vapor
import Fluent

class SkillCollection: ApiCollection {

    typealias T = Skill
    
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
    
    func create(_ req: Request) throws -> EventLoopFuture<T.DTO> {
        let user = try req.auth.require(User.self)
        let model = try T.init(from: req.content.decode(T.DTO.self))
        model.id = nil
        
        return user.$skill.create(model, on: req.db)
            .flatMapThrowing({
                try model.dataTransferObject()
            })
    }
    
    func update(_ req: Request) throws -> EventLoopFuture<T.DTO> {
        let user = try req.auth.require(User.self)
        let id = try req.parameters.require(restfulIDKey, as: T.IDValue.self)
        
        let model = try req.content.decode(T.DTO.self)
        
        return user.$skill.query(on: req.db)
            .filter(\.$id == id)
            .first()
            .unwrap(orError: Abort(.notFound))
            .flatMap({ exist -> EventLoopFuture<T> in
                do {
                    return try exist.update(with: model)
                        .update(on: req.db)
                        .map { exist }
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
            })
            .flatMapThrowing({
                try $0.dataTransferObject()
            })
    }
    
    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        let id = try req.parameters.require(restfulIDKey, as: T.IDValue.self)
        
        return user.$skill.query(on: req.db)
            .filter(\.$id == id)
            .first()
            .unwrap(orError: Abort(.notFound))
            .flatMap({
                $0.delete(on: req.db)
            })
            .map({ .ok })
    }
}
