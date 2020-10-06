import Vapor
import FluentMySQLDriver

class BlogCollection: RestfulApiCollection {
    typealias T = Blog

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(.constant(path))

        let path = PathComponent.parameter(restfulIDKey)

        routes.on(.GET, use: readAll)
        routes.on(.GET, path, use: read)

        let trusted = routes.grouped([
            User.authenticator(),
            Token.authenticator(),
            User.guardMiddleware()
        ])

        trusted.on(.POST, use: create)
        trusted.on(.PUT, path, use: update)
        trusted.on(.DELETE, path, use: delete)
    }

    func read(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        var model: T!

        return try queryBuilder(on: req)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap({ saved -> EventLoopFuture<ByteBuffer> in
                model = saved
                return req.fileio.collectFile(at: self._filepath(req, blog: saved))
            })
            .flatMapThrowing({
                var byteBuffer = $0
                var coding = try model.reverted()
                coding.content = byteBuffer.readString(length: byteBuffer.readableBytes) ?? ""
                return coding
            })
    }

    func readAll(_ req: Request) throws -> EventLoopFuture<[Blog.Coding]> {
        Blog.query(on: req.db)
            .field(\.$id)
            .field(\.$alias)
            .field(\.$title)
            .field(\.$artworkUrl)
            .field(\.$excerpt)
            .field(\.$tags)
            .field(\.$createdAt)
            .field(\.$updatedAt)
            .field(\.$user.$id)
            .all()
            .flatMapEachThrowing({
                try $0.reverted()
            })
    }

    func update(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        let coding = try req.content.decode(T.SerializedObject.self)

        let upgrade = try T.init(content: coding)

        return try topLevelQueryBuilder(on: req)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap({
                // If alias changed we should remove old blog content file.
                if $0.alias != upgrade.alias {
                    self._removeBlog($0, on: req)
                }

                $0.merge(upgrade)
                return self.performUpdate($0, on: req)
            })
    }

    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try topLevelQueryBuilder(on: req)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap({ saved in
                saved.delete(on: req.db).flatMap({
                    self._removeBlog(saved, on: req)
                    return req.eventLoop.makeSucceededFuture(.ok)
                })
            })
    }

    func performUpdate(
        _ upgrade: T,
        on req: Request
    ) -> EventLoopFuture<T.SerializedObject> {

        let content = upgrade.contentUrl

        upgrade.contentUrl = ""

        /// Blog update logic.
        /// - 1. update blog meta info(e.g. title excerpt ...)
        /// - 2. write blog content to local file
        /// - 3. update `blog.contentUrl` to point to that file writed in step 2 and save.
        return upgrade.save(on: req.db)
            .flatMapErrorThrowing({
                if case MySQLError.duplicateEntry = $0 {
                    throw Abort.init(.unprocessableEntity, reason: "Value for key 'alias' already exsit.")
                }
                throw $0
            })
            .flatMap({
                req.fileio.writeFile(.init(string: content), path: self._filepath(req, blog: upgrade), relative: "")
            })
            .flatMap({ path -> EventLoopFuture<Void> in
                upgrade.contentUrl = path
                return upgrade.update(on: req.db)
            })
            .flatMapThrowing({ _ in
                var result = try upgrade.reverted()
                result.content = content
                return result
            })
    }

    func queryBuilder(on req: Request) throws -> QueryBuilder<Blog> {
        let queryBuilder = T.query(on: req.db)

        if let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) {
            queryBuilder.filter(\._$id == id)
        } else if let alias = req.parameters.get(restfulIDKey) {
            queryBuilder.filter(\.$alias == alias)
        } else {
            throw Abort(.notFound)
        }

        return queryBuilder
    }

    private func _filepath(_ req: Request, blog: Blog) -> String {
        return req.application.directory.resourcesDirectory + "blog/\(blog.alias).md"
    }

    private func _removeBlog(_ blog: Blog, on req: Request) {
        var isDirectory = ObjCBool(false)
        let filepath = _filepath(req, blog: blog)
        if FileManager.default.fileExists(atPath: filepath, isDirectory: &isDirectory),
           isDirectory.boolValue == false {
            try? FileManager.default.removeItem(atPath: filepath)
        }
    }
}
