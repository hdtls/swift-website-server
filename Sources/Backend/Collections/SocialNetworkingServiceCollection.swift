import Vapor

/// In progress
/// admin user request.
class SocialNetworkingServiceCollection: RouteCollection {

    private var restfulIDKey: String = "id"

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(.constant(SocialNetworking.schema), .constant("services"))

        routes.on(.POST, use: create)
        routes.on(.GET, .parameter(restfulIDKey), use: read)
        routes.on(.GET, use: readAll)
        routes.on(.PUT, .parameter(restfulIDKey), use: update)
        routes.on(.DELETE, .parameter(restfulIDKey), use: delete)
    }

    func create(_ req: Request) async throws -> SocialNetworkingService.DTO {
        let newValue = try req.content.decode(SocialNetworkingService.DTO.self)

        let model = try SocialNetworkingService(from: newValue)
        model.id = nil

        try await req.repository.socialNetworkingService.create(model)

        return try model.dataTransferObject()
    }

    func read(_ req: Request) async throws -> SocialNetworkingService.DTO {
        let id = try req.parameters.require(restfulIDKey, as: SocialNetworkingService.IDValue.self)

        let saved = try await req.repository.socialNetworkingService.identified(by: id)

        return try saved.dataTransferObject()
    }

    func readAll(_ req: Request) async throws -> [SocialNetworkingService.DTO] {
        try await req.repository.socialNetworkingService.readAll().map {
            try $0.dataTransferObject()
        }
    }

    func update(_ req: Request) async throws -> SocialNetworkingService.DTO {
        let id = try req.parameters.require(restfulIDKey, as: SocialNetworkingService.IDValue.self)

        let newValue = try req.content.decode(SocialNetworkingService.DTO.self)

        let saved = try await req.repository.socialNetworkingService.identified(by: id)
        try saved.update(with: newValue)

        try await req.repository.socialNetworkingService.update(saved)

        return try saved.dataTransferObject()
    }

    func delete(_ req: Request) async throws -> HTTPResponseStatus {
        let id = try req.parameters.require(restfulIDKey, as: SocialNetworkingService.IDValue.self)

        try await req.repository.socialNetworkingService.delete(id)

        return .ok
    }
}
