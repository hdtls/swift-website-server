import Vapor

extension User {
    struct Queries: Codable {
        var emb: String?

        private var _emb: [Substring] {
            emb?.split(separator: ".") ?? []
        }

        var includeExperience: Bool {
            _emb.contains("exp")
        }

        var includeEducation: Bool {
            _emb.contains("edu")
        }

        var includeSNS: Bool {
            _emb.contains("sns")
        }

        var includeProjects: Bool {
            _emb.contains("proj")
        }

        var includeSkill: Bool {
            _emb.contains("skill")
        }

        var includeBlog: Bool {
            _emb.contains("blog")
        }
    }
}

extension User.DTO {

    mutating func beforeEncode() throws {
        avatarUrl = avatarUrl?.bucketURLString()
        // Chain beforeEncode to nested content.
        projects = try projects?.map {
            var project = $0
            try project.beforeEncode()
            return project
        }
    }
}

class UserCollection: RouteCollection {

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

        try await req.user.create(user)

        return try user.bridged()
    }

    /// Query user with specified`userID`.
    /// - seealso: `readAll(_:)`
    func read(_ req: Request) async throws -> User.DTO {
        let queries = try req.query.decode(User.Queries.self)

        return try await identified(on: req, queries: queries).bridged()
    }

    func readAll(_ req: Request) async throws -> [User.DTO] {
        let queries = try req.query.decode(User.Queries.self)

        return try await req.user.readAll(queries: queries).map {
            try $0.bridged()
        }
    }

    /// Update exists user with `User.Coding` which contain all properties that user need updated.
    func update(_ req: Request) async throws -> User.DTO {
        let newValue = try req.content.decode(User.DTO.self)

        let saved = try await req.user.identified(by: req.owner.__id)
        try saved.update(with: newValue)

        try await req.user.update(saved)

        return try saved.bridged()
    }

    func patch(_ req: Request) async throws -> User.DTO {
        let saved = try await req.user.identified(by: req.owner.__id)
        saved.avatarUrl = try await uploadImageFile(req).get()

        try await req.user.update(saved)

        return try saved.bridged()
    }

    func delete(_ req: Request) async throws -> HTTPResponseStatus {
        try await req.user.delete(req.owner.__id)
        return .ok
    }

    private func identified(on req: Request, queries: User.Queries?) async throws -> User {
        if let id = req.parameters.get(restfulIDKey, as: User.IDValue.self) {
            guard let queries = queries else {
                return try await req.user.identified(by: id)
            }
            return try await req.user.identified(by: id, queries: queries)
        } else if let id = req.parameters.get(restfulIDKey) {
            guard let queries = queries else {
                return try await req.user.identified(by: id)
            }
            return try await req.user.identified(by: id, queries: queries)
        } else {
            if req.parameters.get(restfulIDKey) != nil {
                throw Abort(.unprocessableEntity)
            } else {
                throw Abort(.internalServerError)
            }
        }
    }
}

extension UserCollection {
    func readAllBlog(_ req: Request) async throws -> [Blog.DTO] {
        let user = try await identified(on: req, queries: nil)

        return try await req.blog.queryAll()
            .filter(\.$user.$id, .equal, user.__id)
            .all()
            .map {
                try $0.bridged()
            }
    }
}

extension UserCollection {
    func readResume(_ req: Request) async throws -> User.DTO {
        let queries = User.Queries.init(emb: "exp.edu.sns.proj.skill")

        return try await identified(on: req, queries: queries).bridged()
    }
}

extension UserCollection {
    func createSocialNetworking(_ req: Request) async throws -> SocialNetworking.DTO {
        var newValue = try req.content.decode(SocialNetworking.DTO.self)
        newValue.userId = try req.owner.__id

        let model = try SocialNetworking.fromBridgedDTO(newValue)

        try await req.socialNetworking.create(model)

        return try model.bridged()
    }
}
