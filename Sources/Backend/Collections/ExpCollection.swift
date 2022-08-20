import Vapor

class ExpCollection: RouteCollection {

    private let restfulIDKey: String = "id"

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(.constant(Experience.schema))

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

    func create(_ req: Request) async throws -> Experience.DTO {
        var newValue = try req.content.decode(Experience.DTO.self)
        newValue.userId = try req.owner.__id

        let industries: [Industry] = newValue.industries.map {
            let industry = Industry.init()
            industry.id = $0.id
            return industry
        }

        let model = try Experience(from: newValue)
        model.id = nil

        try await req.experience.create(model, industries: industries)

        return try model.dataTransferObject()
    }

    func read(_ req: Request) async throws -> Experience.DTO {
        let id = try req.parameters.require(restfulIDKey, as: Experience.IDValue.self)

        let saved = try await req.experience.identified(by: id)

        return try saved.dataTransferObject()
    }

    func readAll(_ req: Request) async throws -> [Experience.DTO] {
        try await req.experience.readAll().map {
            try $0.dataTransferObject()
        }
    }

    func update(_ req: Request) async throws -> Experience.DTO {
        let id = try req.parameters.require(restfulIDKey, as: Experience.IDValue.self)

        var newValue = try req.content.decode(Experience.DTO.self)
        newValue.userId = try req.owner.__id

        let industries: [Industry] = newValue.industries.map {
            let industry = Industry.init()
            industry.id = $0.id
            return industry
        }

        let saved = try await req.experience.identified(by: id, owned: true)
        try saved.update(with: newValue)

        precondition(saved.$user.id == newValue.userId)
        try await req.experience.update(saved, industries: industries)

        return try saved.dataTransferObject()
    }

    func delete(_ req: Request) async throws -> HTTPResponseStatus {
        let id = try req.parameters.require(restfulIDKey, as: Experience.IDValue.self)

        try await req.experience.delete(id)

        return .ok
    }
}
