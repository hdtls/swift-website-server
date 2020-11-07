import Vapor
import FluentKit
import FluentMySQLDriver

class BlogCollection: RestfulApiCollection {
    typealias T = Blog

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(.constant(path))

        let path = PathComponent.parameter(restfulIDKey)
        routes.on(.GET, use: readAll)
        routes.on(.GET, path, use: read)

        routes.group("categories") { (builder) in
            builder.on(.GET, use: readBlogCategories)
            builder.on(.GET, .parameter(restfulIDKey), use: readBlogCategory)
        }

        let trusted = routes.grouped([
            User.authenticator(),
            Token.authenticator(),
            User.guardMiddleware()
        ])

        trusted.on(.POST, use: create)
        trusted.on(.PUT, path, use: update)
        trusted.on(.DELETE, path, use: delete)
    }

    func create(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        return try performUpdate(on: req)
    }

    func read(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        var model: T!

        var builder = try specifiedIDQueryBuilder(on: req)
        builder = applyingEagerLoaders(builder)
        builder = applyingFields(builder)

        return builder
            .first()
            .unwrap(orError: Abort(.notFound))
            .flatMap({ saved -> EventLoopFuture<ByteBuffer> in
                model = saved
                return req.fileio.collectFile(at: self._filepath(req, alias: saved.alias))
            })
            .flatMapThrowing({
                var byteBuffer = $0
                var coding = try model.reverted()
                coding.content = byteBuffer.readString(length: byteBuffer.readableBytes) ?? ""
                return coding
            })
    }

    func readAll(_ req: Request) throws -> EventLoopFuture<[T.SerializedObject]> {
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

        return queryBuilder
            .all()
            .flatMapEachThrowing({
                try $0.reverted()
            })
    }

    func update(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        let userId = try req.auth.require(User.self).requireID()

        return try specifiedIDQueryBuilder(on: req)
            .filter(T.uidFieldKey, .equal, userId)
            .with(\.$categories)
            .first()
            .unwrap(orError: Abort(.notFound))
            .flatMap({
                do {
                    return try self.performUpdate($0, on: req)
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
            })
    }

    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let userId = try req.auth.require(User.self).requireID()

        return try specifiedIDQueryBuilder(on: req)
            .filter(T.uidFieldKey, .equal, userId)
            .first()
            .unwrap(orError: Abort(.notFound))
            .flatMap({ saved in
                saved.delete(on: req.db).flatMap({
                    self._removeBlog(saved.alias, on: req)
                    return req.eventLoop.makeSucceededFuture(.ok)
                })
            })
    }

    func performUpdate(_ original: T?, on req: Request) throws -> EventLoopFuture<T.SerializedObject> {

        let serializedObject = try req.content.decode(T.SerializedObject.self)

        // Make sure this blog has content
        guard let article = serializedObject.content else {
            throw Abort(.unprocessableEntity, reason: "Value required for key 'content'.")
        }

        let content = article

        let categories = serializedObject.categories

        var blog = try T.init(content: serializedObject)
        blog.$user.id = try req.auth.require(User.self).requireID()

        var originalBlogAlias = blog.alias

        if let original = original {
            originalBlogAlias = original.alias
            original.merge(blog)
            blog = original
        }

        return blog.save(on: req.db)
        .flatMapErrorThrowing({
            if case MySQLError.duplicateEntry = $0 {
                throw Abort.init(.unprocessableEntity, reason: "Value for key 'alias' already exsit.")
            }
            throw $0
        })
        .flatMap({
            if originalBlogAlias != blog.alias {
                self._removeBlog(originalBlogAlias, on: req)
            }
            return req.fileio.writeFile(.init(string: content), path: self._filepath(req, alias: blog.alias), relative: "")
                .map({
                    blog.contentUrl = $0
                })
        })
        .flatMap({ () -> EventLoopFuture<[BlogCategory]> in
            let difference = categories.difference(from: blog.$categories.value ?? []) {
                $0.id == $1.id
            }

            return EventLoopFuture<Void>.andAllSucceed(difference.map({
                switch $0 {
                case .insert(offset: _, element: let category, associatedWith: _):
                    return blog.$categories.attach(category, on: req.db)
                case .remove(offset: _, element: let category, associatedWith: _):
                    return blog.$categories.detach(category, on: req.db)
                }
            }), on: req.eventLoop)
            .flatMap({
                blog.$categories.get(reload: true, on: req.db)
            })
        })
        .flatMapThrowing({ _ in
            var result = try blog.reverted()
            result.content = content
            return result
        })
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

    func applyingFields(_ builder: QueryBuilder<T>) -> QueryBuilder<T> {
        builder
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

    func applyingEagerLoadersForQueryAll(_ builder: QueryBuilder<T>) -> QueryBuilder<T> {
        builder.with(\.$categories)
    }

    private func _filepath(_ req: Request, alias: String) -> String {
        return req.application.directory.resourcesDirectory + "blog/\(alias).md"
    }

    private func _removeBlog(_ alias: String, on req: Request) {
        var isDirectory = ObjCBool(false)
        let filepath = _filepath(req, alias: alias)
        if FileManager.default.fileExists(atPath: filepath, isDirectory: &isDirectory),
           isDirectory.boolValue == false {
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
