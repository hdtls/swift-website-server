import Fluent
import Vapor

struct SocialNetworkingRepository: Repository {

    var req: Request

    init(req: Request) {
        self.req = req
    }

    func query(owned: Bool = false) throws -> QueryBuilder<SocialNetworking> {
        let query = SocialNetworking.query(on: req.db).with(\.$service)

        if owned {
            try query.filter(\.$user.$id == req.owner.__id)
        }

        return query
    }

    func query(_ id: SocialNetworking.IDValue, owned: Bool = false) throws -> QueryBuilder<
        SocialNetworking
    > {
        try query(owned: owned).filter(\.$id == id)
    }

    func create(_ model: SocialNetworking) async throws {
        try await req.owner.$social.create(model, on: req.db)
        try await model.$service.load(on: req.db)
    }

    func identified(by id: SocialNetworking.IDValue, owned: Bool = false) async throws
        -> SocialNetworking
    {
        guard let result = try await query(id, owned: owned).first() else {
            throw Abort(.notFound)
        }
        return result
    }

    func readAll(owned: Bool = false) async throws -> [SocialNetworking] {
        try await query(owned: owned).all()
    }

    func update(_ model: SocialNetworking) async throws {
        try await model.save(on: req.db)
        try await model.$service.load(on: req.db)
    }

    func delete(_ id: SocialNetworking.IDValue) async throws {
        try await query(id, owned: true).delete()
    }
}

extension RepositoryID {
    static let socialNetworking: RepositoryID = "social_networking"
}

extension Request {

    var socialNetworking: SocialNetworkingRepository {
        guard
            let result = registry.repository(.socialNetworking, self) as? SocialNetworkingRepository
        else {
            fatalError("Social networking repository is not configured")
        }
        return result
    }
}
