import FluentKit
import FluentMySQLDriver
import Vapor

class BlogCollection: ApiCollection {
    typealias T = Blog

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(.constant(path))

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

    func read(_ req: Request) async throws -> T.DTO {
        var builder = try specifiedIDQueryBuilder(on: req)
        builder = applyingEagerLoaders(builder)
        builder = applyingFields(builder)

        guard let blog = try await builder.first() else {
            throw Abort(.notFound)
        }

        var byteBuffer = try await req.fileio.collectFile(at: _filepath(req, alias: blog.alias))

        var coding = try blog.dataTransferObject()
        coding.content = byteBuffer.readString(length: byteBuffer.readableBytes) ?? ""
        return coding
    }

    func readAll(_ req: Request) async throws -> [T.DTO] {
        struct SupportedQueries: Decodable {
            var categories: String?
        }

        var queryBuilder = Blog.query(on: req.db)
        queryBuilder = applyingFieldsForQueryAll(queryBuilder)
        queryBuilder = applyingEagerLoadersForQueryAll(queryBuilder)

        let supportedQueries = try req.query.decode(SupportedQueries.self)

        if let categories = supportedQueries.categories {
            queryBuilder.filter(BlogCategory.self, \BlogCategory.$name ~~ categories)
        }

        return try await queryBuilder.all().map {
            try $0.dataTransferObject()
        }
    }

    func update(_ req: Request) async throws -> T.DTO {
        let userId = try req.auth.require(User.self).requireID()

        guard
            let blog = try await specifiedIDQueryBuilder(on: req)
                .filter(\.$user.$id == userId)
                .with(\.$categories)
                .first()
        else {
            throw Abort(.notFound)
        }

        return try await performUpdate(blog, on: req)
    }

    func delete(_ req: Request) async throws -> HTTPStatus {
        let userId = try req.auth.require(User.self).requireID()

        guard
            let saved = try await specifiedIDQueryBuilder(on: req)
                .filter(\.$user.$id == userId)
                .with(\.$categories)
                .first()
        else {
            throw Abort(.notFound)
        }

        try await saved.$categories.detach(saved.categories, on: req.db)
        try await saved.delete(on: req.db)
        Task {
            self._removeBlog(saved.alias, on: req)
        }
        return .ok
    }

    func specifiedIDQueryBuilder(on req: Request) throws -> QueryBuilder<T> {
        let builder = T.query(on: req.db)
        if let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) {
            builder.filter(\._$id == id)
        } else if let alias = req.parameters.get(restfulIDKey) {
            builder.filter(\.$alias == alias)
        } else {
            throw Abort(.badRequest)
        }
        return builder
    }

    func applyingFieldsForQueryAll(_ builder: QueryBuilder<T>) -> QueryBuilder<T> {
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

    func applyingEagerLoaders(_ builder: QueryBuilder<Blog>) -> QueryBuilder<T> {
        builder.with(\.$categories)
    }

    func performUpdate(_ original: T?, on req: Request) async throws -> T.DTO {

        var serializedObject = try req.content.decode(T.DTO.self)
        serializedObject.userId = try req.auth.require(User.self).requireID()

        // Make sure this blog has content
        guard let article = serializedObject.content else {
            throw Abort(.unprocessableEntity, reason: "Value required for key 'content'.")
        }

        let content = article

        let categories = try serializedObject.categories.map(BlogCategory.init)

        var blog: T

        var originalBlogAlias: String

        if let original = original {
            originalBlogAlias = original.alias
            blog = try original.update(with: serializedObject)
        } else {
            blog = try T.init(from: serializedObject)
            blog.id = nil
            originalBlogAlias = blog.alias
        }

        do {
            try await blog.save(on: req.db)
        } catch {
            if case MySQLError.duplicateEntry = error {
                throw Abort.init(
                    .unprocessableEntity,
                    reason: "Value for key 'alias' already exsit."
                )
            }
            throw error
        }

        if originalBlogAlias != blog.alias {
            self._removeBlog(originalBlogAlias, on: req)
        }

        blog.content = try await req.fileio.writeFile(
            .init(string: content),
            path: self._filepath(req, alias: blog.alias),
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

    private func _filepath(_ req: Request, alias: String) -> String {
        return req.application.directory.resourcesDirectory + "blog/\(alias).md"
    }

    private func _removeBlog(_ alias: String, on req: Request) {
        var isDirectory = ObjCBool(false)
        let filepath = _filepath(req, alias: alias)
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
