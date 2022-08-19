import Fluent
import Vapor

class UserCollection: RouteCollection {

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

    private let restfulIDKey = "id"

    func boot(routes: RoutesBuilder) throws {

        let users = routes.grouped(.constant(User.schema))

        users.on(.POST, use: create)
        users.on(.GET, use: readAll)
        users.on(.GET, .parameter(restfulIDKey), use: read)
        users.on(.GET, .parameter(restfulIDKey), "blog", use: readAllBlog)
        users.on(.GET, .parameter(restfulIDKey), "resume", use: readResume)

        let trusted = users.grouped([
            User.authenticator(),
            Token.authenticator(),
            User.guardMiddleware(),
        ])
        trusted.on(.PUT, .parameter(restfulIDKey), use: update)
        trusted.on(.DELETE, .parameter(restfulIDKey), use: delete)
        trusted.on(
            .PATCH,
            .parameter(restfulIDKey),
            "profile_image",
            body: .collect(maxSize: "100kb"),
            use: patch
        )
        trusted.on(
            .POST,
            .parameter(restfulIDKey),
            "social_networking",
            use: createSocialNetworking
        )
    }

    /// Register new user with `User.Creation` msg.
    /// - seealso: `User.Creation` for more creation content info.
    /// - note: We make `username` unique so if the `username` already taken an `conflic` statu will be
    /// send to custom.
    func create(_ req: Request) async throws -> User.DTO {
        try User.Creation.validate(content: req)
        let user = try User.init(req.content.decode(User.Creation.self))

        try await req.repository.user.create(user)

        return try user.dataTransferObject()
    }

    /// Query user with specified`userID`.
    /// - seealso: `readAll(_:)`
    func read(_ req: Request) async throws -> User.DTO {
        let supportedQueries = try req.query.decode(SupportedQueries.self)

        let builder = try query(on: req).addEagerLoaders(with: supportedQueries)

        guard let user = try await builder.first() else {
            throw Abort(.notFound)
        }

        return try user.dataTransferObject()
    }

    func readAll(_ req: Request) async throws -> [User.DTO] {
        let supportedQueries = try req.query.decode(SupportedQueries.self)

        let query = req.repository.user.query().addEagerLoaders(with: supportedQueries)

        return try await query.all().map {
            try $0.dataTransferObject()
        }
    }

    /// Update exists user with `User.Coding` which contain all properties that user need updated.
    func update(_ req: Request) async throws -> User.DTO {
        let newValue = try req.content.decode(User.DTO.self)

        let saved = try await req.repository.user.identified(by: req.uid)
        try saved.update(with: newValue)

        try await req.repository.user.update(saved)

        return try saved.dataTransferObject()
    }

    func patch(_ req: Request) async throws -> User.DTO {
        let saved = try await req.repository.user.identified(by: req.uid)
        saved.avatarUrl = try await uploadImageFile(req).get()

        try await req.repository.user.update(saved)

        return try saved.dataTransferObject()
    }

    func delete(_ req: Request) async throws -> HTTPResponseStatus {
        try await req.repository.user.delete(req.uid)
        return .ok
    }

    private func query(on req: Request) throws -> QueryBuilder<User> {
        let builder = req.repository.user.query()

        if let id = req.parameters.get(restfulIDKey, as: User.IDValue.self) {
            builder.filter(\._$id == id)
        } else if let id = req.parameters.get(restfulIDKey) {
            builder.filter(User.FieldKeys.username, .equal, id)
        } else {
            if req.parameters.get(restfulIDKey) != nil {
                throw Abort(.unprocessableEntity)
            } else {
                throw Abort(.internalServerError)
            }
        }

        return builder
    }
}

extension QueryBuilder where Model == User {

    fileprivate func addEagerLoaders(with queries: UserCollection.SupportedQueries) -> Self {
        if queries.includeExperience ?? false {
            with(\.$experiences) {
                $0.with(\.$industries)
            }
        }

        if queries.includeEducation ?? false {
            with(\.$education)
        }

        if queries.includeSNS ?? false {
            with(\.$social) {
                $0.with(\.$service)
            }
        }

        if queries.includeProjects ?? false {
            with(\.$projects)
        }

        if queries.includeSkill ?? false {
            with(\.$skill)
        }

        if queries.includeBlog ?? false {
            with(\.$blog) {
                $0.with(\.$categories)
            }
        }
        return self
    }
}

// MARK: Blog
extension UserCollection {
    func readAllBlog(_ req: Request) async throws -> [Blog.DTO] {
        guard let user = try await query(on: req).first() else {
            throw Abort(.notFound)
        }

        return try await req.repository.blog.queryAll()
            .filter(\.$user.$id == user.requireID())
            .all()
            .map {
                try $0.dataTransferObject()
            }
    }
}

// MARK: CV
extension UserCollection {
    func readResume(_ req: Request) async throws -> User.DTO {
        guard let id = req.parameters.get(restfulIDKey, as: String.self) else {
            throw Abort(.badRequest)
        }

        let resume = try await req.repository.user.formatted(by: id)

        return try resume.dataTransferObject()
    }
}

// MARK: Social Networking
extension UserCollection {
    func createSocialNetworking(_ request: Request) async throws -> SocialNetworking.DTO {
        let serializedObject = try request.content.decode(SocialNetworking.DTO.self)

        let model = try SocialNetworking(from: serializedObject)
        model.$user.id = try request.auth.require(User.self).requireID()

        try await model.save(on: request.db)

        try await model.$service.load(on: request.db)

        return try model.dataTransferObject()
    }
}
