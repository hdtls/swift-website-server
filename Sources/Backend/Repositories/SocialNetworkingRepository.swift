import Vapor
import Fluent

struct SocialNetworkingRepository: Repository {
        
    var req: Request
    
    init(req: Request) {
        self.req = req
    }
    
    func query() -> QueryBuilder<SocialNetworking> {
        SocialNetworking.query(on: req.db)
    }
    
    func query(_ id: SocialNetworking.IDValue) -> QueryBuilder<SocialNetworking> {
        query().filter(\.$id == id)
    }

    func save(_ model: SocialNetworking) async throws {
        try await model.save(on: req.db)
    }

    func read(_ id: SocialNetworking.IDValue) async throws -> SocialNetworking {
        guard let result = try await query(id).with(\.$service).first() else {
            throw Abort(.notFound)
        }
        return result
    }
    
    func owned(_ id: SocialNetworking.IDValue) async throws -> SocialNetworking {
        let result = try await req.user.$social.query(on: req.db)
            .filter(\.$id == id)
            .first()
            
        guard let result = result else {
            throw Abort(.notFound)
        }
        return result
    }
    
    func readAll() async throws -> [SocialNetworking] {
        try await query().with(\.$service).all()
    }
        
    func delete(_ id: SocialNetworking.IDValue) async throws {
        try await req.user.$social.query(on: req.db).filter(\.$id == id).delete()
    }
}

extension RepositoryID {
    static let socialNetworking: RepositoryID = "social_networking"
}

extension RepositoryFactory {

    var socialNetworking: SocialNetworkingRepository {
        guard let result = repository(.socialNetworking) as? SocialNetworkingRepository else {
            fatalError("Social networking repository is not configured")
        }
        return result
    }
}
