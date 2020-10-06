import Vapor

class UserCollection: RouteCollection {
    let profile = "profile/"

    let restfulIDKey = "id"

    func boot(routes: RoutesBuilder) throws {

        let users = routes.grouped("users")

        users.on(.POST, use: create)
        users.on(.GET, use: readAll)
        users.on(.GET, .parameter(restfulIDKey), use: read)

        let trusted = users.grouped([
            User.authenticator(),
            Token.authenticator(),
            User.guardMiddleware()
        ])
        trusted.on(.PUT, .parameter(restfulIDKey), use: update)
        trusted.on(.PATCH, .parameter(restfulIDKey), "profile", body: .collect(maxSize: "100kb"), use: patch)
    }

    /// Register new user with `User.Creation` msg. when success a new user and token is registed.
    /// - seealso: `User.Creation` for more creation content info.
    /// - note: We make `username` unique so if the `username` already taken an `conflic` statu will be
    /// send to custom.
    func create(_ req: Request) throws -> EventLoopFuture<AuthorizeMsg> {
        try User.Creation.validate(content: req)
        
        let user = try User.init(req.content.decode(User.Creation.self))

        var token: Token!

        return User.query(on: req.db)
            .filter(\.$username, .equal, user.username)
            .first()
            .flatMap({
                // If there is already have a user and username same as
                // `user.username` just throw a msg.
                guard $0 == nil else {
                    let error = Abort(.conflict, reason: "Username already taken")
                    return req.eventLoop.makeFailedFuture(error)
                }
                return user.save(on: req.db)
            })
            .flatMap({
                guard let unsafeToken = try? Token.init(user) else {
                    return req.eventLoop.makeFailedFuture(Abort(.internalServerError))
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
    func read(_ req: Request) -> EventLoopFuture<User.Coding> {
        readAll(req)
            .map({ $0.first })
            .unwrap(or: Abort.init(.notFound))
    }

    /// Query users, if `userID` exist add `userID` to filter . there are three query parameters,
    /// `incl_wrk_exp`:  default is `false`, if `true` the result of user will include user's work experiances.
    /// `incl_edu_exp`:  default is `false`, if `true` the result of user will include user's education experiances.
    /// `incl_sns`:  default is `false`, if `true` the result of user will include user's web links.
    /// - note: This is a mix function the `userID` is optional value.
    func readAll(_ req: Request) -> EventLoopFuture<[User.Coding]> {

        var queryBuilder = User.query(on: req.db)

        // Logged in user can query `User` by `id` or unique property `username`.
        // User ID has higher priority to be used for query.
        if let userID = req.parameters.get(restfulIDKey, as: User.IDValue.self) {
            queryBuilder = queryBuilder.filter(\.$id, .equal, userID)
        } else if let userID = req.parameters.get(restfulIDKey) {
            queryBuilder = queryBuilder.filter(\.$username, .equal, userID)
        }

        // Include work experiances to query if the key `incl_wrk_exp` exist.
        if (try? req.query.get(Bool.self, at: "incl_wrk_exp")) ?? false {
            queryBuilder.with(\.$workExps) {
                $0.with(\.$industry)
            }
        }

        // Include edu experiances to query if the key `incl_wrk_exp` exist.
        if (try? req.query.get(Bool.self, at: "incl_edu_exp")) ?? false {
            queryBuilder.with(\.$eduExps)
        }

        if (try? req.query.get(Bool.self, at: "incl_sns")) ?? false {
            queryBuilder.with(\.$social) {
                $0.with(\.$service)
            }
        }

        if (try? req.query.get(Bool.self, at: "incl_projs")) ?? false {
            queryBuilder.with(\.$projects)
        }

        if (try? req.query.get(Bool.self, at: "incl_skill")) ?? false {
            queryBuilder.with(\.$skill)
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
