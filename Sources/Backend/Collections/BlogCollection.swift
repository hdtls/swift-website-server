import Vapor

extension Blog {
    struct Queries: Codable {
        var categories: String?
    }
}

extension Blog.DTO {
    
    mutating func beforeEncode() throws {
        artworkUrl = artworkUrl?.bucketURLString()
    }
}

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

        trusted.on(.POST, body: .collect(maxSize: "1mb"), use: create)
        trusted.on(.PUT, "front-matter", .parameter(restfulIDKey), use: updateFrontMatter)
        trusted.on(
            .PUT,
            .parameter(restfulIDKey),
            body: .collect(maxSize: "1mb"),
            use: updateBlogArticle
        )
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
        let url = makeFileURL(on: req, alias: model.alias)
        try await req.fileio.writeFile(.init(string: article), at: url.path)
        model.content = "/\(url.relativePath)"

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
        let saved = try await identified(on: req)

        let url = makeFileURL(on: req, alias: saved.alias)
        var byteBuffer = try await req.fileio.collectFile(at: url.path)

        var result = try saved.bridged()
        result.content = byteBuffer.readString(length: byteBuffer.readableBytes) ?? ""
        return result
    }

    func readAll(_ req: Request) async throws -> [Blog.DTO] {
        let queries = try req.query.decode(Blog.Queries.self)

        return try await req.blog.readAll(queries: queries).map {
            try $0.bridged()
        }
    }

    func updateFrontMatter(_ req: Request) async throws -> Blog.FrontMatter {
        let saved = try await identified(on: req)

        let frontMatter = try req.content.decode(Blog.FrontMatter.self)

        let categories = try frontMatter.categories.map(BlogCategory.fromBridgedDTO)

        let model = Blog.fromFrontMatter(frontMatter)
        model.id = try saved.requireID()
        model.$user.id = try req.owner.__id

        try await req.blog.update(model, categories: categories)

        return try model.frontMatter
    }

    func updateBlogArticle(_ req: Request) async throws -> Blog.DTO {
        let saved = try await identified(on: req)

        var newValue = try req.content.decode(Blog.DTO.self)
        newValue.userId = try req.owner.__id

        // Make sure this blog has content
        guard let article = newValue.content else {
            throw Abort(.unprocessableEntity, reason: "Value required for key 'content'.")
        }

        let categories = try newValue.categories.map(BlogCategory.fromBridgedDTO)

        let originalBlogAlias = saved.alias
        try saved.update(with: newValue)

        let url = makeFileURL(on: req, alias: saved.alias)
        try await req.fileio.writeFile(.init(string: article), at: url.path)
        saved.content = "/\(url.relativePath)"

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
        guard let saved = try? await identified(on: req) else {
            return .ok
        }

        try await req.blog.delete(saved.requireID())

        removeBlog(saved.alias, on: req)

        return .ok
    }

    private func identified(on req: Request) async throws -> Blog {
        if let id = req.parameters.get(restfulIDKey, as: Blog.IDValue.self) {
            return try await req.blog.identified(by: id)
        } else if let alias = req.parameters.get(restfulIDKey) {
            return try await req.blog.identified(by: alias)
        } else {
            if req.parameters.get(restfulIDKey) != nil {
                throw Abort(.unprocessableEntity)
            } else {
                throw Abort(.internalServerError)
            }
        }
    }

    private func makeFileURL(on req: Request, alias: String) -> URL {
        var url = URL(fileURLWithPath: "blog", relativeTo: URL(fileURLWithPath: req.application.directory.resourcesDirectory))
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        url.appendPathComponent("\(alias).md")
        return url
    }

    private func removeBlog(_ alias: String, on req: Request) {
        var isDirectory = ObjCBool(false)
        let filepath = makeFileURL(on: req, alias: alias).path
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
