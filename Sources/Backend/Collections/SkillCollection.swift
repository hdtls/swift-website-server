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
        let model = try Skill.fromBridgedDTO(req.content.decode(Skill.DTO.self))
        model.id = nil

        try await req.skill.create(model)

        return try model.bridged()
    }

    func read(_ req: Request) async throws -> Skill.DTO {
        let id = try req.parameters.require(restfulIDKey, as: Skill.IDValue.self)

        let result = try await req.skill.identified(by: id)

        return try result.bridged()
    }

    func readAll(_ req: Request) async throws -> [Skill.DTO] {
        try await req.skill.readAll().map {
            try $0.bridged()
        }
    }

    func update(_ req: Request) async throws -> Skill.DTO {
        let id = try req.parameters.require(restfulIDKey, as: Skill.IDValue.self)

        let newValue = try req.content.decode(Skill.DTO.self)

        let saved = try await req.skill.identified(by: id, owned: true)
        try saved.update(with: newValue)

        try await req.skill.update(saved)

        return try saved.bridged()
    }

    func delete(_ req: Request) async throws -> HTTPResponseStatus {
        let id = try req.parameters.require(restfulIDKey, as: Skill.IDValue.self)

        try await req.skill.delete(id)

        return .ok
    }
}
