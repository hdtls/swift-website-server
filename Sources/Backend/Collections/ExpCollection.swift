import Fluent
import Vapor

class ExpCollection: RouteCollection {

    private let restfulIDKey: String = "id"
    
    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(.constant(Experience.schema))

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

    func create(_ req: Request) async throws -> Experience.DTO {
        try await performUpdate(nil, on: req)
    }
    
    func read(_ req: Request) async throws -> Experience.DTO {
        let id = try req.parameters.require(restfulIDKey, as: Experience.IDValue.self)
        
        guard let saved = try await req.repository.exp.query(id).with(\.$industries).first() else {
            throw Abort(.notFound)
        }
        
        return try saved.dataTransferObject()
    }
    
    func readAll(_ req: Request) async throws -> [Experience.DTO] {
        try await req.repository.exp.query().with(\.$industries).all().map {
            try $0.dataTransferObject()
        }
    }
    
    func update(_ req: Request) async throws -> Experience.DTO {
        let id = try req.parameters.require(restfulIDKey, as: Experience.IDValue.self)

        guard
            let exp = try await req.repository.exp.query(id)
                .filter(\.$user.$id == req.uid)
                .with(\.$industries)
                .first()
        else {
            throw Abort(.notFound)
        }

        return try await performUpdate(exp, on: req)
    }

    func delete(_ req: Request) async throws -> HTTPResponseStatus {
        let id = try req.parameters.require(restfulIDKey, as: Experience.IDValue.self)

        guard
            let exp = try await req.repository.exp.query(id)
                .filter(\.$user.$id == req.uid)
                .with(\.$industries)
                .first()
        else {
            throw Abort.init(.notFound)
        }

        try await exp.$industries.detach(exp.industries, on: req.db)
        try await req.repository.exp.delete(exp.requireID())

        return .ok
    }

    func performUpdate(_ original: Experience?, on req: Request) async throws -> Experience.DTO {
        var serializedObject = try req.content.decode(Experience.DTO.self)
        serializedObject.userId = try req.uid

        let industries: [Industry] = serializedObject.industries.map({
            let industry = Industry.init()
            industry.id = $0.id
            return industry
        })

        var upgrade = Experience.init()

        if let original = original {
            upgrade = try original.update(with: serializedObject)
        } else {
            upgrade = try Experience.init(from: serializedObject)
            upgrade.id = nil
        }

        try await req.repository.exp.save(upgrade)

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
