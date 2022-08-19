import FluentKit
import FluentMySQLDriver
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
        try await performUpdate(nil, on: req)
    }
    
    func read(_ req: Request) async throws -> Blog.DTO {
        var builder = try query(on: req)
        builder = applyingEagerLoaders(builder)

        guard let blog = try await builder.first() else {
            throw Abort(.notFound)
        }

        var byteBuffer = try await req.fileio.collectFile(at: filepath(req, alias: blog.alias))

        var coding = try blog.dataTransferObject()
        coding.content = byteBuffer.readString(length: byteBuffer.readableBytes) ?? ""
        return coding
    }

    func readAll(_ req: Request) async throws -> [Blog.DTO] {
        struct SupportedQueries: Decodable {
            var categories: String?
        }

        var queryBuilder = req.repository.blog.query()
        queryBuilder = applyingFieldsForQueryAll(queryBuilder)
        queryBuilder = applyingEagerLoaders(queryBuilder)
        
        let supportedQueries = try req.query.decode(SupportedQueries.self)

        if let categories = supportedQueries.categories {
            queryBuilder.filter(BlogCategory.self, \BlogCategory.$name ~~ categories)
        }

        return try await queryBuilder.all().map {
            try $0.dataTransferObject()
        }
    }

    func update(_ req: Request) async throws -> Blog.DTO {
        guard
            let blog = try await query(on: req)
                .filter(\.$user.$id == req.uid)
                .with(\.$categories)
                .first()
        else {
            throw Abort(.notFound)
        }

        return try await performUpdate(blog, on: req)
    }

    func delete(_ req: Request) async throws -> HTTPResponseStatus {
        guard
            let saved = try await query(on: req)
                .filter(\.$user.$id == req.uid)
                .with(\.$categories)
                .first()
        else {
            throw Abort(.notFound)
        }
        
        try await saved.$categories.detach(saved.categories, on: req.db)
        
        try await req.repository.blog.delete(saved.requireID())
        
        Task {
            self.removeBlog(saved.alias, on: req)
        }
        
        return .ok
    }

    private func query(on req: Request) throws -> QueryBuilder<Blog> {
        let builder = req.repository.blog.query()
        if let id = req.parameters.get(restfulIDKey, as: Blog.IDValue.self) {
            builder.filter(\._$id == id)
        } else if let alias = req.parameters.get(restfulIDKey) {
            builder.filter(\.$alias == alias)
        } else {
            throw Abort(.badRequest)
        }
        return builder
    }

    func applyingFieldsForQueryAll(_ builder: QueryBuilder<Blog>) -> QueryBuilder<Blog> {
        builder
            .field(\.$id)
            .field(\.$alias)
            .field(\.$title)
            .field(\.$artworkUrl)
            .field(\.$excerpt)
            .field(\.$tags)
            .field(\.$createdAt)
            .field(\.$updatedAt)
            .field(\.$user.$id)
    }

    func applyingEagerLoaders(_ builder: QueryBuilder<Blog>) -> QueryBuilder<Blog> {
        builder.with(\.$categories)
    }

    func performUpdate(_ original: Blog?, on req: Request) async throws -> Blog.DTO {
        var serializedObject = try req.content.decode(Blog.DTO.self)
        serializedObject.userId = try req.uid

        // Make sure this blog has content
        guard let article = serializedObject.content else {
            throw Abort(.unprocessableEntity, reason: "Value required for key 'content'.")
        }

        let content = article

        let categories = try serializedObject.categories.map(BlogCategory.init)

        var blog: Blog

        var originalBlogAlias: String

        if let original = original {
            originalBlogAlias = original.alias
            blog = try original.update(with: serializedObject)
        } else {
            blog = try Blog.init(from: serializedObject)
            blog.id = nil
            originalBlogAlias = blog.alias
        }

        try await req.repository.blog.save(blog)

        if originalBlogAlias != blog.alias {
            self.removeBlog(originalBlogAlias, on: req)
        }

        blog.content = try await req.fileio.writeFile(
            .init(string: content),
            path: self.filepath(req, alias: blog.alias),
            relative: ""
        ).get()

        let difference = categories.difference(from: blog.$categories.value ?? []) {
            $0.id == $1.id
        }

        for diff in difference {
            switch diff {
                case .insert(offset: _, element: let category, associatedWith: _):
                    try await blog.$categories.attach(category, on: req.db)
                case .remove(offset: _, element: let category, associatedWith: _):
                    try await blog.$categories.detach(category, on: req.db)
            }
        }

        try await blog.$categories.load(on: req.db)

        var result = try blog.dataTransferObject()
        result.content = content
        return result
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
