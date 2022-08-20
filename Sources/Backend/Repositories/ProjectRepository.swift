import Fluent
import Vapor

struct ProjectRepository: Repository {

    var req: Request

    init(req: Request) {
        self.req = req
    }

    func query(owned: Bool = false) throws -> QueryBuilder<Project> {
        let query = Project.query(on: req.db)

        if owned {
            try query.filter(\.$user.$id == req.owner.__id)
        }

        return query
    }

    func query(_ id: Project.IDValue, owned: Bool = false) throws -> QueryBuilder<Project> {
        try query(owned: owned).filter(\.$id == id)
    }

    func create(_ model: Project) async throws {
        try await req.owner.$projects.create(model, on: req.db)
    }

    func identified(by id: Project.IDValue, owned: Bool = false) async throws -> Project {
        guard let result = try await query(id, owned: owned).first() else {
            throw Abort(.notFound)
        }
        return result
    }

    func readAll() async throws -> [Project] {
        try await query().all()
    }

    func update(_ model: Project) async throws {
        try await model.update(on: req.db)
    }

    func delete(_ id: Project.IDValue) async throws {
        try await query(id, owned: true).delete()
    }
}

extension RepositoryID {
    static let project: RepositoryID = "project"
}

extension Request {

    var project: ProjectRepository {
        guard let result = registry.repository(.project, self) as? ProjectRepository else {
            fatalError("Project repository is not configured")
        }
        return result
    }
}
