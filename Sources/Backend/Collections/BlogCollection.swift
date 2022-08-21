import Fluent
import Vapor

class BlogCollection: RouteCollection {

    private let restfulIDKey = "id"

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(.constant(Blog.schema))

        routes.on(.GET, use: readAll)
        routes.on(.GET, .parameter(restfulIDKey), use: read)

        routes.group("categories") { (builder) in
            builder.on(.GET, use: readBlogCategories)
            builder.on(.GET, .parameter(restfulIDKey), use: readBlogCategory)
        }

        let trusted = routes.grouped([
            User.authenticator(),
            Token.authenticator(),
            User.guardMiddleware(),
        ])

        trusted.on(.POST, use: create)
        trusted.on(.PUT, .parameter(restfulIDKey), use: update)
        trusted.on(.DELETE, .parameter(restfulIDKey), use: delete)
    }

    func create(_ req: Request) async throws -> Blog.DTO {
        var newValue = try req.content.decode(Blog.DTO.self)
        newValue.userId = try req.owner.__id

        // Make sure this blog has content
        guard let article = newValue.content else {
            throw Abort(.unprocessableEntity, reason: "Value required for key 'content'.")
        }

        let categories = try newValue.categories.map(BlogCategory.fromBridgedDTO)

        let model = try Blog.fromBridgedDTO(newValue)
        model.id = nil

        let originalBlogAlias = model.alias

        // Save blog file path to the database.
        model.content = try await req.fileio.writeFile(
            .init(string: article),
            path: self.filepath(req, alias: model.alias),
            relative: ""
        ).get()

        try await req.blog.create(model, categories: categories)

        // Remove old blogs with the same alias.
        if originalBlogAlias != model.alias {
            let alias = originalBlogAlias
            removeBlog(alias, on: req)
        }

        var result = try model.bridged()
        result.content = article
        return result
    }

    func read(_ req: Request) async throws -> Blog.DTO {
        guard let saved = try await query(on: req).first() else {
            throw Abort(.notFound)
        }

        var byteBuffer = try await req.fileio.collectFile(at: filepath(req, alias: saved.alias))

        var result = try saved.bridged()
        result.content = byteBuffer.readString(length: byteBuffer.readableBytes) ?? ""
        return result
    }

    func readAll(_ req: Request) async throws -> [Blog.DTO] {
        struct SupportedQueries: Decodable {
            var categories: String?
        }

        let queryBuilder = try req.blog.queryAll()
        let supportedQueries = try req.query.decode(SupportedQueries.self)

        if let categories = supportedQueries.categories {
            queryBuilder.filter(BlogCategory.self, \BlogCategory.$name ~~ categories)
        }

        return try await queryBuilder.all().map {
            try $0.bridged()
        }
    }

    func update(_ req: Request) async throws -> Blog.DTO {
        guard let saved = try await query(on: req, owned: true).first() else {
            throw Abort(.notFound)
        }

        var newValue = try req.content.decode(Blog.DTO.self)
        newValue.userId = try req.owner.__id

        // Make sure this blog has content
        guard let article = newValue.content else {
            throw Abort(.unprocessableEntity, reason: "Value required for key 'content'.")
        }

        let categories = try newValue.categories.map(BlogCategory.fromBridgedDTO)

        let originalBlogAlias = saved.alias
        try saved.update(with: newValue)

        saved.content = try await req.fileio.writeFile(
            .init(string: article),
            path: self.filepath(req, alias: saved.alias),
            relative: ""
        ).get()

        try await req.blog.update(saved, categories: categories)

        // Remove old blogs with the same alias.
        if originalBlogAlias != saved.alias {
            let alias = originalBlogAlias
            removeBlog(alias, on: req)
        }

        var result = try saved.bridged()
        result.content = article
        return result
    }

    func delete(_ req: Request) async throws -> HTTPResponseStatus {
        let saved = try await query(on: req, owned: true).first()

        guard let saved = saved else {
            return .ok
        }

        try await req.blog.delete(saved.requireID())

        removeBlog(saved.alias, on: req)

        return .ok
    }

    private func query(on req: Request, owned: Bool = false) throws -> QueryBuilder<Blog> {
        let builder = try req.blog.query(owned: owned)
        if let id = req.parameters.get(restfulIDKey, as: Blog.IDValue.self) {
            builder.filter(\._$id == id)
        } else if let alias = req.parameters.get(restfulIDKey) {
            builder.filter(\.$alias == alias)
        } else {
            throw Abort(.badRequest)
        }
        return builder
    }

    private func filepath(_ req: Request, alias: String) -> String {
        return req.application.directory.resourcesDirectory + "blog/\(alias).md"
    }

    private func removeBlog(_ alias: String, on req: Request) {
        var isDirectory = ObjCBool(false)
        let filepath = filepath(req, alias: alias)
        if FileManager.default.fileExists(atPath: filepath, isDirectory: &isDirectory),
            isDirectory.boolValue == false
        {
            try? FileManager.default.removeItem(atPath: filepath)
        }
    }
}

extension BlogCollection {
    func readBlogCategories(_ req: Request) throws -> Response {
        req.redirect(to: "/\(BlogCategory.schema)")
    }

    func readBlogCategory(_ req: Request) throws -> Response {
        guard let id = req.parameters.get(restfulIDKey) else {
            throw Abort(.notFound)
        }
        return req.redirect(to: "/\(BlogCategory.schema)/\(id)")
    }
}
