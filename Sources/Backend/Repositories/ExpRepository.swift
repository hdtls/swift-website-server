import Vapor
import Fluent

struct ExpRepository: Repository {
        
    var req: Request
    
    init(req: Request) {
        self.req = req
    }
    
    func query() -> QueryBuilder<Experience> {
        Experience.query(on: req.db)
    }
    
    func query(_ id: Experience.IDValue) -> QueryBuilder<Experience> {
        query().filter(\.$id == id)
    }
    
    func owned(_ id: Experience.IDValue) async throws -> Experience {
        let result = try await req.user.$experiences.query(on: req.db)
            .filter(\.$id == id)
            .first()
            
        guard let result = result else {
            throw Abort(.notFound)
        }
        return result
    }

    func save(_ model: Experience) async throws {
        try await model.save(on: req.db)
    }
        
    func delete(_ id: Experience.IDValue) async throws {
        try await req.user.$experiences.query(on: req.db).filter(\.$id == id).delete()
    }
}

extension RepositoryID {
    static let exp: RepositoryID = "exp"
}

extension RepositoryFactory {

    var exp: ExpRepository {
        guard let result = repository(.exp) as? ExpRepository else {
            fatalError("Experience repository is not configured")
        }
        return result
    }
}
