import Fluent
import Vapor

struct SocialNetworkingServiceRepository: Repository {

    var req: Request

    init(req: Request) {
        self.req = req
    }

    func query() -> QueryBuilder<SocialNetworkingService> {
        SocialNetworkingService.query(on: req.db)
    }

    func query(_ id: SocialNetworkingService.IDValue) -> QueryBuilder<SocialNetworkingService> {
        query().filter(\.$id == id)
    }

    func save(_ model: SocialNetworkingService) async throws {
        try await model.save(on: req.db)
    }

    func identified(by id: SocialNetworkingService.IDValue) async throws -> SocialNetworkingService
    {
        guard let result = try await query(id).first() else {
            throw Abort(.notFound)
        }
        return result
    }

    func readAll() async throws -> [SocialNetworkingService] {
        try await query().all()
    }

    func delete(_ id: SocialNetworkingService.IDValue) async throws {
        try await query(id).delete()
    }
}

extension RepositoryID {
    static let socialNetworkingService: RepositoryID = "social_networking_service"
}

extension Request {

    var socialNetworkingService: SocialNetworkingServiceRepository {
        guard
            let result = registry.repository(.socialNetworkingService, self)
                as? SocialNetworkingServiceRepository
        else {
            fatalError("Social networking service repository is not configured")
        }
        return result
    }
}
