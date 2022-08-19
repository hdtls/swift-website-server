import Fluent
import Vapor

class SocialNetworkingCollection: RouteCollection {
    
    private var restfulIDKey: String = "id"

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(.constant(SocialNetworking.schema))

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
    
    func create(_ req: Request) async throws -> SocialNetworking.DTO {
        try await performUpdate(on: req)
    }
    
    func read(_ req: Request) async throws -> SocialNetworking.DTO {
        let id = try req.parameters.require(restfulIDKey, as: SocialNetworking.IDValue.self)
        
        let saved = try await req.repository.socialNetworking.read(id)
        
        return try saved.dataTransferObject()
    }

    func readAll(_ req: Request) async throws -> [SocialNetworking.DTO] {
        try await req.repository.socialNetworking.readAll().map {
            try $0.dataTransferObject()
        }
    }
    
    func update(_ req: Request) async throws -> SocialNetworking.DTO {
        let id = try req.parameters.require(restfulIDKey, as: SocialNetworking.IDValue.self)

        let socialNetworking = try await req.repository.socialNetworking.owned(id)
        
        return try await performUpdate(socialNetworking, on: req)
    }

    func delete(_ req: Request) async throws -> HTTPResponseStatus {
        let id = try req.parameters.require(restfulIDKey, as: SocialNetworking.IDValue.self)
        
        try await req.repository.socialNetworking.delete(id)
        
        return .ok
    }

    func performUpdate(_ original: SocialNetworking? = nil, on req: Request) async throws -> SocialNetworking.Coding {
        var serializedObject = try req.content.decode(SocialNetworking.DTO.self)
        serializedObject.userId = try req.uid

        var upgrade = SocialNetworking.init()

        if let original = original {
            upgrade = try original.update(with: serializedObject)
        } else {
            upgrade = try SocialNetworking.init(from: serializedObject)
            upgrade.id = nil
        }

        try await req.repository.socialNetworking.save(upgrade)

        // Make sure `$socialNetworkingService` has been eager loaded
        // before try `model.dataTransferObject()`.
        try await upgrade.$service.load(on: req.db)

        return try upgrade.dataTransferObject()
    }
}
