import Fluent
import Vapor

class EducationCollection: RouteCollection {

    private let restfulIDKey = "id"
    
    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(.constant(Education.schema))

        routes.on(.GET, use: readAll)

        routes.on(.GET, .parameter(restfulIDKey), use: read)

        let trusted = routes.grouped([
            User.authenticator(),
            Token.authenticator(),
            User.guardMiddleware(),
        ])

        trusted.on(.POST, use: create)
        trusted.on(.PUT, .parameter(restfulIDKey), use: update)
        trusted.on(.DELETE, .parameter(restfulIDKey), use: delete)
    }
    
    func create(_ req: Request) async throws -> Education.DTO {
        var newValue = try req.content.decode(Education.DTO.self)
        newValue.userId = try req.uid
        
        let model = try Education(from: newValue)
        model.id = nil
        
        try await req.repository.education.create(model)
        
        return try model.dataTransferObject()
    }

    func read(_ req: Request) async throws -> Education.DTO {
        let id = try req.parameters.require(restfulIDKey, as: Education.IDValue.self)
        
        let saved = try await req.repository.education.read(id)
        
        return try saved.dataTransferObject()
    }
    
    func readAll(_ req: Request) async throws -> [Education.Coding] {
        try await req.repository.education.readAll().map {
            try $0.dataTransferObject()
        }
    }
    
    func update(_ req: Request) async throws -> Education.DTO {
        let id = try req.parameters.require(restfulIDKey, as: Education.IDValue.self)

        var newValue = try req.content.decode(Education.DTO.self)
        newValue.userId = try req.uid
        
        let saved = try await req.repository.education.owned(id)
        try saved.update(with: newValue)
        
        try await req.repository.education.update(saved)
        
        return try saved.dataTransferObject()
    }

    func delete(_ req: Request) async throws -> HTTPResponseStatus {
        let id = try req.parameters.require(restfulIDKey, as: Education.IDValue.self)
        
        try await req.repository.education.delete(id)
        
        return .ok
    }
}
