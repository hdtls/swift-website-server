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
        var newValue = try req.content.decode(SocialNetworking.DTO.self)
        newValue.userId = try req.owner.__id

        let model = try SocialNetworking(from: newValue)
        model.id = nil

        try await req.socialNetworking.create(model)

        return try model.dataTransferObject()
    }

    func read(_ req: Request) async throws -> SocialNetworking.DTO {
        let id = try req.parameters.require(restfulIDKey, as: SocialNetworking.IDValue.self)

        let saved = try await req.socialNetworking.identified(by: id)

        return try saved.dataTransferObject()
    }

    func readAll(_ req: Request) async throws -> [SocialNetworking.DTO] {
        try await req.socialNetworking.readAll().map {
            try $0.dataTransferObject()
        }
    }

    func update(_ req: Request) async throws -> SocialNetworking.DTO {
        let id = try req.parameters.require(restfulIDKey, as: SocialNetworking.IDValue.self)

        var newValue = try req.content.decode(SocialNetworking.DTO.self)
        newValue.userId = try req.owner.__id

        let saved = try await req.socialNetworking.identified(by: id, owned: true)
        try saved.update(with: newValue)

        precondition(saved.$user.id == newValue.userId)
        try await req.socialNetworking.update(saved)

        return try saved.dataTransferObject()
    }

    func delete(_ req: Request) async throws -> HTTPResponseStatus {
        let id = try req.parameters.require(restfulIDKey, as: SocialNetworking.IDValue.self)

        try await req.socialNetworking.delete(id)

        return .ok
    }
}
