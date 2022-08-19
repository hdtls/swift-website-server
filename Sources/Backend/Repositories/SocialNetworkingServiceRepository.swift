import Vapor
import Fluent

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
    
    func create(_ model: SocialNetworkingService) async throws {
        try await model.create(on: req.db)
    }

    func read(_ id: SocialNetworkingService.IDValue) async throws -> SocialNetworkingService {
        guard let result = try await query(id).first() else {
            throw Abort(.notFound)
        }
        return result
    }
    
    func readAll() async throws -> [SocialNetworkingService] {
        try await query().all()
    }
    
    func update(_ model: SocialNetworkingService) async throws {
        try await model.update(on: req.db)
    }
        
    func delete(_ id: SocialNetworkingService.IDValue) async throws {
        try await query(id).delete()
    }
}

extension RepositoryID {
    static let socialNetworkingService: RepositoryID = "social_networking_service"
}

extension RepositoryFactory {

    var socialNetworkingService: SocialNetworkingServiceRepository {
        guard let result = repository(.socialNetworkingService) as? SocialNetworkingServiceRepository else {
            fatalError("Social networking service repository is not configured")
        }
        return result
    }
}
