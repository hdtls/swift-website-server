import Fluent
import Vapor

class ExpCollection: ApiCollection {
    typealias T = Experience

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(path.components(separatedBy: "/").map(PathComponent.constant))

        routes.on(.GET, use: readAll)

        routes.on(.GET, .parameter(restfulIDKey), use: read)

        let trusted = routes.grouped([
            User.authenticator(),
            Token.authenticator(),
            User.guardMiddleware(),
        ])

        trusted.on(.POST, use: create)
        trusted.on(.PUT, .parameter(restfulIDKey), use: update)
        trusted.on(.DELETE, .parameter(restfulIDKey), use: delete)
    }

    func update(_ req: Request) async throws -> T.DTO {
        let userId = try req.auth.require(User.self).requireID()

        guard
            let exp = try await specifiedIDQueryBuilder(on: req)
                .filter(\.$user.$id == userId)
                .with(\.$industries)
                .first()
        else {
            throw Abort(.notFound)
        }

        return try await performUpdate(exp, on: req)
    }

    func applyingEagerLoaders(_ builder: QueryBuilder<T>) -> QueryBuilder<T> {
        builder.with(\.$industries)
    }

    func delete(_ req: Request) async throws -> HTTPStatus {
        guard
            let exp = try await specifiedIDQueryBuilder(on: req)
                .with(\.$industries)
                .first()
        else {
            throw Abort.init(.notFound)
        }

        try await exp.$industries.detach(exp.industries, on: req.db)
        try await exp.delete(on: req.db)

        return .ok
    }

    func performUpdate(_ original: T?, on req: Request) async throws -> T.DTO {
        var serializedObject = try req.content.decode(T.DTO.self)
        serializedObject.userId = try req.auth.require(User.self).requireID()

        let industries: [Industry] = serializedObject.industries.map({
            let industry = Industry.init()
            industry.id = $0.id
            return industry
        })

        var upgrade = T.init()

        if let original = original {
            upgrade = try original.update(with: serializedObject)
        } else {
            upgrade = try T.init(from: serializedObject)
            upgrade.id = nil
        }

        try await upgrade.save(on: req.db)

        let difference = industries.difference(from: upgrade.$industries.value ?? []) {
            $0.id == $1.id
        }

        for diff in difference {
            switch diff {
                case .insert(offset: _, element: let industry, associatedWith: _):
                    try await upgrade.$industries.attach(industry, on: req.db)
                case .remove(offset: _, element: let industry, associatedWith: _):
                    try await upgrade.$industries.detach(industry, on: req.db)
            }
        }

        try await upgrade.$industries.load(on: req.db)
        return try upgrade.dataTransferObject()
    }
}
