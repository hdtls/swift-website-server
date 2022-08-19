import Vapor
import Fluent

struct EducationRepository: Repository {
        
    var req: Request
    
    init(req: Request) {
        self.req = req
    }
    
    func query() -> QueryBuilder<Education> {
        Education.query(on: req.db)
    }
    
    func query(_ id: Education.IDValue) -> QueryBuilder<Education> {
        query().filter(\.$id == id)
    }
    
    func create(_ model: Education) async throws {
        try await req.user.$education.create(model, on: req.db)
    }

    func read(_ id: Education.IDValue) async throws -> Education {
        guard let result = try await query(id).first() else {
            throw Abort(.notFound)
        }
        return result
    }
    
    func owned(_ id: Education.IDValue) async throws -> Education {
        let result = try await req.user.$education.query(on: req.db)
            .filter(\.$id == id)
            .first()
            
        guard let result = result else {
            throw Abort(.notFound)
        }
        return result
    }
    
    func readAll() async throws -> [Education] {
        try await query().all()
    }
    
    func update(_ model: Education) async throws {
        // Authentication check
        _ = try req.user
        try await model.update(on: req.db)
    }
        
    func delete(_ id: Education.IDValue) async throws {
        try await req.user.$education.query(on: req.db).filter(\.$id == id).delete()
    }
}

extension RepositoryID {
    static let education: RepositoryID = "education"
}

extension RepositoryFactory {

    var education: EducationRepository {
        guard let result = repository(.education) as? EducationRepository else {
            fatalError("Education repository is not configured")
        }
        return result
    }
}
