import Vapor

class BlogCategoryCollection: RouteCollection {

    private let restfulIDKey = "id"

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(.constant(BlogCategory.schema))
        routes.on(.POST, use: create)
        routes.on(.GET, .parameter(restfulIDKey), use: read)
        routes.on(.GET, use: readAll)
        routes.on(.PUT, .parameter(restfulIDKey), use: update)
        routes.on(.DELETE, .parameter(restfulIDKey), use: delete)
    }

    func create(_ req: Request) async throws -> BlogCategory.DTO {
        let newValue = try req.content.decode(BlogCategory.DTO.self)

        let model = try BlogCategory.fromBridgedDTO(newValue)
        model.id = nil

        try await req.blogCategory.create(model)

        return try model.bridged()
    }

    func read(_ req: Request) async throws -> BlogCategory.DTO {
        let id = try req.parameters.require(restfulIDKey, as: BlogCategory.IDValue.self)

        let result = try await req.blogCategory.identified(by: id)

        return try result.bridged()
    }

    func readAll(_ req: Request) async throws -> [BlogCategory.DTO] {
        try await req.blogCategory.readAll().map {
            try $0.bridged()
        }
    }

    func update(_ req: Request) async throws -> BlogCategory.DTO {
        let id = try req.parameters.require(restfulIDKey, as: BlogCategory.IDValue.self)

        let newValue = try req.content.decode(BlogCategory.DTO.self)

        let saved = try await req.blogCategory.identified(by: id)
        try saved.update(with: newValue)

        try await req.blogCategory.update(saved)

        return try saved.bridged()
    }

    func delete(_ req: Request) async throws -> HTTPResponseStatus {
        let id = try req.parameters.require(restfulIDKey, as: BlogCategory.IDValue.self)

        try await req.blogCategory.delete(id)

        return .ok
    }
}
