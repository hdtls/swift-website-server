import Vapor
import Fluent

struct ProjectRepository: Repository {
        
    var req: Request
    
    init(req: Request) {
        self.req = req
    }
    
    func query() -> QueryBuilder<Project> {
        Project.query(on: req.db)
    }
    
    func query(_ id: Project.IDValue) -> QueryBuilder<Project> {
        query().filter(\.$id == id)
    }
    
    func create(_ model: Project) async throws {
        try await req.user.$projects.create(model, on: req.db)
    }

    func read(_ id: Project.IDValue) async throws -> Project {
        guard let result = try await query(id).first() else {
            throw Abort(.notFound)
        }
        return result
    }
    
    func owned(_ id: Project.IDValue) async throws -> Project {
        let result = try await req.user.$projects.query(on: req.db)
            .filter(\.$id == id)
            .first()
            
        guard let result = result else {
            throw Abort(.notFound)
        }
        return result
    }
    
    func readAll() async throws -> [Project] {
        try await query().all()
    }
    
    func update(_ model: Project) async throws {
        // Authentication check
        _ = try req.user
        try await model.update(on: req.db)
    }
        
    func delete(_ id: Project.IDValue) async throws {
        try await req.user.$projects.query(on: req.db).filter(\.$id == id).delete()
    }
}

extension RepositoryID {
    static let project: RepositoryID = "project"
}

extension RepositoryFactory {

    var project: ProjectRepository {
        guard let result = repository(.project) as? ProjectRepository else {
            fatalError("Project repository is not configured")
        }
        return result
    }
}
