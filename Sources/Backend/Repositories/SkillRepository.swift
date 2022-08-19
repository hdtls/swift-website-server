import Vapor
import Fluent

struct SkillRepository: Repository {
        
    var req: Request
    
    init(req: Request) {
        self.req = req
    }
    
    func query() -> QueryBuilder<Skill> {
        Skill.query(on: req.db)
    }
    
    func query(_ id: Skill.IDValue) -> QueryBuilder<Skill> {
        query().filter(\.$id == id)
    }
    
    func create(_ model: Skill) async throws {
        try await req.user.$skill.create(model, on: req.db)
    }

    func read(_ id: Skill.IDValue) async throws -> Skill {
        guard let result = try await query(id).first() else {
            throw Abort(.notFound)
        }
        return result
    }
    
    func owned(_ id: Skill.IDValue) async throws -> Skill {
        let result = try await req.user.$skill.query(on: req.db)
            .filter(\.$id == id)
            .first()
            
        guard let result = result else {
            throw Abort(.notFound)
        }
        return result
    }
    
    func readAll() async throws -> [Skill] {
        try await query().all()
    }
    
    func update(_ model: Skill) async throws {
        // Authentication check
        _ = try req.user
        try await model.update(on: req.db)
    }
        
    func delete(_ id: Skill.IDValue) async throws {
        try await req.user.$skill.query(on: req.db).filter(\.$id == id).delete()
    }
}

extension RepositoryID {
    static let skill: RepositoryID = "skill"
}

extension RepositoryFactory {

    var skill: SkillRepository {
        guard let result = repository(.skill) as? SkillRepository else {
            fatalError("Skill repository is not configured")
        }
        return result
    }
}
