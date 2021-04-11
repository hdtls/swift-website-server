import Vapor
import FluentMySQLDriver

class UserCollection: RestfulApiCollection {
    
    typealias T = User
    
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
                
        return user.save(on: req.db)
            .flatMapErrorThrowing({
                if case MySQLError.duplicateEntry = $0 {
                    throw Abort.init(.unprocessableEntity, reason: "Value for key 'username' already exsit.")
                }
                throw $0
            })
            .flatMap({
                guard let token = try? Token.init(user) else {
                    return user.delete(on: req.db).flatMap({
                        req.eventLoop.makeFailedFuture(Abort(.internalServerError))
                    })
                }
                return token.save(on: req.db).map { token }
            })
            .flatMapThrowing({
                try AuthorizeMsg.init(user: user.dataTransferObject(), token: $0)
            })
    }
    
    /// Query user with specified`userID`.
    /// - seealso: `readAll(_:)`
    func read(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        let supportedQueries = try req.query.decode(SupportedQueries.self)

        var builder = try specifiedIDQueryBuilder(on: req)
        builder = applyingFields(builder)
        builder = applyingEagerLoaders(builder, with: supportedQueries)
        
        return builder
            .first()
            .unwrap(orError: Abort(.notFound))
            .flatMapThrowing({
                try $0.dataTransferObject()
            })
    }
    
    func readAll(_ req: Request) throws -> EventLoopFuture<[User.SerializedObject]> {
        let supportedQueries = try req.query.decode(SupportedQueries.self)

        var builder = T.query(on: req.db)
        builder = applyingFieldsForQueryAll(builder)
        builder = applyingEagerLoadersForQueryAll(builder, with: supportedQueries)
        
        return builder
            .all()
            .flatMapEachThrowing({
                try $0.dataTransferObject()
            })
    }

    
    /// Update exists user with `User.Coding` which contain all properties that user need updated.
    func update(_ req: Request) throws -> EventLoopFuture<User.Coding> {
        let userId = try req.auth.require(User.self).requireID()
        let coding = try req.content.decode(User.Coding.self)
        let upgrade = User.init(from: coding)
        
        return User.find(userId, on: req.db)
            .unwrap(or: Abort.init(.notFound))
            .flatMap({ saved -> EventLoopFuture<User> in
                saved.update(with: upgrade)
                return saved.update(on: req.db).map({ saved })
            })
            .flatMapThrowing({
                try $0.dataTransferObject()
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
                try $0.dataTransferObject()
            })
    }
    
    func specifiedIDQueryBuilder(on req: Request) throws -> QueryBuilder<User> {
        let builder = T.query(on: req.db)
        if let id = req.parameters.get(restfulIDKey, as: User.IDValue.self) {
            builder.filter(\._$id == id)
        } else if let id = req.parameters.get(restfulIDKey) {
            builder.filter(User.FieldKeys.username.rawValue, .equal, id)
        } else {
            throw Abort(.notFound)
        }
        return builder
    }
    
    func applyingEagerLoaders(
        _ builder: QueryBuilder<User>,
        with supportedQueries: SupportedQueries
    ) -> QueryBuilder<User> {
        applyingEagerLoadersForQueryAll(builder, with: supportedQueries)
    }
    
    func applyingEagerLoadersForQueryAll(
        _ builder: QueryBuilder<User>,
        with supportedQueries: SupportedQueries
    ) -> QueryBuilder<User> {
        if supportedQueries.includeExperience ?? false {
            builder.with(\.$workExps) {
                $0.with(\.$industries)
            }
        }
        
        if supportedQueries.includeEducation ?? false {
            builder.with(\.$eduExps)
        }
        
        if supportedQueries.includeSNS ?? false {
            builder.with(\.$social) {
                $0.with(\.$service)
            }
        }
        
        if supportedQueries.includeProjects ?? false {
            builder.with(\.$projects)
        }
        
        if supportedQueries.includeSkill ?? false {
            builder.with(\.$skill)
        }
        
        if supportedQueries.includeBlog ?? false {
            builder.with(\.$blog) {
                $0.with(\.$categories)
            }
        }
        
        return builder
    }
}

extension UserCollection {
    // MARK: Blog
    func readAllBlog(_ req: Request) throws -> EventLoopFuture<[Blog.SerializedObject]> {
        try specifiedIDQueryBuilder(on: req)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap({
                return BlogCollection.init()
                    .applyingFieldsForQueryAll($0.$blog.query(on: req.db))
                    .all()
            })
            .flatMapEachThrowing({
                try $0.dataTransferObject()
            })
    }
}

extension UserCollection {
    // MARK: CV
    func readResume(_ req: Request) throws -> EventLoopFuture<User.SerializedObject> {
        try specifiedIDQueryBuilder(on: req)
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
                try $0.dataTransferObject()
            })
    }
}
