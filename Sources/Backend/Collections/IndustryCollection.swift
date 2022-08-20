import Vapor

class IndustryCollection: RouteCollection {

    private let restfulIDKey = "id"

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(.constant(Industry.schema))
        routes.on(.POST, use: create)
        routes.on(.GET, .parameter(restfulIDKey), use: read)
        routes.on(.GET, use: readAll)
        routes.on(.PUT, .parameter(restfulIDKey), use: update)
        routes.on(.DELETE, .parameter(restfulIDKey), use: delete)
    }

    func create(_ req: Request) async throws -> Industry.DTO {
        let coding = try req.content.decode(Industry.DTO.self)
        guard coding.title != nil else {
            throw Abort.init(.unprocessableEntity, reason: "Value required for key 'title'")
        }

        let model = try Industry(from: coding)
        model.id = nil

        try await req.industry.save(model)

        return try model.dataTransferObject()
    }

    func read(_ req: Request) async throws -> Industry.DTO {
        let id = try req.parameters.require(restfulIDKey, as: Industry.IDValue.self)

        let result = try await req.industry.identified(by: id)

        return try result.dataTransferObject()
    }

    func readAll(_ req: Request) async throws -> [Industry.DTO] {
        try await req.industry.readAll().map {
            try $0.dataTransferObject()
        }
    }

    func update(_ req: Request) async throws -> Industry.DTO {
        let id = try req.parameters.require(restfulIDKey, as: Industry.IDValue.self)

        let coding = try req.content.decode(Industry.DTO.self)
        guard coding.title != nil else {
            throw Abort.init(.unprocessableEntity, reason: "Value required for key 'title'")
        }

        let saved = try await req.industry.identified(by: id)
        try saved.update(with: coding)

        try await req.industry.save(saved)

        return try saved.dataTransferObject()
    }

    func delete(_ req: Request) async throws -> HTTPResponseStatus {
        let id = try req.parameters.require(restfulIDKey, as: Industry.IDValue.self)

        try await req.industry.delete(id)

        return .ok
    }
}
