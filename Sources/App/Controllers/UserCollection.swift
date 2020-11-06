import Vapor
import FluentMySQLDriver

class UserCollection: RestfulApiCollection {
    typealias T = User

    func boot(routes: RoutesBuilder) throws {

        let users = routes.grouped(.constant(path))

        let path  = PathComponent.parameter(restfulIDKey)

        users.on(.POST, use: create)
        users.on(.GET, use: readAll)
        users.on(.GET, path, use: read)
        users.on(.GET, path, "blog", use: readAllBlog)
        users.on(.GET, path, "resume", use: readResume)

        let trusted = users.grouped([
            User.authenticator(),
            Token.authenticator(),
            User.guardMiddleware()
        ])
        trusted.on(.PUT, path, use: update)
        trusted.on(.DELETE, path, use: delete)
        trusted.on(.PATCH, path, "profile_image", body: .collect(maxSize: "100kb"), use: patch)
    }

    /// Register new user with `User.Creation` msg. when success a new user and token is registed.
    /// - seealso: `User.Creation` for more creation content info.
    /// - note: We make `username` unique so if the `username` already taken an `conflic` statu will be
    /// send to custom.
    func create(_ req: Request) throws -> EventLoopFuture<AuthorizeMsg> {
        try User.Creation.validate(content: req)
        
        let user = try User.init(req.content.decode(User.Creation.self))

        var token: Token!

        return user.save(on: req.db)
            .flatMapErrorThrowing({
                if case MySQLError.duplicateEntry = $0 {
                    throw Abort.init(.unprocessableEntity, reason: "Value for key 'username' already exsit.")
                }
                throw $0
            })
            .flatMap({
                guard let unsafeToken = try? Token.init(user) else {
                    return user.delete(on: req.db).flatMap({
                        req.eventLoop.makeFailedFuture(Abort(.internalServerError))
                    })
                }
                token = unsafeToken
                return token.save(on: req.db)
            })
            .flatMapThrowing({
                try AuthorizeMsg.init(user: user.reverted(), token: token)
            })
    }

    /// Query user with specified`userID`.
    /// - seealso: `UserCollection.queryAllUsers(_:)`
    func read(_ req: Request) throws -> EventLoopFuture<User.Coding> {
        try readAll(req)
            .map({ $0.first })
            .unwrap(or: Abort.init(.notFound))
    }

    /// Query users, if `userID` exist add `userID` to filter . there are three query parameters,
    /// `incl_wrk_exp`:  default is `false`, if `true` the result of user will include user's work experiances.
    /// `incl_edu_exp`:  default is `false`, if `true` the result of user will include user's education experiances.
    /// `incl_sns`:  default is `false`, if `true` the result of user will include user's web links.
    /// - note: This is a mix function the `userID` is optional value.
    func readAll(_ req: Request) throws -> EventLoopFuture<[User.Coding]> {
        struct SupportedQueries: Decodable {
            var includeExperience: Bool?
            var includeEducation: Bool?
            var includeSNS: Bool?
            var includeProjects: Bool?
            var includeSkill: Bool?
            var includeBlog: Bool?

            enum CodingKeys: String, CodingKey {
                case includeExperience = "incl_wrk_exp"
                case includeEducation = "incl_edu_exp"
                case includeSNS = "incl_sns"
                case includeProjects = "incl_projs"
                case includeSkill = "incl_skill"
                case includeBlog = "incl_blog"
            }
        }

        var queryBuilder = User.query(on: req.db)

        // Logged in user can query `User` by `id` or unique property `username`.
        // User ID has higher priority to be used for query.
        if let userID = req.parameters.get(restfulIDKey, as: User.IDValue.self) {
            queryBuilder = queryBuilder.filter(\.$id, .equal, userID)
        } else if let userID = req.parameters.get(restfulIDKey) {
            queryBuilder = queryBuilder.filter(\.$username, .equal, userID)
        }

        let supportedQueries = try req.query.decode(SupportedQueries.self)

        // Include work experiances to query if the key `incl_wrk_exp` exist.
        if supportedQueries.includeExperience ?? false {
            queryBuilder.with(\.$workExps) {
                $0.with(\.$industries)
            }
        }

        // Include edu experiances to query if the key `incl_wrk_exp` exist.
        if supportedQueries.includeEducation ?? false {
            queryBuilder.with(\.$eduExps)
        }

        if supportedQueries.includeSNS ?? false {
            queryBuilder.with(\.$social) {
                $0.with(\.$service)
            }
        }

        if supportedQueries.includeProjects ?? false {
            queryBuilder.with(\.$projects)
        }

        if supportedQueries.includeSkill ?? false {
            queryBuilder.with(\.$skill)
        }

        if supportedQueries.includeBlog ?? false {
            queryBuilder.with(\.$blog)
        }

        return queryBuilder
            .all()
            .flatMapEachThrowing({
                try $0.reverted()
            })
    }

    /// Update exists user with `User.Coding` which contain all properties that user need updated.
    func update(_ req: Request) throws -> EventLoopFuture<User.Coding> {
        let userId = try req.auth.require(User.self).requireID()
        let coding = try req.content.decode(User.Coding.self)
        let upgrade = User.init(content: coding)

        return User.find(userId, on: req.db)
            .unwrap(or: Abort.init(.notFound))
            .flatMap({ saved -> EventLoopFuture<User> in
                saved.merge(upgrade)
                return saved.update(on: req.db).map({ saved })
            })
            .flatMapThrowing({
                try $0.reverted()
            })
    }

    func patch(_ req: Request) throws -> EventLoopFuture<User.Coding> {
        let userId = try req.auth.require(User.self).requireID()

        return User.find(userId, on: req.db)
            .unwrap(or: Abort.init(.notFound))
            .flatMap({ saved -> EventLoopFuture<User> in
                do {
                    return try uploadImageFile(req)
                        .flatMap({
                            saved.avatarUrl = $0
                            return saved.update(on: req.db).map({ saved })
                        })
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
            })
            .flatMapThrowing({
                try $0.reverted()
            })
    }
}

extension UserCollection {
    // MARK: Blog
    func readAllBlog(_ req: Request) throws -> EventLoopFuture<[Blog.SerializedObject]> {
        let queryBuilder = User.query(on: req.db)

        if let id = req.parameters.get(restfulIDKey, as: User.IDValue.self) {
            queryBuilder.filter(\._$id == id)
        } else if let id = req.parameters.get(restfulIDKey) {
            queryBuilder.filter(User.FieldKeys.username.rawValue, .equal, id)
        } else {
            throw Abort(.notFound)
        }

        return queryBuilder.first()
            .unwrap(or: Abort(.notFound))
            .flatMap({
                $0.$blog.query(on: req.db)
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
            })
            .flatMapEachThrowing({
                try $0.reverted()
            })
    }
}

extension UserCollection {
    // MARK: CV
    func readResume(_ req: Request) throws -> EventLoopFuture<User.SerializedObject> {
        let queryBuilder = User.query(on: req.db)
        // Support for `id` and `username` check.
        if let id = req.parameters.get(restfulIDKey, as: User.IDValue.self) {
            queryBuilder.filter(\._$id == id)
        } else if let id = req.parameters.get(restfulIDKey) {
            queryBuilder.filter(User.FieldKeys.username.rawValue, .equal, id)
        } else {
            throw Abort(.notFound)
        }
        return queryBuilder
            .with(\.$projects)
            .with(\.$eduExps)
            .with(\.$workExps) {
                $0.with(\.$industries)
            }
            .with(\.$social) {
                $0.with(\.$service)
            }
            .with(\.$skill)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing({
                try $0.reverted()
            })
    }
}
