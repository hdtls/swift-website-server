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
        newValue.userId = try req.owner.__id

        let model = try Education.fromBridgedDTO(newValue)
        model.id = nil

        try await req.education.create(model)

        return try model.bridged()
    }

    func read(_ req: Request) async throws -> Education.DTO {
        let id = try req.parameters.require(restfulIDKey, as: Education.IDValue.self)

        let saved = try await req.education.identified(by: id)

        return try saved.bridged()
    }

    func readAll(_ req: Request) async throws -> [Education.DTO] {
        try await req.education.readAll().map {
            try $0.bridged()
        }
    }

    func update(_ req: Request) async throws -> Education.DTO {
        let id = try req.parameters.require(restfulIDKey, as: Education.IDValue.self)

        var newValue = try req.content.decode(Education.DTO.self)
        newValue.userId = try req.owner.__id

        let saved = try await req.education.identified(by: id, owned: true)
        try saved.update(with: newValue)

        precondition(saved.$user.id == newValue.userId)
        try await req.education.update(saved)

        return try saved.bridged()
    }

    func delete(_ req: Request) async throws -> HTTPResponseStatus {
        let id = try req.parameters.require(restfulIDKey, as: Education.IDValue.self)

        try await req.education.delete(id)

        return .ok
    }
}
