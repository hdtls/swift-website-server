import Fluent
import Vapor

class SocialNetworkingCollection: ApiCollection {

    typealias T = SocialNetworking

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(path.components(separatedBy: "/").map(PathComponent.constant))

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

    func update(_ req: Request) async throws -> T.DTO {
        let user = try req.auth.require(User.self)
        let id = try req.parameters.require(restfulIDKey, as: T.IDValue.self)

        guard
            let socialNetworking = try await user.$social.query(on: req.db)
                .filter(\.$id == id)
                .first()
        else {
            throw Abort(.notFound)
        }
        return try await performUpdate(socialNetworking, on: req)
    }

    func delete(_ req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let id = try req.parameters.require(restfulIDKey, as: T.IDValue.self)

        guard
            let saved = try await user.$social.query(on: req.db)
                .filter(\.$id == id)
                .first()
        else {
            throw Abort(.notFound)
        }
        try await saved.delete(on: req.db)
        return .ok
    }

    func applyingFields(_ builder: QueryBuilder<SocialNetworking>) -> QueryBuilder<SocialNetworking>
    {
        builder.with(\.$service)
    }

    func performUpdate(_ original: T?, on req: Request) async throws -> SocialNetworking.Coding {
        var serializedObject = try req.content.decode(T.DTO.self)
        serializedObject.userId = try req.auth.require(User.self).requireID()

        var upgrade = T.init()

        if let original = original {
            upgrade = try original.update(with: serializedObject)
        } else {
            upgrade = try T.init(from: serializedObject)
            upgrade.id = nil
        }

        try await upgrade.save(on: req.db)

        // Make sure `$socialNetworkingService` has been eager loaded
        // before try `model.dataTransferObject()`.
        try await upgrade.$service.load(on: req.db)

        return try upgrade.dataTransferObject()
    }
}
