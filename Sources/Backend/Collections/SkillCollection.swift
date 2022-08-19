import Fluent
import Vapor

class SkillCollection: RouteCollection {
    
    private let restfulIDKey: String = "id"
    
    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(.constant(Skill.schema))

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

    func create(_ req: Request) async throws -> Skill.DTO {
        let model = try Skill.init(from: req.content.decode(Skill.DTO.self))
        model.id = nil

        try await req.repository.skill.create(model)

        return try model.dataTransferObject()
    }

    func read(_ req: Request) async throws -> Skill.DTO {
        let id = try req.parameters.require(restfulIDKey, as: Skill.IDValue.self)

        let result = try await req.repository.skill.read(id)
            
        return try result.dataTransferObject()
    }
    
    func readAll(_ req: Request) async throws -> [Skill.DTO] {
        try await req.repository.skill.readAll().map {
            try $0.dataTransferObject()
        }
    }
    
    func update(_ req: Request) async throws -> Skill.DTO {
        let id = try req.parameters.require(restfulIDKey, as: Skill.IDValue.self)

        let model = try req.content.decode(Skill.DTO.self)

        let saved = try await req.repository.skill.owned(id)
        try saved.update(with: model)
        
        try await req.repository.skill.update(saved)
  
        return try saved.dataTransferObject()
    }

    func delete(_ req: Request) async throws -> HTTPResponseStatus {
        let id = try req.parameters.require(restfulIDKey, as: Skill.IDValue.self)

        try await req.repository.skill.delete(id)

        return .ok
    }
}
